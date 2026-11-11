#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// DynamicListsSettings
	InitiateDynamicListSettings();
	// End DynamicListsSettings
	ListOfDocumentsAutoUpdateMode = True;
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	URL = "e1cib/app/DataProcessor.AccountSalesToConsignors";
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	If QuickFilterStructure <> Undefined Then
		If QuickFilterStructure.Property("PeriodVariant") Then
			Period.Variant = QuickFilterStructure.PeriodVariant;
		Else
			Period.Variant = StandardPeriodVariant.Custom;
		EndIf;
	EndIf;
	
	If Parameters.Property("Period") And ValueIsFilled(Parameters.Period) Then
		Period = Parameters.Period;
	EndIf;
	
	If Parameters.Property("RegistrationPeriod") And ValueIsFilled(Parameters.RegistrationPeriod) Then
		// The form is opened from the Month closing operations form.
		Period.StartDate 	 = BegOfMonth(Parameters.RegistrationPeriod);
		Period.EndDate = EndOfMonth(Parameters.RegistrationPeriod);
	EndIf;
	
	GoodsForRegistration.Parameters.SetParameterValue("AccountSalesToConsignor", NStr("vi = 'Bảng kê hàng bán dành cho người đặt ký gửi';
																						|ru = 'Отчет комитенту о продажах';
																						|en = 'Consignment settlement notification'; fa = 'اعلامیه تسویه امانی';
																						|it = 'Report al committente sulle vendite';
																						|pl = 'Raport dla komitenta dot. sprzedaży';
																						|tr = 'Konsinye uzlaşma bildirimi'"));
	GoodsForRegistration.Parameters.SetParameterValue("PurchaseInvoiceConsignmentStockLost", NStr("vi = 'Báo cáo ghi giảm cho người đặt ký gửi';
																									|ru = 'Отчет комитенту о списании';
																									|en = 'Vendor consignment stock adjustment'; fa = 'تعدیل موجودی امانی تأمین‌کننده';
																									|it = 'Report al committente sullo storno';
																									|pl = 'Raport dla komitenta o spisaniu';
																									|tr = 'Satıcı konsinye stok düzeltmesi'"));
	GoodsForRegistration.Parameters.SetParameterValue("StateNotStarted", NStr("vi = 'Chưa bắt đầu';
																				|ru = 'Не начат';
																				|en = 'Not started'; fa = 'شروع‌نشده';
																				|it = 'Non è iniziato';
																				|pl = 'Nie rozpoczęto';
																				|tr = 'Başlatılmadı'"));
		
	DocumentTypesUsed = New Array;
	DocumentTypesUsed.Add(Type("DocumentRef.ConsignmentReportToVendor"));
	DocumentTypesUsed.Add(Type("DocumentRef.PurchaseInvoiceConsignmentStockLost"));
		
	Items.GoodsForRegistrationCreateAccountSalesToConsignor.Visible = 
		AccessRight("Insert", Metadata.Documents.ConsignmentReportToVendor);
		
	Items.GoodsForRegistrationOrganization.Visible = GetFunctionalOption("UseMultipleCompanies");
	Items.GoodsForRegistrationCurrency.Visible = GetFunctionalOption("UseMultipleCurrencies");
	
	List.Parameters.SetParameterValue("ObjectIDReportToTheCommitee",
		Common.MetadataObjectID("Document.ConsignmentReportToVendor"));
	List.Parameters.SetParameterValue("ObjectIDReportToTheCommiteeOnWriteOff",
		Common.MetadataObjectID("Document.PurchaseInvoiceConsignmentStockLost"));
		
	Items.ListSetDeletionMark.Visible = AccessRight("Delete", Metadata.Documents.ConsignmentReportToVendor);
	Items.ListPost.Visible                  = AccessRight("Posting", Metadata.Documents.ConsignmentReportToVendor);
	Items.ListUndoPosting.Visible          = AccessRight("UndoPosting", Metadata.Documents.ConsignmentReportToVendor);
		
	DocumentTypes = New Array();
	DocumentTypes.Add("Document.ConsignmentReportToVendor");
	DocumentTypes.Add("Document.PurchaseInvoiceConsignmentStockLost");
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List,
		DocumentTypes);
	
	
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.ListCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	SetFilter();
	SetParametersForDynamicLists();
	SetCurrentPage();
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Consignor = Settings.Get("Consignor");
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetFlagForAutoUpdatingListOfDocumentsWhenUploadingDataFromSettings(ThisObject,
		"List", Settings);
	// End DynamicListsSettings
	
	SetFilter();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	// DynamicListsSettings
	SetParametersForUpdatingDocumentLists(False, 0);
	// End DynamicListsSettings
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
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
	
	If EventName = "Write_ConsignmentReportToVendor"
		Or EventName = "Write_PurchaseInvoiceConsignmentStockLost"
		Or EventName = "Conducting_Storno"
		Or EventName = "Write_ReversingEntry"
		Or EventName = "Write_PurchasingReportToConsignorPrincipal" Then
		Items.GoodsForRegistration.Refresh();
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("List", Parameter);
		// End DynamicListsSettings
	EndIf;
	

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ConsignorOnChange(Item)
	
	SetFilter();
	
EndProcedure

&AtClient
Procedure PeriodOptionOnChange(Item)
	
	SetParametersForDynamicLists();
	
EndProcedure

&AtClient
Procedure PeriodStartDate_OnChange(Item)
	
	If Period.StartDate > Period.EndDate Then
		Period.EndDate = Period.StartDate;
	EndIf;
	
	SetParametersForDynamicLists();
	
EndProcedure

&AtClient
Procedure PeriodEndDate_2OnChange(Item)
	
	If Period.StartDate > Period.EndDate Then
		Period.StartDate = Period.EndDate;
	EndIf;

	SetParametersForDynamicLists();
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.PageOfTheOrderForRegistration Then
		Items.GoodsForRegistration.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);

	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Item, Title);
	
EndProcedure

&AtServer
Procedure ListOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.List);
	
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.List, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));
	
EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.List, Title, Undefined,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "List"));

EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(Period, , Notification);
	
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	Period = ValueSelected;
	SetSelectionByPeriod();
	
EndProcedure

&AtClient
Procedure CreateAccountSalesToConsignor(Command)
	
	String = Items.GoodsForRegistration.CurrentData;
	If String <> Undefined Then
		
		StructureBase = New Structure;
		StructureBase.Insert("Partner", String.Consignor);
		StructureBase.Insert("Organization", String.Organization);
		StructureBase.Insert("Counterparty", String.Counterparty);
		StructureBase.Insert("Terms", String.Terms);
		StructureBase.Insert("Contract", String.Contract);
		StructureBase.Insert("VATTaxation", String.VATTaxation);
		StructureBase.Insert("Currency", String.Currency);
		StructureBase.Insert("BeginOfPeriod", Period.StartDate);
		StructureBase.Insert("EndOfPeriod", Period.EndDate);
		StructureBase.Insert("FillInByTheGoodsForRegistration", True);
		StructureBase.Insert("DocumentSales", String.DocumentSales);
		
		ParametersStructure1 = New Structure;
		ParametersStructure1.Insert("Basis", StructureBase);
		If String.RevenueAmount <> 0 Or String.ReturnAmount <> 0 Or String.QuantityConsumedBalance = 0 Then
			OpenForm("Document.ConsignmentReportToVendor.ObjectForm", ParametersStructure1, Items.List);
		Else
			OpenForm("Document.PurchaseInvoiceConsignmentStockLost.ObjectForm", ParametersStructure1, Items.List);
		EndIf;
	Else
		OpenForm("Document.ConsignmentReportToVendor.ObjectForm", , Items.List);
	EndIf;
	
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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem


&AtClient
Procedure DocumentsListRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("List");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
EndProcedure

&AtServer
Procedure SetFilter()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Partner",
		Consignor,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Consignor));
	
	CommonClientServer.SetDynamicListFilterItem(
		GoodsForRegistration,
		"Consignor",
		Consignor,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Consignor));
	SetSelectionByPeriod();
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	List.Parameters.SetParameterValue("BeginOfPeriod",
		Period.StartDate);
	List.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(Period.EndDate), Period.EndDate, EndOfDay(Date(3999, 12, 31))));
		
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "List");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetCurrentPage()
	
	CurrentPageName = "";
	
	If Parameters.Property("RegistrationPeriod") Then
		// The form is opened from the Month closing operations form.
		CurrentPageName = Items.PageOfTheOrderForRegistration.Name;
	Else
		Parameters.Property("CurrentPageName", CurrentPageName);
	EndIf;
	
	If ValueIsFilled(CurrentPageName) Then
		CurrentItem = Items[CurrentPageName];
	EndIf;
	
EndProcedure

&AtServer
Procedure SetParametersForDynamicLists()
	DateOfRemainingGoods = ?(ValueIsFilled(Period.EndDate), Period.EndDate, Date(2399, 1, 1));
	Boundary = New Boundary(EndOfDay(DateOfRemainingGoods), BoundaryType.Including);
	
	GoodsForRegistration.Parameters.SetParameterValue("ConBorder", EndOfDay(DateOfRemainingGoods));
	GoodsForRegistration.Parameters.SetParameterValue("InitialBorder", BegOfDay(Period.StartDate));
EndProcedure

&AtServerNoContext
Procedure GoodsForRegistrationOnGetDataAtServer(TagName, Settings, Rows)
	
	If Not AccessRight("Read", Metadata.Documents.CustomerInvoice) Then
		
		SetPrivilegedMode(True);
		
		For Each KeyOfLineToDesign In Rows.GetKeys() Do
			ListLine = Rows[KeyOfLineToDesign];
			ListLine.Appearance["DocumentSales"].SetParameterValue(
				"Text", String(ListLine.Data.DocumentSales));
		EndDo;
		
		SetPrivilegedMode(False);
		
	EndIf;
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.ConsignmentReportToVendor.EmptyRef"));
	Managers.Add(PredefinedValue("Document.PurchaseInvoiceConsignmentStockLost.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Ref = ReferencesArrray[0];
		Items.List.CurrentRow = Ref;
		ShowValue(Undefined, Ref);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
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
