#Region Variables

&AtClient
Var FormModified; // it is used to work out the form modification change event

&AtClient
Var CachedValues;

&AtClient
Var CurDataId;

&AtClient
Var SecurityCalculationWaitingParameters;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	RecordOfPerformed = Parameters.RecordOfPerformed;
	EmbeddingParameters = Documents.ProductionStage2_2.AvailableRemainingEmbeddingOptions(Object);
	ProvisionInDocumentsServer.AvailableBalancesWhenCreatedOnServer(ThisObject, EmbeddingParameters);
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
		
	If Not ValueIsFilled(Parameters.Key)
		And Not Parameters.FillingValues.Property("HeaderAttributes") Then
		MessageText = NStr("vi = 'Không thể mở trực tiếp biểu mẫu này.';
							|ru = 'Непосредственное открытие этой формы не предусмотрено.';
							|en = 'Application cannot open this form explicitly.'; fa = 'Application cannot open this form explicitly.';
							|it = 'L''apertura diretta di questo modulo non è prevista.';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest przewidziane.';
							|tr = 'Bu formun doğrudan açılması sağlanmamaktadır.'");
		Raise MessageText;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.ManufacturedProducts);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.SideAndIntermediateRelease);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.MaterialsAndWorksConsumption);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.UnusedMaterials);
		
	EndIf;
	
	BeginningOfAccountingOfLaborCostsForEmployees = Date(1,1,1);
	
	// Clipboard
	SetAvailabilityOfClipboardCommands(ThisObject, ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.ProductionStage2_2.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	SetupParameters = Documents.ProductionStage2_2.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	TMCommonUse.CustomizePeripherals(ThisObject, "MaterialsAndWorksConsumption_,UnusedMaterials_,ManufacturedProducts_,SideAndIntermediateRelease_");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	SetVisibilityOfInputCommandsBasedOn_();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("Attachable_WhenChangingModifiabilityOfForm", 1);
	
	If StartWaitingForCalculationOfCollateral Then
		StartWaitingForCalculationOfCollateral();
	EndIf;
	
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
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ProductionStage2_2.Form.DocumentForm.Event.ChoiceProcessing");
	
	If ChoiceSource.FormName = "CommonForm.EnterCostShare" Then
		
		ProcessingInputOfFractionOfCost(CurrentItem.CurrentData, ValueSelected);
		
	ElsIf ChoiceSource.FormName = "DataProcessor.OrderSupplyForecast.Form.Form" Then
		
		AddressOfTheMovementTable = FillInCollateralFromCollateralStateForm(
			ValueSelected.ActionCode,
			ValueSelected.AddressAnalyst,
			ValueSelected.FillParameters);
			
		// Returning the control to the form of processing the security status.
		RunCallback(ValueSelected.Callback, AddressOfTheMovementTable);
		
	ElsIf ChoiceSource.FormName = "Document.EngineeringChangeOrder.Form.SubstitutionOfMaterialsWithAlternativeMaterials" Then
		
		Replace_With_Analogues(ValueSelected.AddressInStorage);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters[ValueSelected.TSName], ValueSelected);
		
		ProductsSeriesRecalculatePrices(, ValueSelected.TSName);
		
		If ValueSelected.TSName = "ManufacturedProducts" 
			And ProductionClient.ItIsNecessaryToCalculatePercentageOfDistributionOfCostsForOutputProducts(
				Items.ManufacturedProducts, 
				CostAllocationParameters, 
				ProcessingOfTabularFormsClientServer.LineCache(Items.ManufacturedProducts, ThisObject)) Then
			
			CalculatePercentageOfCostAllocationForOutputProducts();
			
		EndIf;
		
	ElsIf ChoiceSource.FormName = "DataProcessor.OrderClosureWizard.Form.ClosureForm" Then
		
		AdjustOrderLines(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Catalog.BillsOfMaterials.Form.SelectMaterialsByBOM" Then
		
		StartProcessingSelectionResult(ValueSelected, "SelectMaterialsByBOM");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommands(ThisObject, True);
		
	ElsIf EventName = "Write_SubcontractOrder2_5"
		Or False Then
		
		If TypeOf(Parameter) = Type("Array") And Parameter.Find(Object.Ref) <> Undefined Then
			Read();
		EndIf; 
		
	ElsIf EventName = "ChangingSequenceOfStages"
		And Object.ProductionLot = Parameter Then
		
		Read();
		
	ElsIf EventName = "StageDivision_"
		And Object.Ref = Parameter Then
		
		Read();
		
	EndIf;

	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	BarcodeProcessingIsPossible = Not RecordOfPerformed
									And Not Object.ProductionByThirdParty
									And (Object.Status = StatusStarted()
										Or Object.Status = StatusCompleted_1());
	
	// Peripherals
	If IsInputAvailable()
		And BarcodeProcessingIsPossible
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			BarcodeData_5 = EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter);
			
			If TypeOf(CurrentItem) = Type("FormTable")
				And Items.Pages.CurrentPage = Items.MaterialsAndWorksConsumptionPage Then
				
				TSName = CurrentItem.Name;
				
			Else
				TSName = "MaterialsAndWorksConsumption";
			EndIf;
			
			ProcessBarcodes(BarcodeData_5, TSName);
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
	// Unknown barcodes
	If BarcodeProcessingIsPossible
		And EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5, Parameter.TSName);
		
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
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	EmbeddingParameters = Documents.ProductionStage2_2.AvailableRemainingEmbeddingOptions(Object);
	ProvisionInDocumentsServer.AvailableBalancesWhenReadingOnServer(ThisObject, EmbeddingParameters);
	
	OnReadCreateAtServer();

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	If Not Object.StagePlacementInProductionSchedule Then
		
		ProductionProcessEditor.SaveTypesOfWorkCenters(
			WorkCenterTypes, 
			CurrentObject.PlanOperationsOfWorkCenterTypes,
			CurrentObject.WorkCenterTypes,
			CurrentObject.AlternateWorkCenterTypes);
		
	EndIf;
	
	If TheProductionScheduleIsPlanned And Object.StagePlacementInProductionSchedule Then
		CurrentObject.AdditionalProperties.Insert("ProductionSchedule", ProductionSchedule);
	EndIf;
	
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	If CurrentObject.ProductionByThirdParty Then
		// You need to unlock the object
		UnlockFormDataForEdit();
	EndIf; 
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	
	FillInServiceDetailsOfTableParts();
	FillInStateOfOperations();
	FillInAssignmentSelectionParameters();
	
	LabelSpecification = FormattedStringLabelSpecification();
	ConfigureDependentFormElements(ThisObject);
	FillInSelectionListOfProductOwners(ThisObject);
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ProvisionInDocumentsServer.AfterWriteAtServer(ThisObject);
	SetSoftwareVisibility();
	
	StartWaitingForCalculationOfCollateral = ThereAreTasksForCalculatingCollateral(Object.ReferenceOrder,
		Object.SupplyWithMaterialsAndWorks.Unload(New Structure("Canceled", False), "Products")
		.UnloadColumn("Products"));
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	FormModified = Undefined;
	Attachable_WhenChangingModifiabilityOfForm();
	ProvisionInDocumentsClient.AfterWrite(ThisObject, "Attachable_CheckCompletionOfInventoryAllocationTask");
	
	WriteParameters.Insert("Department", Object.Department);
	Notify("Write_ProductionStages", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	If StartWaitingForCalculationOfCollateral Then
		StartWaitingForCalculationOfCollateral();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	#Region ProductionSchedule
	
	ProcessingStagePlacementCheckInSchedule(Cancel);
	
	If MarkPlanNotEarlierThan
		And Not ValueIsFilled(Object.PlanNotEarlierThan) Then
		
		MessageText = NStr("vi = 'Giá trị ""Kế hoạch không sớm hơn"" không được chỉ định.';
							|ru = 'Значение ""Планировать не ранее"" не указано.';
							|en = 'The ""Plan not earlier than"" value is not specified.'; fa = 'The ""Plan not earlier than"" value is not specified.';
							|it = 'Valore ""Non pianificare prima di"" non indicato';
							|pl = 'Wartość ""Planuj nie wcześniej niż"" nie została określona.';
							|tr = '""Öncesinde Olmaksızın Planla"" değeri belirtilmedi.'");
		
		Common.MessageToUser(
			MessageText, 
			Object.Ref,
			?(Object.DynamicStructure, "PlanNoEarlierThanDate", "LabelPlanNotEarlierThan"),
			,
			Cancel);
		
	EndIf;
	
	#EndRegion
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	// Output items - canceling lines
	FinishedProductsHideCanceledLines =  Settings.Get("FinishedProductsHideCanceledLines");
	
	If FinishedProductsHideCanceledLines Then
		Items.ManufacturedProducts.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.ManufacturedProducts.RowFilter = Undefined;
	EndIf;
	
	Items.OutputItemsHideCanceledLines.Check = FinishedProductsHideCanceledLines;
	
	// By-products - cancellation of lines
	SideProductsHideCanceledLines =  Settings.Get("SideProductsHideCanceledLines");
	
	If SideProductsHideCanceledLines Then
		Items.SideAndIntermediateRelease.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.SideAndIntermediateRelease.RowFilter = Undefined;
	EndIf;
	
	Items.SideItemsHideCanceledLines.Check = SideProductsHideCanceledLines;
	
	// Provision of materials and works - cancellation of lines
	FulfillmentHideCanceledLines =  Settings.Get("FulfillmentHideCanceledLines");
	
	If FulfillmentHideCanceledLines Then
		Items.SupplyWithMaterialsAndWorks.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.SupplyWithMaterialsAndWorks.RowFilter = Undefined;
	EndIf;
	
	Items.SoftwareToHideCancelledLines.Check = FulfillmentHideCanceledLines;
	
	// Labor costs - cancellation of lines
	LaborCostsHideCanceledLines =  Settings.Get("LaborCostsHideCanceledLines");
	
	If LaborCostsHideCanceledLines Then
		Items.LaborCosts.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.LaborCosts.RowFilter = Undefined;
	EndIf;
	
	Items.LaborCosts_HideCanceledRows.Check = LaborCostsHideCanceledLines;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Object.BillOfMaterials.IsEmpty() Then
		If ShowStandardsMaterials Then
			ShowStandardsMaterials = False;
		EndIf;
		If ShowStandardsLaborCosts Then
			ShowStandardsLaborCosts = False;
		EndIf;
	EndIf;
	
	AttributesList = "";
	
	If ShowStandardsMaterials Or ShowStandardsLaborCosts Then
		If ShowStandardsMaterials
				And Object.SupplyWithMaterialsAndWorks.Count() > 0
			Or ShowStandardsLaborCosts
				And Object.LaborCosts.Count() > 0 Then
			ShowStandardsWhenChangingOnServer();
		Else
			AttributesList = 
				AttributesList + ?(ValueIsFilled(AttributesList), ",", "") + "ShowStandards";
		EndIf;
	EndIf;
	
	If RightToReadSubstitutes And ShowAnalogues And Not Object.WorkPlanning Then
		
		AttributesList = 
			AttributesList + ?(ValueIsFilled(AttributesList), ",", "") + "ShowAnalogues";
		
		NotePresenceOfAnalogues();
		
	EndIf;
	
	If ValueIsFilled(AttributesList) Then
		ConfigureDependentFormElements(ThisObject, AttributesList);	
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NumberOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "StageName");

EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateOrderForActivity(True);
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	ProcessStatusChangeOnServer();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	DivisionWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure UnitOfMeasureOfStageDurationOnChange(Item)
	
	If Object.UnitOfMeasureOfStageDuration.IsEmpty() Then
		Object.UnitOfMeasureOfStageDuration = TheBasicUnitOfTimeForTheDurationOfTheUBBWStage;
	EndIf; 
	
	ConfigureDependentFormElements(ThisObject, "UnitOfMeasureOfStageDuration");
	
EndProcedure

&AtClient
Procedure NotShipInInstallmentsOnChange(Item)
	
	DoNotShipInPartsWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure DateOfShipmentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	FillInWHDate("SupplyWithMaterialsAndWorks", "DateOfShipment", Object.DateOfShipment);
	If RecordOfPerformed Then
		Object.DateOfMaterialWorkConsumption = Object.DateOfShipment;
		FillInWHDate("MaterialsAndWorksConsumption",  "DateOfMaterialWorkConsumption", Object.DateOfMaterialWorkConsumption);
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "DateOfShipment");
	
EndProcedure

&AtClient
Procedure ProductionInOneDayOnChange(Item)
	
	ProductionByOneDateWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure ProductionDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ProductionDateWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure ConsumptionInOneDayOnChange(Item)
	
	ConsumptionByOneDateWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure DateOfMaterialWorkConsumptionOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfExpenditureWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ProductionStage2_2.Form.DocumentForm.Item.Currency.OnChange");
	
	If PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency, "SideAndIntermediateRelease")
		Or PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency, "ManufacturedProducts")  Then
		CurrencyOnChangeServer();
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	EndIf;
	
	DocumentCurrency = Object.Currency;

	WhenChangingMethodOfDistributionOfCostsForOutputProducts();
	
EndProcedure

&AtClient
Procedure HyperlinkLabelProductsClick(Item)
	
	ProductsCollapsed = Not ProductsCollapsed;
	
	SetPropertiesOfCollapsibleGroup(
		Items.GroupFinishedProducts, 
		Items.HyperlinkLabelProducts, 
		ProductsCollapsed);
	
EndProcedure

&AtClient
Procedure HyperLinkLabelSideProductsClick(Item)
	
	SideProductsAreCollapsed = Not SideProductsAreCollapsed;
	
	SetPropertiesOfCollapsibleGroup(
		Items.GroupByProductsCollapsible, 
		Items.HyperLinkLabelSideProducts, 
		SideProductsAreCollapsed);
		
EndProcedure

&AtClient
Procedure HyperLinkLabelConsumptionOfMaterialsAndWorksClick(Item)
	
	ConsumedMaterialsAreCollapsed = Not ConsumedMaterialsAreCollapsed;
	
	SetPropertiesOfCollapsibleGroup(
		Items.TableSpentMaterials, 
		Items.HyperLinkLabelConsumptionOfMaterialsAndWorks, 
		ConsumedMaterialsAreCollapsed);
	
EndProcedure

&AtClient
Procedure HyperLinkLabelPSavingMaterialsClick(Item)
	
	UnspentMaterialsAreCollapsed = Not UnspentMaterialsAreCollapsed;
	
	SetPropertiesOfCollapsibleGroup(
		Items.UnusedMaterials, 
		Items.HyperLinkLabelPSavingMaterials, 
		UnspentMaterialsAreCollapsed);
	
EndProcedure

&AtClient
Procedure CloseStage(Command)
	
	If Modified Or Not Object.Posted Then
		ShowQueryBox(New CallbackDescription("CloseStageCompletion", ThisObject),
						NStr("vi = 'Cần kết chuyển chứng từ để hoàn thành giao dịch. Kết chuyển chứng từ?';
							|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
							|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
							|it = 'È necessario registrare il documento per eseguire operazione. Registrare documento?';
							|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
							|tr = 'İşlemin gerçekleştirilmesi için belgenin kaydedilmesi gerekmektedir. Belge kaydedilsin mi?'"),QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	CloseStageFragment();
	
EndProcedure

&AtClient
Procedure CloseStageCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	If Response = DialogReturnCode.No Then
		Return;
	ElsIf Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
		Return;
	EndIf;
	
	CloseStageFragment();
	
EndProcedure

&AtClient
Procedure CloseStageFragment()
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ProductionStage2_2.DocumentForm.Command.CloseOrderFragment");
	
	ListOfOrdersToClose = New ValueList;
	ListOfOrdersToClose.Add(Object.Ref);
	
	ClosureStructure = New Structure;
	ClosureStructure.Insert("Orders",                       ListOfOrdersToClose);
	ClosureStructure.Insert("DocumentInitiator",            Object.Ref);
	ClosureStructure.Insert("CancelUnprocessedLines", True);
	ClosureStructure.Insert("CloseOrders",              True);
	
	OpenForm("DataProcessor.OrderClosureWizard.Form.ClosureForm", ClosureStructure,
					ThisObject,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure StartAStage(Command)
	
	If StageExecutionIsStarted Or StageIsCompleted Then
		Return;
	EndIf;

	CallbackDescription = New CallbackDescription("MarkAsStartedContinued", ThisObject, New Structure());

	FormParameters = New Structure();
	FormParameters.Insert("NeedChoiceOfArtist", Not UseOperationManagement);
	FormParameters.Insert("CurrentPerformer", Object.Performer);
	FormParameters.Insert("Department", Object.Department);
	FormParameters.Insert("Organization", Object.Organization);
	OpenForm(
		"Document.ProductionStage2_2.Form.CancelStageFulfillmentStart",
		FormParameters,
		ThisObject,,,,
		CallbackDescription, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MarkAsStartedContinued(ActionParameters, AdditionalParameters) Export
	
	If ActionParameters = Undefined Then
		Return;
	EndIf;
	
	// In the first step, we deal with the provision.  
	// Limitation - the question of removing the "Ship by one date" flag may be asked unnecessarily. It is not taken into account that the unsecured part can be replaced with analogues.

	QuestionAsked = False;
	
	If ActionParameters.FillInSupply Then
	
		Result = ProvidingSetAction(ActionParameters.ActionCode, False);
		
		CommonClientServer.SupplementStructure(Result, ActionParameters);
		
		QuestionAsked = ProvisionInDocumentsClient.ShowIssueOfFillingSoftwareWithWholePackages(
			ThisObject,
			Object.SupplyWithMaterialsAndWorks,
			Result,
			"MarkStartOfExecutionAfterQuestionFillInProvisionWithWholePackagingUnits");
			
		If Not QuestionAsked Then
			
			QuestionAsked = ProvisionInDocumentsClient.ShowQuestionUncheckShipByOneDate(
				ThisObject,
				Object.SupplyWithMaterialsAndWorks,
				Result,
				"MarkStartOfExecutionAfterQuestionUncheckShipByOneDateFlag");
				
		EndIf;

	EndIf;
	
	If Not QuestionAsked Then 
		
		MarkAsStartedCompletion(ActionParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MarkStartOfExecutionAfterQuestionFillInProvisionWithWholePackagingUnits(Response, Result) Export
	
	QuestionAsked = ProvisionInDocumentsClient.ShowQuestionUncheckShipOneDateAfterQuestion(
		ThisObject,
		Object.SupplyWithMaterialsAndWorks,
		Result,
		Response,
		"MarkStartOfExecutionAfterQuestionUncheckShipByOneDateFlag");
		
	If Not QuestionAsked Then
		
		MarkAsStartedCompletion(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MarkStartOfExecutionAfterQuestionUncheckShipByOneDateFlag(Response, Result) Export
	
	MarkStartOfExecutionAfterQuestionsOnFillingOutCollateral(Response, Result);
	
EndProcedure

&AtServer
Procedure MarkStartOfExecutionAfterQuestionsOnFillingOutCollateral(Response, Result)
	
	EnsuringToSetActionAfterQuestion(Response, Result);
	
	MarkAsStartedCompletion(Result);
	
EndProcedure

&AtServer
Procedure MarkAsStartedCompletion(Result)
	
	If Not StageExecutionIsStarted Then
		StageExecutionIsStarted = True;
		ProcessStartOfStageExecution();
	EndIf;
	
	If Result.FillInSupply And Result.Replace_With_Analogues Then
		Replace_With_Analogues(, Result.ActionCodeAnalogs, False);
	EndIf;	
	
	If Result.AssignAssignee Then
		Object.Performer = Result.Performer; // the executor check is not needed, it is performed in the form
	EndIf;
	
EndProcedure

&AtClient
Procedure MethodOfAllocatingFinishedProductCostsOnChange(Item)
	
	WhenChangingMethodOfDistributionOfCostsForOutputProducts();
	
EndProcedure

&AtClient
Procedure WorkPerformanceAsOneDayOnChange(Item)
	
	ExecutionOfWorksByOneDateWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure WorkExecutionDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateWorkWasCompletedWhenItWasChangedOnServer();
	
EndProcedure

&AtClient
Procedure SecurityStatusHyperlinkClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

&AtClient
Procedure HyperlinkSecurityStatusIsBeingShippedClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

&AtClient
Procedure HyperlinkOrderSecurityStatusToTheProcessorClick(Item)

	FormParameters = ProvisionInDocumentsClient.OrderSecurityStateFormParameters("ORDERLIST");
	FormParameters.Orders = CommonClientServer.ValueInArray(Object.SubcontractOrder);
	OpenForm("DataProcessor.OrderSupplyForecast.Form",
		FormParameters,
		ThisObject,
		UUID,
		,
		,
		Undefined,
		FormWindowOpeningMode.Independent);

EndProcedure

&AtClient
Procedure HyperlinkSecurityStatusIssueClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

&AtClient
Procedure HyperlinkStateOfSoftwareDynamicStructureClick(Item)
	
	HyperlinkStateOfProvisionClickGeneral();
	
EndProcedure

&AtClient
Procedure RecordAndProcessClickOfHyperlink(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Write() Then
		HyperlinkStateOfProvisionClickGeneral();
	EndIf; 
	
EndProcedure

&AtClient
Procedure PlanNoEarlierThanDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Object.PlanNotEarlierThan = PlanNoEarlierThanDate;
	Modified = True;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormPageElementsMain

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
		
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure StageNameOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "StageName");
	
EndProcedure

&AtClient
Procedure ProductionMethodOnChange(Item)
	
	HandleChangingProductionMethodOnServer();
	
EndProcedure

&AtClient
Procedure SpecificationStageURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "#ShowStages" Then
		
		ProductionManagementClient.OpenStageChainEditingForm(Object.ReferenceOrder, Object.ProductionLot);
		
	ElsIf FormattedStringURL = "#OpenBillOfMaterials"
		And ValueIsFilled(Object.BillOfMaterials) Then
		
		ShowValue(, Object.BillOfMaterials);
		
	ElsIf FormattedStringURL = "#OpenFirstOperation"
		And ValueIsFilled(FirstOperation) Then
		
		ShowValue(, FirstOperation);
		
	ElsIf FormattedStringURL = "#OpenLastOperation"
		And ValueIsFilled(LastOperation_) Then
		
		ShowValue(, LastOperation_);
		
	ElsIf FormattedStringURL = "#EditTechnicalProcess" Then
		
		If Modified Then
			ShowQueryBox(
				New CallbackDescription("NavigationLinkEditProcessEnd", ThisObject),
				NStr("vi = 'Cần ghi lại chứng từ để thực hiện giao dịch. Ghi lại chứng từ?';
					|ru = 'Необходимо записать документ для выполнения операции. Записать документ?';
					|en = 'You need to save the document before running the operation. Do you want to save it?'; fa = 'You need to save the document before running the operation. Do you want to save it?';
					|it = 'È necessario salvare il documento per eseguire operazione. Salvare il documento?';
					|pl = 'Należy zapisać dokument aby wykonać operację. Zapisać dokument?';
					|tr = 'İşlemin gerçekleştirilmesi için belgenin kaydedilmesi gerekmektedir. Belge kaydedilsin mi?'"),
				QuestionDialogMode.YesNo);
		Else
			OpenProcessEditingForm();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LabelProductURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "#OpenProduct"
		And ValueIsFilled(ProductionBatchData.MainProductProducts) Then
		
		ShowValue(, ProductionBatchData.MainProductProducts);
		
	ElsIf FormattedStringURL = "#OpenProductDescription"
		And ValueIsFilled(ProductionBatchData.MainProductCharacteristic) Then
		
		ShowValue(, ProductionBatchData.MainProductCharacteristic);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodOfProductionClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenManualChartEditingForm();
	
EndProcedure

&AtClient
Procedure PlanningMethodOnChange(Item)
	
	ProcessChangeInSchedulingMethod();
	
EndProcedure

&AtClient
Procedure MarkPlanNotEarlierThanOnChange(Item)
	
	If Not MarkPlanNotEarlierThan Then
		
		Object.PlanNotEarlierThan = Undefined;
		
		If Object.DynamicStructure Then
			PlanNoEarlierThanDate = '00010101';
		Else
			LabelPlanNotEarlierThan = FormattedStringPlanNotEarlier(
				Object.PlanNotEarlierThan,
				ScheduleDateFormat);
		EndIf;
		
	EndIf;
		
	ConfigureDependentFormElements(ThisObject, "MarkPlanNotEarlierThan");
	
EndProcedure

&AtClient
Procedure ActualStageEndOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ProcessStageCompletionDateChange();
	
EndProcedure

&AtClient
Procedure LabelTollingOrderURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	ProductionStage2_2ClientLocalization.LabelTollingOrderURLProcessing(
		ThisObject,
		FormattedStringURL,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure LabelPlanNotEarlierThanURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "#OpenStageToPlanNoEarlier" Then
		
		If ValueIsFilled(Object.PlanNotEarlierThan)
			And TypeOf(Object.PlanNotEarlierThan) = Type("DocumentRef.ProductionStage2_2") Then
			
			ShowValue(, Object.PlanNotEarlierThan);
			
		EndIf;
		
	ElsIf FormattedStringURL = "#EditValue" Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Ref", Object.Ref);
		FormParameters.Insert("ReferenceOrder", Object.ReferenceOrder);
		FormParameters.Insert("PlanNotEarlierThan", Object.PlanNotEarlierThan);
		FormParameters.Insert("ScheduleDateFormat", ScheduleDateFormat);
		
		CallbackDescription = New CallbackDescription(
			"OpenEditFormNoEarlierThanCompletion", 
			ThisObject);
		
		OpenForm(
				"Document.ProductionStage2_2.Form.EditPlanNotEarlierThan", 
				FormParameters, 
				ThisObject,,,, 
				CallbackDescription, 
				FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenEditFormNoEarlierThanCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult <> Undefined Then
		
		Object.PlanNotEarlierThan = ClosingResult;
		
		LabelPlanNotEarlierThan = FormattedStringPlanNotEarlier(
			Object.PlanNotEarlierThan,
			ScheduleDateFormat);
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NumberOfPackagesPlanOnChange(Item)
	
	NumberOfPackagesPlanWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure PackagePlanOnChange(Item)
	
	PackingPlanWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure NumberOfPackagesRealOnChange(Item)
	
	NumberOfPackagesChangedWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure PackageActualDataOnChange(Item)
	
	PackingFactWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure NumberOfPackagesCanceledOnChange(Item)
	
	NumberOfPackagesCancelledWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure PackageCanceledOnChange(Item)
	
	PackagingUndoneWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure InformationIsDefectiveGoodsLabelClick(Item)
	
	Filter = New Structure;
	Filter.Insert("Stage", ThisObject.Object.Ref);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("VariantKey", "ProgressOfStageOperationsContext");
	
	OpenForm("Report.ProductionOperationProgress.Form", FormParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersManufacturedProducts

&AtClient
Procedure ManufacturedProductsOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	If (Field = Items.ManufacturedProductsSeries 
			Or Field = Items.ManufacturedProductsBatchesIndicationStatus)
		And CurrentData.BatchesIndicationStatus > 0
		And CurrentData.BatchesIndicationStatus <= 11 Then
		OpenSelectionOfSeries("ManufacturedProducts");
	EndIf;
	
	If (Field = Items.ManufacturedProductsCostSharePercentage
			Or Field = Items.ManufacturedProductsThereAreErrorsOfFillingInCostShare)
		And Object.MethodOfAllocatingFinishedProductCosts <> PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares") Then
		StandardProcessing = False;
		OpenCostShareEntryForm(CurrentData);
	EndIf;
	
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ManufacturedProducts, ThisObject);
	
	ProductionManagementClient.OutputProductsOfStageAtBeginningOfEditing(
				ThisObject, CurrentData, "ManufacturedProducts", NewRow, Copy); 
	
	If NewRow Then
		
		If RecordOfPerformed Then
			CurrentData.Manufactured = True;
		Else
			CurrentData.Manufactured = False;
		EndIf;
		
		FillInProductionDateInLine(CurrentData);
		
		//Setting up accounting accounts 
		If Copy Then
			GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
		EndIf;
		
		If Not Copy Then
			CurrentData.Department = Object.Department;
		EndIf;
		
	EndIf;
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters.ManufacturedProducts, Copy);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,
		CachedValues,
		SeriesSpecificationParameters.ManufacturedProducts);
	
	CalculatePercentageOfCostAllocation = ProductionClient.ItIsNecessaryToCalculatePercentageOfDistributionOfCostsForOutputProducts(
		Item,
		CostAllocationParameters,
		ProcessingOfTabularFormsClientServer.LineCache(Items.ManufacturedProducts, ThisObject),
		NewRow);
	
	UpdateAppointmentSettings = ProductionSupplyClientServer.ItIsNecessaryToUpdateParametersForFillingAssignmentsWhenChangingProducts(
		Object,
		CurrentData,
		ProcessingOfTabularFormsClientServer.LineCache(Items.ManufacturedProducts, ThisObject));
	
	If UpdateSeriesStatuses
		Or CalculatePercentageOfCostAllocation
		Or UpdateAppointmentSettings Then
			
		OutputItemsAtEndOfEditingOnServer(
			CurrentData.GetID(),
			CachedValues,
			UpdateSeriesStatuses,
			CalculatePercentageOfCostAllocation,
			UpdateAppointmentSettings);
		
	EndIf;
	
	If UpdateSeriesStatuses Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item,
			CachedValues,
			SeriesSpecificationParameters.ManufacturedProducts);
	EndIf;
	
	If NewRow And CancelEdit Then
		ConfigureDependentFormElements(ThisObject, "ManufacturedProducts");
	EndIf;
	
EndProcedure

&AtServer
Procedure OutputItemsAtEndOfEditingOnServer(RowID, CachedValues, UpdateSeriesStatuses, CalculatePercentageOfCostAllocation, UpdateAppointmentSettings)
	
	If UpdateSeriesStatuses Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS("ManufacturedProducts", RowID, CachedValues);
	EndIf;
	
	If CalculatePercentageOfCostAllocation Then
		CalculatePercentageOfCostAllocationForOutputProducts();
	EndIf;
	
	If UpdateAppointmentSettings Then
		FillInAssignmentSelectionParameters();
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters.ManufacturedProducts);

EndProcedure

&AtClient
Procedure ManufacturedProductsAfterDeleteRow(Item)
	
	AfterRemovingTSRowsForWhichThereIsSeries("ManufacturedProducts", Item);
	OutputProductsAfterDeletionOnServer();
	
EndProcedure

&AtServer
Procedure OutputProductsAfterDeletionOnServer()
	
	CalculatePercentageOfCostAllocationForOutputProducts();
	FillInAssignmentSelectionParameters();
	
EndProcedure

&AtClient
Procedure ManufacturedProductsProductsOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	WhenChangingProducts(CurrentData, "ManufacturedProducts");

EndProcedure

&AtClient
Procedure ManufacturedProductsCharacteristicOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	WhenChangingCharacteristics(CurrentData, "ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsPackageOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("RecalculateCostShare", CostAllocationParameters);
	
	If UseTargetCost Then
		
		If CurrentData.Count > 0 Then
			StructureOfActions.Insert("RecalculatePricePerPackage", CurrentData.Count);
		Else
			StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(ThisObject));
		EndIf;
		
		StructureOfActions.Insert("RecalculateAmount");
		
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.ManufacturedProducts.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.ManufacturedProducts.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters.ManufacturedProducts, ValueSelected);
	
	ProductsSeriesRecalculatePrices(, "ManufacturedProducts");

EndProcedure

&AtClient
Procedure ManufacturedProductsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("ManufacturedProducts", Item.EditText);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	WhenChangingNumberOfPackages(CurrentData, "ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsPriceOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	ProductionManagementClient.ProductsOfStagePriceWhenChanging(CurrentData, CachedValues);

EndProcedure

&AtClient
Procedure ManufacturedProductsSumOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	ProductionManagementClient.ItemsOfAmountStageWhenChanged(CurrentData, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsManufacturedOnChange(Item)
	
	WhenFlagIsChangedFollowingIsDone("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsProductionDateOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	StructureOfActions = New Structure;
	AddQualityControlActionsToStructure("ManufacturedProducts", StructureOfActions, CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsDirectionOfProductionIssueOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	WhenChangingDirectionOfRelease(CurrentData, "ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsRecipientOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	WhenChangingRecipient(CurrentData, "ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsToControlQualityOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsQualityConfirmationDateOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsCanceledOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	ItemsCanceledWhenModified("ManufacturedProducts", CurrentData)
	
EndProcedure

&AtClient
Procedure ManufacturedProductsProcessByBOMOnChange(Item)
	
	ProcessBySpecificationWhenModified("ManufacturedProducts", Items.ManufacturedProducts.CurrentData);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsStageConsumerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	ConsumerStageBeginningOfChoice(CurrentData, "ManufacturedProducts")
	
EndProcedure

&AtClient
Procedure ManufacturedProductsPurposeOnChange(Item)
	
	
	Return;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSideAndIntermediateRelease

&AtClient
Procedure SideAndIntermediateReleaseOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	If (Field = Items.SideAndIntermediateReleaseSeries 
			Or Field = Items.SideAndIntermediateReleaseBatchesIndicationStatus)
		And CurrentData.BatchesIndicationStatus > 0
		And CurrentData.BatchesIndicationStatus <= 11 Then
		OpenSelectionOfSeries("SideAndIntermediateRelease");
	EndIf;
	
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.SideAndIntermediateRelease, ThisObject);
	
	ProductionManagementClient.OutputProductsOfStageAtBeginningOfEditing(
				ThisObject, CurrentData, "SideAndIntermediateRelease", NewRow, Copy); 
	
	If NewRow Then
		
		If RecordOfPerformed Then
			CurrentData.Manufactured = True;
		Else
			CurrentData.Manufactured = False;
		EndIf;
		
		FillInProductionDateInLine(CurrentData);
		
		//Setting up accounting accounts 
		If Copy Then
			GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
		EndIf;
		
		If Not Copy Then
			CurrentData.Department = Object.Department;
		EndIf;
		
		StructureOfActions = New Structure;
		InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		
		If Object.InternalSubcontracting Then
			CurrentData.ProductOwner = Object.MaterialProviderCompany;
		EndIf;
		
	EndIf;
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters.SideAndIntermediateRelease, Copy);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters.SideAndIntermediateRelease) Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS("SideAndIntermediateRelease", IDCurrentRow, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters.SideAndIntermediateRelease);
		
	EndIf;
	
	If NewRow And CancelEdit Then
		ConfigureDependentFormElements(ThisObject, "SideAndIntermediateRelease");
	EndIf;
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters.SideAndIntermediateRelease);

EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseAfterDeleteRow(Item)
	
	AfterRemovingTSRowsForWhichThereIsSeries("SideAndIntermediateRelease", Item);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseProductsOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	WhenChangingProducts(CurrentData, "SideAndIntermediateRelease");

EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseCharacteristicOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	WhenChangingCharacteristics(CurrentData, "SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleasePackageOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	If CurrentData.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentData.Count);
	Else
		StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(ThisObject));
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.SideAndIntermediateRelease.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.SideAndIntermediateRelease.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters.SideAndIntermediateRelease, ValueSelected);

	ProductsSeriesRecalculatePrices(, "SideAndIntermediateRelease");

EndProcedure

&AtClient
Procedure ProductsSeriesRecalculatePrices(CurrentRow = Undefined, TabularSectionName)
	
	If Not (TabularSectionName = "ManufacturedProducts"
		Or TabularSectionName = "SideAndIntermediateRelease") Then
		Return;
	EndIf;
	
	If CurrentRow = Undefined Then
		CurrentRow = Items[TabularSectionName].CurrentData;
	EndIf;
	
	If PriceManagementSystemClient.ItIsNecessaryToRecalculatePriceWhenChanging(CurrentRow.Products, "Series") Then
		
		StructureOfActions = New Structure;
		If TabularSectionName = "SideAndIntermediateRelease"
			Or TabularSectionName = "ManufacturedProducts"
				And UseTargetCost Then
			StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(ThisObject));
			StructureOfActions.Insert("RecalculateAmount");
		EndIf;
		
		If TabularSectionName = "ManufacturedProducts" Then
			StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
		EndIf;
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("SideAndIntermediateRelease", Item.EditText);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	WhenChangingNumberOfPackages(CurrentData, "SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseManufacturedOnChange(Item)
	
	WhenFlagIsChangedFollowingIsDone("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseProductionDateOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	StructureOfActions = New Structure;
	AddQualityControlActionsToStructure("SideAndIntermediateRelease", StructureOfActions, CacheQualityControl);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDirectionOfProductionIssueOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	WhenChangingDirectionOfRelease(CurrentData, "SideAndIntermediateRelease")
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleasePriceOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	ProductionManagementClient.ProductsOfStagePriceWhenChanging(CurrentData, CachedValues);

EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSumOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	ProductionManagementClient.ItemsOfAmountStageWhenChanged(CurrentData, CachedValues);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseRecipientOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	WhenChangingRecipient(CurrentData, "SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseToControlQualityOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseQualityConfirmationDateOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	If Not CurrentData.ToControlQuality Then
		CurrentData.QualityConfirmationDate = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseCanceledOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	ItemsCanceledWhenModified("SideAndIntermediateRelease", CurrentData)
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseProcessByBOMOnChange(Item)
	
	ProcessBySpecificationWhenModified("SideAndIntermediateRelease", Items.SideAndIntermediateRelease.CurrentData);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseStageConsumerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	ConsumerStageBeginningOfChoice(CurrentData, "SideAndIntermediateRelease")
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleasePurposeOnChange(Item)

	StructureOfActions = New Structure;
	
	
	InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
	
	If ValueIsFilled(StructureOfActions) Then
	
		CurrentData = Items.SideAndIntermediateRelease.CurrentData;
		
		ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, ValuesInCache);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLaborCosts

&AtClient
Procedure LaborCostsOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	If Copy Then
		CurrentData.RowCode = 0;
		CurrentData.KeyWorkType = Undefined;
	EndIf;
	
	If NewRow Then
		
		If RecordOfPerformed Then
			CurrentData.Completed2 = True;
		Else
			CurrentData.Completed2 = False;
		EndIf;
		
		If Object.WorkPerformanceAsOneDay Then
			CurrentData.ExecutionDate = Object.WorkExecutionDate;
		EndIf;
		
		If Not Copy Then
			CurrentData.Department = Object.Department;
		EndIf;
		
	EndIf;
	
	AccountingOfLaborCostsInContextOfEmployeesIsUsed = ValueIsFilled(BeginningOfAccountingOfLaborCostsForEmployees)
		And (CurrentData.ExecutionDate >= BeginningOfAccountingOfLaborCostsForEmployees
		Or ?(ValueIsFilled(Object.ActualStageStart), Object.ActualStageStart,
								Object.Date) >= BeginningOfAccountingOfLaborCostsForEmployees);
	
	ProductionManagementClientServer.SetArtistType(
		CurrentData.Performer,
		UseTeamWorkOrders,
		AccountingOfLaborCostsInContextOfEmployeesIsUsed);
	
EndProcedure

&AtClient
Procedure LaborCostsExecutionDateOnChange(Item)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	If Not ValueIsFilled(CurrentData.ExecutionDate)
		Or ValueIsFilled(CurrentData.Performer) Then
		Return;
	EndIf;
	
	CurrentData.Performer = Undefined;
	
	AccountingOfLaborCostsInContextOfEmployeesIsUsed = ValueIsFilled(BeginningOfAccountingOfLaborCostsForEmployees)
		And CurrentData.ExecutionDate >= BeginningOfAccountingOfLaborCostsForEmployees;
	
	ProductionManagementClientServer.SetArtistType(
		CurrentData.Performer,
		UseTeamWorkOrders,
		AccountingOfLaborCostsInContextOfEmployeesIsUsed);
	
EndProcedure

&AtClient
Procedure LaborCostsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	If ShowStandardsLaborCosts And CurrentData <> Undefined Then
		
		DataArray = New Array;
		RowData = New Structure("WorkKind");
		FillPropertyValues(RowData, CurrentData);
		DataArray.Add(RowData);
		Standards = GetStandardsWhenChangingRows("LaborCosts", DataArray, StorageAddressStandards);
		CurrentData.NormativeStandard = Standards[0];
		
	EndIf;
	
	If NewRow And CancelEdit Then
		ConfigureDependentFormElements(ThisObject, "LaborCosts");
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsCompleted2OnChange(Item)
	
	CurrentData = Items.LaborCosts.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Id = CurrentData.GetID();
	LaborPerformedWhenChangingOnServer(Id);
	
	If Not ValueIsFilled(CurrentData.ExecutionDate)
		Or ValueIsFilled(CurrentData.Performer) Then
		Return;
	EndIf;
	
	If ValueIsFilled(Object.Performer) Then
		
		CurrentData.Performer = Object.Performer;

	Else
	
		CurrentData.Performer = Undefined;
		
		AccountingOfLaborCostsInContextOfEmployeesIsUsed = ValueIsFilled(BeginningOfAccountingOfLaborCostsForEmployees)
			And CurrentData.ExecutionDate >= BeginningOfAccountingOfLaborCostsForEmployees;
		
		ProductionManagementClientServer.SetArtistType(
			CurrentData.Performer,
			UseTeamWorkOrders,
			AccountingOfLaborCostsInContextOfEmployeesIsUsed);
			
	EndIf;
	
EndProcedure

&AtServer
Procedure LaborPerformedWhenChangingOnServer(Val Id)
	
	CurrentData = Object.LaborCosts.FindByID(Id);
	
	If CurrentData.Completed2 Then
		
		If Not StageExecutionIsStarted Then
			StageExecutionIsStarted = True;
			ProcessStartOfStageExecution();
		EndIf;
		
	EndIf;
	
	If Object.WorkPerformanceAsOneDay Then
		ProductionManagement.SetDateOfCompletionOfLaborCosts(CurrentData, Object.WorkExecutionDate);
	Else
		ProductionManagement.SetDateOfCompletionOfLaborCosts(CurrentData, EventDateCompletion);
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsPerformerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	CallbackDescription = New CallbackDescription("PerformerStartChoiceCompletion", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Object.Organization,
		CurrentData.Department,
		CurrentData.Performer,
		CurrentData.ExecutionDate,
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure LaborCostsPerformerAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(
			ChoiceData, Text, Items.LaborCosts.CurrentData.Department, Object.Organization, Items.LaborCosts.CurrentData.ExecutionDate);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsPerformerTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		
		StandardProcessing = False;
		
		PerformerGettingSelectionData(
			ChoiceData, Text, Items.LaborCosts.CurrentData.Department, Object.Organization, Items.LaborCosts.CurrentData.ExecutionDate);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsCanceledOnChange(Item)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	If CurrentData.Canceled
		And CurrentData.Completed2 Then
		CurrentData.Completed2 = False;
		LaborPerformedWhenChangingOnServer(CurrentData.GetID());
	EndIf;
	
	If Not CurrentData.Canceled Then
		CurrentData.CancellationReason = PredefinedValue("Catalog.ReasonsForProductionCancellation.EmptyRef");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSupplyWithMaterialsAndWorks

&AtClient
Procedure SupplyWithMaterialsAndWorksSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ProductionStage2_2.Form.DocumentForm.Items.SupplyWithMaterialsAndWorks.Selection");
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	If Field = Items.SupplyWithMaterialsAndWorksAvailable And Not ReadOnly And Not RecordOfPerformed Then
		
		StandardProcessing = False;
		ProvidingMaterialsAndWorksSelectionIsAvailable(CurrentData);
		
	ElsIf Field = Items.SupplyWithMaterialsAndWorksThereAreSubstituteMaterials And Not ReadOnly And Not RecordOfPerformed Then
		
		StandardProcessing = False;
		OpenSelectionOfAnalogues();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.SupplyWithMaterialsAndWorks, ThisObject);
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	If NewRow And Not Copy Then
		CurrentData.Department = Object.Department;
	EndIf;
	
	ProductionManagementClient.ProvisionOfMaterialsAndWorksOfStageAtBeginningOfEditing(
		ThisObject,
		CurrentData,
		NewRow,
		Copy);
	
	WarehousesClient.UpdateCachedValues(
		Item, 
		CachedValues, 
		SeriesSpecificationParameters.SupplyWithMaterialsAndWorks, 
		Copy);
		
	If NewRow Then
		
		StructureOfActions = New Structure();
		
		ProvisionInDocumentsClientServer.AddCollateralActions(
			StructureOfActions,
			"SupplyOption,Available,WarehouseIsRequired,DateOfShipmentRequired_",
			DocumentParametersForSoftwareActions(ThisObject));
			
		If Copy
		   And StructureOfActions.Property("CheckSoftwareInSalesDocument") Then
		
			SecurityOptionAndFlagSeparately = ProvisionInDocumentsClientServer.ProvisionOptionAndFlagAreSeparateByDefault(
				CurrentData.WithAssignment);
				
			ActionParameters = StructureOfActions.CheckSoftwareInSalesDocument;
				
			If TypeOf(ActionParameters) = Type("Structure") 
			   And ActionParameters.Property("SecurityOptionAndFlagSeparately") Then
				ActionParameters.SecurityOptionAndFlagSeparately = SecurityOptionAndFlagSeparately;
			EndIf;
				
		EndIf;
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
		
		ProductDataManagementClient.ClearSetDetailsInLine(CurrentData);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	If CurrentData <> Undefined Then
		
		If Object.NotShipInInstallments Then
			
			CurrentData.DateOfShipment = Object.DateOfShipment;
			
		EndIf;
		
		If ShowStandardsMaterials Then
			
			DataArray = New Array;
			RowData = New Structure("Products,Characteristic,ItemVariantsAreUsed,Package");
			FillPropertyValues(RowData, CurrentData);
			DataArray.Add(RowData);
			Standards = GetStandardsWhenChangingRows("SupplyWithMaterialsAndWorks", DataArray, StorageAddressStandards);
			CurrentData.NormativeStandard = Standards[0];
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
	
	BeforeDeletingRowsIncludedInSets();
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksAfterDeleteRow(Item)
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(
			Object.SupplyWithMaterialsAndWorks,
			DateOfShipmentRequired_,
			WarehouseIsRequired);
			
	SupplyWithMaterialsAndWorksAfterDeleteRowServer();
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksProductsOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	WhenChangingProducts(CurrentData, "SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksCharacteristicOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	WhenChangingCharacteristics(CurrentData, "SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyOptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProvisionInDocumentsClient.SupplyOptionChoiceProcessing(
		ThisObject,
		Items.SupplyWithMaterialsAndWorks.CurrentData,
		ValueSelected);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyOptionOnChange(Item)
	
	Var FormParameters;
	If ProvisionInDocumentsClient.OpenWarehouseAndSeriesSelectionForm(ThisObject) Then
		OptionForGettingParameters = ProvisionInDocumentsClientServer.ActionSelectionMode();
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(OptionForGettingParameters); // A call to the server
	EndIf;
	
	ProvisionInDocumentsClient.SupplyOptionOnChange(
		ThisObject,
		FormParameters,
		"ProcessWarehouseAndBatchSelection",
		True,
		"ProvisionOfMaterialsAndWorksOptionOfProvisionInCaseOfChangeAfterQuestion");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyOptionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksWithAssignmentOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	ProvisionInDocumentsClient.WithAssignmentOnChange(CurrentData);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInAssignmentInProductionPhase");
	
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		"AvailableInOtherLines",
		DocumentParametersForSoftwareActions(ThisObject));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyAssignmentOnChange(Item)
	
	TableRow = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure();
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		"AvailableInOtherLines",
		DocumentParametersForSoftwareActions(ThisObject));
	StructureOfActions.Insert("FillInAssignmentInProductionPhase");
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, Undefined);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksWarehouseStartChoice(Item, ChoiceData, StandardProcessing)
	
	FormParameters = ParametersOfQuantityAndSeriesRequestForm(ProvisionInDocumentsClientServer.WarehouseSelectionMode());
	
	If TypeOf(FormParameters) = Type("Structure") Then
		
		StandardProcessing = False;
		OpenForm(
			"DataProcessor.QuantityAndBatchRequest.Form",
			FormParameters,
			ThisObject,
			,
			,
			,
			New CallbackDescription("ProcessWarehouseAndBatchSelection", ThisObject, FormParameters));
		
	ElsIf RecordOfPerformed And Not ValueIsFilled(Object.Department) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksPackageOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		"AvailableInOtherLines",
		DocumentParametersForSoftwareActions(ThisObject));
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	WhenChangingNumberOfPackages(CurrentData, "SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSeriesOnChange(Item)
	
	CurrentRow = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value                   = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks, ValueSelected);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("SupplyWithMaterialsAndWorks", Item.EditText, Items.SupplyWithMaterialsAndWorks.CurrentData);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksProducedOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	CurrentData.BillOfMaterials = Undefined;
	
	StructureOfActions = New Structure();
	
	AddCheckActionFillInSpecification(ThisObject, StructureOfActions, CurrentData);
	
	StructureOfActions.Insert("FillInPurposeOfProvisionInProductionPhase", ParametersForFillingAssignments);
	
	MethodParameters = New Structure();
	MethodParameters.Insert("ProductionOrder",    Object.ReferenceOrder);
	MethodParameters.Insert("Department",          Object.Department);
	MethodParameters.Insert("Ref",                 Object.Ref);
	MethodParameters.Insert("Status",                 Object.Status);
	MethodParameters.Insert("SubcontractOrder",     Object.SubcontractOrder);
	MethodParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
	MethodParameters.Insert("Form",                  ThisObject);
	
	ProductionManagementClientServer.AddToStructureActionsCheckSoftwareInProductionPhase(
		StructureOfActions,
		MethodParameters);
	
	ProductionManagementClientServer.AddActionsToStructureFillInAvailableColumn(
		StructureOfActions,
		MethodParameters,
		CurrentData);
		
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		"AvailableInOtherLines",
		DocumentParametersForSoftwareActions(ThisObject));
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksWarehouseOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	StructureOfActions = ProductionManagementClient.ProvisionOfMaterialsAndWorksForWarehouseStageInCaseOfChanges(
		ThisObject,
		CurrentData,
		SeriesSpecificationParameters.SupplyWithMaterialsAndWorks, 
		CachedValues);
		
	If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions) Then
		UpdateColumnAvailableServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure DoNotShipInPartsWhenChangingOnServer()

	If Object.NotShipInInstallments Then
		Object.DateOfShipment = Documents.ProductionStage2_2.MaximumDateWH(
									Object.SupplyWithMaterialsAndWorks, "DateOfShipment");
		FillInWHDate("SupplyWithMaterialsAndWorks", "DateOfShipment", Object.DateOfShipment);
		
		If RecordOfPerformed Then
			Object.ConsumptionInOneDay = Object.NotShipInInstallments;
			Object.DateOfMaterialWorkConsumption = Object.DateOfShipment;
			FillInWHDate("MaterialsAndWorksConsumption",  "DateOfMaterialWorkConsumption", Object.DateOfMaterialWorkConsumption);
		EndIf;
		
	EndIf;
	
	ChangedBankingDetails = "NotShipInInstallments";
	If RecordOfPerformed Then
		ChangedBankingDetails = ChangedBankingDetails + ",ConsumptionInOneDay";
	EndIf;
	ConfigureDependentFormElements(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksCanceledOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	If Not CurrentData.Canceled Then
		CurrentData.CancellationReason = PredefinedValue("Catalog.ReasonsForProductionCancellation.EmptyRef");
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", CurrentData.Warehouse, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksSupplyOptionStartChoice(Item, ChoiceData, StandardProcessing)
	
	NewArray = New Array();
	
	NewParameter1 = New ChoiceParameter("MultipleWarehouses", True);
	NewArray.Add(NewParameter1);
	
	UnacceptableActions = New Array();
	
	// The "Ship" software option is not available.
	ShipmentIsAvailable = Not(
		Object.ProductionByThirdParty
			And TollingOrderCreated
			And Object.NotShipInInstallments
			And Not ValueIsFilled(Object.DateOfShipment));
		
	If Not ShipmentIsAvailable Then
		UnacceptableActions.Add(PredefinedValue("Enum.SupplyOptions.Ship"));
	EndIf;
	
	// The "Reserve as received" collateral option is not available.
	If Object.DynamicStructure Then
		UnacceptableActions.Add(PredefinedValue("Enum.SupplyOptions.ReserveAsReceived"));
	EndIf;
	
	If UnacceptableActions.Count() > 0 Then
		
		ActionsArray = ProvisionInDocumentsClientServer.AvailableActionsForSelectingCollateralInDefaultRow();
		For Each InvalidAction In UnacceptableActions Do
			IndexOf = ActionsArray.Find(InvalidAction);
			If IndexOf <> Undefined Then
				ActionsArray.Delete(IndexOf);
			EndIf;
		EndDo;
		AllowedActions = New FixedArray(ActionsArray);
		NewParameter1 = New ChoiceParameter("AllowedActions", AllowedActions);
		
		NewArray.Add(NewParameter1);
		
	EndIf;
	
	Item.ChoiceParameters = New FixedArray(NewArray);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksUnderRepairProductOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	CurDataStructure = ProductionManagementClientServer.TheseLinesSupplyOfMaterialsAndWorksStructure(CurrentData);

	// redefining to use standard actions
	CurDataStructure.Insert("Products", CurrentData.UnderRepairProduct);
	CurDataStructure.Insert("Characteristic", CurrentData.UnderRepairVariant);
	CurDataStructure.Insert("ItemVariantsAreUsed", CurrentData.FinishedProductBeingRepairedCharacteristicsAreUsed);
	CurDataStructure.Insert("ItemsType", CurrentData.RepairedFinishedProductTypeOfItem);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.UnderRepairVariant);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("UnderRepairProduct", "RepairedFinishedProductTypeOfItem"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Undefined, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurDataStructure, StructureOfActions, CachedValues);
	
	CurrentData.UnderRepairVariant             = CurDataStructure.Characteristic;
	CurrentData.FinishedProductBeingRepairedCharacteristicsAreUsed = CurDataStructure.ItemVariantsAreUsed;
	CurrentData.UnderRepairBatch                      = CurDataStructure.UnderRepairBatch;
	CurrentData.UnderRepairBatchSpecificationStatus        = CurDataStructure.UnderRepairBatchSpecificationStatus;
	CurrentData.RepairedFinishedProductTypeOfItem            = CurDataStructure.RepairedFinishedProductTypeOfItem;
	
	StructureOfActions = New Structure;
	AddCheckActionFillInSpecification(ThisObject, StructureOfActions, CurrentData);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksUnderRepairVariantOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	
	AddCheckActionFillInSpecification(ThisObject, StructureOfActions, CurrentData);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksUnderRepairBatchOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	ValueSelected.Value                   = CurrentData.UnderRepairBatch;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	CurrentRow = New Structure;
	CurrentRow.Insert("SupplyOption", PredefinedValue("Enum.SupplyOptions.NotRequired"));
	CurrentRow.Insert("Canceled", CurrentData.Canceled);
	CurrentRow.Insert("Series", CurrentData.UnderRepairBatch);
	CurrentRow.Insert("BatchesIndicationStatus", CurrentData.UnderRepairBatchSpecificationStatus);
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks, ValueSelected, CurrentRow);
	
	CurrentData.UnderRepairBatch               = CurrentRow.Series;
	CurrentData.UnderRepairBatchSpecificationStatus = CurrentRow.BatchesIndicationStatus;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMaterialsAndWorksConsumption

&AtClient
Procedure MaterialsAndWorksConsumptionBeforeDeleteRow(Item, Cancel)
	ProcessingOfTabularFormsClient.CacheCurLine(Items.MaterialsAndWorksConsumption, ThisObject);
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionAfterDeleteRow(Item)
	ExpenseOfMaterialsAndWorksAfterDeletionOnServer();
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.MaterialsAndWorksConsumption.CurrentData;
	If NewRow Then
		If Object.ConsumptionInOneDay And Object.DateOfMaterialWorkConsumption <> '000101010000' Then
			CurrentData.DateOfMaterialWorkConsumption = Object.DateOfMaterialWorkConsumption;
		EndIf;
		If Not Copy Then
			CurrentData.Department = Object.Department;
		EndIf;
	EndIf;
	ProcessingOfTabularFormsClient.CacheCurLine(Items.MaterialsAndWorksConsumption, ThisObject);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionOnEditEnd(Item, NewRow, CancelEdit)
	
	If NewRow And CancelEdit Then
		ConfigureDependentFormElements(ThisObject, "MaterialsAndWorksConsumption");
	EndIf;
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, Items.MaterialsAndWorksConsumption, AdditionalParameters);
	If AdditionalParameters.Property("ServerCallRequired__") Then
		AttachIdleHandler("ExpenseOfMaterialsAndWorksAtEndOfEditingForServerCall", 0.5, True);
	EndIf;

EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionProductsOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorksConsumption.CurrentData;
	WhenChangingProducts(CurrentData, "MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionCharacteristicOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorksConsumption.CurrentData;
	WhenChangingCharacteristics(CurrentData, "MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionPackageOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorksConsumption.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorksConsumption.CurrentData;
	WhenChangingNumberOfPackages(CurrentData, "MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionSeriesOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorksConsumption.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = CurrentData.Series;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters.MaterialsAndWorksConsumption, ValueSelected);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("MaterialsAndWorksConsumption", Item.EditText);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumptionOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "MaterialsAndWorksConsumption");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUnusedMaterials

&AtClient
Procedure UnusedMaterialsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	
	If NewRow And Not Copy Then
		CurrentData.Department = Object.Department;
	EndIf;
	
	ProductionManagementClient.UnusedMaterialsOnStartEdit(
		ThisObject,
		Object,
		CurrentData,
		NewRow,
		Copy);
		
	WarehousesClient.UpdateCachedValues(Item, CachedValues, SeriesSpecificationParameters.UnusedMaterials, Copy);
	
	//Setting up accounting accounts 
	If NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,CachedValues,SeriesSpecificationParameters.UnusedMaterials, Copy);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters.UnusedMaterials) Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			"UnusedMaterials", IDCurrentRow, CachedValues);
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item, CachedValues, SeriesSpecificationParameters.UnusedMaterials);
		
	EndIf;
	
	If NewRow And CancelEdit Then
		ConfigureDependentFormElements(ThisObject, "UnusedMaterials");
	EndIf;
	
EndProcedure

&AtClient
Procedure UnusedMaterialsBeforeDeleteRow(Item, Cancel)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters.UnusedMaterials);

EndProcedure

&AtClient
Procedure UnusedMaterialsAfterDeleteRow(Item)
	
	AfterRemovingTSRowsForWhichThereIsSeries("UnusedMaterials", Item);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsProductsOnChange(Item)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	WhenChangingProducts(CurrentData, "UnusedMaterials");
	
EndProcedure

&AtClient
Procedure UnusedMaterialsCharacteristicOnChange(Item)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	WhenChangingCharacteristics(CurrentData, "UnusedMaterials");
	
EndProcedure

&AtClient
Procedure UnusedMaterialsPackageOnChange(Item)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	WhenChangingNumberOfPackages(CurrentData, "UnusedMaterials");
	
EndProcedure

&AtClient
Procedure UnusedMaterialsSeriesOnChange(Item)
	
	CurrentRow = Items.UnusedMaterials.CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	ValueSelected.Value                   = CurrentRow.Series;
	ValueSelected.CurrentRowID = CurrentRow.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters.UnusedMaterials, ValueSelected);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("UnusedMaterials", Item.EditText, Items.UnusedMaterials.CurrentData);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "UnusedMaterials");
	
EndProcedure

&AtClient
Procedure UnusedMaterialsRecipientOnChange(Item)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	WhenChangingRecipient(CurrentData, "UnusedMaterials");
	
EndProcedure

&AtClient
Procedure UnusedMaterialsActionsOnChange(Item)
	
	CurrentData = Items.UnusedMaterials.CurrentData;
	SavingMaterialsActionWhenChanging(CurrentData);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure UnusedMaterialsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure UnusedMaterialsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormPageElementEventHandlersProductionProcess

&AtClient
Procedure WorkCenterTypesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	CurrentData = Items.WorkCenterTypes.CurrentData;
	
	ProductionProcessEditorClient.WorkCenterTypesBeforeAddRow(
		CurrentData, 
		WorkCenterTypes, 
		Items.WorkCenterTypes,
		Object.OperatingProcedureOfWorkCenterTypes,
		ThereIsSynchronousLoad,
		Cancel,
		True);
	
	ConfigureDependentFormElements(ThisObject, "WorkCenterTypes");
	
EndProcedure

&AtClient
Procedure WorkCenterTypesOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		CurrentData = Items.WorkCenterTypes.CurrentData;
		CurrentData.UnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Minute");
		If Not CurrentData.AlternateType Then
			CurrentData.Use = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure WorkCenterTypesOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateNumberOfTypesOfWorkCenters(ThisObject);
	
EndProcedure

&AtClient
Procedure WorkCenterTypesAfterDeleteRow(Item)
	
	// You need to check that the type of RC is selected
	CollectionOfMainTypesOfRC = WorkCenterTypes.GetItems();
	For Each RowMainViewOfRC In CollectionOfMainTypesOfRC Do
		If RowMainViewOfRC.Use Then
			Continue;
		EndIf;
		CollectionOfAlternatives = RowMainViewOfRC.GetItems();
		AlternativeIsUsed = False;
		For Each StringAlternative In CollectionOfAlternatives Do
			If StringAlternative.Use Then
				AlternativeIsUsed = True;
				Break;
			EndIf;
		EndDo;
		If Not AlternativeIsUsed Then
			RowMainViewOfRC.Use = True;
		EndIf;
	EndDo;
	
	ProductionProcessEditorClient.WhenChangingCompositionOfTypesOfWorkCenters(
		WorkCenterTypes, 
		Object.OperatingProcedureOfWorkCenterTypes,
		True);
	
	CalculateNumberOfTypesOfWorkCenters(ThisObject);
	
	ProductionProcessEditorClientServer.CalculateServiceSignsOfLoadingVRC(
		WorkCenterTypes,,
		ThereIsSynchronousLoad);
	
	ConfigureDependentFormElements(ThisObject, "WorkCenterTypes");
	
EndProcedure

&AtClient
Procedure WorkCenterTypesUseOnChange(Item)
	
	// This is always a check box setting
	CurrentData = Items.WorkCenterTypes.CurrentData;
	
	ItemParent = CurrentData.GetParent();
	If ItemParent = Undefined Then
		ItemParent = CurrentData;
		CollectionOfAlternatives = CurrentData.GetItems();
	Else
		CollectionOfAlternatives = ItemParent.GetItems();
	EndIf;
	
	For Each StringAlternative In CollectionOfAlternatives Do
		If StringAlternative.Use And StringAlternative <> CurrentData Then
			StringAlternative.Use = False;
		EndIf;
	EndDo;
	If ItemParent.Use And ItemParent <> CurrentData Then
		ItemParent.Use = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure WorkCenterTypesWorkCenterTypeOnChange(Item)
	
	CurrentRow = Items.WorkCenterTypes.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FillInServiceDetailsInLineOfTypesOfRC(CurrentRow);
	TypesOfWorkCentersRecalculateLoad(Items.WorkCenterTypes.CurrentData);
	TypesOfWorkCentersRecalculateWorkingHours(Items.WorkCenterTypes.CurrentData);
	
EndProcedure

&AtClient
Procedure WorkCenterTypesSetupSettingsOnChange(Item)
	
	CurrentRow = Items.WorkCenterTypes.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FillInServiceDetailsInLineOfTypesOfRC(CurrentRow);
	TypesOfWorkCentersRecalculateLoad(Items.WorkCenterTypes.CurrentData);
	TypesOfWorkCentersRecalculateWorkingHours(Items.WorkCenterTypes.CurrentData);
	
EndProcedure

&AtClient
Procedure WorkCenterTypesOperationTimeStandardOnChange(Item)
	
	TypesOfWorkCentersRecalculateWorkingHours(Items.WorkCenterTypes.CurrentData);
	
EndProcedure

&AtClient
Procedure WorkCenterTypesLoadStandardOnChange(Item)
	
	TypesOfWorkCentersRecalculateLoad(Items.WorkCenterTypes.CurrentData);
	TypesOfWorkCentersRecalculateWorkingHours(Items.WorkCenterTypes.CurrentData);
	
EndProcedure

&AtClient
Procedure PreliminaryBufferOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "PreliminaryBuffer");
	
EndProcedure

&AtClient
Procedure FollowUpBufferOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "FollowUpBuffer");
	
EndProcedure

&AtClient
Procedure UnitOfMeasureOfPreliminaryBufferOnChange(Item)
	
	If Object.UnitOfMeasureOfPreliminaryBuffer.IsEmpty() Then
		
		Object.UnitOfMeasureOfPreliminaryBuffer = BasicBufferTimeUnit;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UnitOfMeasureOfFollowUpBufferOnChange(Item)
	
	If Object.UnitOfMeasureOfFollowUpBuffer.IsEmpty() Then
		
		Object.UnitOfMeasureOfFollowUpBuffer = BasicBufferTimeUnit;
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure OperatingProcedureOfWorkCenterTypesOnChange(Item)
	
	ProductionProcessEditorClient.OperatingProcedureOfWorkCenterTypesOnChange(
		WorkCenterTypes,
		Object.OperatingProcedureOfWorkCenterTypes,
		ThereIsSynchronousLoad,
		False);
	
EndProcedure
	
#EndRegion

#Region EventHandlersForFormPageElementsAdvanced

&AtClient
Procedure InternalSubcontractingOnChange(Item)
	
	If Object.InternalSubcontracting Then
		Object.MaterialProviderCompany = Object.Organization;
		Object.Organization = Undefined;
	Else
		Object.Organization = Object.MaterialProviderCompany;
		Object.MaterialProviderCompany = Undefined;
	EndIf;
	
	InternalProcessingWhenChangingOnServer();
	
	ConfigureDependentFormElements(ThisObject, "InternalSubcontracting");
	FillInSelectionListOfProductOwners(ThisObject);
	
	CompanyBeforeChange = Object.Organization;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	If Not CompanyBeforeChange = Object.Organization Then
		
		If Object.Organization = Object.MaterialProviderCompany Then
			
			CommonClient.MessageToUser(NStr("vi = 'Doanh nghiệp trên chứng từ không thể trùng với doanh nghiệp đặt gia công. Đã hủy thao tác.';
											|ru = 'Организация документа не может совпадать с организацией-давальцем. Действие отменено.';
											|en = 'Document company and the material provider company cannot be the same. The action is canceled.'; fa = 'Document company and the material provider company cannot be the same. The action is canceled.';
											|it = 'Организация документа не может совпадать с организацией-давальцем. Действие отменено.';
											|pl = 'Document company and the material provider company cannot be the same. The action is canceled.';
											|tr = 'Belgenin iş yeri işe tedarikçi iş yeri aynı olamaz. Eylem iptal edildi.'"));
			Object.Organization = CompanyBeforeChange;
			
			Return;
			
		EndIf;
		
		OrganizationWhenChangedOnServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionIssueForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region ProductionAndPlanning

&AtClient
Procedure ProductionOpenBOM(Command)
	
	If ValueIsFilled(Object.BillOfMaterials) Then
		ShowValue(, Object.BillOfMaterials)
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionShowStages(Command)
	
	ProductionManagementClient.OpenStageChainEditingForm(Object.ReferenceOrder, Object.ProductionLot);
	
EndProcedure

&AtClient
Procedure Production_EditTechnicalProcess(Command)
	
	OpenProcessEditingForm();

EndProcedure

&AtClient
Procedure ProductionGoToManualScheduleEditing(Command)
	
	OpenManualChartEditingForm();
	
EndProcedure

&AtClient
Procedure ProductionOfInformationOnOperations(Command)
	
	InformationOnOperationsOnServer();
	
	ShowUserNotification(
		NStr("vi = 'Giao dịch đã kết thúc';
			|ru = 'Операция завершена';
			|en = 'Operation is complete'; fa = 'عملیات تکمیل شد';
			|it = 'Operazione conclusa';
			|pl = 'Operacja została zakończona.';
			|tr = 'İşlem tamamlandı'"),,,
		PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure ProductionExecutionOfOperations(Command)
	
	If Modified Then
		
		ShowQueryBox(
			New CallbackDescription("RecordAndOpenExecutionOfOperationsEnd", ThisObject),
			NStr("vi = 'Cần ghi lại chứng từ để thực hiện giao dịch. Ghi lại chứng từ?';
				|ru = 'Необходимо записать документ для выполнения операции. Записать документ?';
				|en = 'You need to save the document before running the operation. Do you want to save it?'; fa = 'You need to save the document before running the operation. Do you want to save it?';
				|it = 'È necessario salvare il documento per eseguire operazione. Salvare il documento?';
				|pl = 'Należy zapisać dokument aby wykonać operację. Zapisać dokument?';
				|tr = 'İşlemin gerçekleştirilmesi için belgenin kaydedilmesi gerekmektedir. Belge kaydedilsin mi?'"),
			QuestionDialogMode.YesNo);
		
	Else
		
		ProductionManagementClient.OpenPerformingOperations(Object.Ref, ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordAndOpenExecutionOfOperationsEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
		Return;
	EndIf;
	
	ProductionManagementClient.OpenPerformingOperations(Object.Ref, ThisObject);
	
EndProcedure

&AtClient
Procedure ProductionShiftTasks(Command)
	
	OpenForm(
		"Document.ShiftTask.ListForm",
		New Structure("FilterByStep", Object.Ref),
		ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure Production_ProductionOperations(Command)
	
	OpenForm(
		"Document.ProductionOperation2_2.ListForm",
		New Structure("StepFilter", Object.Ref),
		ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure ProductionOrderStructure_2(Command)
	
	If Not Object.Ref.IsEmpty() Then
		OpenForm(
			"Report.ProductionOrderStructure2_2.Form.OrderStructure",
			New Structure("Stage", Object.Ref),
			ThisObject,
			UUID);
	Else
		ShowQueryBox(
			New CallbackDescription("ConductAndOpenOrderStructureEnd", ThisObject),
			NStr("vi = 'Cần kết chuyển chứng từ để thực hiện giao dịch. Kết chuyển chứng từ?';
				|ru = 'Необходимо провести документ для выполнения операции. Провести документ?';
				|en = 'To proceed, you need to post the document. Do you want to post the document?'; fa = 'To proceed, you need to post the document. Do you want to post the document?';
				|it = 'È necessario registrare il documento per eseguire operazione. Registrare documento?';
				|pl = 'Należy zaksięgować dokument aby wykonać operację. Zaksięgować dokument?';
				|tr = 'İşlemin gerçekleştirilmesi için belgenin kaydedilmesi gerekmektedir. Belge kaydedilsin mi?'"),
			QuestionDialogMode.YesNo);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure ConductAndOpenOrderStructureEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	If Not Write(New Structure("WriteMode", DocumentWriteMode.Posting)) Then
		Return;
	EndIf;
	
	OpenForm(
		"Report.ProductionOrderStructure2_2.Form.OrderStructure",
		New Structure("Stage", Object.Ref),
		ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure Production_ReflectDefectiveGoods(Command)
	
	If Modified Then
		
		ShowQueryBox(
			New CallbackDescription("RecordAndReflectDefectiveGoodsEnding", ThisObject),
			NStr("vi = 'Cần ghi lại chứng từ để thực hiện giao dịch. Ghi lại chứng từ?';
				|ru = 'Необходимо записать документ для выполнения операции. Записать документ?';
				|en = 'You need to save the document before running the operation. Do you want to save it?'; fa = 'You need to save the document before running the operation. Do you want to save it?';
				|it = 'È necessario salvare il documento per eseguire operazione. Salvare il documento?';
				|pl = 'Należy zapisać dokument aby wykonać operację. Zapisać dokument?';
				|tr = 'İşlemin gerçekleştirilmesi için belgenin kaydedilmesi gerekmektedir. Belge kaydedilsin mi?'"),
			QuestionDialogMode.YesNo);
		
	Else
		
		RecordDefectiveGoods();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordAndReflectDefectiveGoodsEnding(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Write() Then
		RecordDefectiveGoods();
	EndIf; 
	
EndProcedure

&AtClient
Procedure ProductionCancel(Command)
	
	If Modified Then
		
		ShowQueryBox(
			New CallbackDescription("RecordAndCancelProductionCompletion", ThisObject),
			NStr("vi = 'Cần ghi lại chứng từ để thực hiện giao dịch. Ghi lại chứng từ?';
				|ru = 'Необходимо записать документ для выполнения операции. Записать документ?';
				|en = 'You need to save the document before running the operation. Do you want to save it?'; fa = 'You need to save the document before running the operation. Do you want to save it?';
				|it = 'È necessario salvare il documento per eseguire operazione. Salvare il documento?';
				|pl = 'Należy zapisać dokument aby wykonać operację. Zapisać dokument?';
				|tr = 'İşlemin gerçekleştirilmesi için belgenin kaydedilmesi gerekmektedir. Belge kaydedilsin mi?'"),
			QuestionDialogMode.YesNo);
		
		
		CancelProduction();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordAndCancelProductionCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Write() Then
		CancelProduction();
	EndIf; 
	
EndProcedure

&AtClient
Procedure ReduceIncreaseProduction(Command)
	
	If Modified Then
		
		ShowQueryBox(
			New CallbackDescription("RecordAndReduceIncreaseProduction", ThisObject),
			NStr("vi = 'Cần ghi lại chứng từ để thực hiện giao dịch. Ghi lại chứng từ?';
				|ru = 'Необходимо записать документ для выполнения операции. Записать документ?';
				|en = 'You need to save the document before running the operation. Do you want to save it?'; fa = 'You need to save the document before running the operation. Do you want to save it?';
				|it = 'È necessario salvare il documento per eseguire operazione. Salvare il documento?';
				|pl = 'Należy zapisać dokument aby wykonać operację. Zapisać dokument?';
				|tr = 'İşlemin gerçekleştirilmesi için belgenin kaydedilmesi gerekmektedir. Belge kaydedilsin mi?'"),
			QuestionDialogMode.YesNo);
		
	Else
		
		ReduceIncreaseProduction_();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordAndReduceIncreaseProduction(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Write() Then
		ReduceIncreaseProduction_();
	EndIf; 
	
EndProcedure

&AtClient
Procedure ProductionCreateANewStage(Command)
	
	If Modified Then
		
		ShowQueryBox(
			New CallbackDescription("RecordAndCreateNewStageEnding", ThisObject),
			NStr("vi = 'Cần ghi lại chứng từ để thực hiện giao dịch. Ghi lại chứng từ?';
				|ru = 'Необходимо записать документ для выполнения операции. Записать документ?';
				|en = 'You need to save the document before running the operation. Do you want to save it?'; fa = 'You need to save the document before running the operation. Do you want to save it?';
				|it = 'È necessario salvare il documento per eseguire operazione. Salvare il documento?';
				|pl = 'Należy zapisać dokument aby wykonać operację. Zapisać dokument?';
				|tr = 'İşlemin gerçekleştirilmesi için belgenin kaydedilmesi gerekmektedir. Belge kaydedilsin mi?'"),
			QuestionDialogMode.YesNo);
		
	Else
		
		CreateNewStage();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordAndCreateNewStageEnding(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Write() Then
		CreateNewStage();
	EndIf; 
	
EndProcedure

&AtClient
Procedure ProductionFillInAccordingToSpecification(Command)
	
	If Object.WorkPlanning Then
		FillInAccordingToSpecificationOnServer(New Structure("SupplyWithMaterialsAndWorks"));
	Else
	
		FormParameters = New Structure;
		FormParameters.Insert("UseFinishedProducts", ThisIsAProductionIssueStage(ThisObject));
		FormParameters.Insert("UseLaborCosts", Not Object.ProductionByThirdParty);
		FormParameters.Insert("UseWorkCenterTypes",
			Not Object.StagePlacementInProductionSchedule
			And Object.PlanOperationsOfWorkCenterTypes 
			And ProductionResourcePlanningIsAvailable(ThisObject));
		
		OpenForm(
			"Document.ProductionStage2_2.Form.FillingParametersByBOM",
			FormParameters,
			ThisObject,
			Object.Ref,,,
			New CallbackDescription("ProductionFillInAccordingToSpecificationCompletion", ThisObject),
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionFillInAccordingToSpecificationCompletion(ListOfData, AdditionalParameters) Export
	
	If ListOfData = Undefined Then
		Return;
	EndIf;
	
	FillInAccordingToSpecificationOnServer(ListOfData);
	
EndProcedure

#EndRegion

#Region Pm_TeamsProvisionOfMaterialsAndWorks 

&AtClient
Procedure ToChangeTheDateOfShipment(Command)
	
	If TypeOf(ProductionSchedule) = Type("Structure") Then
		ChangeShippingDateOnServer(ProductionSchedule.Begin);
	EndIf;
	
EndProcedure

&AtClient
Procedure EnsureToIncludeASeparateProvision(Command)
	
	ProvidingSetAction("FLAG_UNITED");
	
EndProcedure

&AtClient
Procedure CollateralTurnOffStandAloneCollateral(Command)
	
	ProvidingSetAction("FLAG_NOTABLE");
	
EndProcedure

&AtClient
Procedure CollateralToCollateral(Command)
	
	ProvidingSetActionWithQuestion("ACTION_COOPERATION");
	
EndProcedure

&AtClient
Procedure ProvisionDoNotProvide(Command)
	
	ProvidingSetActionWithQuestion("ACTION_NOTABLE");
	
EndProcedure

&AtClient
Procedure ReserveCollateralAsItBecomesAvailable(Command)
	
	ProvidingSetAction("ACTION_RESERVATION_REFERENCES");
	
EndProcedure

&AtClient
Procedure SoftwareToShip(Command)
	
	ProvidingSetActionWithQuestion("Action_Ship_PRIORITY_WithAssignment");
	
EndProcedure

&AtClient
Procedure ProvisionOfBackup(Command)
	
	ProvidingSetActionWithQuestion("Action_ToReserve__PRIORITY_WithAssignment");
	
EndProcedure

&AtClient
Procedure EnsureToPickUpTheGoods(Command)
	
	OpensGoodsSelection("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure ToCreateAnAdjustmentPurposeTheRemovalOfTheReserve(Command)
	
	DocumentData = SupplyInDocumentsServerCall.DocumentDataForCreatingDestinationAdjustment(Object.Ref,
		New Structure("IDInStorage,ThisIsWithdrawalOfReserve", UUID, True));
	
	If Object.Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.BeingGenerated") Then
		
		MinimumStatus = PredefinedValue("Enum.StatusesOfProductionStages2_2.Generated1");
		SupplyClient.ReportRequiredMinimumDocumentStatus(False, MinimumStatus);
		
	ElsIf Modified Or Not DocumentData.Posted Then
		
		ShowMessageBox(, NStr("vi = 'Để hoàn nhập dự phòng theo hỉ định, trước tiên cần kết chuyển chứng từ.';
								|ru = 'Для снятия резерва под назначение необходимо предварительно провести документ.';
								|en = 'To unreserve inventory, please post the document.'; fa = 'To unreserve inventory, please post the document.';
								|it = 'Per annullare la prenotazione per l''assegnazione è innanzitutto necessario registrare il documento in contabilità.';
								|pl = 'Aby anulować rezerwę do przeznaczenia, należy najpierw zaksięgować dokument.';
								|tr = 'Atama rezervinin kaldırılması için önce belgeyi kaydetmeniz gerekmektedir.'"));
		
	Else
		
		CommandDetails = New Structure();
		CommandDetails.Insert("ObjectsOfBases", CommonClientServer.ValueInArray(Object.Ref));
		CommandDetails.Insert("Form", ThisObject);
		CommandDetails.Insert("AddressOfGoods", DocumentData.AddressOfGoods);
		If DocumentData.ThereAreGoodsToWithdrawReserve Then
			If DocumentData.Assignments.Count() = 1 Then
				CommandDetails.Insert("Purpose", DocumentData.Assignments[0]);
				GenerationByReferenceTMClient.OpenReserveWithdrawalWizard(CommandDetails);
			Else
				CommandDetails.Insert("Assignments", DocumentData.Assignments);
				GenerationByReferenceTMClient.OpenMassReserveWithdrawalWizard(CommandDetails);
			EndIf;
		Else
			SupplyClient.ReportAbsenceOfGoodsForWithdrawalOfReserve();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SoftwareToCreateACorrectionPurposeRedundant(Command)
	
	DocumentData = SupplyInDocumentsServerCall.DocumentDataForCreatingDestinationAdjustment(Object.Ref,
		New Structure("IDInStorage,ThisIsWithdrawalOfReserve", UUID, False));
	
	If Object.Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.BeingGenerated") Then
		
		MinimumStatus = PredefinedValue("Enum.StatusesOfProductionStages2_2.Generated1");
		SupplyClient.ReportRequiredMinimumDocumentStatus(False, MinimumStatus);
		
	ElsIf Modified Or Not DocumentData.Posted Then
		
		ShowMessageBox(, NStr("vi = 'Để lập dự phòng theo chỉ định trước tiên cần kết chuyển chứng từ.';
								|ru = 'Для резервирования под назначение необходимо предварительно провести документ.';
								|en = 'To reserve for assignment, post the document first.'; fa = 'To reserve for assignment, post the document first.';
								|it = 'Per prenotare per l''assegnazione è innanzitutto necessario registrare il documento in contabilità.';
								|pl = 'Aby zarezerwować dokument do przeznaczenia, należy najpierw zaksięgować dokument.';
								|tr = 'Atama rezervinin yapılması için önce belgeyi kaydetmeniz gerekmektedir.'"));
		
	Else
		
		CommandDetails = New Structure();
		CommandDetails.Insert("ObjectsOfBases", CommonClientServer.ValueInArray(Object.Ref));
		CommandDetails.Insert("Form", ThisObject);
		CommandDetails.Insert("AddressOfGoods", DocumentData.AddressOfGoods);
		If DocumentData.ThereAreGoodsToSeparateProvision Then
			If DocumentData.Assignments.Count() = 1 Then
				CommandDetails.Insert("Purpose", DocumentData.Assignments[0]);
				GenerationByReferenceTMClient.OpenBackupWizard(CommandDetails);
			Else
				CommandDetails.Insert("Assignments", DocumentData.Assignments);
				GenerationByReferenceTMClient.OpenMassBackupWizard(CommandDetails);
			EndIf;
		Else
			SupplyClient.ReportAbsenceOfGoodsForSeparateProvision();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProvidingACopyOfTheString(Command)
	
	CopyTSLines("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure SoftwareInsertRows(Command)
	
	GetLinesFromClipboard("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure TheProvisionToSplitTheString(Command)
	
	BreakTSString("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure ToClarifyThePreviousMaterial(Command)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	If CurrentData = Undefined Or Not ThereAreMaterialSpecifications Then
		Return;
	EndIf;
	
	ProductionManagementClient.GoToAutoSelectLineThatYouWantToSpecify(Object,
		ThisObject, "SupplyWithMaterialsAndWorks", CurrentData.LineNumber, -1);
	
EndProcedure

&AtClient
Procedure EnsuringToClarifyTheMaterialIsAsFollows(Command)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	If CurrentData = Undefined Or Not ThereAreMaterialSpecifications Then
		Return;
	EndIf;
	
	ProductionManagementClient.GoToAutoSelectLineThatYouWantToSpecify(Object,
		ThisObject, "SupplyWithMaterialsAndWorks", CurrentData.LineNumber, 1);
	
EndProcedure

&AtClient
Procedure ToClarifyASideProductOfThePrevious(Command)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	If CurrentData = Undefined Or Not ThereAreSideProductSpecifications Then
		Return;
	EndIf;
	
	ProductionManagementClient.GoToAutoSelectLineThatYouWantToSpecify(Object,
		ThisObject, "SideAndIntermediateRelease", CurrentData.LineNumber, -1);
	
EndProcedure

&AtClient
Procedure ProvisionSpecifyTheByProductAsFollows(Command)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	If CurrentData = Undefined Or Not ThereAreSideProductSpecifications Then
		Return;
	EndIf;
	
	ProductionManagementClient.GoToAutoSelectLineThatYouWantToSpecify(Object,
		ThisObject, "SideAndIntermediateRelease", CurrentData.LineNumber, 1);
	
EndProcedure

&AtClient
Procedure SecurityShowStandards(Command)
	
	SavedInSettingsDataModified = True;
	
	ShowStandardsMaterials = Not ShowStandardsMaterials;
	ShowStandardsWhenChangingOnServer("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure ProvisionShowAnalogues(Command)
	
	ShowAnalogues = Not ShowAnalogues;
	If RightToReadSubstitutes And ShowAnalogues And Not Object.WorkPlanning Then
		NotePresenceOfAnalogues();
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "ShowAnalogues");
	
EndProcedure

&AtClient
Procedure SoftwareToPickUpAnalogs(Command)
	
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.ProductionStage2_2.Form.DocumentForm.Command.SoftwareToPickUpAnalogs");

	OpenSelectionOfAnalogues();
	
EndProcedure

&AtClient
Procedure ReplaceProvisionsWithAnalogues(Command)
	
	Replace_With_Analogues();
	
EndProcedure

&AtClient
Procedure SoftwareForCompletingTheFEFOSeries(Command)
	
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
Procedure SupplyFillInTheWarehouseInTheSelectedLines(Command)
	
	SelectedRows = New Array;
	For Each RowID In Items.SupplyWithMaterialsAndWorks.SelectedRows Do
		
		CurrentData = Object.SupplyWithMaterialsAndWorks.FindByID(RowID);
		If CurrentData.SupplyOption =
				PredefinedValue("Enum.SupplyOptions.TransferedEarlier") Then
			Continue;
		EndIf;
		
		SelectedRows.Add(RowID);
		
	EndDo;
	
	If WarehousesClient.CheckPossibilityOfFillingWarehousesInTablePart(
								Object,
								Object.SupplyWithMaterialsAndWorks,
								NStr("vi = 'Cung cấp nguyên vật liệu và công việc';
									|ru = 'Обеспечение материалами и работами';
									|en = 'Supply with materials and works'; fa = 'تأمین با مواد و کارها';
									|it = 'Fornitura di materiali e lavoro';
									|pl = 'Zaopatrzenie w materiały i pracę';
									|tr = 'Malzemelerin ve işlerin karşılanması'"),
								SelectedRows) Then
		
		Filter = New Structure;
		Filter.Insert("IsFolder", False);
		If RecordOfPerformed Then
			
			DepartmentFilter = Undefined;
			For Each Id In SelectedRows Do
				RowData = Object.SupplyWithMaterialsAndWorks.FindByID(Id);
				If DepartmentFilter = Undefined Then
					DepartmentFilter = RowData.Department;
				ElsIf DepartmentFilter <> RowData.Department Then
					ShowMessageBox(,NStr("vi = 'Trong chứng từ đã chọn các dòng có bộ phận khác nhau. Không thể điền trường ""Kho bãi""';
										|ru = 'В документе выбраны строки разных подразделений. Поле ""Склад"" не может быть заполнено';
										|en = 'Rows with different business units are selected in the document. Cannot populate the ""Warehouse"" field'; fa = 'Rows with different business units are selected in the document. Cannot populate the ""Warehouse"" field';
										|it = 'Nel documento sono state selezionate righe di suddivisioni diverse. Il campo ""Magazzino"" non può essere completato';
										|pl = 'W dokumencie wybrano wiersze różnych działów. Pole ""Magazyn"" nie może być wypełnione';
										|tr = 'Belgede farklı departmanların satırları seçildi. ""Ambar"" alanı doldurulamaz'"));
					Return;
				EndIf;
			EndDo;
			
			Filter.Insert("Department", DepartmentFilter);
			Filter.Insert("ShopFloorStockroom",	True);
			
		EndIf;
		
		ParametersStructure = New Structure("Filter,ChoiceFoldersAndItems", Filter, FoldersAndItemsUse.Items);
		
		AdditionalParameters =  New Structure("SelectedRows", SelectedRows);
		CallbackDescription = New CallbackDescription("SupplyFillInTheWarehouseInTheSelectedLinesCompletion",
			ThisObject,
			AdditionalParameters);
		
		OpenForm("Catalog.Warehouses.ChoiceForm",
			ParametersStructure,
			ThisObject,
			,
			,
			,
			CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyFillInTheWarehouseInTheSelectedLinesCompletion(SelectedWarehouse, AdditionalParameters) Export
	
	SelectedRows = AdditionalParameters.SelectedRows;
	
	If ValueIsFilled(SelectedWarehouse) Then
		
		FilledWithRows = FillWarehouseInSelectedLinesOnServer(SelectedRows, SelectedWarehouse);
		WarehousesClient.ShowNotificationAboutFillingOfWarehouseInTablePart(SelectedWarehouse, FilledWithRows, SelectedRows.Count());
		
	EndIf;

EndProcedure

&AtClient
Procedure SoftwareToChooseAccordingToSpecification(Command)
	
	FormParameters = New Structure;
	
	ItemData_3 = ProductData_4();
	ItemData_3.Count = CountPlan;
	
	FillPropertyValues(ItemData_3, ProductionBatchData,
		"ReferenceOrder, ProductionStart, ProductionDispatcherBusinessUnit, LineOfBusiness, BillOfMaterials, Products, Characteristic");
	
	FormParameters.Insert("ItemData_3", ItemData_3);
	FormParameters.Insert("Stage", Object.Stage);
	FormParameters.Insert("FirstOperationID", FirstOperationID);
	FormParameters.Insert("LastOperationID", LastOperationID);
	FormParameters.Insert("ShowQuantityMatched", True);
	FormParameters.Insert("ColumnTitleQuantitySelected", NStr("vi = 'Trong công đoạn';
																|ru = 'В этапе';
																|en = 'In stage'; fa = 'In stage';
																|it = 'Nella fase';
																|pl = 'Na etapie';
																|tr = 'Aşamada'"));
	FormParameters.Insert("SearchStructureSelectedMaterials", New Structure("Products,Characteristic"));
	FormParameters.Insert("AddressSelectedMaterials", PlaceMaterialsForSelectionAccordingToSpecificationInRepository());
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("ReferenceOrder", Object.ReferenceOrder);
	FormParameters.Insert("Basis", Object.Ref);
	FormParameters.Insert("UseProductionAccordingToSpecification", Not ProductionBatchData.DynamicStructure);
	FormParameters.Insert("IntermediateSemiFinishedProducts", ProductDataManagementClientServer.IntermediateSemiFinishedProductsGet());
	
	OpenForm("Catalog.BillsOfMaterials.Form.SelectMaterialsByBOM",
			FormParameters,
			ThisObject, 
			UUID,,,, 
			FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SpecifySeriesOfConsumedMaterialsClick(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ProductionStage2_2.Form.DocumentForm.SpecifySeriesOfConsumedMaterialsClick");
	
	FillInPlaceMaterialsForSpecifyingSeriesInRepository(2);
	
	CallbackDescription = New CallbackDescription("SpecifySeriesOfConsumedMaterialsClickCompletion", ThisObject);
	OpenFlowSeriesEditingForm(CallbackDescription);
	
EndProcedure

&AtClient
Procedure HowToFillInTheCalculationArticle(Command)
	
	FillInTheCostingItem("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure ProvisionToCancelTheSelectedRow(Command)
	
	CancelSelectedLines("SupplyWithMaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure SoftwareToHideCancelledLines(Command)
	
	FulfillmentHideCanceledLines =  Not FulfillmentHideCanceledLines;
	
	If FulfillmentHideCanceledLines Then
		Items.SupplyWithMaterialsAndWorks.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.SupplyWithMaterialsAndWorks.RowFilter = Undefined;
	EndIf;
	
	Items.SoftwareToHideCancelledLines.Check = FulfillmentHideCanceledLines;
	
EndProcedure

#EndRegion

#Region Pm_CommandsConsumptionOfMaterialsAndWorks

&AtClient
Procedure MaterialAndWorkConsumptionCopyLines(Command)
	
	CopyTSLines("MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure MaterialAndWorkConsumptionInsertLines(Command)
	
	GetLinesFromClipboard("MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure ConsumptionOfMaterialsAndWorksFillInAccordingToTheDataProvidedByTheSoftware(Command)
	
	If Object.MaterialsAndWorksConsumption.Count() <> 0 Then
		QueryText = NStr("vi = 'Điền lại phần bảng theo dữ liệu đảm bảo
									|có tính đến nguyên vật liệu không tiêu hao?';
									|ru = 'Перезаполнить табличную часть по данным обеспечения
									|с учетом неизрасходованных материалов?';
									|en = 'Refill the table according to supply data 
									|considering unused materials?'; fa = 'Refill the table according to supply data 
									|considering unused materials?';
									|it = 'Ricompilare la parte tabulare secondo i dati di approvvigionamento
									|tenendo conto dei materiali non utilizzati?';
									|pl = 'Wypełnić ponownie tabelaryczną część wg danych zaopatrzenia
									|z uwzględnieniem niezużytych materiałów?';
									|tr = 'Sarf edilmeyen malzemeler dikkate alınarak
									|temin verilerine göre tablo bölümü yeniden doldurulsun mu?'");
		CallbackDescription = New CallbackDescription("ConsumptionOfMaterialsAndWorksFillInAccordingToTheDataProvidedByTheSoftwareCompletion", ThisObject);
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Điền';
													|ru = 'Заполнить';
													|en = 'Fill'; fa = 'پرکردن';
													|it = 'Compilare';
													|pl = 'Fill';
													|tr = 'Doldur'"));
		ButtonsList.Add(DialogReturnCode.Cancel);
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList); 
	Else
		ConsumptionOfMaterialsAndWorksFillInAccordingToTheDataProvidedByTheSoftwareCompletion(DialogReturnCode.Yes, Undefined);
	EndIf; 
	
EndProcedure

&AtClient
Procedure MaterialAndWorkConsumptionSplitLine_3(Command)
	
	BreakTSString("MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure MaterialAndWorkConsumptionFillInTheExpenseDate(Command)
	
	If Items.MaterialsAndWorksConsumption.SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Bạn phải chọn nguyên vật liệu cần điền vào ngày tiêu thụ.';
							|ru = 'Необходимо выбрать материалы, для которых необходимо заполнить дату расхода.';
							|en = 'Select the materials for which it is required to populate the consumption date.'; fa = 'Select the materials for which it is required to populate the consumption date.';
							|it = 'È necessario scegliere i materiali per i quali è necessario compilare la data di consumo.';
							|pl = 'Należy wybrać materiały, dla których trzeba wypełnić datę wydatkowania.';
							|tr = 'Sarfiyat tarihinin doldurulması gereken malzemeleri seçmeniz gerekmektedir.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	Notification = New CallbackDescription("MaterialAndWorkConsumptionFillInTheExpenseDateCompletion", ThisObject, Items.MaterialsAndWorksConsumption.SelectedRows);
	TMCommonUseClient.EnterDateWithControlOfEmptyValue(
			StartOfDayCurSessionDate(), 
			NStr("vi = 'Nhập ngày tiêu thụ nguyên vật liệu (nhân công)';
				|ru = 'Введите дату расхода материалов (работ)';
				|en = 'Enter the material (work) consumption date'; fa = 'Enter the material (work) consumption date';
				|it = 'Inserite la data di consumo materiali (lavori)';
				|pl = 'Wprowadź datę wydatkowania materiałów (pracy)';
				|tr = 'Malzemelerin (işlerin) sarfiyat tarihini girin'"), 
			DateFractions.Date, Notification);
	
EndProcedure

&AtClient
Procedure ConsumptionOfMaterialsAndWorksPickUpGoods(Command)
	
	OpensGoodsSelection("MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure ConsumptionOfMaterialsAndWorksFillInTheCalculationArticle(Command)
	
	FillInTheCostingItem("MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumption_ImportDataFromPDT(Command)
	
	ImportDataFromPDT("MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure ConsumptionOfMaterialsAndWorksSearchByBarcode(Command)
	
	SearchByBarcode("MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksConsumption_GetWeight(Command)
	
	GetWeight("MaterialsAndWorksConsumption");
	
EndProcedure

&AtClient
Procedure TheConsumptionOfMaterialsAndWorksShouldBeSupplementedAccordingToTheDataProvidedByTheSoftware(Command)
	
	FillInConsumptionOfMaterialsAndWorkOnProvisionDataOnServer(1);
	
EndProcedure

#EndRegion

#Region Pm_CommandsSaveMaterials

&AtClient
Procedure SavingMaterialsCopyLines(Command)

	CopyTSLines("UnusedMaterials");
	
EndProcedure

&AtClient
Procedure SaveMaterialsInsertLines(Command)
	
	GetLinesFromClipboard("UnusedMaterials");
	
EndProcedure

&AtClient
Procedure SavingMaterialsSplitALine(Command)
	
	BreakTSString("UnusedMaterials");
	
EndProcedure

&AtClient
Procedure SavingMaterialsFillInUnspent(Command)
	
	FillWithUnspentMaterialsOnServer();
	
EndProcedure

&AtClient
Procedure UnusedMaterials_ImportDataFromPDT(Command)
	
	ImportDataFromPDT("UnusedMaterials");
	
EndProcedure

&AtClient
Procedure SavingMaterialsBarcodeSearch(Command)
	
	SearchByBarcode("UnusedMaterials");
	
EndProcedure

&AtClient
Procedure UnusedMaterials_GetWeight(Command)
	
	GetWeight("UnusedMaterials");
	
EndProcedure

&AtClient
Procedure MaterialSavingFillInExpenseItem(Command)
	
	If Items.UnusedMaterials.SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Bạn phải chọn các chứng từ mà bạn muốn điền vào dạng chi phí.';
							|ru = 'Необходимо выбрать материалы, для которых требуется заполнить статью расходов.';
							|en = 'Select materials to fill in the expense item for.'; fa = 'Select materials to fill in the expense item for.';
							|it = 'È necessario scegliere i materiali per i quali è necessario compilare una voce di spesa.';
							|pl = 'Należy wybrać materiały, dla których trzeba wypełnić pozycję wydatków.';
							|tr = 'Gider kaleminin doldurulması gereken malzemeleri seçmeniz gerekmektedir.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	IDs = New Array();
	For Each RowID In Items.UnusedMaterials.SelectedRows Do
		RowData = Object.UnusedMaterials.FindByID(RowID);
		If Not RowData.ToExpenseAs Then
			Continue;
		EndIf;
		IDs.Add(RowID);
	EndDo;
	
	If IDs.Count() = 0 Then
		WarningText = NStr("vi = 'Không có chứng từ trong các dòng được tô sáng mà bạn cần điền vào dạng chi phí.';
							|ru = 'В выделенных строках отсутствуют материалы, для которых требуется заполнить статью расходов.';
							|en = 'There are no materials in the selected lines for which expense item population is required.'; fa = 'There are no materials in the selected lines for which expense item population is required.';
							|it = 'Nelle linee selezionate non ci sono materiali per i quali è necessario compilare una voce di spesa.';
							|pl = 'W zaznaczonych wierszach brak materiałów, dla których trzeba wypełnić pozycję wydatków.';
							|tr = 'Belirtilen satırlarda, gider kaleminin doldurulması gereken malzemeler bulunmamaktadır.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(ThisObject, Items.UnusedMaterialsExpenseItem, IDs);
	
EndProcedure

&AtClient
Procedure MaterialSavingFillInDate(Command)
	
	If Items.UnusedMaterials.SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Bạn phải chọn các chứng từ mà bạn muốn điền vào ngày chuyển (ghi giảm).';
							|ru = 'Необходимо выбрать материалы, для которых требуется заполнить дату передачи (списания).';
							|en = 'Select the materials for which it is required to populate the transfer (write-off) date.'; fa = 'Select the materials for which it is required to populate the transfer (write-off) date.';
							|it = 'È necessario scegliere i materiali per i quali è necessario compilare la data di trasferimento (cancellazione).';
							|pl = 'Należy wybrać materiały, dla których trzeba wypełnić datę przekazana (wyksięgowania)';
							|tr = 'Transfer (gider yazma) tarihinin doldurulması gereken malzemeleri seçmeniz gerekmektedir.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	Notification = New CallbackDescription("MaterialSavingFillInDateCompletion", ThisObject, Items.UnusedMaterials.SelectedRows);
	TMCommonUseClient.EnterDateWithControlOfEmptyValue(
			StartOfDayCurSessionDate(), 
			NStr("vi = 'Nhập ngày chuyển (ghi giảm)';
				|ru = 'Введите дату передачи (списания)';
				|en = 'Enter transfer (write-off) date'; fa = 'Enter transfer (write-off) date';
				|it = 'Inserire data di trasferimento (cancellazione)';
				|pl = 'Wybierz datę przekazana (wyksięgowania)';
				|tr = 'Transfer (gider yazma) tarihini girin '"),
			DateFractions.Date, Notification);
	
EndProcedure

&AtClient
Procedure SavingMaterialsSpecifyTheSeries(Command)
	
	OpenSelectionOfSeries("UnusedMaterials");
	
EndProcedure

#EndRegion

#Region Pm_CommandsOutputProducts

&AtClient
Procedure OutputItemsSplitLine_3(Command)
	
	BreakTSString("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProducts_PickUpProducts(Command)
	
	OpensGoodsSelection("ManufacturedProducts");
	
EndProcedure
 
&AtClient
Procedure OutputProductsSpecifyTheSeries_3(Command)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ManufacturedProducts, ThisObject);
	OpenSelectionOfSeries("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure OutputItemsFillInTheRecipient(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ProductionStage2_2.Form.DocumentForm.Command.OutputItemsFillInTheRecipient");	
	
	TSParameters = New Structure;
	TSParameters.Insert("NameTSForm"      , "ManufacturedProducts");
	TSParameters.Insert("NameTsObject"     , "ManufacturedProducts");
	TSParameters.Insert("PresentationOfTS" , NStr("vi = 'Sản phẩm giá trị ước tính';
													|ru = 'Изделия по рассчитываемой стоимости';
													|en = 'Products by calculated cost'; fa = 'محصولات بر اساس بهای محاسبه‌شده';
													|it = 'Prodotti in base al valore calcolato';
													|pl = 'Wyroby po szacowanej cenie';
													|tr = 'Hesaplanan maliyete göre nihai ürünler'"));
	
	If RecordOfPerformed Then
		DepartmentFilter = Undefined;
		For Each Id In Items.ManufacturedProducts.SelectedRows Do
			
			RowData = Object.ManufacturedProducts.FindByID(Id);
			
			If RowData.ToExpenseAs 
				Or RowData.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
				Continue;
			EndIf;
			
			If DepartmentFilter = Undefined Then
				DepartmentFilter = RowData.Department;
			ElsIf DepartmentFilter <> RowData.Department Then
				ShowMessageBox(,NStr("vi = 'Đã chọn các dòng có bộ phận khác nhau. Không thể thực hiện giao dịch.';
									|ru = 'Выбраны строки с разными подразделениями. Операция не может быть выполнена.';
									|en = 'Rows with different business units are selected. Cannot perform the operation.'; fa = 'Rows with different business units are selected. Cannot perform the operation.';
									|it = 'Sono state selezionate righe con suddivisioni diverse. L''operazione non può essere eseguita.';
									|pl = 'Wybrano wiersze z różnymi działami. Operacja nie może być wykonane.';
									|tr = 'Farklı departman türlerine sahip satırlar seçildi. İşlem gerçekleştirilemez.'"));
				Return;
			EndIf;
			
		EndDo;
		
		If DepartmentFilter <> Undefined Then
			Filter = New Structure;
			Filter.Insert("Department", DepartmentFilter);
			Filter.Insert("ShopFloorStockroom", True);
			TSParameters.Insert("Filter", Filter);
		EndIf;
	EndIf;
	
	CallbackDescription = New CallbackDescription("FillInRecipientCompletion", 
												   ThisObject, New Structure("TSParameters", TSParameters));
	
	ProductionClient.OpenRecipientSelectionForm(ThisObject, Object, TSParameters,, CallbackDescription); 
	
EndProcedure

&AtClient
Procedure OutputProductsChangeQuality(Command)
	
	TSName = "ManufacturedProducts";
	
	CurrentRow = Items[TSName].CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ChangeQuality");
	
	If ValueIsFilled(CurrentRow.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentRow.Characteristic);
	EndIf;
	If ValueIsFilled(CurrentRow.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentRow.Package);
	EndIf;
	
	AddActionsToStructureWhenChangingProducts(TSName, ThisObject, StructureOfActions);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName", TSName);
	
	CallbackDescription = New CallbackDescription("ChangeQualityCompletion", ThisObject, AdditionalParameters);
	
	WarehousesClient.ChangeQuality(CurrentRow, StructureOfActions, CachedValues, CallbackDescription);
	
EndProcedure

&AtClient
Procedure ManufacturedProducts_GetWeight(Command)
	
	GetWeight("ManufacturedProducts");
	
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
Procedure WeekendItemsToCancelTheSelectedRow(Command)
	
	CancelSelectedLines("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure OutputItemsHideCanceledLines(Command)
	
	FinishedProductsHideCanceledLines =  Not FinishedProductsHideCanceledLines;
	
	If FinishedProductsHideCanceledLines Then
		Items.ManufacturedProducts.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.ManufacturedProducts.RowFilter = Undefined;
	EndIf;
	
	Items.OutputItemsHideCanceledLines.Check = FinishedProductsHideCanceledLines;
	
EndProcedure

&AtClient
Procedure OutputItemsChangeQualityCancelLine(Command)
	
	CurrentRow = Items.ManufacturedProducts.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ManufacturedProducts, ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ChangeQuality");
	
	If ValueIsFilled(CurrentRow.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentRow.Characteristic);
	EndIf;
	If ValueIsFilled(CurrentRow.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentRow.Package);
	EndIf;
	
	AddActionsToStructureWhenChangingProducts("ManufacturedProducts", ThisObject, StructureOfActions);
			
	AdditionalParameters = New Structure("TSName", "ManufacturedProducts");
	CallbackDescription = New CallbackDescription(
		"Products_ChangeQualityCancelLineCompletion",
		ThisObject,
		AdditionalParameters);
	
	WarehousesClient.ChangeQuality(CurrentRow, StructureOfActions, CachedValues, CallbackDescription);
	
EndProcedure

&AtClient
Procedure OutputProductsFillInPrices(Command)
	
	FillInPricesByPriceKind("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure OutputProductsFillInThePricesAccordingToTheCalculation_3(Command)

	CurrentData = Items.ManufacturedProducts.CurrentData;
	If CurrentData = Undefined Then
		Return
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RowsIDs", 
		TMCommonUseClientServer.Array(CurrentData.GetID(),
			False));

	FormParameters = New Structure;
	FilterStructure1 = New Structure();
	FilterStructure1.Insert("Date", Object.Date);
	FilterStructure1.Insert("Organization", Object.Organization);
	FilterStructure1.Insert("ProductionDispatcherBusinessUnit", Object.Department);
	FilterStructure1.Insert("Product", CurrentData.Products);
	CostObjects = New Array();
	CostObjects.Add(Object.ReferenceOrder);
	If ValueIsFilled(Object.BillOfMaterials) Then
		CostObjects.Add(Object.BillOfMaterials);
	EndIf;
	FilterStructure1.Insert("CostObjects", CostObjects);
	FilterStructure1.Insert("Characteristic", CurrentData.Characteristic);
	FilterStructure1.Insert("Purpose", CurrentData.Purpose);
	FormParameters.Insert("FilterStructure1", FilterStructure1);
	
	FormParameters.Insert("State", 
		PredefinedValue("Enum.StatesOfStandardCostEstimateCalculation.Calculated"));
	
	OpenForm("Document.StandardCosting2_2.Form.ChoiceForm", FormParameters,,,,, 
		New CallbackDescription("CompletionOfPlanningCalculationSelection", ThisObject, AdditionalParameters),
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure CompletionOfPlanningCalculationSelection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillInPlanningCalculationsAndPricesOnServer(AdditionalParameters.RowsIDs, 
		Result);
		
EndProcedure

#EndRegion

#Region Pm_CommandsByProducts

&AtClient
Procedure SideProductsSplitTheLine(Command)
	
	BreakTSString("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideOfTheProductToPickUpTheGoods(Command)
	
	OpensGoodsSelection("SideAndIntermediateRelease");
	
EndProcedure
 
&AtClient
Procedure SideOfTheProductToSpecifySeries(Command)
	
	OpenSelectionOfSeries("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure ByProductsFillInTheRecipient(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ProductionStage2_2.Form.DocumentForm.Command.ByProductsFillInTheRecipient");	
	
	TSParameters = New Structure;
	TSParameters.Insert("NameTSForm"      , "SideAndIntermediateRelease");
	TSParameters.Insert("NameTsObject"     , "SideAndIntermediateRelease");
	TSParameters.Insert("PresentationOfTS" , NStr("vi = 'Sản phẩm phụ và xuất xưởng trung gian với giá trị cố định';
													|ru = 'Побочный и промежуточный выход по фиксированной стоимости';
													|en = 'Side and intermediate product at fixed cost'; fa = 'محصول فرعی و میانی با بهای ثابت';
													|it = 'Uscita collaterale e intermedia ad un costo fisso';
													|pl = 'Produkcja poboczna i pośrednia po stałej cenie';
													|tr = 'Sabit maliyetle yan ve ara ürün çıkışı'"));
	
	If RecordOfPerformed Then
		
		DepartmentFilter = Undefined;
		For Each Id In Items.SideAndIntermediateRelease.SelectedRows Do
			
			RowData = Object.SideAndIntermediateRelease.FindByID(Id);
			
			If RowData.ToExpenseAs 
				Or RowData.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
				Continue;
			EndIf;
			
			If DepartmentFilter = Undefined Then
				DepartmentFilter = RowData.Department;
			ElsIf DepartmentFilter <> RowData.Department Then
				ShowMessageBox(,NStr("vi = 'Đã chọn các dòng có bộ phận khác nhau. Không thể thực hiện giao dịch.';
									|ru = 'Выбраны строки с разными подразделениями. Операция не может быть выполнена.';
									|en = 'Rows with different business units are selected. Cannot perform the operation.'; fa = 'Rows with different business units are selected. Cannot perform the operation.';
									|it = 'Sono state selezionate righe con suddivisioni diverse. L''operazione non può essere eseguita.';
									|pl = 'Wybrano wiersze z różnymi działami. Operacja nie może być wykonane.';
									|tr = 'Farklı departman türlerine sahip satırlar seçildi. İşlem gerçekleştirilemez.'"));
				Return;
			EndIf;
			
		EndDo;
		
		If DepartmentFilter <> Undefined Then
			Filter = New Structure;
			Filter.Insert("Department", DepartmentFilter);
			Filter.Insert("ShopFloorStockroom", True);
			TSParameters.Insert("Filter", Filter);
		EndIf;
		
	EndIf;
	
	CallbackDescription = New CallbackDescription("FillInRecipientCompletion", 
												   ThisObject, New Structure("TSParameters", TSParameters));
	
	ProductionClient.OpenRecipientSelectionForm(ThisObject, Object, TSParameters,, CallbackDescription); 
	
EndProcedure

&AtClient
Procedure ByProductsChangeQuality(Command)
	
	TSName = "SideAndIntermediateRelease";
	
	CurrentRow = Items[TSName].CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ChangeQuality");
	
	If ValueIsFilled(CurrentRow.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentRow.Characteristic);
	EndIf;
	If ValueIsFilled(CurrentRow.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentRow.Package);
	EndIf;
	
	AddActionsToStructureWhenChangingProducts(TSName, ThisObject, StructureOfActions);
			
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName", TSName);
			
	CallbackDescription = New CallbackDescription("ChangeQualityCompletion", ThisObject, AdditionalParameters);
	
	WarehousesClient.ChangeQuality(CurrentRow, StructureOfActions, CachedValues, CallbackDescription);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateRelease_GetWeight(Command)
	
	GetWeight("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure ByProductsFillInPrices(Command)
	
	FillInPricesByPriceKind("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideItemsCopyLines(Command)
	
	CopyTSLines("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure ByProductsInsertRows_3(Command)
	
	GetLinesFromClipboard("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure ByProductsCancelSelectedRows(Command)
	
	CancelSelectedLines("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideItemsHideCanceledLines(Command)
	
	SideProductsHideCanceledLines = Not SideProductsHideCanceledLines;
	
	If SideProductsHideCanceledLines Then
		Items.SideAndIntermediateRelease.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.SideAndIntermediateRelease.RowFilter = Undefined;
	EndIf;
	
	Items.SideItemsHideCanceledLines.Check = SideProductsHideCanceledLines;
	
EndProcedure

&AtClient
Procedure ByProductsChangeQualityCancelLine(Command)
	
	CurrentRow = Items.SideAndIntermediateRelease.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.SideAndIntermediateRelease, ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("ChangeQuality");
	
	If ValueIsFilled(CurrentRow.Characteristic) Then
		StructureOfActions.Insert("FillInDescriptionOfPoorQualityProduct", CurrentRow.Characteristic);
	EndIf;
	If ValueIsFilled(CurrentRow.Package) Then
		StructureOfActions.Insert("FillInPackagingOfLowQualityGoods", CurrentRow.Package);
	EndIf;
	
	AddActionsToStructureWhenChangingProducts("SideAndIntermediateRelease", ThisObject, StructureOfActions);
			
	AdditionalParameters = New Structure("TSName", "SideAndIntermediateRelease");
	CallbackDescription = New CallbackDescription(
		"Products_ChangeQualityCancelLineCompletion",
		ThisObject,
		AdditionalParameters);
	
	WarehousesClient.ChangeQuality(CurrentRow, StructureOfActions, CachedValues, CallbackDescription);
	
EndProcedure

&AtClient
Procedure SideProductsPopulateCostingItem(Command)
	
	FillInTheCostingItem("SideAndIntermediateRelease");
	
EndProcedure

#EndRegion

#Region Pm_CommandsTypesOfWorkCenters

&AtClient
Procedure AddAlternativeViewOfRCCommand(Command)
	
	CurrentData = Items.WorkCenterTypes.CurrentData;
	
	ProductionProcessEditorClient.AddAnAlternativeTypeOfRC(
		CurrentData, 
		WorkCenterTypes, 
		Items.WorkCenterTypes,
		Object.OperatingProcedureOfWorkCenterTypes,
		ThereIsSynchronousLoad,
		True);
	
EndProcedure

#EndRegion

#Region Pm_CommandsLaborCosts

&AtClient
Procedure TheEffortToSplitTheString(Command)
	
	BreakTSString("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsInsertLines(Command)
	
	GetLinesFromClipboard("LaborCosts");
	
EndProcedure

&AtClient
Procedure TheEffortToCopyRows(Command)
	
	CopyTSLines("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsFillInThePerformersInTheHighlightedLines(Command)
	
	SelectedRows = Items.LaborCosts.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		ClearMessages();
		WarningText = NStr("vi = 'Bạn phải chọn các dòng để điền vào người thực hiện.';
							|ru = 'Необходимо выбрать строки для заполнения исполнителей.';
							|en = 'Select lines to fill in assignees.'; fa = 'Select lines to fill in assignees.';
							|it = 'È necessario scegliere le righe per la compilazione degli esecutori.';
							|pl = 'Należy wybrać wiersze, aby wprowadzić wykonawców';
							|tr = 'Atananların doldurulması için satırları seçmeniz gerekmektedir.'");
		CommonClientServer.MessageToUser(WarningText);
		Return;
	EndIf;
	
	FirstRow = Object.LaborCosts.FindByID(SelectedRows[0]);
	DepartmentFilter = FirstRow.Department;
	CurrentPerformer = FirstRow.Performer;
	
	For IndexOf = 1 To SelectedRows.UBound() Do
		
		RowData = Object.LaborCosts.FindByID(SelectedRows[IndexOf]);
		
		If DepartmentFilter <> Undefined
			And DepartmentFilter <> RowData.Department Then
			DepartmentFilter = Undefined;
		EndIf;
		
		If CurrentPerformer <> Undefined
			And (TypeOf(CurrentPerformer) <> TypeOf(RowData.Performer)
				Or CurrentPerformer <> RowData.Performer) Then
			CurrentPerformer = Undefined;
		EndIf;
		
	EndDo;
	
	ProductionClient.OpenArtistSelectionForm(
		Object.Organization,
		DepartmentFilter,
		CurrentPerformer,
		?(ValueIsFilled(Object.ActualStageStart),
							Object.ActualStageStart,
							Object.Date),
		,
		New CallbackDescription("FillInPerformersCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure LaborCostsFillInTheCalculationArticleInTheHighlightedLines(Command)
	
	FillInTheCostingItem("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsShowStandards(Command)
	
	SavedInSettingsDataModified = True;
	
	ShowStandardsLaborCosts = Not ShowStandardsLaborCosts;
	ShowStandardsWhenChangingOnServer("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsCancelSelectedLines(Command)
	
	CancelSelectedLines("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCosts_HideCanceledRows(Command)
	
	LaborCostsHideCanceledLines =  Not LaborCostsHideCanceledLines;
	
	If LaborCostsHideCanceledLines Then
		Items.LaborCosts.RowFilter = New FixedStructure("Canceled", False);
	Else
		Items.LaborCosts.RowFilter = Undefined;
	EndIf;
	
	Items.LaborCosts_HideCanceledRows.Check = LaborCostsHideCanceledLines;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure PostAndClose(Command)
	
	If (RecordOfPerformed
			Or Object.WorkPlanning)
		And FlowSeriesMustBeSpecified() Then
		CallbackDescription = New CallbackDescription("HoldAndCloseReflectionOfCompletedCompletion", ThisObject);
		OpenFlowSeriesEditingForm(CallbackDescription);
	Else
		TMCommonUseClient.PostAndClose(ThisObject, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	If (RecordOfPerformed
			Or Object.WorkPlanning)
		And Object.Posted
		And FlowSeriesMustBeSpecified() Then
		CallbackDescription = New CallbackDescription("WriteDocumentReflectingCompletedCompletion", ThisObject);
		OpenFlowSeriesEditingForm(CallbackDescription);
	Else
		TMCommonUseClient.Write(ThisObject, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	If (RecordOfPerformed
			Or Object.WorkPlanning)
		And FlowSeriesMustBeSpecified() Then
		CallbackDescription = New CallbackDescription("ConductDocumentReflectionOfCompletedProject", ThisObject);
		OpenFlowSeriesEditingForm(CallbackDescription);
	Else
		TMCommonUseClient.Post(ThisObject, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInRecipientCompletion(ValueSelected, AdditionalParameters) Export
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;	
	
	TSParameters      = AdditionalParameters.TSParameters;
	SelectedRows = Items[TSParameters.NameTSForm].SelectedRows;
	
	FillInRecipientOnServer(TSParameters, SelectedRows, ValueSelected);
	
EndProcedure

&AtServer
Procedure FillInRecipientOnServer(TSParameters, SelectedRows, Recipient)
	
	NameTsObject = TSParameters.NameTsObject;
	NameTSForm  = TSParameters.NameTSForm;
	
	ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	AddQualityControlActionsToStructure(NameTsObject, StructureOfActions, CacheQualityControl);
	
	SeriesSpecificationParameters = ThisObject[StageEditingParameters.PropsNameParametersForSpecifyingSeries];
	
	SeriesVerificationParameters = New Structure;
	SeriesVerificationParameters.Insert("Warehouse"                    , Recipient);
	SeriesVerificationParameters.Insert("SeriesSpecificationParameters"   , SeriesSpecificationParameters[NameTSForm]);
	
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	RowsToProcess = New Array();
	
	For Each RowID In SelectedRows Do
		RowData = Object[NameTsObject].FindByID(RowID);
		RowData.Recipient = Recipient;
		RowsToProcess.Add(RowData);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[NameTsObject],
		ValuesInCache);
	
	AfterChangingTSStringsProgrammaticallyOnServer(NameTSForm, SelectedRows);
	
EndProcedure

&AtClient
Procedure ChangeQualityCompletion(CurrentRow, AdditionalParameters) Export

	StructureOfActions = New Structure;
	
	ProductionClientServer.AddToStructureActionsCheckFillProductionWarehouse(
		CurrentRow.Department, StructureOfActions, "Recipient");
	
	StructureOfActions.Insert("FillInShopPantryAttribute");
	StructureOfActions.Insert(
		"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, ValuesInCache);
	
	RowsArray = New Array;
	RowsArray.Add(CurrentRow.GetID());
	
	AfterChangingTSStringsProgrammaticallyOnServer(AdditionalParameters.TSName, RowsArray);
	
EndProcedure

&AtServer                                                     
Procedure AfterChangingQualityAndCancelingRow(TSName, NewlineIds, IdsOfOldLine)
	
	TableRow = Object[TSName].FindByID(NewlineIds);
	
	StructureOfActions = New Structure;
	
	ProductionClientServer.AddToStructureActionsCheckFillProductionWarehouse(
		TableRow.Department, StructureOfActions, "Recipient");	
		
	ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
	BatchProcessingOfTablePartServer.ProcessTSString(TableRow, StructureOfActions, ValuesInCache);
	
	RowsArray = New Array;
	RowsArray.Add(NewlineIds);
	RowsArray.Add(IdsOfOldLine);
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsArray);	
	
EndProcedure		

&AtClient
Procedure ReflectTheNumberOfHoursOfWH(Command)
	
	ClearMessages();
	
	If Object.NumberOfPackagesReal = 0 Then
		CommonClient.MessageToUser(
			CommonClientServer.FillingErrorText(,, NStr("vi = 'Đã thực hiện';
														|ru = 'Выполнено';
														|en = 'Completed'; fa = 'تکمیل‌شده';
														|it = 'Completato';
														|pl = 'Completed';
														|tr = 'Gerçekleştirildi'")),,
			"NumberOfPackagesReal",
			"Object");
		Return;
	ElsIf Object.NumberOfPackagesPlan = 0 Then
		CommonClient.MessageToUser(
			CommonClientServer.FillingErrorText(,, NStr("vi = 'Dự tính';
														|ru = 'Запланировано';
														|en = 'Scheduled'; fa = 'برنامه‌ریزی‌شده';
														|it = 'Pianificato';
														|pl = 'Scheduled';
														|tr = 'Planlandı'")),,
			"NumberOfPackagesPlan",
			"Object");
		Return;
	EndIf;
	
	LineSubdivision = Undefined;
	If Object.LaborCosts.Count() <> 0
			And Not (UseOperationManagement And Object.OperationAsOutputReference)
			And ThereAreLaborCostsWithEmptyExecutor(LineSubdivision) Then 
			
		ProductionClient.OpenArtistSelectionForm(
			Object.Organization,
			LineSubdivision,
			Object.Performer,
			Object.Date,
			,
			New CallbackDescription("ReflectNumberOfWHFactAfterQuestion", ThisObject));
	Else
		
		ReflectNumberOfAvailableWHOnServer(Undefined);
		ShowUserNotification(NStr("vi = 'Giao dịch đã kết thúc';
									|ru = 'Операция завершена';
									|en = 'Operation is complete'; fa = 'عملیات تکمیل شد';
									|it = 'Operazione conclusa';
									|pl = 'Operacja została zakończona.';
									|tr = 'İşlem tamamlandı'"),,,PictureLib.Information32);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure ReflectNumberOfWHFactAfterQuestion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		SelectedPerformer = Result;
		If SelectedPerformer <> Object.Performer And ValueIsFilled(Object.Performer) Then
			Object.Performer = Undefined; 
		EndIf;
	Else
		SelectedPerformer = Object.Performer;
	EndIf;
	
	ReflectNumberOfAvailableWHOnServer(SelectedPerformer);
	ShowUserNotification(NStr("vi = 'Giao dịch đã kết thúc';
								|ru = 'Операция завершена';
								|en = 'Operation completed'; fa = 'Operation completed';
								|it = 'Operazione conclusa';
								|pl = 'Operacja została zakończona.';
								|tr = 'İşlem tamamlandı'"),,,PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure ReflectTheAmountCanceledByWH(Command)
	
	ClearMessages();
	
	If Object.NumberOfPackagesCanceled = 0 Then
		CommonClient.MessageToUser(
			CommonClientServer.FillingErrorText(,, NStr("vi = 'Đã hủy bỏ';
														|ru = 'Отменено';
														|en = 'Canceled'; fa = 'لغوشده';
														|it = 'Annullato';
														|pl = 'Anulowano';
														|tr = 'İptal edildi'")),,
			"NumberOfPackagesCanceled",
			"Object");
		Return;
	ElsIf Object.NumberOfPackagesPlan = 0 Then
		CommonClient.MessageToUser(
			CommonClientServer.FillingErrorText(,, NStr("vi = 'Dự tính';
														|ru = 'Запланировано';
														|en = 'Scheduled'; fa = 'برنامه‌ریزی‌شده';
														|it = 'Pianificato';
														|pl = 'Zaplanowano';
														|tr = 'Planlandı'")),,
			"NumberOfPackagesPlan",
			"Object");
		Return;
	EndIf;
	
	ShowInputValue(
		New CallbackDescription("SelectCancellationReasonCompletion", ThisObject),,
		NStr("vi = 'Nguyên nhân hủy bỏ';
			|ru = 'Причина отмены';
			|en = 'Cancellation reason'; fa = 'دلیل لغو';
			|it = 'Causa di annullamento';
			|pl = 'Przyczyna anulowania';
			|tr = 'İptal nedeni'"),
		Type("CatalogRef.ReasonsForProductionCancellation"));
	
EndProcedure

&AtClient
Procedure SelectCancellationReasonCompletion(CancellationReason, AdditionalParameters) Export
	
	ReflectAmountOfCancelledWHOnServer(CancellationReason);
	ShowUserNotification(NStr("vi = 'Giao dịch đã kết thúc';
								|ru = 'Операция завершена';
								|en = 'Operation is complete'; fa = 'عملیات تکمیل شد';
								|it = 'Operazione conclusa';
								|pl = 'Operacja została zakończona.';
								|tr = 'İşlem tamamlandı'"),,, PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure PerformerOnChange(Item)

	If Not ValueIsFilled(Object.Performer) And Object.Performer <> Undefined Then
		Object.Performer = Undefined; // Historically, an unselected artist in this field corresponds to the value Undefined
	EndIf;

EndProcedure

&AtClient
Procedure PerformerStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)

	StandardProcessing = False;
	CallbackDescription = New CallbackDescription("PlannedPerformerIsBeginningOfSelectionCompletion", ThisObject);
	ProductionClient.OpenArtistSelectionForm(,,Object.Performer,,, CallbackDescription);

EndProcedure
 
&AtClient
Procedure PlannedPerformerIsBeginningOfSelectionCompletion(Result, AdditionalParameters) Export
	Object.Performer = Result;
EndProcedure

#EndRegion

#Region AttachableCommands

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
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


// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure Attachable_ExecuteOverriddenCommandOnServer(AdditionalParameters) Export
	
	FormEvents.ExecuteOverridableCommand(ThisObject, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.ObjectAttributesLock
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	ConfigureRightToEditAttributesOfPlannedGroup(ThisObject);
	ObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject);
EndProcedure
// End StandardSubsystems.ObjectAttributesLock

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

#EndRegion

#Region Private

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	InstallConditionalAppearanceSoftware();
	EstablishConditionalAppearanceConsumptionOfMaterialsAndWorks();
	SetConditionalAppearanceOfBuildingMaterials();
	SetConditionalAppearanceOfFinishedProduct();
	EstablishConditionalAppearanceOfLaborCosts();
	EstablishConditionalAppearanceTypesOfWorkCenters();
	EstablishConditionalAppearancePlannedDateOfReceipt();
	
EndProcedure

&AtServer
Procedure InstallConditionalAppearanceSoftware()
	
	DataPaths = New Structure;
	DataPaths.Insert("WorkPlanning", "Object.WorkPlanning");
	
	ItemsNames = ProductionFormManagement.NamesOfMaterialAndWorkSupportElements();
	ItemsNames.TSName = Items.SupplyWithMaterialsAndWorks.Name;
	ItemsNames.DateOfShipment = Items.DateOfShipment.Name;
	ItemsNames.TSDateOfShipment = Items.SupplyWithMaterialsAndWorksDateOfShipment.Name;
	ItemsNames.TSNumberOfPackages = Items.SupplyWithMaterialsAndWorksNumberOfPackages.Name;
	ItemsNames.TSProductsUnitOfMeasure = Items.SupplyWithMaterialsAndWorksProductsUnitOfMeasure.Name;
	ItemsNames.TSWithAssignment = Items.SupplyWithMaterialsAndWorksWithAssignment.Name;
	ItemsNames.TSCanceled = Items.SupplyWithMaterialsAndWorksCanceled.Name;
	ItemsNames.TSCancellationReason = Items.SupplyWithMaterialsAndWorksCancellationReason.Name;
	ItemsNames.TSSeries = Items.SupplyWithMaterialsAndWorksSeries.Name;
	ItemsNames.TSWarehouse = Items.SupplyWithMaterialsAndWorksWarehouse.Name;
	ItemsNames.TSBillOfMaterials = Items.SupplyWithMaterialsAndWorksBillOfMaterials.Name;
	ItemsNames.TSProductCostElement = Items.SupplyWithMaterialsAndWorksProductCostElement.Name;
	ItemsNames.TSCharacteristic = Items.SupplyWithMaterialsAndWorksCharacteristic.Name;
	ItemsNames.TSPurpose = Items.SupplyWithMaterialsAndWorksSupplyAssignment.Name;
	ItemsNames.TSProduced = Items.SupplyWithMaterialsAndWorksProduced.Name;
	ItemsNames.TSUnderRepairProduct = Items.SupplyWithMaterialsAndWorksUnderRepairProduct.Name;
	ItemsNames.TSUnderRepairVariant = Items.SupplyWithMaterialsAndWorksUnderRepairVariant.Name;
	ItemsNames.TSUnderRepairBatch = Items.SupplyWithMaterialsAndWorksUnderRepairBatch.Name;
	
	ProductionFormManagement.EstablishConditionalAppearanceOfProvisionOfMaterialsAndWorks(
		ThisObject, "Object", "SupplyWithMaterialsAndWorks", ItemsNames, DataPaths);
	
	// It is necessary to redefine the conditional design of the field Separately, set in the Production Management forms.Establish a conditional form of providing materials and works(...)
	If RecordOfPerformed Then
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksWithAssignment.Name);
		
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.SupplyOption");
		Filter.ComparisonType = DataCompositionComparisonType.Equal;
		Filter.RightValue = Enums.SupplyOptions.Ship;
		
		ListOfGoodsAndWork = New ValueList();
		ListOfGoodsAndWork.Add(Enums.ItemsTypes.OwnGoods);
		ListOfGoodsAndWork.Add(Enums.ItemsTypes.Work_5);
		
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.ItemsType");
		Filter.ComparisonType = DataCompositionComparisonType.InList;
		Filter.RightValue = ListOfGoodsAndWork;
		
		Item.Appearance.SetParameterValue("ReadOnly", False);
		
	EndIf;
	
	// Presentation appointment-stage
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksSupplyAssignment.Name);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.SupplyAssignment");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = New DataCompositionField("Object.Purpose");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Công đoạn hiện tại';
													|ru = 'Текущий этап';
													|en = 'Current step'; fa = 'مرحله جاری';
													|it = 'Fase corrente';
													|pl = 'Bieżący etap';
													|tr = 'Mevcut aşama'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksSupplyAssignment.Name);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.SupplyAssignment");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = New DataCompositionField("Object.Purpose");
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.WithAssignment");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ValueOfPredefinedText);
	
	// Blank mark at the Bill of Materials
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksBillOfMaterials.Name);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	Filter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.WorkPlanning");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = False;
	
	Filter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.Produced");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = False;
	
	Filter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.Canceled");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// No editing in the bill of Materials
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksBillOfMaterials.Name);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.WorkPlanning");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = True;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.Produced");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chỉ định cho công việc được sản xuất>';
													|ru = '<указывается для производимых работ>';
													|en = '<specified for works performed>'; fa = '<specified for works performed>';
													|it = '<specified for works performed>';
													|pl = '<specified for works performed>';
													|tr = '<yapılan iş için belirtilir>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	//
	
	ProductionFormManagement.SetConditionalAppearanceOfSecurityFields(
		ThisObject, "Object", "SupplyWithMaterialsAndWorks");
	
	ProductionFormManagement.EstablishConditionalAppearanceOfShipmentDate(
		ThisObject, "Object", "SupplyWithMaterialsAndWorks");
	
	#Region MaterialProviderCompany
	
	// Setting the mandatory filling of the "Giver Organization" is mandatory
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialProviderCompany.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.InternalSubcontracting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialProviderCompany");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Setting the mandatory filling of the "Giver Organization" is not necessary
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialProviderCompany.Name);
	
	OrGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.InternalSubcontracting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialProviderCompany");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfFinishedProduct()

	ItemNamesOutputItems = New Structure;
	ItemNamesOutputItems.Insert("ProductsUnitOfMeasure", Items.ManufacturedProductsProductsUnitOfMeasure.Name);
	ItemNamesOutputItems.Insert("Characteristic", Items.ManufacturedProductsCharacteristic.Name);
	ItemNamesOutputItems.Insert("Series", Items.ManufacturedProductsSeries.Name);
	ItemNamesOutputItems.Insert("BatchesIndicationStatus", Items.ManufacturedProductsBatchesIndicationStatus.Name);
	ItemNamesOutputItems.Insert("Purpose", Items.ManufacturedProductsPurpose.Name);
	ItemNamesOutputItems.Insert("ProductionDate", Items.ManufacturedProductsProductionDate.Name);
	ItemNamesOutputItems.Insert("DirectionOfProductionIssue", Items.ManufacturedProductsDirectionOfProductionIssue.Name);
	ItemNamesOutputItems.Insert("ExpenseItem", Items.ManufacturedProductsExpenseItem.Name);
	ItemNamesOutputItems.Insert("DimensionOfExpenses", Items.ManufacturedProductsDimensionOfExpenses.Name);
	ItemNamesOutputItems.Insert("AssetsLiabilitiesDimension", Items.ManufacturedProductsAssetsLiabilitiesDimension.Name);
	ItemNamesOutputItems.Insert("TransactionRecordingPresentation", Items.ManufacturedProductsTransactionRecordingPresentation.Name);
	ItemNamesOutputItems.Insert("Manufactured", Items.ManufacturedProductsManufactured.Name);
	ItemNamesOutputItems.Insert("Recipient", Items.ManufacturedProductsRecipient.Name);
	ItemNamesOutputItems.Insert("NumberOfPackages", Items.ManufacturedProductsNumberOfPackages.Name);
	ItemNamesOutputItems.Insert("Canceled", Items.ManufacturedProductsCanceled.Name);
	ItemNamesOutputItems.Insert("CancellationReason", Items.ManufacturedProductsCancellationReason.Name);
	ItemNamesOutputItems.Insert("BillOfMaterials", Items.ManufacturedProductsBillOfMaterials.Name);
	ItemNamesOutputItems.Insert("ProcessByBOM", Items.ManufacturedProductsProcessByBOM.Name);

	ProductionManagement.EstablishConditionalAppearanceOfOutputProductsOfProductionStage(
		ThisObject, "Object", "ManufacturedProducts", ItemNamesOutputItems);
		
	ItemNamesByProducts = New Structure;
	ItemNamesByProducts.Insert("ProductsUnitOfMeasure", Items.SideAndIntermediateReleaseProductsUnitOfMeasure.Name);
	ItemNamesByProducts.Insert("Characteristic", Items.SideAndIntermediateReleaseCharacteristic.Name);
	ItemNamesByProducts.Insert("Series", Items.SideAndIntermediateReleaseSeries.Name);
	ItemNamesByProducts.Insert("BatchesIndicationStatus", Items.SideAndIntermediateReleaseBatchesIndicationStatus.Name);
	ItemNamesByProducts.Insert("Purpose", Items.SideAndIntermediateReleasePurpose.Name);
	ItemNamesByProducts.Insert("ProductionDate", Items.SideAndIntermediateReleaseProductionDate.Name);
	ItemNamesByProducts.Insert("DirectionOfProductionIssue", Items.SideAndIntermediateReleaseDirectionOfProductionIssue.Name);
	ItemNamesByProducts.Insert("ExpenseItem", Items.SideAndIntermediateReleaseExpenseItem.Name);
	ItemNamesByProducts.Insert("DimensionOfExpenses", Items.SideAndIntermediateReleaseDimensionOfExpenses.Name);
	ItemNamesByProducts.Insert("AssetsLiabilitiesDimension", Items.SideAndIntermediateReleaseAssetsLiabilitiesDimension.Name);
	ItemNamesByProducts.Insert("TransactionRecordingPresentation", Items.SideAndIntermediateReleaseTransactionRecordingPresentation.Name);
	ItemNamesByProducts.Insert("Manufactured", Items.SideAndIntermediateReleaseManufactured.Name);
	ItemNamesByProducts.Insert("Recipient", Items.SideAndIntermediateReleaseRecipient.Name);
	ItemNamesByProducts.Insert("NumberOfPackages", Items.SideAndIntermediateReleaseNumberOfPackages.Name);
	ItemNamesByProducts.Insert("Canceled", Items.SideAndIntermediateReleaseCanceled.Name);
	ItemNamesByProducts.Insert("CancellationReason", Items.SideAndIntermediateReleaseCancellationReason.Name);
	ItemNamesByProducts.Insert("BillOfMaterials", Items.SideAndIntermediateReleaseBillOfMaterials.Name);
	ItemNamesByProducts.Insert("ProcessByBOM", Items.SideAndIntermediateReleaseProcessByBOM.Name);
	ItemNamesByProducts.Insert("ProductOwner", Items.SideAndIntermediateReleaseProductOwner.Name);
	
	ProductionManagement.EstablishConditionalAppearanceOfOutputProductsOfProductionStage(
		ThisObject, "Object", "SideAndIntermediateRelease", ItemNamesByProducts);
	
	ProductionManagement.EstablishConditionalAppearanceOfDestinationOfOutputProductsOfProductionStage(
		ThisObject);
	
	ProductionManagement.EstablishConditionalAppearanceOfAppointmentOfByProductsOfProductionStage(
		ThisObject);
	
	ProductionManagement.SetConditionalAppearanceOfStageConsumerOfSemiFinishedProductField(
		ThisObject, "Object", "ManufacturedProducts");
	
	ProductionManagement.SetConditionalAppearanceOfStageConsumerOfSemiFinishedProductField(
		ThisObject, "Object", "SideAndIntermediateRelease");
		
	ProductionFormManagement.SetConditionalAppearanceOfCalculationArticle(
		ThisObject, "Object", "SideAndIntermediateRelease", "SideAndIntermediateReleaseProductCostElement",, True);
		
	ProductionManagement.EstablishConditionalAppearanceOfFixedCostOfProductionStage(
		ThisObject, "Object", "SideAndIntermediateRelease");
	
	ProductionServer.SetConditionalAppearanceOfShareCostPercentageField(
		ThisObject, "Object", "ManufacturedProducts");
	
	ProductionServer.SetConditionalAppearanceOfShareOfCostOfCanceledRowsField(
		ThisObject, "Object", "ManufacturedProducts");
	
	
	#Region OutputProducts_ByProducts_BlankMark
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ProductionProcessType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ProductionProcessTypes.WithoutBillsOfMaterials;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThisIsAProductionIssueStage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FinishedProductsQuantity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThisIsAProductionIssueStage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FinishedProductsQuantity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SideAndIntermediateRelease.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ProductionByThirdParty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThisIsAProductionIssueStage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SideProductsQuantity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ProductionProcessType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ProductionProcessTypes.WithoutBillsOfMaterials;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion

	#Region Recycling_ProductionDate_MarkBlank
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturedProductsProductionDate.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SideAndIntermediateReleaseProductionDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ProductionByThirdParty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TollingOrderCreated");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	StatusesList = New ValueList;
	StatusesList.Add(Enums.StatusesOfProductionStages2_2.BeingGenerated);
	StatusesList.Add(Enums.StatusesOfProductionStages2_2.Generated1);
	StatusesList.Add(Enums.StatusesOfProductionStages2_2.ForCompletion);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = StatusesList;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region TargetCost
	
	// Visibility of planned cost fields.
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturedProductsPrice.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturedProductsSum.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseTargetCost");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ProductionByThirdParty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#Region SideAndIntermediateReleaseProductOwner
	
	InternalSubcontractingServer.SetConditionalAppearanceOfProductOwnerField(
		ThisObject,
		"Object",
		"SideAndIntermediateRelease",
		ItemNamesByProducts);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfBuildingMaterials()
	
	ProductionManagement.EstablishConditionalAppearanceForMaterialsOfProductionStage(
		ThisObject, "Object");
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceConsumptionOfMaterialsAndWorks()
	
	ItemsNames = ProductionManagement.NamesOfElementsConsumptionOfMaterialsAndWorksOfProductionStage();
	ItemsNames.ProductsUnitOfMeasure = Items.MaterialsAndWorksConsumptionProductsUnitOfMeasure.Name;
	ItemsNames.Characteristic               = Items.MaterialsAndWorksConsumptionCharacteristic.Name;
	ItemsNames.Series                        = Items.MaterialsAndWorksConsumptionSeries.Name;
	ItemsNames.ProductCostElement            = Items.MaterialsAndWorksConsumptionProductCostElement.Name;
	
	ProductionManagement.EstablishConditionalAppearanceOfConsumptionOfMaterialsAndWorksOfProductionStage(
		ThisObject, "Object", "MaterialsAndWorksConsumption", ItemsNames);

	#Region ExpenseDate_MarkBlank
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DateOfMaterialWorkConsumption.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ConsumptionInOneDay");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NumberOfConsumptionLines");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceTypesOfWorkCenters()
	
	ProductionProcessEditor.EstablishConditionalAppearanceTypesOfWorkCenters(
		ThisObject, "WorkCenterTypes", False);
	
	#Region OpeningHoursViewOnly
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.WorkCenterTypesOperationTime.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.WorkCenterTypesUnitOfMeasure.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WorkCenterTypes.OperationTimeStandard");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	#Region OpeningHoursHint
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.WorkCenterTypesOperationTime.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WorkCenterTypes.OperationTimeStandard");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WorkCenterTypes.OperationTime");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<tính toán từ tiêu chuẩn>';
													|ru = '<расчет от норматива>';
													|en = '<calculation from standard>'; fa = '<calculation from standard>';
													|it = '<расчет от норматива>';
													|pl = '<calculation from standard>';
													|tr = '<standart muhasebe>'"));
	
	#EndRegion
	
	#Region DownloadViewOnly
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.WorkCenterTypesLoad.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("WorkCenterTypes.LoadStandard");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceOfLaborCosts()
	
	ProductionManagement.EstablishConditionalAppearanceOfLaborCosts(
		ThisObject, "Object", "LaborCosts");

	#Region WorkCompletionDateTable_MarkBlank
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LaborCostsExecutionDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.LaborCosts.Completed2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region WorkCompletionDateBasement_MarkBlank
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.WorkExecutionDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.WorkPerformanceAsOneDay");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NumberOfLaborCostsLines");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region PlannedExecutor_InputHint
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LaborCostsPerformer.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.LaborCosts.Completed2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.LaborCosts.Performer");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseOperationManagement");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False; 
	// operationsacrasporyazheniyevywork - the mode is outdated, we do not support Conditional appearance
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.Performer"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	#EndRegion
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearancePlannedDateOfReceipt()
	
	// Props in the header
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ProductionDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = StatusStarted();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ProductionInOneDay");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ProductionDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("PlannedDateOfReceipt");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ValueOfPredefinedText);
	
	// Output items
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturedProductsProductionDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ProductionInOneDay");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.Manufactured");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.ProductionDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("PlannedDateOfReceipt");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ValueOfPredefinedText);
	
	// By-products
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.SideAndIntermediateReleaseProductionDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ProductionInOneDay");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SideAndIntermediateRelease.Manufactured");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SideAndIntermediateRelease.ProductionDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("PlannedDateOfReceipt");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ValueOfPredefinedText);
	
EndProcedure

#EndRegion

#Region FormSettingsItem

&AtServer
Procedure CustomizeFormElements()
	
	LabelSpecification = FormattedStringLabelSpecification();
	LabelProduct = FormattedStringLabelProduct();
	
	ThisIsAProductionIssueStage = ThisIsAProductionIssueStage(ThisObject);
	If ThisIsAProductionIssueStage Then
		
		SideProductsAreCollapsed = (Object.SideAndIntermediateRelease.Count() = 0);
		
		SetPropertiesOfCollapsibleGroup(
			Items.GroupByProductsCollapsible, 
			Items.HyperLinkLabelSideProducts, 
			SideProductsAreCollapsed);
			
	EndIf;
	
	// Visibility Of The FinishedProduct Being Repaired
	Items.SupplyOfMaterialsAndWorksGroupRepairedFINISHEDProduct.Visible =
		Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
			And Object.WorkPlanning;
	
	UnspentMaterialsAreCollapsed = (Object.UnusedMaterials.Count() = 0);
	
	SetPropertiesOfCollapsibleGroup(
		Items.UnusedMaterials, 
		Items.HyperLinkLabelPSavingMaterials,
		UnspentMaterialsAreCollapsed);
	
	Items.MethodOfAllocatingFinishedProductCosts.Visible = ThisIsAProductionIssueStage;
	
	Items.AssignmentProducts.Visible = Not Object.AssignmentProducts.IsEmpty();
	
	// Visibility of the "Disassemble" flag
	TheStructureOfTheSearch = New Structure("ProcessByBOM", True);
	ThisIsDisassembly = Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly;
	Items.OutputProductsGroupSpecification.Visible = ThisIsDisassembly
		And (Object.ManufacturedProducts.FindRows(TheStructureOfTheSearch).Count() Or Not Object.DynamicStructure);
	Items.SideProductsGroupBOM.Visible = ThisIsDisassembly
		And (Object.SideAndIntermediateRelease.FindRows(TheStructureOfTheSearch).Count() Or Not Object.DynamicStructure);
	
	Items.PageProvidingMaterialsAndWorks.Title = Documents.ProductionStage2_2.PresentationOfTSSupply(
		Object, RecordOfPerformed);
	
	SetSoftwareVisibility();
	
	Items.SpecifySeriesOfConsumedMaterials.Visible = False;

	If RecordOfPerformed Then
		
		Items.SpecifySeriesOfConsumedMaterials.Visible = True;
		
		Items.HeaderRightGroup.Visible			= False;
		Items.ReferenceOrder.Visible				= False;
		
		Items.OutputItemsGroupCancel.Visible	= False;
		Items.ByProductsGroupCancel.Visible	= False;
		
		Items.FinishedProductsCancelLines.Visible	= False;
		Items.SideProductsCancelLines.Visible	= False;
		
		Items.AdvancedGroup.Visible			= False;
		
		ArrayOfParameterRelationships = New Array;
		ArrayOfParameterRelationships.Add(New ChoiceParameterLink("Filter.Department", "Object.Department"));
		ArrayOfParameterRelationships = New FixedArray(ArrayOfParameterRelationships);
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.ShopFloorStockroom", True));
		ChoiceParametersArray = New FixedArray(ChoiceParametersArray);
		
		Items.SupplyWithMaterialsAndWorksWarehouse.ChoiceParameterLinks	= ArrayOfParameterRelationships;
		Items.SupplyWithMaterialsAndWorksWarehouse.ChoiceParameters		= ChoiceParametersArray;
	EndIf;
	
	If Object.WorkPlanning Then
		
		AvailableProductTypes = ProductionServer.ArrayOfValues(Enums.ItemsTypes.Work_5);
		
		ProductDataManagementClientServer.SetSelectionByItemType(
			Items.SupplyWithMaterialsAndWorksProducts,
			AvailableProductTypes);
		
		Items.EnsureToPickUpTheGoods.Title = NStr("vi = 'Chọn công việc';
													|ru = 'Подобрать работы';
													|en = 'Pick works'; fa = 'Pick works';
													|it = 'Pick works';
													|pl = 'Pick works';
													|tr = 'Подобрать работы'");
		Items.SupplyWithMaterialsAndWorksProduced.Title = NStr("vi = 'Sản xuất';
																|ru = 'Произвести';
																|en = 'Produce'; fa = 'تولید';
																|it = 'Produce';
																|pl = 'Produce';
																|tr = 'Üret'");
		Items.SupplyWithMaterialsAndWorksWarehouse.Visible = False;
		Items.SupplyFillInTheWarehouseInTheSelectedLines.Visible = False;
		
	EndIf;
	
	If Not AccessRight("Insert", Metadata.Documents.InventoryAssignmentAdjustment)
		Or Object.WorkPlanning Then
		Items.ToCreateAnAdjustmentPurposeTheRemovalOfTheReserve.Visible = False;
		Items.SoftwareToCreateACorrectionPurposeRedundant.Visible = False;
	EndIf;
	
	Items.SupplyWithMaterialsAndWorksProduced.Visible = 
		Object.ProductionProcessType <> Enums.ProductionProcessTypes.WithoutBillsOfMaterials
		And Not Object.DynamicStructure
		Or Object.WorkPlanning;
	
	Items.ProvisionOfMaterialsAndWorksAnalogsGroup.Visible = RightToReadSubstitutes
		And Not Object.WorkPlanning;
	
	Items.SupplyWithMaterialsAndWorksIncludedInSet.Visible =  UseOfKitsInProductionIsAvailable;
	
	Items.SupplyWithMaterialsAndWorksBillOfMaterials.Visible = 
		Object.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
		Or Object.WorkPlanning
		Or Object.ProductionProcessType <> Enums.ProductionProcessTypes.WithoutBillsOfMaterials
			And Not Object.DynamicStructure;
	
	Items.StartAStage.Enabled = HasEditPermission;
	Items.CloseStage.Enabled = HasEditPermission;
	
	Items.FormOrderStructure.Visible = Not Object.DynamicStructure
		And AccessRight("View", Metadata.Reports.ProductionOrderStructure2_2);
		
	Items.InformationIsDefectiveGoodsLabel.Hyperlink =
		AccessRight("View", Metadata.Reports.ProductionOperationProgress);
	
	ParametersArray = New FixedArray(
		CommonClientServer.ValueInArray(
			New ChoiceParameter("Products", ProductionBatchData.MainProductProducts)));
	Items.PackagePlan.ChoiceParameters = ParametersArray;
	Items.PackageActualData.ChoiceParameters = ParametersArray;
	Items.PackageCanceled.ChoiceParameters = ParametersArray;
	
	If ValueIsFilled(ProductionBatchData.MainProductProducts) Then
		Items.PackagePlan.InputHint = MainProductUnitOfMeasurementName;
		Items.PackageActualData.InputHint = MainProductUnitOfMeasurementName;
		Items.PackageCanceled.InputHint = MainProductUnitOfMeasurementName;
	EndIf;

	DateEditingFormat = ProductionManagementClientServer.FormatForEditingStageCompletionDates();
	Items.ActualStageStart.EditFormat    = DateEditingFormat;
	Items.ActualStageEnd.EditFormat = DateEditingFormat;
	
	// Internal Processing
	ItemsToProcess_2 = New Array;
	ItemsToProcess_2.Add("InternalSubcontracting");
	ItemsToProcess_2.Add("DecorationIndentationInternalProcessing");
	ItemsToProcess_2.Add("MaterialProviderCompany");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		ItemsToProcess_2,
		"Visible",
		UseInternalSubcontracting);
	
	MultipleCalculation = SimultaneouslyManufacturedQuantity > 1;
	TemplateText = ?(MultipleCalculation, NStr("vi = 'Tiêu chuẩn cho mỗi %1 %2';
												|ru = 'Норматив на каждые %1 %2';
												|en = 'Standard for each %1 %2'; fa = 'Standard for each %1 %2';
												|it = 'Норматив на каждые %1 %2';
												|pl = 'Standard for each %1 %2';
												|tr = 'Her %1 %2 için standart'"), NStr("vi = 'Tiêu chuẩn cho %1 %2';
																						|ru = 'Норматив на %1 %2';
																						|en = 'Standard for %1 %2'; fa = 'Standard for %1 %2';
																						|it = 'Норматив на %1 %2';
																						|pl = 'Standard for %1 %2';
																						|tr = '%1 %2 standardı'"));
	Items.WorkCentersTypesGroupStandards.Title = StrTemplate(TemplateText,
		Format(NumberOfStandardCalculationTypesOfRC, "NG=;"),
		MainProductUnitOfMeasurementName);
	
	Items.PlanNoEarlierThanDate.EditFormat = ScheduleDateFormat;
	
	ConfigureOrderInformation();
	
	CalculateNumberOfTypesOfWorkCenters(ThisObject);
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

// The procedure is called when changing the details that depend on the properties of other details, such as visibility.
//
&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")

	Object = Form.Object;
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	// The header of the form
	#Region FormCaption
	If Initialize
		Or AttributesStructure1.Property("StageName") Then
		
		StringHeader = New Array;
		
		PresentationDetails = New Structure("Number, StageName");
		FillPropertyValues(PresentationDetails, Object);
		
		PresentationStage = PresentationStage(PresentationDetails);
		StringHeader.Add(PresentationStage);
		StringHeader.Add(NStr("vi = '(công đoạn sản xuất)';
								|ru = '(Этап производства)';
								|en = '(Production stage)'; fa = '(Production stage)';
								|it = '(fase di produzione)';
								|pl = '(Etap produkcji)';
								|tr = '(Üretim aşaması)'"));
		
		Form.AutoTitle = False;
		Form.Title = StrConcat(StringHeader, " ");
		
	EndIf;
	#EndRegion
	
	// InternalSubcontracting
	#Region InternalSubcontracting
	If Initialize
		Or AttributesStructure1.Property("InternalSubcontracting") Then
		
		Items.Organization.ReadOnly =
			Not Form.UseInternalSubcontracting
			Or Not Object.InternalSubcontracting;
		
		ArtistSelectionParameters = New Array;
		
		If ValueIsFilled(Object.MaterialProviderCompany) Then
			
			CurrencySelectionParameterAccountingReg = New ChoiceParameter("Filter.LocalAccountingCurrency", Form.LocalAccountingCurrency);
			ArtistSelectionParameters.Add(CurrencySelectionParameterAccountingReg);
			
			CountryOfRegistrationSelectionParameter = New ChoiceParameter("Filter.RegistrationCountry", Form.RegistrationCountry);
			ArtistSelectionParameters.Add(CountryOfRegistrationSelectionParameter);
			
			OrganizationChoiceParameter = New ChoiceParameter("ModeForSelectingRelatedOrganizations", "JustNotInterconnected");
			ArtistSelectionParameters.Add(OrganizationChoiceParameter);
			
			OrganizationChoiceParameter = New ChoiceParameter("Organization", Object.MaterialProviderCompany);
			ArtistSelectionParameters.Add(OrganizationChoiceParameter);
			
		EndIf;
		
		Items.Organization.ChoiceParameters = New FixedArray(ArtistSelectionParameters);
		
		If Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly")
			And True Then // Subdavalchesky scheme
			
			Items.GroupProductionMethod.Visible =
				(Form.ProductionByThirdPartyIsUsed Or Form.UseSubcontractOrders2_5)
				And Not Object.WorkPlanning
				And Not Object.InternalSubcontracting;
			
		ElsIf Not Form.RecordOfPerformed
			And Form.UseSubcontractOrders2_5
			And Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials") Then // Subdavalchesky scheme
			Items.GroupProductionMethod.Visible =
				Not Object.WorkPlanning
				And Not Object.InternalSubcontracting;
		Else
			Items.GroupProductionMethod.Visible =
				Object.ProductionByThirdParty
				And Not Object.WorkPlanning
				And Not Object.InternalSubcontracting;
		EndIf;
		
	EndIf;
	#EndRegion

	// Processing on the side
	#Region ProcessingByThirdParties
	If Initialize
		Or AttributesStructure1.Property("ProductionMethod")  Then
		
		Items.ManufacturedProductsManufactured.Visible =
			Not Form.Object.ProductionByThirdParty
			And Not Form.RecordOfPerformed;
		
		Items.SideAndIntermediateReleaseManufactured.Visible = 
			Not Form.Object.ProductionByThirdParty
			And Not Form.RecordOfPerformed;
		
		TollManufacturing2_5 =
				Object.BusinessOperation =
					PredefinedValue("Enum.BusinessTransactions.TollManufacturing2_5");
		
		If Form.Object.ProductionByThirdParty Then
			Items.OutputItemsRecipientGroup.Title = ?(TollManufacturing2_5,
																	NStr("vi = 'Người nhận';
																		|ru = 'Получатель';
																		|en = 'Recipient'; fa = 'گیرنده';
																		|it = 'Destinatario';
																		|pl = 'Recipient';
																		|tr = 'Alıcı'"),
																	NStr("vi = 'Người nhận / dạng và đối tượng phân tích';
																		|ru = 'Получатель / статья и аналитика';
																		|en = 'Recipient / item and dimension'; fa = 'Recipient / item and dimension';
																		|it = 'Destinatario / voci e analisi dati';
																		|pl = 'Odbiorca / pozycja i analityka';
																		|tr = 'Alıcı / kalem ve boyut'"));
			Items.ByProductsRecipientGroup.Title = NStr("vi = 'Người nhận / dạng và đối tượng phân tích';
														|ru = 'Получатель / статья и аналитика';
														|en = 'Recipient / item and dimension'; fa = 'Recipient / item and dimension';
														|it = 'Destinatario / voci e analisi dati';
														|pl = 'Odbiorca / pozycja i analityka';
														|tr = 'Alıcı / kalem ve boyut'");
		Else
			Items.OutputItemsRecipientGroup.Title = ?(TollManufacturing2_5,
																	NStr("vi = 'Người nhận';
																		|ru = 'Получатель';
																		|en = 'Recipient'; fa = 'گیرنده';
																		|it = 'Destinatario';
																		|pl = 'Recipient';
																		|tr = 'Alıcı'"),
																	NStr("vi = 'Người nhận / dạng và đối tượng phân tích / tài khoản kế toán';
																		|ru = 'Получатель / статья и аналитика / счет учета';
																		|en = 'Recipient / item and dimension / ledger account'; fa = 'گیرنده / قلم و بُعد / حساب دفتر کل';
																		|it = 'Destinatario / articolo e analitica / conto contabilità';
																		|pl = 'Odbiorca / pozycja i analityka / rachunek ewidencji';
																		|tr = 'Alıcı / kalem ve boyut / defterikebir hesabı'"));
			Items.ByProductsRecipientGroup.Title = NStr("vi = 'Người nhận / dạng và đối tượng phân tích / tài khoản kế toán';
														|ru = 'Получатель / статья и аналитика / счет учета';
														|en = 'Recipient / item and dimension / ledger account'; fa = 'گیرنده / قلم و بُعد / حساب دفتر کل';
														|it = 'Destinatario / articolo e analitica / conto contabilità';
														|pl = 'Odbiorca / pozycja i analityka / rachunek ewidencji';
														|tr = 'Alıcı / kalem ve boyut / defterikebir hesabı'");
		EndIf;
		
		ProductionStage2_2ClientServerLocalization.CreateOrderCreationHyperlink(Form);
		
		If Object.ProductionByThirdParty And Form.TollingOrderCreated 
			Or Form.UseOperationManagement And Form.OperationsStarted Then
			Items.ProductionMethod.ReadOnly = True;
		Else
			Items.ProductionMethod.ReadOnly = False;
		EndIf;
		
	EndIf;
	#EndRegion

	// Production schedule
	#Region ProductionSchedule
	
	// Planning parameters
	If AttributesStructure1.Property("PlanningMethod")
		Or AttributesStructure1.Property("ProductionMethod") 
		Or AttributesStructure1.Property("Status")
		Or Initialize Then
		
		Items.GroupProductionPeriod.Visible =
			Form.TheProductionScheduleIsPlanned
			And Not Form.RecordOfPerformed;
			
		Items.GroupSchedulePlanningParameters.Visible =
			(Form.TheProductionScheduleIsPlanned
				Or Object.DynamicStructure)
			And Not Form.RecordOfPerformed;
		
		If Form.TheProductionScheduleIsPlanned
			Or Object.DynamicStructure Then
			
			Items.GroupProductionPeriod.Enabled = Form.RightToEditProductionSchedule
				And Form.TheProductionScheduleIsPlanned;
			
			Items.GroupSchedulePlanningParameters.Enabled = Form.RightToEditProductionSchedule
															 And Object.Status <> StatusCompleted_1();
			
			Items.UBBVDurationGroup.Visible = Not Form.Object.StagePlacementInProductionSchedule
													  And Not Form.Object.PlanOperationsOfWorkCenterTypes;
			
			Items.BBVPlanningMethod.Visible = ProductionResourcePlanningIsAvailable(Form);
			
			Items.ManualSchedulingMethod.Visible = Form.TheProductionScheduleIsPlanned;
			Items.ManualEditingOfTheProductionSchedule.Visible = Form.Object.StagePlacementInProductionSchedule;
			
			Items.GroupPlanNotEarlier.Visible = Form.TheProductionScheduleIsPlanned;
			Items.GroupPlanNotEarlier.Enabled = Not Form.Object.StagePlacementInProductionSchedule
															And Object.Status <> StatusStarted()
															And Object.Status <> StatusCompleted_1();
			
			NumberOfFieldsOnLeft = ?(Items.UBBWPlanningMethod.Visible, 1, 0)
				+ ?(Items.BBVPlanningMethod.Visible, 1, 0)
				+ ?(Items.ManualSchedulingMethod.Visible, 1, 0);
			
			NumberOfFieldsOnRight = ?(Items.UBBVDurationGroup.Visible, 1, 0)
				+ ?(Items.ManualEditingOfTheProductionSchedule.Visible, 1, 0);
			
			Items.GroupMethodIndent1.Visible = NumberOfFieldsOnRight > 0
				And (NumberOfFieldsOnLeft - NumberOfFieldsOnRight) >= 1;
			
			Items.GroupMethodIndent2.Visible = NumberOfFieldsOnRight > 0
				And (NumberOfFieldsOnLeft - NumberOfFieldsOnRight) = 2;
			
		EndIf;
		
		Items.GroupPlanningParametersWithoutASchedule.Visible =
			Not Form.TheProductionScheduleIsPlanned
			And Not Form.RecordOfPerformed
			And Not Object.DynamicStructure;
		Items.GroupPlanningParametersWithoutASchedule.Enabled = Form.RightToEditProductionSchedule;
		
		Items.PageTypesOfWorkCenters.Visible = Not Form.Object.StagePlacementInProductionSchedule
														 And Form.Object.PlanOperationsOfWorkCenterTypes 
														 And ProductionResourcePlanningIsAvailable(Form);
														 
		Items.PageTypesOfWorkCenters.Enabled = Form.RightToEditProductionSchedule;
		
	EndIf;
	
	// Pre-buffer
	If AttributesStructure1.Property("PreliminaryBuffer") Or Initialize Then
		
		If Not ValueIsFilled(Form.Object.UnitOfMeasureOfPreliminaryBuffer)
			And Form.Object.PreliminaryBuffer <> 0 Then
			Items.UnitOfMeasureOfPreliminaryBuffer.MarkIncomplete = True;
		Else
			Items.UnitOfMeasureOfPreliminaryBuffer.MarkIncomplete = False;
		EndIf;
		
	EndIf;
	
	// The final buffer
	If AttributesStructure1.Property("FollowUpBuffer") Or Initialize Then
		
		If Not ValueIsFilled(Form.Object.UnitOfMeasureOfFollowUpBuffer)
			And Form.Object.FollowUpBuffer <> 0 Then
			Items.UnitOfMeasureOfFollowUpBuffer.MarkIncomplete = True;
		Else
			Items.UnitOfMeasureOfFollowUpBuffer.MarkIncomplete = False;
		EndIf;
	
	EndIf;
	
	// Unit of measurement of the duration of the UBB stage
	If AttributesStructure1.Property("UnitOfMeasureOfStageDuration") Or Initialize Then
		
		UnitOfMeasurementDay = PredefinedValue("Enum.TimeMeasureUnits.Day");
		
		If Form.Object.UnitOfMeasureOfStageDuration = UnitOfMeasurementDay Then
			ToolTipText = NStr("vi = 'Khi lập kế hoạch, lịch làm việc Bộ phận được sử dụng.';
								|ru = 'При планировании используется календарь работы подразделения.';
								|en = 'Business unit calendar is used on scheduling.'; fa = 'تقویم واحد تجاری در زمان‌بندی استفاده می‌شود.';
								|it = 'Quando si pianifica si utilizzano unità di lavoro del calendario.';
								|pl = 'Podczas planowania używa się kalendarz pracy działu.';
								|tr = 'Planlama yapılırken departmanın çalışma takvimi kullanılmaktadır.'");
		Else
			ToolTipText = NStr("vi = 'Khi lập kế hoạch, lịch làm việc của Bộ phận được sử dụng.';
								|ru = 'При планировании используется расписание работы подразделения.';
								|en = 'Business unit timetable is used while planning.'; fa = 'Business unit timetable is used while planning.';
								|it = 'Quando si pianifica si utilizzano unità di lavoro del grafico';
								|pl = 'Podczas planowania używa się harmonogram pracy działu.';
								|tr = 'Planlama yapılırken departmanın çalışma çizelgesi kullanılmaktadır.'");
		EndIf;
		
		If Form.TheProductionScheduleIsPlanned Then
			Form.Items.UnitOfMeasureOfStageDuration.ToolTip = ToolTipText;
		Else
			Form.Items.UnitOfMeasurementForTheDurationOfAStageWithoutASchedule.ToolTip = ToolTipText;
		EndIf;
		
	EndIf;
		
	// Planning period
	If AttributesStructure1.Property("ProductionSchedule")
		Or Initialize Then
		
		TextProductionPeriod = "";
		
		If Form.TheProductionScheduleIsPlanned Then
			
			If Form.ProductionSchedule.Calculated Then
				
				ProductionSchedule = Form.ProductionSchedule;// Structure
				
				TemplateProductionPeriod = NStr("vi = 'từ %1 đến %2';
												|ru = 'с %1 по %2';
												|en = 'from %1 to %2'; fa = 'from %1 to %2';
												|it = 'da %1 fino a %2';
												|pl = 'od %1 do %2';
												|tr = '%1 ile %2 arası'");
				
				TextProductionPeriod = StrTemplate(TemplateProductionPeriod,
											Format(ProductionSchedule.Begin, Form.ScheduleDateFormat),
											Format(ProductionSchedule.Ending, Form.ScheduleDateFormat));
				
			Else
				
				TextProductionPeriod = NStr("vi = '<lịch sản xuất không được tính>';
											|ru = '<график производства не рассчитан>';
											|en = '<production schedule is not calculated>'; fa = '<production schedule is not calculated>';
											|it = '<grafico produzione non calcolato>';
											|pl = '<harmonogram produkcji nie jest obliczony>';
											|tr = '<üretim programı hesaplanmadı>'");
				
			EndIf;
			
		EndIf;
		
		Form.LabelProductionPeriod = TextProductionPeriod;
		
	EndIf;
	
	// Plan not earlier
	If AttributesStructure1.Property("MarkPlanNotEarlierThan")
		Or AttributesStructure1.Property("PlanningMethod")
		Or Initialize Then
		
		Items.LabelPlanNotEarlierThan.Visible = Form.MarkPlanNotEarlierThan
			And Not Object.DynamicStructure;
		
		Items.PlanNoEarlierThanDate.Visible = Form.MarkPlanNotEarlierThan
			And Object.DynamicStructure;
		
	EndIf;
	
	#EndRegion
	
	// Organization
	#Region Organization
	If Initialize
		Or AttributesStructure1.Property("Organization") Then
		
		Items.OutputProductsFillInPrices.Visible              = Form.UseTargetCost;
		Items.OutputProductsFillInThePricesAccordingToTheCalculation_3.Visible = Form.UseTargetCost;
		
	EndIf;
	#EndRegion
	
	// Department
	#Region Department
	If AttributesStructure1.Property("Department")
		Or Initialize Then
		
		Items.Department.ReadOnly = Form.UseOperationManagement And Form.OperationsStarted;
		
	EndIf;
	#EndRegion

	// Provision, Expense, Economy
	#Region Provision_ConsumptionOfMaterialsAndWorks_SavingOfMaterials
	
	If AttributesStructure1.Property("MaterialsAndWorksConsumption")
		Or AttributesStructure1.Property("UnusedMaterials") 
		Or Initialize Then
		
		ConsumptionOfMaterialsAndWorksQuantity = Form.Object.MaterialsAndWorksConsumption.Count();
		SavingMaterialsQuantity = Form.Object.UnusedMaterials.Count();
		
		If AttributesStructure1.Property("MaterialsAndWorksConsumption") Or Initialize Then
			If ConsumptionOfMaterialsAndWorksQuantity > 0 Then
				Form.LabelConsumptionOfMaterialsAndWorks = StrTemplate("%1 (%2)", Items.MaterialsAndWorksConsumption.Title, ConsumptionOfMaterialsAndWorksQuantity);
			Else
				Form.LabelConsumptionOfMaterialsAndWorks = Items.MaterialsAndWorksConsumption.Title;
			EndIf;
		EndIf;
		
		If AttributesStructure1.Property("UnusedMaterials") Or Initialize Then
			If SavingMaterialsQuantity > 0 Then
				Form.LabelMaterialSaving = StrTemplate("%1 (%2)", Items.UnusedMaterials.Title, SavingMaterialsQuantity);
			Else
				Form.LabelMaterialSaving = Items.UnusedMaterials.Title;
			EndIf;
		EndIf;
		
		Form.NumberOfConsumptionLines = ConsumptionOfMaterialsAndWorksQuantity + SavingMaterialsQuantity;
		
	EndIf;
	
	If AttributesStructure1.Property("ProductionMethod") 
		Or AttributesStructure1.Property("Status")
		Or Initialize Then
		
		VisibilityOfElements = Not Form.Object.ProductionByThirdParty
							And Not Form.RecordOfPerformed
							And Not Form.Object.WorkPlanning
							And (Form.Object.Status = StatusStarted() Or Form.Object.Status = StatusCompleted_1());
							
		Items.MaterialsAndWorksConsumptionPage.Visible = VisibilityOfElements;
		
	EndIf;
	
	// Shipment by one date and the date of shipment
	If AttributesStructure1.Property("NotShipInInstallments")
		Or AttributesStructure1.Property("ProductionMethod")
		Or Initialize Then
		
		// If the stage is included in the order to the processor, 
		// then the date entry mode cannot be changed in the stage, 
		// because it should be the same for all stages of the order.
		If Object.ProductionByThirdParty Then
			
			If Form.TollingOrderCreated And Not Object.NotShipInInstallments Then
				Items.NotShipInInstallments.Visible = False;
			Else
				Items.NotShipInInstallments.Visible = True;
			EndIf;
			
			Items.NotShipInInstallments.ReadOnly = Form.TollingOrderCreated;
			Items.DateOfShipment.ReadOnly = Form.TollingOrderCreated;
			
		EndIf;
		ShipmentIsAvailable = Not(
			Object.ProductionByThirdParty
				And Form.TollingOrderCreated
				And Object.NotShipInInstallments
				And Not ValueIsFilled(Object.DateOfShipment));
			
		Items.SupplyWithMaterialsAndWorksSoftwareToShip.Enabled = ShipmentIsAvailable;
		Items.SupplyWithMaterialsAndWorksContextMenuSoftwareToShip.Enabled = ShipmentIsAvailable;
		
		Items.DateOfShipment.Visible = Object.NotShipInInstallments;
		
	EndIf;
	
	If AttributesStructure1.Property("ThereAreMaterialSpecifications") Or Initialize Then
		Items.GroupSpecificationOfMaterials.Visible = Form.ThereAreMaterialSpecifications;
	EndIf;
	
	If AttributesStructure1.Property("ThereAreSideProductSpecifications") Or Initialize Then
		Items.GroupSpecifySideProducts.Visible = Form.ThereAreSideProductSpecifications;
	EndIf;
	
	If AttributesStructure1.Property("NotShipInInstallments")
		Or AttributesStructure1.Property("DateOfShipment")
		Or AttributesStructure1.Property("ProductionSchedule")
		Or Initialize Then
		
		ProductionSchedule = Form.ProductionSchedule;// Structure
		
		RescheduleShipmentDate = Object.NotShipInInstallments
			And Form.TheProductionScheduleIsPlanned
			And ValueIsFilled(ProductionSchedule.Begin)
			And Object.DateOfShipment <> BegOfDay(ProductionSchedule.Begin);
		
		Form.Items.ToChangeTheDateOfShipment.Visible = RescheduleShipmentDate;
		
		If RescheduleShipmentDate Then
			
			Form.Items.ToChangeTheDateOfShipment.Title = StrTemplate(
				NStr("vi = 'đặt %1 (đã lên lịch)';
					|ru = 'установить %1 (по графику)';
					|en = 'set %1 (on schedule)'; fa = 'set %1 (on schedule)';
					|it = 'impostare %1 (in base al grafico)';
					|pl = 'ustalić %1 według harmonogramu)';
					|tr = '%1 yapılandır (programa göre)'"),
				Format(ProductionSchedule.Begin, "DLF=D"));
			
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("ConsumptionInOneDay")
		Or Initialize Then
		
		Items.DateOfMaterialWorkConsumption.Visible = Object.ConsumptionInOneDay;
		Items.MaterialsAndWorksConsumptionDateOfMaterialWorkConsumption.Visible = Not Object.ConsumptionInOneDay;
		Items.UnusedMaterialsDateOfTransaction.Visible = Not Object.ConsumptionInOneDay;
		Items.MaterialAndWorkConsumptionFillInTheExpenseDate.Visible = Not Object.ConsumptionInOneDay;
		Items.MaterialSavingFillInDate.Visible = Not Object.ConsumptionInOneDay;
		
	EndIf;
	
	#EndRegion
	
	// Output items
	#Region OutputProducts_ByProducts
	
	If AttributesStructure1.Property("ManufacturedProducts")
		Or AttributesStructure1.Property("SideAndIntermediateRelease")
		Or Initialize Then
		
		Form.FinishedProductsQuantity = Form.Object.ManufacturedProducts.Count();
		Form.SideProductsQuantity = Form.Object.SideAndIntermediateRelease.Count();
		
		If AttributesStructure1.Property("ManufacturedProducts") Or Initialize Then
			If Form.FinishedProductsQuantity > 0 Then
				Form.LabelProducts = StrTemplate("%1 (%2)", Items.ManufacturedProducts.Title, Form.FinishedProductsQuantity);
			Else
				Form.LabelProducts = Items.ManufacturedProducts.Title;
			EndIf;
		EndIf;
		
		If AttributesStructure1.Property("SideAndIntermediateRelease") Or Initialize Then
			If Form.SideProductsQuantity > 0 Then
				Form.LabelSideProducts = StrTemplate("%1 (%2)", Items.SideAndIntermediateRelease.Title, Form.SideProductsQuantity);
			Else
				Form.LabelSideProducts = Items.SideAndIntermediateRelease.Title;
			EndIf;
		EndIf;
		
		Form.NumberOfLinesFinishedProducts = Form.FinishedProductsQuantity + Form.SideProductsQuantity;
		
	EndIf;
	
	If AttributesStructure1.Property("ThisIsAProductionIssueStage")
		Or AttributesStructure1.Property("ProductionMethod")
		Or Initialize Then
		
		Items.OutputProductsPage.Visible = Not Form.Object.WorkPlanning;
		
		Items.GroupProducts_2.Visible = ThisIsAProductionIssueStage(Form)
			Or Form.Object.ManufacturedProducts.Count() > 0;
		If Not Items.GroupProducts_2.Visible Then
			Items.HyperLinkLabelSideProducts.Visible = False;
		EndIf;
	EndIf; 
	
	// Leave the products for further processing
	If AttributesStructure1.Property("ProductionMethod")
		Or Initialize Then
		
		Items.LeaveProductsAtSubcontractor.Visible =
			False
			And Object.ProductionByThirdParty2_5;
		
		Items.LeaveProductsAtSubcontractor.ReadOnly = Form.TollingOrderCreated;
		
	EndIf;
	
	// Single date production and production date
	If AttributesStructure1.Property("ProductionInOneDay")
		Or AttributesStructure1.Property("ProductionMethod")
		Or AttributesStructure1.Property("Status")
//		OR the structure of the requirements.Property("Output products")
//		OR the structure of requirements.Property("Side products")
		Or Initialize Then
		
		// If the stage is included in the order to the processor, 
		// then the date entry mode cannot be changed in the stage, 
		// because it should be the same for all stages of the order.
		If Object.ProductionByThirdParty Then
			
			Items.ProductionInOneDay.ReadOnly = Form.TollingOrderCreated;
			Items.ProductionDate.ReadOnly = Form.TollingOrderCreated;
			
			ProductionDateIsAvailable = Object.Status = StatusPending() Or Object.Status = StatusStarted() Or Object.Status = StatusCompleted_1() Or Object.DynamicStructure;
			
			Items.ProductionInOneDay.Visible = ProductionDateIsAvailable;
			Items.ProductionDate.Visible = Object.ProductionInOneDay And ProductionDateIsAvailable;
			Items.ManufacturedProductsProductionDate.Visible = Not Object.ProductionInOneDay And ProductionDateIsAvailable;
			Items.SideAndIntermediateReleaseProductionDate.Visible = Not Object.ProductionInOneDay And ProductionDateIsAvailable;
			
		Else
			
			ProductionDateIsAvailable = Object.Status = StatusStarted() Or Object.Status = StatusCompleted_1() Or Object.DynamicStructure;
			
			Items.ProductionInOneDay.Visible = ProductionDateIsAvailable;
			Items.ProductionDate.Visible = Object.ProductionInOneDay And ProductionDateIsAvailable;
			Items.ManufacturedProductsProductionDate.Visible = Not Object.ProductionInOneDay And ProductionDateIsAvailable;
			Items.SideAndIntermediateReleaseProductionDate.Visible = Not Object.ProductionInOneDay And ProductionDateIsAvailable;
			
		EndIf;
		
		// Bypassing the platform error - does not work out the conditional design (the mark of the filled one is set, but not reset)
		ProductionDateRequired_ = (Object.Status = StatusStarted() 
											Or Object.Status = StatusCompleted_1() 
											Or Object.Status = StatusPending() And Form.TollingOrderCreated) And Form.NumberOfLinesFinishedProducts > 0; 
											
		If ProductionDateRequired_ Then 									
			Items.ProductionDate.AutoMarkIncomplete = True;
		Else
			Items.ProductionDate.AutoMarkIncomplete = False;
			Items.ProductionDate.MarkIncomplete = False;
		EndIf;

	EndIf;
	
	#EndRegion
	
	// LaborCosts
	#Region LaborCosts
	
	// Number of lines in TS
	If Initialize Or AttributesStructure1.Property("LaborCosts") Then
		Form.NumberOfLaborCostsLines = Form.Object.LaborCosts.Count();
	EndIf;
	
	// Date of work completion
	If AttributesStructure1.Property("WorkPerformanceAsOneDay")
		Or Initialize Then
		Items.WorkExecutionDate.Visible = Object.WorkPerformanceAsOneDay;
		Items.LaborCostsExecutionDate.Visible = Not Object.WorkPerformanceAsOneDay;
	EndIf;
	
	If Initialize
		Or AttributesStructure1.Property("ProductionMethod")
		Or AttributesStructure1.Property("Department") Then
		
		Items.LaborCostsPage.Visible = Not Form.Object.ProductionByThirdParty And Not Form.Object.WorkPlanning;
		
		VisibilityOfFact = Not (Form.UseOperationManagement And Object.OperationAsOutputReference)
		Or Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials");
		
		Items.LaborCostsGroupExecuted.Visible   = VisibilityOfFact And Not Form.RecordOfPerformed;
		Items.LaborCostsPerformer.Visible       = VisibilityOfFact;
		Items.LaborCostsProductCostElement.Visible = VisibilityOfFact;
		Items.GroupWorkCompletionDate.Visible     = VisibilityOfFact;
		
		Items.LaborCostsFillInThePerformersInTheHighlightedLines.Visible      = VisibilityOfFact;
		Items.LaborCostsFillInTheCalculationArticleInTheHighlightedLines.Visible = VisibilityOfFact;
		
	EndIf;
	
	#EndRegion
	
	// Standards
	#Region Standards
	
	If AttributesStructure1.Property("ShowStandards") Or Initialize Then
		
		Items.SupplyWithMaterialsAndWorksNormativeStandard.Visible = Form.ShowStandardsMaterials;
		Items.SecurityShowStandards.Check = Form.ShowStandardsMaterials;
		
		Items.LaborCostsNormativeStandard.Visible = Form.ShowStandardsLaborCosts;
		Items.LaborCostsShowStandards.Check = Form.ShowStandardsLaborCosts;
		
	EndIf;
	
	#EndRegion
	
	// Perform
	#Region StageExecution
	
	// Batch Change Commands
	If AttributesStructure1.Property("Status")
		Or Initialize Then
		
		Items.Production_ReflectDefectiveGoods.Visible = Form.ThereIsRightToDivideParty
			And Object.Status <> StatusCompleted_1();
		
	EndIf;
	
	// Due date
	If AttributesStructure1.Property("StageExecutionIsStarted")
		Or AttributesStructure1.Property("StageIsCompleted")
		Or Initialize Then
		
		Items.ActualStageStart.AutoMarkIncomplete = Form.StageExecutionIsStarted;
		Items.ActualStageEnd.AutoMarkIncomplete = Form.StageIsCompleted;
		
	EndIf;
	
	// Actual start of the stage
	If Initialize Or AttributesStructure1.Property("StageExecutionIsStarted") Then
		
		Items.ActualStageStart.ReadOnly = Not Form.StageExecutionIsStarted;
		
	EndIf;
	
	// Actual end of the stage
	If Initialize Or AttributesStructure1.Property("StageIsCompleted") Then
		
		Items.ActualStageEnd.ReadOnly = Not Form.StageIsCompleted;
		
	EndIf;
	
	// Groups to reflect execution
	If Initialize Or AttributesStructure1.Property("ProductionMethod") Then
		
		Items.GroupExecution.Visible = 
			Not Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials")
			And Not Object.WorkPlanning;
		
		Items.GroupExecuted.Visible = Not Form.Object.ProductionByThirdParty;
		Items.GroupCanceled.Visible = Not Form.Object.ProductionByThirdParty;
		
		Items.GroupChangeOfBatch.Visible = Not Form.Object.ProductionByThirdParty
			And Not Object.WorkPlanning
			And Object.ProductionProcessType
				<> PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials");
	
	EndIf;
	
	#EndRegion
	
	// BillOfMaterials
	#Region BillOfMaterials
	
	If AttributesStructure1.Property("BillOfMaterials")
		Or Initialize Then
		
		ThereAreBillOfMaterialsAvailable = Not Form.Object.BillOfMaterials.IsEmpty()
			And Not Form.Object.Stage.IsEmpty();
			
		Items.FormFillInByBOM.Visible        = ThereAreBillOfMaterialsAvailable;
		Items.SecurityShowStandards.Visible       = ThereAreBillOfMaterialsAvailable;
		Items.LaborCostsShowStandards.Visible      = ThereAreBillOfMaterialsAvailable;
		Items.SoftwareToChooseAccordingToSpecification.Visible = ThereAreBillOfMaterialsAvailable And Not Form.Object.WorkPlanning;
		
	EndIf;
	
	#EndRegion
	
	// Working with operations
	#Region Operations
	
	If AttributesStructure1.Property("Department")
		Or AttributesStructure1.Property("ProductionMethod")
		Or AttributesStructure1.Property("Status")
		Or AttributesStructure1.Property("ItIsRequiredToPopulateByOperationsManually")
		Or Initialize Then
		
		// visibility of elements
		VisibilityOfElements = VisibilityOfOperationalControlElements(Form);
		
		Items.FillInTheFormForOperations.Visible     = VisibilityOfElements;
		Items.ItIsRequiredToPopulateByOperationsManually.Visible = VisibilityOfElements And Form.Object.ItIsRequiredToPopulateByOperationsManually;
		Items.FormPerformingOperations.Visible       = VisibilityOfElements;
		Items.ShiftTasksForm.Visible           = VisibilityOfElements And Form.UseShiftTasks;
		Items.ProductionOperationsForm.Visible = VisibilityOfElements;
		Items.EditTechnicalProcess.Visible       = VisibilityOfElements;
		
		// availability of elements
		ItemsAvailability = AvailabilityOfOperationalControlElements(Form);
		
		Items.FillInTheFormForOperations.Enabled     = ItemsAvailability;
		Items.FormPerformingOperations.Enabled       = ItemsAvailability And Not Form.Object.Status = StatusCompleted_1();
		Items.ShiftTasksForm.Enabled           = ItemsAvailability;
		Items.ProductionOperationsForm.Enabled = ItemsAvailability;
		Items.EditTechnicalProcess.Enabled       = ItemsAvailability;
		
		// view of the Go group
		ChildrenCount1 = 0;
		For Each Item In Items.FormGroupGoTo.ChildItems Do
			If Item.Visible Then
				ChildrenCount1 = ChildrenCount1 + 1;
			EndIf;
		EndDo;
		Items.FormGroupGoTo.Type = ?(ChildrenCount1 > 1,
			FormGroupType.Popup,
			FormGroupType.ButtonGroup);
		
	EndIf;
	
	If AttributesStructure1.Property("OperationStatus")
		Or Initialize Then
		
		// information about the presence of marriage
		Items.InformationGroupHasDefectiveGoods.Visible = Form.ThereIsDefectiveGoodsInOperations;
		
	EndIf;
	
	#EndRegion
	
	// Group Fill In
	#Region Fill
	
	If AttributesStructure1.Property("BillOfMaterials")
		Or AttributesStructure1.Property("Department")
		Or AttributesStructure1.Property("ProductionMethod")
		Or Initialize Then
		
		ChildrenCount1 = 0;
		For Each Item In Items.FormGroupFillOut.ChildItems Do
			If Item.Visible Then
				ChildrenCount1 = ChildrenCount1 + 1;
			EndIf;
		EndDo;
		Items.FormGroupFillOut.Type = ?(ChildrenCount1 > 1,
			FormGroupType.Popup,
			FormGroupType.ButtonGroup);
		If ChildrenCount1 > 1 Then
			Items.FormFillInByBOM.Title = NStr("vi = 'Theo bảng kê chi tiết các nguồn lực sản xuất';
												|ru = 'По спецификации';
												|en = 'By bill of materials'; fa = 'بر اساس فهرست مواد';
												|it = 'Per specifica';
												|pl = 'Wg specyfikacji';
												|tr = 'Ürün reçetesine göre'");
			Items.FillInTheFormForOperations.Title = NStr("vi = 'Theo giao dịch';
															|ru = 'По операциям';
															|en = 'By operations'; fa = 'By operations';
															|it = 'Per operazioni';
															|pl = 'Wg operacji';
															|tr = 'İşlemlere göre'");
		Else
			Items.FormFillInByBOM.Title = NStr("vi = 'Điền theo bảng kê chi tiết các nguồn lực sản xuất';
												|ru = 'Заполнить по спецификации';
												|en = 'Fill in by BOM'; fa = 'تکمیل بر اساس فهرست مواد';
												|it = 'Compila secondo la specifica';
												|pl = 'Wypełnij wg specyfikacji';
												|tr = 'Ürün reçetesine göre doldur'");
			Items.FillInTheFormForOperations.Title = NStr("vi = 'Điền theo giao dịch';
															|ru = 'Заполнить по операциям';
															|en = 'Fill in according to operations'; fa = 'تکمیل بر اساس عملیات';
															|it = 'Compilare per le operazioni';
															|pl = 'Wypełnij według operacji';
															|tr = 'İşlemlere göre doldur'");
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	// WorkCenterTypes
	#Region WorkCenterTypes
	
	If AttributesStructure1.Property("WorkCenterTypes")
		Or Initialize Then
		
		SeveralTypesOfRC = Form.WorkCenterTypes.GetItems().Count() > 1;
	
		If SeveralTypesOfRC Then
			Items.OperatingProcedureOfWorkCenterTypes.InputHint = "";
		Else
			Items.OperatingProcedureOfWorkCenterTypes.InputHint = NStr("vi = '<không sử dụng>';
																		|ru = '<не используется>';
																		|en = '<not used>'; fa = '<استفاده نمی‌شود>';
																		|it = '<non viene utilizzato>';
																		|pl = '<nie używa się>';
																		|tr = '<kullanılmayan>'");
		EndIf;
		
		Items.OperatingProcedureOfWorkCenterTypes.Enabled = SeveralTypesOfRC
			And (Not Object.DynamicStructure
				Or Object.OperatingProcedureOfWorkCenterTypes <> PredefinedValue("Enum.OperatingProcedureOfWorkCenterTypes.Simultaneously"));
		
	EndIf;
	
	#EndRegion
	
	// Substitutes
	#Region Substitutes
	
	If AttributesStructure1.Property("ShowAnalogues") Or Initialize Then
		
		Items.ProvisionShowAnalogues.Check = Form.ShowAnalogues;
		Items.SupplyWithMaterialsAndWorksThereAreSubstituteMaterials.Visible = Form.RightToReadSubstitutes
			And Not Object.WorkPlanning
			And Form.ShowAnalogues;
		
	EndIf;
	
	#EndRegion
	
	// Quantity in the header
	#Region QuantityInHeader
	
	If AttributesStructure1.Property("NumberOfPackagesPlan")
		Or AttributesStructure1.Property("NumberOfPackagesReal")
		Or AttributesStructure1.Property("NumberOfPackagesCanceled")
		Or AttributesStructure1.Property("PackagePlan")
		Or AttributesStructure1.Property("PackageActualData")
		Or AttributesStructure1.Property("PackageCanceled")
		Or Initialize Then
		
		Items.ReduceIncreaseProduction.Visible = Form.ThereIsRightToDivideParty
			And Object.NextStageNo <> 0
			And (Form.CountReal > Form.CountPlan // Increase
				Or (Form.CountCanceled > 0
					And Form.CountCanceled < Form.CountPlan) // Reduce
			);
		
		Items.ProductionCancel.Visible = Form.ThereIsRightToDivideParty
			And Object.NextStageNo <> 0
			And Form.CountCanceled >= Form.CountPlan
			And Form.CountReal = 0;
		
	EndIf;
	
	If AttributesStructure1.Property("NumberOfPackagesCanceled")
		Or AttributesStructure1.Property("PackageCanceled")
		Or Initialize Then
		
		Items.ProductionCreateANewStage.Visible = Form.ThereIsRightToAdd
			And Object.NumberOfPackagesCanceled > 0
			And (Object.NextStageNo <> 0
				Or Object.ProductionProcessType 
					= PredefinedValue("Enum.ProductionProcessTypes.Disassembly"));
		
		If Object.NumberOfPackagesCanceled > 0 Then
			Items.ProductionCreateANewStage.Title = StrTemplate(
				NStr("vi = 'Tạo một kỳ mới ở %1 %2';
					|ru = 'Создать новый этап на %1 %2';
					|en = 'Create a new stage on the %1 %2'; fa = 'Create a new stage on the %1 %2';
					|it = 'Creare una nuova fase su %1 %2';
					|pl = 'Utwórz nowy etap na %1 %2';
					|tr = '%2 %1 üzerine yeni aşama oluştur'"),
				Object.NumberOfPackagesCanceled,
				?(Object.PackageCanceled.IsEmpty(),
					Items.PackageCanceled.InputHint,
					Object.PackageCanceled));
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	// The Start Stage command
	#Region StartAStage
	If AttributesStructure1.Property("Status")
		Or Initialize Then
		
		Items.StartAStage.Visible =
			Object.Status = GeneratedStatus()
			Or Object.Status = StatusPending();
		
	EndIf;
	#EndRegion
	
	// The Close Stage command
	#Region CloseStage
	If AttributesStructure1.Property("Status")
		Or Initialize Then
		
		Items.CloseStage.Visible =
			Object.Status = GeneratedStatus() 
			Or Object.Status = StatusStarted() 
			Or Object.Status = StatusPending();
		
	EndIf;
	#EndRegion
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInSelectionListOfProductOwners(Form)
	
	Items = Form.Items;
	Object   = Form.Object;
	
	ChoiceList = Items.SideAndIntermediateReleaseProductOwner.ChoiceList;
	ChoiceList.Clear();
	
	If Not Object.InternalSubcontracting Then
		Return;
	EndIf;
	
	If ValueIsFilled(Object.MaterialProviderCompany) Then
		Form.TextOwnerGiver = StrTemplate(NStr("vi = 'Bên đặt gia công: %1';
												|ru = 'Давалец: %1';
												|en = 'Material provider: %1'; fa = 'Material provider: %1';
												|it = 'Давалец: %1';
												|pl = 'Material provider: %1';
												|tr = 'Tedarikçi: %1'"), Object.MaterialProviderCompany);
		ChoiceList.Add(Object.MaterialProviderCompany, Form.TextOwnerGiver);
	EndIf;
	
	If ValueIsFilled(Object.Organization) Then
		Form.TextOwnerProcessor = StrTemplate(NStr("vi = 'Bên nhận gia công: %1';
													|ru = 'Переработчик: %1';
													|en = 'Subcontractor: %1'; fa = 'Subcontractor: %1';
													|it = 'Переработчик: %1';
													|pl = 'Subcontractor: %1';
													|tr = 'Fason üretici: %1'"), Object.Organization);
		ChoiceList.Add(Object.Organization, Form.TextOwnerProcessor);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureRightToEditAttributesOfPlannedGroup(Form)
	
	If Not TMCommonUseClientServer.HasObjectAttribute(Form, "AttributeEditProhibitionParameters") Then
		Return;
	EndIf;
	
	RightToEditPlanned = Not Form.OperationsAreAssigned
		And Not Form.TechnologicalProcessType = PredefinedValue("Enum.TechnologicalProcessTypesOfStage.Individual_");
	
	For Each ProhibitionParameter In Form.AttributeEditProhibitionParameters Do
		If ProhibitionParameter.AttributeName = "NumberOfPackagesPlan"
			Or ProhibitionParameter.AttributeName = "PackagePlan" Then
			ProhibitionParameter.RightToEdit = RightToEditPlanned;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.Properties 

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

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);

EndProcedure

// End StandardSubsystems.Properties


#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(TSName, Text = "", CurrentData = Undefined)
	
	If TSName = "SupplyWithMaterialsAndWorks" And CurrentData.BatchesIndicationStatus > 8 Then
		
		FormParameters = ParametersOfQuantityAndSeriesRequestForm(ProvisionInDocumentsClientServer.SeriesSelectionMode());
		
		If FormParameters <> Undefined Then
			
			OpenForm(
				"DataProcessor.QuantityAndBatchRequest.Form",
				FormParameters,
				ThisObject,
				,
				,
				,
				New CallbackDescription("ProcessWarehouseAndBatchSelection", ThisObject, FormParameters));
				
		EndIf;
		
		Return;
	EndIf;
	
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
	
		ProductsSeriesRecalculatePrices(, AdditionalParameters.SeriesSpecificationParameters.NameTSGoods);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(Val SeriesSpecificationParameters, Val ParametersOfSeriesIndicationForm)
	
	StructureOfActions = New Structure;
	If SeriesSpecificationParameters.NameTSGoods = "ManufacturedProducts"
		Or SeriesSpecificationParameters.NameTSGoods = "SideAndIntermediateRelease"
		Or SeriesSpecificationParameters.NameTSGoods = "UnusedMaterials" Then
		StructureOfActions.Insert("UpdateNumberOfProductsWhenRegistering", True);
		AddActionsToStructureWhenChangingPackagesNumber(SeriesSpecificationParameters.NameTSGoods, ThisObject, StructureOfActions);
	EndIf;
	
	ProductsServer.ProcessSeriesIndication_(
		Object, 
		SeriesSpecificationParameters, 
		ParametersOfSeriesIndicationForm, 
		StructureOfActions);
		
	AfterChangingTSStringsProgrammaticallyOnServer(SeriesSpecificationParameters.NameTSGoods,, StructureOfActions);
	
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
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
				SeriesSpecificationParameters[TSName], IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Procedure CalculatePercentageOfCostAllocationForOutputProducts()
	
	ProductionServer.CalculatePercentageOfCostAllocationForOutputProducts(Object, CostAllocationParameters);
	
EndProcedure

&AtServer
Function ParametersOfCostShareEntryForm_(CurDataId)
	
	FormParameters = ProductionServer.ParametersOfCostShareEntryForm(Object, CostAllocationParameters, CurDataId);
	Return FormParameters;
	
EndFunction

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer(ListOfTS = Undefined, UpdateParametersForSpecifyingSeries = False)
	
	If UpdateParametersForSpecifyingSeries Then
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ProductionStage2_2));
		SetVisibilityOfSeriesElements();
	EndIf; 
	
	If ListOfTS <> Undefined Then
		ArrayTS = StrSplit(ListOfTS, ",");
		For Each TSName In ArrayTS Do
			ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters[TSName]);
		EndDo; 
	Else
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.ManufacturedProducts);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.SideAndIntermediateRelease);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.MaterialsAndWorksConsumption);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.UnusedMaterials);
	EndIf; 
	
EndProcedure

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	// Materials and works
	Items.SupplyWithMaterialsAndWorksSeries.Visible = SeriesSpecificationParameters.SupplyWithMaterialsAndWorks.UseItemsBatch
		And Not Object.WorkPlanning; // There are only works in TS
	Items.SoftwareForCompletingTheFEFOSeries.Visible = SeriesSpecificationParameters.SupplyWithMaterialsAndWorks.UseItemsBatch
		And Not Object.WorkPlanning; // There are only works in TS

	// expense and savings
	Items.UnusedMaterialsSeries.Visible = SeriesSpecificationParameters.UnusedMaterials.UseItemsBatch;
	Items.MaterialsAndWorksConsumptionSeries.Visible = SeriesSpecificationParameters.MaterialsAndWorksConsumption.UseItemsBatch;
	Items.SpecifySeriesOfConsumedMaterials.Visible = SeriesSpecificationParameters.SupplyWithMaterialsAndWorks.UseItemsBatch
		And RecordOfPerformed;

	// Output and by-products
	Items.ManufacturedProductsSeries.Visible = SeriesSpecificationParameters.ManufacturedProducts.UseItemsBatch;
	Items.ManufacturedProductsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.ManufacturedProducts.UseItemsBatch;
	Items.OutputProductsSpecifyTheSeries_3.Visible = SeriesSpecificationParameters.ManufacturedProducts.UseItemsBatch;
	
	Items.SideAndIntermediateReleaseSeries.Visible = SeriesSpecificationParameters.SideAndIntermediateRelease.UseItemsBatch;
	Items.SideAndIntermediateReleaseBatchesIndicationStatus.Visible = SeriesSpecificationParameters.SideAndIntermediateRelease.UseItemsBatch;
	Items.SideOfTheProductToSpecifySeries.Visible = SeriesSpecificationParameters.SideAndIntermediateRelease.UseItemsBatch;
	
	// Products under repair
	Items.SupplyWithMaterialsAndWorksUnderRepairBatch.Visible = SeriesSpecificationParameters.SupplyWithMaterialsAndWorks.UseItemsBatch
		And Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
			And Object.WorkPlanning;
	
EndProcedure

&AtServer
Function ThereAreFilledSeriesByFEFO()

	Return ProductsServer.ThereAreLinesWithFEFOFilledSeries(Object.SupplyWithMaterialsAndWorks);

EndFunction

&AtServer
Function FillInSeriesByFEFOServer()
	
	If ProductsServer.ThereAreLinesWithFEFOFilledSeries_(Object.SupplyWithMaterialsAndWorks) Then
		
		ProductsServer.FillInSeriesByFEFO(Object,SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
		UpdateColumnAvailableServer();
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

&AtClient
Procedure CompleteSeriesOnFEFOCompletion(Result, AdditionalParameters) Export 
	
	If Not Result Then
		
		Return;
		
	EndIf;
	
	If Not FillInSeriesByFEFOServer() Then
		
		ProductsClient.WarnAboutAbsenceOfLinesFilledByFEFO();
		
	EndIf;
	
EndProcedure

#Region SeriesOfSpentMaterials

&AtClient
Function ParametersOfFlowSeriesEditingForm()
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref",					Object.Ref);
	FormParameters.Insert("Department",			Object.Department);
	FormParameters.Insert("Purpose",				Object.Purpose);
	FormParameters.Insert("ConsumptionInOneDay",			Object.ConsumptionInOneDay);
	FormParameters.Insert("DateOfMaterialWorkConsumption",				Object.DateOfMaterialWorkConsumption);
	FormParameters.Insert("SeriesState",			"1");
	FormParameters.Insert("SeriesSpecificationParameters",	SeriesSpecificationParameters.MaterialsAndWorksConsumption);
	FormParameters.Insert("AddressMaterialsForSeries",	AddressMaterialsForSeries);
	
	Return FormParameters;
	
EndFunction

&AtClient
Procedure OpenFlowSeriesEditingForm(CallbackDescription)
	
	FormParameters = ParametersOfFlowSeriesEditingForm();
	OpenForm("Document.ProductionStage2_2.Form.EditBatchInConsumption",
		FormParameters,
		ThisObject,
		UUID,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SpecifySeriesOfConsumedMaterialsClickCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	GetMaterialsForSpecifyingSeriesFromTemporaryStorage();
	ConfigureDependentFormElements(ThisObject, "MaterialsAndWorksConsumption");
	
EndProcedure

&AtServer
Function FlowSeriesMustBeSpecified()
	
	FillInConsumptionOfMaterialsAndWorkOnProvisionDataOnServer(2);
	
	FilterStructure1 = New Structure("BatchesIndicationStatus", 1);
	Table = Object.MaterialsAndWorksConsumption.FindRows(FilterStructure1);
	
	If Table.Count() > 0 Then
		PlaceMaterialsForSpecifyingSeriesInStorage();
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Fills and pushes the materials to specify the series in the vault
//
// Parameters:
//  Mode - See Documents.ProductionStage2_2.FillInConsumptionOfMaterialsAndWorksAccordingToProvisionData.Mode
//
&AtServer
Procedure FillInPlaceMaterialsForSpecifyingSeriesInRepository(Mode = 0)
	
	FillInConsumptionOfMaterialsAndWorkOnProvisionDataOnServer(Mode);
	PlaceMaterialsForSpecifyingSeriesInStorage();
	
EndProcedure

&AtServer
Procedure PlaceMaterialsForSpecifyingSeriesInStorage()
	
	Table = Object.MaterialsAndWorksConsumption.Unload();
	If IsTempStorageURL(AddressMaterialsForSeries) Then
		AddressMaterialsForSeries = PutToTempStorage(Table, AddressMaterialsForSeries);
	Else
		AddressMaterialsForSeries = PutToTempStorage(Table, UUID);
	EndIf;
	
EndProcedure

&AtServer
Procedure GetMaterialsForSpecifyingSeriesFromTemporaryStorage()
	
	If IsTempStorageURL(AddressMaterialsForSeries) Then
		Table = GetFromTempStorage(AddressMaterialsForSeries);
		Object.MaterialsAndWorksConsumption.Load(Table);
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocumentReflectingCompletedCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	GetMaterialsForSpecifyingSeriesFromTemporaryStorage();
	ConfigureDependentFormElements(ThisObject, "MaterialsAndWorksConsumption");
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure HoldAndCloseReflectionOfCompletedCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	GetMaterialsForSpecifyingSeriesFromTemporaryStorage();
	ConfigureDependentFormElements(ThisObject, "MaterialsAndWorksConsumption");
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure ConductDocumentReflectionOfCompletedProject(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	GetMaterialsForSpecifyingSeriesFromTemporaryStorage();
	ConfigureDependentFormElements(ThisObject, "MaterialsAndWorksConsumption");
	TMCommonUseClient.Post(ThisObject, True);
	
EndProcedure

#EndRegion

#EndRegion

#Region ProductionAndPlanning

#Region ProductionSchedule

&AtServer
Function FormParametersForManuallyPlacingStageInGraph()
	
	Result = ProductionManagement.FormParametersForManuallyPlacingStageInGraph(Object, UUID);
	
	Result.ProductionSchedule = ProductionSchedule;
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillInProductionSchedule(FillingData = Undefined)
	
	ProductionSchedule = Undefined;
	
	If TheProductionScheduleIsPlanned Then
		
		If FillingData = Undefined Then
			ProductionSchedule = Documents.ProductionStage2_2.ProductionSchedule(Object.Ref);
		Else
			ProductionSchedule = DataManualPlacementInGraph(FillingData);
		EndIf;
		
	EndIf;
	
	FillInPlannedReceiptDate();
	
EndProcedure

&AtServer
Procedure FillInPlannedReceiptDate()
	
	PreviousValue = PlannedDateOfReceipt;
	
	If TheProductionScheduleIsPlanned Then
		PlannedDateOfReceipt = BegOfDay(ProductionSchedule.Ending);
	Else
		PlannedDateOfReceipt = Documents.ProductionStage2_2.PlannedDateOfReceipt(Object.Ref);
	EndIf;
	
	UpdateScheduledAdmissionDates(PlannedDateOfReceipt, PreviousValue);
	
EndProcedure

&AtClientAtServerNoContext
Function DataManualPlacementInGraph(FillingData)
	
	PlacementStructure = ProductionManagementClientServer.StructureOfStagePlacementInSchedule();
	
	FillPropertyValues(PlacementStructure, FillingData);
	
	Return PlacementStructure;
	
EndFunction

&AtServer
Procedure FillInManualPlacementData(FillingData = Undefined)
	
	Object.OccupancyOfWorkCenterTypes.Clear();
	
	If FillingData <> Undefined Then
		
		FillInProductionSchedule(FillingData.DataManualPlacementInGraph);
		
		If IsTempStorageURL(FillingData.AddressOccupiedByStage) Then
			
			BusyStage = GetFromTempStorage(FillingData.AddressOccupiedByStage);
			Object.OccupancyOfWorkCenterTypes.Load(BusyStage);
			
		EndIf;
		
	ElsIf ValueIsFilled(Object.Ref) Then
		
		BusyStage = AccumulationRegisters.AvailabilityOfWorkCenterTypes.BusyStage(Object.Ref);
		Object.OccupancyOfWorkCenterTypes.Load(BusyStage);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateScheduledAdmissionDates(NewValue, PreviousValue)
	
	// After manually changing the schedule, it is necessary to update the planned production dates
	If PreviousValue = Undefined
		 Or PreviousValue = NewValue
		 Or Not TheProductionScheduleIsPlanned Then
		Return;
	EndIf;
	
	ProductionManagement.UpdateScheduledAdmissionDates(Object, NewValue, PreviousValue);
	
EndProcedure

&AtServer
Procedure ClearManualPlacementData()
	
	FillInProductionSchedule();
	
	Object.OccupancyOfWorkCenterTypes.Clear();
	
EndProcedure

&AtServer
Procedure ProcessingStagePlacementCheckInSchedule(Cancel)
	
	If Not TheProductionScheduleIsPlanned Or Not Object.StagePlacementInProductionSchedule Then
		Return;
	EndIf;
	
	DataPath = "PlanningMethod";
	
	ProductionManagementClientServer.CheckStagePlacementInSchedule(
		ProductionSchedule, 
		Object.Ref, 
		DataPath, 
		Cancel);
	
EndProcedure

#EndRegion

#Region PlanningMethods

&AtClientAtServerNoContext
Function GetPlanningMethod(Form)
	
	If Not Form.TheProductionScheduleIsPlanned
		And Not Form.Object.DynamicStructure Then
		Return 0;
	EndIf;
	
	Object = Form.Object;
	
	If Object.StagePlacementInProductionSchedule Then
		
		Return ManualSchedulingMethod();
		
	ElsIf Object.PlanOperationsOfWorkCenterTypes 
				And ProductionResourcePlanningIsAvailable(Form) Then
		
		Return PlanningMethodForAvailability();
		
	Else
		
		Return MethodOfPlanningByTotalDuration();
		
	EndIf;
	
EndFunction

&AtServer
Procedure ProcessChangeInSchedulingMethod(FillingData = Undefined)
	
	Object.PlanOperationsOfWorkCenterTypes = (PlanningMethod = PlanningMethodForAvailability());
	Object.StagePlacementInProductionSchedule = (PlanningMethod = ManualSchedulingMethod());
	
	If Object.StagePlacementInProductionSchedule Then
		Object.PlanNotEarlierThan = Undefined;
		If Object.DynamicStructure Then
			PlanNoEarlierThanDate = '00010101';
		Else
			LabelPlanNotEarlierThan = FormattedStringPlanNotEarlier(
				Object.PlanNotEarlierThan,
				ScheduleDateFormat);
		EndIf;
		MarkPlanNotEarlierThan = False;
		FillInManualPlacementData(FillingData);
	Else
		ClearManualPlacementData();
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "PlanningMethod, ProductionSchedule");
	
EndProcedure

#EndRegion

#Region ProductionMethods

&AtClientAtServerNoContext
Function GetProductionMethod(Form)
	
	If Form.Object.ProductionByThirdParty Then
		
		Return ProductionMethodOnSide();
		
	Else
		
		Return ProductionMethodOwn();
		
	EndIf;
	
EndFunction

&AtServer
Procedure HandleChangingProductionMethodOnServer()
	
	Object.ProductionByThirdParty = (ProductionMethod = ProductionMethodOnSide());
	
	Object.ProductionByThirdParty2_5 =
		Object.ProductionByThirdParty
		And UseSubcontractOrders2_5
		And (TypeOf(Object.SubcontractOrder) = Type("Undefined")
			Or TypeOf(Object.SubcontractOrder) = Type("DocumentRef.SubcontractOrder2_5"));
	
	Object.LeaveProductsAtSubcontractor =
		False
		And Object.ProductionByThirdParty2_5
		And Object.LeaveProductsAtSubcontractor;
	
	If Object.ProductionByThirdParty Then
		WhenChoosingProductionMethodOnSide();
	EndIf;
	
	If QualityControl.UpdateActionParameters(Documents.ProductionStage2_2, Object, CacheQualityControl) Then
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProducts, StructureOfActions);
		BatchProcessingOfTablePartServer.TreatTS(Object.SideAndIntermediateRelease, StructureOfActions);
	EndIf;
	
	EmbeddingParameters = Documents.ProductionStage2_2.AvailableRemainingEmbeddingOptions(Object);
	ProvisionInDocumentsServer.AvailableBalancesWhenReadingOnServer(ThisObject, EmbeddingParameters);
	FillInStatusesForSpecifyingSeriesServer("ManufacturedProducts,SideAndIntermediateRelease", True);
	
	ConfigureDependentFormElements(ThisObject, "ProductionMethod");
	SetSoftwareVisibility();
	
	SetVisibilityOfInputCommandsBasedOn_();

EndProcedure

#EndRegion

#Region ProductionByThirdParty

&AtServer
Procedure FillInProcessorSOrderDetails()
	
	TollingOrderCreated =
		Object.ProductionByThirdParty
		And Not Object.SubcontractOrder = Undefined;
	
	If TollingOrderCreated Then
		
		SetPrivilegedMode(True);
		OrderDetails = Common.ObjectAttributesValues(Object.SubcontractOrder, "Number,Date,Posted");
		TollingOrderAttributes = New FixedStructure(OrderDetails);
		SetPrivilegedMode(False);
		
	Else
		TollingOrderAttributes = New FixedStructure;
	EndIf; 

EndProcedure

&AtClient
Procedure RecordObjectAndCreateOrderForProcessor(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Object.Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.BeingGenerated")
		Or Object.Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.Generated1") Then
		Object.Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.ForCompletion");
	EndIf;
	
	If Write() Then
		CreateOrderForProcessor(AdditionalParameters);
	EndIf; 
	
EndProcedure

&AtClient
Procedure CreateOrderForProcessor(Hyperlink)

	ProductionStage2_2ClientLocalization.CreateOrderForProcessor(Object, Hyperlink);
	
EndProcedure

// Changes stage data that is not available for processing on the side
//
&AtServer
Procedure WhenChoosingProductionMethodOnSide()

	Object.PlanOperationsOfWorkCenterTypes = False;
	PlanningMethod = GetPlanningMethod(ThisObject);
	
	ListOfTS = New Array;
	ListOfTS.Add("ManufacturedProducts");
	ListOfTS.Add("SideAndIntermediateRelease");
	For Each TSName In ListOfTS Do
		For Each RowData In Object[TSName] Do
			RowData.Manufactured = False;
		EndDo;
	EndDo; 
	
EndProcedure

#EndRegion

#Region MarkOfCompletion

&AtServer
Procedure ProcessStartOfStageExecution(ChangedBankingDetails = "")
	
	ProductionManagement.SetDateByMark(
				StageExecutionIsStarted, 
				Object.ActualStageStart);

	AddToListOfChangedBankingDetails(
				ChangedBankingDetails, 
				"StageExecutionIsStarted");

	If Not StageExecutionIsStarted
		And ValueIsFilled(Object.ActualStageEnd) Then
		
		StageIsCompleted = False;
		
		ProductionManagement.SetDateByMark(
					StageIsCompleted, 
					Object.ActualStageEnd);
		
		AddToListOfChangedBankingDetails(
					ChangedBankingDetails, 
					"StageIsCompleted");
		
	EndIf;
	
	HandleChangeOfProgressMark(ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure ProcessStageCompletion(ChangedBankingDetails = "")
	
	ProductionManagement.SetDateByMark(
				StageIsCompleted, 
				Object.ActualStageEnd,
				,
				True);
	
	AddToListOfChangedBankingDetails(
				ChangedBankingDetails, 
				"StageIsCompleted");
	
	If StageIsCompleted And Not StageExecutionIsStarted Then
		
		StageExecutionIsStarted = True;
		
		ProductionManagement.SetDateByMark(
					StageExecutionIsStarted, 
					Object.ActualStageStart);
		
		AddToListOfChangedBankingDetails(
					ChangedBankingDetails, 
					"StageExecutionIsStarted");
	
	EndIf;
	
	HandleChangeOfProgressMark(ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure ProcessStageCompletionDateChange()
	
	DateOfEventBeforeChange = EventDateCompletion;
	EventDateCompletion = BegOfDay(Object.ActualStageEnd);
	
	If Object.ProductionInOneDay Then
		
		If Object.ProductionDate = DateOfEventBeforeChange Then
			
			ProductionManagement.SetDateByMark(
				True,
				Object.ProductionDate, EventDateCompletion, True);
			
			ProductionDateWhenModifiedOnServer();
			
		EndIf;
		
	Else
		
		TablesNames = ProductionManagementClientServer.ProductTableNames();
		
		For Each TableName In TablesNames Do
			
			ChangeWHDate(
				TableName,
				"ProductionDate",
				EventDateCompletion,
				DateOfEventBeforeChange,
				True,
				"Manufactured");
			
		EndDo;
		
	EndIf;
	
	If Object.ConsumptionInOneDay Then
		
		If Object.DateOfMaterialWorkConsumption = DateOfEventBeforeChange Then
			
			ProductionManagement.SetDateByMark(
				True,
				Object.DateOfMaterialWorkConsumption, EventDateCompletion, True);
			
			DateOfExpenditureWhenChangedOnServer();
			
		EndIf;
		
	Else
		
		ChangeWHDate("MaterialsAndWorksConsumption",  "DateOfMaterialWorkConsumption",  EventDateCompletion, DateOfEventBeforeChange);
		ChangeWHDate("UnusedMaterials",      "DateOfTransaction", EventDateCompletion, DateOfEventBeforeChange);
		ChangeWHDate("SavingMaterialsBatch", "DateOfTransaction", EventDateCompletion, DateOfEventBeforeChange);
		
	EndIf;
	
	If Object.WorkPerformanceAsOneDay Then
		
		If Object.WorkExecutionDate = DateOfEventBeforeChange Then
			
			ProductionManagement.SetDateByMark(
				True,
				Object.WorkExecutionDate, EventDateCompletion, True);
			
			DateWorkWasCompletedWhenItWasChangedOnServer();
			
		EndIf;
		
	Else
		
		ChangeWHDate("LaborCosts", "ExecutionDate", EventDateCompletion, DateOfEventBeforeChange, True, "Completed2");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure HandleChangeOfProgressMark(AttributesList = "")
	
	FillingData = FillInDataWhenStatusChanges();
	
	ChangedBankingDetails = ProductionManagement.FillInStageDetailsWhenChangingProgressMark(
		Object,
		FillingData);
	
	AddToListOfChangedBankingDetails(
		AttributesList,
		ChangedBankingDetails);
	
	If CurrentStatus <> Object.Status Then
		
		AfterChangingStatusOnServer(AttributesList);
		UpdateColumnAvailableServer();
		
	Else
		
		ConfigureDependentFormElements(ThisObject, AttributesList);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessStatusChangeOnServer()
	
	FillingData = FillInDataWhenStatusChanges();
	
	ChangedBankingDetails = ProductionManagement.FillInStageDetailsWhenStatusChanges(
		Object, 
		CurrentStatus, 
		FillingData);
	
	AfterChangingStatusOnServer(ChangedBankingDetails);
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Procedure AfterChangingStatusOnServer(ChangedBankingDetails = "")
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ProductionStage2_2));
	
	SetVisibilityOfSeriesElements();
	
	RecalculateNumberOfUnitsInHeader();
	
	FillInServiceDetails();
	FillInServiceDetailsOfTableParts(ChangedBankingDetails);

	ConfigureDependentFormElements(ThisObject, ChangedBankingDetails);
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

#EndRegion

#Region State

&AtServer
Procedure FillInStateOfOperations()
	
	OperationsStarted = False;
	ThereIsDefectiveGoodsInOperations = False;
	
	If UseOperationManagement
		And Not Object.ProductionByThirdParty Then
	
		CheckedStatuses = ProductionManagementClientServer.StatusesAvailableByOperationalManagement(ThisObject);
		If CheckedStatuses.Find(Object.Status) <> Undefined Then
			
			QueryText = "
			|SELECT
			|	MAX(CASE
			|		WHEN Operations.DefectiveGoodsCount > 0
			|			THEN TRUE
			|		ELSE FALSE
			|	END) AS ThereIsDefectiveGoodsInOperations
			|FROM
			|	Document.ProductionOperation2_2 AS Operations
			|WHERE
			|	Operations.Stage = &Stage
			|	AND Operations.Posted
			|HAVING
			|	COUNT(Operations.Ref) > 0";
			
			Query = New Query;
			Query.Text = QueryText;
			Query.SetParameter("Stage", Object.Ref);
			
			SetPrivilegedMode(True);
			QueryResult = Query.Execute();
			SetPrivilegedMode(False);
			
			If Not QueryResult.IsEmpty() Then
				
				Selection = QueryResult.Select();
				Selection.Next();
				
				OperationsStarted = True;
				ThereIsDefectiveGoodsInOperations       = Selection.ThereIsDefectiveGoodsInOperations;
				
			EndIf;
		
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ChangeTechnicalProcess

&AtServerNoContext
Procedure UnblockDataForEditingATServer(Ref, UUID)
	
	UnlockDataForEdit(Ref, UUID);
	
EndProcedure

&AtClient
Procedure NavigationLinkEditProcessEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Write() Then
		OpenProcessEditingForm();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenProcessEditingForm()
	
	If Not Modified Then
		UnblockDataForEditingATServer(Object.Ref, UUID);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Stage", Object.Ref);
	FormParameters.Insert("Mode", ProductionProcessEditorClientServer.ModeFromStageForm());
	
	CallbackDescription = New CallbackDescription(
		"OpenProcessEditingFormCompletion",
		ThisObject);
	
	OpenForm(
		"DataProcessor.ProductionProcessEditor.Form",
		FormParameters,
		ThisObject,
		Object.Ref,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpenProcessEditingFormCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> Undefined Then
		
		OpenProcessEditingFormForEndingAtServer(ClosingResult);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OpenProcessEditingFormForEndingAtServer(ClosingResult)
	
	AttributesList = New Array;
	AttributesList.Add("TechnologicalProcess");
	
	If ClosingResult.Property("AddressOfStageDataToUpdate")
		And IsTempStorageURL(ClosingResult.AddressOfStageDataToUpdate) Then
		
		DataForUpdate = GetFromTempStorage(ClosingResult.AddressOfStageDataToUpdate); // Structure
		
		If ValueIsFilled(DataForUpdate) Then
			
			For Each KeyAndValue In DataForUpdate Do
				
				TSName = KeyAndValue.Key;
				
				Object[TSName].Load(KeyAndValue.Value);
				
				AfterChangingTSStringsProgrammaticallyOnServer(TSName);
				
				Modified = True;
				
				AttributesList.Add(TSName);
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	ReadExternalAttributes();
	
	LabelSpecification = FormattedStringLabelSpecification();
	
	ConfigureDependentFormElements(ThisObject, StrConcat(AttributesList, ","));
	
EndProcedure

#EndRegion

#Region Other

&AtClientAtServerNoContext
Procedure CalculateNumberOfTypesOfWorkCenters(Form)
	
	Form.TypesOfWorkCentersNumber = Form.WorkCenterTypes.GetItems().Count();
	
EndProcedure

&AtClient
Procedure OpenManualChartEditingForm()
	
	If Not TheProductionScheduleIsPlanned Then
		Return;
	EndIf;
	
	NameOfFormToOpen_ = "Document.ProductionStage2_2.Form.StagePlacementInProductionSchedule";
	
	FormParameters = FormParametersForManuallyPlacingStageInGraph();
	
	CallbackDescription = New CallbackDescription(
				"OpenManualChartEditingFormCompletion", 
				ThisObject);
	
	OpenForm(
			NameOfFormToOpen_, 
			FormParameters, 
			ThisObject,,,, 
			CallbackDescription, 
			FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure OpenManualChartEditingFormCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult <> Undefined
		And ClosingResult.StagePlacementInProductionSchedule Then
		
		PlanningMethod = ManualSchedulingMethod(); 
		
		ProcessChangeInSchedulingMethod(ClosingResult);
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function NumberOfProductsPerBatch(ProductionLot, Stage)
	
	Result = New Structure;
	Result.Insert("NumberOfPackages", 0);
	Result.Insert("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	
	QueryText = 
		"SELECT
		|	SUM(
		|		CASE
		|			WHEN ProductionStage.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
		|				OR ProductionStage.NumberOfPackagesReal + ProductionStage.NumberOfPackagesCanceled >= ProductionStage.NumberOfPackagesPlan
		|				THEN ProductionStage.NumberOfPackagesReal
		|			ELSE ProductionStage.NumberOfPackagesPlan - ProductionStage.NumberOfPackagesCanceled
		|		END) AS NumberOfPackages,
		|	SUM(
		|		CASE
		|			WHEN ProductionStage.Status = VALUE(Enum.StatusesOfProductionStages2_2.Completed)
		|				OR ProductionStage.NumberOfPackagesReal * ISNULL(&PackagingFactorFact, 1)
		|					+ ProductionStage.NumberOfPackagesCanceled * ISNULL(&PackagingFactorCanceled, 1)
		|					>= ProductionStage.NumberOfPackagesPlan * ISNULL(&PackagingFactorPlan, 1)
		|				THEN ProductionStage.NumberOfPackagesReal * ISNULL(&PackagingFactorFact, 1)
		|			ELSE ProductionStage.NumberOfPackagesPlan * ISNULL(&PackagingFactorPlan, 1)
		|				- ProductionStage.NumberOfPackagesCanceled * ISNULL(&PackagingFactorCanceled, 1)
		|		END) AS Count,
		|	CASE
		|		WHEN MIN(ProductionStage.PackagePlan = ProductionStage.PackageActualData
		|						AND ProductionStage.PackagePlan = ProductionStage.PackageCanceled) = TRUE
		|			THEN MIN(ProductionStage.PackagePlan)
		|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	END AS Package
		|		
		|FROM
		|	Document.ProductionStage2_2 AS ProductionStage
		|
		|WHERE
		|	ProductionStage.ProductionLot = &ProductionLot
		|	AND ProductionStage.Stage = &Stage
		|	AND ProductionStage.Posted
		|
		|HAVING
		|	SUM(ProductionStage.NumberOfPackagesPlan) > 0";
	
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactorPlan",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductionStage.PackagePlan",
			"ProductionStage.ProductionLot.MainProductProducts"));
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactorFact",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductionStage.PackageActualData",
			"ProductionStage.ProductionLot.MainProductProducts"));
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactorCanceled",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductionStage.PackageCanceled",
			"ProductionStage.ProductionLot.MainProductProducts"));
	
	Query = New Query(QueryText);
	Query.SetParameter("ProductionLot", ProductionLot);
	Query.SetParameter("Stage", Stage);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		If ValueIsFilled(Selection.Package) Then
			Result.NumberOfPackages = Selection.NumberOfPackages;
			Result.Package = Selection.Package;
		Else
			Result.NumberOfPackages = Selection.Count;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function VisibilityOfOperationalControlElements(Form)
	
	Return Form.UseOperationManagement
		And Not Form.Object.ProductionByThirdParty
		And Not Form.Object.WorkPlanning
		And Not Form.RecordOfPerformed
		And Not Form.Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials");
	
EndFunction

&AtClientAtServerNoContext
Function AvailabilityOfOperationalControlElements(Form)
	
	CheckedStatuses = ProductionManagementClientServer.StatusesAvailableByOperationalManagement(Form);
	Return CheckedStatuses.Find(Form.Object.Status) <> Undefined;
	
EndFunction

&AtClientAtServerNoContext
Function ProductionResourcePlanningIsAvailable(Form)
	
	Return (Form.PlanningByProductionResourcesIsUsed Or Form.Object.DynamicStructure)
			And Not Form.Object.WorkPlanning
			And Not Form.Object.ProductionByThirdParty;
	
EndFunction

#EndRegion

#EndRegion

#Region Supply

&AtClient
Procedure Attachable_CheckCompletionOfInventoryAllocationTask()
	
	Error = False;
	If ProvisionInDocumentsClient.NeedToUpdateAvailabilityAfterRecording(ThisObject,
		"Attachable_CheckCompletionOfInventoryAllocationTask", Error) Then
		ProvisionInDocumentsClient.ConfigureHyperlinksSupplyForecastAfterRecording(ThisObject, Error);
		ReflectAnalogsInSupplyForecastHyperlink(ThisObject);
		UpdateColumn = ProvisionInDocumentsClient.ToUpdateColumnAvailableAfterInventoryAllocation(ThisObject);
		If UpdateColumn Then
			UpdateColumnAvailableAfterInventoryAllocation();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateColumnAvailableAfterInventoryAllocation()
	ProvisionInDocumentsServer.UpdateAvailabilityAfterRecording(ThisObject);
EndProcedure

&AtServer
Function AddressOfMovementTableInRepository()
	
	Return ProvisionInDocumentsServer.AddressOfMovementTableInRepository(ThisObject);
	
EndFunction

&AtServer
Function FillInCollateralFromCollateralStateForm(ActionCode, AddressAnalyst, FillParameters)
	
	Modified = True;
	Changes = ProvisionInDocumentsServer.FillInCollateralFromCollateralStateForm(
		ActionCode,
		AddressAnalyst,
		ThisObject);
	
	Mode = ProvisionInDocumentsClientServer.SoftwareStateMode();
	AfterFillingOutCollateral(Changes, Mode, FillParameters);
	AddressOfTheMovementTable = AddressOfMovementTableInRepository();
	Return AddressOfTheMovementTable;
	
EndFunction

&AtServer
Function ProvidingSetAction(ActionCode, SetActionForSelectedLines = True)
	
	Result = ProvisionInDocumentsServer.ProvidingSetActionResultStructure();
	
	If ActionCode = "FLAG_UNITED" Or ActionCode = "FLAG_NOTABLE" Then
		
		// Restriction of the choice of actions for manufactured semi-finished products.
		IDs = New Array();
		If SetActionForSelectedLines Then
			RowsCollection = New Array();
			For Each Id In Items.SupplyWithMaterialsAndWorks.SelectedRows Do
				RowsCollection.Add(Object.SupplyWithMaterialsAndWorks.FindByID(Id));
			EndDo;	
		Else
			RowsCollection = Object.SupplyWithMaterialsAndWorks;
		EndIf;
		For Each LineProducts_ In RowsCollection Do
			If ActionCode = "FLAG_NOTABLE"
					And LineProducts_.Produced Then
				Continue;
			EndIf;
			IDs.Add(LineProducts_.GetID());
		EndDo;
		
		Changes = ProvisionInDocumentsServer.SetActionApart(
			ActionCode,
			ThisObject,
			IDs,
			Not RecordOfPerformed);
		
		ModifiedRows = New Array();
		For Each Update In Changes.ChangesTable Do
			ModifiedRows.Add(Update.String);
		EndDo;
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInAssignmentInProductionPhase");
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		CollectionOnForm = ProvisionInDocumentsClientServer.CollectionOnForm(
			ThisObject, AvailableRemainingEmbeddingOptions);
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ModifiedRows,
			StructureOfActions,
			CollectionOnForm,
			CachedValues);
		
		UpdateColumnAvailableServer();
		
	Else
		
		IDs = New Array();
		If SetActionForSelectedLines Then
			For Each Id In Items.SupplyWithMaterialsAndWorks.SelectedRows Do
				IDs.Add(Id);
			EndDo; 
		Else 
			For Each LineProducts_ In Object.SupplyWithMaterialsAndWorks Do
				IDs.Add(LineProducts_.GetID());
			EndDo; 
		EndIf;
		
		Changes = ProvisionInDocumentsServer.SetAction(
			ActionCode,
			ThisObject,
			IDs);
			
		FillPropertyValues(Result, Changes);
		
		If Changes.ChangesTable <> Undefined Then
			AfterFillingOutCollateral(
				Changes.ChangesTable,
				ProvisionInDocumentsClientServer.ActionSelectionMode(),
				Result);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function ProcessWarehouseAndBatchSelectionOnServer(ValueSelected, FormParameters, FillParameters)

	Modified = True;
	Changes = ProvisionInDocumentsServer.WhenChoosingWarehouse(
		ValueSelected,
		ThisObject,
		Items.SupplyWithMaterialsAndWorks.CurrentRow,
		FormParameters.FieldsToFillIn);
		
	AfterFillingOutCollateral(Changes, FormParameters.Mode, FillParameters);
	TextProcessedLines = ProvisionInDocumentsServer.TextProcessedLines(Changes.Count());
	Return TextProcessedLines;
	
EndFunction

&AtClientAtServerNoContext
Function DocumentParametersForSoftwareActions(Form)
	
	DocumentParameters = New Structure();
	DocumentParameters.Insert("Form",                              Form);
	DocumentParameters.Insert("Collection",                          Form.Object.SupplyWithMaterialsAndWorks);
	DocumentParameters.Insert("SecurityOptionAndFlagSeparately", Undefined);
	
	Return DocumentParameters;
	
EndFunction

&AtClient
Procedure HyperlinkStateOfProvisionClickGeneral()
	
	If ThereAreAnalogues And RightToReadSubstitutes And Not Object.WorkPlanning Then
		
		OpeningParameters = ParametersOfReplacementAssistantForm();
		
		Notification = New CallbackDescription("AfterReplacementViaAssistant", ThisObject);
		
		OpenForm("Document.EngineeringChangeOrder.Form.ReplacementWizard", OpeningParameters, ThisObject, UUID,,,
			Notification,FormWindowOpeningMode.LockOwnerWindow);
		
	Else	
		
		OpenSupplyForecastOfOrders();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeShippingDateOnServer(NewDate)
	
	Object.DateOfShipment = NewDate;
	FillInWHDate("SupplyWithMaterialsAndWorks", "DateOfShipment", Object.DateOfShipment);
	
	If (RecordOfPerformed
			Or Object.WorkPlanning) Then
		Object.DateOfMaterialWorkConsumption = Object.DateOfShipment;
		FillInWHDate("MaterialsAndWorksConsumption",  "DateOfMaterialWorkConsumption", Object.DateOfMaterialWorkConsumption);
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "DateOfShipment");
	
EndProcedure

&AtServer
Procedure ProvisionOfMaterialsAndWorksSoftwareOptionWhenChangedOnServer(FillParameters)
	
	Changes = ProvisionInDocumentsServer.SupplyOptionOnChange(
		ThisObject,
		Items.SupplyWithMaterialsAndWorks.CurrentRow);
		
	Mode = ProvisionInDocumentsClientServer.ModeSelectActionDirectly();
	AfterFillingOutCollateral(Changes, Mode, FillParameters);
	
EndProcedure

&AtClient
Procedure ProvisionOfMaterialsAndWorksOptionOfProvisionInCaseOfChangeAfterQuestion(Response, AdditionalParameters) Export
	
	FillParameters = ProvisionInDocumentsClient.ParametersForProcessingShipmentDatesAfterFillingInCollateral(Response);
	ProvisionOfMaterialsAndWorksSoftwareOptionWhenChangedOnServer(FillParameters);
	
EndProcedure

&AtClient
Procedure ProvidingMaterialsAndWorksSelectionIsAvailable(CurrentData)
	
	FormParameters = ParametersOfQuantityAndSeriesRequestForm(Undefined);
	
	If FormParameters <> Undefined Then
		OpenForm("DataProcessor.QuantityAndBatchRequest.Form", FormParameters, ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure SupplyWithMaterialsAndWorksAfterDeleteRowServer()
	
	If RightToReadSubstitutes And ShowAnalogues And Not Object.WorkPlanning Then
		NotePresenceOfAnalogues();
	EndIf;
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Procedure ProvisionOfMaterialsAndWorksInCaseOfChangesInProductRange()
	
	UpdateColumnAvailableServer();
	If RightToReadSubstitutes And ShowAnalogues And Not Object.WorkPlanning Then
		NotePresenceOfAnalogues();
	EndIf;
	
EndProcedure

&AtServer
Procedure ProvisionOfMaterialsAndWorksInCaseOfChangesInCharacteristics()
	
	LineOfATabularSection = Object.SupplyWithMaterialsAndWorks.FindByID(
		Items.SupplyWithMaterialsAndWorks.CurrentRow);
	
	UpdateColumnAvailableServer();
	If RightToReadSubstitutes And ShowAnalogues And Not Object.WorkPlanning Then
		NotePresenceOfAnalogues();
	EndIf;
	
EndProcedure

&AtServer
Procedure EnsuringToSetActionAfterQuestion(Response, Result)
	
	ResultStructure1 = ProvisionInDocumentsServer.SetActionAfterQuestion(Response, Result, ThisObject);
	AfterFillingOutCollateral(
		ResultStructure1.ChangesTable,
		ProvisionInDocumentsClientServer.ActionSelectionMode(),
		ResultStructure1);
	
EndProcedure

&AtClient
Procedure ProvidingSetActionWithQuestion(ActionCode)
	
	Result = ProvidingSetAction(ActionCode);
	
	QuestionAsked = ProvisionInDocumentsClient.ShowIssueOfFillingSoftwareWithWholePackages(
		ThisObject,
		Object.SupplyWithMaterialsAndWorks,
		Result,
		"AfterQuestionOfFillingPackageWithWholePackages");
		
	If Not QuestionAsked Then
		
		ProvisionInDocumentsClient.ShowQuestionUncheckShipByOneDate(
			ThisObject,
			Object.SupplyWithMaterialsAndWorks,
			Result,
			"AfterQuestionRemoveFlagShipByOneDate");
			
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateColumnAvailableServer()
	
	ProvisionInDocumentsServer.UpdateColumnAvailable(ThisObject);
	
EndProcedure

&AtClient
Procedure ProcessWarehouseAndBatchSelection(ValueSelected, FormParameters) Export
	
	If Not ProvisionInDocumentsClient.ThereAreSelectedProducts(ValueSelected) Then
		Return;
	EndIf;
	
	ProvisionInDocumentsClient.ShowQuestionUncheckShipByOneDateAfterSelectingCollateral(
		ThisObject,
		ValueSelected,
		FormParameters,
		"ProcessSelectionWarehouseAndBatchAfterQuestion");
	
EndProcedure

&AtClient
Procedure ProcessSelectionWarehouseAndBatchAfterQuestion(Response, Var_Parameters) Export
	
	FillParameters = ProvisionInDocumentsClient.ParametersForProcessingShipmentDatesAfterFillingInCollateral(Response);
	
	Notification = ProcessWarehouseAndBatchSelectionOnServer(
		Var_Parameters.ValueSelected,
		Var_Parameters.FormParameters,
		FillParameters);
	
	NotificationText1 = ProvisionInDocumentsClient.TextProcessingAlertsWarehouseAndBatchSelection(Var_Parameters.FormParameters.Mode);
	ShowUserNotification(NotificationText1, , Notification);
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingModifiabilityOfForm()
	
	If FormModified <> Modified Then
		
		FormModified = Modified;
		ProvisionInDocumentsClient.ConfigureHyperlinkedSoftwareState(ThisObject);
		ReflectAnalogsInSupplyForecastHyperlink(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterQuestionOfFillingPackageWithWholePackages(Response, Result) Export
	
	QuestionAsked = ProvisionInDocumentsClient.ShowQuestionUncheckShipOneDateAfterQuestion(
		ThisObject,
		Object.SupplyWithMaterialsAndWorks,
		Result,
		Response,
		"AfterQuestionRemoveFlagShipByOneDate");
		
	If Not QuestionAsked Then
		
		EnsuringToSetActionAfterQuestion(Response, Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterQuestionRemoveFlagShipByOneDate(Response, Result) Export
	
	EnsuringToSetActionAfterQuestion(Response, Result);
	
EndProcedure

&AtServer
Procedure AfterFillingOutCollateral(Changes, Mode = Undefined, FillParameters = Undefined)
	
	ChangedBankingDetails = Documents.ProductionStage2_2.AfterFillingOutCollateral(
		Object,
		Changes,
		Mode,
		FillParameters,
		FillInDataWhenStatusChanges());
	ConfigureDependentFormElements(ThisObject, "NotShipInInstallments");
		
	StructureOfActions = New Structure();
	ProvisionInDocumentsClientServer.AddCollateralActions(
		StructureOfActions,
		"WarehouseIsRequired,DateOfShipmentRequired_",
		DocumentParametersForSoftwareActions(ThisObject));
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	CollectionOnForm = ProvisionInDocumentsClientServer.CollectionOnForm(
		ThisObject, AvailableRemainingEmbeddingOptions);
	
	RowsToProcess = New Array();
	
	For Each Update In Changes Do
		RowsToProcess.Add(Update.String);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		CollectionOnForm,
		CachedValues);
	
	ProvisionInDocumentsClientServer.FillInServiceDetails(
		Object.SupplyWithMaterialsAndWorks,
		DateOfShipmentRequired_,
		WarehouseIsRequired);
	
	If CurrentStatus <> Object.Status Then
		AfterChangingStatusOnServer(ChangedBankingDetails);
	EndIf;
	UpdateColumnAvailableServer();
	
EndProcedure

&AtServer
Procedure SetSoftwareVisibility()
	
	If RecordOfPerformed Then
		
		Items.SupplyWithMaterialsAndWorksSoftwareToShip.Visible                     = False;
		Items.SupplyWithMaterialsAndWorksProvisionOfBackup.Visible                 = False;
		Items.SupplyWithMaterialsAndWorksCollateralToCollateral.Visible                  = False;
		Items.SupplyWithMaterialsAndWorksReserveCollateralAsItBecomesAvailable.Visible = False;
		Items.SupplyWithMaterialsAndWorksProvisionDoNotProvide.Visible                = False;
		Items.SupplyWithMaterialsAndWorksAvailable.Visible                                 = False;
		Items.ToCreateAnAdjustmentPurposeTheRemovalOfTheReserve.Visible                 = False;
		Items.SoftwareToCreateACorrectionPurposeRedundant.Visible                = False;
		Items.ProvisionShowAnalogues.Visible                                             = False;
		Items.SoftwareToPickUpAnalogs.Visible                                            = False;
		Items.ReplaceProvisionsWithAnalogues.Visible                                           = False;
		Items.ReplaceProvisionsWithAnalogues.Visible                                           = False;
		Items.PagesHyperlinkSoftwareStatus.Visible                                 = False;
		Items.PagesStateOfSoftwareStage.Visible                                        = False;
		Items.SupplyWithMaterialsAndWorksContextMenuSoftwareToShip.Visible      = False;
		Items.SupplyWithMaterialsAndWorksContextMenuProvisionOfBackup.Visible  = False;
		Items.SupplyWithMaterialsAndWorksContextMenuCollateralToCollateral.Visible   = False;
		Items.ProvisionOfMaterialsContextMenuProvisionReserveAsReceived.Visible = False;
		Items.SupplyWithMaterialsAndWorksContextMenuProvisionDoNotProvide.Visible = False;
		Items.SupplyWithMaterialsAndWorksSupplyOption.Visible                       = False;
		
	Else
		
		VisibilityStandardCommands = False;
		VisibilityOfStageTeam = False;
		
		If Object.DynamicStructure Then
			If ProvisionInDocumentsServer.HaveRightToViewStateHyperlink() Then
				VisibilityOfStageTeam = True;
				Items.PagesStateOfSoftwareStage.CurrentPage
					= Items.SoftwareStatePageDynamicStructure;
			EndIf;
		Else
			If ProvisionInDocumentsServer.HaveRightToViewStateHyperlink() Then
				If Object.ProductionByThirdParty
						And Object.SubcontractOrder <> Undefined
						And Common.ObjectAttributeValue(Object.SubcontractOrder, "Posted") Then
					VisibilityOfStageTeam = True;
					Items.PagesStateOfSoftwareStage.CurrentPage =
						Items.StateOfOrderSecurityPageForProcessor;
				Else
					VisibilityStandardCommands = True;
					ProvisionInDocumentsServer.ConfigureHyperlinkedSoftwareState(ThisObject);
				EndIf;
			EndIf;
		EndIf;
		
		ReflectAnalogsInSupplyForecastHyperlink(ThisObject);
		Items.PagesHyperlinkSoftwareStatus.Visible = VisibilityStandardCommands;
		Items.PagesStateOfSoftwareStage.Visible = VisibilityOfStageTeam;
		
		Items.SupplyWithMaterialsAndWorksProvisionOfBackup.Visible =
			Not Object.WorkPlanning;
		Items.SupplyWithMaterialsAndWorksContextMenuProvisionOfBackup.Visible =
			Not Object.WorkPlanning;
		Items.SupplyWithMaterialsAndWorksReserveCollateralAsItBecomesAvailable.Visible =
			Not Object.DynamicStructure;
		Items.ProvisionOfMaterialsContextMenuProvisionReserveAsReceived.Visible =
			Not Object.DynamicStructure;
		
	EndIf;
	
	Items.DateOfShipment.ToolTip = ProvisionInDocumentsServer.HintShipmentDate();
	
EndProcedure

&AtServer
Function SoftwareSelectionParameters(Mode)
	
	FormParameters = ProvisionInDocumentsServer.SoftwareSelectionParameters(
		ThisObject,
		Items.SupplyWithMaterialsAndWorks.CurrentRow,
		Mode,
		?(RecordOfPerformed, WarehousesToReflectCompleted(Object.Department), Undefined));
	
	Return FormParameters;
	
EndFunction

&AtServerNoContext
Function WarehousesToReflectCompleted(Department)
	
	Query = New Query();
	Query.Text =
		"SELECT ALLOWED
		|	Warehouses.Ref AS Ref
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.ShopFloorStockroom
		|		AND Warehouses.Department = &Department";
	Query.SetParameter("Department", Department);
	Warehouses = Query.Execute().Unload().UnloadColumn("Ref");
	Return Warehouses;
	
EndFunction

&AtServer
Procedure ShowStandardsWhenChangingOnServer(ListOfTS = Undefined)
	
	If (ListOfTS = Undefined Or Find(ListOfTS, "SupplyWithMaterialsAndWorks") > 0) Then
		FillInStandards("SupplyWithMaterialsAndWorks");
	EndIf;
	
	If (ListOfTS = Undefined Or Find(ListOfTS, "LaborCosts") > 0) Then
		FillInStandards("LaborCosts");
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "ShowStandards");
	
EndProcedure

&AtServer
Procedure FillInStandards(TSName, FillInLines = Undefined)
	
	RequiredToFillIn = False;
	
	If FillInLines <> Undefined Then
		RowsArray = FillInLines;
	Else
		RowsArray = Object[TSName];
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks"
		And ShowStandardsMaterials Then
	
		DataArray = New Array;
		For Each CurrentData In RowsArray Do
			RowData = New Structure("Products,Characteristic,ItemVariantsAreUsed,Package");
			FillPropertyValues(RowData, CurrentData);
			DataArray.Add(RowData);
		EndDo;
		RequiredToFillIn = True;
		
	ElsIf TSName = "LaborCosts"
		And ShowStandardsLaborCosts Then
		
		DataArray = New Array;
		For Each CurrentData In RowsArray Do
			RowData = New Structure("WorkKind");
			FillPropertyValues(RowData, CurrentData);
			DataArray.Add(RowData);
		EndDo;
		RequiredToFillIn = True;
		
	EndIf;
	
	If RequiredToFillIn Then
		
		StandardsFromRepository = GetStandardsFromTemporaryStorage();
		
		Standards = GetStandardsWhenChangingRows(TSName, DataArray, StandardsFromRepository);
		For Cnt = 0 To RowsArray.Count() - 1 Do
			RowsArray[Cnt].NormativeStandard = Standards[Cnt];
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Function GetStandardsFromTemporaryStorage()

	If IsTempStorageURL(StorageAddressStandards) Then
		
		Result = GetFromTempStorage(StorageAddressStandards);
		Return Result;
		
	EndIf;
	
	Result = New Structure();
	
	SpecificationData = GetStandardsForSpecifications(True, "MaterialsAndServices,IncomingProducts,LaborCosts");
	
	If SpecificationData <> Undefined Then
		
		Table = SpecificationData.MaterialsAndServices.Copy(, "Products,Characteristic,Package,PackageData,NumberOfPackages"); // ValueTable - 
		Table.GroupBy("Products,Characteristic,Package,PackageData", "NumberOfPackages");
		Result.Insert("SupplyWithMaterialsAndWorks", Table);
		
		Table = SpecificationData.LaborCosts.Copy(, "WorkKind,Count"); // ValueTable - 
		Table.GroupBy("WorkKind", "Count");
		Result.Insert("LaborCosts", Table);
		
	EndIf;
	
	StorageAddressStandards = PutToTempStorage(Result, UUID);
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function GetStandardsWhenChangingRows(Val TSName, Val DataArray, Val AddressOrRegulations)
	
	If IsTempStorageURL(AddressOrRegulations) Then
		StandardsFromRepository = GetFromTempStorage(AddressOrRegulations);
	Else
		StandardsFromRepository = AddressOrRegulations;
	EndIf;
	
	If ValueIsFilled(StandardsFromRepository) And StandardsFromRepository.Property(TSName) Then
		Standards = StandardsFromRepository[TSName];
	Else
		Standards = Undefined;
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		TheStructureOfTheSearch = New Structure("Products,Characteristic");
		
		Result = ProductionManagement.GetStandards(
			Standards,
			DataArray,
			TheStructureOfTheSearch,
			True);
		
	ElsIf TSName = "LaborCosts" Then
		
		TheStructureOfTheSearch = New Structure("WorkKind");
		
		Result = ProductionManagement.GetStandards(
			Standards,
			DataArray,
			TheStructureOfTheSearch,
			False);
	
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function GetStandardsForSpecifications(ReceiveMaterialsOnDemand, Val ListOfData = Undefined)
	
	ProductionBatchDataCopy = Common.CopyRecursive(ProductionBatchData, False);
	// we change the quantity to the planned quantity from the current stage
	ProductionBatchDataCopy.Count = CountPlan;
	
	Return Documents.ProductionStage2_2.GetStandardsForSpecifications(
		ProductionBatchDataCopy,
		ReceiveMaterialsOnDemand,
		ListOfData,
		New Structure("Stage", Object.Stage));
	
EndFunction

&AtClient
Function ParametersOfQuantityAndSeriesRequestForm(Mode)
	
	CheckParameters = SupplyClientServer.InitializeFillVerificationParameters(
		"SupplyWithMaterialsAndWorks", 
		NStr("vi = 'Đảm bảo';
			|ru = 'Обеспечение';
			|en = 'Supply'; fa = 'Supply';
			|it = 'Approvvigionamento';
			|pl = 'Zaopatrzenie';
			|tr = 'Tedarik'"));
		
	CheckParameters.Fields.Delete("Warehouse");
	
	If Not SupplyClient.CheckFilling(
				Object,
				Object.SupplyWithMaterialsAndWorks,
				Items.SupplyWithMaterialsAndWorks.CurrentRow,
				CheckParameters,
				Undefined,
				Mode) Then
		Return Undefined;
	EndIf;
	
	If (RecordOfPerformed
			Or Object.WorkPlanning)
		And Not ValueIsFilled(Object.Department) Then
		
		ClearMessages();
		MessageText = NStr("vi = 'Chưa điền bộ phận của công đoạn.';
							|ru = 'Не заполнено подразделение этапа.';
							|en = 'Stage business unit is required.'; fa = 'Stage business unit is required.';
							|it = 'Reparto della fase non compilato.';
							|pl = 'Nie wypełniono dział etapu.';
							|tr = 'Aşama departmanı doldurulmadı.'");
		CommonClient.MessageToUser(MessageText);
		
		Return Undefined;
		
	EndIf;

	FormParameters = SoftwareSelectionParameters(Mode);
	FormParameters.SeriesSpecificationParameters = SeriesSpecificationParameters.SupplyWithMaterialsAndWorks;
	
	Return FormParameters;
	
EndFunction

// This procedure should be used if the rows were added programmatically (not interactively), for example, when pasting from
// a buffer, or when filling in according to the specification. The procedure performs actions that depend on the data in the rows.
//
&AtServer
Procedure AfterChangingTSStringsProgrammaticallyOnServer(TSName, ArrayOfRowIDs_ = Undefined, StructureOfPreviouslyPerformedActions = Undefined)
	
	RowsArray = Undefined;
	RowsCollection = Object[TSName]; // FormDataCollection
	If ArrayOfRowIDs_ <> Undefined Then
		RowsArray = New Array;
		For Each RowID In ArrayOfRowIDs_ Do
			RowsArray.Add(Object[TSName].FindByID(RowID));
		EndDo; 
		RowsCollection = RowsArray; // Array of FormDataCollectionItem
	EndIf;
	
	If StructureOfPreviouslyPerformedActions = Undefined Then
		StructureOfPreviouslyPerformedActions = New Structure;
	EndIf;
	
	DivisionChanged_ = False; 
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		For Each CurrentData In RowsCollection Do
			
			If Object.NotShipInInstallments And Object.DateOfShipment <> '000101010000' Then
				CurrentData.DateOfShipment = Object.DateOfShipment;
			EndIf;
			
			If CurrentData.Department <> Object.Department Then
				CurrentData.Department = Object.Department;
				DivisionChanged_ = True;
			EndIf;
			
		EndDo;
		
		WarehousesClientServer.FillDefaultWarehouse(
				UseSeveralWarehouses, 
				DefaultWarehouse, 
				RowsCollection);
				
		UpdateColumnAvailableServer();
		
	ElsIf TSName = "MaterialsAndWorksConsumption" Then
		
		For Each CurrentData In RowsCollection Do
			
			If Object.ConsumptionInOneDay And Object.DateOfMaterialWorkConsumption <> '000101010000' Then
				CurrentData.DateOfMaterialWorkConsumption = Object.DateOfMaterialWorkConsumption;
			EndIf;
			
			If CurrentData.Department <> Object.Department Then
				CurrentData.Department = Object.Department;
				DivisionChanged_ = True;
			EndIf;
			
		EndDo; 
		
	ElsIf TSName = "UnusedMaterials" Then
		
		For Each CurrentData In RowsCollection Do
			
			If Not CurrentData.ToExpenseAs Then
				WarehousesClientServer.FillDefaultWarehouse(
						UseSeveralWarehouses, 
						DefaultWarehouse, 
						CurrentData,
						"Recipient");
			EndIf;
			
			If Object.ConsumptionInOneDay And Object.DateOfMaterialWorkConsumption <> '000101010000' Then
				CurrentData.DateOfTransaction = Object.DateOfMaterialWorkConsumption;
			EndIf;
			
			If CurrentData.Department <> Object.Department Then
				CurrentData.Department = Object.Department;
				DivisionChanged_ = True;
			EndIf;
			
		EndDo;
		
		If DivisionChanged_ Then
			If Object.SavingMaterialsBatch.Count() > 0 Then
				RowFilter = New Structure("Department", Catalogs.BusinessStructure.EmptyRef());
				FillInRows = Object.SavingMaterialsBatch.FindRows(RowFilter);
				
				For Each TSRow In FillInRows Do
					TSRow.Department = Object.Department;
				EndDo;
			EndIf;
		EndIf;
		
	ElsIf TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		
		For Each CurrentData In RowsCollection Do
			
			If Object.ProductionInOneDay And Object.ProductionDate <> '000101010000' Then
				CurrentData.ProductionDate = Object.ProductionDate;
			EndIf;
			
			If RecordOfPerformed Then
				CurrentData.Manufactured = True;
			EndIf;
			
			If CurrentData.Department <> Object.Department Then
				CurrentData.Department = Object.Department;
				DivisionChanged_ = True;
			EndIf;
			
		EndDo;
		
	ElsIf TSName = "LaborCosts" Then
		
		For Each CurrentData In RowsCollection Do
			
			If RecordOfPerformed Then
				CurrentData.Completed2 = True;
			EndIf;
			
			If Object.WorkPerformanceAsOneDay And Object.WorkExecutionDate <> '000101010000' Then
				CurrentData.ExecutionDate = Object.WorkExecutionDate;
			EndIf;
			
			If CurrentData.Department <> Object.Department Then
				CurrentData.Department = Object.Department;
				DivisionChanged_ = True;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If Not StructureOfPreviouslyPerformedActions.Property("FillInFeatureAttribute")
		Or Not StructureOfPreviouslyPerformedActions.Property("FillInArticleAttribute")
		Or Not StructureOfPreviouslyPerformedActions.Property("FillInProductTypeAttribute_") Then
		
		FillInServiceDetailsOfTableParts(TSName, RowsArray);
		
	Else
		
		If (TSName = "SupplyWithMaterialsAndWorks"
				Or TSName = "LaborCosts") Then
			FillInStandards(TSName, RowsArray);
		EndIf;
		
	EndIf;
	
	If (TSName = "SupplyWithMaterialsAndWorks"
			Or TSName = "ManufacturedProducts"
			Or TSName = "SideAndIntermediateRelease"
			Or TSName = "MaterialsAndWorksConsumption"
			Or TSName = "UnusedMaterials")
		And (Not StructureOfPreviouslyPerformedActions.Property("CheckSeriesCalculateStatus")
			Or DivisionChanged_) Then
		FillInStatusesForSpecifyingSeriesServer(TSName);
	EndIf;
	
	StructureOfActions = New Structure;
	
	If (TSName = "ManufacturedProducts"
			Or TSName = "SideAndIntermediateRelease"
			Or TSName = "UnusedMaterials"
			Or TSName = "SupplyWithMaterialsAndWorks")
		And Not StructureOfPreviouslyPerformedActions.Property("RecalculateNumberOfUnits") Then
		StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	EndIf;
	
	AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl);
	
	If ValueIsFilled(StructureOfActions) Then
		
		ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsCollection,
			StructureOfActions,
			Object[TSName],
			ValuesInCache);
		
	EndIf;
	
	ChangedBankingDetails = TSName;
	
	If TSName = "ManufacturedProducts" Then
		FillInAssignmentSelectionParameters();
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, ChangedBankingDetails);
	
	If TSName = "MaterialsAndWorksConsumption" Then
		FormEvents.WhenChangingElement(ThisObject, "RawMaterials");
	EndIf;
	
EndProcedure

&AtServer
Function FillWarehouseInSelectedLinesOnServer(Val ArrayOfSelectedRows, Warehouse)
	
	FilledWithRows = WarehousesServer.FillInWarehousesInSelectedLines(Object.SupplyWithMaterialsAndWorks, ArrayOfSelectedRows, Warehouse);
	
	If FilledWithRows > 0 Then
		
		AfterChangingTSStringsProgrammaticallyOnServer("SupplyWithMaterialsAndWorks", ArrayOfSelectedRows);
		
	EndIf;
	
	Return FilledWithRows;
	
EndFunction

&AtServerNoContext
Function ThereAreTasksForCalculatingCollateral(ProductionOrder, ProductsArray)
	
	If ProductionOrder.IsEmpty()
		Or ProductsArray.UBound() = -1 Then
		Return False;
	EndIf;
	
	Query = New Query(
		"SELECT TOP 1
		|	Jobs.Products
		|FROM
		|	InformationRegister.OrderStructureCalculationTasksInventoryAllocation AS Jobs
		|WHERE
		|	Jobs.ProductionOrder = &ProductionOrder
		|	AND Jobs.Products IN (&Products)");
		
	Query.SetParameter("ProductionOrder", ProductionOrder);
	Query.SetParameter("Products", ProductsArray);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

&AtClient
Procedure StartWaitingForCalculationOfCollateral()
	
	StartWaitingForCalculationOfCollateral = False;
	
	Items.StateOfSoftwareDynamicStructure.Visible = False;
	Items.StateOfSoftwareDynamicStructureNotification.Visible = True;
	
	TimeConsumingOperationsClient.InitIdleHandlerParameters(SecurityCalculationWaitingParameters);
	SecurityCalculationWaitingParameters.CurrentInterval = 3;
	
	DetachIdleHandler("Attachable_CheckEndOfCollateralCalculation");
	AttachIdleHandler("Attachable_CheckEndOfCollateralCalculation",
		SecurityCalculationWaitingParameters.CurrentInterval,
		True);
	
EndProcedure

&AtClient
Procedure Attachable_CheckEndOfCollateralCalculation()
	
	ProductsArray = New Array;
	For Each String In Object.SupplyWithMaterialsAndWorks.FindRows(New Structure("Canceled", False)) Do
		ProductsArray.Add(String.Products);
	EndDo;
	
	If ThereAreTasksForCalculatingCollateral(Object.ReferenceOrder, ProductsArray) Then
		TimeConsumingOperationsClient.UpdateIdleHandlerParameters(SecurityCalculationWaitingParameters);
		AttachIdleHandler("Attachable_CheckEndOfCollateralCalculation",
			SecurityCalculationWaitingParameters.CurrentInterval,
			True);
	Else
		Items.StateOfSoftwareDynamicStructure.Visible = True;
		Items.StateOfSoftwareDynamicStructureNotification.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSpecificationInLines(Rows, CheckFillMode = False)
	
	RowsData = New Array;
	
	For Each String In Rows Do
		ProductData = ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
			Object, String, BOMSelectionParameters.SupplyWithMaterialsAndWorks, ThisObject);
		If CheckFillMode Then
			ProductData.Insert("CurrentSpecification", String.BillOfMaterials);
		EndIf;
		
		RowsData.Add(ProductData);
	EndDo;
	
	ProductDataManagement.FillInSpecificationInLines(
		Rows, RowsData, BOMSelectionParameters.SupplyWithMaterialsAndWorks);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddCheckActionFillInSpecification(Form, StructureOfActions, LineOfATabularSection)
	
	If Not LineOfATabularSection.Produced Then
		Return;
	EndIf;
	
	FillParameters = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		Form.Object, LineOfATabularSection, Form.BOMSelectionParameters.SupplyWithMaterialsAndWorks, Form);
	StructureOfActions.Insert("CheckFillSpecification", FillParameters);
	
EndProcedure

#EndRegion

#Region ClarificationOfProducts

&AtServer
Procedure CheckForProductItemConstraints(TSName, Attribute)
	
	Attribute = False;
	
	FoundRows = Object[TSName].FindRows(New Structure("UseAutoselection", True));
	
	For Each String In FoundRows Do
		
		If (String.Products.IsEmpty() Or String.Characteristic.IsEmpty() And String.ItemVariantsAreUsed) Then
			
			Attribute = True;
			
			Return;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region MaterialsAndWorksConsumption

&AtClient
Procedure ConsumptionOfMaterialsAndWorksFillInAccordingToTheDataProvidedByTheSoftwareCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInConsumptionOfMaterialsAndWorkOnProvisionDataOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialAndWorkConsumptionFillInTheExpenseDateCompletion(SelectedDate, ArrayOfSelectedRows) Export
	
	If ValueIsFilled(SelectedDate) Then
		For Each RowID In ArrayOfSelectedRows Do
			TableRow = Object.MaterialsAndWorksConsumption.FindByID(RowID);
			TableRow.DateOfMaterialWorkConsumption = SelectedDate;
		EndDo;
	EndIf; 
	
EndProcedure

// Fills in the expense of materials and works according to the security data
//
// Parameters:
//  Mode - See Documents.ProductionStage2_2.FillInConsumptionOfMaterialsAndWorksAccordingToProvisionData.Mode
//
&AtServer
Procedure FillInConsumptionOfMaterialsAndWorkOnProvisionDataOnServer(Mode = 0)

	Documents.ProductionStage2_2.FillInConsumptionOfMaterialsAndWorksAccordingToProvisionData(Object, Mode);
	AfterChangingTSStringsProgrammaticallyOnServer("MaterialsAndWorksConsumption");
	
EndProcedure

&AtServer
Procedure ConsumptionByOneDateWhenChangingOnServer()

	If Object.ConsumptionInOneDay Then
		Object.DateOfMaterialWorkConsumption = Max(Documents.ProductionStage2_2.MaximumDateWH(Object.MaterialsAndWorksConsumption, "DateOfMaterialWorkConsumption"), 
										Documents.ProductionStage2_2.MaximumDateWH(Object.UnusedMaterials, "DateOfTransaction"));
		DateOfExpenditureWhenChangedOnServer();
	EndIf;

	ConfigureDependentFormElements(ThisObject, "ConsumptionInOneDay");
	
EndProcedure

&AtServer
Procedure DateOfExpenditureWhenChangedOnServer()
	
	FillInWHDate("MaterialsAndWorksConsumption",  "DateOfMaterialWorkConsumption", Object.DateOfMaterialWorkConsumption);
	FillInWHDate("UnusedMaterials",      "DateOfTransaction", Object.DateOfMaterialWorkConsumption);
	FillInWHDate("SavingMaterialsBatch", "DateOfTransaction", Object.DateOfMaterialWorkConsumption);
	
EndProcedure

&AtServer
Procedure ExpenseOfMaterialsAndWorksAfterDeletionOnServer()
	FormEvents.WhenChangingElement(ThisObject, "RawMaterials");
EndProcedure

&AtClient
Procedure ExpenseOfMaterialsAndWorksAtEndOfEditingForServerCall()
	ExpenseOfMaterialsAndWorksAtEndOfEditingOnServer();
EndProcedure

&AtServer
Procedure ExpenseOfMaterialsAndWorksAtEndOfEditingOnServer()
	FormEvents.WhenChangingElement(ThisObject, "RawMaterials");
EndProcedure

#EndRegion

#Region Savings

&AtClient
Procedure UnusedMaterialsSelection(Item, RowSelected, Field, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	
EndProcedure

&AtServer
Procedure FillWithUnspentMaterialsOnServer()
	
	Documents.ProductionStage2_2.FillInUnspentMaterials(Object);
	AfterChangingTSStringsProgrammaticallyOnServer("UnusedMaterials");
	
EndProcedure

&AtClient
Procedure MaterialSavingFillInDateCompletion(SelectedDate, ArrayOfSelectedRows) Export

	If ValueIsFilled(SelectedDate) Then
		For Each RowID In ArrayOfSelectedRows Do
			TableRow = Object.UnusedMaterials.FindByID(RowID);
			TableRow.DateOfTransaction = SelectedDate;
		EndDo;
	EndIf; 
	
EndProcedure

&AtClient
Procedure SavingMaterialsActionWhenChanging(LineOfATabularSection)
	
	ProductionManagementClient.SavingMaterialsOfStageActionWhenChanging(
		LineOfATabularSection,
		ThisObject,
		Object,
		CachedValues);
	
EndProcedure

#EndRegion

#Region ManufacturedProducts

&AtServer
Procedure ProductionByOneDateWhenModifiedOnServer()

	If Object.ProductionInOneDay Then
		Object.ProductionDate = Max(Documents.ProductionStage2_2.MaximumDateWH(Object.ManufacturedProducts, "ProductionDate"), 
										Documents.ProductionStage2_2.MaximumDateWH(Object.SideAndIntermediateRelease, "ProductionDate"));
	EndIf;
	ProductionDateWhenModifiedOnServer();

	ConfigureDependentFormElements(ThisObject, "ProductionInOneDay");
	
EndProcedure

&AtServer
Procedure ProductionDateWhenModifiedOnServer()

	FillInWHDate("ManufacturedProducts",      "ProductionDate", Object.ProductionDate);
	FillInWHDate("BatchFinishedProducts", "ProductionDate", Object.ProductionDate);
	FillInWHDate("SideAndIntermediateRelease",      "ProductionDate", Object.ProductionDate);
	FillInWHDate("BatchSideAndIntermediateRelease", "ProductionDate", Object.ProductionDate);

EndProcedure

&AtServer
Procedure ToShiftPlannedProductionDatesToDate(NewTargetDate)

	ToShiftPlannedProductionDatesToDateOfWH("ManufacturedProducts",      NewTargetDate);
	ToShiftPlannedProductionDatesToDateOfWH("BatchFinishedProducts", NewTargetDate);
	ToShiftPlannedProductionDatesToDateOfWH("SideAndIntermediateRelease",      NewTargetDate);
	ToShiftPlannedProductionDatesToDateOfWH("BatchSideAndIntermediateRelease", NewTargetDate);

EndProcedure

&AtServer
Procedure ToShiftPlannedProductionDatesToDateOfWH(TSName, NewDate)
	
	For Each RowData In Object[TSName] Do
		If Not RowData.Manufactured And RowData.ProductionDate <> '00010101' And NewDate > RowData.ProductionDate Then
			RowData.ProductionDate = NewDate;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function NumberOfRowsProduced() 
	
	FilterStructure1 = New Structure("Manufactured", True);
	
	RowsCount = Object.ManufacturedProducts.FindRows(FilterStructure1).Count() + Object.SideAndIntermediateRelease.FindRows(FilterStructure1).Count();

	Return RowsCount;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionFillProductionDate(Form, StructureOfActions)
	
	Object = Form.Object;
	
	If Object.Status = StatusStarted() Or Object.Status = StatusCompleted_1() Or Object.DynamicStructure Then
		If Object.ProductionInOneDay Then
			ActionParameters = ProductionManagementClientServer.ActionParametersFillProductionDate(
				Object.ProductionDate,
				Object.ProductionDate);
			StructureOfActions.Insert("FillInProductionDate", ActionParameters);
		Else
			ActionParameters = ProductionManagementClientServer.ActionParametersFillProductionDate(
				Form.EventDateCompletion,
				Form.PlannedDateOfReceipt);
			StructureOfActions.Insert("FillInProductionDate", ActionParameters);
		EndIf;
	Else
		ActionParameters = ProductionManagementClientServer.ActionParametersFillProductionDate();
		StructureOfActions.Insert("FillInProductionDate", ActionParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInProductionDateInLine(CurrentRow)
	
	StructureOfActions = New Structure;
	
	AddActionFillProductionDate(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Function FillInPricesOfSelectedRowsByPriceTypeServer(TSName, PricesKind, IDs)
	
	ReadyForProcessing_ = New Array;
	
	For Each Id In IDs Do
		
		RowData = Object[TSName].FindByID(Id);
		RowData.Price  = 0;
		RowData.Sum = 0;
		
		ReadyForProcessing_.Add(RowData);
		
	EndDo;
	
	FillParameters = ProductionManagementClientServer.ParametersForFillingIssuePrices(
		Object.PriceKind,
		Object.Currency,
		Object.ActualStageStart);
	
	FillParameters.Insert("Organization", Object.Organization);
	
	PricesAreFilledOut = EnterprisePricesFillingServer.FillInPrices(
		Object[TSName], // Table part
		ReadyForProcessing_, // Array of rows or selection structure
		FillParameters, // The fill parameters
		New Structure( // The structure of the action with the changed strings
			"RecalculateAmount",
			"NumberOfPackages"));
	
	Return PricesAreFilledOut;
	
EndFunction

&AtClient
Procedure ProcessBySpecificationWhenModified(TSName, CurrentData)
	
	If Not CurrentData.ProcessByBOM Then
		CurrentData.BillOfMaterials = Undefined;
		Return;
	EndIf;
	
	FillParameters = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		Object,
		CurrentData,
		BOMSelectionParameters.ManufacturedProducts,
		ThisObject,
		New Structure("KeyOfDataPaths", "Object."+TSName));
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillSpecification", FillParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ItemsCanceledWhenModified(TSName, CurrentData)
	
	If CurrentData.Canceled Then
		CurrentData.Manufactured = False;
	Else
		CurrentData.CancellationReason = PredefinedValue("Catalog.ReasonsForProductionCancellation.EmptyRef");
	EndIf;
	
	StructureOfActions = New Structure;
	
	AddActionFillProductionDate(ThisObject, StructureOfActions);
	AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl);
	
	SeriesVerificationParameters = New Structure;
	SeriesVerificationParameters.Insert("Warehouse", CurrentData.Recipient);
	SeriesVerificationParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters[TSName]);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure Products_ChangeQualityCancelLineCompletion(ValueSelected, AdditionalParameters) Export
	
	TSName = AdditionalParameters.TSName;
	OldRow = Items[TSName].CurrentData;
	
	NewRow = ObjectTableByName(Object, TSName).Insert(ObjectTableByName(Object, TSName).IndexOf(OldRow) + 1);
	FillPropertyValues(NewRow, OldRow,, "RowCode,KeyProducts");
	
	FillPropertyValues(OldRow, ProcessingOfTabularFormsClientServer.LineCache(Items[TSName], ThisObject));
	OldRow.Canceled = True;
	ItemsCanceledWhenModified(TSName, OldRow);
	
	AfterChangingQualityAndCancelingRow(
		TSName, NewRow.GetID(), OldRow.GetID());
	
	Items[TSName].CurrentRow  = NewRow.GetID();
	
EndProcedure

#EndRegion

#Region LaborCosts

&AtServerNoContext
Procedure PerformerGettingSelectionData(ChoiceData, Text, Department, Organization, Date)
	
	ChoiceData = New ValueList;
	
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("Department", Department);
	ChoiceParameters.Insert("Organization", Organization);
	ChoiceParameters.Insert("Date", Date);
	
	ProductionServer.FillInSelectionDataWhenEnteringArtist(ChoiceData, Text, ChoiceParameters);
	
EndProcedure

&AtClient
Procedure FillInPerformersCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items.LaborCosts.SelectedRows;
	
	For Each RowID In SelectedRows Do
		CurrentData = Object.LaborCosts.FindByID(RowID);
		CurrentData.Performer = Result;
	EndDo;
	
	If ValueIsFilled(Object.Performer) 
			And Object.LaborCosts.Count() = SelectedRows.Count() Then
		Object.Performer = Result;
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformerStartChoiceCompletion(Result, AdditionalParameters) Export
	
	CurrentData = Items.LaborCosts.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(Result) Then
		
		CurrentData.Performer = Result;
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecutionOfWorksByOneDateWhenChangingOnServer()

	If Object.WorkPerformanceAsOneDay Then
		Object.WorkExecutionDate = Documents.ProductionStage2_2.MaximumDateWH(
									Object.LaborCosts, "ExecutionDate");
	EndIf;
	FillInWHDate("LaborCosts", "ExecutionDate", Object.WorkExecutionDate);
	
	ConfigureDependentFormElements(ThisObject, "WorkPerformanceAsOneDay");

EndProcedure

&AtServer
Procedure DateWorkWasCompletedWhenItWasChangedOnServer()
	
	FillInWHDate("LaborCosts", "ExecutionDate", Object.WorkExecutionDate);
	
EndProcedure

&AtServer
Function ThereAreLaborCostsWithEmptyExecutor(LineSubdivision)
	
	Result = False;
	
	For Each String In Object.LaborCosts Do
		If Not ValueIsFilled(String.Performer)
				And Not String.Canceled Then
			
			Result = True;
			
			If LineSubdivision = Undefined Then
				LineSubdivision = String.Department;
			ElsIf LineSubdivision <> String.Department Then
				LineSubdivision = Undefined;
				Break;
			EndIf;
			
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

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
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		CompositionOfLines = "Products,Characteristic,Package,NumberOfPackages,Department";
	ElsIf TSName = "SupplyWithMaterialsAndWorks" Or TSName = "MaterialsAndWorksConsumption" Then
		CompositionOfLines = "Products,Characteristic,Package,NumberOfPackages,ProductCostElement,Department";
	ElsIf TSName = "UnusedMaterials" Then
		CompositionOfLines = "Products,Characteristic,Package,NumberOfPackages,Department";
	ElsIf TSName = "LaborCosts" Then
		CompositionOfLines = "WorkKind,Count,ProductCostElement,Performer,Department";
	EndIf;
	
	SelectGoods = StrFind("ManufacturedProducts,SideAndIntermediateRelease,SupplyWithMaterialsAndWorks,MaterialsAndWorksConsumption,UnusedMaterials", TSName) > 0;
	If SelectGoods Then
		
		ArrayOfProductTypes = New Array;
		If Not Object.WorkPlanning Then
			ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
			ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		EndIf;
		If TSName <> "UnusedMaterials" Then
			ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		EndIf;
		
		FilterParameters = New Map;
		FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
		
	EndIf;
	
	LinesFromBuffer = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, CompositionOfLines);
	
	If Not ValueIsFilled(LinesFromBuffer) Then
		Return;
	EndIf;
	
	ReadyForProcessing_ = New Array;
	ArrayOfIdentifiers = New Array;
	LinesForSelectionOfSpecifications = New Array;
	
	StructureOfActions = New Structure;
	If SelectGoods Then
		AddActionsToStructureWhenChangingProducts(TSName, ThisObject, StructureOfActions);
		If TSName = "SideAndIntermediateRelease" Then
			InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
		EndIf;
	EndIf;
	
	For Each LineFromBuffer In LinesFromBuffer Do
		
		CurrentRow = ObjectTableByName(Object, TSName).Add();
		FillPropertyValues(CurrentRow, LineFromBuffer);
		CurrentRow.Department = Object.Department;
		
		If SelectGoods Then 
			
			If RecordOfPerformed
				And (TSName = "ManufacturedProducts"
					Or TSName = "SideAndIntermediateRelease") Then
				CurrentRow.Manufactured = True;
			EndIf;
			
			If TSName = "SideAndIntermediateRelease"
				And Object.InternalSubcontracting Then
				CurrentRow.ProductOwner = Object.MaterialProviderCompany;
			EndIf;
			
			ReadyForProcessing_.Add(CurrentRow);
			
		EndIf;
		
		ArrayOfIdentifiers.Add(CurrentRow.GetID());
		
		If TSName = "SupplyWithMaterialsAndWorks"
			And CurrentRow.Produced Then
			LinesForSelectionOfSpecifications.Add(CurrentRow);
		EndIf;
		
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ReadyForProcessing_,
		StructureOfActions,
		ObjectTableByName(Object, TSName),
		CachedValues);
	
	If LinesForSelectionOfSpecifications.UBound() <> -1 Then
		FillInSpecificationInLines(LinesForSelectionOfSpecifications, True);
	EndIf;
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, ArrayOfIdentifiers, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfClipboardCommands(Form, AttributeAvailability)
	
	Form.Items.ManufacturedProducts_InsertRows.Enabled = AttributeAvailability;
	Form.Items.ContextMenuOutputItemsInsertLines.Enabled = AttributeAvailability;
	
	Form.Items.ByProductsInsertRows_3.Enabled = AttributeAvailability;
	Form.Items.ContextMenuSideItemsInsertLines.Enabled = AttributeAvailability;

	Form.Items.SoftwareInsertRows.Enabled = AttributeAvailability;
	Form.Items.SupplyWithMaterialsAndWorksContextMenuSoftwareInsertRows.Enabled = AttributeAvailability;
	
	Form.Items.MaterialAndWorkConsumptionInsertLines.Enabled = AttributeAvailability;
	Form.Items.MaterialsAndWorksConsumptionContextMenuMaterialAndWorkConsumptionInsertLines.Enabled = AttributeAvailability;
	
	Form.Items.SaveMaterialsInsertLines.Enabled = AttributeAvailability;
	Form.Items.UnusedMaterialsContextMenuSaveMaterialsInsertLines.Enabled = AttributeAvailability;
	
	Form.Items.LaborCostsInsertLines.Enabled = AttributeAvailability;
	Form.Items.ContextMenuLaborCostsInsertLines.Enabled = AttributeAvailability;
	
EndProcedure

#EndRegion

#Region Substitutes

&AtServer
Procedure NotePresenceOfAnalogues()

	TableName = "SupplyWithMaterialsAndWorks";
	AlternativeMaterials.NotePresenceOfAnalogues(Object[TableName], AnalogSelectionParameters(TableName, 0), ThisObject);
	ReflectAnalogsInSupplyForecastHyperlink(ThisObject);

EndProcedure

&AtClient
Procedure OpenSelectionOfAnalogues()
	
	TableName = "SupplyWithMaterialsAndWorks";
	
	If Items[TableName].SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn (các) dòng';
								|ru = 'Необходимо выделить строку(и)';
								|en = 'Highlight the line(s)'; fa = 'Highlight the line(s)';
								|it = 'È necessario evidenziare la riga (le righe)';
								|pl = 'Należy zaznaczyć wiersz(e)';
								|tr = 'Satır(lar) vurgulanmalıdır'"));
		Return;
	EndIf;
	
	AlternativeMaterialsClient.OpenSelectionOfAnalogues(AnalogSelectionParameters(TableName, 1), ThisObject);
	
EndProcedure

&AtServer
Procedure Replace_With_Analogues(
			AddressInStorage = Undefined,
			ActionCodeAnalogs = "Action_Substitutes_ToReserve_",
			DisplayMessageAboutResult = True)
	
	TableName = "SupplyWithMaterialsAndWorks";
	
	AdditionalFillingParameters = New Structure;
	AdditionalFillingParameters.Insert("PermissionValidityDate", StartOfDayCurSessionDate());
	
	Result = Documents.ProductionStage2_2.Replace_With_Analogues(
					ThisObject,
					TableName,
					AddressInStorage,
					ActionCodeAnalogs,
					AdditionalFillingParameters);
	
	IndexesOfModifiedRows = Result.IndexesOfModifiedRows;
	IndexesOfNewRows = Result.IndexesOfNewRows;
	
	NumberOfReplacementsMade = IndexesOfModifiedRows.Count() + IndexesOfNewRows.Count(); 
	
	If DisplayMessageAboutResult Then
		MessageText  = StrTemplate(NStr("vi = 'Dòng được thay đổi: %1';
										|ru = 'Измененных строк: %1';
										|en = 'Changed lines: %1'; fa = 'Changed lines: %1';
										|it = 'Измененных строк: %1';
										|pl = 'Changed lines: %1';
										|tr = 'Değiştirilen satırlar: %1'"), NumberOfReplacementsMade);
		Common.MessageToUser(MessageText);
	EndIf;

	If NumberOfReplacementsMade = 0 Then
		Return;
	EndIf;
	
	Modified = True;
	
	StructureOfActions = New Structure;
	
	RowsIDs = New Array;
	
	Documents.ProductionStage2_2.AfterReplacementWithAnalogs(
		ThisObject,
		TableName,
		Result,
		StructureOfActions,
		RowsIDs);
	
	AfterChangingTSStringsProgrammaticallyOnServer(TableName, RowsIDs, StructureOfActions);
	
EndProcedure

// Generates parameters for selecting analogs
//
// Parameters:
//	TableName - String - Name of the table to be processed
//	Mode      - Number  - 0-show analogs
//                        1 - choose the analogues
//                        2-replace with analogs
// 
// Returns:
//  See AlternativeMaterials.AnalogSelectionParameters
//
&AtServer
Function AnalogSelectionParameters(TableName, Mode)
	
	AdditionalFillingParameters = New Structure;
	AdditionalFillingParameters.Insert("PermissionValidityDate", StartOfDayCurSessionDate());
	
	Return Documents.ProductionStage2_2.AnalogSelectionParameters(
				ThisObject,
				TableName,
				Mode,
				AdditionalFillingParameters);
	
EndFunction

#EndRegion

#Region MaterialsAndWorksSets

&AtClient
Procedure BeforeDeletingRowsIncludedInSets()
	
	SelectedRows = Items.SupplyWithMaterialsAndWorks.SelectedRows;
	
	If ProductDataManagementClient.ThereAreLinesIncludedInSet(Object, SelectedRows) Then
		
		ProcessDeletionOfRowsIncludedInSets(SelectedRows);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingNomenclatureOfCharacteristicInLineIncludedInSet()
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	If ValueIsFilled(CurrentData.CommunicationKeySet) Then
		
		RowsIDs = CommonClientServer.ValueInArray(Items.SupplyWithMaterialsAndWorks.CurrentRow);
		ProcessDeletionOfRowsIncludedInSets(RowsIDs);
		
		CurrentData.CommunicationKeySet = Undefined;
		CurrentData.IncludedInSet   = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessDeletionOfRowsIncludedInSets(RowsIDs)
	
	ProductDataManagement.ProcessDeletionOfRowsIncludedInSets(Object, RowsIDs);
	
EndProcedure

&AtServer
Function AddSetComposition(StringSelection__, TSName)
	
	AddedRows  = New Array;
	
	ContentData = StringSelection__.ContentData;
	If ValueIsFilled(ContentData) Then
		
		For Each String In ContentData.MaterialsAndServices Do
			
			NewRow = ObjectTableByName(Object, TSName).Add();
			FillPropertyValues(NewRow, String);
			
			AddedRows.Add(NewRow);
			
		EndDo;
		
		For Each String In ContentData.MaterialsAndWorksSets Do
			
			NewRow = Object.MaterialsAndWorksSets.Add();
			FillPropertyValues(NewRow, String);
			
		EndDo;
		
	Else
		
		MessageText = StrTemplate(NStr("vi = 'Không thể nhận thành phần bộ sản phẩm: %1';
										|ru = 'Не удалось получить состав набора: %1';
										|en = 'Cannot receive the set content: %1'; fa = 'Cannot receive the set content: %1';
										|it = 'Non è stato possibile ricevere la composizione del kit: %1';
										|pl = 'Nie udało się otrzymać składu zestawu: %1';
										|tr = 'Set kapsamı alınamadı: %1'"),
			ProductsClientServer.ProductPresentation(StringSelection__.Products, StringSelection__.Characteristic));
			
		Common.MessageToUser(
			MessageText,
			Object.Ref);
		
	EndIf;
	
	Return AddedRows;
	
EndFunction

&AtClient
Procedure ProcessSplitOfStringIncludedInSet(NewRow)
	
	If ValueIsFilled(NewRow.CommunicationKeySet) Then
		ProcessSplitOfStringIncludedInSetServer(NewRow.CommunicationKeySet);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessSplitOfStringIncludedInSetServer(CommunicationKeySet)
	
	ProductDataManagement.AdjustTableSetsOfMaterialsAndWorks(
		Object.MaterialsAndWorksSets, CommunicationKeySet, 1);
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure SearchByBarcode(TSName)

	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject, TSName);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);

EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, TSName) Export
	
	ProcessBarcodes(BarcodeData_2, TSName);
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(BarcodeData_5, TSName)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithModifiedStrings = New Structure;
	
	FillInActionStructuresForBarcodeProcessing(
			TSName,
			ThisObject,
			StructureOfActionsWithAddedStrings,
			StructureOfActionsWithModifiedStrings);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.TSName                                  = TSName;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters[TSName];
	StructureOfActions.GoodsOnly                           = True;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("Attachable_OpenSeriesSelectionWhenScanningProductBarCode_" + TSName, 0.1, True);
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items[TSName]["CurrentRow"] = StructureOfActions.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
	If StructureOfActionParameters.TSName = "MaterialsAndWorksConsumption" Then
		FormEvents.WhenChangingElement(ThisObject, "RawMaterials");
	EndIf;
	
	If StructureOfActionParameters.CurrentRow <> Undefined Then
		RowsArray = TMCommonUseClientServer.Array(StructureOfActionParameters.CurrentRow, False);
		
		AfterChangingTSStringsProgrammaticallyOnServer(
			StructureOfActionParameters.TSName,
			RowsArray,
			StructureOfActionParameters.StructureOfActionsWithAddedStrings);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(TSName)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject, TSName),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, TSName) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods, TSName);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_OpenSeriesSelectionWhenScanningProductBarCode_MaterialsAndWorksConsumption()

	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.MaterialsAndWorksConsumption.FindByID(CurDataId);
	OpenSelectionOfSeries("MaterialsAndWorksConsumption",,CurrentData);

EndProcedure

&AtClient
Procedure Attachable_OpenSeriesSelectionWhenScanningProductBarCode_UnusedMaterials()

	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.UnusedMaterials.FindByID(CurDataId);
	OpenSelectionOfSeries("UnusedMaterials",,CurrentData);

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

// Is a description of the warning about closing, is used in the procedure Paucities
//
// Parameters:
//  ExecutionResult - Arbitrary -
//  AdditionalParameters - Structure - Contains:
//                             * CurrentRow - FormDataCollectionItem - Contains:
//                                                ** NumberOfPackages - Number - 
//
&AtClient
Procedure GetWeightCompletion(ExecutionResult, AdditionalParameters) Export
	
	If ExecutionResult.Result Then
		
		AdditionalParameters.CurrentRow.NumberOfPackages = ExecutionResult.Weight;
		
		StructureOfActions = New Structure;
		
		AddActionsToStructureWhenChangingPackagesNumber(AdditionalParameters.TSName, ThisObject, StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(AdditionalParameters.CurrentRow, StructureOfActions, CachedValues);
		
		If AdditionalParameters.TSName = "ManufacturedProducts"
			Or AdditionalParameters.TSName = "SideAndIntermediateRelease"
			Or AdditionalParameters.TSName = "UnusedMaterials" Then
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

#Region Constants

&AtClientAtServerNoContext
Function MethodOfPlanningByTotalDuration()
	
	Return 0;
	
EndFunction

&AtClientAtServerNoContext
Function PlanningMethodForAvailability()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Function ManualSchedulingMethod()
	
	Return 2;
	
EndFunction

&AtClientAtServerNoContext
Function ProductionMethodOwn()
	
	Return 0;
	
EndFunction

&AtClientAtServerNoContext
Function ProductionMethodOnSide()
	
	Return 1;
	
EndFunction

#EndRegion

#Region FillType

&AtClient
Procedure FillInTheCostingItem(TSName)
	
	SelectedRows = Items[TSName].SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		ClearMessages();
		WarningText = NStr("vi = 'Cần chọn các hàng mà muốn điền dạng chi phí';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить статью калькуляции.';
							|en = 'Select the lines for which it is required to populate the product cost element.'; fa = 'Select the lines for which it is required to populate the product cost element.';
							|it = 'È necessario selezionare le righe per le quali si deve compilare la voce di calcolo.';
							|pl = 'Należy wybrać wiersze, dla których trzeba wypełnić pozycję kalkulacji.';
							|tr = 'Ürün maliyet kalemini doldurmanız gereken satırları seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	FilterParameters = New Structure;
	
	CostTypes = ProductionClient.TypesOfCostsForChoosingCalculationArticle(TSName);
	If CostTypes.UBound() <> -1 Then
		FilterParameters.Insert("ExpenseType", CostTypes);
	EndIf;	
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("MultipleChoice", False);
	
	CallbackDescription = New CallbackDescription("FillInTheCostingItemCompletion", ThisObject, TSName);
	
	OpenForm("Catalog.ProductCostElements.ChoiceForm", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInTheCostingItemCompletion(ClosingResult, TSName) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items[TSName].SelectedRows;
	TabularSection = Object[TSName];
	
	For Each RowID In SelectedRows Do
		
		CurrentData = TabularSection.FindByID(RowID);
		CurrentData.ProductCostElement = ClosingResult;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CancelSelectedLines(TSName)
	
	If Object[TSName].Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Phần bảng chưa điền.';
										|ru = 'Табличная часть не заполнена.';
										|en = 'Table is not filled in.'; fa = 'Table is not filled in.';
										|it = 'Parte tabulare non compilata.';
										|pl = 'Wypełnić ponownie część tabelaryczną?';
										|tr = 'Tablo bölümü doldurulmadı.'"));
		Return;
	ElsIf Items[TSName].SelectedRows.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Không có hàng được tô sáng trong phần bảng.';
										|ru = 'В табличной части отсутствуют выделенные строки.';
										|en = 'No rows are selected in the table.'; fa = 'No rows are selected in the table.';
										|it = 'Nella parte tabulare non ci sono righe selezionate.';
										|pl = 'W części tabelarycznej nie ma zaznaczonych wierszy.';
										|tr = 'Tablo bölümünde belirtilen satırlar bulunmamaktadır.'"));
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName", TSName);
	AdditionalParameters.Insert("SelectedRows", Items[TSName].SelectedRows);
	
	OpenForm("Catalog.ReasonsForProductionCancellation.ChoiceForm",
		,
		,
		,
		,
		,
		New CallbackDescription("UndoSelectedLinesSelectReasonEnd", ThisObject, AdditionalParameters),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure UndoSelectedLinesSelectReasonEnd(CancellationReason, AdditionalParameters) Export
	
	If CancellationReason = Undefined Then
		Return;
	EndIf;
	
	UndoSelectedRowsOnServer(
		CancellationReason,
		AdditionalParameters.SelectedRows,
		AdditionalParameters.TSName);
	
	ShowUserNotification(NStr("vi = 'Các dòng đã chọn bị hủy bỏ';
								|ru = 'Выделенные строки отменены';
								|en = 'Selected lines are canceled'; fa = 'Selected lines are canceled';
								|it = 'Righe selezionate annullate';
								|pl = 'Zaznaczone wiersze anulowano';
								|tr = 'Belirtilen satırlar iptal edildi'"),,, PictureLib.Information32);
	
EndProcedure

&AtServer
Procedure UndoSelectedRowsOnServer(CancellationReason, SelectedRows, TSName)
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		
		ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		StructureOfActions = New Structure;
		
		AddActionFillProductionDate(ThisObject, StructureOfActions);
		AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl);
		
		SeriesVerificationParameters = New Structure;
		SeriesVerificationParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters[TSName]);
		StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
		
		RowsToProcess = New Array();
		
		For Each RowID In SelectedRows Do
			
			String = Object[TSName].FindByID(RowID);
			
			String.Canceled = True;
			String.CancellationReason = CancellationReason;
			String.Manufactured = False;
			
			RowsToProcess.Add(String);
			
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object[TSName],
			ValuesInCache);
		
	ElsIf TSName = "SupplyWithMaterialsAndWorks" Then
		
		For Each RowID In SelectedRows Do
			String = Object.SupplyWithMaterialsAndWorks.FindByID(RowID);
			String.Canceled = True;
			String.CancellationReason = CancellationReason;
		EndDo;
		
		FillInStatusesForSpecifyingSeriesServer("SupplyWithMaterialsAndWorks");
		
	ElsIf TSName = "LaborCosts" Then
		
		For Each RowID In SelectedRows Do
		
			String = Object.LaborCosts.FindByID(RowID);
			String.Canceled = True;
			String.CancellationReason = CancellationReason;
			
			If String.Completed2 Then
				String.Completed2 = False;
				LaborPerformedWhenChangingOnServer(RowID);
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ReflectNumberOfAvailableWHOnServer(Performer)
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.ReflectTheNumberOfHoursOfWH(Performer);
	ValueToFormAttribute(DocumentObject, "Object");
	
	FillInServiceDetails();
	FillInServiceDetailsOfTableParts();
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure ReflectAmountOfCancelledWHOnServer(CancellationReason)
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.ReflectTheAmountCanceledByWH(CancellationReason);
	ValueToFormAttribute(DocumentObject, "Object");
	
	FillInServiceDetails();
	FillInServiceDetailsOfTableParts();
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInAccordingToSpecificationOnServer(ListOfData)
	
	ListOfRSData = 
		?(ListOfData.Property("SupplyWithMaterialsAndWorks"), ",MaterialsAndServices,IncomingProducts", "")
		+ ?(ListOfData.Property("ManufacturedProducts"), ",ManufacturedProducts", "")
		+ ?(ListOfData.Property("SideAndIntermediateRelease"), ",RecyclableWaste", "")
		+ ?(ListOfData.Property("LaborCosts"), ",LaborCosts", "")
		+ ?(ListOfData.Property("WorkCenterTypes"), ",WorkCenterTypes,AlternateWorkCenterTypes,Stages", "");
	ListOfRSData = Right(ListOfRSData, StrLen(ListOfRSData)-1);
	
	SpecificationData = GetStandardsForSpecifications(False, ListOfRSData);
	If SpecificationData = Undefined Then
		Return;
	EndIf;
	
	Exceptions = Documents.ProductionStage2_2.DivisionItems(Object.Ref);
	SoftwareExceptions = New Structure("Products, Characteristic, Warehouse, Purpose");
	FinishedProductExceptions = New Structure("Products, Characteristic, Recipient, Purpose");
	
	If ListOfData.Property("SupplyWithMaterialsAndWorks") Then
		
		If Exceptions.Supply.Count() = 0 Then
			Object.SupplyWithMaterialsAndWorks.Clear();
		Else
			For IndexOf = -Object.SupplyWithMaterialsAndWorks.Count()+1 To 0 Do
				String = Object.SupplyWithMaterialsAndWorks[-IndexOf];
				FillPropertyValues(SoftwareExceptions, String);
				If Exceptions.Supply.FindRows(SoftwareExceptions).UBound() = -1 Then
					Object.SupplyWithMaterialsAndWorks.Delete(String);
				EndIf;
			EndDo;
		EndIf;
		
		// Filling out assignments
		TypeDescription = New TypeDescription("CatalogRef.Assignments");
		SpecificationData.MaterialsAndServices.Columns.Add("Purpose", TypeDescription);
		SpecificationData.MaterialsAndServices.Columns.Add("SupplyAssignment", TypeDescription);
		SpecificationData.IncomingProducts.Columns.Add("Purpose", TypeDescription);
		SpecificationData.IncomingProducts.Columns.Add("SupplyAssignment", TypeDescription);
		
		AssignmentsOfMaterials = Undefined;
		If ValueIsFilled(ParametersForFillingAssignments.AssignmentMaterials) Then
			AssignmentsOfMaterials = New ValueTable();
			AssignmentsOfMaterials.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
			AssignmentsOfMaterials.Columns.Add("ZoomRatio", New TypeDescription("Number", New NumberQualifiers()));
			AssignmentsOfMaterials.Add();
			AssignmentsOfMaterials[0].Purpose = ParametersForFillingAssignments.AssignmentMaterials;
			AssignmentsOfMaterials[0].ZoomRatio = 1;
		ElsIf Object.DynamicStructure Then
			AssignmentsOfMaterials = ProductionSupply.CoefficientsOfSecurityAssignmentsInProductionStage(
				Object,
				Object.ManufacturedProducts.Unload(New Structure("Canceled", False)));
		EndIf;
		
		If AssignmentsOfMaterials <> Undefined Then
			ProductionSupply.FillInAssignmentOfMaterialsSpecifications(
				SpecificationData,
				Object.Stage,
				AssignmentsOfMaterials,
				ParametersForFillingAssignments.AssignmentSemiFinishedProducts);
		EndIf;
		
		// Adding rows
		TMCommonUse.AddRowsToTable(
			Object.SupplyWithMaterialsAndWorks,
			SpecificationData.MaterialsAndServices,
			New Structure("LinkKeyBOM, Department", "ConnectionKey", "StageSubdivision"));
		
		AfterChangingTSStringsProgrammaticallyOnServer("SupplyWithMaterialsAndWorks");
		Object.MaterialsAndWorksSets.Clear();
		If SpecificationData.Property("MaterialsAndWorksSets") Then
			Object.MaterialsAndWorksSets.Load(SpecificationData.MaterialsAndWorksSets);
		EndIf;
		
		CheckForProductItemConstraints("SupplyWithMaterialsAndWorks", ThereAreMaterialSpecifications);
		ConfigureDependentFormElements(ThisObject, "ThereAreMaterialSpecifications");
		
	EndIf;
	
	If ListOfData.Property("ManufacturedProducts") Then
		
		If Exceptions.Products_1.Count() = 0 Then
			Object.ManufacturedProducts.Clear();
			Object.BatchFinishedProducts.Clear();
		Else
			For IndexOf = -Object.ManufacturedProducts.Count()+1 To 0 Do
				String = Object.ManufacturedProducts[-IndexOf];
				FillPropertyValues(FinishedProductExceptions, String);
				If Exceptions.Products_1.FindRows(FinishedProductExceptions).UBound() = -1 Then
					Object.ManufacturedProducts.Delete(String);
				EndIf;
			EndDo;
			For IndexOf = -Object.BatchFinishedProducts.Count()+1 To 0 Do
				String = Object.BatchFinishedProducts[-IndexOf];
				FillPropertyValues(FinishedProductExceptions, String);
				If Exceptions.Products_1.FindRows(FinishedProductExceptions).UBound() = -1 Then
					Object.BatchFinishedProducts.Delete(String);
				EndIf;
			EndDo;
		EndIf;
		
		TMCommonUse.AddRowsToTable(
			Object.ManufacturedProducts,
			SpecificationData.ManufacturedProducts,
			New Structure("Recipient, Department", "Warehouse", "StageSubdivision"));
		
		AfterChangingTSStringsProgrammaticallyOnServer("ManufacturedProducts");
		
	EndIf;
	
	If ListOfData.Property("SideAndIntermediateRelease") Then
		
		Object.SideAndIntermediateRelease.Clear();
		Object.BatchSideAndIntermediateRelease.Clear();
		
		TMCommonUse.AddRowsToTable(
			Object.SideAndIntermediateRelease,
			SpecificationData.RecyclableWaste,
			New Structure("Recipient, Department", "Warehouse", "StageSubdivision"));
		
		AfterChangingTSStringsProgrammaticallyOnServer("SideAndIntermediateRelease");
		
	EndIf;
	
	If ListOfData.Property("LaborCosts") Then
		
		Object.LaborCosts.Clear();
		
		TMCommonUse.AddRowsToTable(
			Object.LaborCosts,
			SpecificationData.LaborCosts,
			New Structure("Department", "StageSubdivision"));
			
		AfterChangingTSStringsProgrammaticallyOnServer("LaborCosts");
		
	EndIf;
	
	If ListOfData.Property("WorkCenterTypes") Then
		
		Object.WorkCenterTypes.Clear();
		Object.AlternateWorkCenterTypes.Clear();
		
		TMCommonUse.AddRowsToTable(
			Object.WorkCenterTypes,
			SpecificationData.WorkCenterTypes,,
			New Structure("Use", True));
		
		TMCommonUse.AddRowsToTable(
			Object.AlternateWorkCenterTypes,
			SpecificationData.AlternateWorkCenterTypes);
		
		FillInTheTypesOfWorkCenters();
		
		If SpecificationData.Stages.Count() <> 0 Then
			Object.OperatingProcedureOfWorkCenterTypes = SpecificationData.Stages[0].OperatingProcedureOfWorkCenterTypes;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAssignmentSelectionParameters()
	
	ParametersForFillingAssignments = ProductionSupply.ActionParametersFillInPurposeOfProvisionInProductionPhase(
		Object, Object.ManufacturedProducts);
	
	ProductionSupply.FillInListOfSelectedAssignmentsInProductionPhase(
		Object, Object.ManufacturedProducts, RefsFilterInSelectionOfAssignmentsForm);
	
	Items.SupplyWithMaterialsAndWorksSupplyAssignment.ChoiceList.LoadValues(
		RefsFilterInSelectionOfAssignmentsForm.UnloadValues());
	
	AssignmentStage = Items.SupplyWithMaterialsAndWorksSupplyAssignment.ChoiceList.FindByValue(Object.Purpose);
	If AssignmentStage <> Undefined Then
		AssignmentStage.Presentation = NStr("vi = 'Công đoạn hiện tại';
											|ru = 'Текущий этап';
											|en = 'Current step'; fa = 'مرحله جاری';
											|it = 'Fase corrente';
											|pl = 'Bieżący etap';
											|tr = 'Mevcut aşama'");
	EndIf;
	
EndProcedure

#EndRegion

#Region Pickup

&AtClient
Procedure OpensGoodsSelection(TSName)
	
	If Object.WorkPlanning Then
		HeaderParameter_ = NStr("vi = 'Chọn công việc vào %1';
								|ru = 'Подбор работ в %1';
								|en = 'Pick works in %1'; fa = 'Pick works in %1';
								|it = 'Pick works in %1';
								|pl = 'Pick works in %1';
								|tr = '%1 içinde iş seçimi'");
	ElsIf TSName = "SupplyWithMaterialsAndWorks" Or TSName = "MaterialsAndWorksConsumption" Then
		HeaderParameter_ = NStr("vi = 'Chọn nguyên vật liệu và công việc vào %1';
								|ru = 'Подбор материалов и работ в %1';
								|en = 'Pick materials and works in %1'; fa = 'Pick materials and works in %1';
								|it = 'Selezione materiali e lavori in %1';
								|pl = 'Wybór materiałów i prac w %1';
								|tr = '%1 içinde malzeme ve iş seçimi'");
	ElsIf TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		HeaderParameter_ = NStr("vi = 'Chọn sản phẩm vào %1';
								|ru = 'Подбор изделий в %1';
								|en = 'Pick finished products in %1'; fa = 'Pick finished products in %1';
								|it = 'Selezione articoli in %1';
								|pl = 'Wybór wyrobów w %1';
								|tr = '%1 içinde nihai ürün seçimi'");
	Else
		HeaderParameter_ = NStr("vi = 'Chọn vào %1';
								|ru = 'Подбор в %1';
								|en = 'Pick in %1'; fa = 'Pick in %1';
								|it = 'Selezione in %1';
								|pl = 'Wybór w %1';
								|tr = '%1 içinde seçim'");
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrTemplate(HeaderParameter_, Object.Ref);
	Else
		HeaderParameter_ = StrTemplate(HeaderParameter_, NStr("vi = 'công đoạn sản xuất';
																|ru = 'этап производства';
																|en = 'production stage'; fa = 'production stage';
																|it = 'fase di produzione';
																|pl = 'Etap produkcji';
																|tr = 'üretim aşaması'"));
	EndIf;
	
	If Object.WorkPlanning Then
		ItemsTypes = CommonClientServer.ValueInArray(
			PredefinedValue("Enum.ItemsTypes.Work_5"));
	Else
		SetsAreAvailable = UseOfKitsInProductionIsAvailable
			And TSName = "SupplyWithMaterialsAndWorks";
		ItemsTypes = ProductsClientServer.SelectionByProductReusablePackagingWork(SetsAreAvailable);
	EndIf;
	FilterByProductType = New FixedArray(ItemsTypes);
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectionModeWithoutAmountParameters", True);
	FormParameters.Insert("HideTheViewPriceColumn",            True);
	FormParameters.Insert("HideTheItemPricesCommand",   True);
	FormParameters.Insert("DoNotSplitSetsByComponents",  True);
	FormParameters.Insert("UseShipmentDates",          False);
	FormParameters.Insert("Title",               HeaderParameter_);
	FormParameters.Insert("Document",                Object.Ref);
	FormParameters.Insert("Date",                    Object.Date);
	FormParameters.Insert("Department",           Object.Department);
	FormParameters.Insert("FilterByProductType", FilterByProductType);
	FormParameters.Insert("SeriesSpecificationParameters",  SeriesSpecificationParameters[TSName]);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
		FormParameters.Insert("AllWarehouseBalance",               True);
		FormParameters.Insert("SelectSupplyOptions",         Not RecordOfPerformed);
		FormParameters.Insert("Purpose",                         Object.Purpose);
		FormParameters.Insert("AvailableRemainingDocumentParameters",
			ProvisionInDocumentsClient.AvailableRemainingDocumentParameters(ThisObject));
		If RecordOfPerformed Then
			WarehousesList = New ValueList();
			WarehousesList.LoadValues(WarehousesToReflectCompleted(Object.Department));
			FormParameters.Insert("Warehouse", WarehousesList);
			TitleOfCheckBoxIsOnlyAvailable = StrTemplate(NStr("vi = 'Chỉ có sẵn trong kho của bộ phận ""%1""';
																|ru = 'Только в наличии в кладовых подразделения ""%1""';
																|en = 'Only goods available in storerooms of the ""%1"" business unit'; fa = 'Only goods available in storerooms of the ""%1"" business unit';
																|it = 'Только в наличии в кладовых подразделения ""%1""';
																|pl = 'Only goods available in storerooms of the ""%1"" business unit';
																|tr = 'Sadece ""%1"" ambar departmanı stoklarında mevcuttur'"), Object.Department);
			FormParameters.Insert("TitleOfCheckBoxIsOnlyAvailable", TitleOfCheckBoxIsOnlyAvailable);
			AcceptableSeparateActions = New ValueList();
			AcceptableSeparateActions.Add(PredefinedValue("Enum.SupplyOptions.Ship"));
			AllowedNonIsolatedActions = New ValueList();
			AllowedNonIsolatedActions.Add(PredefinedValue("Enum.SupplyOptions.Ship"));
			FormParameters.Insert("AcceptableSeparateActions", AcceptableSeparateActions);
			FormParameters.Insert("AllowedNonIsolatedActions", AllowedNonIsolatedActions);
		Else
			
			AllowedActions = Undefined;
			
			// The "Ship" software option is not available.
			ShipmentIsAvailable = Not(
				Object.ProductionByThirdParty
					And TollingOrderCreated
					And Object.NotShipInInstallments
					And Not ValueIsFilled(Object.DateOfShipment));
			
			If Not ShipmentIsAvailable Then
				
				AllowedActions = ProvisionInDocumentsClientServer.AllActions();
				
				AllowedActions.Delete(
					AllowedActions.FindByValue(
						PredefinedValue("Enum.SupplyOptions.Ship")));
				
			EndIf;
			
			// The "Reserve as received" collateral option is not available.
			If Object.DynamicStructure Then
				
				If AllowedActions = Undefined Then
					AllowedActions = ProvisionInDocumentsClientServer.AllActions();
				EndIf;
				
				AllowedActions.Delete(
					AllowedActions.FindByValue(
						PredefinedValue("Enum.SupplyOptions.ReserveAsReceived")));
				
			EndIf;
			
			If AllowedActions <> Undefined Then
				
				FormParameters.Insert("AcceptableSeparateActions",   AllowedActions);
				FormParameters.Insert("AllowedNonIsolatedActions", AllowedActions.Copy());
				
			EndIf;
			
		EndIf;
	Else
		FormParameters.Insert("HideCommandRemainingQuantityInWarehouses",    True);
		FormParameters.Insert("SelectSupplyOptions",         False);
	EndIf;
	
	Notification = New CallbackDescription("OpensGoodsSelectionCompletion",
		ThisObject,
		TSName);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form",
		FormParameters,
		ThisObject,
		UUID,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure OpensGoodsSelectionCompletion(ValueSelected, TSName) Export
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;
	
	StartProcessingSelectionResult(ValueSelected.GoodsAddressInStorage, "SelectGoods", TSName);
	
EndProcedure

&AtClient
Procedure StartProcessingSelectionResult(GoodsAddressInStorage, SelectionOption, TSName = "SupplyWithMaterialsAndWorks")
	
	StartProcessingSelectionResultOnServer(GoodsAddressInStorage, SelectionOption, TSName);
	
	If TimeConsumingOperation <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"ProcessingOfSelectionResultCompletion",
			ThisObject);
			
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = True;
			
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			CallbackDescription,
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StartProcessingSelectionResultOnServer(GoodsAddressInStorage, SelectionOption, TSName)
	
	If TimeConsumingOperation <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
		TimeConsumingOperation = Undefined;
	EndIf;
	
	TableOfGoods = GetFromTempStorage(GoodsAddressInStorage); // ValueTable
	If TableOfGoods.Count() = 0 Then
		Return;
	EndIf;
	
	If TableOfGoods.Find(Enums.ItemsTypes.Set, "ItemsType") <> Undefined Then
		StartAddingCompositionOfSetsToSelectionResult(TableOfGoods, SelectionOption, TSName);
	ElsIf SelectionOption = "SelectGoods" Then
		ProcessingSelectionOfSelectionOnServer(TableOfGoods, TSName);
	ElsIf SelectionOption = "SelectMaterialsByBOM" Then
		UploadResultOfSelectingMaterialsBasedOnSpecifications(TableOfGoods);
	EndIf;
	
EndProcedure

&AtServer
Procedure StartAddingCompositionOfSetsToSelectionResult(TableOfGoods, SelectionOption, TSName = "SupplyWithMaterialsAndWorks")
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground    = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Nhận thành phần bộ sản phẩm khi chọn.';
														|ru = 'Получение состава наборов при подборе.';
														|en = 'Get the set content during picking.'; fa = 'Get the set content during picking.';
														|it = 'Ricezione composizione kit durante la selezione.';
														|pl = 'Otrzymanie składu zestawów podczas wyboru.';
														|tr = 'Seçim sırasında küme içeriğinin alınması.'");
	
	ParametersForObtainingComposition = ProductDataManagement.ParametersForObtainingCompositionOfSetInProduction();
	ParametersForObtainingComposition.AssigneeBusinessUnit = Object.Department;
	ParametersForObtainingComposition.ReferenceOrder             = ProductionBatchData.ReferenceOrder;
	ParametersForObtainingComposition.ProductionStart       = ProductionBatchData.ProductionStart;
	ParametersForObtainingComposition.ProductionDispatcherBusinessUnit   = ProductionBatchData.ProductionDispatcherBusinessUnit;
	ParametersForObtainingComposition.LineOfBusiness  = ProductionBatchData.LineOfBusiness;
	ParametersForObtainingComposition.Product                  = ProductionBatchData.MainProductProducts;
	ParametersForObtainingComposition.ItemVariantOfProduct    = ProductionBatchData.MainProductCharacteristic;
	ParametersForObtainingComposition.ProductSpecification      = Object.BillOfMaterials;
	ParametersForObtainingComposition.ProductSpecificationStage  = Object.Stage;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("SelectionOption", SelectionOption);
	ProcedureParameters.Insert("TSName",          TSName);
	ProcedureParameters.Insert("TableOfGoods", TableOfGoods);
	ProcedureParameters.Insert("ParametersForObtainingComposition", ParametersForObtainingComposition);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
		"ProductDataManagement.AddCompositionOfSetsToSelectionResultInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
EndProcedure

&AtClient
Procedure ProcessingOfSelectionResultCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined And Result.Status = "Completed2" Then
		
		ProcessingOfSelectionResultCompletionOnServer(Result);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingOfSelectionResultCompletionOnServer(TimeConsumingOperation)
	
	Result = GetFromTempStorage(TimeConsumingOperation.ResultAddress);
	
	SelectionOption = Result.SelectionOption;
	TableOfGoods = Result.TableOfGoods;
	TSName = Result.TSName;
	
	If SelectionOption = "SelectGoods" Then
		ProcessingSelectionOfSelectionOnServer(TableOfGoods, TSName);
	ElsIf SelectionOption = "SelectMaterialsByBOM" Then
		UploadResultOfSelectingMaterialsBasedOnSpecifications(TableOfGoods);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(TableOfGoods, TSName)
	
	AddedRows = New Array;
	
	For Each String In TableOfGoods Do
		
		If String.ItemsType = Enums.ItemsTypes.Set Then
			
			For Each NewRow In AddSetComposition(String, TSName) Do
				
				If ValueIsFilled(String.Warehouse) Then
					NewRow.Warehouse = String.Warehouse;
				EndIf;
				NewRow.Department = Object.Department;
				AddedRows.Add(NewRow);
				
			EndDo;
			
		Else
			NewRow = ObjectTableByName(Object, TSName).Add();
			FillPropertyValues(NewRow, String);
			NewRow.Department = Object.Department;
			AddedRows.Add(NewRow);
		EndIf;
		
	EndDo;
	
	ArrayOfIdentifiers = New Array;
	LinesForSelectionOfSpecifications = New Array;
	
	StructureOfActions = New Structure;
	If TSName = "SupplyWithMaterialsAndWorks" Then
		StructureOfActions.Insert("FillInPurposeOfProvisionInProductionPhase", ParametersForFillingAssignments);
	ElsIf TSName = "SideAndIntermediateRelease" Then
		InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
	EndIf;
	AddActionsToStructureWhenChangingProducts(TSName, ThisObject, StructureOfActions, True);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	For Each CurrentRow In AddedRows Do
		If TSName = "SupplyWithMaterialsAndWorks" Then
			If CurrentRow.Produced Then
				LinesForSelectionOfSpecifications.Add(CurrentRow);
			EndIf;
		ElsIf RecordOfPerformed
				And (TSName = "ManufacturedProducts"
					Or TSName = "SideAndIntermediateRelease") Then
				CurrentRow.Manufactured = True;
		EndIf;
		
		If TSName = "SideAndIntermediateRelease" Then
			If Object.InternalSubcontracting Then
				CurrentRow.ProductOwner = Object.MaterialProviderCompany;
			EndIf;
		EndIf;
		
		ArrayOfIdentifiers.Add(CurrentRow.GetID());
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActions,
		ObjectTableByName(Object, TSName),
		CachedValues);
	
	If LinesForSelectionOfSpecifications.UBound() <> -1 Then
		FillInSpecificationInLines(LinesForSelectionOfSpecifications);
	EndIf;
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, ArrayOfIdentifiers, StructureOfActions);
	
EndProcedure

&AtServer
Procedure UploadResultOfSelectingMaterialsBasedOnSpecifications(TableOfGoods)
	
	TSName = "SupplyWithMaterialsAndWorks";
	
	RowsArray = New Array;
		
	AssignmentsOfMaterials = New ValueTable();
	AssignmentsOfMaterials.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	AssignmentsOfMaterials.Columns.Add("ZoomRatio", New TypeDescription("Number", New NumberQualifiers()));
	
	If ValueIsFilled(ParametersForFillingAssignments.AssignmentMaterials) Then
		AssignmentsOfMaterials.Add();
		AssignmentsOfMaterials[0].Purpose = ParametersForFillingAssignments.AssignmentMaterials;
		AssignmentsOfMaterials[0].ZoomRatio = 1;
	ElsIf Object.DynamicStructure Then
		AssignmentCoefficients = ProductionSupply.CoefficientsOfSecurityAssignmentsInProductionStage(
			Object,
			Object.ManufacturedProducts.Unload(New Structure("Canceled", False)));
		// If this is a stage with many assignments, then the selection result is loaded
		// with an empty assignment - it must be selected manually.
		If AssignmentCoefficients.Count() = 1 Then
			AssignmentsOfMaterials = AssignmentCoefficients;
		EndIf;
	EndIf;
	
	TypeDescription = New TypeDescription("CatalogRef.Assignments");
	TableOfGoods.Columns.Add("Purpose", TypeDescription);
	TableOfGoods.Columns.Add("SupplyAssignment", TypeDescription);
	
	SpecificationData = New Structure("MaterialsAndServices", TableOfGoods);
	ProductionSupply.FillInAssignmentOfMaterialsSpecifications(
		SpecificationData,
		Object.Stage,
		AssignmentsOfMaterials,
		ParametersForFillingAssignments.AssignmentSemiFinishedProducts);
	
	For Each String In TableOfGoods Do
		If String.ItemsType = Enums.ItemsTypes.Set Then
			For Each NewRow In AddSetComposition(String, TSName) Do
				FillPropertyValues(NewRow, String, "Purpose, SupplyAssignment");
				NewRow.LinkKeyBOM = String.ConnectionKey;
				RowsArray.Add(NewRow.GetID());
			EndDo;
		Else
			NewRow = Object.SupplyWithMaterialsAndWorks.Add();
			FillPropertyValues(NewRow, String);
			NewRow.LinkKeyBOM = String.ConnectionKey;
			RowsArray.Add(NewRow.GetID());
		EndIf;
	EndDo;
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsArray);
	
	CheckForProductItemConstraints(TSName, ThereAreMaterialSpecifications);
	ConfigureDependentFormElements(ThisObject, "ThereAreMaterialSpecifications");
	
EndProcedure

&AtServer
Function PlaceMaterialsForSelectionAccordingToSpecificationInRepository()
	
	Table = Object.SupplyWithMaterialsAndWorks.Unload(,
		"Products,Characteristic,NumberOfPackages,Package,Department");
	
	Return PutToTempStorage(Table, UUID);
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	SubsystemSettingsProduction = ProductionServer.SubsystemSettingsProduction();
	FillPropertyValues(ThisObject, SubsystemSettingsProduction);
	ProductionStage2_2Localization.FillInServiceDetailsOfForm(ThisObject);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.ProductionStage2_2));
	SetVisibilityOfSeriesElements();
	
	StageEditingParameters = New FixedStructure(Documents.ProductionStage2_2.StageEditingParameters());
	CostAllocationParameters = New FixedStructure(Documents.ProductionStage2_2.CostAllocationParameters(Object));
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(Object, Documents.ProductionStage2_2);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.SupplyWithMaterialsAndWorksBillOfMaterials, BOMSelectionParameters.SupplyWithMaterialsAndWorks);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.ManufacturedProductsBillOfMaterials, BOMSelectionParameters.ManufacturedProducts);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.SideAndIntermediateReleaseBillOfMaterials, BOMSelectionParameters.ManufacturedProducts);
	
	StorageAddressStandards = "";
	ProductionBatchData = Documents.ProductionStage2_2.ProductionBatchData(Object.ReferenceOrder, Object.AssignmentProducts, Object.ProductionLot);
	
	AttributesNames = New Structure;
	AttributesNames.Insert("Description");
	AttributesNames.Insert("ProductKind");
	AttributesNames.Insert("UnitOfMeasurementName", "UnitOfMeasure.Description");
	MainProductData = Common.ObjectAttributesValues(
		ProductionBatchData.MainProductProducts, AttributesNames);
	MainProductDescription = MainProductData.Description;
	MainProductProductKind = MainProductData.ProductKind;
	MainProductUnitOfMeasurementName = MainProductData.UnitOfMeasurementName;
	
	CompanyBeforeChange            = Object.Organization;
	
	UseInternalSubcontracting =
		GetFunctionalOption("UseInternalSubcontracting")
		And Not Object.WorkPlanning;
	
	UseSeveralWarehouses      = GetFunctionalOption("UseSeveralWarehouses");
	DefaultWarehouse = TMCommonUse.GetCheckWarehouseByDefault();
	
	UseWriteOffForExpenses =
		(GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities")
			Or GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"))
		And True;
	
	
	DocumentCurrency = Object.Currency;
	
	SpecialTextColor = StyleColors.SpecialTextColor;
	
	RightToReadSubstitutes = GetFunctionalOption("UseAlternativeMaterials")
						  And AccessRight("Read", Metadata.InformationRegisters.AlternativeMaterials);
	RightToEditProductionSchedule = AccessRight("Update", Metadata.InformationRegisters.ScheduleOfProductionStages2_2);
	
	BasicBufferTimeUnit = Catalogs.ProductionStages.BasicBufferTimeUnit();
	TheBasicUnitOfTimeForTheDurationOfTheUBBWStage = Catalogs.ProductionStages.TheBasicUnitOfTimeForTheDurationOfTheUBBWStage();
	
	Enums.StatusesOfProductionStages2_2.FillChoiceList(Items.Status.ChoiceList, Object.Status);
	
	ListOfOrders_ = New Array;
	ListOfOrders_.Add(Object.ReferenceOrder);
	ProductionManagement.UpdateAttributeYouNeedToFillInStageConsumerField(ThisObject, ListOfOrders_);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
		Or False Then
		PurposeOfTollRelease = Documents.ProductionStage2_2.DefaultAssignmentForByProducts(Object.ReferenceOrder);
	EndIf;
	
	AllowableDeviationOfAutomaticRounding = TMCommonUseCached.AllowableDeviationOfAutomaticRounding();
	
	UpdateOrderForActivity(False);
	
	ItemsAndDimensionsSelectionParameters = Documents.ProductionStage2_2.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	SetupParameters = Documents.ProductionStage2_2.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	
	StartWaitingForCalculationOfCollateral = ThereAreTasksForCalculatingCollateral(Object.ReferenceOrder,
		Object.SupplyWithMaterialsAndWorks.Unload(New Structure("Canceled", False), "Products")
		.UnloadColumn("Products"));
	
	RecalculateNumberOfUnitsInHeader();
	FillInDetailsForDivision();
	FillInDetailsOfOrder();
	FillInAttributesAccordingToSpecification();
	ReadExternalAttributes();
	FillInDetailsForOrganizationOfGiver();
	
	FillInServiceDetails();
	FillInServiceDetailsOfTableParts();
	EstablishUseOfPlannedValue();
	
	ProcessingOfTabularForms.InitializeRowCache(Items.ManufacturedProducts);
	ProcessingOfTabularForms.InitializeRowCache(Items.SideAndIntermediateRelease);
	ProcessingOfTabularForms.InitializeRowCache(Items.SupplyWithMaterialsAndWorks);
	ProcessingOfTabularForms.InitializeRowCache(Items.MaterialsAndWorksConsumption);
	
	FillInProductionSchedule();
	FillInStateOfOperations();
	FillInProcessorSOrderDetails();
	
	CheckForProductItemConstraints("SupplyWithMaterialsAndWorks", ThereAreMaterialSpecifications);
	CheckForProductItemConstraints("SideAndIntermediateRelease", ThereAreSideProductSpecifications);
	
	FillInAssignmentSelectionParameters();
	FillInSelectionListOfProductOwners(ThisObject);
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure FillInDetailsForDivision(Initialize = True)
	
	DivisionParameters = ProductionServerCached.ProductionBusinessUnitDescription(Object.Department);
	
	FillPropertyValues(
		ThisObject,
		DivisionParameters,
		"UseOperationManagement,
		|UseManufacturingExecutionSystem,
		|UseTeamWorkOrders,
		|UseShiftTasks");
	
	PlanningInterval = DivisionParameters.PlanningInterval;
	
	If Not Initialize Then
		
		ProductionProcessEditor.SaveTypesOfWorkCenters(
					WorkCenterTypes, 
					Object.PlanOperationsOfWorkCenterTypes,
					Object.WorkCenterTypes,
					Object.AlternateWorkCenterTypes);
		
		ProductDataManagement.CheckComplianceOfDetailsWithDivision(Object, "WorkCenterTypes");
		
	EndIf; 
	
	FillInTheTypesOfWorkCenters();
	
	ProductionProcessEditor.FillInSelectionOfBufferUnit(
			PlanningInterval, 
			Items.UnitOfMeasureOfPreliminaryBuffer.ChoiceList);
			
	ProductionProcessEditor.FillInSelectionOfBufferUnit(
			PlanningInterval, 
			Items.UnitOfMeasureOfFollowUpBuffer.ChoiceList);
	
EndProcedure

&AtServer
Procedure FillInDetailsOfOrder()
	
	DetailsOfOrder = Common.ObjectAttributesValues(Object.ReferenceOrder, 
		"EarliestStartDate,Department");
	
	EarliestStartDate          = DetailsOfOrder.EarliestStartDate;
	ProductionDispatcherBusinessUnit = DetailsOfOrder.Department;
	
EndProcedure

&AtServer
Procedure FillInAttributesAccordingToSpecification()
	
	SimultaneouslyManufacturedQuantity = 0;
	If Not Object.BillOfMaterials.IsEmpty()
		And Not Object.Stage.IsEmpty() Then
		QueryText = 
			"SELECT
			|	CASE
			|		WHEN BillsOfMaterials.ProductionIssueByCustomPortions
			|			THEN ProductionStages.QuantityOfProductUnitsLotsProducedSimultaneously
			|		ELSE ProductionStages.QuantityOfProductUnitsLotsProducedSimultaneously
			|				* ProductsBOM.NumberOfPackagesPerStartingLotUnit
			|				* ISNULL(&PackagingFactor, 1)
			|	END AS SimultaneouslyManufacturedQuantity
			|FROM
			|	Catalog.ProductionStages AS ProductionStages
			|	
			|	INNER JOIN Catalog.BillsOfMaterials AS BillsOfMaterials
			|	ON ProductionStages.Owner = BillsOfMaterials.Ref
			|	
			|	LEFT JOIN InformationRegister.ProductsBOM AS ProductsBOM
			|	ON NOT BillsOfMaterials.ProductionIssueByCustomPortions
			|		AND ProductsBOM.ProductKind = &ProductKind
			|		AND ProductsBOM.Products = &Products
			|		AND ProductsBOM.Characteristic = &Characteristic
			|		AND ProductsBOM.BillOfMaterials = &BillOfMaterials
			|WHERE
			|	ProductionStages.Ref = &Stage";
		
		QueryText = StrReplace(
			QueryText,
			"&PackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"ProductsBOM.Package",
				"ProductsBOM.Products"));
		
		Query = New Query(QueryText);
		Query.SetParameter("ProductKind", MainProductProductKind);
		Query.SetParameter("Products", ProductionBatchData.MainProductProducts);
		Query.SetParameter("Characteristic", ProductionBatchData.MainProductCharacteristic);
		Query.SetParameter("BillOfMaterials", Object.BillOfMaterials);
		Query.SetParameter("Stage", Object.Stage);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			SimultaneouslyManufacturedQuantity = Selection.SimultaneouslyManufacturedQuantity;
		EndIf;
	EndIf;
	
	If SimultaneouslyManufacturedQuantity <> 0 Then
		NumberOfStandardCalculationTypesOfRC = SimultaneouslyManufacturedQuantity;
	ElsIf Object.QuantityPerReleaseLotUnit <> 0 Then
		NumberOfStandardCalculationTypesOfRC = Object.QuantityPerReleaseLotUnit;
	Else
		NumberOfStandardCalculationTypesOfRC = 1;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDetailsForOrganizationOfGiver()
	
	If ValueIsFilled(Object.MaterialProviderCompany) Then
		
		LocalAccountingCurrency =
			SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.MaterialProviderCompany);
		
		RegistrationCountry =
			Common.ObjectAttributeValue(Object.MaterialProviderCompany, "RegistrationCountry");
			
	Else
		LocalAccountingCurrency = Undefined;
		RegistrationCountry = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadExternalAttributes()
	
	SetPrivilegedMode(True);
	
	Query = New Query(
		"SELECT
		|	TechnicalProcess.TechnologicalProcessType                                                                     AS TechnologicalProcessType,
		|	TechnicalProcess.TechnologicalProcess                                                                          AS TechnologicalProcess,
		|	TechnicalProcess.TechnologicalProcessFactor                                                             AS TechnologicalProcessFactor,
		|	TechnicalProcess.FirstOperationID                                                                     AS FirstOperationID,
		|	TechnicalProcess.LastOperationID                                                                  AS LastOperationID,
		|	ISNULL(FirstOperation.Operation.Ref, FirstOperation.ProductionOperation)                          AS FirstOperation,
		|	ISNULL(FirstOperation.Operation.Description, FirstOperation.ProductionOperation.Description)       AS FirstOperationPresentation,
		|	ISNULL(LastOperation_.Operation.Ref, LastOperation_.ProductionOperation)                    AS LastOperation_,
		|	ISNULL(LastOperation_.Operation.Description, LastOperation_.ProductionOperation.Description) AS LastOperation_Presentation
		|FROM
		|	Document.ProductionStage2_2 AS DocStage
		|	
		|	LEFT JOIN InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcess
		|	ON DocStage.Ref = TechnicalProcess.Stage
		|
		|	LEFT JOIN InformationRegister.QueueOfProductionOperations AS FirstOperation
		|	ON DocStage.Ref = FirstOperation.Stage
		|		AND TechnicalProcess.FirstOperationID = FirstOperation.OperationID
		|		AND FirstOperation.MainEntry_
		|
		|	LEFT JOIN InformationRegister.QueueOfProductionOperations AS LastOperation_
		|	ON DocStage.Ref = LastOperation_.Stage
		|		AND TechnicalProcess.LastOperationID = LastOperation_.OperationID
		|		AND LastOperation_.MainEntry_
		|
		|WHERE
		|	DocStage.Ref = &Stage
		|
		|;
		|
		|SELECT TOP 1
		|	TRUE AS OperationsAreAssigned
		|FROM
		|	InformationRegister.OperationsToCreateShiftTasks AS AssignedOperations
		|WHERE
		|	AssignedOperations.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
		|	AND AssignedOperations.Stage = &Stage
		|
		|");
	Query.SetParameter("Stage", Object.Ref);
	
	QueryResults = Query.ExecuteBatch();
	
	SamplingProcessData = QueryResults[0].Select();
	If SamplingProcessData.Next() Then
		FillPropertyValues(ThisObject, SamplingProcessData);
	EndIf;
	
	If (ValueIsFilled(FirstOperationID)
			And Not ValueIsFilled(FirstOperation))
		Or (ValueIsFilled(LastOperationID)
			And Not ValueIsFilled(LastOperation_)) Then
		
		Operations = InformationRegisters.QueueOfProductionOperations.ListOfOperationsAccordingToStageData(
			Documents.ProductionStage2_2.DataForCalculatingOperationQueue(Object.Ref, False)[Object.Ref]);
		
		LineOperation = Operations.Find(FirstOperationID, "OperationID");
		If LineOperation <> Undefined Then
			FirstOperation = LineOperation.Operation;
			FirstOperationPresentation = LineOperation.OperationPresentation;
		EndIf;
		
		LineOperation = Operations.Find(LastOperationID, "OperationID");
		If LineOperation <> Undefined Then
			LastOperation_ = LineOperation.Operation;
			LastOperation_Presentation = LineOperation.OperationPresentation;
		EndIf;
		
	EndIf;
	
	SamplingAssignedOFOperations = QueryResults[1].Select();
	If SamplingAssignedOFOperations.Next() Then
		FillPropertyValues(ThisObject, SamplingAssignedOFOperations);
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()

	CurrentStatus = Object.Status;
	
	ProductionMethod = GetProductionMethod(ThisObject);
	PlanningMethod = GetPlanningMethod(ThisObject);
	
	MarkPlanNotEarlierThan = ValueIsFilled(Object.PlanNotEarlierThan);
	If Object.DynamicStructure Then
		PlanNoEarlierThanDate = Object.PlanNotEarlierThan;
	Else
		LabelPlanNotEarlierThan = FormattedStringPlanNotEarlier(
			Object.PlanNotEarlierThan,
			ScheduleDateFormat);
	EndIf;
	
	StageExecutionIsStarted = (CurrentStatus = StatusStarted())
		Or (CurrentStatus = StatusCompleted_1());
	StageIsCompleted = (CurrentStatus = StatusCompleted_1());
	
	If StageIsCompleted Then
		EventDateCompletion = BegOfDay(Object.ActualStageEnd);
	Else
		EventDateCompletion = Undefined;
	EndIf;
	
	ThereIsRightToDivideParty = AccessRight("Use", Metadata.DataProcessors.ProductionLotDivision);
	ThereIsRightToAdd = AccessRight("Insert", Metadata.Documents.ProductionStage2_2);
	HasEditPermission = AccessRight("Update", Metadata.Documents.ProductionStage2_2);
	
	UseOfKitsInProductionIsAvailable = ProductDataManagementCached.UseOfKitsInProductionIsAvailable();
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	
EndProcedure

&AtServer
Procedure EstablishUseOfPlannedValue()
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"FinancialAccountingPolicy",
		Object.Organization,
		Object.Date);
	
	If Not AccountingPolicyParameters = Undefined Then
		UseTargetCost = AccountingPolicyParameters.ProductCostingByPlannedCost;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTableParts(ListOfTS = "", FillInLines = Undefined)
	
	StructureOfTS = New Structure(ListOfTS);
	AllTS = (StructureOfTS.Count() = 0);
	
	If StructureOfTS.Property("ManufacturedProducts") Or AllTS Then
		ProductionManagement.FillInServiceDetailsOfOutputProductsOfProductionStage(Object.ManufacturedProducts, FillInLines);
		ProductionManagement.FillInWHReleaseDirection(?(FillInLines <> Undefined, FillInLines, Object.ManufacturedProducts));
		GLAccountSettingsServer.UpdateSettingsPresentation(ThisObject, "Object.ManufacturedProducts");
		CalculatePercentageOfCostAllocationForOutputProducts();
	EndIf;
	
	If StructureOfTS.Property("SideAndIntermediateRelease") Or AllTS Then
		ProductionManagement.FillInServiceDetailsOfOutputProductsOfProductionStage(Object.SideAndIntermediateRelease, FillInLines);
		ProductionManagement.FillInWHReleaseDirection(?(FillInLines <> Undefined, FillInLines, Object.SideAndIntermediateRelease));
		GLAccountSettingsServer.UpdateSettingsPresentation(ThisObject, "Object.SideAndIntermediateRelease");
		InternalSubcontractingServer.FillInProductOwnerIsAvailableInTable(ThisObject, Object.SideAndIntermediateRelease);
	EndIf;
	
	If StructureOfTS.Property("MaterialsAndWorksConsumption") Or AllTS Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
		StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		
		ProductsServer.FillInServiceDetailsForProductInCollection(
			Object.MaterialsAndWorksConsumption,
			StructureOfActions,
			FillInLines);
		
	EndIf;
	
	If StructureOfTS.Property("UnusedMaterials") Or AllTS Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
		StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		
		ProductsServer.FillInServiceDetailsForProductInCollection(
			Object.UnusedMaterials,
			StructureOfActions,
			FillInLines);
			
		RowsCollection = ?(FillInLines <> Undefined, FillInLines, Object.UnusedMaterials);
		For Each RowData In RowsCollection Do
			RowData.Actions = ?(RowData.ToExpenseAs, 
										Enums.BusinessTransactions.GoodsConsumptionOnDemand, 
										Enums.BusinessTransactions.ReturnFromProduction);
		EndDo;
		
		ProductionServer.FillInShopPantryAttributeInTable(Object.UnusedMaterials, "Recipient",, FillInLines);
		GLAccountSettingsServer.UpdateSettingsPresentation(ThisObject, "Object.UnusedMaterials");
		
	EndIf;
	
	If StructureOfTS.Property("SupplyWithMaterialsAndWorks") Or AllTS Then

		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
		StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		
		If Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
			And Object.WorkPlanning Then
			StructureOfActions.FillInFeatureAttribute.Insert("UnderRepairProduct", "FinishedProductBeingRepairedCharacteristicsAreUsed");
			StructureOfActions.FillInProductTypeAttribute_.Insert("UnderRepairProduct", "RepairedFinishedProductTypeOfItem");
		EndIf;
		
		ProductsServer.FillInServiceDetailsForProductInCollection(
			Object.SupplyWithMaterialsAndWorks,
			StructureOfActions,
			FillInLines);
		
		FillInStandards("SupplyWithMaterialsAndWorks", FillInLines);
		
		ProductionServer.FillInShopPantryAttributeInTable(Object.SupplyWithMaterialsAndWorks, "Warehouse",, FillInLines);
		
		If RightToReadSubstitutes And ShowAnalogues And Not Object.WorkPlanning Then
			NotePresenceOfAnalogues();
		EndIf;
		
		ProvisionInDocumentsServer.FillInServiceDetailsOfDocumentForm(
			DocumentParametersForSoftwareActions(ThisObject));
		
		ProductDataManagement.FillInDetailsIncludedInSet(Object);
		
	EndIf;
	
	If StructureOfTS.Property("LaborCosts") Or AllTS Then
		
		FillInStandards("LaborCosts", FillInLines);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInTheTypesOfWorkCenters()
	
	ProductionProcessEditor.FillInTreeOfTypesOfWorkCenters(
		Object.WorkCenterTypes,
		Object.AlternateWorkCenterTypes,
		WorkCenterTypes,
		False);
	
	ProductionProcessEditorClientServer.CalculateServiceSignsOfLoadingVRC(
		WorkCenterTypes,,
		ThereIsSynchronousLoad);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsInLineOfTypesOfRC(Id)
	
	RowData = WorkCenterTypes.FindByID(Id);
	If RowData = Undefined Then
		Return;
	EndIf;
	
	ProductionProcessEditor.FillInServiceDetailsInLineOfTypesOfRC(
				Undefined, 
				Undefined, 
				True, 
				RowData);
	
	ProductionProcessEditorClientServer.CalculateServiceSignsOfLoadingVRC(
		WorkCenterTypes,,
		ThereIsSynchronousLoad);
	
EndProcedure

&AtServer
Function FormattedStringLabelSpecification()
	
	RowsArray = New Array();
	
	If Not Object.BillOfMaterials.IsEmpty() Then
		
		Table = New ValueTable;
		Table.Columns.Add("Title");
		Table.Columns.Add("RepresentationOfTheReference");
		Table.Columns.Add("Ref");
		Table.Columns.Add("Required2");
		Table.Columns.Add("Available");
		
		NewRow = Table.Add();
		NewRow.Title = "";
		NewRow.RepresentationOfTheReference = Common.ObjectAttributeValue(Object.BillOfMaterials, "Description");
		NewRow.Ref = "#OpenBillOfMaterials";
		NewRow.Required2 = StrLen(NewRow.RepresentationOfTheReference);
		NewRow.Available = Min(NewRow.Required2, 50);
		RowsToRecalculate = ?(NewRow.Available < NewRow.Required2, 1, 0);
			
		If ValueIsFilled(FirstOperation) Then
			NewRow = Table.Add();
			NewRow.Title = NStr("vi = 'có giao dịch:';
								|ru = 'с операции:';
								|en = 'from operation:'; fa = 'from operation:';
								|it = 'с операции:';
								|pl = 'from operation:';
								|tr = 'işlem ile:'") + " ";
			NewRow.RepresentationOfTheReference = FirstOperationPresentation;
			NewRow.Ref = "#OpenFirstOperation";
			NewRow.Required2 = StrLen(NewRow.Title) + StrLen(NewRow.RepresentationOfTheReference);
			NewRow.Available = Min(NewRow.Required2, 25);
			RowsToRecalculate = ?(NewRow.Available < NewRow.Required2, RowsToRecalculate+1, RowsToRecalculate);
		EndIf;
		
		If ValueIsFilled(LastOperation_) Then
			NewRow = Table.Add();
			NewRow.Title = NStr("vi = 'theo giao dịch:';
								|ru = 'по операцию:';
								|en = 'to operation:'; fa = 'to operation:';
								|it = 'по операцию:';
								|pl = 'to operation:';
								|tr = 'işleme göre:'") + " ";
			NewRow.RepresentationOfTheReference = LastOperation_Presentation;
			NewRow.Ref = "#OpenLastOperation";
			NewRow.Required2 = StrLen(NewRow.Title) + StrLen(NewRow.RepresentationOfTheReference);
			NewRow.Available = Min(NewRow.Required2, 25);
			RowsToRecalculate = ?(NewRow.Available < NewRow.Required2, RowsToRecalculate+1, RowsToRecalculate);
		EndIf;
		
		Balance = 100 - Table.Total("Available");
		If Balance > 0 And RowsToRecalculate > 0 Then
			For Each String In Table Do
				If String.Available < String.Required2 Then
					Count = Min(String.Required2 - String.Available,
						?(RowsToRecalculate = 1, Balance, Round(Balance/RowsToRecalculate)));
					String.Available = String.Available + Count;
					Balance = Balance - Count;
					RowsToRecalculate = RowsToRecalculate - 1;
				EndIf;
				If Balance = 0 Or RowsToRecalculate = 0 Then
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		RowsArray = New Array();
		
		For IndexOf = 0 To Table.Count()-1 Do
			String = Table[IndexOf];
			
			If Not IsBlankString(String.Title) Then
				RowsArray.Add(String.Title);
			EndIf;
			
			RepresentationOfTheReference = ?(String.Available < String.Required2,
				Left(String.RepresentationOfTheReference, String.Available - StrLen(String.Title) - 3) + "...",
				String.RepresentationOfTheReference);
			RowsArray.Add(New FormattedString(RepresentationOfTheReference,,,,String.Ref));
			
			If IndexOf < Table.Count()-1 Then
				RowsArray.Add("  ");
			EndIf;
		EndDo;
		
	Else
		RowsArray.Add("<" + NStr("vi = 'không có bảng kê chi tiết các nguồn lực sản xuất';
								|ru = 'нет спецификации';
								|en = 'no BOM'; fa = 'no BOM';
								|it = 'non ci sono specifiche';
								|pl = 'brak specyfikacji';
								|tr = 'ürün reçetesi yok'") + ">");
	EndIf;
	
	If AccessRight("Use", Metadata.DataProcessors.EditProductionStageSequence) Then
		RowsArray.Add("  ");
		RowsArray.Add(New FormattedString(NStr("vi = 'hiển thị các công đoạn';
												|ru = 'показать этапы';
												|en = 'show stages'; fa = 'show stages';
												|it = 'mostrare le fasi';
												|pl = 'pokaż etapy';
												|tr = 'aşamaları göster'"),,,, "#ShowStages"));
	EndIf;
	
	If VisibilityOfOperationalControlElements(ThisObject)
			And AccessRight("Use", Metadata.DataProcessors.ProductionProcessEditor)
			And Object.Posted Then
		RowsArray.Add("  ");
		If Object.Status = StatusCompleted_1() Then
			HyperlinkText = NStr("vi = 'hiển thị quy trình kỹ thuật';
								|ru = 'показать техпроцесс';
								|en = 'show technological process'; fa = 'show technological process';
								|it = 'show technological process';
								|pl = 'show technological process';
								|tr = 'Teknolojik süreci göster'");
		Else
			HyperlinkText = NStr("vi = 'thay đổi quy trình công nghệ';
								|ru = 'изменить техпроцесс';
								|en = 'edit technological process'; fa = 'edit technological process';
								|it = 'edit technological process';
								|pl = 'edit technological process';
								|tr = 'teknolojik süreci değiştir'");
		EndIf;
		If TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.AlternateType Then
			HyperlinkText = StrTemplate("%1 (%2)", HyperlinkText, TechnologicalProcess);
		ElsIf TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.Individual_ Then
			HyperlinkText = StrTemplate("%1 (%2)", HyperlinkText, NStr("vi = 'riêng biệt';
																		|ru = 'индивидуальный';
																		|en = 'individual'; fa = 'individual';
																		|it = 'individual';
																		|pl = 'individual';
																		|tr = 'özelleştirilmiş'"));
		EndIf;
		RowsArray.Add(New FormattedString(HyperlinkText,,,, "#EditTechnicalProcess"));
	EndIf;
	
	Return New FormattedString(RowsArray);
	
EndFunction

&AtServer
Function FormattedStringLabelProduct()
	
	RowsArray = New Array();
	
	If ValueIsFilled(ProductionBatchData.MainProductProducts) Then
		
		RowsArray.Add(New FormattedString(MainProductDescription,,,,"#OpenProduct"));
		
		If ValueIsFilled(ProductionBatchData.MainProductCharacteristic) Then
			
			RowsArray.Add(" / ");
			StringCharacteristic = Common.ObjectAttributeValue(
				ProductionBatchData.MainProductCharacteristic,
				"Description");
			RowsArray.Add(New FormattedString(StringCharacteristic,,,,"#OpenProductDescription"));
			
		EndIf;
		
	Else
		RowsArray.Add("<" + NStr("vi = 'không có hàng hóa';
								|ru = 'нет изделия';
								|en = 'no item'; fa = 'no item';
								|it = 'nessun prodotto';
								|pl = 'brak wyrobu';
								|tr = 'nihai ürün yok'") + ">");
	EndIf;
	
	Return New FormattedString(RowsArray);
	
EndFunction

&AtServerNoContext
Function PresentationStage(Data_Stage)
	
	Return Documents.ProductionStage2_2.PresentationStage(Data_Stage);
	
EndFunction

&AtServer
Procedure UpdateOrderForActivity(Fill = True)
	
	FillParameters = Documents.ProductionStage2_2.ParametersForFillingInVATActivityType(Object);
	
	If Fill Then
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.ProductionIssueForActivity,
			FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		Items.ProductionIssueForActivity,
		Object.ProductionIssueForActivity,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtClient
Procedure WhenChangingProducts(LineOfATabularSection, TSName)
	
	StructureOfActions = New Structure;
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		
		If Not RecordOfPerformed Then
			LineOfATabularSection.Manufactured = False;
		EndIf;
		
		StructureOfActions.Insert("CheckFillAssignment", PurposeOfTollRelease);
		
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		StructureOfActions.Insert("CheckFillCommunicationKeySpecifications");
		AddCheckActionFillInSpecification(ThisObject, StructureOfActions, LineOfATabularSection);
		ProvisionInDocumentsClientServer.AddCollateralActions(
			StructureOfActions,
			"AvailableInOtherLines",
			DocumentParametersForSoftwareActions(ThisObject));
		StructureOfActions.Insert("FillInPurposeOfProvisionInProductionPhase", ParametersForFillingAssignments);
	EndIf;
	
	AdditionalParameters = Undefined;
	If TSName = "SupplyWithMaterialsAndWorks"
		And RecordOfPerformed Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("SupplyOption",
			PredefinedValue("Enum.SupplyOptions.Ship"));
		AdditionalParameters.Insert("WarehouseOnlyHasItsOwnShopFloorStockroom", True);
	EndIf;
	
	ProductionManagementClientServer.AddActionsToStructureWhenChangingProducts(
			TSName,
			ThisObject,
			Object,
			StructureOfActions,
			AdditionalParameters);
	
	ProductionManagementClientServer.AddQualityControlActionsToStructure(
		TSName,
		StructureOfActions,
		CacheQualityControl);
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		WarehouseForSeries = LineOfATabularSection.Recipient;
	ElsIf TSName = "UnusedMaterials" Then
		WarehouseForSeries = LineOfATabularSection.Recipient;
	ElsIf TSName = "MaterialsAndWorksConsumption" Then
		WarehouseForSeries = LineOfATabularSection.Department;
	ElsIf TSName = "SupplyWithMaterialsAndWorks" Then
		WarehouseForSeries = LineOfATabularSection.Warehouse;
	EndIf;
	SeriesVerificationParameters = New Structure;
	SeriesVerificationParameters.Insert("Warehouse", WarehouseForSeries);
	SeriesVerificationParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters[TSName]);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		
		AddActionFillProductionDate(ThisObject, StructureOfActions);
		
		ProductionClientServer.AddToStructureActionsCheckFillProductionWarehouse(
			LineOfATabularSection.Department, StructureOfActions, "Recipient");
		
		
		If TSName = "SideAndIntermediateRelease" Then
			InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
		EndIf;
		
	EndIf;
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Or TSName = "UnusedMaterials" Then
		IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, ThisObject, "Object." + TSName);
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	EndIf;
	
	If (TSName = "ManufacturedProducts" And UseTargetCost)
		Or TSName = "SideAndIntermediateRelease" Then
			
		StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(ThisObject));
		StructureOfActions.Insert("RecalculateAmount");
		
	EndIf;
	
	If TSName = "MaterialsAndWorksConsumption" Then
		BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
			ThisObject, "Products", StructureOfActions);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(LineOfATabularSection, StructureOfActions, CachedValues);
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		
		FillReleaseDirectionSelectionList(LineOfATabularSection, TSName);

	ElsIf TSName = "SupplyWithMaterialsAndWorks" Then
		
		ProvisionInDocumentsClientServer.FillInServiceDetails(
			Object.SupplyWithMaterialsAndWorks,
			DateOfShipmentRequired_,
			WarehouseIsRequired);
		
		If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions)
				Or RightToReadSubstitutes And ShowAnalogues Then
					
					ProvisionOfMaterialsAndWorksInCaseOfChangesInProductRange();
					
		EndIf;
		
		WhenChangingNomenclatureOfCharacteristicInLineIncludedInSet();
		
	ElsIf TSName = "UnusedMaterials" Then
		
		ProductionManagementClient.SavingMaterialsFillInFeatureSeparately(LineOfATabularSection, Object.SupplyWithMaterialsAndWorks);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingCharacteristics(LineOfATabularSection, TSName)
	
	StructureOfActions = New Structure;
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		
		If Not RecordOfPerformed Then
			LineOfATabularSection.Manufactured = False;
		EndIf;
		
		StructureOfActions.Insert("CheckFillAssignment", PurposeOfTollRelease);
		
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		StructureOfActions.Insert("CheckFillCommunicationKeySpecifications");
		AddCheckActionFillInSpecification(ThisObject, StructureOfActions, LineOfATabularSection);
		ProvisionInDocumentsClientServer.AddCollateralActions(
			StructureOfActions,
			"AvailableInOtherLines",
			DocumentParametersForSoftwareActions(ThisObject));
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	EndIf;
	
	If (TSName = "ManufacturedProducts" And UseTargetCost)
		Or TSName = "SideAndIntermediateRelease" Then
			
		StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(ThisObject));
		StructureOfActions.Insert("RecalculateAmount");
		
	EndIf;
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		AddActionFillProductionDate(ThisObject, StructureOfActions);
	EndIf;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		ProductionClientServer.AddToStructureActionsCheckFillProductionWarehouse(
			LineOfATabularSection.Department, StructureOfActions);
		StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	EndIf;
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, TSName));

	BatchProcessingOfTablePartClient.ProcessTSString(LineOfATabularSection, StructureOfActions, CachedValues);
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		If ProvisionInDocumentsClient.YouNeedToUpdateAvailableColumn(StructureOfActions)
				Or RightToReadSubstitutes And ShowAnalogues Then
					
					ProvisionOfMaterialsAndWorksInCaseOfChangesInCharacteristics();
					
		EndIf;
		
		WhenChangingNomenclatureOfCharacteristicInLineIncludedInSet();
		
	ElsIf TSName = "UnusedMaterials" Then
		
		ProductionManagementClient.SavingMaterialsFillInFeatureSeparately(LineOfATabularSection, Object.SupplyWithMaterialsAndWorks);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingNumberOfPackages(LineOfATabularSection, TSName)

	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingPackagesNumber(TSName, ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(LineOfATabularSection, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure WhenChangingRecipient(LineOfATabularSection, TSName)
	
	ProductionManagementClient.RecipientOnChange(
		LineOfATabularSection,
		TSName,
		ThisObject,
		Object,
		CachedValues);
	
EndProcedure

&AtClient
Procedure WhenFlagIsChangedFollowingIsDone(Val TSName)

	CurrentData = Items[TSName].CurrentData;
	
	NeedContextualServerCall = False; 
	
	If CurrentData.Manufactured And Not StageExecutionIsStarted Then
		NeedContextualServerCall = True;
	EndIf;
	
	CurrentSessionDate = StartOfDayCurSessionDate();

	If CurrentData.Manufactured And Object.ProductionInOneDay And CurrentSessionDate <> Object.ProductionDate And NumberOfLinesFinishedProducts > 1 Then
		NeedContextualServerCall = True;
	EndIf;
	
	If NeedContextualServerCall Then 
		WhenFlagIsChangedItIsMadeOnServer(TSName, Items[TSName].CurrentRow, CurrentSessionDate);
		Return;
	EndIf;
	
	If CurrentData.Manufactured And Object.ProductionInOneDay And CurrentSessionDate <> Object.ProductionDate And NumberOfLinesFinishedProducts = 1 Then
		Object.ProductionDate = CurrentSessionDate;
		ConfigureDependentFormElements(ThisObject, "ProductionDate");
	EndIf;
	
	StructureOfActions = New Structure;
	
	SeriesVerificationParameters = New Structure;
	SeriesVerificationParameters.Insert("Warehouse", CurrentData.Recipient);
	SeriesVerificationParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters[TSName]);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	If TSName = "SideAndIntermediateRelease" Or UseTargetCost Then
		If TSName = "ManufacturedProducts" And CurrentData.Price = 0 Then
			// If the price is set, the flag change should not change it.
			StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(ThisObject));
		EndIf;
		StructureOfActions.Insert("RecalculateAmount");
	EndIf;
	
	AddActionFillProductionDate(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure WhenFlagIsChangedItIsMadeOnServer(Val TSName, Val RowID, Val CurrentSessionDate)
	
	CurrentData = Object[TSName].FindByID(RowID);
	
	If CurrentData.Manufactured Then
		ChangedBankingDetails = "";
		If Object.ProductionInOneDay And Object.ProductionDate <> CurrentSessionDate Then
			If NumberOfLinesFinishedProducts = 1 Then
				Object.ProductionDate = CurrentSessionDate;
				ChangedBankingDetails = "ProductionDate";
			ElsIf Object.ProductionDate < CurrentSessionDate And NumberOfRowsProduced() = 1 Then
				Object.ProductionDate = CurrentSessionDate;
				ChangedBankingDetails = "ProductionDate";
				ProductionDateWhenModifiedOnServer();
			Else
				Object.ProductionInOneDay = False;
				ChangedBankingDetails = "ProductionInOneDay";
				If Object.ProductionDate < CurrentSessionDate Then
					ToShiftPlannedProductionDatesToDate(CurrentSessionDate);
				EndIf;
			EndIf;
		EndIf;
		If Not StageExecutionIsStarted Then
			StageExecutionIsStarted = True;
			ProcessStartOfStageExecution(ChangedBankingDetails);
		ElsIf ChangedBankingDetails <> "" Then
			ConfigureDependentFormElements(ThisObject, ChangedBankingDetails);
		EndIf;
	EndIf;
	
	StructureOfActions = New Structure;
	
	SeriesVerificationParameters = New Structure;
	SeriesVerificationParameters.Insert("Warehouse", CurrentData.Recipient);
	SeriesVerificationParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters[TSName]);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	If TSName = "SideAndIntermediateRelease" Or UseTargetCost Then
		StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(ThisObject));
		StructureOfActions.Insert("RecalculateAmount");
	EndIf;
	
	AddActionFillProductionDate(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure WhenChangingDirectionOfRelease(LineOfATabularSection, TSName)
	
	ProductionManagementClient.OutputProductsOfStageOfDirectionOfReleaseWhenChanging(
		LineOfATabularSection,
		TSName,
		ThisObject,
		Object,
		CachedValues);
	
EndProcedure

&AtClient
Procedure FillReleaseDirectionSelectionList(LineOfATabularSection, TSName)
	
	ItemSelectionList = ProductionManagementClient.FillReleaseDirectionSelectionList(
		LineOfATabularSection,
		TSName,
		ThisObject);
	
	If ItemSelectionList.FindByValue(LineOfATabularSection.DirectionOfProductionIssue) = Undefined Then
		LineOfATabularSection.DirectionOfProductionIssue = ItemSelectionList[0].Value;
		WhenChangingDirectionOfRelease(LineOfATabularSection, TSName);
	EndIf;
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer()
	
	OldCurrency                = DocumentCurrency;
	NewCurrency                 = Object.Currency;
	DocumentDate               = ?(ValueIsFilled(Object.ActualStageStart),
		Object.ActualStageStart, CurrentSessionDate());
	StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate);
	StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency,  DocumentDate);
	
	// Recalculate the price
	For Each CurRow In Object.SideAndIntermediateRelease Do
		CurRow.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(CurRow.Price,
			StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
	EndDo;

	For Each CurRow In Object.ManufacturedProducts Do
		CurRow.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(CurRow.Price,
			StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
	EndDo;
	
	// Recalculate the amount
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.SideAndIntermediateRelease, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProducts, StructureOfActions, CachedValues);
	
EndProcedure

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
	
	If TSName = "ManufacturedProducts" 
		Or TSName = "SideAndIntermediateRelease" 
		Or TSName = "SupplyWithMaterialsAndWorks" 
		Or TSName = "LaborCosts" 
		Or TSName = "UnusedMaterials" Then
		NewRow.RowCode = 0;
	EndIf;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease"
		Or TSName = "SupplyWithMaterialsAndWorks" Then
		NewRow.KeyProducts = Undefined;
	EndIf;
	
	If TSName = "LaborCosts" Then
		NewRow.KeyWorkType = Undefined;
	EndIf;
	
	CurrentData = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	If TSName = "ManufacturedProducts" 
		Or TSName = "SideAndIntermediateRelease" 
		Or TSName = "SupplyWithMaterialsAndWorks"
		Or TSName = "UnusedMaterials"
		Or TSName = "MaterialsAndWorksConsumption" Then
		
		StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
		
		If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
			StructureOfActions.Insert("RecalculateAmount");
		EndIf;
		If TSName = "SideAndIntermediateRelease" Then
			InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
		EndIf;
		
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		ProvisionInDocumentsClientServer.AddCollateralActions(
			StructureOfActions,
			"UpdateProductCache_",
			DocumentParametersForSoftwareActions(ThisObject));
			
		ProcessSplitOfStringIncludedInSet(NewRow);
		
	EndIf;
	BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
	
	If TSName = "ManufacturedProducts" Then
		ProductionClientServer.RecalculateFractionOfCostWhenSplittingRow(NewRow, CurrentData, CostAllocationParameters.MethodOfAllocatingFinishedProductCosts);
	EndIf;
	
	RowsArray = New Array;
	RowsArray.Add(CurrentData.GetID());
	RowsArray.Add(NewRow.GetID());
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsArray, StructureOfActions);

EndProcedure

&AtServer
Procedure DivisionWhenChangedOnServer()
	
	If Not Object.Department.IsEmpty() Then
		
		CompositionOfTS = New Array;
		CompositionOfTS.Add("ManufacturedProducts");
		CompositionOfTS.Add("BatchFinishedProducts");
		CompositionOfTS.Add("SideAndIntermediateRelease");
		CompositionOfTS.Add("BatchSideAndIntermediateRelease");
		CompositionOfTS.Add("SupplyWithMaterialsAndWorks");
		CompositionOfTS.Add("MaterialsAndWorksConsumption");
		CompositionOfTS.Add("UnusedMaterials");
		CompositionOfTS.Add("SavingMaterialsBatch");
		CompositionOfTS.Add("LaborCosts");
		
		For Each TSName In CompositionOfTS Do
			For Each String In Object[TSName] Do
				String.Department = Object.Department;
			EndDo;
		EndDo;
		
	EndIf;
	
	FillInStatusesForSpecifyingSeriesServer(, True);
	FillInDetailsForDivision(False);
	ConfigureDependentFormElements(ThisObject, "Department");

EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingProducts(TSName, Form, StructureOfActions, SelectionProcessing = False)
	
	Object = Form.Object;
	
	If Not StructureOfActions.Property("CheckSeriesCalculateStatus")
		And (TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Or TSName = "UnusedMaterials") Then
		
		SeriesVerificationParameters = New Structure("SeriesSpecificationParameters", Form.SeriesSpecificationParameters[TSName]);
		StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
		
	EndIf;
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Or TSName = "UnusedMaterials" Then
		IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(StructureOfActions, Form, "Object." + TSName);
	EndIf;
	
	
	If TSName = "SideAndIntermediateRelease" Then
		InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(Form, StructureOfActions);
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		StructureOfActions.Insert("CheckFillInCostShare", Form.CostAllocationParameters);
	EndIf;
	
	If (TSName = "ManufacturedProducts" And Form.UseTargetCost)
		Or TSName = "SideAndIntermediateRelease" Then
		StructureOfActions.Insert("CheckFillIssuePrice", ParametersForFillingIssuePrices(Form));
		StructureOfActions.Insert("RecalculateAmount");
	EndIf;
	
	AdditionalParameters = Undefined;
	
	If TSName = "SupplyWithMaterialsAndWorks" Then
		
		AdditionalParameters = New Structure;
		If SelectionProcessing Then
			AdditionalParameters.Insert("FillInSeparately", False);
			AdditionalParameters.Insert("FillInOnlyEmpty", True);
		EndIf;
		If Form.RecordOfPerformed Then
			AdditionalParameters.Insert("SupplyOption",
				PredefinedValue("Enum.SupplyOptions.Ship"));
			AdditionalParameters.Insert("WarehouseOnlyHasItsOwnShopFloorStockroom", True);
		EndIf;
		
		StructureOfActions.Insert("FillInPurposeOfProvisionInProductionPhase", Form.ParametersForFillingAssignments);
		
	EndIf;
	
	ProductionManagementClientServer.AddActionsToStructureWhenChangingProducts(
			TSName, 
			Form,
			Object,
			StructureOfActions,
			AdditionalParameters);
	
	ProductionManagementClientServer.AddQualityControlActionsToStructure(
		TSName,
		StructureOfActions,
		Form.CacheQualityControl);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl)
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInActionStructuresForBarcodeProcessing(TSName, Form, StructureOfActionsWithAddedStrings, StructureOfActionsWithModifiedStrings)
	
	// Actions for new lines
	AddActionsToStructureWhenChangingProducts(TSName, Form, StructureOfActionsWithAddedStrings);
	AddActionsToStructureWhenChangingPackagesNumber(TSName, Form, StructureOfActionsWithAddedStrings);
	AddQualityControlActionsToStructure(TSName, StructureOfActionsWithAddedStrings, Form.CacheQualityControl);
	
	// Actions for modified rows
	AddActionsToStructureWhenChangingPackagesNumber(TSName, Form, StructureOfActionsWithModifiedStrings);
	
EndProcedure

&AtClientAtServerNoContext
Function ThisIsAProductionIssueStage(Form)
	
	Return ProductionManagementClientServer.ThisIsAProductionIssueStage(Form.Object);

EndFunction

&AtClientAtServerNoContext
Function GeneratedStatus()
	
	Return PredefinedValue("Enum.StatusesOfProductionStages2_2.Generated1");
	
EndFunction

&AtClientAtServerNoContext
Function StatusPending()
	
	Return PredefinedValue("Enum.StatusesOfProductionStages2_2.ForCompletion");

EndFunction

&AtClientAtServerNoContext
Function StatusStarted()
	
	Return PredefinedValue("Enum.StatusesOfProductionStages2_2.Initiated");

EndFunction

&AtClientAtServerNoContext
Function StatusCompleted_1()
	
	Return PredefinedValue("Enum.StatusesOfProductionStages2_2.Completed");

EndFunction

&AtServer
Procedure FillInWHDate(Val TSName, Val DateField_, Val NewDate)
	
	For Each RowData In Object[TSName] Do
		
		RowData[DateField_] = NewDate;
		
	EndDo;
	
	StructureOfActions = New Structure;
	AddQualityControlActionsToStructure(TSName, StructureOfActions, CacheQualityControl);
	If ValueIsFilled(StructureOfActions) Then
		BatchProcessingOfTablePartServer.TreatTS(Object[TSName], StructureOfActions);
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeWHDate(Val TSName, Val DateField_, Val NewDate, Val OldDate = Undefined, Val OnlyChecked = False, Val MarkField = Undefined)

	If NewDate = '000101010000' Then
		Return;
	EndIf;
	
	For Each RowData In Object[TSName] Do
		
		If OnlyChecked And Not RowData[MarkField]
			Or OldDate <> Undefined And OldDate <> RowData[DateField_] Then
			Continue;
		EndIf;
		
		RowData[DateField_] = NewDate;
		
	EndDo;

EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure


&AtServer
Function FillInDataWhenStatusChanges()
	
	Return ProductionManagement.FillInDataWhenStatusChanges(
		Object, PlannedDateOfReceipt);
	
EndFunction

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

&AtClientAtServerNoContext
Procedure SetPropertiesOfCollapsibleGroup(GroupItem1, PictureGroup, GroupCollapsed)

	GroupItem1.Visible = Not GroupCollapsed;
	
	If GroupCollapsed Then
		PictureGroup.Picture = PictureLib.RightArrow;
	Else
		PictureGroup.Picture = PictureLib.DownArrow;
	EndIf; 

EndProcedure

&AtServerNoContext
Procedure AddToListOfChangedBankingDetails(ChangedBankingDetails, Attributes)
	
	ChangedBankingDetails = ChangedBankingDetails + ?(IsBlankString(Attributes),"", ",") + Attributes;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfInputCommandsBasedOn_()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure InformationOnOperationsOnServer()
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillInAccordingToOperations();
	ValueToFormAttribute(DocumentObject, "Object");
	
	RecalculateNumberOfUnitsInHeader();
	FillInServiceDetails();
	FillInServiceDetailsOfTableParts();
	UpdateColumnAvailableServer();
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure AdjustOrderLines(StructureOfAdditionalParameters)
	
	DocumentObject = FormAttributeToValue("Object");
	
	StructureOfAdditionalParameters.CheckBalance =
		DocumentObject.Status <> Enums.StatusesOfProductionStages2_2.BeingGenerated;
	
	ValueToFormAttribute(DocumentObject, "Object");
	
	If StructureOfAdditionalParameters.CloseOrders Then
		Object.Status = Enums.StatusesOfProductionStages2_2.Completed;
		ProcessStatusChangeOnServer();
	EndIf;
	
	FillInServiceDetailsOfTableParts();
	UpdateColumnAvailableServer();
	
	Modified = True;
	
EndProcedure

&AtClientAtServerNoContext
Function StartOfDayCurSessionDate()
	
	#If Server Then
	Return BegOfDay(CurrentSessionDate());
	#Else
	Return BegOfDay(CommonClient.SessionDate());
	#EndIf
	
EndFunction

&AtClient
Procedure TypesOfWorkCentersRecalculateLoad(CurrentData)
	
	If Not CurrentData.ParallelLoad Then
		Return;
	EndIf;
	
	If NumberOfStandardCalculationTypesOfRC <> 0 Then
		CurrentData.Load = CountPlan / NumberOfStandardCalculationTypesOfRC * CurrentData.LoadStandard;
	Else
		CurrentData.Load = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure TypesOfWorkCentersRecalculateWorkingHours(CurrentData)
	
	If CurrentData.ParallelLoad Then
		
		NumberOfDownloadCycles = 1;
		If CurrentData.MaximumLoad <> 0 Then
			NumberOfDownloadCycles = Int(CurrentData.Load / CurrentData.MaximumLoad)
				+ ?(CurrentData.Load % CurrentData.MaximumLoad > 0, 1, 0);
		ElsIf NumberOfStandardCalculationTypesOfRC <> 0 Then
			NumberOfDownloadCycles = Int(CountPlan / NumberOfStandardCalculationTypesOfRC)
				+ ?(CountPlan % NumberOfStandardCalculationTypesOfRC > 0, 1, 0);
		EndIf;
		
		CurrentData.OperationTime = CurrentData.OperationTimeStandard * NumberOfDownloadCycles;
		
	ElsIf NumberOfStandardCalculationTypesOfRC <> 0 Then
		
		If SimultaneouslyManufacturedQuantity > 1 Then
			NumberOfClockCycles = Int(CountPlan / NumberOfStandardCalculationTypesOfRC)
				+ ?(CountPlan % NumberOfStandardCalculationTypesOfRC > 0, 1, 0);
			
			CurrentData.OperationTime = CurrentData.OperationTimeStandard * NumberOfClockCycles;
		Else
			CurrentData.OperationTime = CountPlan / NumberOfStandardCalculationTypesOfRC * CurrentData.OperationTimeStandard;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function FormattedStringPlanNotEarlier(PlanNotEarlierThan, ScheduleDateFormat)
	
	RowsArray = New Array;
	
	If Not ValueIsFilled(PlanNotEarlierThan) Then
		
		RowsArray.Add(
			New FormattedString(NStr("vi = '<chỉ định>';
									|ru = '<указать>';
									|en = '<specify>'; fa = '<specify>';
									|it = '<indicare>';
									|pl = '<specify>';
									|tr = '<belirt>'"),,,,"#EditValue"));
		
	Else
		
		If TypeOf(PlanNotEarlierThan) = Type("DocumentRef.ProductionStage2_2") Then
		
			Presentation = Documents.ProductionStage2_2.PresentationStage(PlanNotEarlierThan);
			
			RowsArray.Add(
				New FormattedString(Presentation,,,,"#OpenStageToPlanNoEarlier"));
		
		Else
		
			RowsArray.Add(Format(PlanNotEarlierThan, ScheduleDateFormat));
			
		EndIf;
		
		RowsArray.Add("  ");
		RowsArray.Add(
			New FormattedString(NStr("vi = 'thay đổi';
									|ru = 'изменить';
									|en = 'change'; fa = 'change';
									|it = 'modificare';
									|pl = 'change';
									|tr = 'değiştir'"),,,,"#EditValue"));
		
	EndIf;
	
	Return New FormattedString(RowsArray);
	
EndFunction

&AtClientAtServerNoContext
Function ParametersForFillingIssuePrices(Form)
	
	FillParameters = ProductionManagementClientServer.ParametersForFillingIssuePrices(
		Form.Object.PriceKind,
		Form.Object.Currency,
		Form.Object.ActualStageStart);
	
	Return FillParameters;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(TSName, Form, StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	If TSName = "SideAndIntermediateRelease"
		Or (TSName = "ManufacturedProducts" And Form.UseTargetCost) Then
		StructureOfActions.Insert("RecalculateAmount");
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		StructureOfActions.Insert("RecalculateCostShare", Form.CostAllocationParameters);
	EndIf;

EndProcedure

&AtServer
Procedure WhenChangingMethodOfDistributionOfCostsForOutputProducts()
	
	CostAllocationParametersStructure = Documents.ProductionStage2_2.CostAllocationParameters(Object);
	CostAllocationParameters = New FixedStructure(CostAllocationParametersStructure);
	
	ProductionServer.CalculateFractionOfCost(Object, CostAllocationParameters);
	CalculatePercentageOfCostAllocationForOutputProducts();
	
EndProcedure

&AtClient
Procedure OpenCostShareEntryForm(CurrentData)

	NoErrors_ = ProductionClient.CheckFillingBeforeEnteringCostFraction(CurrentData, CostAllocationParameters);
	
	If NoErrors_ Then
		FormParameters = ParametersOfCostShareEntryForm_(CurrentData.GetID());
		OpenForm("CommonForm.EnterCostShare",
			FormParameters,
			ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingInputOfFractionOfCost(CurrentData, ValueSelected)
	
	If CurrentData.CostShare <> ValueSelected.CostShare Then
		
		ProductionClientServer.FillInCostFractionInLine(
			CurrentData,
			ValueSelected);
		
		CalculatePercentageOfCostAllocationForOutputProducts();
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ConsumerStageBeginningOfChoice(CurrentData, TSName)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RowID", Items[TSName]["CurrentRow"]);
	AdditionalParameters.Insert("TSName", TSName);
	CallbackDescription = New CallbackDescription("ConsumerStageBeginningOfChoiceCompletion", ThisObject, AdditionalParameters);
	
	ProductionManagementClient.OpenConsumerStageSelectionForm(
		Object,
		CurrentData,
		ThisObject,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure ConsumerStageBeginningOfChoiceCompletion(Result, Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	String = Object[Var_Parameters.TSName].FindByID(Var_Parameters.RowID);
	String.StageConsumer = Result;
	
	Modified = True;
	
EndProcedure

&AtServerNoContext
Function ProductData_4()
	
	Return Catalogs.BillsOfMaterials.ProductData_5();
	
EndFunction

&AtServer
Procedure RecalculateNumberOfUnitsInHeader(Suffix = "")
	
	If Suffix = "Plan" Then
		PropsNameQuantity         = "CountPlan";
		PropsNameNumberOfPackages = "NumberOfPackagesPlan";
		PropsNamePackaging           = "PackagePlan";
	ElsIf Suffix = "Real" Then
		PropsNameQuantity         = "CountReal";
		PropsNameNumberOfPackages = "NumberOfPackagesReal";
		PropsNamePackaging           = "PackageActualData";
	ElsIf Suffix = "Canceled" Then
		PropsNameQuantity         = "CountCanceled";
		PropsNameNumberOfPackages = "NumberOfPackagesCanceled";
		PropsNamePackaging           = "PackageCanceled";
	Else
		PropsNameQuantity         = "Count";
		PropsNameNumberOfPackages = "NumberOfPackages";
		PropsNamePackaging           = "Package";
	EndIf;
	
	Products = ProductionBatchData.MainProductProducts;
	
	If IsBlankString(Suffix) Then
		
		CoefficientPlan = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor
			(Object.PackagePlan, Products);
		CoefficientFact = ?(Object.PackageActualData = Object.PackagePlan, CoefficientPlan,
			Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(
				Object.PackageActualData, Products));
		ZoomRatioCanceled = ?(Object.PackageCanceled = Object.PackagePlan, CoefficientPlan,
			Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(
				Object.PackageCanceled, Products));
		
		CountPlan = Object.NumberOfPackagesPlan * CoefficientPlan;
		CountReal = Object.NumberOfPackagesReal * CoefficientFact;
		CountCanceled = Object.NumberOfPackagesCanceled * ZoomRatioCanceled;
		
	Else
		
		ThisObject[PropsNameQuantity] = Object[PropsNameNumberOfPackages]
			* Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Object[PropsNamePackaging], Products);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure NumberOfPackagesPlanWhenChangedOnServer()
	
	RecalculateNumberOfUnitsInHeader("Plan");
	ConfigureDependentFormElements(ThisObject, "NumberOfPackagesPlan");
	
	StorageAddressStandards = "";
	FillInStandards("SupplyWithMaterialsAndWorks");
	FillInStandards("LaborCosts");
	
	LabelSpecification = FormattedStringLabelSpecification();
	
EndProcedure

&AtServer
Procedure NumberOfPackagesChangedWhenChangedOnServer()
	
	RecalculateNumberOfUnitsInHeader("Real");
	WhenChangingAmountInHeader("NumberOfPackagesReal");
	
EndProcedure

&AtServer
Procedure NumberOfPackagesCancelledWhenChangedOnServer()
	
	RecalculateNumberOfUnitsInHeader("Canceled");
	WhenChangingAmountInHeader("NumberOfPackagesCanceled");
	
EndProcedure

&AtServer
Procedure PackingPlanWhenChangedOnServer()
	
	RecalculateNumberOfUnitsInHeader("Plan");
	ConfigureDependentFormElements(ThisObject, "PackagePlan");
	
	StorageAddressStandards = "";
	FillInStandards("SupplyWithMaterialsAndWorks");
	FillInStandards("LaborCosts");
	
	LabelSpecification = FormattedStringLabelSpecification();
	
EndProcedure

&AtServer
Procedure PackingFactWhenChangingOnServer()
	
	RecalculateNumberOfUnitsInHeader("Real");
	WhenChangingAmountInHeader("PackageActualData");
	
EndProcedure

&AtServer
Procedure PackagingUndoneWhenModifiedOnServer()
	
	RecalculateNumberOfUnitsInHeader("Canceled");
	WhenChangingAmountInHeader("PackageCanceled");
	
EndProcedure

&AtServer
Procedure WhenChangingAmountInHeader(ChangedBankingDetails)
	
	If CountReal >= CountPlan And CountCanceled = 0 Then
	
		StageIsCompleted = True;
		ProcessStageCompletion(ChangedBankingDetails);
		
	ElsIf CountReal > 0 And Not StageExecutionIsStarted Then
		
		StageExecutionIsStarted = True;
		ProcessStartOfStageExecution(ChangedBankingDetails);
		
	ElsIf StageIsCompleted And CountPlan > CountReal + CountCanceled Then
		
		StageIsCompleted = False;
		ProcessStageCompletion(ChangedBankingDetails);
		
	Else
		
		ConfigureDependentFormElements(ThisObject, ChangedBankingDetails);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordDefectiveGoods()
	
	UnlockFormDataForEdit();
	
	FormParameters = New Structure;
	FormParameters.Insert("ProductionLot", Object.ProductionLot);
	FormParameters.Insert("Stage", Object.Ref);
	FormParameters.Insert("RecordDefectiveGoods", True);
	
	OpenForm(
		"DataProcessor.ProductionLotDivision.Form.Workplace",
		FormParameters,
		ThisObject,
		Object.ProductionLot);
	
EndProcedure

&AtClient
Procedure CancelProduction()
	
	UnlockFormDataForEdit();
	
	FormParameters = New Structure;
	FormParameters.Insert("ProductionLot", Object.ProductionLot);
	FormParameters.Insert("Stage", Object.Ref);
	FormParameters.Insert("Cancel", True);
	
	OpenForm(
		"DataProcessor.ProductionLotDivision.Form.Workplace",
		FormParameters,
		ThisObject,
		Object.ProductionLot);
	
EndProcedure

&AtClient
Procedure ReduceIncreaseProduction_()
	
	FormParameters = New Structure;
	FormParameters.Insert("ProductionLot", Object.ProductionLot);
	FormParameters.Insert("Stage", Object.Ref);
	FormParameters.Insert("ReduceIncrease", True);
	
	If Object.Stage.IsEmpty() Then
		
		If CountReal > CountPlan Then
		
			// Increase
			FormParameters.Insert("NumberOfPackages", Object.NumberOfPackagesReal);
			FormParameters.Insert("Package", Object.PackageActualData);
		
		Else
			
			// Reduce
			If Object.PackagePlan = Object.PackageCanceled Then
				FormParameters.Insert("NumberOfPackages",
					Object.NumberOfPackagesPlan - Object.NumberOfPackagesCanceled);
				FormParameters.Insert("Package", Object.PackagePlan);
			Else
				FormParameters.Insert("NumberOfPackages",
					CountPlan - CountCanceled);
			EndIf;
			
		EndIf;
		
	Else
		
		BatchSize = NumberOfProductsPerBatch(Object.ProductionLot, Object.Stage);
		FormParameters.Insert("NumberOfPackages", BatchSize.NumberOfPackages);
		FormParameters.Insert("Package", BatchSize.Package);
		
	EndIf;
	
	OpenForm(
		"DataProcessor.ProductionLotDivision.Form.Workplace",
		FormParameters,
		ThisObject,
		Object.ProductionLot);
	
EndProcedure

&AtClient
Procedure CreateNewStage()
	
	ClearMessages();
	
	Ref = CreateNewStageOnServer();
	
	ShowValue(, Ref);
	
EndProcedure

&AtClient
Procedure FillInPricesByPriceKind(TSName)
	
	ClearMessages();
	
	If Object.PriceKind.IsEmpty() Then
		
		MessageText = NStr("vi = 'Trường ""Dạng giá"" không được điền';
							|ru = 'Не заполнено поле ""Вид цены""';
							|en = '""Price type"" is not filled in'; fa = '""Price type"" is not filled in';
							|it = 'Il campo ""Tipo prezzo"" non è compilato';
							|pl = 'Nie wypełniono pole ""Rodzaj ceny""';
							|tr = '""Fiyat Türü"" alanı doldurulmadı'");
		CommonClientServer.MessageToUser(MessageText,,"PriceKind","Object");
		
		Return;
	EndIf;
	
	SelectedRows = Items[TSName].SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		
		TemplateText = NStr("vi = 'Không có hàng nào được chọn trong bảng ""%1"". Giá không thể được điền';
							|ru = 'В таблице ""%1"" не выбрано ни одной строки. Цены не могут быть заполнены';
							|en = 'No line is selected in the ""%1"" table. Cannot fill in prices'; fa = 'No line is selected in the ""%1"" table. Cannot fill in prices';
							|it = 'Nella tabella ""%1"" non è stata selezionata nessuna riga. I prezzi non possono essere compilati';
							|pl = 'W tabeli ""%1"" nie wybrano ani jednego wiersza. Ceny nie mogą być wypełnione';
							|tr = '""%1"" tablosunda herhangi bir satır seçilmedi. Fiyatlar doldurulamaz'");
		If TSName = "ManufacturedProducts" Then
			Control = LabelProducts;
		Else
			Control = LabelSideProducts;
		EndIf;
		
		ShowMessageBox( , StrTemplate(TemplateText, Control));
		
		Return;
	EndIf;
	
	IDs = New Array;
	
	For Each String In SelectedRows Do
		IDs.Add(String);
	EndDo;
	
	If IDs.Count() = 0 Then
		
		MessageText = NStr("vi = 'Trong các dòng được tô sáng, không có vị trí có sẵn để điền theo loại giá.';
							|ru = 'В выделенных строках отсутствуют позиции, доступные для заполнения по виду цен.';
							|en = 'There are no items available for population by a price type in the selected lines.'; fa = 'There are no items available for population by a price type in the selected lines.';
							|it = 'Nelle righe selezionate non ci sono voci disponibili per la compilazione per tipo di prezzi.';
							|pl = 'W wybranych wierszach brak pozycji, dostępnych do wypełnienia według cen.';
							|tr = 'Seçilen satırlarda, fiyat türüne göre doldurulabilecek pozisyon bulunmamaktadır.'");
		ShowMessageBox( , MessageText);
		
		Return;
	EndIf;
	
	PricesCalculated = FillInPricesOfSelectedRowsByPriceTypeServer(TSName, Object.PriceKind, IDs);
	SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);

EndProcedure

&AtServer
Procedure FillInPlanningCalculationsAndPricesOnServer(RowsIDs = Undefined, StandardCostEstimate = Undefined)
	
	If RowsIDs = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items.ManufacturedProducts.SelectedRows;
	RowsArray = New Array;
	For Each IdOfSelectedLine In SelectedRows Do
		RowOfProduct = Object.ManufacturedProducts.FindByID(IdOfSelectedLine);
		RowsArray.Add(RowOfProduct);
	EndDo;
	
	FillParameters = Documents.StandardCosting2_2.DescriptionOfPriceFillingParameterInCollection();
	FillParameters.DocumentDate = Object.Date;
	FillParameters.DocumentCurrency = DocumentCurrency;
	FillParameters.StandardCostEstimate = StandardCostEstimate;
	
	Documents.StandardCosting2_2.FillInPricesByCalculationInCollection(
		Object.ManufacturedProducts,
		RowsArray,
		FillParameters);
	
EndProcedure

&AtServer
Function CreateNewStageOnServer()
	
	UnlockFormDataForEdit();
	
	NewRef = Documents.ProductionStage2_2.CreateDocumentForCancelledQuantity(
		Object.Ref,
		Object.NumberOfPackagesCanceled,
		Object.PackageCanceled);
	
	Read();
	
	Return NewRef;
	
EndFunction

&AtClientAtServerNoContext
Function ObjectTableByName(Object, TableName)
	
	If TableName = "ManufacturedProducts" Then
		ObjectTable = Object.ManufacturedProducts;
		
	ElsIf TableName = "BatchFinishedProducts" Then
		ObjectTable = Object.BatchFinishedProducts;
		
	ElsIf TableName = "SideAndIntermediateRelease" Then
		ObjectTable = Object.SideAndIntermediateRelease;
		
	ElsIf TableName = "BatchSideAndIntermediateRelease" Then
		ObjectTable = Object.SideAndIntermediateRelease;

	ElsIf TableName = "SupplyWithMaterialsAndWorks" Then
		ObjectTable = Object.SupplyWithMaterialsAndWorks;

	ElsIf TableName = "MaterialsAndWorksConsumption" Then
		ObjectTable = Object.MaterialsAndWorksConsumption;

	ElsIf TableName = "UnusedMaterials" Then
		ObjectTable = Object.UnusedMaterials;

	ElsIf TableName = "SavingMaterialsBatch" Then
		ObjectTable = Object.SavingMaterialsBatch;

	ElsIf TableName = "LaborCosts" Then
		ObjectTable = Object.LaborCosts;

	ElsIf TableName = "WorkCenterTypes" Then
		ObjectTable = Object.WorkCenterTypes;

	ElsIf TableName = "AlternateWorkCenterTypes" Then
		ObjectTable = Object.AlternateWorkCenterTypes;

	ElsIf TableName = "OccupancyOfWorkCenterTypes" Then
		ObjectTable = Object.OccupancyOfWorkCenterTypes;

	ElsIf TableName = "Successors" Then
		ObjectTable = Object.Successors;

	ElsIf TableName = "InventoryOwnerAttributesProducts" Then
		ObjectTable = Object.InventoryOwnerAttributesProducts;

	ElsIf TableName = "InventoryOwnerAttributesMaterials" Then
		ObjectTable = Object.InventoryOwnerAttributesMaterials;

	Else
		ObjectTable = Undefined;

	EndIf;
	
	Return ObjectTable;
	
EndFunction

&AtServer
Procedure InternalProcessingWhenChangingOnServer()
	
	FillInDetailsForOrganizationOfGiver();
	
	If Object.ProductionByThirdParty
		And Object.InternalSubcontracting Then
		ProductionMethod = ProductionMethodOwn();
		HandleChangingProductionMethodOnServer();
	EndIf;
	
	CheckOwnerOfProducts();
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	If Object.InternalSubcontracting
		And ValueIsFilled(Object.Organization) Then
		
		If Not Object.MaterialProviderCompany = Object.Organization
			And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Object.Organization, Object.MaterialProviderCompany) Then
			
			MessageText = NStr("vi = 'Doanh nghiệp nhận gia công không được phép có quan hệ với doanh nghiệp đặt gia công theo cấu trúc tổ chức.';
								|ru = 'Организация-переработчик не должна быть взаимосвязана с организацией-давальцем по организационной структуре.';
								|en = 'Subcontractor company must not be interrelated to the material provider company by the organizational structure.'; fa = 'Subcontractor company must not be interrelated to the material provider company by the organizational structure.';
								|it = 'Организация-переработчик не должна быть взаимосвязана с организацией-давальцем по организационной структуре.';
								|pl = 'Subcontractor company must not be interrelated to the material provider company by the organizational structure.';
								|tr = 'Fason üretici iş yeri, iş yeri yapısı bakımından tedarikçi iş yeri ile bağlantılı olmamalıdır.'");
			Common.MessageToUser(MessageText,, "Organization", "Object");
			
			Object.Organization = CompanyBeforeChange;
			
			Return;
			
		EndIf;
		
	EndIf;
	
	UpdateOrderForActivity();
	
	FillInSelectionListOfProductOwners(ThisObject);
	
	If Object.InternalSubcontracting Then
		CheckOwnerOfProducts();
	EndIf;
	
	EstablishUseOfPlannedValue();
	ConfigureDependentFormElements(ThisObject, "Organization");
	
	CompanyBeforeChange = Object.Organization;
	
EndProcedure

&AtServer
Procedure CheckOwnerOfProducts()
	
	For Each CurrentData In Object.SideAndIntermediateRelease Do
		
		If Not Object.InternalSubcontracting Then
			CurrentData.ProductOwner = Undefined;
		ElsIf ValueIsFilled(CurrentData.ProductOwner)
			And CurrentData.ProductOwner = CompanyBeforeChange Then
			CurrentData.ProductOwner = Object.Organization;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function ParametersOfReplacementAssistantForm()

	OpeningParameters = New Structure;
	
	Rows = New Array;
	Columns = "LineNumber, Products, Characteristic, ItemVariantsAreUsed, Purpose, SupplyAssignment, WithAssignment, SupplyOption, Warehouse, Department, BillOfMaterials, Count";
	For Each TSRow In Object.SupplyWithMaterialsAndWorks Do
			
		If TSRow.ThereAreSubstituteMaterials
		   And Not TSRow.Canceled
		   And Not TSRow.SupplyOption = Enums.SupplyOptions.Ship Then
		
			Rows.Add(TSRow);
		
		EndIf;
		
	EndDo;
	
	VT = Object.SupplyWithMaterialsAndWorks.Unload(Rows, Columns);
	VT.Columns.Add("Ref", New TypeDescription("DocumentRef.ProductionStage2_2"));
	VT.Columns.Add("Stage", New TypeDescription("DocumentRef.ProductionStage2_2"));
	VT.Columns.Add("StageOfResourceBillOfMaterials", New TypeDescription("CatalogRef.ProductionStages"));
	VT.Columns.Add("LineOfBusiness", New TypeDescription("CatalogRef.LinesOfBusiness"));
	VT.Columns.Add("ProductionOrder", New TypeDescription("DocumentRef.ProductionOrder2_2"));
	VT.Columns.Add("Product", New TypeDescription("CatalogRef.Products"));	
	VT.Columns.Add("ItemVariantOfProduct", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	VT.Columns.Add("LineNumberDocument", Common.TypeDescriptionNumber(5));
	VT.Columns.Add("Shipped", Common.TypeDescriptionNumber(15, 3));
	VT.Columns.Add("Supplied", Common.TypeDescriptionNumber(15, 3));
	VT.Columns.Add("Total", Common.TypeDescriptionNumber(15, 3));
		
	For Each SpecificationRow In VT Do
		
		SpecificationRow.Ref = Object.Ref;
		SpecificationRow.Stage = Object.Ref;
		SpecificationRow.ProductionOrder = ProductionBatchData.ReferenceOrder;
		SpecificationRow.BillOfMaterials = ProductionBatchData.BillOfMaterials;
		SpecificationRow.Product = ProductionBatchData.Products;
		SpecificationRow.ItemVariantOfProduct = ProductionBatchData.Characteristic;
		SpecificationRow.StageOfResourceBillOfMaterials = Object.Stage;
		SpecificationRow.LineOfBusiness = Object.LineOfBusiness;
		SpecificationRow.Purpose = SpecificationRow.SupplyAssignment;
		SpecificationRow.LineNumberDocument = SpecificationRow.LineNumber;
		SpecificationRow.Total = SpecificationRow.Count;
		
		If SpecificationRow.SupplyOption = Enums.SupplyOptions.Ship Then
		
			SpecificationRow.Shipped = SpecificationRow.Count;
			SpecificationRow.Supplied = SpecificationRow.Count;
			
		ElsIf SpecificationRow.SupplyOption = Enums.SupplyOptions.ReserveAsReceived
			  Or SpecificationRow.SupplyOption = Enums.SupplyOptions.FromWarehouse Then
			
			SpecificationRow.Supplied = SpecificationRow.Count;
			
		EndIf;
	
	EndDo;
	
	AdditionalParametersAnaloguesOfMaterials = AlternativeMaterials.AdditionalParameters();
	AdditionalParametersAnaloguesOfMaterials.RowFilter = New Structure("Canceled", CommonClientServer.ValueInArray(False));
		
	SourceType = New TypeDescription("DocumentRef.ProductionStage2_2");
	
	FieldsStructure = AlternativeMaterials.StructureOfTableFieldsToReplaceWithAnalogues();
	FieldsStructure.AdditionalFields.Insert("Ref", SourceType);
	FieldsStructure.DefaultValues.Insert("Ref", Object.Ref);
	FieldsStructure.SpoofFields.Insert("Purpose", "SupplyAssignment");
	
	ProductData_9 = AlternativeMaterials.GetProductData(
		ThisObject, "Object", "SupplyWithMaterialsAndWorks", 1, True, FieldsStructure, AdditionalParametersAnaloguesOfMaterials);
		
	OpeningParameters.Insert("InventoryAllocation", ProductData_9.InventoryAllocation);
	OpeningParameters.Insert("Stage", Object.Ref);
	OpeningParameters.Insert("GoodsTableAddress", PutToTempStorage(VT));
	
	Return OpeningParameters;

EndFunction

&AtClient
Procedure AfterReplacementViaAssistant(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
	
		UpdateDataAfterReplacementViaAssistant(Result);
		
		OpenSupplyForecastOfOrders();
	
	EndIf;

EndProcedure

&AtServer
Procedure UpdateDataAfterReplacementViaAssistant(Address)

	TableOfCompletedReplacements = GetFromTempStorage(Address);
	DeleteFromTempStorage(Address);
	
	ArrayOfCompletedReplacements = TableOfCompletedReplacements.FindRows(New Structure("NumberHasChanged", True));
	HasChanges = ArrayOfCompletedReplacements.Count() > 0;
	
	If Not HasChanges Then
		Return;
	EndIf;
	
	StructureOfModifiedRows = New Structure;
	StructureOfModifiedRows.Insert("IndexesOfModifiedRows", New Array);
	StructureOfModifiedRows.Insert("IndexesOfNewRows", New Array);
	
	EmptyPackaging = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	
	LinesToDelete = New Array;
	
	DataBeforeChange = Object.SupplyWithMaterialsAndWorks.Unload(,"LineNumber, ProductCostElement");
	DataBeforeChange.Indexes.Add("LineNumber");
	SearchForOldData = New Structure("LineNumber");
	
	For Each RowOfReplacementTable In ArrayOfCompletedReplacements Do
	
		If RowOfReplacementTable.ThisIsASubstitute Then
			
			NewRow = Object.SupplyWithMaterialsAndWorks.Add();
			FillPropertyValues(NewRow, RowOfReplacementTable);
			NewRow.NumberOfPackages = NewRow.Count;
			NewRow.WithAssignment = ValueIsFilled(RowOfReplacementTable.Purpose);
			NewRow.SupplyAssignment = NewRow.Purpose;
			StructureOfModifiedRows.IndexesOfNewRows.Add(NewRow.LineNumber - 1);
			
			If RowOfReplacementTable.LineNumberDocument >= 0 Then
			
				SearchForOldData.LineNumber = RowOfReplacementTable.LineNumberDocument;
				ArrayOfOldData = DataBeforeChange.FindRows(SearchForOldData);
				For Each StringOfOldData In ArrayOfOldData Do
					NewRow.ProductCostElement = StringOfOldData.ProductCostElement;
				EndDo;
			
			EndIf;
			
		Else
			
			DocumentLine = Object.SupplyWithMaterialsAndWorks[RowOfReplacementTable.LineNumberDocument - 1];
			DocumentLine.Count = RowOfReplacementTable.Count;
			DocumentLine.NumberOfPackages = RowOfReplacementTable.Count;
			DocumentLine.Package = EmptyPackaging;
			
			If DocumentLine.Count = 0 Then
				LinesToDelete.Add(DocumentLine);
			EndIf;
			
			StructureOfModifiedRows.IndexesOfModifiedRows.Add(RowOfReplacementTable.LineNumberDocument - 1);
		
		EndIf;
	
	EndDo;
	
	Modified = True;
	
	TableName = "SupplyWithMaterialsAndWorks";
	StructureOfActions = New Structure;
	RowsIDs = New Array;
	
	Documents.ProductionStage2_2.AfterReplacementWithAnalogs(
		ThisObject,
		TableName,
		StructureOfModifiedRows,
		StructureOfActions,
		RowsIDs);
	
	AfterChangingTSStringsProgrammaticallyOnServer(TableName, RowsIDs, StructureOfActions);
	
	TMCommonUse.DeleteTableRows(Object.SupplyWithMaterialsAndWorks, LinesToDelete);

EndProcedure

&AtClient
Procedure OpenSupplyForecastOfOrders()

	FormParameters = ProvisionInDocumentsClient.SecurityStatusHyperlinkClick(ThisObject);
	
	If Object.Status = PredefinedValue("Enum.StatusesOfProductionStages2_2.BeingGenerated")
	 Or Object.DynamicStructure Then
		
		FormParameters.AcceptableSecurityOptions = ProvisionInDocumentsClient.AllValidSecurityOptions();
		FormParameters.AcceptableSecurityOptions.Delete(
			PredefinedValue("Enum.SupplyOptions.FromWarehouse"));
		
	EndIf;
	
	If FormParameters.ContextOfUse = "TABLE" Then
		
		FormParameters.AddressOfTheMovementTable = AddressOfMovementTableInRepository();
		
	EndIf;
	
	FormParameters.StageOfDynamicOrderStructure = Object.DynamicStructure;
	
	OpenForm("DataProcessor.OrderSupplyForecast.Form", FormParameters, ThisObject, UUID);

EndProcedure
	
&AtClientAtServerNoContext
Procedure ReflectAnalogsInSupplyForecastHyperlink(Form)
	
	If Form.RightToReadSubstitutes Then
	
		Object = Form.Object;
		Items = Form.Items;
		ThereAreAnalogues = Form.ThereAreAnalogues;
		HintAvailabilityOfAnalogues = NStr("vi = ' (cho phép thay thế sang vật tư tương tự)';
											|ru = ' (доступна замена на аналоги)';
											|en = ' (replacement with substitutes is available)'; fa = ' (replacement with substitutes is available)';
											|it = ' (replacement with substitutes is available)';
											|pl = ' (replacement with substitutes is available)';
											|tr = ' (ikameler ile değiştirmek mümkündür)'");
		
		If Object.DynamicStructure Then
			
			FormItem = Items.StateOfSoftwareDynamicStructure;
			
		Else
			
			HyperlinkProperties = SupplyInDocumentsServerCall.PropertiesOfSoftwareStateHyperlink(
				Form.Modified,
				Object.Ref,
				Form.AvailableRemainingEmbeddingOptions.InternalParameters.ReadyForSupply);
			
			ItemsNames = Form.AvailableRemainingEmbeddingOptions.ItemsNames;
				
			FormItem = Items[ItemsNames[HyperlinkProperties.HyperlinkName]];
		
		EndIf;
		
		HyperlinkHeader = FormItem.Title;
		HyperlinkHeader = StrReplace(HyperlinkHeader, HintAvailabilityOfAnalogues, "");
		
		If ThereAreAnalogues Then
			ArrayOfHintTexts = New Array;
			ArrayOfHintTexts.Add(HyperlinkHeader);
			ArrayOfHintTexts.Add(HintAvailabilityOfAnalogues);
			HyperlinkHeader = StrConcat(ArrayOfHintTexts);
		EndIf;
		
		FormItem.Title = HyperlinkHeader;
	
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureOrderInformation()

	OrderStatus = Common.ObjectAttributeValue(Object.ReferenceOrder, "Status");
	
	If OrderStatus = Enums.ProductionOrderStatuses2_2.Closed Then
		Items.TextInformation.Title = NStr("vi = 'Đơn hàng sản xuất đã được đóng.';
											|ru = 'Заказ на производство закрыт.';
											|en = 'The production order is closed.'; fa = 'The production order is closed.';
											|it = 'The production order is closed.';
											|pl = 'The production order is closed.';
											|tr = 'Üretim emri kapatıldı.'");
		Items.InformationGroup.Visible = True;
	Else	
		Items.TextInformation.Title = "";
		Items.InformationGroup.Visible = False;
	EndIf;

EndProcedure

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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	ElsIf Item.Name = "sh_ShamsiInput_F_PlanNoEarlierThanDate" Then
		PlanNoEarlierThanDateOnChange(Items.PlanNoEarlierThanDate);
	ElsIf Item.Name = "sh_ShamsiInput_DateOfShipment" Then
		DateOfShipmentOnChange(Items.DateOfShipment);
	ElsIf Item.Name = "sh_ShamsiInput_DateOfMaterialWorkConsumption" Then
		DateOfMaterialWorkConsumptionOnChange(Items.DateOfMaterialWorkConsumption);
	ElsIf Item.Name = "sh_ShamsiInput_ProductionDate" Then
		ProductionDateOnChange(Items.ProductionDate);
	ElsIf Item.Name = "sh_ShamsiInput_WorkExecutionDate" Then
		WorkExecutionDateOnChange(Items.WorkExecutionDate);
	ElsIf Item.Name = "sh_ShamsiInput_ActualStageEnd" Then
		ActualStageEndOnChange(Items.ActualStageEnd);
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
