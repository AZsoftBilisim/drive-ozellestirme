
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	Warehouse = Catalogs.Warehouses.DefaultWarehouse();
	
	If Parameters.Property("Status", Status) Then
		StatusWhenChangedOnClientOnServer(ThisForm);
	Else
		Status = "All";
	EndIf;
	
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Warehouse", Warehouse);
		QuickFilterStructure.Property("Premise", Premise);	
	Else
		QuickFilterStructure = New Structure("Warehouse, Premise", Warehouse, Premise);
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(RecountsList, 
			"Warehouse", 
			Warehouse, 
			QuickFilterStructure,
			True);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(RecountsList, 
			"Premise", 
			Premise, 
			QuickFilterStructure,
			True);
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise);
	
	SetRoomVisibility();
	UpdateInformationAboutDiscrepancies();
	
	If Not AccessRight("Insert", Metadata.Documents.InventoryRecount) Then
		
		Items.CreateAJobToRecalculateANonAddressWarehouse.Visible = False;
		Items.AssignAssignee.Visible = False;
		
		Items.CreateAJobToRecalculateTheAddressWarehouse.Visible = False;
		Items.GenerateTasksForRecalculatingTheAddressWarehouse.Visible = False;
		Items.AssignAPerformerToAnAddressWarehouse.Visible = False;
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	TypesList = RecountsList.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.GroupsPrefix = "AddressWarehouse";
	PlacementParameters.CommandBar = Items.GroupCommandPanelConversionTasksAddressWarehouse;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.GroupsPrefix = "UnaddressedWarehouse";
	PlacementParameters.CommandBar = Items.GroupCommandPanelRecalculationTasksNonAddressWarehouse;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	SetVisibilityOfCommands();
	SetVisibilityOfContextReportCommands();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "RecountsList.Date", Items.RecountsListDate.Name);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(
		ThisObject,
		Items.GroupCommandPanelRecalculationTasksNonAddressWarehouse);
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(
		ThisObject,
		Items.GroupCommandPanelConversionTasksAddressWarehouse);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
		
	EnableWaitingHandlerForMonitoringOperationOfBackgroundJobsFormingQueue();

	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	
	If EventName = "Write_InventoryRecount" Then
		If Items.PagesInformationOnDiscrepancies.Visible Then
			UpdateTheListOnServer()
		Else
			Items.RecountsList.Refresh();
		EndIf;
	ElsIf EventName = "Creation_WarehouseCertificates" Then
		If Items.PagesInformationOnDiscrepancies.Visible Then
			UpdateInformationAboutDiscrepancies();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource) 
	
	If ChoiceSource.FormName = "Catalog.Users.Form.ListForm" 
		And TypeOf(ValueSelected) = Type("CatalogRef.Users") Then
		// The purpose of the performer is to select the user
		
		ArrayOfChangedDocuments = ProcessingArtistSelectionOnServer(ValueSelected);
		
		If ArrayOfChangedDocuments.Count() > 0 Then
			
			MessageText = NStr("vi = 'Đối với %ProcessedItemsCount% / %TotalCount1% được chọn trong danh sách nhiệm vụ kiểm đếm đã ấn định người thực hiện %Performer%';
								|ru = 'Для %ProcessedItemsCount% из %TotalCount1% выделенных в списке заданий на пересчет назначен исполнитель %Performer%';
								|en = 'Assignee %Performer% is assigned for %ProcessedItemsCount% out of %TotalCount1% selected in the list of recount jobs'; fa = 'Assignee %Performer% is assigned for %ProcessedItemsCount% out of %TotalCount1% selected in the list of recount jobs';
								|it = 'Per %ProcessedItemsCount% di %TotalCount1% task di ricalcolo selezionati nell''elenco è assegnato l''esecutore %Performer%';
								|pl = 'Aby %ProcessedItemsCount% z %TotalCount1% zaznaczonych na liście zadań na przeliczanie mianowany wykonawca %Performer%';
								|tr = '%ProcessedItemsCount% için %TotalCount1%''dan  seçili görevler listesinden yeniden hesaplama için atanan atandı %Performer%'");
			MessageText = StrReplace(MessageText, "%ProcessedItemsCount%", ArrayOfChangedDocuments.Count());
			MessageText = StrReplace(MessageText, "%TotalCount1%",        ListOfSelectedDocuments.Count());
			MessageText = StrReplace(MessageText, "%Performer%",            ValueSelected);
			
			TitleText = NStr("vi = 'Đã ấn định người thực hiện %Performer%';
							|ru = 'Исполнитель %Performer% назначен';
							|en = 'Assignee %Performer% is assigned'; fa = 'Assignee %Performer% is assigned';
							|it = 'L''esecutore %Performer% è assegnato';
							|pl = 'Wykonawca %Performer% mianowany';
							|tr = '%Performer% atanan atandı'");
			TitleText = StrReplace(TitleText, "%Performer%", ValueSelected);
			ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
			
		Else
			
			MessageText = NStr("vi = 'Chưa ấn định người thực hiện %Performer% đối với nhiệm vụ kiểm đếm nào';
								|ru = 'Исполнитель %Performer% не назначен ни для одного задания на пересчет';
								|en = 'Assignee %Performer% is not assigned for any recount job'; fa = 'Assignee %Performer% is not assigned for any recount job';
								|it = 'L''esecutore %Performer% non è assegnato per alcun task di ricalcolo';
								|pl = 'Wykonawca %Performer% nie jest mianowany do żadnego zadania na przeliczanie';
								|tr = 'Atanan %Performer% herhangi bir yeniden hesaplama görevine atanmadı'");
			MessageText = StrReplace(MessageText, "%Performer%", ValueSelected);
			
			TitleText = NStr("vi = 'Chưa ấn định người thực hiện %Performer%';
							|ru = 'Исполнитель %Performer% не назначен';
							|en = 'Assignee %Performer% is not assigned'; fa = 'Assignee %Performer% is not assigned';
							|it = 'L''esecutore %Performer% non è assegnato';
							|pl = 'Wykonawca %Performer% nie jest mianowany';
							|tr = '%Performer% atanan atanmadı'");
			TitleText = StrReplace(TitleText, "%Performer%", ValueSelected);
			ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	TMCommonUse.ClearFormSettingsOrDetailsFromNonexistentLinks(Settings, ThisObject);

	If QuickFilterStructure <> Undefined Then
		
		If QuickFilterStructure.Property("Warehouse") And ValueIsFilled(QuickFilterStructure.Warehouse) Then
			Warehouse = QuickFilterStructure.Warehouse;
		EndIf;
		
		If QuickFilterStructure.Property("Premise") And ValueIsFilled(QuickFilterStructure.Premise) Then
			Premise = QuickFilterStructure.Premise;
		EndIf;
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(RecountsList, 
			"Warehouse", 
			Warehouse, 
			DataCompositionComparisonType.Equal,, 
			True);
			
	CommonClientServer.SetDynamicListFilterItem(RecountsList, 
			"Premise", 
			Premise, 
			DataCompositionComparisonType.Equal,, 
			True);
	
	SetRoomVisibility();
	SetVisibilityOfRecalculationsListCommandPanelPages();
	UpdateInformationAboutDiscrepancies();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	EnableWaitingHandlerForMonitoringOperationOfBackgroundJobsFormingQueue()
	
EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	
	StorageWhenChangedOnServer();
	EnableWaitingHandlerForMonitoringOperationOfBackgroundJobsFormingQueue();

EndProcedure

&AtClient
Procedure ThereIsAProblemURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "StartGeneration" Then
		
		ClearMessages();
		StartCreatingAdjustments();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AttentionClick(Item)
	ClearMessages();
	StartCreatingAdjustments();
EndProcedure


&AtClient
Procedure StatusOnChange(Item)
	StatusWhenChangedOnClientOnServer(ThisForm);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRecountsList

&AtClient
Procedure RecountsListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure RecountsListOnChange(Item)
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.RecountsList);
EndProcedure
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure GenerateConversionTasks(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	OpenForm("Document.InventoryRecount.Form.SettingsFormOfInventoryRecountJobsCreation", 
			FormParameters, 
			ThisForm,,,,, 
			FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CreateRecountJob(Command)
	
	FillingValues = New Structure;
	FillingValues.Insert("Warehouse", Warehouse);
	FillingValues.Insert("Premise", Premise); 
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillingValues);	
		
	OpenForm("Document.InventoryRecount.ObjectForm", FormParameters);
		
EndProcedure

&AtClient
Procedure AssignAssignee(Command)
	
	ClearMessages();
	                                  
	ArrayOfSelectedDocuments_ = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.RecountsList);
	
	If ArrayOfSelectedDocuments_.Count() = 0 Then
		Return;
	EndIf;
	
	ListOfSelectedDocuments.Clear();
	
	For Each SelectedRow In ArrayOfSelectedDocuments_ Do
		ListOfSelectedDocuments.Add(SelectedRow);	
	EndDo;
	
	OpenForm("Catalog.Users.ChoiceForm", New Structure("ChoiceMode", True), ThisForm,,,,,
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.RecountsList);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.RecountsList);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Items.RecountsList);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure OpenTheGoodsInTheProcessOfShipmentReport(Command)
	FormParameters = New Structure("UserSettingsKey, PurposeUseKey, VariantKey, GenerateOnOpen, Filter, DoNotUseFixedSettings");
	FormParameters.UserSettingsKey	= "RecalculationOfProductsListForm";
	FormParameters.PurposeUseKey	= "RecalculationOfProductsListForm";
	FormParameters.VariantKey					= "ShippedGoods";
	FormParameters.GenerateOnOpen		= True;
	FormParameters.Filter						= New Structure;
	If Not Warehouse.IsEmpty() Then
		FormParameters.Filter.Insert("Warehouse",		Warehouse);
	EndIf;
	If Not Premise.IsEmpty() Then
		FormParameters.Filter.Insert("Premise",	Premise);
	EndIf;

	OpenForm("Report.WarehouseStock.Form", FormParameters, ThisForm);
EndProcedure

&AtClient
Procedure UpdateList(Command)
	If Items.PagesInformationOnDiscrepancies.Visible Then
		UpdateTheListOnServer();
	Else
		Items.RecountsList.Refresh();
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RecountsListStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseInventoryRecountStatuses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.InventoryRecount.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.RecountsList.CurrentRow = ReferencesArrray[0];
		ShowValue(,ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#Region BackgroundTaskForCreatingAdjustments

&AtServer
Procedure StartCreatingAdjustments()
	
	HasError = WarehousesServer.GenerateAdjustmentsForSurplusShortagesByProductLocationsForAllWarehousePremises(Warehouse);
	
	Items.StateOfAutomaticAdjustmentGeneration.Visible = HasError;
	
EndProcedure

&AtClient
Procedure MonitoringOperationOfBackgroundQueueFormationTasks()
		
	MonitoringOperationOfBackgroundQueueGenerationTasksOnServer();
			
EndProcedure

&AtServer
Procedure MonitoringOperationOfBackgroundQueueGenerationTasksOnServer()
			
	Items.StateOfAutomaticAdjustmentGeneration.Visible =
		WarehousesServer.ThereArePremisesForWhichThereIsNoBackgroundTaskForFormationOfAdjustmentsForSurplusShortagesInCommodityPlaces(Warehouse);
				
EndProcedure

&AtClient
Procedure EnableWaitingHandlerForMonitoringOperationOfBackgroundJobsFormingQueue()
	
	If Not UseBinLocationWarehousing Then
		Items.StateOfAutomaticAdjustmentGeneration.Visible = False;
		DetachIdleHandler("MonitoringOperationOfBackgroundQueueFormationTasks");
		Return;
	EndIf; 
	
	MonitoringOperationOfBackgroundQueueFormationTasks();
	AttachIdleHandler("MonitoringOperationOfBackgroundQueueFormationTasks", 600);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetRoomVisibility()
	
	If WarehousesServer.UseWarerooms(Warehouse) Then
		Items.FiltersGroup.CurrentPage = Items.GroupFiltersWithRoom;
	Else
		Items.FiltersGroup.CurrentPage = Items.GroupFiltersWithoutRoom;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfRecalculationsListCommandPanelPages()
	
	If WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise) Then
		Items.PageGroupHeaderOfTheRecalculationTask.CurrentPage = Items.GroupPageHeaderOfTheRecalculationTaskAddressWarehouse;
	Else
		Items.PageGroupHeaderOfTheRecalculationTask.CurrentPage = Items.GroupPageHeaderOfTheRecalculationTaskNonAddressWarehouse;
	EndIf;	
	
EndProcedure

&AtServer
Function ProcessingArtistSelectionOnServer(ValueSelected)
			
	Query = New Query;
	
	Query.Text = 
	"SELECT
	|	InventoryRecount.Ref AS Ref
	|FROM
	|	Document.InventoryRecount AS InventoryRecount
	|WHERE
	|	InventoryRecount.Performer <> &Performer
	|	AND InventoryRecount.Ref IN(&DocumentsArray)";
	
	Query.SetParameter("Performer", ValueSelected);
	Query.SetParameter("DocumentsArray", ListOfSelectedDocuments);
		
	SelectionOfDocuments = Query.Execute().Select();
	
	ArrayOfChangedDocuments = New Array;
	
	While SelectionOfDocuments.Next() Do
		
		Try
			DocumentObject = SelectionOfDocuments.Ref.GetObject();
			
			DocumentObject.Lock();
			
			DocumentObject.Performer = ValueSelected;
			
			DocumentObject.Write(DocumentWriteMode.Write);
			ArrayOfChangedDocuments.Add(SelectionOfDocuments.Ref);
		Except
			CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		EndTry;
		
	EndDo;
	
	Items.RecountsList.Refresh();
		
	Return ArrayOfChangedDocuments;

EndFunction

&AtServerNoContext
Function ThereAreDiscrepancies(Warehouse)
	Return DataProcessors.WarehouseGoodsIssueReceiptWizard.GoodsForRegistrationOfWarehouseActs(Warehouse).Count() > 0;
EndFunction

&AtServer
Procedure UpdateInformationAboutDiscrepancies()
	
	If Not ValueIsFilled(Warehouse)
		Or Not AccessRight("Use", Metadata.DataProcessors.WarehouseGoodsIssueReceiptWizard)
		Or Not WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Warehouse) Then
		Items.PagesInformationOnDiscrepancies.Visible = False;
		Return;
	Else
		Items.PagesInformationOnDiscrepancies.Visible = True;
	EndIf;
	
	If Not ValueIsFilled(Warehouse) Then
		Items.PagesInformationOnDiscrepancies.CurrentPage = Items.PageNoWarehouse;
	ElsIf ThereAreDiscrepancies(Warehouse) Then
		Items.PagesInformationOnDiscrepancies.CurrentPage = Items.PageDiscrepanciesExist;
	Else
		Items.PagesInformationOnDiscrepancies.CurrentPage = Items.PageNoDiscrepancies; 
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationThereAreDiscrepanciesURLProcessing(Item, Var_URL, StandardProcessing)

	StandardProcessing = False;
	
	FormParameters = New Structure("Warehouse", Warehouse);
	
	OpenForm("DataProcessor.WarehouseGoodsIssueReceiptWizard.Form", FormParameters, ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure StatusWhenChangedOnClientOnServer(Form)
	If Form.Status = "All" Then
		CommonClientServer.DeleteDynamicListFilterGroupItems(Form.RecountsList, "Status");
	ElsIf Form.Status = "OnlyNotCompleted" Then
		CommonClientServer.SetDynamicListFilterItem(
			Form.RecountsList, 
			"Status", 
			PredefinedValue("Enum.InventoryRecountStatuses.Completed2"), 
			DataCompositionComparisonType.NotEqual,, 
			True);	
	ElsIf Form.Status = "InProgress" Then
		CommonClientServer.SetDynamicListFilterItem(
			Form.RecountsList, 
			"Status", 
			PredefinedValue("Enum.InventoryRecountStatuses.InProgress"), 
			DataCompositionComparisonType.Equal,, 
			True);		
	ElsIf Form.Status = "EnteringResults" Then
		CommonClientServer.SetDynamicListFilterItem(
			Form.RecountsList, 
			"Status", 
			PredefinedValue("Enum.InventoryRecountStatuses.EnteringResults"), 
			DataCompositionComparisonType.Equal,, 
			True);
	ElsIf Form.Status = "Completed2" Then
		CommonClientServer.SetDynamicListFilterItem(
			Form.RecountsList, 
			"Status", 
			PredefinedValue("Enum.InventoryRecountStatuses.Completed2"), 
			DataCompositionComparisonType.Equal,, 
			True);
	ElsIf Form.Status = "Prepared2" Then
		CommonClientServer.SetDynamicListFilterItem(
			Form.RecountsList, 
			"Status", 
			PredefinedValue("Enum.InventoryRecountStatuses.Prepared2"), 
			DataCompositionComparisonType.Equal,, 
			True);
	Else
		Form.Status = "All";
		CommonClientServer.DeleteDynamicListFilterGroupItems(Form.RecountsList, "Status");
	EndIf;	
EndProcedure

&AtServer 
Procedure SetVisibilityOfContextReportCommands()
	NumberOfAvailableReports = 0;
	
	If AccessRight("View", Metadata.Reports.WarehouseStock) Then
		Items.OpenTheGoodsInTheProcessOfShipmentReport.Visible = True;
		NumberOfAvailableReports = NumberOfAvailableReports + 1;
	Else
		Items.OpenTheGoodsInTheProcessOfShipmentReport.Visible = False;
	EndIf;
	
	If NumberOfAvailableReports > 0 Then
		Items.PagesContextReports.CurrentPage = Items.PageAvailableReports;
	Else
		Items.PagesContextReports.CurrentPage = Items.PageNoAvailableReports;
	EndIf;
EndProcedure

&AtServer 
Procedure SetVisibilityOfCommands()
	
	ThereIsEditRight = AccessRight("Edit", Metadata.Documents.InventoryRecount);
	
	Items.CreateAJobToRecalculateANonAddressWarehouse.Visible	= ThereIsEditRight;
	Items.RecountsList.ChangeRowSet				= ThereIsEditRight;
	
EndProcedure

&AtServer
Procedure UpdateTheListOnServer()
	UpdateInformationAboutDiscrepancies();
	Items.RecountsList.Refresh();
EndProcedure

&AtServer
Procedure WarehouseOnChangeServer()
	
	CommonClientServer.SetDynamicListFilterItem(RecountsList, 
		"Warehouse", 
		Warehouse, 
		DataCompositionComparisonType.Equal,, 
		True);
	
	UseWarehouseManagemantSystemForGoodsSurplusesShortages =
		WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Warehouse);
			
	SetRoomVisibility();
	UpdateInformationAboutDiscrepancies();
	
	UseInventoryRecountStatuses = WarehousesServer.UseInventoryRecountStatuses(Warehouse);
	
	StorageWhenChangedOnServer();

EndProcedure

&AtServer
Procedure StorageWhenChangedOnServer()
	
	CommonClientServer.SetDynamicListFilterItem(RecountsList, 
		"Premise", 
		Premise, 
		DataCompositionComparisonType.Equal,, 
		True);
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise);
	
	SetVisibilityOfRecalculationsListCommandPanelPages();
	
EndProcedure

#EndRegion

#EndRegion
