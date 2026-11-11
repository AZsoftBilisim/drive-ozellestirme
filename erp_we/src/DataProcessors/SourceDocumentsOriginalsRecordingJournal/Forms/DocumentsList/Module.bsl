///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2021, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	SetConditionalAppearance();
	
	
	DataCompositionClientServer.SetParameter(
		DocumentsList.SettingsComposer.Settings,
		"TextContractWithCounterparty",
		NStr("vi = 'Hợp đồng với đối tác';
			|ru = 'Договор с контрагентом';
			|en = 'Contract'; fa = 'قرارداد';
			|it = 'Contratto con la controparte';
			|pl = 'Umowa z kontrahentem';
			|tr = 'Cari hesap sözleşmesi'"));
	
	DataCompositionClientServer.SetParameter(
		DocumentsList.SettingsComposer.Settings,
		"CounterpartyContractsCatalogName",
		Metadata.Catalogs.CounterpartyContracts.FullName());
	
	FillInResponsibleSelectionList();
	
	FillOriginalStateSelectionList();
	
	FilterState = NStr("vi = '<Trạng thái đã biết>';
						|ru = '<Состояние известно>';
						|en = '<Known state>'; fa = '<Known state>';
						|it = '<Stato noto>';
						|pl = '<Status jest znany>';
						|tr = '<Durum bellidir>'");
	
	ListDisplay = "ByDocuments";
	
	URL = "e1cib/app/DataProcessor.SourceDocumentsOriginalsRecordingJournal";
	
	RestoreSettings();
	
	SetListSelections();
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.DocumentsListCommandBar;
	PlacementParameters.Sources = DataProcessors.SourceDocumentsOriginalsRecordingJournal.ObjectsWithSourceDocumentsOriginalsAccounting();
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecording.OnCreateAtServerListForm(ThisObject, Items.DocumentsList, Items.DocumentsListSum);
	SourceDocumentsOriginalsRecording.SetConditionalAppearanceInListForm(ThisObject, Items.DocumentsList);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	UsePeripherals = True;
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OnConnectBarcodeScanner(ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure OnClose(Exit)

	If Not Exit Then
		ShouldSaveSettings();
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	If EventName = "Write_SourceDocumentsOriginalsStates" Then
		FillOriginalStateSelectionList();
	EndIf;
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.ProcessBarcode(Parameter,EventName);
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerListForm(EventName, ThisObject, Items.DocumentsList);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)

	SetListSelections()

EndProcedure

&AtClient
Procedure FilterChangeAuthorOnChange(Item)

	SetListSelections()

EndProcedure

&AtClient
Procedure ListDisplayOnChange(Item)

	DisplayingListWhenChangingOnServer();

EndProcedure

&AtClient
Procedure FilterStateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;

	OpenForm("Catalog.SourceDocumentsOriginalsStates.Form.StateChoiceForm",New Structure("StatesList", FilterOriginalStates),Item);

EndProcedure

&AtClient
Procedure FilterStateChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	SetSelectionByOriginalState(ValueSelected);
	
EndProcedure

&AtClient
Procedure FilterStateClearing(Item, StandardProcessing)

	FilterOriginalStates.Clear();
	CommonClientServer.DeleteDynamicListFilterGroupItems(DocumentsList,"SourceDocumentOriginalState");

EndProcedure

&AtClient
Procedure FilterStateOnChange(Item)
	
	SetSelectionByOriginalState(FilterState);
	
EndProcedure

&AtClient
Procedure HelpTextFilterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("SetSelectionByDocumentTypeCompletion", ThisObject);
	OpenForm("DataProcessor.SourceDocumentsOriginalsRecordingJournal.Form.DocumentsKindsFilterSettingForm",New Structure("FilterDocumentsKinds",FilterDocumentsKinds),
		ThisObject,,,,Notification);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDocumentsList

&AtClient
Procedure DocumentsListSelection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False; 
	If Field.Name = "SourceDocumentOriginalState" Or Field.Name = "StateOriginalReceived" Then
		SourceDocumentsOriginalsRecordingClient.ListSelection(Field.Name,ThisObject,Items.DocumentsList,StandardProcessing);
	Else
		// Opening the document
		OpenDocument();
	EndIf;

EndProcedure

&AtClient
Procedure DocumentsListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
    AttachableCommandsClient.StartCommandUpdate(ThisObject);
    // End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenDocumentCommand(Command)

	OpenDocument();

EndProcedure

&AtClient
Procedure SetDateInterval(Command)

	Dialog = New StandardPeriodEditDialog();
	Dialog.Period = Period;
	Dialog.Show(New CallbackDescription("SetDateIntervalCompletion", ThisObject, New Structure("Dialog", Dialog)));

EndProcedure

// StandardSubsystems.SourceDocumentsOriginalsRecording

// Parameters:
//  Command - FormCommand
//
&AtClient
Procedure Attachable_SetOriginalState(Command)
	
	SourceDocumentsOriginalsRecordingClient.SetOriginalState(Command.Name,ThisObject,Items.DocumentsList);

EndProcedure

&AtClient
Procedure Attachable_UpdateOriginalStateCommands()
	
	UpdateOriginalStateCommands()
	
EndProcedure
//End StandardSubsystems.SourceDocumentsOriginalsRecording

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.DocumentsList);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.DocumentsList);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
		"DocumentsList.IBDocumentDate",
		"DocumentsListIBDocumentDate");
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject,
		"DocumentsList.SourceDocumentDate",
		"DocumentsListSourceDocumentDate");

	Item = DocumentsList.ConditionalAppearance.Items.Add();

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.Use  = True;
	FilterGroup.GroupType  = DataCompositionFilterItemsGroupType.OrGroup;

	FilterElement = FilterGroup.Items.Add(Type("DataCompositionFilterItem")); 
	FilterElement.Use = True;
	FilterElement.LeftValue = New DataCompositionField("OverallState"); 
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterElement = FilterGroup.Items.Add(Type("DataCompositionFilterItem")); 
	FilterElement.Use = True;
	FilterElement.LeftValue = New DataCompositionField("OverallState");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = True;

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("IndentField1");

	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = DocumentsList.ConditionalAppearance.Items.Add();

	FilterElement = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("OverallState");
	FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
	FilterElement.RightValue =True;
	FilterElement.Use = True;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.AuxiliaryNavigationColor);

	If GetFunctionalOption("UseMultipleCompanies")= False Then
		Items.FilterOrganization.Visible = False;
	EndIf;
	
	If GetFunctionalOption("UsePartnersAndCounterparties")= False Then
		Items.DocumentsListCounterparty.Visible = False;
	EndIf;

EndProcedure

&AtServer
Procedure RestoreSettings()

	Settings = Common.CommonSettingsStorageLoad("DataProcessor.SourceDocumentsOriginalsRecordingJournal.Form.Form", "SourceDocumentOriginals");

	If TypeOf(Settings) = Type("Structure") Then
		If Settings.Property("FilterDocumentsKinds") Then
			FilterDocumentsKinds = Settings.FilterDocumentsKinds;
		EndIf;
		If Settings.Property("FilterOrganization") Then
			FilterOrganization = Settings.FilterOrganization;
		EndIf;
		If Settings.Property("FilterChangeAuthor") Then
			FilterChangeAuthor = Settings.FilterChangeAuthor;
		EndIf;
		If Settings.Property("FilterState") Then
			FilterState = Settings.FilterState;
		EndIf;
		If Settings.Property("DocumentsCount") Then
			DocumentsCount = Settings.DocumentsCount;
		EndIf;
		If Settings.Property("FilterOriginalStates") Then
			PastSelectionOfOriginalState = Settings.FilterOriginalStates; 
		EndIf;
		If Settings.Property("ListDisplay") Then
			ListDisplay = Settings.ListDisplay;
		EndIf;

		// Restoring the selection list by state
		If ValueIsFilled(PastSelectionOfOriginalState) Then
			For Each State In PastSelectionOfOriginalState Do
				FilterOriginalStates.Add(State.Value, State.Presentation);
			EndDo;
		EndIf;
	
	Else
	// If there are no saved settings, fill in the list for selection by type of documents
		FillInitialSelectionListOfDocumentTypes();
		FilterState = NStr("vi = '<Trạng thái đã biết>';
							|ru = '<Состояние известно>';
							|en = '<Known state>'; fa = '<Known state>';
							|it = '<Stato noto>';
							|pl = '<Status jest znany>';
							|tr = '<Durum bellidir>'");		
	EndIf;

EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.DocumentsList);
EndProcedure

&AtServer
Procedure UpdateOriginalStateCommands()
	
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.DocumentsListCommandBar;
	PlacementParameters.Sources = DataProcessors.SourceDocumentsOriginalsRecordingJournal.ObjectsWithSourceDocumentsOriginalsAccounting();
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export

	If Not ValueSelected = Undefined Then
		TitleText = NStr("vi = 'Nhật ký chứng từ gốc';
						|ru = 'Журнал учета оригиналов первичных документов';
						|en = 'Source document tracking log'; fa = 'گزارش ردیابی اسناد مبدأ';
						|it = 'Registro contabile degli originali dei documenti primari';
						|pl = 'Dziennik ewidencji oryginałów dokumentów podstawowych';
						|tr = 'Birincil belgelerin asıllarının muhasebe günlüğü'")+ " ";
		DateTemplate = NStr("vi = 'DF=%Couples1%';
							|ru = 'ДФ=%Couples1%';
							|en = 'DF=%Couples1%'; fa = 'DF=%Couples1%';
							|it = 'DF=%Couples1%';
							|pl = 'DF=%Couples1%';
							|tr = 'DF=%Couples1%'");
		DateTemplate = StrReplace(DateTemplate, "%Couples1%", "dd.MM.yy");
		Values = New Structure("StartDate, EndDate",Format(ValueSelected.StartDate,DateTemplate), Format(ValueSelected.EndDate,DateTemplate));
		If Not ValueIsFilled(ValueSelected) Then
			Title = TitleText;
		ElsIf Not ValueIsFilled(ValueSelected.StartDate) Then
			Title = TitleText +StringFunctionsClientServer.InsertParametersIntoString(NStr("vi = '(đến [EndDate])';
																							|ru = '(по [EndDate])';
																							|en = '(to [EndDate])'; fa = '(to [EndDate])';
																							|it = '(al [EndDate])';
																							|pl = '(do [EndDate])';
																							|tr = '([EndDate] göre)'"), Values);
		ElsIf Not ValueIsFilled(ValueSelected.EndDate)Then
			Title = TitleText +StringFunctionsClientServer.InsertParametersIntoString(NStr("vi = '(từ [StartDate])';
																							|ru = '(с [StartDate])';
																							|en = '(from [StartDate])'; fa = '(from [StartDate])';
																							|it = '(dal  [StartDate])';
																							|pl = '(od [StartDate])';
																							|tr = '([StartDate] ile)'"), Values);
		ElsIf ValueSelected.Variant = StandardPeriodVariant.Today Or ValueSelected.Variant = StandardPeriodVariant.Yesterday 
			Or  ValueSelected.Variant = StandardPeriodVariant.Tomorrow Then
			Title = TitleText +StringFunctionsClientServer.InsertParametersIntoString(NStr("vi = '([StartDate])';
																							|ru = '([StartDate])';
																							|en = '([StartDate])'; fa = '([StartDate])';
																							|it = '([StartDate])';
																							|pl = '([StartDate])';
																							|tr = '([StartDate])'"), Values);
		Else
			Title = TitleText +StringFunctionsClientServer.InsertParametersIntoString(NStr("vi = '(từ [StartDate] đến [EndDate])';
																							|ru = '(с [StartDate] по [EndDate])';
																							|en = '(from [StartDate] to [EndDate])'; fa = '(from [StartDate] to [EndDate])';
																							|it = '(dal [StartDate] al [EndDate])';
																							|pl = '(od [StartDate] do [EndDate])';
																							|tr = '([StartDate] itibaren [EndDate] kadar)'"), Values);
		EndIf;

		Period = ValueSelected;

		SetSelectionByPeriod();
	EndIf;

EndProcedure

&AtServer
Procedure ShouldSaveSettings()

	AttributesToSaveNames =
		"FilterDocumentsKinds,
		|FilterOrganization,
		|FilterChangeAuthor,
		|FilterState,
		|DocumentsCount,
		|FilterOriginalStates,
		|ListDisplay";

	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisObject);

	Common.CommonSettingsStorageSave("DataProcessor.SourceDocumentsOriginalsRecordingJournal.Form.Form", "SourceDocumentOriginals",Settings);

EndProcedure

&AtClient
Procedure OpenDocument()

	If Items.DocumentsList.SelectedRows = Undefined Then
		ShowMessageBox(, NStr("vi = 'Chưa chọn chứng từ nào.';
								|ru = 'Не выделено ни одного документа.';
								|en = 'No document is selected.'; fa = 'No document is selected.';
								|it = 'Nessun documento evidenziato.';
								|pl = 'Nie wybrano żadnego dokumentu.';
								|tr = 'Hiçbir belge seçilmedi.'"));
		Return;
	EndIf;
		
	For Each ListLine In Items.DocumentsList.SelectedRows Do
		Document = Items.DocumentsList.RowData(ListLine);
		ShowValue(,Document.Ref);
	EndDo;

EndProcedure

#Region Filters

&AtServer
Procedure FillInResponsibleSelectionList()

	SetPrivilegedMode(True);

	UsersArray = InfoBaseUsers.GetUsers();

	Items.FilterChangeAuthor.ChoiceList.Clear();
	Items.FilterChangeAuthor.ChoiceList.Add(Users.CurrentUser(),NStr("vi = '<Ghi chép của tôi>';
																	|ru = '<Мои записи>';
																	|en = '<My records>'; fa = '<My records>';
																	|it = '<Le mie scritture>';
																	|pl = '<Moje wpisy>';
																	|tr = '<Kayıtlarım>'"));

	For Each User In UsersArray Do

		If User.Roles.Contains(Metadata.Roles.SourceDocumentsOriginalsStatesChange) 
			And Not Users.CurrentUser() = Users.FindByName(User.Name) Then
			FoundUser =Users.FindByName(User.Name);
			Items.FilterChangeAuthor.ChoiceList.Add(FoundUser);
		EndIf;

	EndDo;

	SetPrivilegedMode(False);

EndProcedure

&AtServer
Procedure FillOriginalStateSelectionList()

	OriginalStates = SourceDocumentsOriginalsRecording.AllStates();
	
	Items.FilterState.ChoiceList.Clear();
	For Each State In OriginalStates Do
		Items.FilterState.ChoiceList.Add(State);
	EndDo;
	Items.FilterState.ChoiceList.Add("Statesknown",NStr("vi = '<Trạng thái đã biết>';
														|ru = '<Состояние известно>';
														|en = '<Known state>'; fa = '<Known state>';
														|it = '<Stato noto>';
														|pl = '<Status jest znany>';
														|tr = '<Durum bellidir>'"));
	Items.FilterState.ChoiceList.Add("Statesnotable",NStr("vi = '<Trạng thái đã biết>';
															|ru = '<Состояние неизвестно>';
															|en = '<Unknown state>'; fa = '<Unknown state>';
															|it = '<Stato sconosciuto>';
															|pl = '<Nieznany status>';
															|tr = '<Durum belirsiz>'"));
	
EndProcedure

&AtServer
Procedure FillInitialSelectionListOfDocumentTypes() 

	DocumentsKindsTable.Clear();

	AvailableTypes = DataProcessors.SourceDocumentsOriginalsRecordingJournal.ObjectsWithSourceDocumentsOriginalsAccounting();
	DocumentNames = New Array;
	For Each Type In AvailableTypes.Types() Do
		DocumentType = Metadata.FindByType(Type);
		DocumentNames.Add(DocumentType.FullName());
	EndDo;
	
	Query = New Query;
	Query.Text = "SELECT
	               |	MetadataObjectIDs.FullName AS FullName,
	               |	MetadataObjectIDs.Synonym AS Synonym,
	               |	MetadataObjectIDs.Ref AS Ref
	               |FROM
	               |	Catalog.MetadataObjectIDs AS MetadataObjectIDs
	               |WHERE
	               |	MetadataObjectIDs.FullName IN(&DocumentNames)";
	Query.SetParameter("DocumentNames",DocumentNames);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Filter = New Structure("Presentation", Selection.Synonym);
		FoundRows = DocumentsKindsTable.FindRows(Filter);
		If FoundRows.Count()= 0 Then
			NewRow = DocumentsKindsTable.Add();
			NewRow.DocumentKind = Selection.Ref;
			NewRow.Presentation = Selection.Synonym;
			NewRow.Filter = True;
		EndIf;
	EndDo;
	
	//checking the FO of sales
	If Not GetFunctionalOption("UseTransferToCustodyWithRightOfSale")
		And Not GetFunctionalOption("UseProductionByThirdParty2_5")
		And Not GetFunctionalOption("UseTollManufacturing2_5")
		And Not GetFunctionalOption("UseCustodyDuringPurchase") Then
		LinesToDelete = DocumentsKindsTable.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "TransferOfGoodsToBailee")));
																
		For Each RowToDelete In LinesToDelete Do
			DocumentsKindsTable.Delete(RowToDelete);
		EndDo;
		
		LinesToDelete = DocumentsKindsTable.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "RedemptionOfGoodsFromStorage")));
																
		For Each RowToDelete In LinesToDelete Do
			DocumentsKindsTable.Delete(RowToDelete);
		EndDo;

	EndIf;
	
	If Not GetFunctionalOption("UseCreditNotes") Then
		LinesToDelete = DocumentsKindsTable.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "SaleAdjustment")));
																
		For Each RowToDelete In LinesToDelete Do
			DocumentsKindsTable.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	If Not GetFunctionalOption("UseReportsOfDiscrepanciesAfterShipment") Then
		LinesToDelete = DocumentsKindsTable.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "DiscrepancyReportFollowingShipment")));
																
		For Each RowToDelete In LinesToDelete Do
			DocumentsKindsTable.Delete(RowToDelete);
		EndDo;
	EndIf;

	//FO of production

	
	If Not GetFunctionalOption("UseTollManufacturing2_5") Then
		
		LinesToDelete = DocumentsKindsTable.FindRows(
			New Structure(
					"DocumentKind",
					Catalogs.MetadataObjectIDs.FindByAttribute("Name", "ReportToMaterialProvider2_5")));
		
		For Each RowToDelete In LinesToDelete Do
			DocumentsKindsTable.Delete(RowToDelete);
		EndDo;
		
	EndIf;
	//
	//Purchasing information
	If Not GetFunctionalOption("UseDebitNotes") Then
		LinesToDelete = DocumentsKindsTable.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "PurchaseAdjustment")));
																
		For Each RowToDelete In LinesToDelete Do
			DocumentsKindsTable.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	If Not GetFunctionalOption("UseNonConformanceCertificatesFollowingAcceptance") Then
		LinesToDelete = DocumentsKindsTable.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "DiscrepancyReportFollowingReceipt")));
																
		For Each RowToDelete In LinesToDelete Do
			DocumentsKindsTable.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	//FO of internal documents
	If Not GetFunctionalOption("UseGoodsTransfer") Then
		LinesToDelete = DocumentsKindsTable.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "InventoryTransfer")));
																
		For Each RowToDelete In LinesToDelete Do
			DocumentsKindsTable.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	If Not GetFunctionalOption("UseNonConformanceCertificatesFollowingTransfer") Then
		LinesToDelete = DocumentsKindsTable.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "DiscrepancyReportFollowingTransfer")));
																
		For Each RowToDelete In LinesToDelete Do
			DocumentsKindsTable.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	
	//FO documents between organizations
	If Not GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		LinesToDelete = DocumentsKindsTable.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "IntercompanyGoodsReturn")));
																
		For Each RowToDelete In LinesToDelete Do
			DocumentsKindsTable.Delete(RowToDelete);
		EndDo;
		
		LinesToDelete = DocumentsKindsTable.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "CommissionReportIntercompany")));
																
		For Each RowToDelete In LinesToDelete Do
			DocumentsKindsTable.Delete(RowToDelete);
		EndDo;
		
		LinesToDelete = DocumentsKindsTable.FindRows(New Structure("DocumentKind",																	
			Catalogs.MetadataObjectIDs.FindByAttribute("Name", "CustomerInvoiceIntercompany")));
																
		For Each RowToDelete In LinesToDelete Do
			DocumentsKindsTable.Delete(RowToDelete);
		EndDo;
	EndIf;
	
	FilterDocumentsKinds.Clear();
	
	For Each DocumentKind In DocumentsKindsTable Do
		If DocumentKind.Filter = True Then
			FilterDocumentsKinds.Add(DocumentKind.DocumentKind,DocumentKind.Presentation);
		EndIf;
	EndDo;

	If FilterDocumentsKinds.Count() = 0 Then
		For Each DocumentKind In DocumentsKindsTable Do
			FilterDocumentsKinds.Add(DocumentKind.DocumentKind,DocumentKind.Presentation);
		EndDo;
	EndIf;
	
	DocumentsCount = FilterDocumentsKinds.Count(); 
EndProcedure

&AtServer
Procedure SetListSelections()

	CommonClientServer.SetDynamicListFilterItem(DocumentsList,"Organization",FilterOrganization,
		DataCompositionComparisonType.Equal,,ValueIsFilled(FilterOrganization));

	CommonClientServer.SetDynamicListFilterItem(DocumentsList,"ChangeAuthor",FilterChangeAuthor,
		DataCompositionComparisonType.Equal,,ValueIsFilled(FilterChangeAuthor));

	SetSelectionByDocumentType(FilterDocumentsKinds);
	
	DisplayingListWhenChangingOnServer();

	SetSelectionByOriginalState();
	
EndProcedure

&AtClient
Procedure SetSelectionByDocumentTypeCompletion(Result, AdditionalParameters = Undefined) Export
	
	SetSelectionByDocumentType(Result);
	
EndProcedure	
	
&AtServer
Procedure SetSelectionByDocumentType(Result)

	CommonClientServer.DeleteDynamicListFilterGroupItems(DocumentsList,"RefType");
	
	If ValueIsFilled(Result) Then
		If TypeOf(Result) = Type("Structure") Then 
			Array = New Array;
			DocumentsCount = Result.DocumentsCount;
			For Each Filter In Result.FilterDocumentsKinds Do
				Array.Add(Filter.Value);
			EndDo;
		Else	
			Array = New Array;
			For Each Filter In Result Do
				Array.Add(Filter.Value);
			EndDo;
		EndIf;
		
		FilterDocumentsKinds.LoadValues(Array);
				
		CommonClientServer.SetDynamicListFilterItem(DocumentsList,"RefType",FilterDocumentsKinds,
			DataCompositionComparisonType.InList,,True);

		If FilterDocumentsKinds.Count() = DocumentsCount Or FilterDocumentsKinds.Count()= 0 Then
			Template = NStr("vi = 'Hiển thị tất cả chứng từ trong nhật ký <a href=""%Couples1%"">Tùy chỉnh</a>';
							|ru = 'Показаны все документы журнала <a href=""%Couples1%"">Настроить</a>';
							|en = 'Showing all log documents <a href=""%Couples1%"">Configure</a>'; fa = 'Showing all log documents <a href=""%Couples1%"">Configure</a>';
							|it = 'Показаны все документы журнала <a href=""%Couples1%"">Настроить</a>';
							|pl = 'Showing all log documents <a href=""%Couples1%"">Configure</a>';
							|tr = 'Tüm defter belgeleri gösterildi <a href=""%Couples1%"">Ayarla</a>'");
			Template = StrReplace(Template, "%Couples1%", "ConfigureFilter");
			Items.HelpTextFilter.Title = StringFunctions.FormattedString(Template);
		Else	
			LabelText = StringFunctionsClientServer.StringWithNumberForAnyLanguage(NStr("vi = ';Đã hiển thị %1 chứng từ trong nhật ký;;
			|Đã hiển thị %1 chứng từ trong nhật ký;Đã hiển thị %1 chứng từ trong nhật ký;';
			|ru = ';Показан %1 документ журнала;;
			|Показано %1 документа журнала;Показано %1 документов журнала;';
			|en = ';%1 log document is displayed;;
			|%1 log documents are displayed;%1 log documents are displayed;'; fa = ';%1 log document is displayed;;
			|%1 log documents are displayed;%1 log documents are displayed;';
			|it = ';Visualizzato %1 documento del registro;; 
			|Visualizzato %1 del documento del registro; Visualizzato %1 documenti del registro;';
			|pl = ';Pokazano %1 dokument dziennika;;
			|Pokazano %1 dokumenty dzennika;Pokazano %1 dokumentów dziennika;';
			|tr = ';Gösterildi %1 defter belgesi;;
			| Gösterildi %1defter belgesi;Gösterildi %1 defter belgesi;'"),FilterDocumentsKinds.Count());
			Template = NStr("vi = '<a href=""%Couples1%"">Tùy chỉnh</a>';
							|ru = '<a href=""%Couples1%"">Настроить</a>';
							|en = '<a href=""%Couples1%"">Configure</a>'; fa = '<a href=""%Couples1%"">Configure</a>';
							|it = '<a href=""%Couples1%"">Настроить</a>';
							|pl = '<a href=""%Couples1%"">Configure</a>';
							|tr = '<a href=""%Couples1%"">Ayarla</a>'");
			Template = StrReplace(Template, "%Couples1%", "ConfigureFilter");
			Items.HelpTextFilter.Title = StringFunctions.FormattedString(LabelText + " " +Template);
		EndIf;

	Else
		If Not DocumentsKindsTable.Count() = 0 Then
			Array = New Array;
			For Each Filter In DocumentsKindsTable Do
				Array.Add(Filter.DocumentKind);
			EndDo; 
		FilterDocumentsKinds.Clear();
		FilterDocumentsKinds.LoadValues(Array);
		
		Template = NStr("vi = 'Hiển thị tất cả chứng từ trong nhật ký <a href=""%Couples1%"">Tùy chỉnh</a>';
						|ru = 'Показаны все документы журнала <a href=""%Couples1%"">Настроить</a>';
						|en = 'Showing all log documents <a href=""%Couples1%"">Configure</a>'; fa = 'Showing all log documents <a href=""%Couples1%"">Configure</a>';
						|it = 'Показаны все документы журнала <a href=""%Couples1%"">Настроить</a>';
						|pl = 'Showing all log documents <a href=""%Couples1%"">Configure</a>';
						|tr = 'Tüm defter belgeleri gösterildi <a href=""%Couples1%"">Ayarla</a>'");
		Template = StrReplace(Template, "%Couples1%", "ConfigureFilter");
		Items.HelpTextFilter.Title = StringFunctions.FormattedString(Template)

		EndIf;
			CommonClientServer.SetDynamicListFilterItem(DocumentsList,"RefType",FilterDocumentsKinds,
			DataCompositionComparisonType.InList,,True);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionByOriginalState(ValueSelected = Undefined)

	FilterState = "";

	If ValueSelected=Undefined And FilterOriginalStates.Count()>1 Then 
		For Each State In FilterOriginalStates Do
			If State.Value = "Statesnotable" Then
				Unknowns = True;
			EndIf;
			FilterState = FilterState + ?(ValueIsFilled(FilterState), ", ", "")+ ?(IsBlankString(State.Presentation), State.Value, State.Presentation);
		EndDo;
			
	ElsIf ValueSelected=Undefined And FilterOriginalStates.Count()=1 Then
		FilterState = ?(IsBlankString(FilterOriginalStates[0].Presentation),FilterOriginalStates[0].Value, FilterOriginalStates[0].Presentation);
		If FilterOriginalStates[0].Value = "Statesnotable" Then
			CommonClientServer.SetDynamicListFilterItem(DocumentsList,"SourceDocumentOriginalState",,
				DataCompositionComparisonType.NotFilled,,ValueIsFilled(FilterState));
			Return;
		ElsIf FilterOriginalStates[0].Value = "Statesknown" Then
			CommonClientServer.SetDynamicListFilterItem(DocumentsList,"SourceDocumentOriginalState",,
				DataCompositionComparisonType.Filled,,ValueIsFilled(FilterState));
			Return; 			
		EndIf;
		
	ElsIf TypeOf(ValueSelected) = Type("ValueList") Then
		FilterOriginalStates.Clear();
		CheckingForAllEmptyMarks = 0;
		For Each State In ValueSelected Do
			If State.Check Then
				If State.Value = "Statesnotable" Then
					Unknowns = True;
					FilterOriginalStates.Add(State.Value, State.Presentation);
					FilterState = FilterState + ?(ValueIsFilled(FilterState), ", ", "")+ State.Presentation;
				Else
					FilterOriginalStates.Add(State.Value, State.Presentation);
					FilterState = FilterState + ?(ValueIsFilled(FilterState), ", ", "")+ State.Value;
				EndIf;
			Else
				CheckingForAllEmptyMarks = CheckingForAllEmptyMarks + 1; 
			EndIf;
			
		EndDo;
		If CheckingForAllEmptyMarks = ValueSelected.Count() Then
			Unknowns = True;
			For Each State In ValueSelected Do
				FilterOriginalStates.Add(State.Value, State.Presentation);
			EndDo;
		EndIf;
	Else 
		FilterOriginalStates.Clear();
		If Not ValueSelected=Undefined Then
			If ValueSelected = "Statesnotable" Then 
				FilterOriginalStates.Add(ValueSelected,NStr("vi = '<Trạng thái đã biết>';
															|ru = '<Состояние неизвестно>';
															|en = '<Unknown state>'; fa = '<Unknown state>';
															|it = '<Stato sconosciuto>';
															|pl = '<Nieznany status>';
															|tr = '<Durum belirsiz>'"));
				FilterState = NStr("vi = '<Trạng thái đã biết>';
									|ru = '<Состояние неизвестно>';
									|en = '<Unknown state>'; fa = '<Unknown state>';
									|it = '<Stato sconosciuto>';
									|pl = '<Nieznany status>';
									|tr = '<Durum belirsiz>'");
			ElsIf ValueSelected = "Statesknown" Then
				FilterOriginalStates.Add(ValueSelected,NStr("vi = '<Trạng thái đã biết>';
															|ru = '<Состояние известно>';
															|en = '<Known state>'; fa = '<Known state>';
															|it = '<Stato noto>';
															|pl = '<Status jest znany>';
															|tr = '<Durum bellidir>'"));
				FilterState = NStr("vi = '<Trạng thái đã biết>';
									|ru = '<Состояние известно>';
									|en = '<Known state>'; fa = '<Known state>';
									|it = '<Stato noto>';
									|pl = '<Status jest znany>';
									|tr = '<Durum bellidir>'");
			Else
				FilterOriginalStates.Add(ValueSelected);
				FilterState = ValueSelected;
			EndIf;
		EndIf;
		
		If ValueSelected = "Statesnotable" Or FilterState = "Statesnotable" Then
			CommonClientServer.SetDynamicListFilterItem(DocumentsList,"SourceDocumentOriginalState",,
				DataCompositionComparisonType.NotFilled,,ValueIsFilled(FilterState));
			Return;
		ElsIf ValueSelected = "Statesknown" Or FilterState = "Statesknown" Then
				CommonClientServer.SetDynamicListFilterItem(DocumentsList,"SourceDocumentOriginalState",,
			DataCompositionComparisonType.Filled,,ValueIsFilled(FilterState));
			Return;
		EndIf;
	EndIf;

	If Unknowns = True Then
		
		CommonClientServer.DeleteDynamicListFilterGroupItems(DocumentsList,"SourceDocumentOriginalState");
		
		FilterGroup = DocumentsList.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.Use  = True;
		FilterGroup.GroupType  = DataCompositionFilterItemsGroupType.OrGroup;
		
		FilterElement = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.Use = True;
		FilterElement.LeftValue = New DataCompositionField("SourceDocumentOriginalState");; 
		FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;

		FilterElement = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.Use = True;
		FilterElement.LeftValue = New DataCompositionField("SourceDocumentOriginalState");
		FilterElement.ComparisonType = DataCompositionComparisonType.InList;
		FilterElement.RightValue = FilterOriginalStates;
		
	ElsIf ValueIsFilled(FilterState) Then
		CommonClientServer.SetDynamicListFilterItem(DocumentsList,"SourceDocumentOriginalState",FilterOriginalStates,
			DataCompositionComparisonType.InList,,ValueIsFilled(FilterState));	
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayingListWhenChangingOnServer()

	// We reset the selection according to the general condition
	CommonClientServer.DeleteDynamicListFilterGroupItems(DocumentsList,"OverallState");

	If ListDisplay = "ByDocuments" Then
		
		FilterGroup = DocumentsList.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterGroup.Use  = True;
		FilterGroup.GroupType  = DataCompositionFilterItemsGroupType.OrGroup;
		
		// Setting a new selection to display the list "by documents"
		FilterElement = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.Use = True;
		FilterElement.LeftValue = New DataCompositionField("OverallState");; 
		FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;

		FilterElement = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.Use = True;
		FilterElement.LeftValue = New DataCompositionField("OverallState");
		FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
		FilterElement.RightValue = True;

		Items.IndentField1.Visible = False;
		Items.SourceDocumentPresentation.Visible = False;

	ElsIf ListDisplay = "OnPrintedForms" Then
		Items.IndentField1.Visible = True;
		Items.SourceDocumentPresentation.Visible = True;
	EndIf;

EndProcedure

&AtServer
Procedure SetSelectionByPeriod()

	DocumentsList.Parameters.SetParameterValue("BeginOfPeriod",Period.StartDate);
	
	DocumentsList.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(Period.EndDate), Period.EndDate, EndOfDay(Date(3999, 12, 31))));

EndProcedure

#EndRegion

#EndRegion