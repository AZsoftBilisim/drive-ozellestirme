
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	RegisterUpdateOrderForShipmentToBeExecutedHasBeenCompleted = Not Constants.DeleteShipmentReferencesToShipNotFilled.Get(); 
	If Not RegisterUpdateOrderForShipmentToBeExecutedHasBeenCompleted Then
		ListReferencesForRegistration.QueryText = QueryTextBalancesOfCustomerOrders();
	EndIf; 
	
	If ValueIsFilled(Parameters.FormCaption) Then
		Title = Parameters.FormCaption;
	EndIf;
	
	// Getting a FO
	UsePartnersAndCounterparties = GetFunctionalOption("UsePartnersAndCounterparties");
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	UseSaleByMultipleOrders = GetFunctionalOption("UseSaleByMultipleOrders");
	UseCustomerInvoicesForSeveralOrders = GetFunctionalOption("UseCustomerInvoicesForSeveralOrders");
	UseWarehouseManagemantSystemForGoodsIssue = GetFunctionalOption("UseWarehouseManagemantSystemForGoodsIssue");
	UseShipmentWithDeferredTransferOfTitle2_5 =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5");
	
	Items.PageToTransferOwnership.Visible = UseShipmentWithDeferredTransferOfTitle2_5;
	If UseShipmentWithDeferredTransferOfTitle2_5 = False Then
		Items.Pages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	// Installation of selections.
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Organization",        Organization);
		QuickFilterStructure.Property("Warehouse",              Warehouse);
		QuickFilterStructure.Property("InvoiceStatus", InvoiceStatus);
		QuickFilterStructure.Property("NoteState",    NoteState);
	EndIf;
	
	If Not UseSeveralWarehouses Then
		If Not ValueIsFilled(Warehouse) Then
			Warehouse = Catalogs.Warehouses.DefaultWarehouse();
		EndIf;
	EndIf;
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = RequestTextForListOfProcessingOrders();
	ListProperties.MainTable = "";
	ListProperties.DynamicDataRead = Undefined;
	Common.SetDynamicListProperties(Items.ListReferencesForRegistration, ListProperties);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReferencesForRegistration,
		"InvoiceStatus",
		?(ValueIsFilled(InvoiceStatus), Number(InvoiceStatus), InvoiceStatus),
		QuickFilterStructure,,,
		True);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReferencesForRegistration,
		"NoteState",
		?(ValueIsFilled(NoteState), Number(NoteState), NoteState),
		QuickFilterStructure,,,
		True);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ListReferencesForRegistration,
		"Organization",
		Organization,
		QuickFilterStructure);

	SetOrganizationAndWarehouseParametersAtServer();
		
	Items.Warehouse.Visible = UseSeveralWarehouses;
	
	Items.ListReferencesForRegistrationNoteState.Visible = UseWarehouseManagemantSystemForGoodsIssue;
	Items.ListReferencesForRegistrationInvoiceStatus.Visible = UseAdvancedFeaturesOfSalesOrder;
	
	Items.NoteState.Visible = UseWarehouseManagemantSystemForGoodsIssue;
	Items.InvoiceStatus.Visible = UseAdvancedFeaturesOfSalesOrder;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"ListReferencesForRegistrationOrganization",
		"Visible",
		GetFunctionalOption("UseMultipleCompanies"));
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"ListReferencesForRegistrationWarehouse",
		"Visible",
		UseSeveralWarehouses);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"ListReferencesForRegistrationSalesOpportunity",
		"Visible",
		GetFunctionalOption("UseSalesOpportunitiesToCustomer"));
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"ListReferencesForRegistrationCurrency",
		"Visible",
		GetFunctionalOption("UseMultipleCurrencies"));
	
	ListReferencesForRegistration.Parameters.SetParameterValue("CurrentDate", BegOfDay(CurrentSessionDate()));
	
	HaveRightToReadLeftovers = AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences)
								And AccessRight("Read", Metadata.AccumulationRegisters.GoodsForIssue);
	
	ThereIsRightToAddTransferOfGoods = AccessRight("Insert", Metadata.Documents.TransferOfGoodsToBailee);
	
	Items.ListReferencesForRegistration.Visible = HaveRightToReadLeftovers;
	
	Items.ListOfOrdersForRegistrationShouldBeIssuedAccordingToOrders.Visible = ThereIsRightToAddTransferOfGoods
																			Or AccessRight("Insert", Metadata.Documents.CustomerInvoiceServices)
																			Or AccessRight("Insert", Metadata.Documents.CustomerInvoice);
	Items.ListReferencesForRegistrationRegisterByShipment.Visible = ThereIsRightToAddTransferOfGoods
																			Or AccessRight("Insert", Metadata.Documents.CustomerInvoice);
	Items.ListReferencesForRegistrationExecutionState.Visible = AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus);
	
	Items.ListOfOrdersForRegistrationToArrangeShipmentByOrders.Visible = UseShipmentWithDeferredTransferOfTitle2_5
																				And AccessRight("Insert", Metadata.Documents.GoodsShipmentToCustomer);
																				
	Items.ListOfOrderForRegistrationToIssueShipmentByOrder.Visible = UseShipmentWithDeferredTransferOfTitle2_5
																				And UseWarehouseManagemantSystemForGoodsIssue
																				And AccessRight("Insert", Metadata.Documents.GoodsShipmentToCustomer);
	FillSelectionListsByShipmentStates();
	
	Items.ListReferencesForRegistrationCounterparty.Visible = UsePartnersAndCounterparties;
	Items.ListForTransferOfOwnershipCounterparty.Visible = UsePartnersAndCounterparties;
	
	If UseShipmentWithDeferredTransferOfTitle2_5 Then
		FillInCommandsByVisibilityCondition();
	EndIf;
	
	CreateHyperlinkSeeAlsoIn();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_CustomerInvoice"
		Or EventName = "Write_SalesOrder"
		Or EventName = "Write_TransferOfGoodsToBailee"
		Or EventName = "Write_RequestForReturnOfGoodsFromCustomer"
		Or EventName = "Write_CustomerInvoiceServices"
		Or EventName = "Write_GoodsIssueNote"
		Or EventName = "Write_CashAccountReceiptNote"
		Or EventName = "Accept_FormOfCreatedDocuments"
		Or EventName = "IssuedSalesDocument"
		Or EventName = "Write_GoodsShipmentToCustomer"
		Or EventName = "CancellationOfSalesDocuments" Then
		
		Items.ListReferencesForRegistration.Refresh();
		If UseShipmentWithDeferredTransferOfTitle2_5 Then 
			Items.ListForTransferOfOwnership.Refresh();
		EndIf;
	ElsIf EventName = "ToCancelTheBatchFormation" Then
		ToCancelTheBatchFormation = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.LogOfSalesDocuments.Form.ParametersOfSalesDocumentCreation" Then
		If ValueSelected <> Undefined Then
			SalesServerCall.SaveDocumentSetSettings(
				ValueSelected,
				"DataProcessor.LogOfSalesDocuments.Form.ToRegisterInvoices/CurrentData");
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Warehouse", Warehouse);
		Settings.Delete("Warehouse");
		QuickFilterStructure.Property("InvoiceStatus", InvoiceStatus);
		Settings.Delete("InvoiceStatus");
		QuickFilterStructure.Property("NoteState", NoteState);
		Settings.Delete("NoteState");
		QuickFilterStructure.Property("Organization", Organization);
		Settings.Delete("Organization");
	Else
		Warehouse              = Settings.Get("Warehouse");
		InvoiceStatus = Settings.Get("InvoiceStatus");
		NoteState    = Settings.Get("NoteState");
		Organization        = Settings.Get("Organization");
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListReferencesForRegistration,
		"InvoiceStatus",
		?(ValueIsFilled(InvoiceStatus), Number(InvoiceStatus), InvoiceStatus),
		QuickFilterStructure, 
		Settings,
		ValueIsFilled(InvoiceStatus),
		,
		True);
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListReferencesForRegistration,
		"NoteState",
		?(ValueIsFilled(NoteState), Number(NoteState), NoteState),
		QuickFilterStructure,
		Settings,
		ValueIsFilled(NoteState),
		,
		True);
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ListReferencesForRegistration,
		"Organization",
		Organization,
		QuickFilterStructure,
		Settings,
		ValueIsFilled(Organization));
	
	SetOrganizationAndWarehouseParametersAtServer();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	ListReferencesForRegistration.Parameters.SetParameterValue("Warehouse", Warehouse);
	
EndProcedure

&AtClient
Procedure ListReferencesForRegistrationSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(Undefined, Item.CurrentData.ReferenceOrder);
	
EndProcedure

&AtClient
Procedure InvoiceStatusOnChange(Item)
	
	State = ?(ValueIsFilled(InvoiceStatus), Number(InvoiceStatus), 0);
	
	CommonClientServer.SetDynamicListFilterItem(ListReferencesForRegistration,
		"InvoiceStatus",
		State,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(InvoiceStatus));
		
EndProcedure

&AtClient
Procedure NoteStateOnChange(Item)
	
	State = ?(ValueIsFilled(NoteState), Number(NoteState), 0);
	
	CommonClientServer.SetDynamicListFilterItem(ListReferencesForRegistration,
		"NoteState",
		State,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(NoteState));
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		ListReferencesForRegistration,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Organization));
	
	CommonClientServer.SetDynamicListParameter(ListReferencesForRegistration, "Organization", Organization);
	CommonClientServer.SetDynamicListParameter(ListForTransferOfOwnership, "Organization", Organization);
	
EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("FormAssignmentKey", "");
	FormParameters.Insert("FormUniqueID", False);
	
	If FormattedStringURL = "DataProcessor.LogOfSalesDocuments.Form.DocumentsList" Then
	EndIf;
	
	If FormattedStringURL = "Document.InvoiceIssued.Form.DocumentsListForm"
		Or FormattedStringURL = "Document.InvoiceIssued.Form.WorkplaceFormForProcessingCorrectedInvoicesForShipments" Then
		QuickFilterStructure = New Structure;
		QuickFilterStructure.Insert("Organization", Organization);
		FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	EndIf;
	
	OpenForm(FormattedStringURL, FormParameters,, FormParameters.FormUniqueID);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListForTransferOfOwnership

&AtClient
Procedure ListForTransferOfOwnershipSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(Undefined, Item.CurrentData.ReferenceOrder);
	
EndProcedure

&AtClient
Procedure ListForTransferOfOwnershipOnActivateRow(Item)
		
	DetachIdleHandler("UpdateCommandsByVisibilityCondition");
	AttachIdleHandler("UpdateCommandsByVisibilityCondition", 0.2, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure IssueByOrder(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.CustomerInvoice.ToRegisterInvoices.Command.IssueByOrder");
	
	SelectedRows = Items.ListReferencesForRegistration.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters("Invoices")) Then
		Return;
	EndIf;
	
	ByNotes = False;
	ArrangeShipment = False;
	RegisterSale();
	
EndProcedure

&AtClient
Procedure RegisterByShipment(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.CustomerInvoice.ToRegisterInvoices.Command.RegisterByShipment");
		
	SelectedRows = Items.ListReferencesForRegistration.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters("Invoices")) Then
		Return;
	EndIf;
	
	ByNotes = True;
	ArrangeShipment = False;
	RegisterSale();
	
EndProcedure

&AtClient
Procedure ExecutionState(Command)
	
	SelectedRows = Items.ListReferencesForRegistration.SelectedRows;
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	DocumentsList = New ValueList;
	ArrayOfDocumentTypes_ = New Array;
	For Each SelectedRow In SelectedRows Do
		
		SelectedDocument_ = Items.ListReferencesForRegistration.RowData(SelectedRow).Ref;
		SelectedDocumentType_ = TypeOf(SelectedDocument_);
		
		If ArrayOfDocumentTypes_.Find(SelectedDocumentType_) = Undefined Then
			ArrayOfDocumentTypes_.Add(SelectedDocumentType_);
			If ArrayOfDocumentTypes_.Count() > 1 Then
				ShowMessageBox( , NStr("vi = 'Lệnh không thể được thực thi cho các chứng từ thuộc các loại khác nhau.';
										|ru = 'Команда не может быть выполнена для документов разного вида.';
										|en = 'Command cannot be executed for documents of different kinds.'; fa = 'Command cannot be executed for documents of different kinds.';
										|it = 'Il comando non può essere eseguito per i documenti di tipo diverso.';
										|pl = 'Polecenie nie może być wykonane dla dokumentów różnego rodzaju.';
										|tr = 'Komut farklı belge türleri için yürütülemez.'"));
				Return;
			EndIf;
		EndIf;
		
		If DocumentsList.FindByValue(SelectedDocument_) = Undefined Then
			DocumentsList.Add(SelectedDocument_);
		EndIf;
			
	EndDo;
	
	If DocumentsList.Count() = 0 Then
		Return;
	EndIf;
	
	OpenForm("Report.DocumentFulfillmentStatus.Form.ReportForm", 
		New Structure("IncomingDocuments", DocumentsList), 
		ThisForm,
		False);
	
EndProcedure

&AtClient
Procedure RelatedDocuments(Command)
	
	CurrentData = Items.ListReferencesForRegistration.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SelectedDocument = CurrentData.Ref;
	If Not ValueIsFilled(SelectedDocument) Then
		Return;
	EndIf;
	
	OpenForm("CommonForm.RelatedDocuments",
		New Structure("FilterObject", SelectedDocument),
			ThisForm,
			False);
	
EndProcedure

&AtClient
Procedure ArrangeShipmentOfGoods(Command)
	
	NameOfShipmentCommand = Command.Name;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("Document.GoodsShipmentToCustomer.ToRegisterInvoices.Command." + NameOfShipmentCommand);
	
	SelectedRows = Items.ListReferencesForRegistration.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters("Invoices")) Then
		Return;
	EndIf;
	
	ByNotes = False;
	ArrangeShipment = True;
	If NameOfShipmentCommand = "ArrangeShipmentByOrder" Then
		ByNotes = True;
	EndIf;
	
	RegisterSale();
	
EndProcedure

&AtClient
Procedure ToIssueDocumentsOfTransferOfOwnership(Command)
	
	NameOfShipmentCommand = Command.Name;
	DocumentName = "CustomerInvoice";
	
	// Certificate of discrepancy after shipment
	If NameOfShipmentCommand = "IssueCertificateOfDiscrepancyAfterShipment" Then
		DocumentName = "DiscrepancyReportFollowingShipment";
	
	// Shipment correction	
	ElsIf NameOfShipmentCommand = "IssueShipmentCorrection" Then
		DocumentName = "GoodsShipmentToCustomer";
		
	// Receipt of goods	
	ElsIf NameOfShipmentCommand = "RegisterGoodsReceipt" Then
		DocumentName = "GoodsReceiptFromCustomer";
		
	// Registration of surpluses	
	ElsIf NameOfShipmentCommand = "RegisterRegistrationOfSurpluses" Then
		DocumentName = "RecognitionOfStockSurplusShippedToCustomer";
			
	// Write-Off of Shortages	
	ElsIf NameOfShipmentCommand = "IssueWriteOffOfShortages" Then
		DocumentName = "WriteOffOfShippedGoods";
	EndIf;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("Document." + DocumentName + ".ToRegisterInvoices.Command." + NameOfShipmentCommand);
	
	SelectedRows = Items.ListForTransferOfOwnership.SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters("Invoices")) Then
		Return;
	EndIf;
	
	ToIssueDocumentsForShipment();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Conditional design of the dynamic list "List of assignments"
	ListOfConditionalAppearance = ListReferencesForRegistration.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearance.Items.Clear();
	
	// The document has a high priority
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chứng từ có mức ưu tiên cao';
							|ru = 'Документ имеет высокий приоритет';
							|en = 'High priority document'; fa = 'سند با اولویت بالا';
							|it = 'Il documento ha priorità alta';
							|pl = 'Dokument ma wysoki priorytet';
							|tr = 'Belge yüksek önceliğe sahiptir'");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Priorities.GetTopPriority();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeletionMark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.HighPriorityDocument);
	
	// The document has a low priority
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Chứng từ có mức ưu tiên thấp';
							|ru = 'Документ имеет низкий приоритет';
							|en = 'Low priority document'; fa = 'Low priority document';
							|it = 'Il documento ha priorità bassa';
							|pl = 'Dokument ma niski priorytet';
							|tr = 'Belge düşük önceliğe sahiptir'");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Priority");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Priorities.GetLowerPriority();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeletionMark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("BackColor", StyleColors.LowDocumentPriority);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListReferencesForRegistration.DocumentDate", Items.ListReferencesForRegistrationDocumentDate.Name);
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListForTransferOfOwnership.DocumentDate", Items.ListForTransferOfOwnershipDocumentDate.Name);
	
EndProcedure

&AtServer
Function RequestTextForListOfProcessingOrders()
	
	QueryText =
	"SELECT ALLOWED
	|	Table.ReferenceOrder AS Ref,
	|	Table.Warehouse AS Warehouse,
	|	CASE
	|		WHEN NOT Table.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|		OR Table.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|		AND Table.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue > &CurrentDate
	|			THEN 4
	|		ELSE 0
	|	END AS OrderStatusTime,
	|	CASE
	|		WHEN Warehouses.IsFolder
	|		AND Warehouses.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SplitInvoiceByWarehouses,
	|	CASE
	|		WHEN Warehouses.IsFolder
	|		AND Warehouses.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CombineSalesByWarehouse
	|INTO TueBalancesOnCustomerSOrder
	|FROM
	|	InformationRegister.ShipmentAndReturnReferencesToFulfill AS Table
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON (Warehouses.Ref = CASE
	|			WHEN Table.ReferenceOrder REFS Document.SalesOrder
	|				THEN CAST(Table.ReferenceOrder AS Document.SalesOrder).Warehouse
	|			WHEN Table.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|				THEN CAST(Table.ReferenceOrder AS Document.GoodsShipmentToCustomer).Warehouse
	|			WHEN Table.ReferenceOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|				THEN CAST(Table.ReferenceOrder AS Document.RequestForReturnOfGoodsFromCustomer).Warehouse
	|		END)
	|WHERE
	|	VALUETYPE(Table.ReferenceOrder) IN (TYPE(Document.SalesOrder), TYPE(Document.GoodsShipmentToCustomer),
	|		TYPE(Document.RequestForReturnOfGoodsFromCustomer))
	|	AND Table.StateOfGoodsToShip IN (VALUE(Enum.StateOfRegisteringDocumentsByReference.PendingCreation),
	|		VALUE(Enum.StateOfRegisteringDocumentsByReference.PartiallyRegistered))
	|	AND &Warehouse IN (Table.Warehouse, VALUE(Catalog.Warehouses.EmptyRef))
	|	AND &Organization IN (Table.Organization, VALUE(Catalog.Companies.EmptyRef))
	|
	|;
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT ALLOWED DISTINCT
	|	Table.Ref AS SalesOrder,
	|	Table.Warehouse AS Warehouse
	|INTO TueRegistrationDocuments
	|FROM
	|	TueBalancesOnCustomerSOrder AS Table
	|
	|INDEX BY
	|	SalesOrder,
	|	Warehouse
	|;
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT ALLOWED
	|	Table.SalesOrder AS SalesOrder,
	|	Table.Warehouse AS Warehouse
	|INTO TueThereAreInvoices
	|FROM
	|	TueRegistrationDocuments AS Table
	|		INNER JOIN AccumulationRegister.ShipmentAndReturnReferences AS References
	|		ON Table.SalesOrder = References.ReferenceOrder
	|		AND (Table.Warehouse = References.Warehouse
	|		OR References.Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|WHERE
	|	References.Active
	|	AND Recorder REFS Document.CustomerInvoice
	|	AND References.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|	AND References.Count > 0
	|	AND References.LineNumber = 1
	|
	|INDEX BY
	|	SalesOrder,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT ALLOWED
	|	Table.SalesOrder AS SalesOrder,
	|	Table.Warehouse AS Warehouse
	|INTO TTHasShipments
	|FROM
	|	TueRegistrationDocuments AS Table
	|		INNER JOIN AccumulationRegister.ShipmentAndReturnReferences AS References
	|		ON Table.SalesOrder = References.ReferenceOrder
	|		AND Table.Warehouse = References.Warehouse
	|WHERE
	|	References.Active
	|	AND Recorder REFS Document.GoodsShipmentToCustomer
	|	AND References.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|	AND References.Count > 0
	|	AND References.LineNumber = 1
	|
	|INDEX BY
	|	SalesOrder,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT ALLOWED
	|	Table.Ref AS Ref,
	|	Table.Warehouse AS Warehouse,
	|	CASE
	|		WHEN NOT TableThereAreInvoices.SalesOrder IS NULL
	|			THEN 2
	|		ELSE 1
	|	END AS InvoiceStatusVremya,
	|	Table.OrderStatusTime AS OrderStatusTime,
	|	CASE
	|		WHEN NOT TableHasShipments.SalesOrder IS NULL
	|			THEN 2
	|		ELSE 1
	|	END AS ShipmentStateTime,
	|	Table.OrderStatusTime AS StateOfShipmentOrderTime,
	|	Table.SplitInvoiceByWarehouses AS SplitInvoiceByWarehouses,
	|	Table.CombineSalesByWarehouse AS CombineSalesByWarehouse
	|INTO WTheStateOfTheInvoice
	|FROM
	|	TueBalancesOnCustomerSOrder AS Table
	|		LEFT JOIN TueThereAreInvoices AS TableThereAreInvoices
	|		ON TableThereAreInvoices.SalesOrder = Table.Ref
	|		AND TableThereAreInvoices.Warehouse = Table.Warehouse
	|		LEFT JOIN TTHasShipments AS TableHasShipments
	|		ON TableHasShipments.SalesOrder = Table.Ref
	|		AND TableHasShipments.Warehouse = Table.Warehouse
	|
	|INDEX BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT ALLOWED
	|	Table.DocumentShipments AS DocumentShipments,
	|	Table.Warehouse AS Warehouse,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Series AS Series,
	|	Table.Purpose AS Purpose,
	|	(Table.ToShipBalance - Table.AssembledBalance) = Table.ToRegisterBalance AS TheRemainderIsEqualTo
	|INTO TueLeftoversGoodsToBeShipped
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(, (Warehouse = &Warehouse
	|	OR &Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|	AND (DocumentShipments REFS Document.SalesOrder
	|	OR DocumentShipments REFS Document.GoodsShipmentToCustomer
	|	OR DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|	OR DocumentShipments REFS Document.CustomerInvoice
	|	OR DocumentShipments REFS Document.TransferOfGoodsToBailee)) AS Table
	|
	|INDEX BY
	|	DocumentShipments
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT ALLOWED DISTINCT
	|	Table.DocumentShipments AS DocumentShipments,
	|	Table.Warehouse AS Warehouse
	|INTO TueShippingDocuments
	|FROM
	|	TueLeftoversGoodsToBeShipped AS Table
	|
	|INDEX BY
	|	DocumentShipments,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT
	|	Table.DocumentShipments AS DocumentShipments,
	|	Table.Warehouse AS Warehouse
	|INTO TueThereAreOrders_3
	|FROM
	|	TueShippingDocuments AS Table
	|		INNER JOIN AccumulationRegister.GoodsForIssue AS GoodsForIssue
	|		ON Table.DocumentShipments = GoodsForIssue.DocumentShipments
	|		AND Table.Warehouse = GoodsForIssue.Warehouse
	|WHERE
	|	GoodsForIssue.Active
	|	AND (GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND GoodsForIssue.ToShip > 0
	|	OR GoodsForIssue.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND GoodsForIssue.Assembled > 0)
	|
	|INDEX BY
	|	DocumentShipments,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT ALLOWED
	|	Table.DocumentShipments AS Ref,
	|	Table.Warehouse AS Warehouse,
	|	CASE
	|		WHEN TableHasOrders.DocumentShipments IS NULL
	|		AND NOT CatWarehouses.Ref IS NULL
	|			THEN 1
	|		WHEN Table.TheRemainderIsEqualTo
	|			THEN 0
	|		ELSE 3
	|	END AS OrderStatusTime
	|INTO TueOrderStatus
	|FROM
	|	TueLeftoversGoodsToBeShipped AS Table
	|		LEFT JOIN TueThereAreOrders_3 AS TableHasOrders
	|		ON TableHasOrders.DocumentShipments = Table.DocumentShipments
	|		AND TableHasOrders.Warehouse = Table.Warehouse
	|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
	|		ON CatWarehouses.Ref = Table.Warehouse
	|		AND CatWarehouses.UseWarehouseManagemantSystemForGoodsIssue
	|		AND CatWarehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate
	|WHERE
	|	CASE
	|		WHEN TableHasOrders.DocumentShipments IS NULL
	|		AND NOT CatWarehouses.Ref IS NULL
	|			THEN 1
	|		WHEN Table.TheRemainderIsEqualTo
	|			THEN 0
	|		ELSE 3
	|	END > 0
	|
	|INDEX BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 9
	|SELECT ALLOWED DISTINCT
	|	CASE
	|		WHEN WTheStateOfTheInvoice.Ref IS NULL
	|			THEN TueOrderStatus.Ref
	|		ELSE WTheStateOfTheInvoice.Ref
	|	END AS DocumentShipments,
	|	CASE
	|		WHEN WTheStateOfTheInvoice.Warehouse IS NULL
	|			THEN TueOrderStatus.Warehouse
	|		ELSE WTheStateOfTheInvoice.Warehouse
	|	END AS Warehouse,
	|	ISNULL(WTheStateOfTheInvoice.InvoiceStatusVremya, 0) AS InvoiceStatusVremya,
	|	ISNULL(TueOrderStatus.OrderStatusTime, WTheStateOfTheInvoice.OrderStatusTime) AS OrderStatusTime,
	|	ISNULL(WTheStateOfTheInvoice.ShipmentStateTime, 0) AS ShipmentStateTime,
	|	ISNULL(TueOrderStatus.OrderStatusTime, WTheStateOfTheInvoice.StateOfShipmentOrderTime) AS
	|		StateOfShipmentOrderTime,
	|	ISNULL(WTheStateOfTheInvoice.SplitInvoiceByWarehouses, FALSE) AS SplitInvoiceByWarehouses,
	|	ISNULL(WTheStateOfTheInvoice.CombineSalesByWarehouse, FALSE) AS CombineSalesByWarehouse
	|INTO TueNewOrders
	|FROM
	|	WTheStateOfTheInvoice AS WTheStateOfTheInvoice
	|		FULL JOIN TueOrderStatus AS TueOrderStatus
	|		ON WTheStateOfTheInvoice.Ref = TueOrderStatus.Ref
	|		AND WTheStateOfTheInvoice.Warehouse = TueOrderStatus.Warehouse
	|
	|INDEX BY
	|	DocumentShipments
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 10
	|SELECT ALLOWED
	|	GoodsForIssue.DocumentShipments AS ReferenceOrder,
	|	GoodsForIssue.DocumentShipments AS Ref,
	|	GoodsForIssue.DocumentShipments AS SalesOrder,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).DeletionMark
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).DeletionMark
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).DeletionMark
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).DeletionMark
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).DeletionMark
	|	END AS DeletionMark,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Number
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).Number
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Number
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).Number
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).Number
	|	END AS Number,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Date
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).Date
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Date
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).Date
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).Date
	|	END AS DocumentDate,
	|	VALUETYPE(GoodsForIssue.DocumentShipments) AS TypeOfOrder_,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Posted
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).Posted
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Posted
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).Posted
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).Posted
	|	END AS Posted,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Partner
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).Partner
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Partner
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).Partner
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).Partner
	|	END AS Partner,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Counterparty
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).Counterparty
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Counterparty
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).Counterparty
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).Counterparty
	|	END AS Counterparty,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Organization
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).Organization
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Organization
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).Organization
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).Organization
	|	END AS Organization,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Terms
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).Terms
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Terms
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).Terms
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).Terms
	|	END AS Terms,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Contract
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).Contract
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Contract
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).Contract
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).Contract
	|	END AS Contract,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).SalesOpportunity
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).SalesOpportunity
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).SalesOpportunity
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).SalesOpportunity
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).SalesOpportunity
	|	END AS SalesOpportunity,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Currency
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).Currency
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Currency
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).Currency
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).Currency
	|	END AS Currency,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).DocumentAmount
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).DocumentAmount
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).ReplacementAmount
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).DocumentAmount
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).DocumentAmount
	|		ELSE 0
	|	END AS DocumentAmount,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).PaymentSchedule
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).PaymentSchedule
	|	END AS PaymentSchedule,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Warehouse
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).Warehouse
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Warehouse
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).Warehouse
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).Warehouse
	|	END AS TheStockCaps,
	|	GoodsForIssue.Warehouse AS Warehouse,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Status
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Status
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).Status
	|	END AS Status,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Manager
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).Manager
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Manager
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).Manager
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).Manager
	|	END AS Manager,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).DocumentBasis
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).DocumentBasis
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN UNDEFINED
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).SalesOrder
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).SalesOrder
	|	END AS DocumentBasis,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Priority
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Priority
	|	END AS Priority,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).BusinessOperation
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).BusinessOperation
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).BusinessOperation
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).BusinessOperation
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).BusinessOperation
	|	END AS BusinessOperation,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).CashAccount
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).CashAccount
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).CashAccount
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN VALUE(Catalog.CashAccounts.EmptyRef)
	|	END AS CashAccount,
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).DeliveryMethod
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).DeliveryMethod
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).DeliveryMethod
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).DeliveryMethod
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).DeliveryMethod
	|	END AS DeliveryMethod,
	|	GoodsForIssue.InvoiceStatusVremya AS InvoiceStatus,
	|	GoodsForIssue.OrderStatusTime AS NoteState,
	|	GoodsForIssue.ShipmentStateTime AS ShipmentStatus,
	|	GoodsForIssue.StateOfShipmentOrderTime AS StateOfShipmentOrder,
	|	CASE
	|		WHEN CASE
	|			WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|				THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Priority
	|			WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|				THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Priority
	|		END IN
	|			(SELECT TOP 1
	|				Priorities.Ref AS Priority
	|			FROM
	|				Catalog.Priorities AS Priorities
	|
	|			ORDER BY
	|				Priorities.AddlOrderingAttribute)
	|			THEN 0
	|		WHEN CASE
	|			WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|				THEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Priority
	|			WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|				THEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Priority
	|		END IN
	|			(SELECT TOP 1
	|				Priorities.Ref AS Priority
	|			FROM
	|				Catalog.Priorities AS Priorities
	|
	|			ORDER BY
	|				Priorities.AddlOrderingAttribute DESC)
	|			THEN 2
	|		ELSE 1
	|	END AS PictureOfPriority,
	|
	|	CASE
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.SalesOrder
	|			THEN
	|				CASE
	|					WHEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).Posted
	|						THEN 0
	|					WHEN CAST(GoodsForIssue.DocumentShipments AS Document.SalesOrder).DeletionMark
	|						THEN 1
	|					ELSE 2
	|				END
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.GoodsShipmentToCustomer
	|			THEN
	|				CASE
	|					WHEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).Posted
	|						THEN 0
	|					WHEN CAST(GoodsForIssue.DocumentShipments AS Document.GoodsShipmentToCustomer).DeletionMark
	|						THEN 1
	|					ELSE 2
	|				END
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN
	|				CASE
	|					WHEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Posted
	|						THEN 0
	|					WHEN CAST(GoodsForIssue.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).DeletionMark
	|						THEN 1
	|					ELSE 2
	|				END
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.CustomerInvoice
	|			THEN
	|				CASE
	|					WHEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).Posted
	|						THEN 0
	|					WHEN CAST(GoodsForIssue.DocumentShipments AS Document.CustomerInvoice).DeletionMark
	|						THEN 1
	|					ELSE 2
	|				END
	|		WHEN GoodsForIssue.DocumentShipments REFS Document.TransferOfGoodsToBailee
	|			THEN
	|				CASE
	|					WHEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).Posted
	|						THEN 0
	|					WHEN CAST(GoodsForIssue.DocumentShipments AS Document.TransferOfGoodsToBailee).DeletionMark
	|						THEN 1
	|					ELSE 2
	|				END
	|	END AS CustomPicture,
	|	GoodsForIssue.SplitInvoiceByWarehouses AS SplitInvoiceByWarehouses,
	|	GoodsForIssue.CombineSalesByWarehouse AS CombineSalesByWarehouse
	|FROM
	|	TueNewOrders AS GoodsForIssue
	|WHERE
	|	NOT GoodsForIssue.DocumentShipments.Ref IS NULL";
	
	Return QueryText;
	
EndFunction

&AtServer
Procedure FillSelectionListsByShipmentStates()
	
	ChoiceList = Items.InvoiceStatus.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add("0", NStr("vi = 'Mọi thứ đều được đóng khung';
							|ru = 'Все оформлено';
							|en = 'Fully issued/received'; fa = 'Fully issued/received';
							|it = 'Formalizzato tutto';
							|pl = 'Wszystko jest sporządzone';
							|tr = 'Tümü düzenlenmiş'"), False, PictureLib.InvoiceIsRegistered);
	ChoiceList.Add("1", NStr("vi = 'Tạo hóa đơn bán hàng';
							|ru = 'Создать накладную';
							|en = 'Create invoice'; fa = 'ایجاد فاکتور';
							|it = 'Creare una bolla';
							|pl = 'Utwórz list przewozowy';
							|tr = 'İrsaliye oluştur'"), False, PictureLib.CreateInvoice);
	ChoiceList.Add("2", NStr("vi = 'Gia hạn hóa đơn';
							|ru = 'Дооформить накладную';
							|en = 'Pending issue/receipt'; fa = 'Pending issue/receipt';
							|it = 'Completare la bolla';
							|pl = 'Sporządź do końca list przewozowy';
							|tr = 'İrsaliyeyi tamamla'"), False, PictureLib.CreateInvoiceOnUninvoicedDeliveries);
	
	ChoiceList = Items.NoteState.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add("0", NStr("vi = 'Hóa đơn khớp';
							|ru = 'Соответствуют накладным';
							|en = 'Notes correspond to the invoices'; fa = 'Notes correspond to the invoices';
							|it = 'Corrispondono alle bolle';
							|pl = 'Odpowiadają listom przewozowym';
							|tr = 'İrsaliyelere uygun'"), False, PictureLib.InvoiceIsRegistered);
	ChoiceList.Add("1", NStr("vi = 'Không đóng khung';
							|ru = 'Не оформлены';
							|en = 'Pending creation'; fa = 'در انتظار ایجاد';
							|it = 'Non sono formalizzati';
							|pl = 'Nie są sporządzone';
							|tr = 'Düzenlenmemiş'"), False, PictureLib.CreateInvoice);
	ChoiceList.Add("3", NStr("vi = 'Không khớp hóa đơn';
							|ru = 'Не соответствуют накладным';
							|en = 'Received vs invoiced mismatch'; fa = 'Received vs invoiced mismatch';
							|it = 'Non corrispondono alle bolle';
							|pl = 'Nie odpowiadają listom przewozowym';
							|tr = 'İrsaliyelere uygun değil.'"), False, PictureLib.DiscrepancyOfGoodsNoteAndInvoice);
	ChoiceList.Add("4", NStr("vi = 'Không có sơ đồ đặt hàng được sử dụng';
							|ru = 'Не используется ордерная схема';
							|en = 'Warehouse management is not used'; fa = 'Warehouse management is not used';
							|it = 'Lo schema dei mandati non viene utilizzato';
							|pl = 'Nie jest używany schemat zleceń';
							|tr = 'Ambar yönetimi şeması kullanılmamaktadır'"), False, PictureLib.AnEmptyPicture);
	
EndProcedure

&AtServer
Function QueryTextBalancesOfCustomerOrders()
	QueryText = 
	"SELECT ALLOWED
	|	TableOverridable.ReferenceOrder AS Ref,
	|	TableOverridable.Warehouse AS Warehouse,
	|	CASE
	|		WHEN NOT TableOverridable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|		OR TableOverridable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|		AND TableOverridable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue > &CurrentDate
	|			THEN 4
	|		ELSE 0
	|	END AS OrderStatusTime,
	|	CASE
	|		WHEN WarehousesOverridable.IsFolder
	|		AND WarehousesOverridable.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SplitInvoiceByWarehouses,
	|	CASE
	|		WHEN WarehousesOverridable.IsFolder
	|		AND WarehousesOverridable.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrdersAndInvoices)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CombineSalesByWarehouse
	|FROM
	|	InformationRegister.ShipmentAndReturnReferencesToFulfill AS TableOverridable
	|		LEFT JOIN Catalog.Warehouses AS WarehousesOverridable
	|		ON WarehousesOverridable.Ref = TableOverridable.Warehouse
	|WHERE
	|	(TableOverridable.Warehouse = &Warehouse
	|	OR &Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|	AND (TableOverridable.ReferenceOrder REFS Document.SalesOrder
	|	OR TableOverridable.ReferenceOrder REFS Document.RequestForReturnOfGoodsFromCustomer)
	|	AND
	|		TableOverridable.DocumentStateToRegister <> VALUE(Enum.StateOfRegisteringDocumentsByReference.Decorated)
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	TableOverridable.Ref AS SalesOrder,
	|	TableOverridable.Warehouse AS Warehouse
	|INTO TueRegistrationDocuments
	|FROM
	|	TueBalancesOnCustomerSOrder AS TableOverridable
	|
	|INDEX BY
	|	Ref,
	|	Warehouse
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TueRegistrationDocumentsOverridable.Warehouse AS Warehouse
	|INTO TueRegistrationDocumentsWarehouses
	|FROM
	|	TueRegistrationDocuments AS TueRegistrationDocumentsOverridable
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SalesOrdersOverridable.SalesOrder AS SalesOrder,
	|	SalesOrdersOverridable.Warehouse AS Warehouse
	|INTO TueDocumentsSelected
	|FROM
	|	AccumulationRegister.DeleteSalesOrders AS SalesOrdersOverridable
	|		INNER JOIN TueRegistrationDocumentsWarehouses AS TueRegistrationDocumentsWarehousesOverridable
	|		ON TueRegistrationDocumentsWarehousesOverridable.Warehouse = SalesOrdersOverridable.Warehouse
	|WHERE
	|	SalesOrdersOverridable.Active
	|	AND SalesOrdersOverridable.ToRegister > 0
	|	AND SalesOrdersOverridable.RecordType = VALUE(AccumulationRecordType.Expense)
	|
	|INDEX BY
	|	SalesOrder,
	|	Warehouse
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOverridable.SalesOrder AS SalesOrder,
	|	TableOverridable.Warehouse AS Warehouse
	|INTO TueThereAreInvoices
	|FROM
	|	TueRegistrationDocuments AS TableOverridable
	|		INNER JOIN TueDocumentsSelected AS DocumentsSelectedRedefined
	|		ON TableOverridable.SalesOrder = DocumentsSelectedRedefined.SalesOrder
	|		AND TableOverridable.Warehouse = DocumentsSelectedRedefined.Warehouse
	|
	|INDEX BY
	|	SalesOrder,
	|	Warehouse
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOverridable.Ref AS Ref,
	|	TableOverridable.Warehouse AS Warehouse,
	|	CASE
	|		WHEN NOT TableThereAreInvoicesOverridable.SalesOrder IS NULL
	|			THEN 2
	|		ELSE 1
	|	END AS InvoiceStatusVremya,
	|	TableOverridable.OrderStatusTime AS OrderStatusTime,
	|	TableOverridable.SplitInvoiceByWarehouses AS SplitInvoiceByWarehouses,
	|	TableOverridable.CombineSalesByWarehouse AS CombineSalesByWarehouse
	|INTO WTheStateOfTheInvoice
	|FROM
	|	TueBalancesOnCustomerSOrder AS TableOverridable
	|		LEFT JOIN TueThereAreInvoices AS TableThereAreInvoicesOverridable
	|		ON (TableThereAreInvoicesOverridable.SalesOrder = TableOverridable.Ref)
	|		AND (TableThereAreInvoicesOverridable.Warehouse = TableOverridable.Warehouse)
	|
	|INDEX BY
	|	Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOverridable.DocumentShipments AS DocumentShipments,
	|	TableOverridable.Warehouse AS Warehouse,
	|	TableOverridable.Products AS Products,
	|	TableOverridable.Characteristic AS Characteristic,
	|	TableOverridable.Series AS Series,
	|	TableOverridable.Purpose AS Purpose,
	|	TableOverridable.ToShipBalance -
	|		TableOverridable.AssembledBalance = TableOverridable.ToRegisterBalance AS TheRemainderIsEqualTo
	|INTO TueLeftoversGoodsToBeShipped
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(, (Warehouse = &Warehouse
	|	OR &Warehouse = VALUE(Catalog.Warehouses.EmptyRef))
	|	AND (DocumentShipments REFS Document.SalesOrder
	|	OR DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|	OR DocumentShipments REFS Document.CustomerInvoice)) AS TableOverridable
	|
	|INDEX BY
	|	DocumentShipments
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	TableOverridable.DocumentShipments AS DocumentShipments,
	|	TableOverridable.Warehouse AS Warehouse
	|INTO TueShippingDocuments
	|FROM
	|	TueLeftoversGoodsToBeShipped AS TableOverridable
	|
	|INDEX BY
	|	DocumentShipments,
	|	Warehouse
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TueShippingDocumentsOverridable.Warehouse AS Warehouse
	|INTO TueShippingDocumentsWarehouses
	|FROM
	|	TueShippingDocuments AS TueShippingDocumentsOverridable
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	GoodsForIssueOverridable.DocumentShipments AS DocumentShipments,
	|	GoodsForIssueOverridable.Warehouse AS Warehouse
	|INTO TTGoodsForShipmentOverridable
	|FROM
	|	AccumulationRegister.GoodsForIssue AS GoodsForIssueOverridable
	|		INNER JOIN TueShippingDocumentsWarehouses AS TueShippingDocumentsWarehousesOverridable
	|		ON TueShippingDocumentsWarehousesOverridable.Warehouse = GoodsForIssueOverridable.Warehouse
	|WHERE
	|	GoodsForIssueOverridable.Active
	|	AND GoodsForIssueOverridable.RecordType = VALUE(AccumulationRecordType.Expense)
	|GROUP BY
	|	GoodsForIssueOverridable.DocumentShipments,
	|	GoodsForIssueOverridable.Warehouse
	|HAVING
	|	SUM(GoodsForIssueOverridable.ToShip) > 0
	|
	|UNION
	|
	|SELECT
	|	GoodsForIssueOverridable.DocumentShipments AS DocumentShipments,
	|	GoodsForIssueOverridable.Warehouse AS Warehouse
	|FROM
	|	AccumulationRegister.GoodsForIssue AS GoodsForIssueOverridable
	|		INNER JOIN TueShippingDocumentsWarehouses AS TueShippingDocumentsWarehousesOverridable
	|		ON TueShippingDocumentsWarehousesOverridable.Warehouse = GoodsForIssueOverridable.Warehouse
	|WHERE
	|	GoodsForIssueOverridable.Active
	|	AND GoodsForIssueOverridable.ToShip > 0
	|	AND GoodsForIssueOverridable.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	
	|GROUP BY
	|	GoodsForIssueOverridable.DocumentShipments,
	|	GoodsForIssueOverridable.Warehouse
	|HAVING
	|	SUM(GoodsForIssueOverridable.Assembled) > 0
	|
	|INDEX BY
	|	DocumentShipments,
	|	Warehouse
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOverridable.DocumentShipments AS DocumentShipments,
	|	TableOverridable.Warehouse AS Warehouse
	|INTO TueThereAreOrders_3
	|FROM
	|	TueShippingDocuments AS TableOverridable
	|		INNER JOIN TTGoodsForShipmentOverridable AS TTGoodsForShipmentOverridable
	|		ON TableOverridable.Warehouse = TTGoodsForShipmentOverridable.Warehouse
	|		AND TableOverridable.DocumentShipments = TTGoodsForShipmentOverridable.DocumentShipments
	|
	|INDEX BY
	|	DocumentShipments,
	|	Warehouse
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOverridable.DocumentShipments AS Ref,
	|	TableOverridable.Warehouse AS Warehouse,
	|	CASE
	|		WHEN TableHasOrdersOverridable.DocumentShipments IS NULL
	|		AND
	|		NOT CatWarehousesOverridable.Ref IS NULL
	|			THEN 1
	|		WHEN TableOverridable.TheRemainderIsEqualTo
	|			THEN 0
	|		ELSE 3
	|	END AS OrderStatusTime
	|INTO TueOrderStatus
	|FROM
	|	TueLeftoversGoodsToBeShipped AS TableOverridable
	|		LEFT JOIN TueThereAreOrders_3 AS TableHasOrdersOverridable
	|		ON (TableHasOrdersOverridable.DocumentShipments = TableOverridable.DocumentShipments)
	|		AND (TableHasOrdersOverridable.Warehouse = TableOverridable.Warehouse)
	|		LEFT JOIN Catalog.Warehouses AS CatWarehousesOverridable
	|		ON (CatWarehousesOverridable.Ref = TableOverridable.Warehouse)
	|		AND (CatWarehousesOverridable.UseWarehouseManagemantSystemForGoodsIssue)
	|		AND (CatWarehousesOverridable.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDate)
	|WHERE
	|	CASE
	|		WHEN TableHasOrdersOverridable.DocumentShipments IS NULL
	|		AND
	|		NOT CatWarehousesOverridable.Ref IS NULL
	|			THEN 1
	|		WHEN TableOverridable.TheRemainderIsEqualTo
	|			THEN 0
	|		ELSE 3
	|	END > 0
	|
	|INDEX BY
	|	TableOverridable.DocumentShipments
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	CASE
	|		WHEN WTheStateOfTheInvoiceOverridable.Ref IS NULL
	|			THEN TueOrderStatusOverridable.Ref
	|		ELSE WTheStateOfTheInvoiceOverridable.Ref
	|	END AS DocumentShipments,
	|	CASE
	|		WHEN WTheStateOfTheInvoiceOverridable.Warehouse IS NULL
	|			THEN TueOrderStatusOverridable.Warehouse
	|		ELSE WTheStateOfTheInvoiceOverridable.Warehouse
	|	END AS Warehouse,
	|	ISNULL(WTheStateOfTheInvoiceOverridable.InvoiceStatusVremya, 0) AS InvoiceStatusVremya,
	|	ISNULL(TueOrderStatusOverridable.OrderStatusTime,
	|		WTheStateOfTheInvoiceOverridable.OrderStatusTime) AS OrderStatusTime,
	|	ISNULL(WTheStateOfTheInvoiceOverridable.SplitInvoiceByWarehouses, FALSE) AS SplitInvoiceByWarehouses,
	|	ISNULL(WTheStateOfTheInvoiceOverridable.CombineSalesByWarehouse, FALSE) AS CombineSalesByWarehouse
	|INTO TueNewOrders
	|FROM
	|	WTheStateOfTheInvoice AS WTheStateOfTheInvoiceOverridable
	|		FULL JOIN TueOrderStatus AS TueOrderStatusOverridable
	|		ON WTheStateOfTheInvoiceOverridable.Ref = TueOrderStatusOverridable.Ref
	|
	|INDEX BY
	|	DocumentShipments
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	GoodsForIssueOverridable.DocumentShipments AS ReferenceOrder,
	|	GoodsForIssueOverridable.DocumentShipments AS Ref,
	|	GoodsForIssueOverridable.DocumentShipments AS SalesOrder,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).DeletionMark
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).DeletionMark
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.CustomerInvoice).DeletionMark
	|	END AS DeletionMark,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).Number
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Number
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).Number
	|	END AS Number,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).Date
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Date
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).Date
	|	END AS DocumentDate,
	|	VALUETYPE(GoodsForIssueOverridable.DocumentShipments) AS TypeOfOrder_,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).Posted
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).Posted
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).Posted
	|	END AS Posted,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).Partner
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).Partner
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).Partner
	|	END AS Partner,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).Counterparty
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).Counterparty
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).Counterparty
	|	END AS Counterparty,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).Organization
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).Organization
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).Organization
	|	END AS Organization,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).Terms
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).Terms
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).Terms
	|	END AS Terms,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).Contract
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).Contract
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).Contract
	|	END AS Contract,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).SalesOpportunity
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).SalesOpportunity
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).SalesOpportunity
	|	END AS SalesOpportunity,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).Currency
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).Currency
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).Currency
	|	END AS Currency,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).DocumentAmount
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).ReplacementAmount
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).DocumentAmount
	|		ELSE 0
	|	END AS DocumentAmount,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).PaymentSchedule
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).PaymentSchedule
	|	END AS PaymentSchedule,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).Warehouse
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).Warehouse
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).Warehouse
	|	END AS TheStockCaps,
	|	GoodsForIssueOverridable.Warehouse AS Warehouse,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).Status
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).Status
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).Status
	|	END AS Status,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).Manager
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).Manager
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).Manager
	|	END AS Manager,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).DocumentBasis
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN UNDEFINED
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).SalesOrder
	|	END AS DocumentBasis,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).Priority
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).Priority
	|	END AS Priority,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).BusinessOperation
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).BusinessOperation
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.CustomerInvoice).BusinessOperation
	|	END AS BusinessOperation,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).CashAccount
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).CashAccount
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.CustomerInvoice).CashAccount
	|	END AS CashAccount,
	|	CASE
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).DeliveryMethod
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|				Document.RequestForReturnOfGoodsFromCustomer).DeliveryMethod
	|		WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.CustomerInvoice
	|			THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.CustomerInvoice).DeliveryMethod
	|	END AS DeliveryMethod,
	|	GoodsForIssueOverridable.InvoiceStatusVremya AS InvoiceStatus,
	|	GoodsForIssueOverridable.OrderStatusTime AS NoteState,
	|	CASE
	|		WHEN CASE
	|			WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|				THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).Priority
	|			WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|				THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|					Document.RequestForReturnOfGoodsFromCustomer).Priority
	|		END IN
	|			(SELECT TOP 1
	|				Priorities.Ref AS Priority
	|			FROM
	|				Catalog.Priorities AS Priorities
	|			ORDER BY
	|				Priorities.AddlOrderingAttribute)
	|			THEN 0
	|		WHEN CASE
	|			WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.SalesOrder
	|				THEN CAST(GoodsForIssueOverridable.DocumentShipments AS Document.SalesOrder).Priority
	|			WHEN GoodsForIssueOverridable.DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
	|				THEN CAST(GoodsForIssueOverridable.DocumentShipments AS
	|					Document.RequestForReturnOfGoodsFromCustomer).Priority
	|		END IN
	|			(SELECT TOP 1
	|				Priorities.Ref AS Priority
	|			FROM
	|				Catalog.Priorities AS Priorities
	|			ORDER BY
	|				Priorities.AddlOrderingAttribute DESC)
	|			THEN 2
	|		ELSE 1
	|	END AS PictureOfPriority,
	|	GoodsForIssueOverridable.SplitInvoiceByWarehouses AS SplitInvoiceByWarehouses,
	|	GoodsForIssueOverridable.CombineSalesByWarehouse AS CombineSalesByWarehouse
	|FROM
	|	TueNewOrders AS GoodsForIssueOverridable
	|WHERE
	|	NOT GoodsForIssueOverridable.DocumentShipments.Ref IS NULL";
	Return QueryText;
EndFunction

&AtServer
Procedure FillInCommandsByVisibilityCondition()

	ArrayOfShipmentOrderTypes = New Array;
	ArrayOfShipmentOrderTypes.Add(Type("DocumentRef.SalesOrder"));
	ArrayOfShipmentOrderTypes.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	ArrayOfShipmentOrderTypes.Add(Type("DocumentRef.GoodsShipmentToCustomer"));
	
	ShipmentTypeArray = New Array;
	ShipmentTypeArray.Add(Type("DocumentRef.GoodsShipmentToCustomer"));
	
	CommandsByVisibilityCondition = New Structure();
	For Each CommandItem In Items.CommandsToIssueListForTransferOfOwnership.ChildItems Do
		
		TypesArray = ArrayOfShipmentOrderTypes;
		CommandName = CommandItem.Name;
		If CommandName = "IssueShipmentCorrection" Then
			TypesArray = ShipmentTypeArray;
		EndIf;
		CommandsByVisibilityCondition.Insert(CommandName, New TypeDescription(TypesArray));
	
	EndDo;

EndProcedure

&AtClient
Procedure UpdateCommandsByVisibilityCondition()
	
	Var DocumentType;
	
	CurrentData = Items.ListForTransferOfOwnership.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	DocumentType = TypeOf(CurrentData.Ref);
	For Each StructureItem In CommandsByVisibilityCondition Do
		
		CommandItem = Items[StructureItem.Key];
		Visible = True;
		If Not StructureItem.Value.ContainsType(DocumentType) Then
			Visible = False;
		EndIf;
		CommandItem.Visible = Visible;
	EndDo;

EndProcedure

&AtServer
Procedure SetOrganizationAndWarehouseParametersAtServer()

	CommonClientServer.SetDynamicListParameter(ListReferencesForRegistration, "Organization", Organization);
	CommonClientServer.SetDynamicListParameter(ListForTransferOfOwnership, "Organization", Organization);
	CommonClientServer.SetDynamicListParameter(ListReferencesForRegistration, "Warehouse", Warehouse);

EndProcedure

#Region CreatingNewDocuments

&AtClient
Procedure RegisterSale()
	
	CheckWarehouses = FillInListOfDocumentsAccordingToForm();

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", ThisForm);
	AdditionalParameters.Insert("ReferencesArrray", ListOfOrders_);
	AdditionalParameters.Insert("ByNotes", ByNotes);
	AdditionalParameters.Insert("ArrangeShipment", ArrangeShipment);
	AdditionalParameters.Insert("NameOfShipmentCommand", NameOfShipmentCommand);
	AdditionalParameters.Insert("Warehouse", Warehouse);
	AdditionalParameters.Insert("CheckWarehouses", CheckWarehouses);
	AdditionalParameters.Insert("ObjectKey", "DataProcessor.LogOfSalesDocuments.Form.ToRegisterInvoices/CurrentData");
	
	SalesClient.GenerateSetOfDocumentsChallenge(Undefined, AdditionalParameters);
	
	Items.ListReferencesForRegistration.Refresh();
		
EndProcedure

&AtClient
Function FillInListOfDocumentsAccordingToForm()
	
	CheckWarehouses = New Map;	
	ListOfOrders_.Clear();
	
	SelectedRows = Items.ListReferencesForRegistration.SelectedRows;
	For Each String In SelectedRows Do
		FoundRow = Items.ListReferencesForRegistration.RowData(String);
		
		AddedRow = ListOfOrders_.Add();
		FillPropertyValues(AddedRow, FoundRow);
		
		If FoundRow.CombineSalesByWarehouse Then
			WarehousesByRef = CheckWarehouses.Get(FoundRow.Ref);
			If WarehousesByRef = Undefined Then
				WarehousesByRef = New Array;
				WarehousesByRef.Add(PredefinedValue("Catalog.Warehouses.EmptyRef"));
			EndIf;
			
			WarehousesByRef.Add(FoundRow.Warehouse);
			CheckWarehouses.Insert(FoundRow.Ref, WarehousesByRef);
		EndIf;
	EndDo;
	
	Return CheckWarehouses;
	
EndFunction

&AtClient
Function LogParameters(Var_PurposeUseKey)
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",Organization);
	QuickFilterStructure.Insert("Warehouse",Warehouse);
	
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure",QuickFilterStructure);
	LogParameters.Insert("WorkplaceName","LogOfSalesDocuments");
	LogParameters.Insert("FormAssignmentKey",Var_PurposeUseKey);
	LogParameters.Insert("JournalSynonym",NStr("vi = 'Chứng từ bán hàng';
												|ru = 'Документы продажи';
												|en = 'Sales documents'; fa = 'اسناد فروش';
												|it = 'Documenti di vendita';
												|pl = 'Dokumenty sprzedaży';
												|tr = 'Satış belgeleri'"));
	
	Return LogParameters;
	
EndFunction

&AtClient
Procedure ToIssueDocumentsForShipment()
	
	ListOfOrders_.Clear();
	
	SelectedRows = Items.ListForTransferOfOwnership.SelectedRows;
	For Each String In SelectedRows Do
		FoundRow = Items.ListForTransferOfOwnership.RowData(String);
		AddedRow = ListOfOrders_.Add();
		FillPropertyValues(AddedRow, FoundRow);
	EndDo;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", ThisObject);
	AdditionalParameters.Insert("ReferencesArrray", ListOfOrders_);
	AdditionalParameters.Insert("ByNotes", False);
	AdditionalParameters.Insert("ArrangeShipment", True);
	AdditionalParameters.Insert("NameOfShipmentCommand", NameOfShipmentCommand);
	AdditionalParameters.Insert("Warehouse", Warehouse);
	AdditionalParameters.Insert("ObjectKey", "DataProcessor.LogOfSalesDocuments.Form.ToRegisterInvoices/CurrentData");
	
	SalesClient.GenerateSetOfDocumentsChallenge(Undefined, AdditionalParameters);
	
	Items.ListForTransferOfOwnership.Refresh();
		
EndProcedure

#Region SettingUpSetOfDocuments

&AtClient
Procedure GetASetOfDocumentsSetup(Command)
	
	ObjectKey = "DataProcessor.LogOfSalesDocuments.Form.ToRegisterInvoices/CurrentData";
	
	Notification = New CallbackDescription("GetASetOfDocumentsSetupCompletion", ThisObject, ObjectKey);
	
	FormParameters = SalesServerCall.GetASetOfDocumentsSetup(ObjectKey);
	OpenForm("DataProcessor.LogOfSalesDocuments.Form.ParametersOfSalesDocumentCreation", FormParameters,
		ThisForm, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure GetASetOfDocumentsSetupCompletion(Result, ObjectKey) Export 
	
	If Result <> Undefined Then
		SalesServerCall.SaveDocumentSetSettings(Result, ObjectKey);
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#Region HyperlinkSeeAlsoInWork

&AtServer
Procedure CreateHyperlinkSeeAlsoIn()

	RowsArray = New Array;
	TitleLine_ = NStr("vi = 'Xem thêm:';
						|ru = 'См. также: ';
						|en = 'See also:'; fa = 'همچنین ببینید:';
						|it = 'See also:';
						|pl = 'See also:';
						|tr = 'Ayrıca bakınız:'");
	RowsArray.Add(TitleLine_);
	
	HyperlinkText = NStr("vi = 'Chứng từ bán hàng (hóa đơn đã lập)';
						|ru = 'Документы продажи (оформленные накладные)';
						|en = 'Sales documents (issued invoices)'; fa = 'Sales documents (issued invoices)';
						|it = 'Sales documents (issued invoices)';
						|pl = 'Sales documents (issued invoices)';
						|tr = 'Satış belgeleri (oluşturulan irsaliyeler)'");
	NameOfFormToOpen_ = "DataProcessor.LogOfSalesDocuments.Form.DocumentsList";
	Hyperlink = New FormattedString(HyperlinkText,,,, NameOfFormToOpen_);
	RowsArray.Add(Hyperlink);
	RowsArray.Add("; ");
	
	HyperlinkText = NStr("vi = 'Hóa đơn GTGT (cần lập)';
						|ru = 'Счета-фактуры (к оформлению)';
						|en = 'Tax invoices (for registration)'; fa = 'Tax invoices (for registration)';
						|it = 'Tax invoices (for registration)';
						|pl = 'Tax invoices (for registration)';
						|tr = 'Faturalar (oluşturulması için)'");
	NameOfFormToOpen_ = "Document.InvoiceIssued.Form.DocumentsListForm";
	Hyperlink = New FormattedString(HyperlinkText,,,, NameOfFormToOpen_);
	RowsArray.Add(Hyperlink);
	
	If UseShipmentWithDeferredTransferOfTitle2_5 Then
		HyperlinkText = NStr("vi = 'Hóa đơn điều chỉnh/Hóa đơn sửa đổi về giao hàng (cần lập chứng từ)';
							|ru = 'ИСФ/КСФ по отгрузкам (к оформлению)';
							|en = 'Replacement/corrective tax invoice for shipments (for registration)'; fa = 'Replacement/corrective tax invoice for shipments (for registration)';
							|it = 'Replacement/corrective tax invoice for shipments (for registration)';
							|pl = 'Replacement/corrective tax invoice for shipments (for registration)';
							|tr = 'Sevkiyat Faturası/Düzeltme Faturası için sevkiyatlar (oluşturulmak üzere)'");
		NameOfFormToOpen_ = "Document.InvoiceIssued.Form.WorkplaceFormForProcessingCorrectedInvoicesForShipments";
		Hyperlink = New FormattedString(HyperlinkText,,,, NameOfFormToOpen_);
		RowsArray.Add("; ");
		RowsArray.Add(Hyperlink);
	EndIf;
	
	SeeAlsoInProgress = New FormattedString(RowsArray)

EndProcedure

#EndRegion

#EndRegion
