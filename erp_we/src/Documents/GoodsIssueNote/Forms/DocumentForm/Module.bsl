#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurrentStatus; //client cache of the document status (needed to be able to roll back the status change by the user)

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisObject, "ShippedGoods");
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.ShippedGoods);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.GoodsByReferences);
	Else
		Items.GroupPages.CurrentPage = Items.GroupOfShippedGoods;
	EndIf;
	
	SetVisibilityOfPremises();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		WarningText = NStr("vi = 'Không khuyến khích chỉnh sửa trường ""Loại xuất hàng""';
							|ru = 'Редактирование поля ""Тип отгрузки"" не рекомендуется';
							|en = 'Editing the ""Shipment type"" field is not recommended'; fa = 'Editing the ""Shipment type"" field is not recommended';
							|it = 'Editing the ""Shipment type"" field is not recommended';
							|pl = 'Editing the ""Shipment type"" field is not recommended';
							|tr = '""Sevkiyat türü"" alanının düzenlenmesi önerilmez'");
		Items.ShipmentType.WarningOnEditRepresentation = WarningOnEditRepresentation.Show;
		Items.ShipmentType.WarningOnEdit = WarningText;
		
		WarningText = NStr("vi = 'Không khuyến khích chỉnh sửa trường ""Chuyến đi""';
							|ru = 'Редактирование поля ""Рейс"" не рекомендуется';
							|en = 'Editing the ""Trip"" field is not recommended'; fa = 'Editing the ""Trip"" field is not recommended';
							|it = 'Editing the ""Trip"" field is not recommended';
							|pl = 'Editing the ""Trip"" field is not recommended';
							|tr = '""Sefer"" alanının düzenlenmesi önerilmez'");
		Items.TransportationJob.WarningOnEditRepresentation = WarningOnEditRepresentation.Show;
		Items.TransportationJob.WarningOnEdit = WarningText; 
		
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	CurrentStatus = Object.Status;
	AttachIdleHandler("DisplayInformationOnUnloadedProductsClient",0.1,True);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure OnClose(Exit)

	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();

	PackingListsServer.WhenReadingCreatingFormWithPackingLists(ThisObject,
																Object.ShippedGoods,
																Object.Ref.Metadata().ObjectPresentation);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	Items.GroupInformationAndComment.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	FillInServiceDetailsOfTSGoods("ShippedGoods", True);
	FillInServiceDetailsOfTSGoods("GoodsByReferences");
	PackingListsServer.CreateNavigationLabel(ThisObject,
		Object.Ref.Metadata().ObjectPresentation);
	
	GoodsIssueNoteLocalization.EstablishSignOfUseOfLabeledProducts(ThisObject);
	EstablishVisibilityOfPackagingElementsDuringLabeling();
	
	PackingListsServer.SynchronizePackingListsWithSpendingOrder(CurrentObject.Ref, UseBinLocationWarehousing);
	PackingListsServer.WhenReadingCreatingFormWithPackingLists(ThisObject,
																	Object.ShippedGoods,
																	Object.Ref.Metadata().ObjectPresentation);


	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_GoodsIssueNote", WriteParameters, Object.Ref);


	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	CurrentData = Items.ShippedGoods.CurrentData;
	
	If ChoiceSource.FormName = "Catalog.Products.Form.ChoiceForm" Then
		
		CurrentData.Products = ValueSelected;
		
		ProductsOnChangeServer(CachedValues);
		
		Items.ShippedGoods.CurrentItem = Items.ShippedGoodsNumberOfPackages;
		Items.ShippedGoods.CurrentItem = Items.ShippedGoodsProducts;
		
	ElsIf ChoiceSource.FormName = "Document.PackingList.Form.ChoiceForm" Then
		
		CurrentData.PackingList = ValueSelected;
		PackingListWhenChangingColor(CachedValues);
		Items.ShippedGoods.EndEditRow(False);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters.GoodsByReferences, ValueSelected);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
	// Unknown barcodes
	If EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5);
		
	EndIf;
	
	
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not Object.GoodsViewMode Then
		DocumentObject = FormAttributeToValue("Object");
		If Not DocumentObject.CheckFilling() Then
			Object.GoodsViewMode = True;
			DisplayModeOnChangeServer();
			Cancel = True;
		EndIf;
		CheckedAttributes.Clear();
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PremiseOnChange(Item)
	WarehouseSpaceWhenServerChanges();	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseSpaceWhenServerChanges();
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	ClearMessages();
	
	If UseBinLocationWarehousing Then 
		
		If CurrentStatus = PredefinedValue("Enum.GoodsIssueNoteStatuses.ForPicking")
			And Not (Object.Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.Prepared")
			Or Object.Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.ForPicking")) Then
			
			If Modified
				Or Not Object.Posted Then
				NewStatus   = Object.Status;
				Object.Status = CurrentStatus;
				
				AdditionalParameters = New Structure;
				AdditionalParameters.Insert("NewStatus", NewStatus);
				
				QueryText = NStr("vi = 'Trước khi thay đổi trạng thái, chứng từ sẽ được kết chuyển. Tiếp tục?';
								|ru = 'Перед изменением статуса документ будет проведен. Продолжить?';
								|en = 'Document will be posted before changing the status. Continue?'; fa = 'Document will be posted before changing the status. Continue?';
								|it = 'Prima di modificare lo stato il documento verrà registrato. Continuare?';
								|pl = 'Przed zmianą statusu dokumentu zostanie zaksięgowany. Kontynuować?';
								|tr = 'Belge, durum değişikliğinden önce kaydedilecektir. Devam edilsin mi?'");
				CallbackDescription = New CallbackDescription("QuestionWhenChangingStatusEnds", ThisObject, AdditionalParameters);
				
				ShowQueryBox(CallbackDescription,
								QueryText,
								QuestionDialogMode.OKCancel,
								,
								DialogReturnCode.Cancel);
				Return;
			EndIf;
			
			ChangeStatusAtAddressWarehouse();
			
		ElsIf CurrentStatus = PredefinedValue("Enum.GoodsIssueNoteStatuses.Prepared")
			 And Object.Status <> PredefinedValue("Enum.GoodsIssueNoteStatuses.ForPicking") Then
			 
			 MessageText = NStr("vi = 'Từ trạng thái ""%Prepared%"", có thể chuyển chỉ một lệnh sang trạng thái ""%ForPicking%"".';
								|ru = 'Из статуса ""%Prepared%"" ордер можно перевести только в статус ""%ForPicking%"".';
								|en = 'You can switch the note status from ""%Prepared%"" to ""%ForPicking%"" only.'; fa = 'You can switch the note status from ""%Prepared%"" to ""%ForPicking%"" only.';
								|it = 'Из статуса ""%Prepared%"" ордер можно перевести только в статус ""%ForPicking%"".';
								|pl = 'You can switch the note status from ""%Prepared%"" to ""%ForPicking%"" only.';
								|tr = 'Sipariş, ""%Prepared%"" durumundan sadece ""%ForPicking%"" durumuna aktarılabilir.'");
			 
			 MessageText = StrReplace(MessageText, "%Prepared%" , PredefinedValue("Enum.GoodsIssueNoteStatuses.Prepared"));
			 MessageText = StrReplace(MessageText, "%ForPicking%" , PredefinedValue("Enum.GoodsIssueNoteStatuses.ForPicking"));
			 
			 
			 CommonClientServer.MessageToUser(MessageText);
			 Object.Status = CurrentStatus;
			 
		Else
			
			StatusOnChangeServer(False, Undefined);
			
		EndIf;
	Else
		StatusOnChangeServer(False, Undefined);
	EndIf;
	
	CurrentStatus = Object.Status;
	
EndProcedure

&AtClient
Procedure StatusStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceData = New ValueList;
	If SeriesSpecificationParameters.ShippedGoods.UseItemsBatch Then
		ChoiceData.Add(PredefinedValue("Enum.GoodsIssueNoteStatuses.Prepared"));
	EndIf;
	ChoiceData.Add(PredefinedValue("Enum.GoodsIssueNoteStatuses.ForPicking"));
	ChoiceData.Add(PredefinedValue("Enum.GoodsIssueNoteStatuses.ForChecking"));
	ChoiceData.Add(PredefinedValue("Enum.GoodsIssueNoteStatuses.Verified"));
	ChoiceData.Add(PredefinedValue("Enum.GoodsIssueNoteStatuses.ToShip"));
	ChoiceData.Add(PredefinedValue("Enum.GoodsIssueNoteStatuses.Shipped_"));
	
EndProcedure

&AtClient
Procedure DateOfShipmentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfShipmentOnChangeServer();
	
EndProcedure

&AtClient
Procedure NavigationTextURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	WhenMovingToAnotherLevelServer(Var_URL);
	
EndProcedure

&AtClient
Procedure DisplayModeOnChange(Item)
	DisplayModeOnChangeServer();
	PackingListsClient.UpdateCachedValuesForPCHSWithPackingLists(Items.ShippedGoods, CachedValues, SeriesSpecificationParameters.ShippedGoods);
EndProcedure

&AtClient
Procedure ShipmentTypeOnChange(Item)
	
	Modified = True;
	
	If ShipmentType = "ShipmentUnderTransportationJob" Then
		
		Object.ShipmentUnderTransportationJob = True;
		
	Else
		
		Object.ShipmentUnderTransportationJob = False;
		Object.DeliveryProcedure = "";
		Object.DeliveryProcedure = "";
		Object.TransportationJob = Undefined;
		
	EndIf;
	
	SetTransportTaskAvailability(ThisObject);
	
EndProcedure

&AtClient
Procedure TransportationJobStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		SelectionOfFlights = New Structure;
		SelectionOfFlights.Insert("DepartureWarehouse", Object.Warehouse);
		
		FormParameters = New Structure;
		FormParameters.Insert("CurrentRow", Object.TransportationJob);
		FormParameters.Insert("Filter", SelectionOfFlights);
		OpenForm("Document.Trip.ChoiceForm",
			FormParameters,
			Item);
		
	Else
		
		FormParameters = New Structure("WarehouseDocument,NoteStatus", Object.Ref, Object.Status);
		OpenForm("Document.GoodsIssueNote.Form.TransportationJobChoiceForm",
			FormParameters,
			Item);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TransportationJobOnChange(Item)
	
	If ValueIsFilled(Object.TransportationJob) Then
		Object.DeliveryProcedure = DeliveryOrderInTransportOrder(Object.TransportationJob, Object.Recipient);
	Else
		Object.DeliveryProcedure = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
			And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoodsByReferences

&AtClient
Procedure GoodsByReferencesProductsOnChange(Item)
	CurrentRow = Items.GoodsByReferences.CurrentData;
	
	Actions = New Structure;
	Actions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("CheckSeriesCalculateStatus",
						New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters.GoodsByReferences));
	Actions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisObject.FormName, "GoodsByReferences"));
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
		
EndProcedure

&AtClient
Procedure GoodsByReferencesSeriesOnChange(Item)
		
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.GoodsByReferences.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.GoodsByReferences.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters.GoodsByReferences, ValueSelected);

EndProcedure

&AtClient
Procedure GoodsByReferencesSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("GoodsByReferences", Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsByReferencesReferenceOrderStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;

	ClearMessages();
	
	Cancel = False;
	
	CurrentData = Items.GoodsByReferences.CurrentData;
	
	If Not ValueIsFilled(Object.Warehouse) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Trước khi chọn một lệnh, cần điền kho bãi.';
												|ru = 'Перед выбором распоряжения нужно заполнить склад.';
												|en = 'Fill in a warehouse before selecting a reference.'; fa = 'Fill in a warehouse before selecting a reference.';
												|it = 'Prima di selezionare le disposizioni bisogna compilare il magazzino.';
												|pl = 'Przed wyborem zamówienia należy wypełnić magazyn.';
												|tr = 'Emir seçmeden önce ambarın doldurulması gerekir.'"),
														Object.Ref,
														"Warehouse");
		Cancel = True;												
	EndIf;
	
	Field = CommonClientServer.PathToTabularSection("GoodsByReferences", CurrentData.LineNumber, "Products");
	
	If Not ValueIsFilled(CurrentData.Products) Then
		Field = CommonClientServer.PathToTabularSection("GoodsByReferences", CurrentData.LineNumber, "Products");
	
		CommonClientServer.MessageToUser(NStr("vi = 'Trước khi chọn lệnh, cần điền mặt hàng.';
												|ru = 'Перед выбором распоряжения нужно заполнить номенклатуру.';
												|en = 'Fill in items before selecting a reference.'; fa = 'Fill in items before selecting a reference.';
												|it = 'Prima di selezionare le disposizioni bisogna compilare gli articoli.';
												|pl = 'Przed wyborem zamówienia należy wypełnić pozycję.';
												|tr = 'Emir seçmeden önce ürün gamının doldurulması gerekir.'"),
														Object.Ref,
														Field);
		Cancel = True;												
	EndIf;
	
	If Not ValueIsFilled(CurrentData.Characteristic)
		And CurrentData.ItemVariantsAreUsed Then
		Field = CommonClientServer.PathToTabularSection("GoodsByReferences", CurrentData.LineNumber, "Characteristic");
	
		CommonClientServer.MessageToUser(NStr("vi = 'Trước khi chọn lệnh, cần điền đặc tính mặt hàng.';
												|ru = 'Перед выбором распоряжения нужно заполнить характеристику номенклатуры.';
												|en = 'Fill in item variant before selecting a reference.'; fa = 'Fill in item variant before selecting a reference.';
												|it = 'Prima di selezionare le disposizioni bisogna compilare la caratteristica di articoli.';
												|pl = 'Przed wyborem zamówienia należy wypełnić charakterystykę pozycji.';
												|tr = 'Emir seçmeden önce ürün gamı özelliğinin doldurulması gerekir.'"),
														Object.Ref,
														Field);
		Cancel = True;												
	EndIf;
	
	If Not ValueIsFilled(CurrentData.Series)
		And CurrentData.BatchesIndicationStatus <> 0 Then
		Field = CommonClientServer.PathToTabularSection("GoodsByReferences", CurrentData.LineNumber, "Series");
	
		CommonClientServer.MessageToUser(NStr("vi = 'Trước khi chọn lệnh, cần điền sê-ri mặt hàng.';
												|ru = 'Перед выбором распоряжения нужно заполнить серию номенклатуры.';
												|en = 'Fill in item batch before selecting a reference.'; fa = 'Fill in item batch before selecting a reference.';
												|it = 'Prima di selezionare le disposizioni bisogna compilare la serie di articoli.';
												|pl = 'Przed wyborem zamówienia należy wypełnić serię pozycji.';
												|tr = 'Emir seçmeden önce ürün gamı partisinin doldurulması gerekir.'"),
														Object.Ref,
														Field);
		Cancel = True;												
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	OrderSelectionFormParameters = New Structure;
	OrderSelectionFormParameters.Insert("Recorder", Object.Ref);
	OrderSelectionFormParameters.Insert("Recipient", Object.Recipient);
	OrderSelectionFormParameters.Insert("Warehouse", Object.Warehouse);
	OrderSelectionFormParameters.Insert("WarehouseOperation", Object.WarehouseOperation);
	OrderSelectionFormParameters.Insert("Products", CurrentData.Products);
	OrderSelectionFormParameters.Insert("Characteristic", CurrentData.Characteristic);
	OrderSelectionFormParameters.Insert("Series", CurrentData.Series);
	OrderSelectionFormParameters.Insert("Purpose", CurrentData.Purpose);
	
	OpenForm("Document.GoodsIssueNote.Form.ShipmentReferenceChoiceForm",
				  OrderSelectionFormParameters,
				  Item);
				  
	
EndProcedure

&AtClient
Procedure GoodsByReferencesCountOnChange(Item)
	CurrentRow = Items.GoodsByReferences.CurrentData;
	
	Actions = New Structure;
	Actions.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters.GoodsByReferences));
			
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersShippedGoods

&AtClient
Procedure ShippedGoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	PackingListsClient.BeforeYouStartAddingVTCHSPackingLists(Items.ShippedGoods, Cancel, Copy, CachedValues);
	
EndProcedure

&AtClient
Procedure ShippedGoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ShippedGoods, ThisObject);
	PackingListsClient.AtBeginningOfEditingPMWithPackingLists(ThisObject, CachedValues, NewRow);
	
	If NewRow
		And Not Copy Then
		CurrentData = Items.ShippedGoods.CurrentData;
		
		If ValueIsFilled(CurrentData.PackingListParent) Then
			CurrentData.Action = PredefinedValue("Enum.ActionsWithGoodsIssueNoteRows.Ship");
		ElsIf Object.Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.ForPicking")
			Or Object.Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.Prepared") Then
			CurrentData.Action = PredefinedValue("Enum.ActionsWithGoodsIssueNoteRows.Pick");
		EndIf;
		
	EndIf;
EndProcedure

&AtClient
Procedure ShippedGoodsOnEditEnd(Item, NewRow, CancelEdit)
	ShippedGoodsOnEditEndServer();
	PackingListsClient.AtEndOfEditingPMWithPackingLists(ThisObject, NewRow, CancelEdit);
	AttachIdleHandler("DisplayInformationOnUnloadedProductsClient",0.1,True);
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, Items.ShippedGoods, AdditionalParameters);
	If AdditionalParameters.Property("ServerCallRequired__") Then
		AttachIdleHandler("ShippedGoodsAtEndOfEditingForServerCall", 0.5, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure ShippedGoodsOnEditEndServer()

	GoodsIssueNoteLocalization.EstablishSignOfUseOfLabeledProducts(ThisObject);
	EstablishVisibilityOfPackagingElementsDuringLabeling();
	
EndProcedure

&AtClient
Procedure ShippedGoodsBeforeDeleteRow(Item, Cancel)
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ShippedGoods, ThisObject);
	PackingListsClient.BeforeDeletingPMLinesWithPackingSheets(Items.ShippedGoods, CachedValues, SeriesSpecificationParameters.ShippedGoods);
EndProcedure

&AtClient
Procedure ShippedGoodsAfterDeleteRow(Item)
	GoodsAfterDeleteRowServer(CachedValues);
	AttachIdleHandler("DisplayInformationOnUnloadedProductsClient",0.1,True);
EndProcedure

&AtClient
Procedure ShippedGoodsProductsOnChange(Item)
	ProductsOnChangeServer(CachedValues);
EndProcedure

&AtClient
Procedure ShippedGoodsProductsStartChoice(Item, ChoiceData, StandardProcessing)
	PackingListsClient.StartOfProductPlaceSelection(ThisObject, Item, StandardProcessing, Object.GoodsViewMode);
EndProcedure

&AtClient
Procedure ShippedGoodsPackingListStartChoice(Item, ChoiceData, StandardProcessing)
	PackingListsClient.StartOfProductPlaceSelection(ThisObject, Item, StandardProcessing, Object.GoodsViewMode);
EndProcedure

&AtClient
Procedure ShippedGoodsSelection(Item, RowSelected, Field, StandardProcessing)
	If PackingListsClient.CheckPrepareTransitionToPackingListWhenSelecting(Items.ShippedGoods, Field.Name, "ShippedGoods") Then
		WhenMovingToAnotherLevelServer(Items.ShippedGoods.CurrentData.PackingList);
	ElsIf Field = Items.ShippedGoodsBatchesIndicationStatus Then
		OpenSelectionOfSeries("ShippedGoods");
	EndIf;
EndProcedure

&AtClient
Procedure ShippedGoodsPackingListOnChange(Item)
	PackingListWhenChangingColor(CachedValues);
	Items.ShippedGoods.EndEditRow(False);
EndProcedure

&AtClient
Procedure ShippedGoodsPackageOnChange(Item)
	
	CurrentRow = Items.ShippedGoods.CurrentData;
	
	Actions = New Structure();
	Actions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	Actions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	Actions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	Actions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	Actions.Insert("RecalculateNumberOfPackages");
	Actions.Insert("RecalculateWeightVolume");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
	
EndProcedure

&AtClient
Procedure ShippedGoodsWeightOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByWeight");
	
	CurrentRow = Items.ShippedGoods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure ShippedGoodsVolumeM3OnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByVolume");
	
	CurrentRow = Items.ShippedGoods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure ShippedGoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.ShippedGoods.CurrentData;
	Actions = New Structure();
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, Actions);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
	
	If Not ValueIsFilled(CurrentRow.PackingListParent) Then
		RecalculateNumberOfSeats();
	EndIf;
	
EndProcedure

&AtClient
Procedure ShippedGoodsActionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	CurrentRow = Items.ShippedGoods.CurrentData;
	StandardProcessing = False;
	
	If ValueSelected <> PredefinedValue("Enum.ActionsWithGoodsIssueNoteRows.Ship") Then
		If CurrentRow.ThisIsAPackingList Then
			WarningText = NStr("vi = 'Đối với dòng danh sách đóng gói, chỉ cho phép hành động %Ship%. Để chọn một hành động khác, đầu tiên hãy tách hàng hóa.';
								|ru = 'Для строки упаковочного листа допустимо только действие %Ship%. Для выбора другого действия сначала распакуйте товары.';
								|en = 'Only action %Ship% is allowed for the packing list line. To select another action, unpack the goods first.'; fa = 'Only action %Ship% is allowed for the packing list line. To select another action, unpack the goods first.';
								|it = 'Per la riga del packing list è consentita soltanto l''azione %Ship%. Per selezionare un''azione diversa, prima disimballate la merce.';
								|pl = 'W przypadku wiersza specyfikacji ładunkowej jest dopuszczalna tylko czynność %Ship%. Dla wyboru innej czynności najpierw rozpakuj wiersze pozycji.';
								|tr = 'Bir ürün listesi satırı için yalnızca işleme izin verilir %Ship%. Farklı bir işlem seçmek için önce ürünleri paketleme ünitesinden çıkar.'");	
			WarningText = StrReplace(WarningText,"%Ship%", PredefinedValue("Enum.ActionsWithGoodsIssueNoteRows.Ship"));
			ShowMessageBox(,WarningText);
			Return;
		ElsIf ValueIsFilled(CurrentRow.PackingListParent) Then
			QueryText = NStr("vi = 'Khi thay đổi hành động với dòng này sang %Action%, hàng hóa sẽ bị loại khỏi danh sách đóng gói. Tiếp tục?';
							|ru = 'При изменении действия со строкой на %Action% товар будет исключен из упаковочного листа. Продолжить?';
							|en = 'Goods will be removed from the packing list while changing an action with line for %Action%. Continue?'; fa = 'Goods will be removed from the packing list while changing an action with line for %Action%. Continue?';
							|it = 'Con la modifica di azione della riga %Action% la merce sarà esclusa dal packing list. Continuare?';
							|pl = 'W wypadku zmiany czynności z wierszem na %Action% towar zostanie wykluczony ze specyfikacji ładunkowej. Kontynuować?';
							|tr = 'İşlemi bir satırla %Action%değiştirirken, ürün ürün listesinden çıkarılacaktır. Devam edilsin mi?'");
			QueryText = StrReplace(QueryText,"%Action%", ValueSelected);
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("ValueSelected", ValueSelected);
			
			CallbackDescription = New CallbackDescription("ShippedGoodsActionChoiceProcessingCompletion", ThisObject, AdditionalParameters);
			
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.OKCancel);
			Return;
			
		EndIf;
	EndIf;
	
	CurrentRow.Action = ValueSelected;
	Modified = True;
	
	If Not CurrentRow.ThisIsAPackingList Then		
		Actions = New Structure;
		Actions.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters.ShippedGoods));
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
	EndIf;
EndProcedure

&AtClient
Procedure ShippedGoodsActionChoiceProcessingCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.OK Then
		Return;
	EndIf;
	
	CurrentRow = Items.ShippedGoods.CurrentData;
	CurrentRow.Action = AdditionalParameters.ValueSelected;
	Modified = True;
	
	If Object.GoodsViewMode = 1 Then
		CurrentRow.PackingListParent = Undefined;
		CurrentRow.PackingListParentCode = "";
		Actions = New Structure;
		Actions.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters.ShippedGoods));
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
	Else
		UnpackServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ShippedGoodsSeriesOnChange(Item)
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.ShippedGoods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.ShippedGoods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters.ShippedGoods, ValueSelected);
EndProcedure

&AtClient
Procedure ShippedGoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries("ShippedGoods", Item.EditText);
EndProcedure

&AtClient
Procedure ShippedItemsPackingListParentOpening(Item, StandardProcessing)
	StandardProcessing = False;
	ShowValue(Undefined, Items.ShippedGoods.CurrentData.PackingListParent);
EndProcedure

&AtClient
Procedure ShippedItemsPackingListParentClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ShippedGoodsAtEndOfEditingForServerCall()

	ShippedGoodsAtEndOfEditingOnServer();

EndProcedure

&AtServer
Procedure ShippedGoodsAtEndOfEditingOnServer()

	FormEvents.WhenChangingElement(ThisObject, "ShippedGoods");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure FillInByReferences(Command)
	
	If Object.ShippedGoods.Count() > 0 Then
		ShowQueryBox(New CallbackDescription("FillInByOrderCompletion", ThisObject), NStr("vi = 'Trước khi điền, phần bảng sẽ bị xóa. Điền?';
																							|ru = 'Перед заполнением табличная часть будет очищена. Заполнить?';
																							|en = 'The table will be cleared. Do you want to continue?'; fa = 'جدول پاک خواهد شد. آیا می‌خواهید ادامه دهید؟';
																							|it = 'Prima della compilazione, la tabella sarà cancellata. Compilare?';
																							|pl = 'Przed wypełnieniem część tabelaryczna zostanie wyczyszczona. Wypełnić?';
																							|tr = 'Tablo bölümü doldurulmadan önce temizlenecektir. Doldur?'"), QuestionDialogMode.YesNo);
		
		Return;
	EndIf;
	
	FillInByOrder();
	
EndProcedure

&AtClient
Procedure FillInByOrderCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	FillInByOrder();
	
EndProcedure

&AtServer
Procedure FillInByOrder()
	
	Documents.GoodsIssueNote.FillInShippedGoodsByGoodsByOrders(Object);

	GoodsIssueNoteLocalization.EstablishSignOfUseOfLabeledProducts(ThisObject);
	EstablishVisibilityOfPackagingElementsDuringLabeling();
	
	PackingListsServer.WhenReadingCreatingFormWithPackingLists(ThisObject,
																Object.ShippedGoods,
																Object.Ref.Metadata().ObjectPresentation);
	
	FillInServiceDetailsOfTSGoods("ShippedGoods", True);
	ProductsServer.FillInSeriesByFEFO(Object,SeriesSpecificationParameters.ShippedGoods, False);	
	
	If Not WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.DateOfShipment)
		And GetFunctionalOption("UseItemPackages") Then
		Documents.GoodsIssueNote.SplitByPackagesForReference(Object);
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.ShippedGoods);
	
	DisplayInformationOnUnloadedProducts();
	
	FillInServiceDetailsOfTSGoods("ShippedGoods", False);

EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure DivideByPackagingsForReference(Command)
	
	If Object.ShippedGoods.Count() = 0 Then
		ShowQueryBox(New CallbackDescription("BreakDownReferencePackagesAfterQuestion", ThisObject), NStr("vi = 'Chưa điền phần bảng. Điền theo lệnh?';
																											|ru = 'Табличная часть не заполнена. Заполнить по распоряжению?';
																											|en = 'Table is not filled. Fill in by reference?'; fa = 'Table is not filled. Fill in by reference?';
																											|it = 'La tabella non è compilata, Compilare in base alla disposizione?';
																											|pl = 'Sekcja tabelaryczna nie jest wypełniona. Wypełnić według zamówienia?';
																											|tr = 'Tablo bölümü doldurulmadı. Sipariş üzerine doldurulsun?'"), QuestionDialogMode.YesNo);
		
	Else
		QueryText = NStr("vi = 'Khi thực hiện giao dịch, phần bảng sẽ được điền lại,
		|khi đó các dòng với số lượng bằng 0 sẽ bị xóa. Tiếp tục?';
		|ru = 'При выполнении операции табличная часть будет перезаполнена,
		|при этом строки с нулевым количеством будут удалены. Продолжить?';
		|en = 'Table will be refilled while executing the operation.
		|Rows with zero quantities will be removed. Continue?'; fa = 'Table will be refilled while executing the operation.
		|Rows with zero quantities will be removed. Continue?';
		|it = 'Durante l''esecuzione dell''operazione la tabella sarà ricompilata, 
		| le righe con quantità zero saranno eliminate. Continuare?';
		|pl = 'Podczas wykonywania operacji część tabelaryczna zostanie wypełniona ponownie,
		|przy tym wiersze o zerowej ilości zostaną usunięte. Kontynuować?';
		|tr = 'İşlem yapıldığında tablo bölümü yeniden doldurulacak,
		|sıfır sayılan satırlar ise silinecektir. Devam edilsin mi?'");
		
		ShowQueryBox(New CallbackDescription("DivideByPackagingsForReferenceCompletion", ThisObject), QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtClient
Procedure BreakDownReferencePackagesAfterQuestion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	FillAndBreakIntoPackages();
	
EndProcedure

&AtClient
Procedure DivideByPackagingsForReferenceCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	DivideByPackagingsForReferenceServer();
	
EndProcedure

&AtClient
Procedure VerifyQuantity(Command)
	If ThereAreLabeledProducts Then
		CheckQuantityInTheDocumentClient();
	Else
		WarehousesClient.OpenCheckingFormPackagingAndQuantities(ThisObject, "Validation");
	EndIf;
EndProcedure

&AtClient
Procedure CorrectQuantity(Command)
	If ThereAreLabeledProducts Then
		CheckQuantityInTheDocumentClient();
	Else
		WarehousesClient.OpenCheckingFormPackagingAndQuantities(ThisObject, "Patch");
	EndIf;
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInByFilteredGoods(Command)

	If (Modified Or Not Object.Posted) And Object.ShippedGoods.Count() > 0 Then
				
		QueryText = NStr("vi = 'Trước khi điền, sẽ kết chuyển chứng từ và sẽ xóa phần bảng. Tiếp tục?';
						|ru = 'Перед заполнением документ будет проведен, а табличная часть - очищена. Продолжить?';
						|en = 'The table will be cleared. The document will be posted. Do you want to continue?'; fa = 'The table will be cleared. The document will be posted. Do you want to continue?';
						|it = 'Prima della compilazione il documento verrà registrato e la tabella verrà cancellata. Continuare?';
						|pl = 'Przed wypełnieniem dokument zostanie zaksięgowany, część tabelaryczna zostanie oczyszczona. Kontynuować?';
						|tr = 'Doldurmadan önce belge kaydedilecek ve tablo bölümü temizlenecektir. Devam edilsin mi?'");
			CallbackDescription = New CallbackDescription("CompletionOfWorkOnSelectedProducts", ThisObject);
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		Return;
		
	EndIf;
	
	FillInFollowingSnippetForSelectedProducts();
		
EndProcedure

&AtClient
Procedure CompletionOfWorkOnSelectedProducts(Response, AdditionalParameters) Export
		
	If Response <> DialogReturnCode.Yes Then
		Return;
	Else
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
		
		 FillInByFilteredGoodsServer(False, Undefined);
		
	EndIf;
	    
EndProcedure

&AtClient
Procedure FillInFollowingSnippetForSelectedProducts()
    
    If Object.ShippedGoods.Count() > 0 Then

		QueryText = NStr("vi = 'Trước khi điền, sẽ xóa phần bảng. Điền?';
						|ru = 'Перед заполнением табличная часть будет очищена. Заполнить?';
						|en = 'The table will be cleared. Do you want to continue?'; fa = 'جدول پاک خواهد شد. آیا می‌خواهید ادامه دهید؟';
						|it = 'Prima della compilazione, la tabella sarà cancellata. Compilare?';
						|pl = 'Przed wypełnieniem część tabelaryczna zostanie wyczyszczona. Wypełnić?';
						|tr = 'Tablo bölümü doldurulmadan önce temizlenecektir. Doldur?'");
		
		Response = Undefined;

		ShowQueryBox(New CallbackDescription("FillInByFilteredGoodsCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
        Return;

	EndIf;

	FillInByFilteredGoodsServer(False, Undefined);

EndProcedure

&AtClient
Procedure FillInByFilteredGoodsCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
       
    FillInByFilteredGoodsServer(False, Undefined);

EndProcedure

&AtClient
Procedure GetWeight(Command)
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisObject,"ShippedGoods");
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(
		New CallbackDescription("GetWeightCompletion", ThisObject, CurrentRow),
		UUID);
	
EndProcedure

&AtClient
Procedure GetWeightCompletion(Weight, CurrentRow) Export
	
	If Weight <> Undefined Then
		
		CurrentRow.NumberOfPackages = Weight;
		
		Actions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(ThisObject, Actions);					
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure SplitTheLineProductsByOrders(Command)
	
	FormTable  = Items.GoodsByReferences;
	TableData = Object.GoodsByReferences;
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.FieldNameQuantity = "Count";
	
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable,, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure SplitTheLineShippedItems(Command)
	
	FormTable  = Items.ShippedGoods;
	TableData = Object.ShippedGoods;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	PackingListsClient.BreakUpPMStringWithPackingLists(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.ShippedGoods.CurrentData;
	
	If NewRow <> Undefined Then
		
		Actions = New Structure;
		Actions.Insert("RecalculateNumberOfUnits");
		Actions.Insert("RecalculateWeightVolume");
	
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, Actions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, Actions, CachedValues);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInSeriesByFEFO(Command)
	ClearMessages();
	If ThereAreFilledSeriesByFEFO() Then
		
		ProductsClient.AskQuestionAboutReFillingSeriesByFEFO(
			New CallbackDescription("CompleteSeriesOnFEFOCompletion", ThisObject));
		Return;
		
	EndIf;
	
	If Not FillInSeriesByFEFOServer() Then
		ProductsClient.WarnAboutAbsenceOfLinesFilledByFEFO();
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteSeriesOnFEFOCompletion(Result, AdditionalParameters) Export 
	
	If Not Result Then
		Return;
	EndIf;
	
	If Not FillInSeriesByFEFOServer() Then
		ProductsClient.WarnAboutAbsenceOfLinesFilledByFEFO();
	EndIf;

EndProcedure

&AtClient
Procedure UpLevel(Command)
	UpLevelServer();
EndProcedure

&AtClient
Procedure Unpack(Command)
	PackingListsClient.UnpackPackingList(ThisObject);
EndProcedure

&AtClient
Procedure Pack(Command)
	
	If Items.ShippedGoods.CurrentData = Undefined Then
		WarningText = NStr("vi = 'Hãy chọn dòng để hợp nhất.';
							|ru = 'Выберите строки для объединения.';
							|en = 'Select lines to merge.'; fa = 'Select lines to merge.';
							|it = 'Selezionate le righe da unire.';
							|pl = 'Wybierz wiersze do połączenia';
							|tr = 'Birleştirilecek satırları seçin.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	NewPackingList = PackServer();
	
	If ValueIsFilled(NewPackingList) Then
		NotificationText1 = NStr("vi = 'Tạo:';
								|ru = 'Создание:';
								|en = 'Created:'; fa = 'ایجادشده:';
								|it = 'Creazione:';
								|pl = 'Utworzenie:';
								|tr = 'Oluşturuldu:'");
		ShowUserNotification(NotificationText1,
			GetURL(NewPackingList),
			NewPackingList,
			PictureLib.Information32);
	EndIf;
	
EndProcedure
	
// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure


&AtClient
Procedure SpecifySeries(Command)
	OpenSelectionOfSeries("ShippedGoods");
EndProcedure

&AtClient
Procedure RefillWithShippedGoods(Command)
	ClearMessages();
	
	Cancel = CheckCompletenessOfProductLocations();
	
	If Cancel Then 
		Return;
	EndIf;
	
	If Object.ShippedGoods.Count() > 0 Then

		QueryText = NStr("vi = 'Trước khi điền, phần bảng sẽ bị xóa. Điền?';
						|ru = 'Перед заполнением табличная часть будет очищена. Заполнить?';
						|en = 'The table will be cleared. Do you want to continue?'; fa = 'جدول پاک خواهد شد. آیا می‌خواهید ادامه دهید؟';
						|it = 'Prima della compilazione, la tabella sarà cancellata. Compilare?';
						|pl = 'Przed wypełnieniem część tabelaryczna zostanie wyczyszczona. Wypełnić?';
						|tr = 'Tablo bölümü doldurulmadan önce temizlenecektir. Doldur?'");
		
		Response = Undefined;

		
		ShowQueryBox(New CallbackDescription("RefillWithShippedGoodsCompletion", ThisObject), QueryText, QuestionDialogMode.YesNo);
        Return;

	EndIf;

    RefillWithShippedGoodsServer();

EndProcedure

&AtClient
Procedure MoveToNewNote(Command)
	ClearMessages();
	
	If Items.ShippedGoods.SelectedRows.Count() = 0 Then
		ShowMessageBox(,NStr("vi = 'Chọn các dòng mà bạn muốn chuyển sang lệnh khác.';
							|ru = 'Выделите строки, которые нужно перенести в другой ордер.';
							|en = 'Select lines which should be transferred to another note.'; fa = 'Select lines which should be transferred to another note.';
							|it = 'Selezionate le righe che devono essere trasferite in un altro mandato.';
							|pl = 'Wybierz wiersze które trzeba przenieść do innego zlecenia.';
							|tr = 'Başka bir siparişe aktarılacak satırları seçiniz.'"));
		Return;
	EndIf;
	
	LinesToWrap = New Array;
	For Each ArrRow In Items.ShippedGoods.SelectedRows Do
		TSRow = Object.ShippedGoods.FindByID(ArrRow);
		LinesToWrap.Add(TSRow.LineNumber);
		
		If Not WarehousesClientServer.LineOfSpendingOrderCanBeTransferredToAnotherOrder(TSRow) Then
			Return;
		EndIf;
	EndDo;
	
	If Modified Then
		If Not CheckFilling() Then
			Return;
		EndIf;
	EndIf;
	
	AdditionalParameters = New Structure("LinesToWrap", LinesToWrap);
	
	If Object.ShipmentUnderTransportationJob Then
		
		CallbackDescription = New CallbackDescription("MoveToNewNoteCompletion", ThisObject, AdditionalParameters);
		FormParameters = New Structure("WarehouseDocument", Object.Ref);
		OpenForm("Document.GoodsIssueNote.Form.TransportationJobChoiceForm",
			FormParameters,
			ThisObject,
			,
			,
			,
			CallbackDescription);
		
	Else
		AdditionalParameters.Insert("NoTask");
		MoveToNewNoteCompletion(Undefined, AdditionalParameters);
	EndIf;
	 
EndProcedure

&AtClient
Procedure MoveToExistingNote(Command)
	ClearMessages();
	
	If Items.ShippedGoods.SelectedRows.Count() = 0 Then
		ShowMessageBox(,NStr("vi = 'Chọn các dòng mà bạn muốn chuyển sang lệnh khác.';
							|ru = 'Выделите строки, которые нужно перенести в другой ордер.';
							|en = 'Select lines which should be transferred to another note.'; fa = 'Select lines which should be transferred to another note.';
							|it = 'Selezionate le righe che devono essere trasferite in un altro mandato.';
							|pl = 'Wybierz wiersze które trzeba przenieść do innego zlecenia.';
							|tr = 'Başka bir siparişe aktarılacak satırları seçiniz.'"));
		Return;
	EndIf;
	
	LinesToWrap = New Array;
	For Each ArrRow In Items.ShippedGoods.SelectedRows Do
		TSRow = Object.ShippedGoods.FindByID(ArrRow);
		LinesToWrap.Add(TSRow.LineNumber);
		
		If Not WarehousesClientServer.LineOfSpendingOrderCanBeTransferredToAnotherOrder(TSRow) Then
			Return;
		EndIf;
	EndDo;
	
	If Modified Then
		If Not CheckFilling() Then
			Return;
		EndIf;
	EndIf;
	
	AdditionalParameters = New Structure("LinesToWrap", LinesToWrap);
	CallbackDescription = New CallbackDescription("MoveToExistingNoteCompletion", ThisObject, AdditionalParameters);
	
	OpenForm("Document.GoodsIssueNote.Form.SelectionFormOfGoodsIssue",
				New Structure("WarehouseDocument", Object.Ref),
				ThisObject,
				,
				,
				,
				CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure SortAsc(Command)
	CurrentColumn = Items.ShippedGoods.CurrentItem;
	
	If CurrentColumn <> Undefined Then
		SortRows(CurrentColumn.Name, "ASC");
	EndIf;
EndProcedure

&AtClient
Procedure SortDesc(Command)
	CurrentColumn = Items.ShippedGoods.CurrentItem;
	
	If CurrentColumn <> Undefined Then
		SortRows(CurrentColumn.Name, "DESC");
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement(True, True);
	ConditionalDesignParameters.NameOfUnitField = "ShippedGoodsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.ShippedGoods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//

	WarehousesServer.SetConditionalAppearanceForActionInLine(ThisObject);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsPackage.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseBinLocationWarehousing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.Action");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionsWithGoodsIssueNoteRows.Pick;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.MeasuredValueType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TypesOfMeasuredValues.NumberOfPieces;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsPackage.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.OwnGoods;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject,
																			"ShippedGoodsCharacteristic",
																			"Object.ShippedGoods.ItemVariantsAreUsed");
																			
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject,
																			"GoodsByReferencesCharacteristic",
																			"Object.GoodsByReferences.ItemVariantsAreUsed");
	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject,
																		"SeriesAlwaysWHGoods",
																		"ShippedGoodsSeries",
																		"Object.ShippedGoods.BatchesIndicationStatus",
																		"Object.ShippedGoods.ItemsType");																		
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsBatchesIndicationStatus.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.BatchesIndicationStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject,
																		"SeriesAlwaysWHGoods",
																		"GoodsByReferencesSeries",
																		"Object.GoodsByReferences.BatchesIndicationStatus",
																		"Object.GoodsByReferences.ItemsType");																		
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsAdditionalInfoPackingList.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsPackingList.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.NumberOfCompletedSubordinatePositions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.ThisIsAPackingList");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Recipient.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.WarehouseOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.WarehouseTransactions.ShipmentForInternalNeeds;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsVolumeM3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsUnitOfMeasureForWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShippedGoodsUnitOfMeasureForVolume.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShippedGoods.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//

	PackingListsServer.EstablishConditionalAppearanceTakingIntoAccountPackingLists(ThisObject, "ShippedGoods");
	
	//

	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject,
		                                                            	"ShippedGoodsPurpose",
																		"Object.ShippedGoods.ItemsType");
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisObject,
		                                                            	"GoodsByReferencesPurpose",
																		"Object.GoodsByReferences.ItemsType");
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TransportationJob.Name);
	
	OrGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ShipmentUnderTransportationJob");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = OrGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.TransportationJob");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	AndGroup1 = OrGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StartShipmentOnceDeliveryOrderIsCreated");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	StatusesList = New ValueList;
	StatusesList.Add(Enums.GoodsIssueNoteStatuses.ToShip);
	StatusesList.Add(Enums.GoodsIssueNoteStatuses.Shipped_);
	
	ItemFilter = AndGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = StatusesList;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	UseGoodsIssueNoteStatuses = Common.ObjectAttributeValue(Object.Warehouse, "UseGoodsIssueNoteStatuses");
	If Not UseGoodsIssueNoteStatuses Then
		Items.Inspector.Visible = False;
		Items.ShippedBy.Visible = False;
	EndIf;
	
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse,Premise",Object.Warehouse,Object.Premise));
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsIssueNote));
	
	StartShipmentOnceDeliveryOrderIsCreated = GetFunctionalOption("StartShipmentOnceDeliveryOrderIsCreated", New Structure("Warehouse", Object.Warehouse));
	
	InstallAddressDependentStorage();

	FormEvents.OnReadAtServer(ThisObject, Object);

	GoodsIssueNoteLocalization.EstablishSignOfUseOfLabeledProducts(ThisObject);
	EstablishVisibilityOfPackagingElementsDuringLabeling();

	PackingListsServer.WhenReadingCreatingFormWithPackingLists(ThisObject, Object.ShippedGoods,
																Object.Ref.Metadata().ObjectPresentation);
																
	FillInServiceDetailsOfTSGoods("GoodsByReferences", False);
	FillInServiceDetailsOfTSGoods("ShippedGoods", False);
	
	If Object.ShipmentUnderTransportationJob Then
		Items.DeliveryProcedure.TitleLocation = FormItemTitleLocation.Auto;
		ShipmentType = "ShipmentUnderTransportationJob";
	Else
		Items.DeliveryProcedure.TitleLocation = FormItemTitleLocation.None;
		ShipmentType = "SelfPickup";
	EndIf;

	Items.GroupInformationAndComment.Picture = CommonClientServer.CommentPicture(Object.Comment);
	SetAvailability();
	
	ThereIsDeliveryOnWarehouseOperation = GoodsDelivery.ThereIsDeliveryOnWarehouseOperation(Object.WarehouseOperation);
	SetVisibilityOfDeliveryManagement();
	
	ProcessingOfTabularForms.InitializeRowCache(Items.ShippedGoods);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfDeliveryManagement()
	
	DeliveryManagement = (ThereIsDeliveryOnWarehouseOperation Or Object.ShipmentUnderTransportationJob);
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		DeliveryManagement = (DeliveryManagement And StartShipmentOnceDeliveryOrderIsCreated);
		
	EndIf;
	
	Items.ShipmentType.Visible = DeliveryManagement;
	Items.TransportationJob.Visible = DeliveryManagement;
	Items.DeliveryProcedure.Visible = DeliveryManagement;
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure WarehouseSpaceWhenServerChanges()
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse,Premise",Object.Warehouse,Object.Premise));
	
	InstallAddressDependentStorage();
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsIssueNote));
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.ShippedGoods);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.GoodsByReferences);
	
	StartShipmentOnceDeliveryOrderIsCreated = GetFunctionalOption("StartShipmentOnceDeliveryOrderIsCreated", New Structure("Warehouse", Object.Warehouse));
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		Object.ShipmentUnderTransportationJob = False;
		SetVisibilityOfDeliveryManagement();
		
	EndIf;
	SetVisibilityOfPremises();
	
EndProcedure

&AtServer
Procedure DateOfShipmentOnChangeServer()
	
	InstallAddressDependentStorage();
	
	SetVisibilityOfPremises();
	
EndProcedure

&AtClient
Procedure ChangeStatusAtAddressWarehouse()	
	NewStatus   = Object.Status;
	StatusOnChangeServer(True,NewStatus);
	AttachIdleHandler("DisplayInformationOnUnloadedProductsClient",0.1,True);
EndProcedure

&AtClient
Procedure QuestionWhenChangingStatusEnds(Response, AdditionalParameters) Export
	
	If Response <> DialogReturnCode.OK Then
		Return;
	Else
		If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
			Return;
		EndIf;
	EndIf;
	
	Modified = True;
	
	Object.Status = AdditionalParameters.NewStatus;
	
	ChangeStatusAtAddressWarehouse();
	
	CurrentStatus = Object.Status;
	
EndProcedure

&AtServer
Procedure StatusOnChangeServer(FillInForSelectedProducts, NewStatus)
	
	If FillInForSelectedProducts 
		And WarehousesServer.CheckOrdersForStatusChanges(Object.Ref).Count() = 0 Then
		Object.Status = Common.ObjectAttributeValue(Object.Ref, "Status");
		Return;
	EndIf;
	
	If FillInForSelectedProducts Then
		FillInByFilteredGoodsServer(True, NewStatus);
	Else
		Documents.GoodsIssueNote.FillInActionInLines(Object);
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsIssueNote));
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.ShippedGoods);
	EndIf;
	
	If Object.Status = Enums.GoodsIssueNoteStatuses.Shipped_ Then
		Object.DateOfShipment = CurrentSessionDate();
	EndIf;
	// When the status changes, the shipment date changes, which affects the inclusion of premises and address storage.
	InstallAddressDependentStorage();
	SetVisibilityOfPremises();
	SetAvailability();
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.ShippedGoods.FindByID(CurDataId);
	OpenSelectionOfSeries("ShippedGoods",,CurrentData);

EndProcedure

#EndRegion

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export

	ReturnParameters = Result;
	If ReturnParameters <> Undefined Then
		ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, ?(CachedValues = Undefined, BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(), CachedValues));
		Modified = True;
	EndIf;

EndProcedure

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	
	LinesToDelete = New Array;
	RowsToProcess = New Array;
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(ThisObject, StructureOfActions);
	
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure("Products, Characteristic, Series, BatchesIndicationStatus, Package");
		FillPropertyValues(Filter, SourceRow);
		FoundRows = Object.ShippedGoods.FindRows(Filter);
		
		If FoundRows.Count() = 0 Then
			TSRow = Object.ShippedGoods.Add();
			FillPropertyValues(TSRow, SourceRow);

			ProductsOnChangeServer(CachedValues);
			
			If ValueIsFilled(TSRow.PackingListParent) Then
				TSRow.Action = PredefinedValue("Enum.ActionsWithGoodsIssueNoteRows.Ship");
			ElsIf Object.Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.ForPicking")
				Or Object.Status = PredefinedValue("Enum.GoodsIssueNoteStatuses.Prepared") Then
				TSRow.Action = PredefinedValue("Enum.ActionsWithGoodsIssueNoteRows.Pick");
				RecalculateNumberOfSeats();
			Else
				TSRow.Action = PredefinedValue("Enum.ActionsWithGoodsIssueNoteRows.DoNotShip");
			EndIf;
			
		Else
			For Each TSRow In FoundRows Do
				If SourceRow.NumberOfPackages = 0 Then
					Break;
				EndIf;
				
				If SourceRow.NumberOfPackages >= 0 Then
					
					TSRow.NumberOfPackages = TSRow.NumberOfPackages + SourceRow.NumberOfPackages;
					SourceRow.NumberOfPackages = 0;
					
				Else
					
					QuantityToWriteOff = -SourceRow.NumberOfPackages;
					QuantityPerLine   = TSRow.NumberOfPackages;
					
					If QuantityToWriteOff > QuantityPerLine Then
						SourceRow.NumberOfPackages = QuantityPerLine - QuantityToWriteOff;
						TSRow.NumberOfPackages       = 0;
					Else
						SourceRow.NumberOfPackages = 0;
						TSRow.NumberOfPackages       = QuantityPerLine - QuantityToWriteOff;
					EndIf;
					
				EndIf;
				
				If TSRow.NumberOfPackages = 0 Then
					LinesToDelete.Add(TSRow);
				Else
					RowsToProcess.Add(TSRow);
				EndIf;
				
			EndDo;
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.ShippedGoods,
		CachedValues);
	
	For Each TSRow In LinesToDelete Do
		Object.ShippedGoods.Delete(TSRow);
	EndDo;
	
	FillInServiceDetailsOfTSGoods("ShippedGoods", True);
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsIssueNote));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.ShippedGoods);
	DisplayInformationOnUnloadedProducts();
	
	FormEvents.WhenChangingElement(ThisObject, "ShippedGoods");

EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentClient()
	
	StorageAddress = "";
	OnlyNonLabeledProductsHaveBeenUnloaded = False;
	
	ClearMessages();
	
	If CheckGoodsAndPutThemInTemporaryStorage(StorageAddress, OnlyNonLabeledProductsHaveBeenUnloaded) Then 
	
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage",            StorageAddress);
		OpeningParameters.Insert("TabularSectionName",                    "ShippedGoods");
		OpeningParameters.Insert("Ref",                               Object.Ref);
		OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", True);
		OpeningParameters.Insert("SeriesSpecificationParameters",               New FixedStructure(SeriesSpecificationParameters.ShippedGoods));
		OpeningParameters.Insert("OutputWeightVolume",                     True);
			OpeningParameters.Insert("OnlyNonLabeledProductsHaveBeenUnloaded", OnlyNonLabeledProductsHaveBeenUnloaded);
		
		CallbackDescription = New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject);
		OpenForm("CommonForm.CheckDocumentPopulation", 
			OpeningParameters,,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtServer
Function CheckGoodsAndPutThemInTemporaryStorage(StorageAddress, OnlyNonLabeledProductsHaveBeenUnloaded = False)
	
	MessageTemplate = NStr("vi = 'Để mở quy trình kiểm tra số lượng hàng hóa trong lệnh, cần điền mặt hàng trong dòng %LineNumber%.';
							|ru = 'Для открытия обработки проверки количества товаров в ордере необходимо заполнить номенклатуру в строке %LineNumber%.';
							|en = 'Fill in items in line %LineNumber% to open the data processor for checking goods quantity in the note.'; fa = 'Fill in items in line %LineNumber% to open the data processor for checking goods quantity in the note.';
							|it = 'Per aprire l''elaborazione del controllo quantità di merci nel mandato, è necessario compilare la nomenclatura nella riga %LineNumber%.';
							|pl = 'Aby otworzyć proces sprawdzania ilości towarów w zleceniu, należy wypełnić pozycję wykazu towaru w wierszu %LineNumber%.';
							|tr = 'Siparişteki ürün miktarını kontrol etme işlemini açmak için satırdaki ürün gamının doldurulması gerekir %LineNumber%.'");
	CheckPassed = True;
	
	TabularPartProducts = Object.ShippedGoods.Unload();
	For Each String In TabularPartProducts Do
		If Not ValueIsFilled(String.Products) 
			And Not ValueIsFilled(String.PackingList) 
			And Not ValueIsFilled(String.PackingListParent) Then
			
			ErrorMessage = StrReplace(MessageTemplate, "%LineNumber%", String.LineNumberDisplayed);
			
			Field = CommonClientServer.PathToTabularSection("Goods", String.LineNumber, "Products");
			Common.MessageToUser(ErrorMessage, , Field, "Object");
			CheckPassed = False;
			
		EndIf;
	EndDo;
	
	If CheckPassed 
		And ThereAreLabeledProducts 
		And TabularPartProducts.Columns.Find("ProductTypeIS") <> Undefined Then
		
		CurrentRowNumber = TabularPartProducts.Count()-1;
		While CurrentRowNumber >= 0 Do
			
			PieceByPieceAccountingOfProductsIsConducted = False;
			GoodsIssueNoteLocalization.DefinitionOfFeatureOfOccasionalAccountingOfProductsOnDate(TabularPartProducts[CurrentRowNumber].ProductTypeIS, Object.Date, PieceByPieceAccountingOfProductsIsConducted);
			
			If PieceByPieceAccountingOfProductsIsConducted Then
				TabularPartProducts.Delete(CurrentRowNumber);
				OnlyNonLabeledProductsHaveBeenUnloaded = True;
			EndIf;
			CurrentRowNumber = CurrentRowNumber - 1;
			
		EndDo;
		
	EndIf;

	If CheckPassed Then
		StorageAddress = PutToTempStorage(TabularPartProducts);
	EndIf;
	
	Return CheckPassed;
	
EndFunction

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	ActionsWithAddedLines = New Structure;
	ActionsWithModifiedStrings  = New Structure;
	
	Actions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	Actions.Barcodes                              = BarcodeData_5;
	Actions.StructureOfActionsWithAddedStrings = ActionsWithAddedLines;
	Actions.StructureOfActionsWithModifiedStrings  = ActionsWithModifiedStrings;
	Actions.SeriesSpecificationParameters                 = SeriesSpecificationParameters.ShippedGoods;
	Actions.ChangeQuantity                     = False;
	Actions.GoodsOnly                           = True;
	Actions.TSName                                  = "ShippedGoods";
	
	ProcessBarcodesServer(Actions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(Actions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(Actions) Then
		CurDataId = Actions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	PackingListsClient.UpdateCachedValuesForPCHSWithPackingLists(
		Items.ShippedGoods,
		CachedValues,
		SeriesSpecificationParameters.ShippedGoods);
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(Actions, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, Actions, CachedValues);
	
	RecalculateNumberOfSeats();
	
	If Actions.CurrentRow <> Undefined Then
		Items.ShippedGoods.CurrentRow = Actions.CurrentRow;
		
		Object.GoodsViewMode = True;
		
		DisplayModeOnChangeServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Function ThereAreFilledSeriesByFEFO()
	Return ProductsServer.ThereAreLinesWithFEFOFilledSeries(Object.ShippedGoods);
EndFunction

&AtServer
Function FillInSeriesByFEFOServer()
	If ProductsServer.ThereAreLinesWithFEFOFilledSeries_(Object.ShippedGoods) Then
		ProductsServer.FillInSeriesByFEFO(Object,SeriesSpecificationParameters.ShippedGoods);	
		PackingListsServer.RenumberLines(ThisObject, Object.ShippedGoods);
		Return True;
	Else
		Return False;
	EndIf;
EndFunction

&AtClient
Procedure OpenSelectionOfSeries(TSName, Text = "", CurrentData = Undefined)
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject,SeriesSpecificationParameters[TSName],Text, CurrentData) Then
		If CurrentData = Undefined Then
			CurDataId = Items[TSName].CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId, TSName);
		
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion",
														ThisObject,
														New Structure("TSName,ParametersOfSeriesIndicationForm", TSName,ParametersOfSeriesIndicationForm));

		OpenForm(ParametersOfSeriesIndicationForm.FormName,
					ParametersOfSeriesIndicationForm,
					ThisObject,
					,
					,
					,
					CallbackDescription,
					FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
     
    ReturnValue_1 = Result;
    
    If ReturnValue_1 <> Undefined Then
        ProcessSeriesIndication_Server(AdditionalParameters.ParametersOfSeriesIndicationForm,AdditionalParameters.TSName, CachedValues);
    EndIf;

EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm, TSName, CachedValues)
	
	Actions = New Structure;
	Actions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	Actions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	Actions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	Actions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	Actions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	Actions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	Actions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	Actions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	Actions.Insert("RecalculateWeightVolume");
	
	Actions.Insert(
		"CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters",
		Object.Warehouse,
		SeriesSpecificationParameters[TSName]));
	
	Actions.Insert(
		"RecalculateNumberOfPackages",
		BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters[TSName],ParametersOfSeriesIndicationForm,Actions,CachedValues);
	
	If TSName = "ShippedGoods" Then
		PackingListsServer.RenumberLines(ThisObject, Object.ShippedGoods);
	EndIf;
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId, TSName)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters[TSName], CurDataId, ThisObject);
	
EndFunction

#EndRegion

#Region PackingLists

&AtServer
Procedure DisplayModeOnChangeServer()
	
	PackingListsServer.DisplayModeOnChange(ThisObject, Object.ShippedGoods, Object.Ref.Metadata().ObjectPresentation);
	
EndProcedure

&AtServer
Procedure WhenMovingToAnotherLevelServer(Var_URL)
	PackingListsServer.WhenMovingToAnotherLevel(ThisObject,
		Object.ShippedGoods, Var_URL, Object.Ref.Metadata().ObjectPresentation);
EndProcedure

&AtServer
Procedure ProductsOnChangeServer(CachedValues)
	
	CurrentRow = Object.ShippedGoods.FindByID(Items.ShippedGoods.CurrentRow);
	
	ActionsWithCurLine = New Structure;
	ActionsWithCurLine.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	ActionsWithCurLine.Insert("CheckFillPackageByOwner"      , CurrentRow.Package);
	ActionsWithCurLine.Insert("RecalculateNumberOfUnits");
	ActionsWithCurLine.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ActionsWithCurLine.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ActionsWithCurLine.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	ActionsWithCurLine.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	ActionsWithCurLine.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	ActionsWithCurLine.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	ActionsWithCurLine.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));

	ActionsWithCurLine.Insert("RecalculateWeightVolume");
	ActionsWithCurLine.Insert("CheckSeriesCalculateStatus",
						New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters.ShippedGoods));

	ActionsWithCurLine.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "ShippedGoods"));

	PackingListsServer.ProductsPackingListWhenChanged(ThisObject, Object.ShippedGoods,
		"ShippedGoodsProducts", CachedValues, ActionsWithCurLine);
	
EndProcedure

&AtServer
Function PackServer()
	
	Return PackingListsServer.PackServer(ThisObject);
	
EndFunction

&AtServer
Procedure GoodsAfterDeleteRowServer(CachedValues)
	
	GoodsIssueNoteLocalization.EstablishSignOfUseOfLabeledProducts(ThisObject);
	EstablishVisibilityOfPackagingElementsDuringLabeling();

	PackingListsServer.AfterRemovalOfVTCHSPackingSheets(ThisObject, Object.ShippedGoods, Object.GoodsViewMode);
	
EndProcedure

&AtClient
Procedure AfterClosingUnboxingQuestion(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		UnpackServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure UnpackServer()
	
	PackingListsServer.UnpackPackingList(ThisObject);
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfPackagingElementsDuringLabeling()
	
	VisibilityOfElements = (GetFunctionalOption("UsePackingLists")
		And Not ThereAreLabeledProducts
		And AccessRight("Update", Metadata.Documents.PackingList)
		And AccessRight("Edit", Metadata.Documents.PackingList)
	);
	
	Items.VerifyQuantity.Title = ?(VisibilityOfElements, NStr("vi = 'Kiểm tra và đóng gói';
																|ru = 'Проверить и упаковать';
																|en = 'Verify and pack'; fa = 'تأیید و بسته‌بندی';
																|it = 'Verificare e imballare';
																|pl = 'Zweryfikuj i zapakuj';
																|tr = 'Kontrol et ve paketle'"), NStr("vi = 'Kiểm tra';
																								|ru = 'Проверить';
																								|en = 'Check'; fa = 'چک';
																								|it = 'Verificare';
																								|pl = 'Check';
																								|tr = 'Kontrol et'"));
	Items.TotalNumberOfPackageItems.Visible = VisibilityOfElements;
	Items.DecorationOfPlaces.Visible = VisibilityOfElements;
	
	Items.ShippedGoodsPackingListCode.Visible = VisibilityOfElements;
	Items.ShippedGoodsGroupPackingLists.Visible = VisibilityOfElements;
	
	Items.GroupViewModeNavigation.Visible = VisibilityOfElements;
	
	Items.ShippedGoodsPictureOfThePackingList.Visible = VisibilityOfElements;
	Items.ShippedGoodsAdditionalInfoPackingList.Visible = VisibilityOfElements;
	
	Items.ShippedGoodsPackingList.Visible = VisibilityOfElements;
	Items.ShippedGoodsLineNumberDisplayed.Visible = VisibilityOfElements;
	
	Items.ShippedItemsPackingListParent.Visible = VisibilityOfElements
		And (Object.GoodsViewMode = 1);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure FillInServiceDetailsOfTSGoods(TSName, Renumber = True)
	
	Actions = New Structure;
	Actions.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	Actions.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	Actions.Insert("FillInArticleAttribute",
		New Structure("Products", "SKU"));
	
	If TSName = "ShippedGoods" Then
		Actions.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
		Actions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
		Actions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
		Actions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
		Actions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
		BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", Actions);		
	
		PackingListsServer.FillInServiceDetails(ThisObject, Object.ShippedGoods, Actions, ,Renumber);
	Else
		ProductsServer.FillInServiceDetailsForProductInCollection(Object.GoodsByReferences, Actions);
	EndIf;
	
	If TSName = "ShippedGoods" Then
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateWeightVolume");
		
		BatchProcessingOfTablePartServer.TreatTS(Object.ShippedGoods, StructureOfActions);
		
		FormEvents.WhenChangingElement(ThisObject, "ShippedGoods");
	EndIf;

EndProcedure

&AtServer
Procedure FillInByFilteredGoodsServer(StatusChange, NewStatus)
	
	FillParameters = WarehousesServer.ParametersForFillingOrdersWithSelectedGoods();
	FillParameters.FillMode   = "Singular_";	
	If ValueIsFilled(NewStatus) Then
		FillParameters.DocumentStatus   = Common.EnumerationValueName(NewStatus);
	EndIf;
	FillParameters.StatusChange  = StatusChange;	
	FillParameters.DocumentObject    = Object;	
	
	WarehousesServer.FillOrders_WithSelectedProducts(FillParameters, Modified);
	
	If GoodsIssueNoteLocalization.MarkedProductsAreUsed() Then
		GoodsIssueNoteLocalization.FillInCacheOfBarcodesOfPackages(ThisObject);
	EndIf; 
	
	FillInServiceDetailsOfTSGoods("ShippedGoods");
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsIssueNote));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.ShippedGoods);
	DisplayInformationOnUnloadedProducts();
	
	FormEvents.WhenChangingElement(ThisObject, "ShippedGoods");
	
EndProcedure

&AtServer
Procedure DivideByPackagingsForReferenceServer()
	
	Documents.GoodsIssueNote.SplitByPackagesForReference(Object);
	FillInServiceDetailsOfTSGoods("ShippedGoods");
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.ShippedGoods);
	PackingListsServer.RenumberLines(ThisObject, Object.ShippedGoods);

EndProcedure

&AtServer
Procedure FillAndBreakIntoPackages()

	Documents.GoodsIssueNote.FillInShippedGoodsByGoodsByOrders(Object);
	Documents.GoodsIssueNote.SplitByPackagesForReference(Object);
	
	FillInServiceDetailsOfTSGoods("ShippedGoods");
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters.ShippedGoods);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(Form, Actions)
	
	Actions.Insert("RecalculateNumberOfUnits");
	Actions.Insert("RecalculateWeightVolume");
	Actions.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", Form.Object.Warehouse, Form.SeriesSpecificationParameters.ShippedGoods));
	
EndProcedure

&AtServer
Procedure SetAvailability()
	
	Items.TheGoodsToBeShippedMustBeFilledInByOrder.Enabled =
		(Object.Status = Enums.GoodsIssueNoteStatuses.ForPicking
		Or Object.Status = Enums.GoodsIssueNoteStatuses.Prepared);
		
	Items.ShippedGoodsFillInByFilteredGoods.Enabled =
		(Object.Status = Enums.GoodsIssueNoteStatuses.ForPicking
		Or Object.Status = Enums.GoodsIssueNoteStatuses.ForChecking);
		
	Items.ShippedGoodsFillInSeriesByFEFO.Enabled = SeriesSpecificationParameters.ShippedGoods.ShipmentPlanning
		Or SeriesSpecificationParameters.ShippedGoods.SelectionPlanning
		Or Not GetFunctionalOption("UseGoodsIssueNoteStatuses");
		
	RightToUseVerificationOfQuantityOfGoods = AccessRight("View", Metadata.DataProcessors.GoodsQuantityCheckInDocument);
		
	Items.CorrectQuantity.Visible = RightToUseVerificationOfQuantityOfGoods
		And (Object.Status = Enums.GoodsIssueNoteStatuses.Verified
			Or Object.Status = Enums.GoodsIssueNoteStatuses.ToShip
			Or Object.Status = Enums.GoodsIssueNoteStatuses.Shipped_);
	
	Items.VerifyQuantity.Visible = RightToUseVerificationOfQuantityOfGoods
		And (Object.Status = Enums.GoodsIssueNoteStatuses.ForChecking);
	
	Items.Inspector.Enabled =
		(Object.Status = Enums.GoodsIssueNoteStatuses.ForChecking);
		
	Items.ShippedBy.Enabled = 
		(Object.Status = Enums.GoodsIssueNoteStatuses.Verified);
	
	SetAvailabilityForSelectedProducts();
	SetTransportTaskAvailability(ThisObject);
	
EndProcedure

&AtClient
Procedure DisplayInformationOnUnloadedProductsClient()
	
	DisplayInformationOnUnloadedProducts();
	
EndProcedure

&AtServer
Procedure DisplayInformationOnUnloadedProducts()
	
	QuantityNotToShip = Object.ShippedGoods.FindRows(
							New Structure("Action", Enums.ActionsWithGoodsIssueNoteRows.DoNotShip)).Count();
	
	If QuantityNotToShip > 0 Then
		
		Items.Decoration2.Visible = False;
		Items.PictureInformation.Visible = True;
		Items.TextLeave.Visible = True;
		
		LabelText = NStr("vi = 'Trong khu vực giao hàng cần đặt %NumberOfRows% hàng hóa.';
						|ru = 'В зоне отгрузки необходимо оставить %NumberOfRows% товаров.';
						|en = '%NumberOfRows% of goods should be left in the outbound area.'; fa = '%NumberOfRows% of goods should be left in the outbound area.';
						|it = 'Nella area di spedizione, è necessario lasciare %NumberOfRows% prodotti.';
						|pl = 'W strefie wysyłki należy zostawić %NumberOfRows% towarów.';
						|tr = 'Ürünler yükleme alanında %NumberOfRows% bırakılmalıdır.'");
		NumberOfRows = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(QuantityNotToShip,
																								NStr("vi = 'vị trí,vị trí,vị trí';
																									|ru = 'позицию,позиции,позиций';
																									|en = 'position,positions,positions'; fa = 'position,positions,positions';
																									|it = 'posizione, posizioni, posizioni';
																									|pl = 'pozycję,pozycji,pozycji  ';
																									|tr = 'pozisyonu, pozisyonlar, pozisyonun'"));
		
		LabelText = StrReplace(LabelText,  "%NumberOfRows%", NumberOfRows);
		TextLeave = LabelText;
		
	Else
		
		Items.Decoration2.Visible = True;
		Items.PictureInformation.Visible = False;
		Items.TextLeave.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfPremises()
	
	Items.Premise.Visible = WarehousesServer.UseWarerooms(Object.Warehouse,Object.DateOfShipment);
	
EndProcedure

&AtServer
Procedure InstallAddressDependentStorage()
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.DateOfShipment);
	Items.ShippingZone.Visible = UseBinLocationWarehousing;
	
	If UseBinLocationWarehousing Then
		Object.ShippingZone = Catalogs.StorageBins.DefaultShippingZone(Object.Warehouse, Object.Premise, Object.ShippingZone);
	EndIf;
	
	Items.ShippedGoodsDivideByPackagingsForReference.Enabled = Not UseBinLocationWarehousing;
	SetAvailabilityForSelectedProducts();
	
EndProcedure

&AtServer
Procedure SetAvailabilityForSelectedProducts()
	Items.ShippedGoodsFillInByFilteredGoods.Enabled = UseBinLocationWarehousing
			And Object.Status <> Enums.GoodsIssueNoteStatuses.Prepared;
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtServer
Procedure PackingListWhenChangingColor(CachedValues)
	
	CurrentRow = Object.ShippedGoods.FindByID(Items.ShippedGoods.CurrentRow);
	
	ActionsWithCurLine = New Structure;
	ActionsWithCurLine.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ActionsWithCurLine.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ActionsWithCurLine.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	ActionsWithCurLine.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	ActionsWithCurLine.Insert("RecalculateNumberOfUnits");
	ActionsWithCurLine.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "ShippedGoods"));
	ActionsWithCurLine.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	ActionsWithCurLine.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	ActionsWithCurLine.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	ActionsWithCurLine.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	ActionsWithCurLine.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	ActionsWithCurLine.Insert("RecalculateWeightVolume");
	
	ActionsWithAddedStrings = New Structure;
	ActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	ActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	ActionsWithAddedStrings.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	ActionsWithAddedStrings.Insert("FillInMeasuredValueTypeAttribute", New Structure("Products", "MeasuredValueType"));
	ActionsWithAddedStrings.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	ActionsWithAddedStrings.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	ActionsWithAddedStrings.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	ActionsWithAddedStrings.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	ActionsWithAddedStrings.Insert("RecalculateWeightVolume");
	
	PackingListsServer.ProductsPackingListWhenChanged(ThisObject, Object.ShippedGoods,
		"ShippedGoodsPackingList", CachedValues, ActionsWithCurLine, ActionsWithAddedStrings);
	
EndProcedure

&AtServer
Procedure UpLevelServer()
	
	FoundRows = PackingLists.FindRows(New Structure("PackingList",PackingListParent));
	WhenMovingToAnotherLevelServer(FoundRows[0].PackingListParent);
	
EndProcedure

&AtServer
Procedure RecalculateNumberOfSeats()
	
	PackingListsServer.RecalculateNumberOfSeats(ThisObject, Object.ShippedGoods)
	
EndProcedure

&AtClient
Procedure RefillWithShippedGoodsCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
    	RefillWithShippedGoodsServer();
	EndIf;	
	
EndProcedure

&AtServer
Procedure RefillWithShippedGoodsServer()
	
	Documents.GoodsIssueNote.ChangeGoodsAccordingToOrdersForShippedGoods(Object, True);
	FillInServiceDetailsOfTSGoods("GoodsByReferences", False);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.GoodsByReferences);
	
EndProcedure

&AtClient
Procedure MoveToExistingNoteCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		ModifiedOrder = MoveToExistingNoteServer(Result, AdditionalParameters.LinesToWrap);
		
		If ValueIsFilled(ModifiedOrder) Then
			TMCommonUseClient.NotifyUserAboutChangesToObject(Object.Ref);
			TMCommonUseClient.NotifyUserAboutChangesToObject(ModifiedOrder);
			
			Notify("Write_GoodsIssueNote", Undefined, Object.Ref);
			Notify("Write_GoodsIssueNote", Undefined, ModifiedOrder);
		EndIf;	
	EndIf;
	
EndProcedure

&AtServer
Function MoveToExistingNoteServer(AnotherWarrant, LinesToWrap)
	LockFormDataForEdit();
	
	SourceObject_ = FormAttributeToValue("Object");
	
	ModifiedOrder = Documents.GoodsIssueNote.BreakOrder(SourceObject_, LinesToWrap, AnotherWarrant);
	
	If ValueIsFilled(ModifiedOrder) Then
		ValueToFormAttribute(SourceObject_,"Object");
		Modified = False;
		OnReadCreateAtServer();
	Else
		Read();
	EndIf;
	
	Return ModifiedOrder; 
	
EndFunction

&AtClient
Procedure MoveToNewNoteCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result)
		Or AdditionalParameters.Property("NoTask") Then
		NewWarrant = MoveToNewNoteServer(Result, AdditionalParameters.LinesToWrap);
		If ValueIsFilled(NewWarrant) Then
			TMCommonUseClient.NotifyUserAboutChangesToObject(Object.Ref);
			TMCommonUseClient.NotifyUserAboutChangesToObject(NewWarrant, NStr("vi = 'Bổ sung:';
																				|ru = 'Добавление:';
																				|en = 'Add:'; fa = 'Add:';
																				|it = 'Aggiungere:';
																				|pl = 'Add:';
																				|tr = 'Ekleme:'"));
			
			Notify("Write_GoodsIssueNote", Undefined, Object.Ref);
			Notify("Write_GoodsIssueNote", Undefined, NewWarrant);
		EndIf;	
	EndIf;
	
EndProcedure

&AtServer
Function MoveToNewNoteServer(TransportationJob, LinesToWrap)
	LockFormDataForEdit();
	
	SourceObject_ = FormAttributeToValue("Object");
	NewWarrant = Documents.GoodsIssueNote.BreakOrder(SourceObject_, LinesToWrap,,TransportationJob);
	
	If ValueIsFilled(NewWarrant) Then
		ValueToFormAttribute(SourceObject_,"Object");
		Modified = False;
		OnReadCreateAtServer();
	EndIf;
	
	Return NewWarrant; 
	
EndFunction

&AtServerNoContext
Function DeliveryOrderInTransportOrder(TransportationJob, Recipient)
	
	Return GoodsDelivery.DeliveryOrderInTransportOrder(TransportationJob, Recipient);
	
EndFunction

&AtClientAtServerNoContext
Procedure SetTransportTaskAvailability(Form)
	
	Form.Items.TransportationJob.Enabled = Form.Object.ShipmentUnderTransportationJob;
	
EndProcedure

&AtServer
Function CheckCompletenessOfProductLocations()
	
	Cancel = False;
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.TSName = "ShippedGoods";
	CheckParameters.ConditionForSelectingCompletenessCheckLines = "ShippedGoods.Action <> VALUE(Enum.ActionsWithGoodsIssueNoteRows.DoNotShip)";

	ProductsServer.CheckCompletenessOfProductLocations(Object.ShippedGoods, Cancel, CheckParameters);
	
	Return Cancel;
	
EndFunction

&AtServer
Procedure SortRows(ColumnName, Direction)
	ColumnNameDirection = StrReplace(Items[ColumnName].DataPath, "Object.ShippedGoods.", "") + " " + Direction;
	
	Object.ShippedGoods.Sort(ColumnNameDirection);
	If UsePackingLists Then
		PackingListsServer.RenumberLines(ThisObject, Object.ShippedGoods);
	EndIf;
	
EndProcedure

// StandardSubsystems.Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_DateOfShipment" Then
		DateOfShipmentOnChange(Items.DateOfShipment);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
