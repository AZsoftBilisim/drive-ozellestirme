// @strict-types

#Region Variables

&AtClient
Var CachedValues; // See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IsNew = Parameters.Key.IsEmpty();
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnCreatReadAtServer();
		
	EndIf;
	
	TimeFillingItems = New Array; // Array of FormField
	TimeFillingItems.Add(Items.DeliveryTimeFrom);
	TimeFillingItems.Add(Items.DeliveryTimeTo);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(TimeFillingItems);
	
	SetConditionalAppearance();
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnCreatReadAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	SetAvailabilityOfSelectionCommands();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	IsNew = False;
	
	FillInServiceDetailsForProductRange();
	SetAvailabilityOfSelectionCommands();
	UpdateTotals(Object.Goods, WeightTotal, NetWeightTotal, VolumeTotal);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_Products"
	 Or EventName = "Write_ProductPackages" Then
		
		RecalculateGoodsRows(EventName, Source);
		
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	// StandardSubsystems.FilesOperations
	
	FilesOperationsClient.ShowConfirmationForClosingFormWithFiles(ThisObject, Cancel, Exit, Object.Ref);
	If Cancel Then
		Return;
	EndIf;
	
	// End StandardSubsystems.FilesOperations
	
EndProcedure

// Parameters:
//  ValueSelected - Structure, Arbitrary -
//  ChoiceSource - ClientApplicationForm -
//
&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.PickGoodsToDeliveryDocument.Form.PickForm" Then
		
		Modified = True;
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		CalculateTotalsWeightVolume();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DeliveryMethodOnChange(Item)
	
	DeliveryMethodOnChangeServer();
	
EndProcedure

&AtClient
Async Procedure SenderOnChange(Item)
	
	SenderChanged = (Object.Sender <> CurrentSender);
	
	If SenderChanged
	   And Object.Goods.Count() > 0 Then
		
		Response = Await ShowQuestionAboutClearingListOfGoods(); // DialogReturnCode
		
		If Response <> DialogReturnCode.Yes Then
			
			FillPropertyValues(Object, CurrentSenderData);
			SenderChanged = False;
			
		EndIf;
		
	EndIf;
	
	If SenderChanged Then
		
		Object.Goods.Clear();
		SenderOnChangeServer();
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure RecipientOnChange(Item)
	
	RecipientChanged = (Object.Recipient <> CurrentRecipient);
	
	If RecipientChanged
	   And Object.Goods.Count() > 0 Then
		
		Response = Await ShowQuestionAboutClearingListOfGoods(); // DialogReturnCode
		
		If Response <> DialogReturnCode.Yes Then
			
			FillPropertyValues(Object, CurrentRecipientData);
			RecipientChanged = False;
			
		EndIf;
		
	EndIf;
	
	If RecipientChanged Then
		
		Object.Goods.Clear();
		RecipientOnChangeServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CarrierOnChange(Item)
	
	CarrierOnChangeServer();
	
EndProcedure

&AtClient
Procedure CarrierDeliveryPointOnChange(Item)
	
	If Object.DeliveryToCarrier Then
		
		If Object.CarrierDeliveryPoint.IsEmpty() Then
			
			Object.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
			
		Else
			
			FillInDeliveryZoneByCarrier();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecialTransportationConditionsOnChange(Item)
	
	Items.SpecialTransportationConditionsDescription.ReadOnly = Not Object.SpecialTransportationConditions;
	
EndProcedure

&AtClient
Procedure DeliveryToCarrierOnChange(Item)
	
	If Not Object.DeliveryToCarrier Then
		
		Object.Carrier = PredefinedValue("Catalog.Partners.EmptyRef");
		CurrentCarrier = Object.Carrier;
		Object.CarrierDeliveryPoint = PredefinedValue("Catalog.DeliveryPoints.EmptyRef");
		Object.CarrierSDeliveryArea = PredefinedValue("Catalog.DeliveryZones.EmptyRef");
		
	EndIf;
	
	ConfigureVisibilityAvailabilityOfFields();
	
EndProcedure

&AtClient
Procedure DeliveryPointRecipientOnChange(Item)

	DeliveryPointRecipientOnChangeServer();
	
EndProcedure

&AtClient
Procedure SenderDeparturePointOnChange(Item)
	
	SenderDeparturePointOnChangeServer();
	
EndProcedure

&AtClient
Async Procedure OrganizationOnChange(Item)
	
	OrganizationChanged_1 = (Object.Organization <> CurrentCompany);
	
	If OrganizationChanged_1
	   And Object.Goods.Count() > 0 Then
		
		Response = Await ShowQuestionAboutClearingListOfGoods(); // DialogReturnCode
		
		If Response <> DialogReturnCode.Yes Then
			
			Object.Organization = CurrentCompany;
			OrganizationChanged_1 = False;
			
		EndIf;
		
	EndIf;
	
	If OrganizationChanged_1 Then
		
		Object.Goods.Clear();
		CurrentCompany = Object.Organization;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DepartureAreaOnChange(Item)
	
	CurrentSenderData = SenderData(Object);
	
EndProcedure

&AtClient
Procedure DeliveryZoneOnChange(Item)
	
	CurrentRecipientData = RecipientData(Object);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits", Undefined);
	AddWeightVolumeFillingActions(StructureOfActions);
	StructureOfActions.Insert("RecalculateWeightVolume", Undefined);
	
	ProductsOnChangeOverridable = New Structure;
	ProductsOnChangeOverridable.Insert("FormName", FormName);
	ProductsOnChangeOverridable.Insert("TabularSectionName", "Goods");
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillInNetWeightOfUnit(CurrentRow);
	RecalculateWeightVolumeInCommonUnits(CurrentRow);
	CalculateTotalsWeightVolume();
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", Undefined);
	StructureOfActions.Insert("RecalculateWeightVolume", Undefined);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	RecalculateWeightVolumeInCommonUnits(CurrentRow);
	CalculateTotalsWeightVolume();
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddWeightVolumeFillingActions(StructureOfActions);
	StructureOfActions.Insert("RecalculateNumberOfUnits", Undefined);
	StructureOfActions.Insert("RecalculateWeightVolume", Undefined);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillInNetWeightOfUnit(CurrentRow);
	RecalculateWeightVolumeInCommonUnits(CurrentRow);
	CalculateTotalsWeightVolume();
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	CalculateTotalsWeightVolume();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

// StandardSubsystems.FilesOperations

&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
	
EndProcedure

// End StandardSubsystems.FilesOperations

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

// IntegrationWith1CDocumentManagementSubsystem

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
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
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Async Procedure PickUpData(Command)
	
	ClearMessages();
	Cancel = False;
	
	CheckContentBeforeSelection(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	If Modified
	 Or IsNew Then
		
		RecordingResult = Await ResultOfDocumentRecordingBeforeSelection();
		
		If Not RecordingResult Then
			Cancel = True;
		EndIf;
		
	EndIf;
	
	If Not Cancel Then
		
		PerformanceMonitorClient.TimeMeasurement("Document.DeliveryOrder.DocumentForm.Command.PickUpData");
		OpenDataSelection();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	SetConditionalAppearanceOfUnfilledWeightOfPackagingUnit();
	SetConditionalAppearanceOfUnfilledVolumeOfPackage();
	SetConditionalAppearanceUnfilledNetWeight();
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);
	SetConditionalAppearanceOfSeries();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceUnfilledNetWeight()
	
	TextNotUsed = GoodsDeliveryClientServer.ConditionalAppearanceTextIsNotUsedWeightVolume();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNet_Weight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.NetWeightUnits");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfUnfilledVolumeOfPackage()
	
	TextNotUsed = GoodsDeliveryClientServer.ConditionalAppearanceTextIsNotUsedWeightVolume();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVolumeM3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfUnfilledWeightOfPackagingUnit()
	
	TextNotUsed = GoodsDeliveryClientServer.ConditionalAppearanceTextIsNotUsedWeightVolume();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ItemsGrossWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", TextNotUsed);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfSeries()
	
	ListOfTypesForSeries = New ValueList; // ValueList of EnumRef.ItemsTypes
	ListOfTypesForSeries.Add(Enums.ItemsTypes.OwnGoods);
	ListOfTypesForSeries.Add(Enums.ItemsTypes.ReusablePackage);
	
	PathToSeriesField = "Object.Goods.Series";
	PathToSelectionFieldProductType = "Object.Goods.ItemsType";
	NameOfSeriesFormField = Items.GoodsSeries.Name; // FormField
	
	// For goods
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfSeriesFormField);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldProductType);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = ListOfTypesForSeries;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<cho hàng hóa>';
																		|ru = '<для товаров>';
																		|en = '<for goods>'; fa = '<for goods>';
																		|it = '<per le merci>';
																		|pl = '<dla towarów>';
																		|tr = '<ürünler için>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	// The series is not specified
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfSeriesFormField);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSeriesField);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToSelectionFieldProductType);
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ListOfTypesForSeries;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra sê-ri>';
																		|ru = '<серия не указывается>';
																		|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
																		|it = '<serie non è indicata>';
																		|pl = '<seria nie jest określana>';
																		|tr = '<parti belirtilmemektedir>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	CurrentSender = Object.Sender;
	CurrentRecipient = Object.Recipient;
	CurrentCarrier = Object.Carrier;
	CurrentCompany = Object.Organization;
	
	CurrentSenderData = SenderData(Object);
	CurrentRecipientData = RecipientData(Object);
	
	FillInServiceDetailsForProductRange();
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	ConfigureVisibilityAvailabilityOfFields();
	UpdateTotals(Object.Goods, WeightTotal, NetWeightTotal, VolumeTotal);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	StructureOfActions = New Structure;
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert(
		"FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	
	AddWeightVolumeFillingActions(StructureOfActions);
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	For Each RowOfGoods In Object.Goods Do
		
		FillInNetWeightOfUnit(RowOfGoods);
		RecalculateWeightVolumeInCommonUnits(RowOfGoods);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ConfigureVisibilityAvailabilityOfFields()
	
	VisibleElementsNames = New Array; // Array of String
	NamesOfAllElements = New Array; // Array of String
	NamesOfPossibleMandatoryElements = New Array; // Array of String
	NamesOfRequiredElements = New Array; // Array of String
	
	NamesOfAllElements.Add(Items.SenderDeparturePoint.Name);
	NamesOfAllElements.Add(Items.DepartureArea.Name);
	NamesOfAllElements.Add(Items.DeliveryPointRecipient.Name);
	NamesOfAllElements.Add(Items.DeliveryZone.Name);
	NamesOfAllElements.Add(Items.DeliveryTimeFrom.Name);
	NamesOfAllElements.Add(Items.DeliveryTimeTo.Name);
	NamesOfAllElements.Add(Items.AdditionalInformation.Name);
	NamesOfAllElements.Add(Items.SpecialTransportationConditions.Name);
	NamesOfAllElements.Add(Items.SpecialTransportationConditionsDescription.Name);
	NamesOfAllElements.Add(Items.Carrier.Name);
	NamesOfAllElements.Add(Items.DeliveryToCarrier.Name);
	NamesOfAllElements.Add(Items.CarrierDeliveryPoint.Name);
	NamesOfAllElements.Add(Items.CarrierSDeliveryArea.Name);
	NamesOfAllElements.Add(Items.GoodsSeries.Name);
	
	NamesOfPossibleMandatoryElements.Add(Items.DeliveryPointRecipient.Name);
	NamesOfPossibleMandatoryElements.Add(Items.DeliveryZone.Name);
	NamesOfPossibleMandatoryElements.Add(Items.Carrier.Name);
	NamesOfPossibleMandatoryElements.Add(Items.CarrierDeliveryPoint.Name);
	NamesOfPossibleMandatoryElements.Add(Items.CarrierSDeliveryArea.Name);
	
	If Object.DeliveryMethod <> Enums.TransportMethods25.SelfPickup Then
		
		VisibleElementsNames.Add(Items.SenderDeparturePoint.Name);
		VisibleElementsNames.Add(Items.DepartureArea.Name);
		VisibleElementsNames.Add(Items.DeliveryPointRecipient.Name);
		VisibleElementsNames.Add(Items.DeliveryZone.Name);
		VisibleElementsNames.Add(Items.DeliveryTimeFrom.Name);
		VisibleElementsNames.Add(Items.DeliveryTimeTo.Name);
		VisibleElementsNames.Add(Items.AdditionalInformation.Name);
		VisibleElementsNames.Add(Items.SpecialTransportationConditions.Name);
		VisibleElementsNames.Add(Items.SpecialTransportationConditionsDescription.Name);
		
	EndIf;
	
	If Object.DeliveryMethod = Enums.TransportMethods25.OwnDelivery Then
		
		VisibleElementsNames.Add(Items.DeliveryToCarrier.Name);
		VisibleElementsNames.Add(Items.Carrier.Name);
		VisibleElementsNames.Add(Items.CarrierDeliveryPoint.Name);
		VisibleElementsNames.Add(Items.CarrierSDeliveryArea.Name);
		
		NamesOfRequiredElements.Add(Items.DeliveryPointRecipient.Name);
		NamesOfRequiredElements.Add(Items.DeliveryZone.Name);
		
		If Object.DeliveryToCarrier Then
			
			NamesOfRequiredElements.Add(Items.Carrier.Name);
			NamesOfRequiredElements.Add(Items.CarrierDeliveryPoint.Name);
			NamesOfRequiredElements.Add(Items.CarrierSDeliveryArea.Name);
			
		EndIf;
		
	EndIf;
	
	If Object.DeliveryMethod = Enums.TransportMethods25.ByCarrier Then
		
		VisibleElementsNames.Add(Items.Carrier.Name);
		
		NamesOfRequiredElements.Add(Items.Carrier.Name);
		
	EndIf;
	
	CarrierDataIsAvailable =
		((Object.DeliveryMethod = Enums.TransportMethods25.OwnDelivery
		  And Object.DeliveryToCarrier)
		 Or Object.DeliveryMethod = Enums.TransportMethods25.ByCarrier);
	
	Items.Carrier.ReadOnly = Not CarrierDataIsAvailable;
	Items.CarrierDeliveryPoint.ReadOnly = Not CarrierDataIsAvailable;
	Items.CarrierSDeliveryArea.ReadOnly = Not CarrierDataIsAvailable;
	
	Items.SpecialTransportationConditionsDescription.ReadOnly = Not Object.SpecialTransportationConditions;
	
	SerialSenderParameters = WarehousesServer.UseOfSeriesInStock(Object.Sender, False);
	If SerialSenderParameters.UseItemsBatch Then
		VisibleElementsNames.Add(Items.GoodsSeries.Name);
	EndIf;
	
	TMCommonUseClientServer.SetVisibilityOfElementsByArray(
		Items,
		NamesOfAllElements,
		VisibleElementsNames);
	
	NamesOfOptionalElements = CommonClientServer.ArraysDifference(
		NamesOfPossibleMandatoryElements,
		NamesOfRequiredElements);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		NamesOfOptionalElements,
		"AutoMarkIncomplete",
		False);
		
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		NamesOfOptionalElements,
		"MarkIncomplete",
		False);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		NamesOfRequiredElements,
		"AutoMarkIncomplete",
		True);
	
EndProcedure

&AtServer
Procedure FillInDeliveryZoneByCarrier()
	
	If Object.CarrierDeliveryPoint.IsEmpty() Then
		
		Object.CarrierSDeliveryArea = Catalogs.DeliveryZones.EmptyRef();
		
	Else
		
		DetailsOfCarrierSDeliveryPoint = Common.ObjectAttributesValues(
			Object.CarrierDeliveryPoint, "DeliveryZone");
		Object.CarrierSDeliveryArea = DetailsOfCarrierSDeliveryPoint.DeliveryZone;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure RecalculateWeightVolumeInCommonUnits(RowOfGoods)
	
	// volume in cubic meters
	If RowOfGoods.MeasuringUnit Then
		RowOfGoods.VolumeM3 = RowOfGoods.Count * RowOfGoods.UnitVolume;
	Else
		RowOfGoods.VolumeM3 = RowOfGoods.NumberOfPackages * RowOfGoods.PackageVolume;
	EndIf;
	
	// Net weight in kg
	RowOfGoods.Net_Weight = RowOfGoods.Count * RowOfGoods.NetWeightUnits;
	
	// gross weight in kg
	If RowOfGoods.MeasuringUnit Then
		RowOfGoods.Weight = RowOfGoods.Net_Weight;
	Else
		RowOfGoods.Weight = RowOfGoods.NumberOfPackages * RowOfGoods.PackageWeight;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CoefficientsWeightVolume(Val Products, Val Package)
	
	EmptyPackaging = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
	Result = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(EmptyPackaging, Products,, False);
	MeasuringUnit = Catalogs.PackagesAndUnitsOfMeasure.ThisIsADimensionalUnit(Package);
	Result.Insert("MeasuringUnit", MeasuringUnit);
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure FillInNetWeightOfUnit(RowOfGoods)
	
	ProductData_1 = CoefficientsWeightVolume(RowOfGoods.Products, RowOfGoods.Package);
	RowOfGoods.NetWeightUnits = ProductData_1.Net_Weight; // Number
	RowOfGoods.UnitVolume = ProductData_1.VolumeM3; // Number
	RowOfGoods.MeasuringUnit = ProductData_1.MeasuringUnit;
	
EndProcedure

&AtClient
Async Function ShowQuestionAboutClearingListOfGoods()
	
	QueryText = NStr("vi = 'Danh sách hàng hóa sẽ bị xóa. Tiếp tục?';
					|ru = 'Список товаров будет очищен. Продолжить?';
					|en = 'The item list will be cleared. Continue?'; fa = 'The item list will be cleared. Continue?';
					|it = 'L''elenco degli articoli sarà cancellato. Continuare?';
					|pl = 'Lista towarów zostanie wyczyszczona. Kontynuować?';
					|tr = 'Mallar listesi temizlenecek. Devam edilsin mi?'");
	Promise = DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo);
	
	Return Promise;
	
EndFunction

&AtClientAtServerNoContext
Function SenderData(Object)
	
	FieldsNames = "Sender, SenderDeparturePoint, DepartureArea";
	CurrentData = New Structure(FieldsNames);
	FillPropertyValues(CurrentData, Object);
	
	SenderData = New FixedStructure(CurrentData);
	Return SenderData;
	
EndFunction

&AtClientAtServerNoContext
Function RecipientData(Object)
	
	FieldsNames = "Recipient, DeliveryPointRecipient, DeliveryZone";
	CurrentData = New Structure(FieldsNames);
	FillPropertyValues(CurrentData, Object);
	
	RecipientData = New FixedStructure(CurrentData);
	Return RecipientData;
	
EndFunction

#Region SelectionOfData

&AtClient
Procedure CheckContentBeforeSelection(Cancel)
	
	If Not ValueIsFilled(Object.Organization) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
						|ru = 'Поле ""Организация"" не заполнено';
						|en = '""Company"" is required'; fa = '""Company"" is required';
						|it = 'Il campo ""Società"" non è compilato';
						|pl = 'Nie wypełniono pola ""Firma""';
						|tr = '""İş yeri"" alanı doldurulmadı'");
		CommonClient.MessageToUser(ErrorText,, "Organization", "Object", Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Object.Sender) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Người gửi""';
						|ru = 'Поле ""Отправитель"" не заполнено';
						|en = '""Sender"" is not filled in'; fa = '""Sender"" is not filled in';
						|it = 'Il campo ""Mittente"" non è compilato';
						|pl = 'Nie wypełniono pola ""Отправитель""';
						|tr = '""Gönderen"" alanı doldurulmadı'");
		CommonClient.MessageToUser(ErrorText,, "Sender", "Object", Cancel);
		
	EndIf;
	
	If Not ValueIsFilled(Object.Recipient) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Người nhận""';
						|ru = 'Поле ""Получатель"" не заполнено';
						|en = 'The ""Recipients"" field is required'; fa = 'The ""Recipients"" field is required';
						|it = 'The ""Recipients"" field is required';
						|pl = 'The ""Recipients"" field is required';
						|tr = '""Alıcı"" alanı doldurulmamış'");
		CommonClient.MessageToUser(ErrorText,, "Recipient", "Object", Cancel);
		
	EndIf;
	
EndProcedure

&AtClient
Async Function ResultOfDocumentRecordingBeforeSelection()
	
	RecordingResult = False;
	
	If Object.Posted Then
		QueryText = NStr("vi = 'Chứng từ đã bị thay đổi. Kết chuyển?';
						|ru = 'Документ был изменен. Провести?';
						|en = 'The document was changed. Post it?'; fa = 'The document was changed. Post it?';
						|it = 'The document was changed. Post it?';
						|pl = 'The document was changed. Post it?';
						|tr = 'Belge değiştirildi. Kaydedilsin mi?'");
	Else
		QueryText = NStr("vi = 'Chứng từ đã bị thay đổi. Lưu lại?';
						|ru = 'Документ был изменен. Записать?';
						|en = 'The document was changed. Save it?'; fa = 'The document was changed. Save it?';
						|it = 'The document was changed. Save it?';
						|pl = 'The document was changed. Save it?';
						|tr = 'Belge değiştirildi. Yazılsın mı?'");
	EndIf;
	Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
	
	If Response <> DialogReturnCode.Yes Then
		Return RecordingResult;
	EndIf;
	
	If Object.Posted Then
		
		ClearMessages();
		If CheckFilling() Then
			RecordingResult = Write(New Structure("WriteMode", DocumentWriteMode.Posting));
		EndIf;
		
	Else
		
		RecordingResult = Write(New Structure("WriteMode", DocumentWriteMode.Write));
		
	EndIf;
	
	Return RecordingResult;
	
EndFunction

&AtClient
Procedure OpenDataSelection()
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Warehouse", Object.Sender);
	FormParameters.Insert("Recipient", Object.Recipient);
	FormParameters.Insert("ConsiderQuantityInDocument", Not Object.Posted);
	FormParameters.Insert("DocumentDeliveries", Object.Ref);
	
	If Object.DeliveryDirection = PredefinedValue("Enum.DeliveryDirections.PartnerWarehouse_") Then
		FormParameters.Insert("DeliveryType", PredefinedValue("Enum.DeliveryTypes.OutgoingInfo"));
	EndIf;
	
	If Object.DeliveryToCarrier Then
		
		DeliveryPointFixed = Object.CarrierDeliveryPoint;
		DeliveryZoneFixed = Object.CarrierSDeliveryArea;
		
	Else
		
		DeliveryPointFixed = Object.DeliveryPointRecipient;
		DeliveryZoneFixed = Object.DeliveryZone;
		
	EndIf;
	FormParameters.Insert("DeliveryPointFixed", DeliveryPointFixed);
	FormParameters.Insert("DeliveryZoneFixed", DeliveryZoneFixed);
	FormParameters.Insert("RecordDeliveryParameters", True);
	
	OpenForm("DataProcessor.PickGoodsToDeliveryDocument.Form.PickForm",
		FormParameters,
		ThisObject,
		UUID);
	
EndProcedure

// Parameters:
//  ValueSelected - Structure:
//   * AddressOfSelectedItems - String
//
&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(Val ValueSelected)
	
	SelectedGoods = SelectedGoods(ValueSelected);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	NewGoodsLines = New Array; // Array of FormDataCollectionItem
	
	FilterGoods = New Structure;
	FilterGoods.Insert("ReferenceOrder", Undefined);
	FilterGoods.Insert("DeliveryLineCode", 0);
	
	StructureOfActionRecalculateNumberOfPackagingUnits = New Structure("RecalculateNumberOfPackages", Undefined);
	
	For Each StringMatched In SelectedGoods Do
		
		FillPropertyValues(FilterGoods, StringMatched);
		FilterGoods.DeliveryLineCode = StringMatched.RowCode;
		ContentLinesByGoods = Object.Goods.FindRows(FilterGoods);
		If ContentLinesByGoods.Count() > 0 Then
			
			SuitableString = ContentLinesByGoods[0];
			SuitableString.Count = SuitableString.Count + StringMatched.Count;
			
			IsNewLine = False;
			
		Else
			
			SuitableString = Object.Goods.Add();
			FillPropertyValues(SuitableString, StringMatched);
			SuitableString.DeliveryLineCode = StringMatched.RowCode;
			NewGoodsLines.Add(SuitableString);
			
			IsNewLine = True;
			
		EndIf;
		
		BatchProcessingOfTablePartClientServer.RecalculateNumberOfPackagesInTSLine(
			SuitableString, StructureOfActionRecalculateNumberOfPackagingUnits, CachedValues);
		
		If Not IsNewLine Then
			
			RecalculateWeightVolumeInCommonUnits(SuitableString);
			
		EndIf;
		
	EndDo;
	
	StructureOfActions = New Structure;
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", Undefined);
	StructureOfActions.Insert("CheckFillPackageByOwner", Undefined);
	StructureOfActions.Insert("RecalculateNumberOfUnits", Undefined);
	AddWeightVolumeFillingActions(StructureOfActions);
	StructureOfActions.Insert("RecalculateWeightVolume", Undefined);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		NewGoodsLines, StructureOfActions, Object.Goods, CachedValues);
	
	For Each RowOfGoods In NewGoodsLines Do
		
		FillInNetWeightOfUnit(RowOfGoods);
		RecalculateWeightVolumeInCommonUnits(RowOfGoods);
		
	EndDo;
	
	Documents.DeliveryOrder.UpdateAdditionalParameters(Object, NewGoodsLines);
	
EndProcedure

// Parameters:
//  ValueSelected - Structure - selected value:
// * AddressOfSelectedItems - String - 
// 
// Returns:
//  ValueTable - Table of selected products:
//  * RowCode - Number
//  * DeliveryTo - CatalogRef.Partners
//  * DeliveryPoint - CatalogRef.DeliveryPoints
//  * DeliveryZone - CatalogRef.DeliveryZones
//  * Count - Number
//
&AtServer
Function SelectedGoods(ValueSelected)
	
	SelectedGoods = GetFromTempStorage(ValueSelected.AddressOfSelectedItems); // ValueTable
	DeleteFromTempStorage(ValueSelected.AddressOfSelectedItems);
	Return SelectedGoods;
	
EndFunction

&AtServer
Procedure SetAvailabilityOfSelectionCommands()
	
	Items.GoodsPickUpData.Enabled = (Not ReadOnly);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormHeaderElementsAuxiliary

&AtServer
Procedure DeliveryMethodOnChangeServer()
	
	If Object.DeliveryMethod <> Enums.TransportMethods25.OwnDelivery
	   And Object.DeliveryMethod <> Enums.TransportMethods25.ByCarrier Then
		
		Object.DeliveryToCarrier = False;
		Object.Carrier = Catalogs.Partners.EmptyRef();
		Object.CarrierDeliveryPoint = Catalogs.DeliveryPoints.EmptyRef();
		Object.CarrierSDeliveryArea = Catalogs.DeliveryZones.EmptyRef();
		
	EndIf;
	
	If Object.DeliveryMethod = Enums.TransportMethods25.SelfPickup Then
		
		Object.SenderDeparturePoint = Catalogs.DeliveryPoints.EmptyRef();
		Object.DepartureArea = Catalogs.DeliveryZones.EmptyRef();
		
		Object.DeliveryPointRecipient = Catalogs.DeliveryPoints.EmptyRef();
		Object.DeliveryZone = Catalogs.DeliveryZones.EmptyRef();
		
		Object.DeliveryTimeFrom = Date(1, 1, 1);
		Object.DeliveryTimeTo = Date(1, 1, 1);
		
		Object.AdditionalInformation = "";
		Object.SpecialTransportationConditions = False;
		Object.SpecialTransportationConditionsDescription = "";
		
	EndIf;
	
	ConfigureVisibilityAvailabilityOfFields();
	
EndProcedure

&AtServer
Procedure SenderOnChangeServer()
	
	If Object.Sender = CurrentSender Then
		Return;
	EndIf;
	
	CurrentSender = Object.Sender;
	CurrentSenderData = SenderData(Object);
	SenderSPointData = Catalogs.DeliveryPoints.DeliveryPointInformationMain(Object.Sender);
	Object.SenderDeparturePoint = SenderSPointData.DeliveryPoint;
	Object.DepartureArea = SenderSPointData.DeliveryZone;
	
	ConfigureVisibilityAvailabilityOfFields();
	
EndProcedure

&AtServer
Procedure RecipientOnChangeServer()
	
	If Object.Recipient = CurrentRecipient Then
		Return;
	EndIf;
	
	CurrentRecipient = Object.Recipient;
	CurrentRecipientData = RecipientData(Object);
	RecipientPointData = Catalogs.DeliveryPoints.DeliveryPointInformationMain(Object.Recipient);
	Object.DeliveryPointRecipient = RecipientPointData.DeliveryPoint;
	Object.DeliveryZone = RecipientPointData.DeliveryZone;
	
	ConfigureVisibilityAvailabilityOfFields();
	
EndProcedure

&AtServer
Procedure CarrierOnChangeServer()
	
	If Object.Carrier = CurrentCarrier Then
		Return;
	EndIf;
	
	CurrentCarrier = Object.Carrier;
	
	If Object.DeliveryToCarrier Then
		
		CarrierSDataPoints = Catalogs.DeliveryPoints.DeliveryPointInformationMain(Object.Carrier);
		Object.CarrierDeliveryPoint = CarrierSDataPoints.DeliveryPoint;
		Object.CarrierSDeliveryArea = CarrierSDataPoints.DeliveryZone;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DeliveryPointRecipientOnChangeServer()
	
	If Object.DeliveryPointRecipient.IsEmpty() Then
		
		Object.DeliveryZone = Catalogs.DeliveryZones.EmptyRef();
		
	Else
		
		DetailsOfRecipientSDeliveryPoint = Common.ObjectAttributesValues(
			Object.DeliveryPointRecipient, "DeliveryZone");
		Object.DeliveryZone = DetailsOfRecipientSDeliveryPoint.DeliveryZone;
		
	EndIf;
	
	CurrentRecipientData = RecipientData(Object);
	
EndProcedure

&AtServer
Procedure SenderDeparturePointOnChangeServer()
	
	If ValueIsFilled(Object.SenderDeparturePoint) Then
		
		DetailsOfPointOfDeparture = Common.ObjectAttributesValues(Object.SenderDeparturePoint, "DeliveryZone");
		Object.DepartureArea = DetailsOfPointOfDeparture.DeliveryZone;
		
	Else
		
		Object.DepartureArea = Catalogs.DeliveryZones.EmptyRef();
		
	EndIf;
	
	CurrentSenderData = SenderData(Object);
	
EndProcedure

&AtClient
Procedure RecalculateGoodsRows(EventName, Source)
	
	RowFilter = New Structure;
	
	If EventName = "Write_Products" Then
		
		RowFilter.Insert("Products", Source);
		
	ElsIf EventName = "Write_ProductPackages" Then
		
		RowFilter.Insert("Package", Source);
		
	Else
		
		Return;
		
	EndIf;
	
	RowsForRecalculate = Object.Goods.FindRows(RowFilter);
	If RowsForRecalculate.Count() > 0 Then
		
		RecalculateGoodsRowsServer(RowFilter);
		Modified = True;
		
	EndIf;
	
	CalculateTotalsWeightVolume();
	
EndProcedure

&AtServer
Procedure RecalculateGoodsRowsServer(Val RowFilter)
	
	RowsForRecalculate = Object.Goods.FindRows(RowFilter);
	
	StructureOfActions = New Structure;
	
	If RowFilter.Property("Products") Then
		
		FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
		StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
		StructureOfActions.Insert("CheckCharacteristicsByOwner", Undefined);
		StructureOfActions.Insert("CheckFillPackageByOwner", Undefined);
		
	EndIf;
	
	AddWeightVolumeFillingActions(StructureOfActions);
	StructureOfActions.Insert("RecalculateNumberOfUnits", Undefined);
	StructureOfActions.Insert("RecalculateWeightVolume", Undefined);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(RowsForRecalculate, StructureOfActions, Object.Goods);
	
	For Each RowOfGoods In RowsForRecalculate Do
		
		FillInNetWeightOfUnit(RowOfGoods);
		RecalculateWeightVolumeInCommonUnits(RowOfGoods);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddWeightVolumeFillingActions(StructureOfActions)
	
	StructureOfActions.Insert(
		"FillPackageWeight",
		New Structure("Products, Package", "PackageWeight", Undefined));
	StructureOfActions.Insert(
		"FillPackageVolume",
		New Structure("Products, Package", "PackageVolume", Undefined));
	StructureOfActions.Insert(
		"FillInUnitOfWeight",
		New Structure("Products, Package", "UnitOfMeasureForWeight", Undefined));
	StructureOfActions.Insert(
		"FillInVolumeUnit",
		New Structure("Products, Package", "UnitOfMeasureForVolume", Undefined));
	
EndProcedure

&AtClient
Procedure CalculateTotalsWeightVolume()
	
	UpdateTotals(Object.Goods, WeightTotal, NetWeightTotal, VolumeTotal);
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateTotals(Goods, Weight, Net_Weight, VolumeM3)
	
	Weight = Goods.Total("Weight");
	Net_Weight = Goods.Total("Net_Weight");
	VolumeM3 = Goods.Total("VolumeM3");
	
EndProcedure

#EndRegion

#Region StandardSubsystems_Properties

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
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

#Region StandardSubsystems_PlugInCommands

// StandardSubsystems.AttachableCommands

// Parameters:
//  ExecutionParameters - Structure -
//  AdditionalParameters - Structure -
//
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

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
