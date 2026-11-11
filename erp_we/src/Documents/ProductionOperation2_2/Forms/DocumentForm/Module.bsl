
#Region Variables

&AtClient
Var CachedValues, CurDataId;

&AtClient
Var ParametersForRecording Export;

&AtClient
Var StatusBeforeChange;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.MaterialsAndWorks);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.ManufacturedProducts);
		
	EndIf;
	
	WorkCenterBeforeChange = Object.WorkCenter;
	
	DateToCheck = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	
	If UseShiftTasks And ValueIsFilled(Object.ShiftTask) Then
		DateOfShiftTask = Common.ObjectAttributeValue(Object.ShiftTask, "Date");
		DateToCheck = DateOfShiftTask;
	EndIf;
	
	If ValueIsFilled(Object.ExecutionEnd) Then
		DateToCheck = Object.ExecutionEnd;
	EndIf;
	
	AccountingForLaborCostsByEmployees = ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(
		DateToCheck);
	
	#Region UniversalMechanisms
	
	SetAvailabilityOfClipboardCommands(ThisObject, ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	TMCommonUse.CustomizePeripherals(ThisObject, "MaterialsAndWorks_,ManufacturedProducts_");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	#EndRegion

	If Parameters.Property("Status") Then
		Object.Status = Parameters.Status;
		ProcessStatusChangeOnServer();
	EndIf;
	
	If Parameters.Property("CheckWhenOpening") Then 
		CheckFilling();
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(
			ThisObject, SeriesSpecificationParameters[ValueSelected.TSName], ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommands(ThisObject, True);
		
	ElsIf EventName = "Write_ProductionOperation2_2"
		And TypeOf(Parameter) = Type("Structure")
		And Parameter.Property("Ref")
		And Parameter.Ref = Object.Ref Then
		
		CustomNotification = Source = UUID
			Or TypeOf(FormOwner) = Type("ClientApplicationForm") 
			And Source = FormOwner.UUID;
		
		If Not CustomNotification Then
			Read();
		EndIf;
		
	EndIf;
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// Peripherals
	If IsInputAvailable()
		And Not ReadOnly
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
	// Unknown barcodes
	If Not ReadOnly
		And EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5);
		
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement	
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	OutputStandardsForAdditionalBankingDetails();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetailsOfTableParts();
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	OutputStandardsForAdditionalBankingDetails();
	
	If IsMobileClient Then
		TMCommonUseClientServer.AdaptingFormElementsForMobileScreen(
			Items.GroupAdditionalAttributes.ChildItems);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	OperationKey = ProductionManagementClientServer.ProductionOperationKey();
	FillPropertyValues(OperationKey,Object);
	
	NotificationParameter1 = New Structure;
	NotificationParameter1.Insert("Department", Object.Department);
	NotificationParameter1.Insert("OperationKey", OperationKey);
	NotificationParameter1.Insert("Ref", Object.Ref);
	
	If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
		NotificationSource = FormOwner.UUID;
	Else
		NotificationSource = UUID;
	EndIf;
	
	Notify("Write_ProductionOperation2_2", NotificationParameter1, NotificationSource);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StatusStartChoice(Item, ChoiceData, StandardProcessing)
	
	StatusBeforeChange = Object.Status;
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	ConfirmationParameters = ProductionAccountingClient.ConfirmationWhenSettingStatusOfOperation(Object, Object.Status);
	If ConfirmationParameters <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"ConfirmationOfStatusWhenChangingEnd",
			ThisObject,
			ConfirmationParameters);
		
		ShowQueryBox(CallbackDescription,
			ConfirmationParameters.QueryText + " " + NStr("vi = 'Sẽ ghi lại chứng từ hiện tại.';
															|ru = 'Текущий документ будет записан.';
															|en = 'The current document will be saved.'; fa = 'The current document will be saved.';
															|it = 'The current document will be saved.';
															|pl = 'The current document will be saved.';
															|tr = 'Mevcut belge kaydedilecektir.'"),
			ConfirmationParameters.QuestionDialogMode);
		
	Else
		
		ProcessStatusChangeOnServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("PerformerStartChoiceCompletion", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Object.Organization,
		Object.Department,
		Object.Performer,
		DateForDeterminingContractor(),
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure PerformerAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Object.Department, DateForDeterminingContractor());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformerTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Object.Department, DateForDeterminingContractor());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformerOnChange(Item)
	
	ExecutorWhenChangeIsMadeOnServer();
	
EndProcedure

&AtServer
Procedure ExecutorWhenChangeIsMadeOnServer()
	
	FillInAttributesOfControlRights();
	ConfigureDependentFormElements(ThisObject, "Performer,Count");
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	DivisionWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DivisionWhenChangedOnServer()
	
	FillInDetailsForDivision();
	Object.WorkCenter   = Undefined;
	Object.SetupSettings = Undefined;
	FillInAttributesOfWorkCenterFromObject(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "Department,WorkCenterType");
	
EndProcedure

&AtClient
Procedure OperationKindOnChange(Item)
	
	UpdateAdditionalAttributesItems();
	
EndProcedure

&AtClient
Procedure StageOnChange(Item)
	
	Object.Organization = ?(Object.Stage.IsEmpty(), Undefined, Organization(Object.Stage));
	If Not Object.Stage.IsEmpty() Then
		Object.OperationAsOutputReference = OperationAsOutputReference(Object.Stage);
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	OnCurrentPageChange();
	
EndProcedure

&AtClient
Procedure OperationPresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "#OpenRoute" Then 
		
		ShowValue(, Route);
		
	ElsIf FormattedStringURL = "#OpenOperation" Then
		
		ShowValue(, Object.Operation);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WorkCenterTypeOnChange(Item)
	
	FillInWorkCenterOfObjectFromForm(ThisObject);
	FillInAttributesOfWorkCenterFromObject(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "WorkCenterType");
	
EndProcedure

&AtClient
Procedure CountOnChange(Item)
	
	FillInAmountToBeCompleted();
	
	RecalculateExecutionTime();
	
	ConfigureDependentFormElements(ThisObject, "Count");
	
EndProcedure

&AtClient
Procedure WorkCenterOnChange(Item)
	
	FillInWorkCenterOfObjectFromForm(ThisObject);
	If Not WorkCenterBeforeChange = WorkCenter Then
		WorkCenterWhenChangingOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure TimePerPieceOnChange(Item)
	
	RecalculateExecutionTime();
	
EndProcedure

&AtClient
Procedure TimePerPieceUnitOfMeasureOnChange(Item)
	
	RecalculateExecutionTime();
	
EndProcedure

&AtClient
Procedure SetupTimeOnChange(Item)
	
	RecalculateExecutionTime();
	
EndProcedure

&AtClient
Procedure SetupTimeUnitOfMeasureOnChange(Item)
	
	RecalculateExecutionTime();
	
EndProcedure

&AtClient
Procedure SkippableOnChange(Item)
	
	ConfigureStatusSelectionList();
	
EndProcedure

&AtClient
Procedure ExecutionAndControlOfNavigationLinkProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("Mode",                            Var_URL);
	FormParameters.Insert("ProductionOperation",         Object.Ref);
	FormParameters.Insert("Operation",                         Object.Operation);
	FormParameters.Insert("OperationName_",             Object.Description);
	FormParameters.Insert("OperationID",            Object.OperationID);
	FormParameters.Insert("OperationAsOutputReference", Object.OperationAsOutputReference);
	FormParameters.Insert("BasedOnMasterData",                   Object.BasedOnMasterData);
	FormParameters.Insert("UseShiftTasks",       UseShiftTasks);
	FormParameters.Insert("UnitOfMeasurePresentation",    UnitOfMeasurePresentation);
	
	FormParameters.Insert("Stage",           Object.Stage);
	FormParameters.Insert("Department",  Object.Department);
	FormParameters.Insert("ProductionArea",        Object.ProductionArea);
	FormParameters.Insert("Performer",    Object.Performer);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Mode", Var_URL);
	
	If Var_URL = "To_Control" Then
		FormParameters.Insert("FollowUp", Object.FollowUp);
		NameOfFormToOpen_ = "Document.ProductionOperation2_2.Form.OperationControl";
	ElsIf Var_URL = "OnControl" Then
		FormParameters.Insert("QuantityToPerform", Object.QuantityUnderRevision);
		NameOfFormToOpen_ = "Document.ProductionOperation2_2.Form.PerformingTransaction";
	Else
		FormParameters.Insert("QuantityToPerform", QuantityToPerform);
		NameOfFormToOpen_ = "Document.ProductionOperation2_2.Form.PerformingTransaction";
	EndIf;
	
	Notification = New CallbackDescription("ExecutionAndControlQuantityInputEnd", ThisObject, AdditionalParameters);
	
	OpenForm(NameOfFormToOpen_,
		FormParameters,
		ThisObject,
		UUID,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMaterialsAndWorks

&AtClient
Procedure MaterialsAndWorksOnStartEdit(Item, NewRow, Copy)
	ProcessingOfTabularFormsClient.CacheCurLine(Items.MaterialsAndWorks, ThisObject);
EndProcedure

&AtClient
Procedure MaterialsAndWorksOnEditEnd(Item, NewRow, CancelEdit)
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, Items.MaterialsAndWorks, AdditionalParameters);
	If AdditionalParameters.Property("ServerCallRequired__") Then
		AttachIdleHandler("MaterialsAndWorksAtEndOfEditingForServerCall", 0.5, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksBeforeDeleteRow(Item, Cancel)
	ProcessingOfTabularFormsClient.CacheCurLine(Items.MaterialsAndWorks, ThisObject);
EndProcedure

&AtClient
Procedure MaterialsAndWorksAfterDeleteRow(Item)
	MaterialsAndWorksAfterDeletionOnServer();
EndProcedure

&AtClient
Procedure MaterialsAndWorksProductsOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	WhenChangingProducts(CurrentData, "MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksCharacteristicOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	
	Action = New Structure("FormName, TabularSectionName", FormName, "MaterialsAndWorks");
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", Action);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	WhenChangingNumberOfPackages(CurrentData, "MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksPackageOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	WhenChangingPackaging(CurrentData, "MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) = Type("String")
		And IsTempStorageURL(ValueSelected) Then
		
		ProcessSelectionOfMaterialsByStage(ValueSelected);
		
	Else
		
		ProcessSelectionOfProducts(ValueSelected, "MaterialsAndWorks");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSeriesOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = CurrentData.Series;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters.MaterialsAndWorks, ValueSelected);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("MaterialsAndWorks", Item.EditText);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersManufacturedProducts

&AtClient
Procedure ManufacturedProductsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	If (Field = Items.ManufacturedProductsSeries 
			Or Field = Items.ManufacturedProductsBatchesIndicationStatus)
		And CurrentData.BatchesIndicationStatus > 0
		And CurrentData.BatchesIndicationStatus <= 11 Then
		OpenSelectionOfSeries("ManufacturedProducts");
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,CachedValues,SeriesSpecificationParameters.ManufacturedProducts);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsOnStartEdit(Item, NewRow, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item, CachedValues, SeriesSpecificationParameters.ManufacturedProducts, Copy);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsOnEditEnd(Item, NewRow, CancelEdit)
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters.ManufacturedProducts) Then
		
		CurrentData = Items.ManufacturedProducts.CurrentData;
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS("ManufacturedProducts", IDCurrentRow, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters.ManufacturedProducts);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProcessSelectionOfProducts(ValueSelected, "ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsAfterDeleteRow(Item)
	
	AfterRemovingTSRowsForWhichThereIsSeries("ManufacturedProducts", Item);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsProductsOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	WhenChangingProducts(CurrentData, "ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsCharacteristicOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	StructureOfActions = New Structure;
	
	Action = New Structure("FormName, TabularSectionName", FormName, "ManufacturedProducts");
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", Action);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	WhenChangingNumberOfPackages(CurrentData, "ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsPackageOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	WhenChangingPackaging(CurrentData, "ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.ManufacturedProducts.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.ManufacturedProducts.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters.ManufacturedProducts, ValueSelected);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("ManufacturedProducts", Item.EditText);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLaborCosts

&AtClient
Procedure LaborCostsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	If Copy Then
		CurrentData.RowCode = 0;
	EndIf;
	
	ProductionManagementClientServer.SetArtistType(
		CurrentData.Performer,
		UseTeamWorkOrders,
		AccountingForLaborCostsByEmployees);
	
EndProcedure

&AtClient
Procedure LaborCostsPerformerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	CallbackDescription = New CallbackDescription("LaborCostsPerformerStartChoiceCompletion", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Object.Organization,
		Object.Department,
		CurrentData.Performer,
		DateForDeterminingContractor(),
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure LaborCostsPerformerAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Object.Department, DateForDeterminingContractor());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsPerformerTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(ChoiceData, Text, Object.Department, DateForDeterminingContractor());
		
	EndIf;
	
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

#Region TabularPart_MaterialsAndWorks

&AtClient
Procedure MaterialsAndWorksInsertLines_3(Command)
	
	GetLinesFromClipboard("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksCopyLines_3(Command)
	
	CopyTSLines("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorks_SplitLine(Command)
	
	BreakTSString("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksBarcodeSearch(Command)
	
	SearchByBarcode();
	
EndProcedure

&AtClient
Procedure MaterialsAndWorks_ImportDataFromPDT(Command)
	
	ImportDataFromPDT();
	
EndProcedure

&AtClient
Procedure MaterialsAndWorks_GetWeight(Command)
	
	GetWeight("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksPickUpMaterials(Command)
	
	OpensGoodsSelection("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSelectMaterialsByStage(Command)
	
	PickingParameters = New Structure;
	PickingParameters.Insert("Stage", Object.Stage);
	
	OpenForm(
		"Document.ProductionOperation2_2.Form.SelectMaterialsFromStage",
		PickingParameters,
		Items.MaterialsAndWorks);
	
EndProcedure

#EndRegion

#Region TablePart_OutputProducts

&AtClient
Procedure OutputProductsSpecifyTheSeries_3(Command)
	
	OpenSelectionOfSeries("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProducts_GetWeight(Command)
	
	GetWeight("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProducts_PickUpProducts(Command)
	
	OpensGoodsSelection("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProducts_InsertRows(Command)
	
	GetLinesFromClipboard("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProducts_CopyLines(Command)
	
	CopyTSLines("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure OutputItemsSplitLine_3(Command)
	
	BreakTSString("ManufacturedProducts");
	
EndProcedure

#EndRegion

#Region TablePart_LaborCosts

&AtClient
Procedure LaborCostsInsertLines(Command)
	
	GetLinesFromClipboard("LaborCosts");
	
EndProcedure

&AtClient
Procedure TheEffortToCopyRows(Command)
	
	CopyTSLines("LaborCosts");
	
EndProcedure

&AtClient
Procedure TheEffortToSplitTheString(Command)
	
	BreakTSString("LaborCosts");
	
EndProcedure

#EndRegion

#Region AttachableCommands

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region Other

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure FillInStandards_(Command)
	
	FillInServerOperationStandards();
	
	ShowUserNotification(
		NStr("vi = 'Đã thực hiện điền';
			|ru = 'Заполнение выполнено';
			|en = 'Filled in successfully'; fa = 'Filled in successfully';
			|it = 'Task eseguito';
			|pl = 'Wypełnienie wykonano';
			|tr = 'Doldurma gerçekleşti'"),
		GetURL(Route),
		TextIsFilledInAccordingToStandards(ThisObject),
		PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure ExecutionProtocol(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Title",      StrTemplate(NStr("vi = '%1 ngày %2';
														|ru = '%1 от %2';
														|en = '%1, %2'; fa = '%1, %2';
														|it = '%1 del %2';
														|pl = '%1 z dn. %2';
														|tr = '%2 tarihli %1'"), Object.Number, Format(Object.Date, "DLF=D")));
	FormParameters.Insert("ProductionOperation", Object.Ref);
	FormParameters.Insert("Count",     Object.Count);
	FormParameters.Insert("Control"  ,     Object.Control);
	FormParameters.Insert("Protocol",       Object.Protocol);
	FormParameters.Insert("Operation",       Object.Operation);
	FormParameters.Insert("ReadOnly", ReadOnly Or Not RightToControlExecutionOfOperations);
	
	Notification = New CallbackDescription("ExecutionProtocolCompletion", ThisObject);
	
	OpenForm("Document.ProductionOperation2_2.Form.ProtocolEditor",
		FormParameters,
		ThisObject,
		UUID,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure StartOperation(Command)
	
	Object.Status = PredefinedValue("Enum.ProductionOperationStatuses.Running");
	ProcessStatusChangeOnServer();
	
EndProcedure

&AtClient
Procedure ExecuteOperation(Command)
	
	Object.Status = PredefinedValue("Enum.ProductionOperationStatuses.Executed");
	ProcessStatusChangeOnServer();
	
EndProcedure

&AtClient
Procedure RecordFailureToExecuteOperation(Command)
	
	Object.Status = PredefinedValue("Enum.ProductionOperationStatuses.NotExecuted");
	ProcessStatusChangeOnServer();
	
EndProcedure

// Parameters:
// 	Command - FormCommand -
&AtClient
Procedure PageChange(Command)
	
	Pages = Items.GroupPages;
	
	VisiblePages = New Array();
		
		For Each Page In Pages.ChildItems Do
			If Page.Visible Then
				VisiblePages.Add(Page);
			EndIf;
		EndDo;
	
	CurrentIndex = VisiblePages.Find(Pages.CurrentPage);
	
	If Command.Name = "TabToRight" Then
		CurrentIndex = CurrentIndex + 1;
	Else
		CurrentIndex = CurrentIndex - 1;
	EndIf;
	
	Pages.CurrentPage = VisiblePages.Get(CurrentIndex);
	
	OnCurrentPageChange();
	
EndProcedure

#EndRegion

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

#EndRegion

#Region Private

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	EstablishConditionalAppearanceMaterialsAndWorks();
	SetConditionalAppearanceOfFinishedProduct();
	EstablishConditionalAppearanceOfLaborCosts();
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceMaterialsAndWorks()
	
	EstablishConditionalAppearanceOfCharacteristicsOfMaterialsAndWorks();
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "MaterialsAndWorksProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.MaterialsAndWorks.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisObject,
		"SeriesAlwaysWHGoods",
		"MaterialsAndWorksSeries",
		"Object.MaterialsAndWorks.BatchesIndicationStatus",
		"Object.MaterialsAndWorks.ItemsType");
	
	SetConditionalAppearanceOfRouteMapProducts();
	
	SetConditionalAppearanceOfRouteMapCharacteristics();
	
	SetConditionalAppearanceOfRouteMapPackages();
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceOfCharacteristicsOfMaterialsAndWorks()
	
	FieldName = "MaterialsAndWorksCharacteristic";
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject,
		FieldName,
		"Object.MaterialsAndWorks.ItemVariantsAreUsed");
	
	// The standard conditions of registration must be supplemented with a specific condition
	// that takes into account the presence of the characteristics of the route map.
	
	SupplementConditionalAppearanceOfCharacteristicsOfMaterialsAndWorks(FieldName);
	
EndProcedure

&AtServer
Procedure SupplementConditionalAppearanceOfCharacteristicsOfMaterialsAndWorks(FieldName)
	
	AppearanceItem = Undefined;
	CharacteristicField = Items[FieldName];//FormField - 
	Field = New DataCompositionField(CharacteristicField.Name);
	
	For Each Item In ConditionalAppearance.Items Do
		
		If Item.Fields.Items.Count() > 0
			And Item.Fields.Items[0].Field = Field Then
			
			AppearanceItem = Item;
			Break;
			
		EndIf;
		
	EndDo;
	
	If Not AppearanceItem = Undefined Then
		
		FilterItemsGroup = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		FilterItemsGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
		
		AddConditionsForCreatingRouteMapCharacteristics(FilterItemsGroup);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfRouteMapProducts()
	
	// Text
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.MaterialsAndWorksProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.RouteSheetItems");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("Text",
		New DataCompositionField("Object.MaterialsAndWorks.RouteSheetItemsPresentation"));
	
	// Mark blank
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.MaterialsAndWorksProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.RouteSheetItems");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ProductionOperationStatuses.Executed;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfRouteMapCharacteristics()
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.MaterialsAndWorksCharacteristic.Name);
	
	FilterItemsGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterItemsGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	AddConditionsForCreatingRouteMapCharacteristics(FilterItemsGroup);
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text",
		New DataCompositionField("Object.MaterialsAndWorks.ItemVariantOfRouteSheetPresentation"));
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfRouteMapPackages()
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.MaterialsAndWorksPackage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.Package");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.RouteSheetItems");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("Text",
		New DataCompositionField("Object.MaterialsAndWorks.RouteSheetPackagePresentation"));
	
EndProcedure

&AtServer
Procedure AddConditionsForCreatingRouteMapCharacteristics(FilterItemsGroup)
	
	ItemFilter = FilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterItemsGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.ItemVariantOfRouteSheet");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfFinishedProduct()
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject,
		"ManufacturedProductsCharacteristic",
		"Object.ManufacturedProducts.ItemVariantsAreUsed");
		
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ManufacturedProductsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.ManufacturedProducts.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisObject,
		False,
		"ManufacturedProductsSeries", 
		"Object.ManufacturedProducts.BatchesIndicationStatus", 
		"Object.ManufacturedProducts.ItemsType");
	
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(
		ThisObject,
		False,
		"ManufacturedProductsBatchesIndicationStatus", 
		"Object.ManufacturedProducts.BatchesIndicationStatus");
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceOfLaborCosts()
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.LaborCostsPerformer.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ProductionOperationStatuses.Executed;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.Properties 
&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
	OutputStandardsForAdditionalBankingDetails();
	
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	OutputStandardsForAdditionalBankingDetails();
	
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region SetOfSeries

&AtServer
Procedure ConfigureSeriesUsage()
	
	SeriesParameters_ = ProductsServer.SeriesSpecificationParameters(Object, Documents.ProductionOperation2_2);
	SeriesSpecificationParameters = New FixedStructure(SeriesParameters_);
	
	SetVisibilityOfSeriesElements();
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(TSName, Text = "", CurrentData = Undefined)
	
	NeedServerCall = ProductsClient.YouNeedServerCallToSpecifySeries(
							ThisObject, 
							SeriesSpecificationParameters[TSName], 
							Text, 
							CurrentData);
	
	If NeedServerCall Then
		
		If CurrentData = Undefined Then
			CurDataId = Items[TSName].CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId, TSName);
		AdditionalParameters = New Structure("SeriesSpecificationParameters,ParametersOfSeriesIndicationForm", 
											SeriesSpecificationParameters[TSName], ParametersOfSeriesIndicationForm);
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AdditionalParameters);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName, 
						ParametersOfSeriesIndicationForm, 
						ThisObject,,,,
						CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult <> Undefined Then
		ProcessSeriesIndication_Server(
				AdditionalParameters.SeriesSpecificationParameters, 
				AdditionalParameters.ParametersOfSeriesIndicationForm);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(Val SeriesSpecificationParameters, Val ParametersOfSeriesIndicationForm)
	
	ProductsServer.ProcessSeriesIndication_(
		Object,
		SeriesSpecificationParameters,
		ParametersOfSeriesIndicationForm,
		Undefined);
		
	Documents.ProductionOperation2_2.FillInStatusesForSpecifyingSeries(Object);
	ConfigureSeriesUsage();
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId, TSName)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(
					Object, 
					SeriesSpecificationParameters[TSName], 
					CurDataId, 
					ThisObject);
	
EndFunction

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(TSName, IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
		Object, SeriesSpecificationParameters[TSName], IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer(ListOfTS = Undefined, UpdateParametersForSpecifyingSeries = False)
	
	If UpdateParametersForSpecifyingSeries Then
		ConfigureSeriesUsage();
	EndIf;
	
	If ListOfTS <> Undefined Then
		ArrayTS = StrSplit(ListOfTS, ",");
		For Each TSName In ArrayTS Do
			ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters[TSName]);
		EndDo; 
	Else
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.ManufacturedProducts);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.MaterialsAndWorksSeries.Visible = SeriesSpecificationParameters.MaterialsAndWorks.UseItemsBatch;
	
	SeriesInOutputProducts = SeriesSpecificationParameters.ManufacturedProducts.UseItemsBatch;
	
	Items.ManufacturedProductsSeries.Visible = SeriesInOutputProducts;
	Items.ManufacturedProductsBatchesIndicationStatus.Visible = SeriesInOutputProducts;
	Items.OutputProductsSpecifyTheSeries_3.Visible = SeriesInOutputProducts;
	
EndProcedure

&AtClient
Procedure AfterRemovingTSRowsForWhichThereIsSeries(TSName, Item)

	SeriesStatusesNeedToBeUpdated = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item, CachedValues, SeriesSpecificationParameters[TSName], True);
	
	If SeriesStatusesNeedToBeUpdated Then

		AfterDeletingTSRowsForWhichThereIsSeriesOnServer(TSName, CachedValues); // server call

		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item, CachedValues, SeriesSpecificationParameters[TSName]);
			
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterDeletingTSRowsForWhichThereIsSeriesOnServer(TSName, CachedValues)

	FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(TSName, Undefined, CachedValues);

EndProcedure

#EndRegion

#Region MaterialsAndWorks

&AtClient
Procedure MaterialsAndWorksAtEndOfEditingForServerCall()
	
	MaterialsAndWorksAtEndOfEditingOnServer();
	
EndProcedure

&AtServer
Procedure MaterialsAndWorksAtEndOfEditingOnServer()
	
	FormEvents.WhenChangingElement(ThisObject, "RawMaterials");
	
EndProcedure

&AtServer
Procedure MaterialsAndWorksAfterDeletionOnServer()
	
	FormEvents.WhenChangingElement(ThisObject, "RawMaterials");
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtClient
Procedure CopyTSLines(TSName)

	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items[TSName]) Then
		CopyLinesOnServer(TSName);
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items[TSName].SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtServer
Procedure CopyLinesOnServer(TSName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	
EndProcedure

&AtClient
Procedure GetLinesFromClipboard(TSName)
	
	NumberOfRowsBeforeInsertion = Object[TSName].Count();
	
	GetLinesFromClipboardOnServer(TSName);
	
	NumberOfInserted = Object[TSName].Count() - NumberOfRowsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboardOnServer(TSName)
	
	Var CompositionOfLines, FilterParameters;
	
	SelectGoods = TSName <> "LaborCosts";
	
	If SelectGoods Then
		
		ArrayOfProductTypes = New Array;
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		
		FilterParameters = New Map;
		FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
		
		CompositionOfLines = "Products,Characteristic,Package,NumberOfPackages";
		
	Else
		CompositionOfLines = "WorkKind,Count,Performer";
	EndIf;
	
	LinesFromBuffer = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, CompositionOfLines);
	
	If Not ValueIsFilled(LinesFromBuffer) Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingProducts(TSName, ThisObject, StructureOfActions);
	
	RowsArray = New Array;
	TabularSection = Object[TSName]; // FormDataCollection - 
	RowsToProcess = New Array();
	
	For Each LineFromBuffer In LinesFromBuffer Do
		
		CurrentRow = TabularSection.Add();
		FillPropertyValues(CurrentRow, LineFromBuffer);
		
		If SelectGoods Then
			RowsToProcess.Add(CurrentRow);
		EndIf;
		
		RowsArray.Add(CurrentRow.GetID());
		
	EndDo;
	
	If SelectGoods Then
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			TabularSection);
	EndIf;
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsArray, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfClipboardCommands(Form, AttributeAvailability)
	
	Form.Items.MaterialsAndWorksInsertLines_3.Enabled = AttributeAvailability;
	Form.Items.ContextMenuMaterialsAndWorksInsertLines.Enabled = AttributeAvailability;
	
	Form.Items.ManufacturedProducts_InsertRows.Enabled = AttributeAvailability;
	Form.Items.ContextMenuOutputItemsInsertLines.Enabled = AttributeAvailability;
	
	Form.Items.LaborCostsInsertLines.Enabled = AttributeAvailability;
	Form.Items.ContextMenuLaborCostsInsertLines.Enabled = AttributeAvailability;
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure SearchByBarcode()

	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);

EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	TSName = "MaterialsAndWorks";
	
	StructureOfActionsWithAddedStrings = New Structure;
	AddActionsToStructureWhenChangingProducts(TSName, ThisObject, StructureOfActionsWithAddedStrings);
	AddActionsToStructureCalculateSeriesStatus(TSName, StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.TSName                                  = TSName;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters.MaterialsAndWorks;
	StructureOfActions.ChangeQuantity                     = Not ReadOnly;
	StructureOfActions.OnlyGoodsAndWork                    = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("Attachable_OpenSeriesSelectionWhenScanningProductBarCode_MaterialsAndWorks", 0.1, True);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.MaterialsAndWorks.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
	FormEvents.WhenChangingElement(ThisObject, "RawMaterials");
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT()
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, AdditionalParameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_OpenSeriesSelectionWhenScanningProductBarCode_MaterialsAndWorks()

	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.MaterialsAndWorks.FindByID(CurDataId);
	OpenSelectionOfSeries("MaterialsAndWorks",,CurrentData);

EndProcedure

&AtClient
Procedure GetWeight(TSName)
		
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisObject, TSName);
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(
		New CallbackDescription("GetWeightCompletion", ThisObject, New Structure("CurrentRow,TSName", CurrentRow, TSName)),
		UUID);
	
EndProcedure

// Parameters:
// 	ExecutionResult - Structure - Where:
//  * Result - Boolean - 
//  * ErrorDescription - String, Undefined -
//  * DeviceID - CatalogRef.Peripherals, Undefined -
// 	AdditionalParameters - Structure - Where:
// * CurrentRow -  FormDataStructure, FormDataCollectionItem, FormDataTreeItem -
// * TSName - String - 
&AtClient
Procedure GetWeightCompletion(ExecutionResult, AdditionalParameters) Export
	
	If ExecutionResult.Result Then
		
		AdditionalParameters.CurrentRow.NumberOfPackages = ExecutionResult.Weight;
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(AdditionalParameters.CurrentRow, StructureOfActions, CachedValues);
		
		If AdditionalParameters.TSName = "ManufacturedProducts" Then
			IDCurrentRow = AdditionalParameters.CurrentRow.GetID();
			FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
					AdditionalParameters.TSName, 
					IDCurrentRow, 
					CachedValues);
		EndIf; 
		
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

#EndRegion

#Region OtherUniversalMechanisms

&AtClient
Procedure AddActionsToStructureCalculateSeriesStatus(TSName, StructureOfActions)
	
	SeriesVerificationParameters = New Structure;
	SeriesVerificationParameters.Insert("Warehouse", Object.Department);
	SeriesVerificationParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters[TSName]);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingProducts(TSName, Form, StructureOfActions)

	If Not StructureOfActions.Property("CheckSeriesCalculateStatus")
		And TSName = "ManufacturedProducts" Then
		
		SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters");
		SeriesVerificationParameters.SeriesSpecificationParameters = Form.SeriesSpecificationParameters[TSName];
		SeriesVerificationParameters.Warehouse = Undefined;
		StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
		
	EndIf;
	
	If TSName = "MaterialsAndWorks" Then
		BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
			Form, "Products", StructureOfActions);
	EndIf;
	
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillPackageByOwner");
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	Action = New Structure("FormName, TabularSectionName", Form.FormName, TSName);
	StructureOfActions.Insert("ProductsOnChangeOverridable", Action);
	
EndProcedure

// This procedure should be used if the rows were added programmatically (not interactively), for example, when pasting from a buffer.
// The procedure performs actions that depend on the data in the rows.
//
&AtServer
Procedure AfterChangingTSStringsProgrammaticallyOnServer(TSName, ArrayOfRowIDs_ = Undefined, StructureOfPreviouslyPerformedActions = Undefined)
	
	RowsArray = Undefined;
	RowsCollection = Object[TSName];
	If ArrayOfRowIDs_ <> Undefined Then
		RowsArray = New Array;
		For Each RowID In ArrayOfRowIDs_ Do
			RowsArray.Add(Object[TSName].FindByID(RowID));
		EndDo; 
		RowsCollection = RowsArray;
	EndIf;
	
	If StructureOfPreviouslyPerformedActions = Undefined Then
		StructureOfPreviouslyPerformedActions = New Structure;
	EndIf;
	
	If (TSName = "MaterialsAndWorks" Or TSName = "ManufacturedProducts")
		And Not StructureOfPreviouslyPerformedActions.Property("CheckSeriesCalculateStatus") Then
		FillInStatusesForSpecifyingSeriesServer(TSName);
	EndIf; 
	
	If Not StructureOfPreviouslyPerformedActions.Property("FillInFeatureAttribute")
		Or Not StructureOfPreviouslyPerformedActions.Property("FillInArticleAttribute")
		Or Not StructureOfPreviouslyPerformedActions.Property("FillInProductTypeAttribute_") Then
		
		FillInServiceDetailsOfTableParts(TSName, RowsArray);
		
	EndIf;
	
	If TSName = "MaterialsAndWorks" Then
		FormEvents.WhenChangingElement(ThisObject, "RawMaterials");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTableParts(ListOfTS = "", FillInLines = Undefined)
	
	StructureOfTS = New Structure(ListOfTS);
	AllTS = (StructureOfTS.Count() = 0);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
		
	StructureOfActions.Insert("FillInArticleAttribute",
		New Structure("Products", "SKU"));
		
	StructureOfActions.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
		
	If StructureOfTS.Property("ManufacturedProducts") Or AllTS Then
		
		ProductsServer.FillInServiceDetailsForProductInCollection(
			Object.ManufacturedProducts,
			StructureOfActions,
			FillInLines);
		
	EndIf;
	
	If StructureOfTS.Property("MaterialsAndWorks") Or AllTS Then
		
		BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
			ThisObject, "Products", StructureOfActions);
		ProductsServer.FillInServiceDetailsForProductInCollection(
			Object.MaterialsAndWorks,
			StructureOfActions,
			FillInLines);
		
		FillInServiceDetailsForRouteMapProducts();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForRouteMapProducts()
	
	Query = New Query(
	"SELECT
	|	Table.LineNumber,
	|	Table.RouteSheetItems,
	|	Table.ItemVariantOfRouteSheet,
	|	Table.RouteSheetPackage
	|INTO TTTable
	|FROM
	|	&Table AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTable.LineNumber,
	|	ISNULL(Products.Presentation, """") AS ProductsPresentation,
	|	ISNULL(ItemsCharacteristics.Presentation, """") AS CharacteristicPresentation,
	|	CASE
	|		WHEN NOT PackagesAndUnitsOfMeasure.Ref IS NULL
	|			THEN PackagesAndUnitsOfMeasure.Presentation
	|		WHEN NOT Products.Ref IS NULL
	|			THEN Products.UnitOfMeasure.Presentation
	|		ELSE """"
	|	END AS PackagePresentation
	|FROM
	|	TTTable AS TTTable
	|		LEFT JOIN Catalog.Products AS Products
	|		ON TTTable.RouteSheetItems = Products.Ref
	|		LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		ON TTTable.ItemVariantOfRouteSheet = ItemsCharacteristics.Ref
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON TTTable.RouteSheetPackage = PackagesAndUnitsOfMeasure.Ref
	|WHERE
	|	(TTTable.RouteSheetItems <> &EmptyItemList
	|			OR TTTable.ItemVariantOfRouteSheet <> &EmptyCharacteristic)");
	
	TableColumns1 = "LineNumber, RouteSheetItems, ItemVariantOfRouteSheet, RouteSheetPackage";
	Table = Object.MaterialsAndWorks.Unload(, TableColumns1);
	
	Query.SetParameter("Table", Table);
	Query.SetParameter("EmptyItemList", Catalogs.Products.EmptyRef());
	Query.SetParameter("EmptyCharacteristic", Catalogs.ItemsCharacteristics.EmptyRef());
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		String = Object.MaterialsAndWorks[Selection.LineNumber - 1];
		
		String.RouteSheetItemsPresentation = ?(
			ValueIsFilled(Selection.ProductsPresentation),
			"<" + Selection.ProductsPresentation + ">",
			"");
			
		String.ItemVariantOfRouteSheetPresentation = ?(
			ValueIsFilled(Selection.CharacteristicPresentation),
			"<" + Selection.CharacteristicPresentation + ">",
			"");
		
		String.RouteSheetPackagePresentation = ?(
			ValueIsFilled(Selection.PackagePresentation),
			"<" + Selection.PackagePresentation + ">",
			"");
		
	EndDo;
	
EndProcedure

&AtClient
Procedure WhenChangingProducts(LineOfATabularSection, TSName)
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureCalculateSeriesStatus(TSName, StructureOfActions);
	
	AddActionsToStructureWhenChangingProducts(TSName, ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(LineOfATabularSection, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure WhenChangingNumberOfPackages(LineOfATabularSection, TSName)

	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(LineOfATabularSection, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure WhenChangingPackaging(LineOfATabularSection, TSName)

	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(LineOfATabularSection, StructureOfActions, CachedValues);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
EndProcedure

&AtClient
Procedure OpensGoodsSelection(TSName)

	FormParameters = New Structure;
	FormParameters.Insert("CloseOnChoice", False);
	
	ArrayOfProductTypes = New Array();
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	
	AvailableProductTypes = New FixedArray(ArrayOfProductTypes);
	FormParameters.Insert("Filter", New Structure("ItemsType", AvailableProductTypes));
	
	OpenForm("Catalog.Products.Form.ChoiceForm", 
			FormParameters, 
			Items[TSName], 
			UUID,,,, 
			FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure ProcessSelectionOfProducts(ValueSelected, TSName)
	
	If TypeOf(ValueSelected) = Type("Array") Then
		GoodsList = ValueSelected;
	Else
		GoodsList = New Array;
		GoodsList.Add(ValueSelected);
	EndIf;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingProducts(
			TSName,
			ThisObject,
			StructureOfActions);
			
	RowsArray = New Array;
	RowsToProcess = New Array();
	TabularSection = Object[TSName];//TabularSection - 
	For Each RowOfProduct In GoodsList Do
		CurrentRow = TabularSection.Add();
		CurrentRow.Products = RowOfProduct;
		RowsToProcess.Add(CurrentRow);
		RowsArray.Add(CurrentRow.GetID());
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		TabularSection);

	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsArray, StructureOfActions);
	
EndProcedure

&AtServer
Procedure ProcessSelectionOfMaterialsByStage(ValueSelected)
	
	MaterialList = GetFromTempStorage(ValueSelected);
	
	RowsArray = New Array;
	For Each MaterialString In MaterialList Do
		
		NewRow = Object.MaterialsAndWorks.Add();
		
		FillPropertyValues(NewRow, MaterialString);
		
		RowsArray.Add(NewRow.GetID());
		
	EndDo;
	
	AfterChangingTSStringsProgrammaticallyOnServer("MaterialsAndWorks", RowsArray);
	
EndProcedure

#EndRegion

#Region ExecutionAndControl

&AtClientAtServerNoContext
Function GenerateExecutionAndControlCommands(Form, ListOfCommands)
	
	RowsArray = New Array;
	
	For IndexOf = 0 To ListOfCommands.Count()-1 Do
		
		Command = ListOfCommands[IndexOf];
		
		If IndexOf > 0 Then
			RowsArray.Add("  ");
		EndIf;
		
		RowsArray.Add(New FormattedString(
			Command.Presentation,,,,Command.Value));
		
	EndDo;
	
	Return New FormattedString(RowsArray);
	
EndFunction

&AtServer
Procedure ProcessChangesToProtocolRecords()
	
	FillInAmountToBeCompleted();
	
	RecalculateExecutionTimeAtServer();
	
EndProcedure

&AtServer
Procedure FillInAmountToBeCompleted()
	
	QuantityToPerform = ProductionAccountingClientServer.QuantityToPerform(Object);
	
EndProcedure

&AtClient
Procedure ExecutionAndControlQuantityInputEnd(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	ExecutionAndControlOfQuantityInputEndATServer(Result, AdditionalParameters);
	
	If AdditionalParameters.Mode = "To_Control"
		And RightToControlExecutionOfOperations
		And Not Result.RecalculateStandards
		And ReadOnly Then
			
		If WriteDocumentOnServer() Then
			
			NotifyChanged(Object.Ref);
			NotifyChanged(Type("DocumentRef.ProductionOperation2_2"));
			
		EndIf;
		
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "Status,Count");
	
EndProcedure

&AtServer
Procedure ExecutionAndControlOfQuantityInputEndATServer(Result, AdditionalParameters)
	
	ResultsBeforeChange = ProductionAccountingClientServer.StructureOfResultsConstructor(Object);
	
	Protocol_AddRecords(Result.ProtocolEntries);
	
	Documents.ProductionOperation2_2.CalculateStatusWhenAttributesAreChanged(Object);
	
	ConfigureSeriesUsage();
	
	If Result.RecalculateStandards Then
		
		If Object.BasedOnMasterData Then
		
			FillInServerOperationStandards(True, True);
			
		Else
			
			RecalculateResourcesOfOperationAtServer(ResultsBeforeChange);
			
		EndIf;
		
	EndIf;
	
	ProcessChangesToProtocolRecords();
	
	Modified = True;
	
EndProcedure

&AtServer
Procedure Protocol_AddRecords(ProtocolEntries)
	
	If Not ValueIsFilled(ProtocolEntries) Then
		Return;
	EndIf;
	
	RecordsArray = TMCommonUseClientServer.Array(ProtocolEntries);
	
	For IndexOf = 0 To RecordsArray.UBound() Do
		Documents.ProductionOperation2_2.AddProtocolEntry(Object, RecordsArray[IndexOf]);
	EndDo;
	
EndProcedure

&AtClient
Procedure ExecutionProtocolCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	EditEndProtocolOnServer(Result);
		
	If RightToControlExecutionOfOperations
		And Not Result.RecalculateStandards
		And ReadOnly Then
			
		If WriteDocumentOnServer() Then
			
			NotifyChanged(Object.Ref);
			NotifyChanged(Type("DocumentRef.ProductionOperation2_2"));
			
		EndIf;
		
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "Status,Count");
	
EndProcedure

&AtServer
Procedure EditEndProtocolOnServer(Result)
	
	ResultsBeforeChange = ProductionAccountingClientServer.StructureOfResultsConstructor(Object);
	
	Object.Protocol.Load(Result.Protocol.Unload());
	
	Documents.ProductionOperation2_2.RecalcTotals(Object);
	
	Documents.ProductionOperation2_2.CalculateStatusWhenAttributesAreChanged(Object);
	
	ConfigureSeriesUsage();
	
	If Result.RecalculateStandards Then
		
		If Object.BasedOnMasterData Then
			
			FillInServerOperationStandards(True, True);
			
		Else
			
			RecalculateResourcesOfOperationAtServer(ResultsBeforeChange);
			
		EndIf;
		
	EndIf;
	
	ProcessChangesToProtocolRecords();
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	IsMobileClient = Common.IsMobileClient();
	
	UsePlanningIntervalHour = Constants.UsePlanningIntervalHour.Get();
	UseOperationExecutionControl = GetFunctionalOption("UseOperationExecutionControl");
	
	FillInAttributesOfControlRights();
	FillInTransactionDetails();
	FillInStageDetails();
	FillInDetailsForDivision();
	FillInAttributesOfWorkCenterFromObject(ThisObject);
	FillInServiceDetailsOfTableParts();
	
	FillInAmountToBeCompleted();
	
	CustomizeFormElements();
	ConfigureDependentFormElements(ThisObject);
	ConfigureSeriesUsage();
	ProcessingOfTabularForms.InitializeRowCache(Items.MaterialsAndWorks);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	If Object.BasedOnMasterData Then
		
		TransactionDetails = Common.ObjectAttributesValues(
			Object.Operation, "Owner, Presentation, UnitOfMeasure.Presentation");
		
		RouteDetails = Catalogs.ManufacturingOperations.DetailsOfOperationRoute(TransactionDetails.Owner);
		
		Route = RouteDetails.Route;
		
		OpenRoute = New FormattedString(
			String(Route),
			,
			,
			,
			?(RouteDetails.RouteAvailable,"#OpenRoute",""));
		
		OpenOperation = New FormattedString(
			TransactionDetails.Presentation,
			,
			,
			,
			"#OpenOperation");
		
		OperationPresentation = New FormattedString(
			OpenRoute, ", ", OpenOperation);
		
		If Not UnitOfMeasureCalculate Then
			UnitOfMeasurePresentation            = TransactionDetails.UnitOfMeasurePresentation;
			UnitOfMeasurementSubmissionToExecution = TransactionDetails.UnitOfMeasurePresentation;
			UnitOfMeasurementPerformanceOnControl  = TransactionDetails.UnitOfMeasurePresentation;
			UnitOfMeasurementRepresentationUnderRevision = TransactionDetails.UnitOfMeasurePresentation;
			UnitOfMeasurementRepresentationDefectiveGoods        = TransactionDetails.UnitOfMeasurePresentation;
			UnitOfMeasurePresentationCanceled    = TransactionDetails.UnitOfMeasurePresentation;
			UnitOfMeasurementRepresentationFact        = TransactionDetails.UnitOfMeasurePresentation;
		EndIf;
		
		Items.FormFillInStandards_.Visible = True;
		Items.FormFillInStandards_.Title = FillInTextAccordingToStandards(ThisObject);
		
	Else
		
		Items.FormFillInStandards_.Visible = False;
		
		OptionsArray = ProductionAccountingClientServer.ControlOptionsForIndividualOfOperation(Object.Control);
		Items.Control.ListChoiceMode = True;
		Items.Control.ChoiceList.LoadValues(OptionsArray);
		
	EndIf;
	
	UnitElement = Items.Department; // FormFieldExtensionForALabelField 
	ElementStage = Items.Stage; // FormFieldExtensionForALabelField
	If Object.BasedOnMasterData Or Object.IncludedInTechnologicalProcess Then
		UnitElement.Type         = FormFieldType.LabelField;
		UnitElement.Hyperlink = True;
		ElementStage.Type                  = FormFieldType.LabelField;
		ElementStage.Hyperlink          = True;
	Else
		UnitElement.Type = FormFieldType.InputField;
		ElementStage.Type          = FormFieldType.InputField;
	EndIf;
	
	Items.OperationPresentation.Visible             = Object.BasedOnMasterData;
	Items.OperationKind.ReadOnly                  = Object.BasedOnMasterData;
	
	Items.RunTime.SkipOnInput          = Not Object.BasedOnMasterData;
	Items.ExecutionTimeUnitOfMeasure.SkipOnInput     = Not Object.BasedOnMasterData;
	
	Items.GroupNumberOfOperationByNSI.Visible          = Object.BasedOnMasterData;
	Items.GroupNumberOfOperationIndividual.Visible = Not Object.BasedOnMasterData And Object.IncludedInTechnologicalProcess;
	
	//
	
	DataChangesDenied = Not AccessRight("Update", Metadata.Documents.ProductionOperation2_2);
	
	If Not Object.Stage.IsEmpty()
		And Common.ObjectAttributeValue(Object.Stage, "Status") 
			= Enums.StatusesOfProductionStages2_2.Completed Then
			
		DataChangesDenied = True;
		Items.TextInformation.Title = NStr("vi = 'Công đoạn hoàn thành, hoạt động không thể thay đổi.';
											|ru = 'Этап завершен, операция не может быть изменена.';
											|en = 'Stage is completed, the operation can not be changed.'; fa = 'Stage is completed, the operation can not be changed.';
											|it = 'Fase completata, l''operazione non può essere modificata.';
											|pl = 'Etap został zakończony, operacja nie może być zmieniona.';
											|tr = 'Aşama tamamlandı, işlem değiştirilemez.'");
		
	EndIf;
	
	If Not DataChangesDenied
		And Not Object.ShiftTask.IsEmpty()
		And Common.ObjectAttributeValue(Object.ShiftTask, "Status")
			= Enums.ShiftTaskStatuses.Closed Then
		
		DataChangesDenied = True;
		Items.TextInformation.Title = NStr("vi = 'Ca làm việc được đóng lại, giao dịch không thể thay đổi.';
											|ru = 'Сменное задание закрыто, операция не может быть изменена.';
											|en = 'Shift task is closed. The operation cannot be changed.'; fa = 'Shift task is closed. The operation cannot be changed.';
											|it = 'Task di turno chiuso, l''operazione non può essere modificata.';
											|pl = 'Zadanie zmianowe zostało zamknięte, operacja nie może być zmieniona.';
											|tr = 'Vardiyalı görev kapatıldı, işlem değiştirilemez.'");
		
	EndIf;
	
	//
	
	ConfigureStatusSelectionList();
	
	//
	
	ReadOnly                      = DataChangesDenied;
	Items.InformationGroup.Visible = DataChangesDenied And Not IsBlankString(Items.TextInformation.Title);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")

	Object = Form.Object;
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	BeingGenerated = Object.Status = PredefinedValue("Enum.ProductionOperationStatuses.BeingGenerated");
	Executed   = Object.Status = PredefinedValue("Enum.ProductionOperationStatuses.Executed");
	NotExecuted = Object.Status = PredefinedValue("Enum.ProductionOperationStatuses.NotExecuted");
	IsSkipped   = Object.Status = PredefinedValue("Enum.ProductionOperationStatuses.IsSkipped");
	
	DisplayFact = Not (NotExecuted Or IsSkipped);
	
	If AttributesStructure1.Property("Status") Or Initialize Then
		
		Items.ExecutionStarted.ReadOnly    = Not Executed;
		Items.ExecutionEnd.ReadOnly = Not Executed;
		
		Items.RepetitionIsRequired.Visible = Executed
			And Object.FollowUp = 0
			And Object.CountReal > 0
			And (Object.Repeatable Or Object.RepetitionIsRequired);
		
		Items.ExecutionStarted.Visible         = DisplayFact;
		Items.ExecutionEnd.Visible      = DisplayFact;
		Items.LaborCostsPage.Visible     = DisplayFact;
		
		Items.GroupNumberOfOperationIndividual.ReadOnly = Not BeingGenerated;
		Items.GroupExecutionAndControl.Visible      = Object.BasedOnMasterData Or Object.IncludedInTechnologicalProcess;
		Items.GroupExecutionAndControl.ReadOnly = Object.BasedOnMasterData Or Not BeingGenerated;
		
		Items.ProductionArea.AutoMarkIncomplete = Not BeingGenerated And Not IsSkipped;
		Items.ShiftTask.AutoMarkIncomplete = Not BeingGenerated;
		If BeingGenerated Then
			Items.ShiftTask.MarkIncomplete = False;
		EndIf;
		If BeingGenerated Or IsSkipped Then
			Items.ProductionArea.MarkIncomplete = False;
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("Department") Or Initialize Then
		
		Items.ShiftTask.Visible = Form.UseShiftTasks;
		
		Form.SetFormFunctionalOptionParameters(New Structure("Department", Object.Department));
		
		ProductionManagementClientServer.SetArtistType(
			Object.Performer,
			Form.UseTeamWorkOrders,
			Form.AccountingForLaborCostsByEmployees);
		
		If Form.UseManufacturingExecutionSystem Then
			Format = "DLF=DT";
		Else
			
			If BegOfMinute(Object.ExecutionStarted) <> Object.ExecutionStarted
			 Or BegOfMinute(Object.ExecutionEnd) <> Object.ExecutionEnd Then
			
				Format = "DF='dd.MM.yyyy HH:mm:ss'";
			
			Else
				
				Format = "DF='dd.MM.yyyy HH:mm'";
				
			EndIf;
			
		EndIf;
		
		Items.ExecutionStarted.EditFormat = Format;
		Items.ExecutionEnd.EditFormat = Format;
		
		Links = New Array;
		Links.Add(New ChoiceParameterLink("Department", "Object.Department")); // To clean up when the division changes
		Links.Add(New ChoiceParameterLink("Filter.WorkCenterType", "WorkCenterType"));
		
		If Form.UseAreas Then
			Links.Add(New ChoiceParameterLink("Filter.ProductionArea", "Object.ProductionArea"));
		EndIf;
		
		Items.WorkCenter.ChoiceParameterLinks = New FixedArray(Links);
		
	EndIf;
	
	If AttributesStructure1.Property("Status")
		Or AttributesStructure1.Property("Department")
		Or Initialize Then
		
		Items.MaterialsAndWorksPage.Visible = DisplayFact And Form.UseMaterials;
		Items.OutputProductsPage.Visible  = DisplayFact And Form.UseFinishedProducts;
		
	EndIf;
	
	If AttributesStructure1.Property("WorkCenterType") Or Initialize Then
		
		Items.SetupSettings.Enabled = Form.UseSetupSettings;
		Items.GroupImport.Visible = Form.ParallelLoad;
		
	EndIf;
	
	If AttributesStructure1.Property("Performer") Or Initialize Then
		
		Items.LaborCostsPerformer.Visible = Not ValueIsFilled(Object.Performer);
		
	EndIf;
	
	If AttributesStructure1.Property("Time") Or Initialize Then
		
		Items.GroupExecutionTime.ReadOnly = ValueIsFilled(Object.TimePerPiece) Or ValueIsFilled(Object.SetupTime);
		
	EndIf;
	
	If AttributesStructure1.Property("Status")
		Or AttributesStructure1.Property("Count")
		Or Initialize Then
		
		UnitsOfMeasurementToBeCalculated = New Structure;
		ListOfCommands = New ValueList();
		
		// Assigned_
		UnitsOfMeasurementToBeCalculated.Insert("UnitOfMeasurePresentation", "Count");
		
		// For execution
		Items.GroupToComplete.Visible = (Form.QuantityToPerform > 0)
			And DisplayFact
			And Not Object.Status = PredefinedValue("Enum.ProductionOperationStatuses.Executed")
			And Not (Object.Status = ProductionAccountingClientServer.InitialStatusOfProductionOfOperation(Object) And Not Object.BasedOnMasterData)
			And Not Form.IsMobileClient;
		If Items.GroupToComplete.Visible Then
			
			UnitsOfMeasurementToBeCalculated.Insert("UnitOfMeasurementSubmissionToExecution", "QuantityToPerform");
				
			If Not Form.ReadOnly Then
				ListOfCommands.Clear();
				ListOfCommands.Add("Perform", NStr("vi = 'Thực hiện';
													|ru = 'Выполнить';
													|en = 'Run'; fa = 'اجرا';
													|it = 'Eseguire';
													|pl = 'Run';
													|tr = 'Gerçekleştir'"));
				If Form.RightToSelfControlOfCompletedOperations
					And Form.UseOperationExecutionControl
					And Object.Control = PredefinedValue("Enum.ManufacturingOperationControlOptions.Required2") Then
					ListOfCommands.Add("ExecuteControl", NStr("vi = 'Thực hiện, kiểm soát';
																|ru = 'Выполнить, проконтролировать';
																|en = 'Execute, monitor'; fa = 'Execute, monitor';
																|it = 'Eseguire, controllare';
																|pl = 'Wykonaj, przekontroluj';
																|tr = 'Gerçekleştir, kontrol altında tut'"));
				EndIf;
				Form.CommandsToExecute = GenerateExecutionAndControlCommands(Form, ListOfCommands);
			EndIf;
			
		EndIf;
		
		// On the control
		Items.GroupIsUnderControl.Visible = (Object.FollowUp > 0)
			And DisplayFact
			And Form.UseOperationExecutionControl;
		If Items.GroupIsUnderControl.Visible Then
			
			UnitsOfMeasurementToBeCalculated.Insert("UnitOfMeasurementPerformanceOnControl", "FollowUp");
				
			If Form.RightToControlExecutionOfOperations Then
				ListOfCommands.Clear();
				ListOfCommands.Add("To_Control", NStr("vi = 'Kiểm soát';
														|ru = 'Проконтролировать';
														|en = 'Monitor'; fa = 'پایش';
														|it = 'Controllare';
														|pl = 'Monitor';
														|tr = 'Kontrol altında tut'"));
				Form.TeamsAreUnderControl = GenerateExecutionAndControlCommands(Form, ListOfCommands);
			EndIf;
			
		EndIf;
		
		// Under revision
		Items.GroupIsBeingFinalized.Visible = (Object.QuantityUnderRevision > 0)
			And DisplayFact
			And Form.UseOperationExecutionControl;
		If Items.GroupIsBeingFinalized.Visible Then
			
			UnitsOfMeasurementToBeCalculated.Insert("UnitOfMeasurementRepresentationUnderRevision", "QuantityUnderRevision");
				
			If Not Form.ReadOnly Then
				ListOfCommands.Clear();
				ListOfCommands.Add("OnControl", NStr("vi = 'Trình để kiểm soát';
													|ru = 'Предъявить к контролю';
													|en = 'Present for control'; fa = 'ارائه برای کنترل';
													|it = 'Presentare per il controllo';
													|pl = 'Zgłoś do kontroli';
													|tr = 'Kontrole sun'"));
				Form.CommandsUnderRevision = GenerateExecutionAndControlCommands(Form, ListOfCommands);
			EndIf;
			
		EndIf;
		
		// DefectiveGoods
		Items.DefectiveGoodsGroup.Visible = (Object.DefectiveGoodsCount > 0)
			And DisplayFact;
		If Items.DefectiveGoodsGroup.Visible Then
			
			UnitsOfMeasurementToBeCalculated.Insert("UnitOfMeasurementRepresentationDefectiveGoods", "DefectiveGoodsCount");
			
		EndIf;
		
		// Canceled
		Items.GroupCanceled.Visible = (Object.CountCanceled > 0);
		If Items.GroupCanceled.Visible Then
			UnitsOfMeasurementToBeCalculated.Insert("UnitOfMeasurePresentationCanceled", "CountCanceled");
		EndIf;
		
		// Real
		Items.GroupFact.Visible = (Object.CountReal > 0)
			And DisplayFact;
		If Items.GroupFact.Visible Then
			
			UnitsOfMeasurementToBeCalculated.Insert("UnitOfMeasurementRepresentationFact", "CountReal");
			
		EndIf;
		
		// Unit
		If Form.UnitOfMeasureCalculate Then
			For Each KeyAndValue In UnitsOfMeasurementToBeCalculated Do
				Form[KeyAndValue.Key] = ProductionManagementClientServer.PresentationOfUnitOfOperation(
					Undefined,
					?(Object.Property(KeyAndValue.Value), Object[KeyAndValue.Value], Form[KeyAndValue.Value]));
			EndDo;
		EndIf;
		
		If Not Object.BasedOnMasterData Then
			If Object.Protocol.Count() = 0
				And Object.Status = ProductionAccountingClientServer.InitialStatusOfProductionOfOperation(Object) Then
				Items.Count.Type = FormFieldType.InputField;
			Else
				Items.Count.Type = FormFieldType.LabelField;
			EndIf;
			Items.Count.Width = 10;
		EndIf;
		
	EndIf;

	If Initialize And Form.IsMobileClient Then
		
		#Region Main
		Items.FormPostAndClose.Representation = ButtonRepresentation.Picture;
		Form.Title = NStr("vi = 'Giao dịch';
							|ru = 'Операция';
							|en = 'Operation'; fa = 'عملیات';
							|it = 'Operazione';
							|pl = 'Operation';
							|tr = 'İşlem'") + " " + Form.Object.Number;
		Form.AutoTitle = False;
		
		Items.Number.Visible               = False;
		Items.Date.Visible                = False;
		
		Items.GroupExecution.Group      = ChildFormItemsGroup.Vertical;
		Items.GroupExecutionTime.Group = ChildFormItemsGroup.AlwaysHorizontal;
		Items.GroupNumberOfOperationByNSI.Group   = ChildFormItemsGroup.Vertical;
		Items.GroupNumberOfOperationIndividual.Group   = ChildFormItemsGroup.Vertical;
		
		Items.ExecutionStarted.ReadOnly    = True;
		Items.ExecutionEnd.ReadOnly = True;
		
		Items.WorkCenterType.Title = NStr("vi = 'Dạng nguồn lực sản xuất';
											|ru = 'Вид РЦ';
											|en = 'Work center type'; fa = 'نوع مرکز کاری';
											|it = 'Tipo dei centri di lavoro';
											|pl = 'Rodzaj CP';
											|tr = 'İM türü'");
		Items.Description.Title      = NStr("vi = 'Để thực hiện';
											|ru = 'Изготовить';
											|en = 'Manufacture'; fa = 'Manufacture';
											|it = 'Fabbricare';
											|pl = 'Manufacture';
											|tr = 'İmal et'");
		Items.RunTime.Title   = NStr("vi = 'Thời gian';
									|ru = 'Время';
									|en = 'Time'; fa = 'زمان';
									|it = 'Ora';
									|pl = 'Time';
									|tr = 'Zaman'") + ", " + Form.Object.ExecutionTimeUnitOfMeasure;
		
		Items.MaterialsAndWorksPage.Title = NStr("vi = 'Chi phí';
												|ru = 'Расход';
												|en = 'Expense'; fa = 'هزینه';
												|it = 'Uscita';
												|pl = 'Expense';
												|tr = 'Gider'");
		Items.OutputProductsPage.Title  = NStr("vi = 'Xuất xưởng';
												|ru = 'Выпуск';
												|en = 'Release'; fa = 'آزادسازی';
												|it = 'Produzione';
												|pl = 'Release';
												|tr = 'İmal edilen ürünler'");
		
		Items.AdditionalPage.Title  = NStr("vi = 'Dạng khác';
											|ru = 'Прочее';
											|en = 'Other'; fa = 'سایر';
											|it = 'Altro';
											|pl = 'Other';
											|tr = 'Diğer'");
		
		Items.Count.Title      = NStr("vi = 'Chỉ định';
										|ru = 'Назначено';
										|en = 'Assigned'; fa = 'تخصیص‌یافته';
										|it = 'Assegnato';
										|pl = 'Assigned';
										|tr = 'Atanan'") + ", " + Form.UnitOfMeasurePresentation;
		Items.CountReal.Title  = NStr("vi = 'Đã thực hiện';
										|ru = 'Выполнено';
										|en = 'Completed'; fa = 'تکمیل‌شده';
										|it = 'Completato';
										|pl = 'Completed';
										|tr = 'Gerçekleştirildi'") + ", " + Form.UnitOfMeasurementRepresentationFact;
		
		Items.ExecutionTimeUnitOfMeasure.Visible              = False;
		Items.UnitOfMeasurePresentation.Visible     = False;
		Items.UnitOfMeasurementRepresentationFact.Visible = False;
		
		OperationInformationGroup = Items.Add("OperationInformationGroup",
														Type("FormGroup"), 
														Items.PageGeneral);
		
		OperationInformationGroup.Type = FormGroupType.UsualGroup;
		OperationInformationGroup.Behavior = UsualGroupBehavior.Collapsible;
		OperationInformationGroup.CollapsedRepresentationTitle  = Form.Object.Description;
		OperationInformationGroup.Title = NStr("vi = 'Thông tin giao dịch';
												|ru = 'Информация об операции';
												|en = 'Operation details'; fa = 'Operation details';
												|it = 'Informazione sull''operazione';
												|pl = 'Informacja o operacji';
												|tr = 'İşlem bilgisi'");
		OperationInformationGroup.Hide();
		
		Items.Move(OperationInformationGroup, Items.PageGeneral, Items.GroupMainLeftRight);
		
		Items.Move(Items.Description,          OperationInformationGroup);
		Items.Move(Items.RunTime,       OperationInformationGroup);
		Items.Move(Items.OperationPresentation, OperationInformationGroup);
		Items.Move(Items.Status,                OperationInformationGroup);
		Items.Move(Items.Stage,                  OperationInformationGroup);
		Items.Move(Items.ShiftTask,        OperationInformationGroup);
		Items.Move(Items.Department,         OperationInformationGroup);
		Items.Move(Items.ProductionArea,               OperationInformationGroup);
		Items.Move(Items.WorkCenterType,     OperationInformationGroup);
		
		#EndRegion
		
		#Region SettingUpTS
		Items.MaterialsAndWorksCopyLines_3.OnlyInAllActions                = True;
		Items.MaterialsAndWorksInsertLines_3.OnlyInAllActions                   = True;
		Items.MaterialsAndWorksBarcodeSearch.OnlyInAllActions                 = True;
		Items.MaterialsAndWorks_ImportDataFromPDT.OnlyInAllActions             = True;
		Items.MaterialsAndWorks_GetWeight.OnlyInAllActions                      = True;
		Items.MaterialsAndWorksPickUpMaterials.OnlyInAllActions               = True;
		Items.MaterialsAndWorksSelectMaterialsByStage.OnlyInAllActions        = True;
		Items.ContextMenuMaterialsAndWorksCopyLines.OnlyInAllActions = True;
		Items.ContextMenuMaterialsAndWorksInsertLines.OnlyInAllActions    = True;
		
		Items.ManufacturedProducts_CopyLines.OnlyInAllActions                 = True;
		Items.ManufacturedProducts_InsertRows.OnlyInAllActions                    = True;
		Items.OutputProductsSpecifyTheSeries_3.OnlyInAllActions                      = True;
		Items.ManufacturedProducts_GetWeight.OnlyInAllActions                       = True;
		Items.ManufacturedProducts_PickUpProducts.OnlyInAllActions                   = True;
		Items.ContextMenuOutputItemsCopyLines.OnlyInAllActions  = True;
		Items.ContextMenuOutputItemsInsertLines.OnlyInAllActions     = True;
		
		Items.TheEffortToCopyRows.OnlyInAllActions                    = True;
		Items.LaborCostsInsertLines.OnlyInAllActions                       = True;
		Items.ContextMenuLaborCostsCopyLines.OnlyInAllActions     = True;
		Items.ContextMenuLaborCostsInsertLines.OnlyInAllActions        = True;
		
		#Region MaterialsAndWorks
		
		Items.MaterialsAndWorksLineNumber.Visible = False;
		Items.MaterialsAndWorksProductsUnitOfMeasure.ShowInHeader = False;
		
		Items.MaterialsAndWorksUnitOfMeasure.ShowTitle = False;
		
		Items.Move(Items.MaterialsAndWorksProducts, Items.MaterialsAndWorks, Items.MaterialsAndWorksSKU);
		Items.Move(Items.MaterialsAndWorksUnitOfMeasure, Items.MaterialsAndWorks, Items.MaterialsAndWorksSKU);
		Items.Move(Items.MaterialsAndWorksNumberOfPackages, Items.MaterialsAndWorks, Items.MaterialsAndWorksUnitOfMeasure);

		Items.MaterialsAndWorksNumberOfPackages.Width = 8;
		Items.MaterialsAndWorksProductsUnitOfMeasure.Width = 2;
		Items.MaterialsAndWorksPackage.Width = 2;

		#EndRegion
		
		#Region ManufacturedProducts
		
		Items.OutputItemsLineNumber.Visible = False;
		Items.ManufacturedProductsProductsUnitOfMeasure.ShowInHeader = False;
		
		Items.FinishedProductsUnitOfMeasure.ShowTitle = False;
		
		Items.Move(Items.ManufacturedProductsProducts, Items.ManufacturedProducts, Items.ManufacturedProductsSKU);
		Items.Move(Items.FinishedProductsUnitOfMeasure, Items.ManufacturedProducts, Items.ManufacturedProductsSKU);
		Items.Move(Items.ManufacturedProductsNumberOfPackages, Items.ManufacturedProducts, Items.FinishedProductsUnitOfMeasure);

		Items.ManufacturedProductsNumberOfPackages.Width = 8;
		Items.ManufacturedProductsProductsUnitOfMeasure.Width = 2;
		Items.ManufacturedProductsPackage.Width = 2;
		
		#EndRegion
		
		#Region LaborCosts
		
		Items.LaborCostsLineNumber.Visible = False;
		GroupQuantity = Items.Add("GroupQuantity", Type("FormGroup"), Items.LaborCosts);
		GroupQuantity.Type = FormGroupType.ColumnGroup;
		GroupQuantity.Group = ColumnsGroup.InCell;
		Items.LaborCostsCount.Width = 8;
		Items.LaborCostsWorkKindUnitOfMeasure.Width = 4;
		
		Items.Move(GroupQuantity, Items.LaborCosts, Items.LaborCostsCount);
		Items.Move(Items.LaborCostsCount, GroupQuantity);
		Items.Move(Items.LaborCostsWorkKindUnitOfMeasure, GroupQuantity);
		
		Items.LaborCostsWorkKindUnitOfMeasure.ShowInHeader = False;
		
		#EndRegion
		
		#EndRegion
		
		#Region Status
		StatusGroup = Items.Add("StatusGroup", Type("FormGroup"));
		Items.Move(StatusGroup, Form, Items.InformationGroup);
		
		StatusGroup.Type = FormGroupType.UsualGroup;
		StatusGroup.Representation = UsualGroupRepresentation.None;
		StatusGroup.Group = ChildFormItemsGroup.AlwaysHorizontal;
		StatusGroup.ChildItemsHorizontalAlign = ItemHorizontalLocation.Center;
		StatusGroup.HorizontalStretch = True;
		
		StartOperation               = Form.Commands.Add("StartOperation");
		ExecuteOperation            = Form.Commands.Add("ExecuteOperation");
		RecordFailureToExecuteOperation = Form.Commands.Add("RecordFailureToExecuteOperation");
		
		StartOperation.Action               = "StartOperation";
		ExecuteOperation.Action            = "ExecuteOperation";
		RecordFailureToExecuteOperation.Action = "RecordFailureToExecuteOperation";
		
		StartOperation.Title               = NStr("vi = 'Bắt đầu';
													|ru = 'Начать';
													|en = 'Start'; fa = 'شروع';
													|it = 'Avvia';
													|pl = 'Start';
													|tr = 'Başlat'");
		ExecuteOperation.Title            = NStr("vi = 'Thực hiện';
												|ru = 'Выполнить';
												|en = 'Run'; fa = 'اجرا';
												|it = 'Eseguire';
												|pl = 'Run';
												|tr = 'Gerçekleştir'");
		RecordFailureToExecuteOperation.Title = NStr("vi = 'Phản ánh chưa thực hiện';
													|ru = 'Отразить невыполнение';
													|en = 'Record failure to execute'; fa = 'ثبت عدم اجرا';
													|it = 'Registrare non eseguito';
													|pl = 'Odzwierciedlić niewykonanie';
													|tr = 'Gerçekleştirilmemeyi yansıt'");
		
		StartOperation.ModifiesStoredData               = True;
		ExecuteOperation.ModifiesStoredData            = True;
		RecordFailureToExecuteOperation.ModifiesStoredData = True;
		
		StartStatus               = Items.Add("ToBegin", Type("FormButton"), StatusGroup);
		StatusExecute            = Items.Add("Execute", Type("FormButton"), StatusGroup);
		StatusReflectNonCompliance = Items.Add("RecordFailureToExecute", Type("FormButton"), StatusGroup);
		
		StartStatus.CommandName               = "StartOperation";
		StatusExecute.CommandName            = "ExecuteOperation";
		StatusReflectNonCompliance.CommandName = "RecordFailureToExecuteOperation";
		
		StartStatus.Type               = FormButtonType.Hyperlink;
		StatusExecute.Type            = FormButtonType.Hyperlink;
		StatusReflectNonCompliance.Type = FormButtonType.Hyperlink;
		
		StartStatus.HorizontalAlignInGroup               = ItemHorizontalLocation.Left;
		StatusExecute.HorizontalAlignInGroup            = ItemHorizontalLocation.Center;
		StatusReflectNonCompliance.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
		
		#EndRegion
		
		#Region SwitchingTabs
		TabGroup= Items.Add("TabGroup", Type("FormGroup"));
		Items.Move(TabGroup, Form, Items.InformationGroup);
		
		TabGroup.Type = FormGroupType.UsualGroup;
		TabGroup.Representation = UsualGroupRepresentation.None;
		TabGroup.Group = ChildFormItemsGroup.AlwaysHorizontal;
		TabGroup.ChildItemsHorizontalAlign = ItemHorizontalLocation.Center;
		TabGroup.HorizontalStretch = True;
		
		TabLeft  = Form.Commands.Add("TabLeft");
		TabToRight = Form.Commands.Add("TabToRight");
		
		TabLeft.Action  = "PageChange";
		TabToRight.Action = "PageChange";
		
		LeftTab   = Items.Add("LeftTab", Type("FormButton"), TabGroup);
		CurrentTab = Items.Add("CurrentTab", Type("FormDecoration"), TabGroup);
		RightTab  = Items.Add("RightTab", Type("FormButton"), TabGroup);
		
		LeftTab.HorizontalAlignInGroup   = ItemHorizontalLocation.Left;
		CurrentTab.HorizontalAlignInGroup = ItemHorizontalLocation.Center;
		RightTab.HorizontalAlignInGroup  = ItemHorizontalLocation.Right;
		
		LeftTab.Width  = 9;
		RightTab.Width = 9;

		LeftTab.CommandName   = "TabLeft";
		RightTab.CommandName  = "TabToRight";
		
		CurrentTab.Type = FormDecorationType.Label;
		
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.Swipe;
		
		#EndRegion
		
		TMCommonUseClientServer.AdaptingFormElementsForMobileScreen(Items);
		
	EndIf;
	
	If Form.IsMobileClient
		And (Initialize 
		Or AttributesStructure1.Property("GroupPages") 
		Or AttributesStructure1.Property("Status")) Then
		
		Pages = Items.GroupPages;
		
		VisiblePages = New Array();//Array of FormGroup - 
		
		For Each Page In Pages.ChildItems Do
			If Page.Visible Then
				VisiblePages.Add(Page);
			EndIf;
		EndDo;
		
		CurrentIndex = VisiblePages.Find(Pages.CurrentPage);
		
		If Not DisplayFact And CurrentIndex = Undefined Then
			CurrentIndex = 0;
			Pages.CurrentPage = VisiblePages[0];
		EndIf;
		
		LeftTab = Items["LeftTab"];
		RightTab = Items["RightTab"];
		CurrentTab = Items["CurrentTab"];
		
		If CurrentIndex = 0 Then
			LeftTab.Title   = " ";
			LeftTab.Enabled = False;
		Else
			
			LeftTab.Enabled = True;
			LeftTab.Title   = VisiblePages.Get(CurrentIndex - 1).Title;
			
		EndIf;
		
		If CurrentIndex = VisiblePages.Count() - 1 Then
			
			RightTab.Title   = " ";
			RightTab.Enabled = False;
			
		Else
			
			RightTab.Enabled = True;
			RightTab.Title   = VisiblePages.Get(CurrentIndex + 1).Title;
			
		EndIf;
		
		CurrentTab.Title = Pages.CurrentPage.Title;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureStatusSelectionList()
	
	Items.Status.ChoiceList.Clear();
	For Each Status In Enums.ProductionOperationStatuses Do
		If (Status = Enums.ProductionOperationStatuses.IsSkipped
					And Not Object.Skippable)
			Or (Status = Enums.ProductionOperationStatuses.BeingGenerated
					And Object.BasedOnMasterData) Then
			Continue;
		EndIf;
		Items.Status.ChoiceList.Add(Status);
	EndDo;
	
EndProcedure

&AtClient
Procedure ConfirmationOfStatusWhenChangingEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Object.Status = StatusBeforeChange;
		Return;
	EndIf;
	
	If AdditionalParameters.EventBeingConfirmed = ProductionAccountingClientServer.Confirmation_CancellationOfIndicators() Then
		
		If QuestionResult = DialogReturnCode.Yes Then
			ProcessStatusChangeOnServer();
		Else
			Object.Status = StatusBeforeChange;
		EndIf;
		
	ElsIf AdditionalParameters.EventBeingConfirmed = ProductionAccountingClientServer.Confirmation_CreatingIndividualOperation() Then
		
		ProcessStatusChangeOnServer();
		If QuestionResult = DialogReturnCode.Yes Then
			OpenForm("Document.ProductionOperation2_2.Form.DocumentForm",
				New Structure("CopyingValue", Object.Ref),
				ThisObject, Object.Ref);
			WriteDocumentOnServer();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessStatusChangeOnServer()
	
	Documents.ProductionOperation2_2.FillInDetailsWhenSettingStatus(Object);
	
	ConfigureSeriesUsage();
	ProcessChangesToProtocolRecords();
	
	ConfigureDependentFormElements(ThisObject, "Status,Count");
	
EndProcedure

&AtServer
Procedure FillInServerOperationStandards(SavePerformers = False, SaveBatches = False)
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillInTransactionStandards(, SavePerformers, SaveBatches);
	
	ValueToFormAttribute(DocumentObject, "Object");
	
	AfterChangingTSStringsProgrammaticallyOnServer("MaterialsAndWorks");
	AfterChangingTSStringsProgrammaticallyOnServer("ManufacturedProducts");
	
EndProcedure

&AtServer
Procedure RecalculateResourcesOfOperationAtServer(ResultsBeforeChange)
	
	DocumentObject = FormAttributeToValue("Object");
	
	DocumentObject.RecalculateResourcesOfIndividualOperation(ResultsBeforeChange);
	
	ValueToFormAttribute(DocumentObject, "Object");
	
	AfterChangingTSStringsProgrammaticallyOnServer("MaterialsAndWorks");
	AfterChangingTSStringsProgrammaticallyOnServer("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure RecalculateExecutionTime()
	
	RecalculateExecutionTimeAtServer();
	
	ConfigureDependentFormElements(ThisObject, "Time");
	
EndProcedure

&AtServer
Procedure RecalculateExecutionTimeAtServer()
	
	Documents.ProductionOperation2_2.RecalculateExecutionTime(Object);
	
EndProcedure

&AtClient
Procedure PerformerStartChoiceCompletion(Result, Var_Parameters) Export
	
	If ValueIsFilled(Result) Then
		
		Object.Performer = Result;
		Modified = True;
		
		ExecutorWhenChangeIsMadeOnServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsPerformerStartChoiceCompletion(Result, Var_Parameters) Export
	
	CurrentData = Items.LaborCosts.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(Result) Then
		
		CurrentData.Performer = Result;
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure PerformerGettingSelectionData(ChoiceData, Text, Department, Date)
	
	ChoiceData = New ValueList;
	FilterParameters = New Structure("Organization, Department, Date");
	FilterParameters.Department = Department;
	FilterParameters.Date = Date;
	ProductionServer.FillInSelectionDataWhenEnteringArtist(ChoiceData, Text, FilterParameters);
	
EndProcedure

&AtServer
Procedure OutputStandardsForAdditionalBankingDetails()
	
	// Checking the possibility of withdrawal of standards
	If Object.Operation.IsEmpty()
		Or Object.OperationKind.IsEmpty()
		Or Not GetFunctionalOption("UseKindsOfSpecificTechnologicalOperations") Then
		Return;
	EndIf;
	
	Standards = Catalogs.ManufacturingOperations.StandardsOfValuesOfAdditionalDetails(Object.Operation);
	If Standards.Count() = 0 Then
		Return;
	EndIf;
	
	ThereIsDescriptionOfDetails = False;
	For Each Attribute In GetAttributes() Do
		
		If Attribute.Name = "PropertiesAdditionalAttributeDetails" Then
			
			TableDescription = FormAttributeToValue("PropertiesAdditionalAttributeDetails");//ValueTable - 
			
			ThereIsDescriptionOfDetails = TableDescription.Columns.Find("Property") <> Undefined
				And TableDescription.Columns.Find("ValueAttributeName") <> Undefined
				And TableDescription.Columns.Find("Description") <> Undefined;
			
			Break;
			
		EndIf;
		
	EndDo;
	If Not ThereIsDescriptionOfDetails Then
		Return;
	EndIf;
	
	// Conclusion of standards
	For Each NormativeStandard In Standards Do
		
		If NormativeStandard.ValueMin = 0 And NormativeStandard.ValueMax = 0 Then
			Continue;
		EndIf;
		
		FoundRows = ThisObject.PropertiesAdditionalAttributeDetails.FindRows(
			New Structure("Property", NormativeStandard.Property));
		
		If FoundRows.Count() = 0 Then
			Continue;
		EndIf;
		
		AttributeDetails = FoundRows[0];
		If AttributeDetails.ValueType.Types().UBound() <> 0
			Or Not AttributeDetails.ValueType.ContainsType(Type("Number")) Then
			Continue;
		EndIf;
		
		FormElementProps = Items.Find(AttributeDetails.ValueAttributeName);
		If FormElementProps = Undefined
			Or Items.Find(AttributeDetails.ValueAttributeName + "_Group") <> Undefined Then
			Continue;
		EndIf;
		
		// Adding a group
		GroupFormElement = Items.Add(
			AttributeDetails.ValueAttributeName + "_Group",
			Type("FormGroup"),
			FormElementProps.Parent);
			
		GroupFormElement.Type = FormGroupType.UsualGroup;
		GroupFormElement.Title = StrTemplate(NStr("vi = '%1 (nhóm)';
													|ru = '%1 (группа)';
													|en = '%1 (group)'; fa = '%1 (group)';
													|it = '%1 (gruppo)';
													|pl = '%1 (grupa)';
													|tr = '%1 (grup)'"), AttributeDetails.Description);
		GroupFormElement.Representation = UsualGroupRepresentation.None;
		GroupFormElement.ShowTitle = False;
		GroupFormElement.Group = ChildFormItemsGroup.AlwaysHorizontal;
		
		Items.Move(GroupFormElement, GroupFormElement.Parent, FormElementProps);
		Items.Move(FormElementProps, GroupFormElement);
		
		// Adding decorations (standard)
		FormElementDecoration = Items.Add(
			AttributeDetails.ValueAttributeName + "_Decoration",
			Type("FormDecoration"),
			GroupFormElement);
			
		FormElementDecoration.Type = FormDecorationType.Label;
		FormElementDecoration.TextColor = New Color(0, 150, 70);
		
		Format = NormativeStandard.Format
			+ ?(StrFind(NormativeStandard.Format, "NZ") = 0,
				?(IsBlankString(NormativeStandard.Format), "NZ=0", "; NZ=0"),
				"");
		
		If NormativeStandard.ValueMax <> 0 Then
			DescriptionOfStandard = StrTemplate(NStr("vi = 'tiêu chuẩn: %1 - %2';
													|ru = 'норматив: %1 - %2';
													|en = 'standard: %1 - %2'; fa = 'standard: %1 - %2';
													|it = 'normativo: %1 - %2';
													|pl = 'standard: %1 - %2';
													|tr = 'standart: %1 - %2'"), 
				Format(NormativeStandard.ValueMin, Format),
				Format(NormativeStandard.ValueMax, Format));
		Else
			DescriptionOfStandard = StrTemplate(NStr("vi = 'tiêu chuẩn: %1';
													|ru = 'норматив: %1';
													|en = 'standard: %1'; fa = 'standard: %1';
													|it = 'normativo: %1';
													|pl = 'standard: %1';
													|tr = 'standart: %1'"),
				Format(NormativeStandard.ValueMin, Format));
		EndIf;
		FormElementDecoration.Title = DescriptionOfStandard;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInTransactionDetails()
	
	If Object.BasedOnMasterData Then
		
		UnitOfMeasure = Common.ObjectAttributeValue(Object.Operation, "UnitOfMeasure");
			
		UnitOfMeasureCalculate = Not ValueIsFilled(UnitOfMeasure);
		
	Else
		
		UnitOfMeasureCalculate = True;
		
		If Not ValueIsFilled(Object.Ref) Then
			Object.Status = ProductionAccountingClientServer.InitialStatusOfProductionOfOperation(Object);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInStageDetails()
	
	If Object.BasedOnMasterData Then
		
		BillOfMaterials = Common.ObjectAttributeValue(Object.Stage, "BillOfMaterials");
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInWorkCenterOfObjectFromForm(Form)
	
	If ValueIsFilled(Form.WorkCenter) Then
		Form.Object.WorkCenter = Form.WorkCenter;
	Else
		Form.Object.WorkCenter = Form.WorkCenterType;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInAttributesOfWorkCenterFromObject(Form)
	
	If ValueIsFilled(Form.Object.WorkCenter) Then
		AttributesValues = AttributesOfWorkCenterATServer(Form.Object.WorkCenter);
		FillPropertyValues(Form, AttributesValues);
	Else
		AttributesValues = ProductionAccountingClientServer.AttributesOfWorkCenterConstructor();
	EndIf;
	FillPropertyValues(Form, AttributesValues);
	
EndProcedure

&AtServerNoContext
Function AttributesOfWorkCenterATServer(WorkCenter)
	
	Return ProductionAccounting.AttributesOfWorkCenter(WorkCenter);
	
EndFunction

&AtServer
Procedure WorkCenterWhenChangingOnServer()
	
	Documents.ProductionOperation2_2.RecalculateExecutionTime(Object, WorkCenterBeforeChange);
	WorkCenterBeforeChange = WorkCenter;
	
EndProcedure

&AtServer
Procedure FillInAttributesOfControlRights()
	
	If Not UseOperationExecutionControl Then
		Return;
	EndIf;
	
	RightToControlExecutionOfOperations = Users.RolesAvailable("OperationExecutionControl");
		
	RightToSelfControlOfCompletedOperations = ProductionAccounting.ThereIsRightOfIndependentControlOfOperation(Object);
	
EndProcedure

&AtServer
Procedure FillInDetailsForDivision()
	
	Settings = Documents.ProductionOperation2_2.AccountingSettings(
		Object.Department, Route);
		
	FillPropertyValues(
		ThisObject,
		Settings,
		"UseMaterials,
		|UseFinishedProducts,
		|UseShiftTasks,
		|UseTeamWorkOrders,
		|UseManufacturingExecutionSystem,
		|UseAreas");
	
EndProcedure

&AtServerNoContext
Function Organization(Stage)
	
	Return Common.ObjectAttributeValue(Stage, "Organization");
	
EndFunction

&AtServerNoContext
Function OperationAsOutputReference(Stage)
	
	Return Common.ObjectAttributeValue(Stage, "OperationAsOutputReference");
	
EndFunction

&AtClient
Procedure OnCurrentPageChange()
	
	ConfigureDependentFormElements(ThisObject, "GroupPages");
	
	// StandardSubsystems.Properties
	If Items.GroupPages.CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
		If IsMobileClient Then
			TMCommonUseClientServer.AdaptingFormElementsForMobileScreen(
				Items.GroupAdditionalAttributes.ChildItems);
		EndIf;
		
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Function WriteDocumentOnServer()
	
	SetPrivilegedMode(True);
	
	Try
		
		Result = Write();
		
	Except
		
		Result = False;
		
		EventLogEvent = NStr("vi = 'Không thể ghi lại giao dịch sản xuất';
							|ru = 'Не удалось записать производственную операцию';
							|en = 'Cannot save the routing operation'; fa = 'Cannot save the routing operation';
							|it = 'Non è stato possibile registrare l''operazione di produzione';
							|pl = 'Nie udało się zapisać operacji produkcyjnej';
							|tr = 'Rota işlemi kaydedilemedi'",
			Common.DefaultLanguageCode());
		
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Error,
			,
			,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

&AtClient
Function DateForDeterminingContractor()
	
	Date = Object.ExecutionEnd;
	If Not ValueIsFilled(Date) And ValueIsFilled(DateOfShiftTask) Then
		Date = DateOfShiftTask;
	ElsIf Not ValueIsFilled(Date) Then
		Date = Object.Date;
	EndIf;
	
	Return Date;
EndFunction

&AtClientAtServerNoContext
Function FillInTextAccordingToStandards(Form)
	
	TextFillingOption = ProductionAccountingClientServer.TextFillingOptionAccordingToStandard(Form.Route);
	
	Return StrTemplate(NStr("vi = 'Điền %1';
							|ru = 'Заполнить %1';
							|en = 'Fill %1'; fa = 'Fill %1';
							|it = 'Заполнить %1';
							|pl = 'Fill %1';
							|tr = 'Doldur %1'"), TextFillingOption);
	
EndFunction

&AtClientAtServerNoContext
Function TextIsFilledInAccordingToStandards(Form)
	
	TextFillingOption = ProductionAccountingClientServer.TextFillingOptionAccordingToStandard(Form.Route);
	
	Return StrTemplate(NStr("vi = 'Đã điền chứng từ %1';
							|ru = 'Документ заполнен %1';
							|en = 'Document is filled %1'; fa = 'Document is filled %1';
							|it = 'Document is filled %1';
							|pl = 'Document is filled %1';
							|tr = 'Belge %1 dolduruldu'"), TextFillingOption);
	
EndFunction

&AtClient
Procedure BreakTSString(TSName)
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	
	If TSName = "LaborCosts" Then
		StringSplittingParameters.Title = NStr("vi = 'Hãy nhập số lượng trong dòng mới';
												|ru = 'Введите количество в новой строке';
												|en = 'Enter quantity in a new line'; fa = 'Enter quantity in a new line';
												|it = 'Inserire la quantità nella nuova riga';
												|pl = 'Wprowadź ilość w nowym wierszu';
												|tr = 'Miktarı yeni satıra gir'");
		StringSplittingParameters.FieldNameQuantity = "Count";
	EndIf;
	StringSplittingParameters.AllowZeroCount = False;
	
	Notification = New CallbackDescription("BreakTSStringCompletion", ThisObject, TSName);
	ProcessingOfTabularFormsClient.SplitRow(Object[TSName], Items[TSName], Notification, StringSplittingParameters);

EndProcedure

&AtClient
Procedure BreakTSStringCompletion(NewRow, TSName) Export 
	
	If NewRow = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items[TSName].CurrentData;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "MaterialsAndWorks" Then
	
		WhenChangingNumberOfPackages(NewRow, TSName);
		WhenChangingNumberOfPackages(CurrentData, TSName);
	
	EndIf;

EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

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
