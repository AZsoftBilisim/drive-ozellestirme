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
	ListOfDocumentsCostRecognitionAutoRenewalMode = True;
	// End DynamicListsSettings
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	List.Parameters.SetParameterValue("AccountingStartDate", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	ListDetailed.Parameters.SetParameterValue("AccountingStartDate", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	
	List.Parameters.SetParameterValue("ShowDocumentTime", ShowDocumentTime);
	ListDetailed.Parameters.SetParameterValue("ShowDocumentTime", ShowDocumentTime);
	
	NonCurrentAssetsLocalization.FillInCorrespondenceOfIaJournalDocuments(DocumentCorrespondence);
	
	If Not Parameters.Property("FormAssignmentKey")
		Or IsBlankString(Parameters.FormAssignmentKey) Then
		PurposeUseKey = DefaultFormAssignmentKey();
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
			Title = NStr("vi = 'Chứng từ về tài sản cố định vô hình và chi phí Nghiên cứu phát triển được tạo để chuyển sang kế toán cho tài sản dài hạn phiên bản 2.4';
						|ru = 'Документы по НМА и расходам на НИОКР, созданные для перехода на учет внеоборотных активов версии 2.4';
						|en = 'Documents of intangible assets and R&D expenses created for migration to fixed asset accounting 2.4'; fa = 'Documents of intangible assets and R&D expenses created for migration to fixed asset accounting 2.4';
						|it = 'Documenti sui beni immateriali e sulle spese in Ricerca e Sviluppo, creati per il passaggio alla contabilità per le attività non correnti della versione 2.4';
						|pl = 'Dokumenty po NMA i rozchodach na PNBDK, utworzone w celu przejścia na rachunkowości trwałych aktywów wersji 2.4';
						|tr = 'Duran varlıklar muhasebesine geçiş için oluşturulan GMA ve Ar-Ge harcamalarına ilişkin dokümanlar versiyon 2.4'");
			Items.TheSelectionOfTheOrganizationDepreciation.Visible = False;
			Items.TheSelectionOfIntangibleAssetAmortization.Visible = False;
			Items.ListDepreciation.Visible = False;
			Items.GroupCustomSettingsListDepreciation.Visible = False;
		EndIf; 
		
	ElsIf Parameters.Property("IntangibleAsset") Then
		
		Items.GroupPages.CurrentPage = Items.DocumentsDetailsPage;

		FormsOpenedByHyperlink = True;

		FilterIntangibleAsset = Parameters.IntangibleAsset;
		Items.List.Visible = False;
		Items.FilterOrganization.Visible = False;
		Items.HelpTextFilter.Visible = False;
		Items.FilterIntangibleAsset.Visible = False;
		Items.TheSelectionOfIntangibleAssetAmortization.Visible = False;
		Items.ListDetailedIntangibleAsset.Visible = False;
		Items.GroupUserSettingsList.Visible = False;
		Items.ListRDExpensesRecognition.Visible = False;
		Items.FilterTopicStage.Visible = False;
		Items.TheSelectionOfTheOrganizationRecognitionOfExpenses.Visible = False;
		Items.ToDesignOfStudy.Visible = False;
		
		AutoTitle = False;
		KindOfAccountingObject = Common.ObjectAttributeValue(FilterIntangibleAsset, "KindOfAccountingObject");
		If KindOfAccountingObject = Enums.IntangibleAssetsAccountingItemKinds.RDExpenses Then
			Title = StrTemplate(NStr("vi = 'Chứng từ về chi phí Nghiên cứu phát triển %1';
									|ru = 'Документы по расходам на НИОКР %1';
									|en = '%1 R&D expense documents'; fa = '%1 R&D expense documents';
									|it = 'Documenti sulle spese in Ricerca e Sviluppo %1';
									|pl = 'Dokumenty po rozchodach na PNBDK %1';
									|tr = '%1Ar-Ge harcamalarına ilişkin belgeler'"), String(FilterIntangibleAsset));
		Else
			Title = StrTemplate(NStr("vi = 'Chứng từ về tài sản cố định vô hình %1';
									|ru = 'Документы по нематериальному активу %1';
									|en = '%1 intangible asset documents'; fa = '%1 intangible asset documents';
									|it = 'Documenti sui beni immateriali %1';
									|pl = 'Dokumenty po wartości niematerialnej %1';
									|tr = '%1Maddi olmayan duran varlığa ilişkin belgeler'"), String(FilterIntangibleAsset));
		EndIf; 
		
	ElsIf Parameters.Property("TopicStageOfResearchAndDevelopment") Then
		
		Items.GroupPages.CurrentPage = Items.PageRecognitionOfResearchAndDevelopmentExpenses;

		FormsOpenedByHyperlink = True;
		
		FilterTopicStage = Parameters.TopicStageOfResearchAndDevelopment;
		Items.List.Visible = False;
		Items.ListDetailed.Visible = False;
		Items.ListDepreciation.Visible = False;
		Items.FilterOrganization.Visible = False;
		Items.SelectionOrganizationDetails.Visible = False;
		Items.TheSelectionOfTheOrganizationDepreciation.Visible = False;
		Items.TheSelectionOfTheOrganizationRecognitionOfExpenses.Visible = False;
		Items.HelpTextFilter.Visible = False;
		Items.InformationLabelSelectionInDetail.Visible = False;
		Items.FilterIntangibleAsset.Visible = False;
		Items.TheSelectionOfIntangibleAssetAmortization.Visible = False;
		Items.FilterTopicStage.Visible = False;
		Items.GroupUserSettingsList.Visible = False;
		Items.GroupCustomSettingsListDetails.Visible = False;
		Items.GroupCustomSettingsExpenseRecognition.Visible = False;
		Items.ToDesignOfStudy.Visible = False;
		
		AutoTitle = False;
		Title = StrTemplate(NStr("vi = 'Chứng từ theo đề tài, giai đoạn nghiên cứu và phát triển %1';
								|ru = 'Документы по теме, этапу исследований и разработок %1';
								|en = 'Documents on research and development stage, topic %1'; fa = 'Documents on research and development stage, topic %1';
								|it = 'Documenti su oggetto, fase di ricerche e sviluppi %1';
								|pl = 'Dokumenty wg tematu, etapu badań i opracowań %1';
								|tr = 'Konuyla ilgili belgeler, %1araştırma ve geliştirme aşaması'"), String(FilterTopicStage));
		
	Else
		RestoreSettings();
	EndIf;
	
	QueryText = List.QueryText;
	NonCurrentAssetsLocalization.SupplementTextOfIAJournalRequest(QueryText);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ListOfReglGroupVerification);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing, AdditionalParameters);
	
	FillInFormDetailsWhenCreating();
	CustomizeFormElementsWhenCreating();
	SetDynamicListSelections_();
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List);
		
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.ListDepreciation);
		
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.ListRDExpensesRecognition);
		
	TMCommonUse.FormInscriptionSelection(
		HelpTextFilter, 
		BusinessTransactionsAndDocuments, 
		FilterDocumentTypes, 
		FilterBusinessTransactions);
	
	If Not AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently() Then
		Items.ListRecordInManAccounting.Visible = False;
		Items.ListRecordInLocalAccounting.Visible = False;
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
	TypesOfDocumentsUsedExpenseRecognition = New Array;
	For Each OperationDescription In BusinessTransactionsAndDocumentsRecognitionOfExpenses Do
		TypesOfDocumentsUsedExpenseRecognition.Add(Type("DocumentRef." + StrSplit(OperationDescription.FullDocumentName, ".")[1]));
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
	
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(TypesOfDocumentsUsedExpenseRecognition);
	PlacementParameters.CommandBar = Items.ListRDExpensesRecognitionCommandBar;
	PlacementParameters.GroupsPrefix = "ListOfExpenseRecognition";
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
	
	
	IADataNeedsToBeUpdated = False;
	DepreciationDataNeedsToBeUpdated = False;
	DataNeedsToBeUpdatedExpenseRecognition = False;
	
	If EventName = "Write_File" Then
		
		IADataNeedsToBeUpdated = True;
		DepreciationDataNeedsToBeUpdated = True;
		DataNeedsToBeUpdatedExpenseRecognition = True;
		Items.ListDetailed.Refresh();
		
	ElsIf StrFind(EventName, "Record_") <> 0 Then

		For Each LineDocument In BusinessTransactionsAndDocuments Do
			EventNameDocumentEntry = StrReplace(LineDocument.FullDocumentName, "Document.", "Record_");
			If EventNameDocumentEntry = EventName Then
				IADataNeedsToBeUpdated = True;
				Break;
			EndIf;
		EndDo;
		
		For Each LineDocument In BusinessTransactionsAndDocumentsDepreciation Do
			EventNameDocumentEntry = StrReplace(LineDocument.FullDocumentName, "Document.", "Record_");
			If EventNameDocumentEntry = EventName Then
				DepreciationDataNeedsToBeUpdated = True;
				Break;
			EndIf;
		EndDo;
		
		For Each LineDocument In BusinessTransactionsAndDocumentsRecognitionOfExpenses Do
			EventNameDocumentEntry = StrReplace(LineDocument.FullDocumentName, "Document.", "Record_");
			If EventNameDocumentEntry = EventName Then
				DataNeedsToBeUpdatedExpenseRecognition = True;
				Break;
			EndIf;
		EndDo;

	EndIf;

	If IADataNeedsToBeUpdated Then
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("List", Parameter);
		// End DynamicListsSettings
	EndIf;
	
	If DepreciationDataNeedsToBeUpdated Then
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("ListDepreciation", Parameter);
		// End DynamicListsSettings
	EndIf;
	
	If DataNeedsToBeUpdatedExpenseRecognition Then
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("ListRDExpensesRecognition", Parameter);
		// End DynamicListsSettings
	EndIf;
	
	StartUpdatingDataInBackground();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	WhenSelectionChanges();
	
	StartUpdatingDataInBackground();
	
EndProcedure

&AtClient
Procedure FilterIntangibleAssetOnChange(Item)
	
	WhenSelectionChanges();
	
EndProcedure

&AtClient
Procedure FilterTopicStageOnChange(Item)
	
	WhenSelectionChanges();
	
EndProcedure

&AtClient
Procedure HelpTextFilterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure();
	FormParameters.Insert("AvailableBusinessTransactionsAndDocuments", PlaceBusinessTransactionsAndDocumentsInTemporaryStorage());
	FormParameters.Insert("SettingsKey", PurposeUseKey);
	FormParameters.Insert("FormKey", DefaultFormAssignmentKey());
	
	OpenForm("Catalog.BusinessTransactionsSettings.Form.FormOfFilterSetting",
		FormParameters,,,,, New CallbackDescription("EstablishSelectionsForBusinessTransactionsAndDocuments", ThisObject));
	
EndProcedure

&AtClient
Procedure ToRegistrationAcceptanceForAccountingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "#Recognition" Then
		OpenForm("Document.IntangibleAssetsInitialRecognition2_4.Form.Recognition");
	EndIf;

EndProcedure

&AtClient
Procedure ToDesignOfStudyURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessors.JournalOfIADocuments2_4.Form.IntangibleAssetsDocuments.Event.ToRegisterURLProcessing");
	// End StandardSubsystems.PerformanceMeasurement
	
	StandardProcessing = False;
		
	FormParameters = New Structure;
	QuickFilterStructure = New Structure;
	
	If ValueIsFilled(FilterOrganization) Then
		QuickFilterStructure.Insert("Organization", FilterOrganization);
		FormParameters.Insert("Organization", FilterOrganization);
	EndIf;
	
	CurrentDate = CommonClient.SessionDate();
	QuickFilterStructure.Insert("Period", ListExpenseRecognitionInterval);
	QuickFilterStructure.Insert("RegistrationPeriod", ?(ValueIsFilled(ListExpenseRecognitionInterval.EndDate), BegOfMonth(ListExpenseRecognitionInterval.EndDate), BegOfMonth(CurrentDate)));

	FormParameters.Insert("BeginOfPeriod", QuickFilterStructure.RegistrationPeriod);
	FormParameters.Insert("EndOfPeriod", ?(ValueIsFilled(ListExpenseRecognitionInterval.EndDate), ListExpenseRecognitionInterval.EndDate, EndOfMonth(CurrentDate)));
	FormParameters.Insert("QuickFilterStructure",	QuickFilterStructure);
	FormParameters.Insert("FormAssignmentKey",		DefaultFormAssignmentKey());
	
	OpenForm(FormattedStringURL,FormParameters);

EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Item, Title);
	
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

#EndRegion

#Region FormTableItemsEventHandlersListDepreciation

&AtClient
Procedure ListDepreciationOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure ListDepreciationOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListDepreciation");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListRDExpensesRecognition

&AtClient
Procedure ListRDExpensesRecognitionOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListRDExpensesRecognitionSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListRDExpensesRecognitionBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
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
Procedure ListRDExpensesRecognitionBeforeDeleteRow(Item, Cancel)
		
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Item, Title);
	
EndProcedure

&AtClient
Procedure ListRDExpensesRecognitionBeforeRowChange(Item, Cancel)
		
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtServer
Procedure ListRDExpensesRecognitionOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListRDExpensesRecognition");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ListSetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(ListInterval,, Notification);
	
EndProcedure

&AtClient
Procedure AListOfDetailsToSetTheInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(ListInDetailInterval,, Notification);
	
EndProcedure

&AtClient
Procedure TheListOfAttenuationToSetTheInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(AListOfTheAmortizationInterval,, Notification);
	
EndProcedure

&AtClient
Procedure Post(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();
	
	OnChangingListATServer();
	
EndProcedure

&AtClient
Procedure AListOfDetailsToCarryOut(Command)
	
	TMCommonUseClient.PostDocuments(Items.ListDetailed, Title);
	
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();
	
	OnChangingListATServer();
	
EndProcedure

&AtClient
Procedure ListOfDepreciationHold(Command)
	
	TMCommonUseClient.NavigateDocumentsInBackgroundTask(
		Items.ListDepreciation, "Document.IntangibleAssetsAmortizationCharge2_4.Form.DepreciationCalculation");
	
EndProcedure

&AtClient
Procedure UndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.List, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();
	
	OnChangingListATServer();
	
EndProcedure

&AtClient
Procedure TheListDetailsTheCancellationOfThe(Command)
	
	TMCommonUseClient.UndoPosting(Items.ListDetailed, Title);
	
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();
	
	OnChangingListATServer();
	
EndProcedure

&AtClient
Procedure ListDepreciationCancellationOfTheEvent(Command)
	
	TMCommonUseClient.UndoPosting(Items.ListDepreciation, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListDepreciation"));
	
EndProcedure

&AtClient
Procedure Copy(Command)
	
	TMCommonUseClient.CopyItem(Items.List);
	
EndProcedure

&AtClient
Procedure ListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.List);
	
EndProcedure

&AtClient
Procedure CopyTheListInDetail(Command)
	
	TMCommonUseClient.CopyItem(Items.ListDetailed);
	
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
Procedure SetClearDeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.List, Title, Undefined,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	
EndProcedure

&AtClient
Procedure ListDetailedSetClearADeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.ListDetailed, Title);
	
EndProcedure

&AtClient
Procedure AListOfDepreciationSetUnmarkDelete(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.ListDepreciation, Title, Undefined,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListDepreciation"));
	
EndProcedure

&AtClient
Procedure ListFinancialAccountingPostings(Command)
	If Items.List.CurrentData <> Undefined Then
		NonCurrentAssetsClient.OpenInternationalAccountingTransactions(Items.List.CurrentData.Ref);
	EndIf; 
	Return;
	
EndProcedure

&AtClient
Procedure ListOfInternationalAccountingTransactionsInDetail(Command)
	If Items.ListDetailed.CurrentData <> Undefined Then
		NonCurrentAssetsClient.OpenInternationalAccountingTransactions(Items.ListDetailed.CurrentData.Ref);
	EndIf; 
	Return;
	
EndProcedure

&AtClient
Procedure ListOfDepreciationOfInternationalAccountingTransactions(Command)
	If Items.ListDepreciation.CurrentData <> Undefined Then
		NonCurrentAssetsClient.OpenInternationalAccountingTransactions(Items.ListDepreciation.CurrentData.Ref);
	EndIf; 
	Return;
	
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

&AtClient
Procedure ListTheRecognitionOfExpendituresOnResearchAndDevelopmentToConduct(Command)
	
	TMCommonUseClient.PostDocuments(Items.ListRDExpensesRecognition, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject,
		"ListRDExpensesRecognition"));
	
EndProcedure

&AtClient
Procedure ListTheRecognitionOfExpendituresOnResearchAndDevelopmentToSetTheInterval(Command)
		
	Notification = New CallbackDescription("AListOfTheExpensesToSetTheIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(ListExpenseRecognitionInterval,, Notification);
	
EndProcedure

&AtClient
Procedure ListRecognitionOfResearchAndDevelopmentExpensesCancellationOfTheEvent(Command)
	
	TMCommonUseClient.UndoPosting(Items.ListRDExpensesRecognition, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject,
		"ListRDExpensesRecognition"));

EndProcedure

&AtClient
Procedure ListOfResearchAndDevelopmentExpenditureRecognitionCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.ListRDExpensesRecognition);
	
EndProcedure

&AtClient
Procedure ListOfRAndDAssetWriteOffIsToBeChanged(Command)
	
	TMCommonUseClient.ChangeElement(Items.ListRDExpensesRecognition);
	
EndProcedure

&AtClient
Procedure ListTheRecognitionOfExpendituresOnResearchAndDevelopmentToEstablishAClearMarkRemoval(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.ListRDExpensesRecognition,
		Title, Undefined, OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject,
		"ListRDExpensesRecognition"));
	
EndProcedure

&AtClient
Procedure ListOfRecognitionOfResearchAndDevelopmentExpensesInternationalAccountingEntries(Command)
	If Items.ListRDExpensesRecognition.CurrentData <> Undefined Then
		NonCurrentAssetsClient.OpenInternationalAccountingTransactions(Items.ListRDExpensesRecognition.CurrentData.Ref);
	EndIf; 
	Return;
	
EndProcedure

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

&AtClient
Procedure ListOfDocumentsCostRecognitionUpdate(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("ListRDExpensesRecognition");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	NonCurrentAssetsInternal.SetDateFieldConditionalAppearance(
		ThisObject, "List.Date", "ListDate", "ShowDocumentTime");
		
	NonCurrentAssetsInternal.SetDateFieldConditionalAppearance(
		ThisObject, "ListDetailed.Date", "ListDetailedDate", "ShowDocumentTime");
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(
		ThisObject, "ListRDExpensesRecognition.Date", "ListRDExpensesRecognitionDate");
	
EndProcedure

&AtServer
Procedure FillInFormDetailsWhenCreating()
	
	TableOfValuesAvailable = InitializeBusinessTransactionsAndDocuments(
		BusinessTransactionsAndDocuments.Unload(),
		FilterBusinessTransactions,
		FilterDocumentTypes,
		SettingsKey);
	
	BusinessTransactionsAndDocuments.Load(TableOfValuesAvailable);
	
	TableOfValuesAvailable = InitializeBusinessTransactionsAndDepreciationDocuments(
		BusinessTransactionsAndDocumentsDepreciation.Unload(),
		TheSelectionOfABusinessTransactionDepreciation,
		FilterDocumentTypesDepreciation,
		SettingsKey);
	
	BusinessTransactionsAndDocumentsDepreciation.Load(TableOfValuesAvailable);
	
	TableOfValuesAvailable = InitializeBusinessTransactionsAndDocumentsExpenseRecognition(
		BusinessTransactionsAndDocumentsRecognitionOfExpenses.Unload(),
		SelectionBusinessOperationsRecognitionOfExpenses,
		TheSelectionOfTheTypesOfDocumentsRecognitionOfExpenses,
		SettingsKey,
		FilterCompaniesWithExpenseRecognitionForResearch);
	
	BusinessTransactionsAndDocumentsRecognitionOfExpenses.Load(TableOfValuesAvailable);
	
EndProcedure

&AtServer
Procedure CustomizeFormElementsWhenCreating()
	If Not AccessRight("View", Metadata.DataProcessors.DocumentPostingInFinancialAccounting.Commands.AccountingEntries) Then
		Items.ListFinancialAccountingPostings.Visible = False;
		Items.ListOfInternationalAccountingTransactionsInDetail.Visible = False;
		Items.ListOfDepreciationTransactionsOfTheOperationalAccountingDocument.Visible = False;
		Items.ListOfExpensesRecognitionTransactionsOfTheOperationalAccountingDocument.Visible = False;
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
		Items.ListRecordInTA.Visible = False;
		Items.ListDetailedRecordInTA.Visible = False;
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
Procedure ConfigureDocumentManagementButtons()
	
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form                                               = ThisForm;
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
	ParametersStructure.Form                                               = ThisForm;
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
	ParametersStructure.Form                                               = ThisForm;
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
	
	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form                                               = ThisForm;
	ParametersStructure.NameOfCreateGroup                                    = "AListOfExpenseRecognitionTheGroupToCreateAGenerated";
	ParametersStructure.GroupNameCreateContext                            = "AListOfExpenseRecognitionTheGroupToCreateTheGeneratedContext";
	ParametersStructure.NameOfCopyButton                                = "ListOfExpenseRecognitionCopy";
	ParametersStructure.NameOfCopyContextMenuButton                 = "ListOfExpenseRecognitionCopyContext";
	ParametersStructure.ChangeButtonName                                   = "AListOfTheExpensesChange";
	ParametersStructure.NameOfChangeContextMenuButton                    = "AListOfTheExpensesChangeTheContext";
	ParametersStructure.ButtonNamePost                                   = "AListOfTheExpensesToSpend";
	ParametersStructure.NameOfHoldContextMenuButton                    = "AListOfTheExpensesToHoldTheContext";
	ParametersStructure.NameOfCancelEventButton                           = "ListRecognitionOfExpensesCancellationOfTheEvent";
	ParametersStructure.NameOfCancelButtonIsContextMenu            = "ListRecognitionOfExpensesCancellationOfTheEventContext";
	ParametersStructure.NameOfMarkDeleteButton                  = "ListOfExpenseRecognitionSetDeleteMark";
	ParametersStructure.ButtonNameMarkDeleteContextMenu   = "ListOfExpenseRecognitionSetTheDeleteMarkContext";
	ParametersStructure.ElementPrefix                                    = "ListOfExpenseRecognition";
	ParametersStructure.NameOfTableOfBusinessOperationsAndDocuments          = "BusinessTransactionsAndDocumentsRecognitionOfExpenses";
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);
	
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
Procedure SelectionOperationTypeSelectionProcessingServer(AddressOfBusinessTransactionsAndDocuments)
	
	VTBusinessTransactionsAndDocumentTypes = GetFromTempStorage(AddressOfBusinessTransactionsAndDocuments);
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	
	TMCommonUse.FillInSelectionsAccordingToTableOfBusinessTransactionsAndDocumentTypes(
		VTBusinessTransactionsAndDocumentTypes, FilterBusinessTransactions, FilterDocumentTypes);
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List);
		
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.ListDepreciation);
		
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.ListRDExpensesRecognition);
	
	ConfigureFormUsingSettingsForBusinessOperationsAndDocuments();
	
	WhenSelectionChanges();

	TMCommonUse.FormInscriptionSelection(
		HelpTextFilter, BusinessTransactionsAndDocuments, FilterDocumentTypes, FilterBusinessTransactions);
	
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
		
	CommonClientServer.SetDynamicListFilterItem(
		ListDetailed,
		"IntangibleAsset",
		FilterIntangibleAsset,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterIntangibleAsset));
		
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
		
	ListDepreciation.Parameters.SetParameterValue("IntangibleAsset", FilterIntangibleAsset);
	ListDepreciation.Parameters.SetParameterValue("WithoutSelectionForAnIntangibleAsset", Not ValueIsFilled(FilterIntangibleAsset));
	
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
	
	#Region ListRDExpensesRecognition
	
	CommonClientServer.SetDynamicListFilterItem(
		ListRDExpensesRecognition,
		"RefType",
		TheSelectionOfTheTypesOfDocumentsRecognitionOfExpenses,
		DataCompositionComparisonType.InList,
		,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListRDExpensesRecognition,
		"Organization",
		FilterOrganization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterOrganization));
		
	ListRDExpensesRecognition.Parameters.SetParameterValue("BeginOfPeriod", ListExpenseRecognitionInterval.StartDate);
	ListRDExpensesRecognition.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(ListExpenseRecognitionInterval.EndDate),
			EndOfDay(ListExpenseRecognitionInterval.EndDate),
			EndOfDay(Date(3999, 12, 31))));
			
	CommonClientServer.SetDynamicListParameter(ListRDExpensesRecognition,
			"SelectionByTopicStage",
			FilterTopicStage,
			Not FilterTopicStage.IsEmpty());
	
	Items.AListOfTheExpensesToSetTheInterval.Check = 
		ValueIsFilled(ListExpenseRecognitionInterval.StartDate) Or ValueIsFilled(ListExpenseRecognitionInterval.EndDate);
	
	If Items.Find("ListCostRecognition__ResearchCostRecognition_ResearchAndDevelopmentCostRecognition")
		<> Undefined Then
			
		If FilterOrganization.IsEmpty() Then
			Items.ListCostRecognition__ResearchCostRecognition_ResearchAndDevelopmentCostRecognition.Visible
				= FilterCompaniesWithExpenseRecognitionForResearch.Count() > 0;
		Else
			Items.ListCostRecognition__ResearchCostRecognition_ResearchAndDevelopmentCostRecognition.Visible
				= FilterCompaniesWithExpenseRecognitionForResearch.FindByValue(FilterOrganization) <> Undefined;
		EndIf;
	EndIf;
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListRDExpensesRecognition");
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
Function SupplementBusinessTransactionsForSelection(SelectionOfBusinessOperationsOfList)
	
	SelectionOfBusinessOperationsCopy = SelectionOfBusinessOperationsOfList.Copy();
	
	For Each CollectionItem In SelectionOfBusinessOperationsOfList Do
		If CollectionItem.Value = Enums.BusinessTransactions.IntangibleAssetsInitialRecognition Then
			SelectionOfBusinessOperationsCopy.Add(Enums.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets);
		EndIf;
	EndDo;
	
	Return SelectionOfBusinessOperationsCopy;
	
EndFunction

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "IADocuments";
	
EndFunction

&AtServer
Function PlaceBusinessTransactionsAndDocumentsInTemporaryStorage()
	
	Return PutToTempStorage(BusinessTransactionsAndDocuments.Unload(), UUID);
	
EndFunction

&AtClientAtServerNoContext
Function CurrentList(Form)

	If Form.Items.GroupPages.CurrentPage = Form.Items.DocumentsDetailsPage Then
		Return Form.Items.ListDetailed;
	ElsIf Form.Items.GroupPages.CurrentPage = Form.Items.DepreciationPage Then
		Return Form.Items.ListDepreciation;
	ElsIf Form.Items.GroupPages.CurrentPage = Form.Items.PageRecognitionOfResearchAndDevelopmentExpenses Then
		Return Form.Items.ListRDExpensesRecognition;
	Else
		Return Form.Items.List;
	EndIf; 

EndFunction

&AtServer
Procedure WhenSelectionChanges()
	
	ShouldSaveSettings();
	
	SetDynamicListSelections_();
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	Settings = Common.CommonSettingsStorageLoad("DataProcessor.JournalOfIADocuments2_4.Form.IntangibleAssetsDocuments", PurposeUseKey);
	
	If TypeOf(Settings) = Type("Structure") Then
	
		ListInterval = Settings.ListInterval;
		ListInDetailInterval = Settings.ListInDetailInterval;
		AListOfTheAmortizationInterval = Settings.AListOfTheAmortizationInterval;
		FilterOrganization = Settings.FilterOrganization;
		FilterIntangibleAsset = Settings.FilterIntangibleAsset;
		
		Settings.Property("FilterBusinessTransactions", FilterBusinessTransactions);
		Settings.Property("FilterDocumentTypes", FilterDocumentTypes);
		
		If Settings.Property("ListOfDocumentsAutoUpdateMode") Then
			ListOfDocumentsAutoUpdateMode = Settings.ListOfDocumentsAutoUpdateMode;
		EndIf;
		If Settings.Property("ListOfDocumentsDepreciationAutoUpdateMode") Then
			ListOfDocumentsDepreciationAutoUpdateMode = Settings.ListOfDocumentsDepreciationAutoUpdateMode;
		EndIf;
		If Settings.Property("ListOfDocumentsCostRecognitionAutoRenewalMode") Then
			ListOfDocumentsCostRecognitionAutoRenewalMode = Settings.ListOfDocumentsCostRecognitionAutoRenewalMode;
		EndIf;
		
		ShowDocumentTime = CommonClientServer.StructureProperty(Settings, "ShowDocumentTime", False);
		Items.ListShowDocumentTime.Check = ShowDocumentTime;
		Items.ListDetailedShowDocumentTime.Check = ShowDocumentTime;
		List.Parameters.SetParameterValue("ShowDocumentTime", ShowDocumentTime);
		ListDetailed.Parameters.SetParameterValue("ShowDocumentTime", ShowDocumentTime);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	If FormsOpenedByHyperlink Then
		Return;
	EndIf;
	
	AttributesToSaveNames =
		"ListInterval,ListInDetailInterval,AListOfTheAmortizationInterval,ListExpenseRecognitionInterval,
		|FilterOrganization,
		|FilterIntangibleAsset,
		|FilterBusinessTransactions,
		|FilterDocumentTypes,
		|ShowDocumentTime,
		|ListOfDocumentsAutoUpdateMode,
		|ListOfDocumentsDepreciationAutoUpdateMode,
		|ListOfDocumentsCostRecognitionAutoRenewalMode";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisForm);
	
	Common.CommonSettingsStorageSave("DataProcessor.JournalOfIADocuments2_4.Form.IntangibleAssetsDocuments", PurposeUseKey, Settings);
	
EndProcedure

&AtServerNoContext
Function InitializeBusinessTransactionsAndDocuments(BusinessTransactionsAndDocuments, FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey, UnregisteredDocuments = False)
	
	NonCurrentAssetsInternal.InitializeBusinessTransactionsAndDocumentsOfNonCurrentAssets(BusinessTransactionsAndDocuments);
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.IntangibleAssetsInitialRecognition;
	String.FullDocumentName           = Metadata.Documents.IntangibleAssetsInitialRecognition2_4.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Bắt đầu hạch toán TSCĐ vô hình';
										|ru = 'Принятие к учету НМА';
										|en = 'Intangible assets — Initial recognition'; fa = 'دارایی‌های نامشهود — شناسایی اولیه';
										|it = 'Scrittura nei libri contabili dei beni immateriali';
										|pl = 'Przyjęcie do ewidencji wartości niematerialnych';
										|tr = 'Maddi olmayan varlıklar - İlk tahakkuk'");
	String.AddButtonCreate        = True;
	
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.IATransfer;
	String.FullDocumentName           = Metadata.Documents.IATransfer2_4.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Điều chuyển tài sản cố định vô hình';
										|ru = 'Перемещение НМА';
										|en = 'Transfer intangible assets'; fa = 'انتقال دارایی‌های نامشهود';
										|it = 'Trasferimento dei beni immateriali';
										|pl = 'Przemieszczenie wartości niematerialnych';
										|tr = 'GMA transferi'");
	String.AddButtonCreate        = True;
	
	If GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		
		String = BusinessTransactionsAndDocuments.Add();
		String.BusinessOperation        = Enums.BusinessTransactions.TransferIntangibleAssetsToBranchOffice;
		String.FullDocumentName           = Metadata.Documents.IATransfer2_4.FullName();
		String.PurposeUseKey  = PurposeUseKey;
		String.WorkplaceTitle       = NStr("vi = 'Điều chuyển tài sản cố định vô hình';
											|ru = 'Перемещение НМА';
											|en = 'Transfer intangible assets'; fa = 'انتقال دارایی‌های نامشهود';
											|it = 'Trasferimento dei beni immateriali';
											|pl = 'Przemieszczenie wartości niematerialnych';
											|tr = 'GMA transferi'");
		String.AddButtonCreate        = True;
		
	EndIf; 
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.DisposeIntangibleAssets;
	String.FullDocumentName           = Metadata.Documents.DisposeIntangibleAssets2_4.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Ghi giảm TSCĐ vô hình';
										|ru = 'Списание НМА';
										|en = 'Dispose intangible assets'; fa = 'واگذاری دارایی‌های نامشهود';
										|it = 'Cancellazione degli attivi immateriali';
										|pl = 'Wyksięgowanie wartości niematerialnych';
										|tr = 'Maddi olmayan varlık gider yazma'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.PartialIntangibleAssetsDisposal;
	String.FullDocumentName           = Metadata.Documents.DisposeIntangibleAssets2_4.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Ghi giảm một phần tài sản cố định vô hình';
										|ru = 'Частичное списание НМА';
										|en = 'Partial intangible assets disposal'; fa = 'واگذاری جزئی دارایی‌های نامشهود';
										|it = 'Cancellazione parziale del bene immateriale';
										|pl = 'Częściowe wyksięgowanie AN';
										|tr = 'Maddi olmayan varlık gider yazma kısmi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.PreparingForIntangibleAssetSale;
	String.FullDocumentName           = Metadata.Documents.PreparingForIntangibleAssetSale2_4.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Chuẩn bị chuyển nhượng tài sản cố định vô hình';
										|ru = 'Подготовка к передаче НМА';
										|en = 'Retire intangible assets'; fa = 'کنارگذاری دارایی‌های نامشهود';
										|it = 'Preparazione al trasferimento dei Beni immateriali';
										|pl = 'Przygotowanie do przekazania wartości niematerialnych';
										|tr = 'GMA''nın çekilmesi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.ChangeIntangibleAssetFinancialDetails;
	String.FullDocumentName           = Metadata.Documents.ChangeIntangibleAssetFinancialDetails2_4.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Thay đổi tham số TSCĐVH';
										|ru = 'Изменение параметров НМА';
										|en = 'Adjust intangible asset financial details'; fa = 'تعدیل جزئیات مالی دارایی نامشهود';
										|it = 'Modifica dei parametri degli attivi immateriali';
										|pl = 'Zmiana parametrów wartości niematerialnych';
										|tr = 'Maddi olmayan varlık finansal bilgi düzeltmesi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.IARevaluation;
	String.FullDocumentName           = Metadata.Documents.IARevaluation2_4.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Đánh giá lại tài sản cố định vô hình';
										|ru = 'Переоценка НМА';
										|en = 'Revaluate intangible assets'; fa = 'تجدید ارزیابی دارایی‌های نامشهود';
										|it = 'Rivalutazione Beni Immateriali';
										|pl = 'Przeszacowanie wartości niematerialnych';
										|tr = 'GMA yeniden değerlemesi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.IntangibleAssetsOperatingTime;
	String.FullDocumentName           = Metadata.Documents.IntangibleAssetsOperatingTime.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Sản lượng tính cho TSCĐ vô hình';
										|ru = 'Выработка НМА';
										|en = 'Intangible assets — Operating time'; fa = 'دارایی‌های نامشهود — زمان کارکرد';
										|it = 'Produzione bene immateriale';
										|pl = 'Wydajność wartości niematerialnych';
										|tr = 'GMA işlem süresi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.IntangibleAssetsCostAndAmortizationAdjustment;
	String.FullDocumentName			= Metadata.Documents.IntangibleAssetsCostAndAmortizationAdjustment.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	#Region OBEntry
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntryCostOfOwnedIntangibleAssets;
	String.FullDocumentName			= Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = False;
	String = BusinessTransactionsAndDocuments.Add();
	
	String.BusinessOperation 		= Enums.BusinessTransactions.OBEntryInvestmentsInFixedAssets;
	String.FullDocumentName			= Metadata.Documents.EntryOfCapitalAssetsBalance2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = False;
	#EndRegion
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.CompletionOfResearchAndDevelopmentStages;
	String.FullDocumentName			= Metadata.Documents.RDExpenseRecognition.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Ghi nhận chi phí nghiên cứu và phát triển';
										|ru = 'Признание расходов по исследованиям и разработкам';
										|en = 'R&D expense recognition'; fa = 'شناسایی هزینه تحقیق و توسعه';
										|it = 'Riconoscimento delle spese di ricerche e sviluppi';
										|pl = 'Uznanie rozchodów wg badań i opracowań';
										|tr = 'Ar-Ge giderlerinin muhasebeleştirilmesi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.ImpairmentIA;
	String.FullDocumentName			= Metadata.Documents.ImpairmentFA.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Giảm giá trị tài sản dài hạn';
										|ru = 'Обесценение внеоборотных активов';
										|en = 'Fixed asset impairment'; fa = 'کاهش ارزش دارایی ثابت';
										|it = 'Svalutazione attivi non correnti';
										|pl = 'Utrata wartości aktywów nieobrotowych';
										|tr = 'Duran varlıkların değer kaybı'");
	String.AddButtonCreate        = True;

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.IntangibleAssetImprovement;
	String.FullDocumentName			= Metadata.Documents.IntangibleAssetImprovement.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Cải thiện TSCĐ vô hình';
										|ru = 'Улучшение НМА';
										|en = 'Intangible asset improvement'; fa = 'بهبود دارایی نامشهود';
										|it = 'Улучшение НМА';
										|pl = 'Intangible asset improvement';
										|tr = 'GMA''nın iyileştirilmesi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.IncludeAdditionalExpensesInIntangibleAssetCost;
	String.FullDocumentName			= Metadata.Documents.IntangibleAssetImprovement.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.WorkplaceTitle	 	= NStr("vi = 'Đưa chi phí bổ sung vào giá trị TSCĐ vô hình';
										|ru = 'Включение доп. расходов в стоимость НМА';
										|en = 'Include additional expenses in intangible asset cost'; fa = 'گنجاندن هزینه‌های تکمیلی در بهای دارایی نامشهود';
										|it = 'Include additional expenses in intangible asset cost';
										|pl = 'Include additional expenses in intangible asset cost';
										|tr = 'Ek giderlerin maddi olmayan varlık maliyetine dahil edilmesi'");
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation        = Enums.BusinessTransactions.IntangibleAssetsPhysicalCount;
	String.FullDocumentName           = Metadata.Documents.IntangibleAssetsPhysicalCount.FullName();
	String.PurposeUseKey  = PurposeUseKey;
	String.WorkplaceTitle       = NStr("vi = 'Kiểm kê TSCĐVH';
										|ru = 'Инвентаризация НМА';
										|en = 'Intangible assets — Physical inventory'; fa = 'دارایی‌های نامشهود — شمارش فیزیکی موجودی';
										|it = 'Inventario attivi immateriali';
										|pl = 'Inwentaryzacja wartości niematerialnych';
										|tr = 'Maddi olmayan varlıklar - Fiziksel stok'");
	String.AddButtonCreate        = True;
	
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
	
	If PurposeUseKey = "IADocuments" Then
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

&AtServerNoContext
Function InitializeBusinessTransactionsAndDepreciationDocuments(BusinessTransactionsAndDocuments, FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey)
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.IntangibleAssetsAmortizationCharge;
	String.FullDocumentName			= Metadata.Documents.IntangibleAssetsAmortizationCharge2_4.FullName();
	String.PurposeUseKey 	= "IntangibleAssetsAmortizationCharge";
	String.WorkplaceTitle	 	= NStr("vi = 'Khấu hao';
										|ru = 'Амортизация';
										|en = 'Amortization'; fa = 'استهلاک دارایی نامشهود';
										|it = 'Ammortamento';
										|pl = 'Amortization';
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

&AtServerNoContext
Function InitializeBusinessTransactionsAndDocumentsExpenseRecognition(BusinessTransactionsAndDocuments, FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey, FilterCompaniesWithExpenseRecognitionForResearch)
	
	OrganizationsWithResearchRecognition = RDExpensesAccounting.SettingsForRecognizingCompanyResearchExpenses(
		CurrentSessionDate());
	FilterCompaniesWithExpenseRecognitionForResearch.LoadValues(
			CommonClientServer.CollapseArray(OrganizationsWithResearchRecognition.UnloadColumn("Organization")));
			
	If FilterCompaniesWithExpenseRecognitionForResearch.Count()>0 Then
		String = BusinessTransactionsAndDocuments.Add();
		String.BusinessOperation 		= Enums.BusinessTransactions.RecognitionOfResearchExpenses;
		String.FullDocumentName			= Metadata.Documents.RDExpenseRecognition.FullName();
		String.PurposeUseKey 	= "RDExpenseRecognition";
		String.WorkplaceTitle	 	= NStr("vi = 'Ghi nhận chi phí nghiên cứu và phát triển';
											|ru = 'Признание расходов по исследованиям и разработкам';
											|en = 'R&D expense recognition'; fa = 'شناسایی هزینه تحقیق و توسعه';
											|it = 'Riconoscimento delle spese di ricerche e sviluppi';
											|pl = 'Uznanie rozchodów wg badań i opracowań';
											|tr = 'Ar-Ge giderlerinin muhasebeleştirilmesi'");
		String.AddButtonCreate        = True;
	EndIf;

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.CompletionOfResearchAndDevelopmentStages;
	String.FullDocumentName			= Metadata.Documents.RDExpenseRecognition.FullName();
	String.PurposeUseKey 	= "RDExpenseRecognition";
	String.WorkplaceTitle	 	= NStr("vi = 'Ghi nhận chi phí nghiên cứu và phát triển';
										|ru = 'Признание расходов по исследованиям и разработкам';
										|en = 'R&D expense recognition'; fa = 'شناسایی هزینه تحقیق و توسعه';
										|it = 'Riconoscimento delle spese di ricerche e sviluppi';
										|pl = 'Uznanie rozchodów wg badań i opracowań';
										|tr = 'Ar-Ge giderlerinin muhasebeleştirilmesi'");
	String.AddButtonCreate        = True;
	String.HyperlinkCalculationManagerForRegistration = "Document.RDExpenseRecognition";
	
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
Function SelectionsForCreatingDocument()
	
	StructureSelections = New Structure;
	
	If ValueIsFilled(FilterOrganization) Then
		StructureSelections.Insert("Organization", FilterOrganization);
	EndIf;
	
	If Items.GroupPages.CurrentPage = Items.DocumentsDetailsPage Then
		
		If ValueIsFilled(FilterIntangibleAsset) Then
			StructureSelections.Insert("IntangibleAsset", FilterIntangibleAsset);
		EndIf;
		
	ElsIf Items.GroupPages.CurrentPage = Items.PageRecognitionOfResearchAndDevelopmentExpenses 
		And Not FilterTopicStage.IsEmpty() Then
			
		If ValueIsFilled(FilterTopicStage) Then
			StructureSelections.Insert("TopicsStages", CommonClientServer.ValueInArray(FilterTopicStage));
		EndIf;
		
	EndIf;
	
	Return StructureSelections;
	
EndFunction

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	SetCompletionIntervalOnServer();
	
EndProcedure

&AtClient
Procedure AListOfTheExpensesToSetTheIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	SetCompletionIntervalOnServer();
	
	StartUpdatingDataInBackground();
	
EndProcedure

&AtServer
Procedure SetCompletionIntervalOnServer()
	
	SetDynamicListSelections_();
	
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
	
	#Region ToRegistrationAcceptanceForAccounting
	TimeConsumingOperation = UpdateForRegistrationAcceptanceForAccounting();
	
	CallbackOnCompletion = New CallbackDescription("UpdateForRegistrationAcceptanceForAccountingCompletion", ThisObject);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	#EndRegion
	
	#Region ToDesignOfStudy
	TimeConsumingOperation = UpdateToDesignOfStudy();
	
	CallbackOnCompletion = New CallbackDescription("UpdateToDesignOfStudyCompletion", ThisObject);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	#EndRegion
	
EndProcedure

&AtServer
Function UpdateForRegistrationAcceptanceForAccounting()

	FunctionParameters = New Structure;
	FunctionParameters.Insert("Organization", FilterOrganization);

	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, "DataProcessors.JournalOfIADocuments2_4.WorkplaceData", FunctionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		TextIsUpdatingData = NStr("vi = 'Cần lập: <dữ liệu đang được cập nhật>';
									|ru = 'К оформлению: <идет обновление данных>';
									|en = 'To register: <updating data>'; fa = 'To register: <updating data>';
									|it = 'Da formalizzare: <dati in fase di aggiornamento>';
									|pl = 'Do rejestracji: <odbywa się aktualizacja danych>';
									|tr = 'Düzenlenecek: <veri güncellemesi devam ediyor>'");
		ToRegister = New FormattedString(TextIsUpdatingData);
	EndIf;

	Return TimeConsumingOperation;
	
EndFunction

&AtServer
Function UpdateToDesignOfStudy()

	CurrentDate = CurrentSessionDate();

	GenerationParameters = New Structure;
	GenerationParameters.Insert("Organization", FilterOrganization);
	GenerationParameters.Insert("ThisIsHyperlinkCalculation", True);
	GenerationParameters.Insert("OnlyRegistrationOfDocuments", True);
	GenerationParameters.Insert("BeginOfPeriod", ?(ValueIsFilled(ListExpenseRecognitionInterval.EndDate), BegOfMonth(ListExpenseRecognitionInterval.EndDate), BegOfMonth(CurrentDate)));
	GenerationParameters.Insert("EndOfPeriod", ?(ValueIsFilled(ListExpenseRecognitionInterval.EndDate), ListExpenseRecognitionInterval.EndDate, EndOfMonth(CurrentDate)));
	GenerationParameters.Insert("BriefPresentation", True);
	
	FunctionParameters = New Array;
	FunctionParameters.Add(BusinessTransactionsAndDocumentsRecognitionOfExpenses.Unload());
	FunctionParameters.Add(GenerationParameters);

	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, "DataProcessors.JournalOfIADocuments2_4.CreateHyperlinkToBackgroundTaskLayout", FunctionParameters);
	
	If TimeConsumingOperation.Status = "Running" Then
		TextIsUpdatingData = NStr("vi = 'Cần lập: <dữ liệu đang được cập nhật>';
									|ru = 'К оформлению: <идет обновление данных>';
									|en = 'To register: <updating data>'; fa = 'To register: <updating data>';
									|it = 'Da formalizzare: <dati in fase di aggiornamento>';
									|pl = 'Do rejestracji: <odbywa się aktualizacja danych>';
									|tr = 'Düzenlenecek: <veri güncellemesi devam ediyor>'");
		ToDesignOfStudy = New FormattedString(TextIsUpdatingData);
	EndIf;

	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure UpdateForRegistrationAcceptanceForAccountingCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
			
	UpdateForRegistrationAcceptanceForRegistrationEndOnServer(Result.ResultAddress);
	
EndProcedure 

&AtServer
Procedure UpdateForRegistrationAcceptanceForRegistrationEndOnServer(Val ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);

	If ValueIsFilled(Result) Then
		ToRegistrationAcceptanceForAccounting = New FormattedString(Result);
		Items.ToRegistrationAcceptanceForAccounting.Visible = Items.List.Visible;
		Items.ToRegistrationAcceptanceForAccountingInDetail.Visible = Items.ListDetailed.Visible;
	Else
		Items.ToRegistrationAcceptanceForAccounting.Visible = False;
		Items.ToRegistrationAcceptanceForAccounting.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateToDesignOfStudyCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
			
	UpdateToDesignOfStudyEndOnServer(Result.ResultAddress);
	
EndProcedure 

&AtServer
Procedure UpdateToDesignOfStudyEndOnServer(Val ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);

	If ValueIsFilled(Result) Then
		ToDesignOfStudy = New FormattedString(Result);
		Items.ToDesignOfStudy.Visible = Items.ListRDExpensesRecognition.Visible;
	Else
		Items.ToDesignOfStudy.Visible = False;
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
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "ListRDExpensesRecognition";
	ListParameterStructure.PlacementGroupSettings = Items.DocumentListSettingsGroupExpenseRecognition;
	ListParameterStructure.AttributeNameAutoUpdateMode = "ListOfDocumentsCostRecognitionAutoRenewalMode";
	ListParameterStructure.NameOfListUpdateCommands = Commands.ListOfDocumentsCostRecognitionUpdate.Name;
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