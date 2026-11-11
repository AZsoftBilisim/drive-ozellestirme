
#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		Object.ValidOnDate = CurrentSessionDate();
		OnReadCreateAtServer();
		
	EndIf;
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	StartWaitingForProductionProcessToFill();
	StartWaitingForDashboardUpdate();
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	RecordProductionProcess(Cancel, CurrentObject);
	
	If Cancel Then
		Return;
	EndIf;
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	RecordSpecificationAssignmentParameters(CurrentObject);
	Return; // empty handler
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SavedObjectStatus = CurrentObject.Status;
	
	If ThisIsTechnologicalSet(ThisObject) Then
		ProductionProcessToClean();
	EndIf;
	
	FillInServiceDetails();
	
	CustomizeFormElements();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_BillsOfMaterials");
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	SavedObjectStatus = CurrentObject.Status;
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource <> Undefined 
		And ChoiceSource.FormName = "CommonForm.EnterCostShare" Then
		
		CurrentData = CurrentItem.CurrentData;
		If CurrentData = Undefined Then 
			Return;
		EndIf;
		
		Modified = True;
		ProcessingInputOfFractionOfCost(CurrentItem, CurrentData, ValueSelected);
	ElsIf ChoiceSource <> Undefined 
		And ChoiceSource.FormName = "CommonForm.ConfigureProductAutoSelection" Then
		
		ProcessingSelectionSettingUpAutomaticSelectionOfProducts(ChoiceSource.TSName, ValueSelected);
		
	ElsIf ChoiceSource <> Undefined 
		And ChoiceSource.FormName = "CommonForm.ConfigureFilterByPropertiesAndCalculationUsingFormulas" Then
		
		SelectionProcessingSettingUpSelectionByPropertiesAndCalculationByFormulas(ChoiceSource.TSName, ValueSelected);
		
	ElsIf ChoiceSource <> Undefined
		And (ChoiceSource.FormName = "Catalog.BillsOfMaterials.Form.FormOfMaterialReceiptMethodSelection") Then
		
		CurrentData = CurrentItem.CurrentData;
		If CurrentData = Undefined Then 
			Return;
		EndIf;
		
		Modified = True;
		ProcessingSelectionOfMethodOfObtainingMaterial(CurrentData, ValueSelected);
		
	ElsIf ChoiceSource <> Undefined
		And (ChoiceSource.FormName = "Catalog.BillsOfMaterials.Form.MaterialUsageSetupForm") Then
		
		CurrentData = CurrentItem.CurrentData;
		If CurrentData = Undefined Then 
			Return;
		EndIf;
		
		Modified = True;
		ProcessingSelectionOfMaterialApplicationSetting(CurrentData, ValueSelected);
		
	ElsIf ChoiceSource <> Undefined
		And (ChoiceSource.FormName = "Catalog.ManufacturingOperationClassifier.Form.ListForm") Then
		
		Modified = True;
		ProcessingSelectionOfOperationByClassifier(ValueSelected, Not ChoiceSource.CloseOnChoice);
	ElsIf ChoiceSource <> Undefined
		And (ChoiceSource.FormName = "Catalog.BillsOfMaterials.Form.ProductionProcessElementChoiceForm") Then
		
		Modified = True;
		ProcessingSelectionOfProductionProcessElement(ChoiceSource.TSName, ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "Write_BillsOfMaterials" Then
		
		StartUpdatingDashboardClient();
		
	ElsIf EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommands(ThisObject, AttributeAvailability);
		
	ElsIf EventName = "Write_BusinessStructure" Then
		
		UpdateProductionUnitParameters(Source);
		
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	CheckFillingOfProductionProcess(Cancel);
	CheckFillingOfSpecificationAssignmentParameters(Cancel);
	CurrentObject = FormAttributeToValue("Object");
		
	If StatusCheckModeIsValid Then
		CurrentObject.Status = Enums.BOMStatuses.Valid;
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, CurrentObject);
	// End StandardSubsystems.Properties
	
	CurrentObject.InstallInteractiveVerificationPassed();
	CurrentObject.AdditionalProperties.Insert("DescriptionManufacturingProcess", DescriptionManufacturingProcess());
	CurrentObject.AdditionalProperties.Insert("ThisIsTechnologicalSet", ThisIsTechnologicalSet(ThisObject));
	
	If Not CurrentObject.CheckFilling() Then
		Cancel = True;
	EndIf;
	
	CheckedAttributes.Delete(CheckedAttributes.Find("Object"));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region MainProductSpecifications

&AtClient
Procedure AssignmentOptionOnChange(Item)
	DestinationOptionWhenChangedOnServer();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MainProductProductKindOnChange(Item)
	MainProductProductTypeWhenChangedOnServer();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MainProductProductsOnChange(Item)
	MainProductProductsWhenChangedOnServer(CachedValues);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MainProductCharacteristicOnChange(Item)
	MainProductCharacteristicWhenChangingOnServer();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MainProductNumberOfPackagesOnChange(Item)
	MainProductPackagingNumberOfPackagesWhenChangedOnServer(CachedValues);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MainProductPackageOnChange(Item)
	MainProductPackagingNumberOfPackagesWhenChangedOnServer(CachedValues);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MainProductPackageStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Not (Object.AssignmentOption = PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.ProductKind")) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription(
		"MainProductPackageStartChoiceCompletion",
		ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("PackagingUnitOfMeasure", MainProductPackage);
	
	OpenForm(
		"Catalog.BillsOfMaterials.Form.SelectUnitOfMeasureOrPackage",
		FormParameters,
		ThisObject,,,,
		CallbackDescription);
		
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MainProductPackageAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Not (Object.AssignmentOption = PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.ProductKind")) Then
		Return;
	EndIf;
	
	MainProductPackagingAutoSelectionOnServer(Text, ChoiceData);
	
	StandardProcessing = False;
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MainProductShareOfNonconformityOnChange(Item)
	
	ProcessChangeOfMainProductData(ThisObject);
	
EndProcedure

&AtClient
Procedure RepairedFinishedProductDestinationOptionOnChange(Item)
	ProcessChangeInDataOfFINISHEDProductBeingRepaired();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ItemKindOfProductUnderRMOnChange(Item)
	ProcessChangeInDataOfFINISHEDProductBeingRepaired();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure UnderRepairProductOnChange(Item)
	ProcessChangeInDataOfFINISHEDProductBeingRepaired();
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region ManufacturingProcessStructure

&AtClient
Procedure DescriptionOfTheReleaseBatchWhenChanging(Item)
	
	If Object.ProductionIssueByCustomPortions <> ReleaseInCustomPortionsBeforeChange Then
		
		AttributesList = New Array;
		If RequiredToClearPropsWhenChangingReleaseBatchDescription(AttributesList) Then
			
			TemplateText = NStr("vi = 'Khi thay đổi bội số xuất xưởng sẽ xóa các mục tin: %1
				|Tiếp tục?';
				|ru = 'При изменении кратности выпуска будут очищены реквизиты: %1
				|Продолжить?';
				|en = 'If the release multiplier is changed, attributes will be cleared: %1
				|Continue?'; fa = 'If the release multiplier is changed, attributes will be cleared: %1
				|Continue?';
				|it = 'Cambiando la molteplicità dell''output, verranno cancellati i requisiti: %1
				|Continuare?';
				|pl = 'Podczas zmiany krotności wypuszczania produkcji zostaną oczyszczone atrybuty: %1
				|Kontynuować?';
				|tr = 'Ürün çıkışının çarpım faktörü değiştirildiğinde öznitelikler temizlenecektir: %1
				|Devam edilsin mi?'");
			QueryText = StrTemplate(TemplateText, StrConcat(AttributesList, ", "));
			
			CallbackDescription = New CallbackDescription("ClearDetailsWhenChangingReleaseBatchDescription", ThisObject);
			
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
			Return;
			
		EndIf;
		
		FillInReleaseBatchDescription();
		ConfigureDependentFormElements(ThisObject, "ProductionIssueByCustomPortions,MinimumReleaseLot,EconomicReleaseLot");
		ConfigureDependentFormElementsStep(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MinimumReleaseLotOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "MinimumReleaseLot");
	
EndProcedure

&AtClient
Procedure EconomicReleaseLotOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "EconomicReleaseLot");
	
EndProcedure

&AtClient
Procedure ProductQueuePeriodIsLimitedOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "SettingMaximumPeriodOfBedRest");
	
EndProcedure

&AtClient
Procedure ThereIsIntermediateReleaseOnChange(Item)
	If ThereIsIntermediateRelease Then
		If UseGoodsQuality Then
			Object.RecordMethodOfMaterialTransferBetweenStagesLots = PredefinedValue(
				"Enum.RecordMethodsOfMaterialTransferBetweenStagesLots.NonconformingProducts");
		Else
			Object.RecordMethodOfMaterialTransferBetweenStagesLots = PredefinedValue(
				"Enum.RecordMethodsOfMaterialTransferBetweenStagesLots.SetUpManually");
		EndIf;
	Else
		Object.RecordMethodOfMaterialTransferBetweenStagesLots = PredefinedValue(
			"Enum.RecordMethodsOfMaterialTransferBetweenStagesLots.NotUsed");
	EndIf;
	
	Modified = True;
	
	ConfigureDependentFormElements(ThisObject, "RecordMethodOfMaterialTransferBetweenStagesLots");
	ConfigureDependentFormElementsStep(ThisObject, "RecordMethodOfMaterialTransferBetweenStagesLots");
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WayToReflectMaterialTransferBetweenStagesOfNonconformingProductOnChange(Item)
	ConfigureDependentFormElementsStep(ThisObject, "RecordMethodOfMaterialTransferBetweenStagesLots");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MethodOfReflectingMaterialTransferBetweenStagesIsSetUpManuallyOnChange(Item)
	ConfigureDependentFormElementsStep(ThisObject, "RecordMethodOfMaterialTransferBetweenStagesLots");
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region Stages

&AtClient
Procedure StageName_2OnChange(Item)
	
	CurrentData = Items.ManufacturingProcess.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	UpdateObjectAttributeValuesInTree(ThisObject, CurrentData, "Description");
	
	ProductionProcessUpdatePresentation(TypeOfStageElement(), CurrentData.Ref, CurrentData.Description, ThisObject);
	
EndProcedure

&AtClient
Procedure StageDivisionOnChange(Item)
	
	Step3WhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure StageNumberOfTheStageOnChange(Item)
	
	CurrentData = Items.ManufacturingProcess.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	UpdateObjectAttributeValuesInTree(ThisObject, CurrentData, "Number");
	
	ProductionProcessAdjustRowPosition(ThisObject, CurrentData);
	
	ProcessManufacturingProcessChange(CurrentData.GetID());
	
EndProcedure

&AtClient
Procedure StageNumberOfTheNextStageOnChange(Item)
	
	CurrentData = Items.ManufacturingProcess.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	UpdateObjectAttributeValuesInTree(ThisObject, CurrentData, "TheNumberOfTheNextOne");
	
	ProcessManufacturingProcessChange(CurrentData.GetID());
	
EndProcedure

&AtClient
Procedure StageProductionMethodOnChange(Item)
	CurrentData = Items.ManufacturingProcess.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.GetItems().Count() > 0 // there are operations
		And Boolean(StageProductionMethod) Then
			
			QueryText = StrTemplate(NStr("vi = 'Đối với các công đoạn được thực hiện bởi các nguồn lực của người nhận gia công thì không thể sử dụng thao tác. 
								|Các thao tác hiện tại sẽ bị xóa. Tiếp tục?';
								|ru = 'Для этапов, выполняющихся силами переработчика, использование операций недоступно.
								|Существующие операции будут удалены. Продолжить?';
								|en = 'Using operations for stages performed by the subcontractor is not available.
								|Existing operations will be deleted. Continue?'; fa = 'Using operations for stages performed by the subcontractor is not available.
								|Existing operations will be deleted. Continue?';
								|it = 'Le operazioni non sono disponibili per le fasi eseguite dai subfornitore.
								|Le operazioni esistenti verranno eliminate. Continuare?';
								|pl = 'Dla etapów, wykonywanych przez przetwórcę, używanie operacji jest niedostępne.
								|Istniejące operacje zostaną usunięte. Kontynuować?';
								|tr = 'Fason üretici tarafından gerçekleştirilen aşamalar için işlem yapılamaz.
								|Mevcut işlemler silinecektir. Devam edilsin mi?'"));
			CallbackDescription = New CallbackDescription("QuestionMethodOfProductionInCaseOfChange", ThisObject);
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
			Return;
			
	EndIf;
	StageProductionMethodWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure StagePlanTheWorkOfTheTypesOfWorkCentersOnChange(Item)
	ConfigureDependentFormElementsStep(ThisObject, "PlanOperationsOfWorkCenterTypes");
	
	CalculateStageDuration();
	
	ProductionProcessEditorClientServer.FillInExplanationOfBasicSettings(ProductionProcessStage, ThisObject, "Stage");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure StageOperatingProcedureOfTheTypesOfWorkCentersOnChange(Item)
	
	ProductionProcessEditorClient.OperatingProcedureOfWorkCenterTypesOnChange(
		StageTypesOfWorkCenters,
		ProductionProcessStage.OperatingProcedureOfWorkCenterTypes,
		TheStageIsSynchronousLoading,
		True);
	
	CalculateStageDuration();
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure StageAUnitOfMeasurementForTheDurationOfAStageOnChange(Item)
	
	If ProductionProcessStage.UnitOfMeasureOfStageDuration.IsEmpty() Then
		ProductionProcessStage.UnitOfMeasureOfStageDuration = StageTheBasicUnitOfTimeForTheDurationOfAUBBWStage;
	EndIf;
	
EndProcedure

&AtClient
Procedure PreBufferStageOnChange(Item)
	
	SetBlankMarkForBuffers(ThisObject);
	
	CalculateStageDuration();
	
EndProcedure

&AtClient
Procedure StagePreBufferUnitOfMeasurementOnChange(Item)
	
	If ProductionProcessStage.UnitOfMeasureOfPreliminaryBuffer.IsEmpty() Then
		
		ProductionProcessStage.UnitOfMeasureOfPreliminaryBuffer = StageTheBasicUnitOfBufferTime;
		
	EndIf;
	
	CalculateStageDuration();
	
EndProcedure

&AtClient
Procedure TheFinalBufferStageOnChange(Item)
	
	SetBlankMarkForBuffers(ThisObject);
	
	CalculateStageDuration();
	
EndProcedure

&AtClient
Procedure StageTheUnitOfMeasurementOfTheTerminatingBufferOnChange(Item)
	
	If ProductionProcessStage.UnitOfMeasureOfFollowUpBuffer.IsEmpty() Then
		
		ProductionProcessStage.UnitOfMeasureOfFollowUpBuffer = StageTheBasicUnitOfBufferTime;
		
	EndIf;
	
	CalculateStageDuration();
	
EndProcedure

&AtClient
Procedure RouteMapStageOnChange(Item)
	RouteMapWhenChangedOnServer();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure TheSplitRouteSheetsStageOnChange(Item)
	
	ProductionProcessEditorClient.SetMaximumNumberOfProductBatchUnits(
		TheSplitRouteSheetsStage, StageMaximumNumberOfUnitsOfProductBatches);
	
	ConfigureDependentFormElementsStep(ThisObject, "SplitRouteSheets");
	
EndProcedure

&AtClient
Procedure StageAdditionalBankingDetailsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	ProductionProcessEditAdditionalDetails();
	
EndProcedure

#EndRegion

#Region Operations

&AtClient
Procedure OperationName_OnChange(Item)
	OperationNameONChangeOnClient();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationOperationNumberOnChange(Item)
	CurrentData = Items.ManufacturingProcess.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	UpdateObjectAttributeValuesInTree(ThisObject, CurrentData, "Number");
	
	ProductionProcessAdjustRowPosition(ThisObject, CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationName_AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	If Not OperationItemAvailability Then
		Return;
	EndIf;
	
	ProductionProcessEditorClient.OperationOnClassifierAutoSelection(Text, ChoiceData, StandardProcessing, "Description");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationName_ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	
	ProcessingSelectionOfOperationByClassifier(ValueSelected);
	
	Modified = True;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationName_StartChoice(Item, ChoiceData, StandardProcessing)
	CurrentData = Items.ManufacturingProcess.CurrentData;
	If CurrentData = Undefined
		Or Not OperationItemAvailability Then
		Return;
	EndIf;
	
	ProductionProcessEditorClient.OpenFormForSelectingOperationsByClassifier(ThisObject, ProductionProcessOperation);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationNextOperationOnChange(Item)
	CurrentData = Items.ManufacturingProcess.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	UpdateObjectAttributeValuesInTree(ThisObject, CurrentData, "TheNumberOfTheNextOne");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationWorkCenterOnChange(Item)
	CurrentData = Items.ManufacturingProcess.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	UpdateObjectAttributeValuesInTree(ThisObject, CurrentData, "WorkCenter");
	
	OperationWorkCenterWhenChangingOnServer();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationPlotOnChange(Item)
	
	OperationIsPerformedWhenChangesAreMadeOnServer();
	
	Items.ManufacturingProcess.CurrentData.WorkCenter = ProductionProcessOperation.WorkCenter;
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationSetupOptionOnChange(Item)
	OperationAdjustmentOptionForChangesOnServer();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationSetupOptionStartChoice(Item, ChoiceData, StandardProcessing)
	If ValueIsFilled(ProductionProcessOperation.WorkCenter) Then
		
		StandardProcessing = False;
		
		ProductionProcessEditorClient.OpenSetupOptionSelectionForm(
			ProductionProcessOperation.WorkCenter,
			ProductionProcessOperation.SetupSettings,
			Item);
		
	EndIf;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationWHOChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding, StandardProcessing)
	StandardProcessing = False;
	
	ProcessingSelectionOfOperationByClassifier(ValueSelected);
	
	Modified = True;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationTypeOfOperationOnChange(Item)
	OperationTypeOfOperationWhenChangingOnServer();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationQuantityOnChange(Item)
	Items.OperationUnitOfMeasure.InputHint = ProductionManagementClientServer.PresentationOfUnitOfOperation(
		ProductionProcessOperation.UnitOfMeasure, ProductionProcessOperation.Count);
	ProductionProcessEditorClientServer.FillInUnitOfMeasurementOfTransferBatch(
		ProductionProcessOperation, OperationTransferBatchUnitOfMeasurement);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationUnitOfMeasureOnChange(Item)
	ProductionProcessEditorClientServer.FillInUnitOfMeasurementOfTransferBatch(
		ProductionProcessOperation, OperationTransferBatchUnitOfMeasurement);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationOfTheTransferBatchOnChange(Item)
	ProductionProcessEditorClientServer.FillInUnitOfMeasurementOfTransferBatch(
		ProductionProcessOperation, OperationTransferBatchUnitOfMeasurement);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationAdditionalAttributesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	ProductionProcessEditAdditionalDetails();
EndProcedure

#EndRegion

#Region Works

&AtClient
Procedure WorksPerformedItemsOnChange(Item)
	WorksPerformedItemListOnChangeATServer(CachedValues);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WorksPerformedCharacteristicsOnChange(Item)
	WorkPerformedCharacteristicsOnChangeATServer(CachedValues);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WorksPerformedFinishedProductToBeRepairedItemOnChange(Item)
	WorksPerformedFinishedProductToBeRepairedItemONChangeATServer(CachedValues);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WorksPerformedFinishedProductBeingRepairedCharacteristicsOnChange(Item)
	WorksPerformedFinishedProductUnderRepairCharacteristicsOnChangeATServer(CachedValues);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WorkPerformedIsCarriedOutInProcessOnChange(Item)
	TreeRowData = ManufacturingProcess.FindByID(Items.ManufacturingProcess.CurrentRow);
	TheseLinesWork = ProductionProcessElementData(ThisObject, TreeRowData);
	
	If TheseLinesWork = Undefined Then
		Return;
	EndIf;
	
	If Not TheseLinesWork.ProducedInProcess Then
		TheseLinesWork.BillOfMaterials = PredefinedValue("Catalog.BillsOfMaterials.EmptyRef");
	EndIf;
	
	If Not ValueIsFilled(TheseLinesWork.ProductCostElement) Then
		FillInDefaultCostingArticle(TheseLinesWork);
	EndIf;
	
	ConfigureDependentWorkFormElements(ThisObject, "ProducedInProcess");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WorksBeingPerformedBillOfMaterialsOnChange(Item)
	ConfigureDependentWorkFormElements(ThisObject, "ProducedInProcess");
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region AssignmentParameters

// Handler when changing the use of the destination parameter
// 
// Parameters:
// 	Item - FormField - Form element
&AtClient
Procedure Attachable_UsingDestinationParameterWhenChanging(Item)
	
	Id = StrReplace(Item.Name, "_Use", "");
	
	Parameter = AssignmentParameters.FindRows(New Structure("Id", Id))[0];
	
	ConfigureDestinationParameterElements(ThisObject, Parameter);
	
	UpdateHeaderOfDestinationParameterGroup(ThisObject);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure Attachable_ConditionOfDestinationParameterCleanup(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

// Handler for changing the condition of the destination parameter
// 
// Parameters:
// 	Item - FormField - Form element
&AtClient
Procedure Attachable_ConditionOfDestinationParameterWhenChanging(Item)
	
	Id = StrReplace(Item.Name, "_Condition", "");
	
	Parameter = AssignmentParameters.FindRows(New Structure("Id", Id))[0];
	
	Condition = PurposeParametersConditions[ThisObject[Item.Name]];
	
	ValueTypeParameter = AdjustedTypeOfAssignmentParameterByCondition(Parameter.ValueType, Condition);
	
	If Condition.List Then
		
		ThisObject[Parameter.AttributeValue] = New ValueList;
		ThisObject[Parameter.AttributeValue].ValueType = ValueTypeParameter;
		
	Else
		
		ParameterValue = ThisObject[Parameter.AttributeValue];
		If Condition.Interval Or Condition.Fullness Then
			ParameterValue = Undefined;
		EndIf;
		ThisObject[Parameter.AttributeValue] = ValueTypeParameter.AdjustValue(ParameterValue);
		
	EndIf;
	
	If Parameter.IntervalIsAvailable Then
		ThisObject[Parameter.AttributeValue+"1"] = ValueTypeParameter.AdjustValue(Undefined);
		ThisObject[Parameter.AttributeValue+"2"] = ValueTypeParameter.AdjustValue(Undefined);
	EndIf;
	
	UpdateWhetherDestinationParameterMustBeFilledIn(Parameter, Condition, ValueTypeParameter);
	
	ConfigureDestinationParameterElements(ThisObject, Parameter);
	
	Modified = True;
	
EndProcedure

// Handler when changing the value of the destination parameter
// 
// Parameters:
// 	Item - FormField - Form element
&AtClient
Procedure Attachable_ValueOfDestinationParameterWhenChanging(Item)
	
	Id = Mid(Item.Name, 1, StrFind(Item.Name, "_Value")-1);
	
	Parameter = AssignmentParameters.FindRows(New Structure("Id", Id))[0];
	
	Condition = PurposeParametersConditions[ThisObject[Parameter.AttributeCondition]];
	
	If Condition.Interval Then
		ValueTypeParameter = New TypeDescription(CommonClientServer.ValueInArray(TypeOf(ThisObject[Item.Name])));
		For IndexOf = 1 To 2 Do
			ThisObject[Parameter.AttributeValue+IndexOf] = ValueTypeParameter.AdjustValue(ThisObject[Parameter.AttributeValue+IndexOf]);
		EndDo;
	EndIf;
	
	ConfigureDestinationParameterElements(ThisObject, Parameter);
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure MethodOfAllocatingFinishedProductCostsOnChange(Item)
	
	WhenChangingMethodOfDistributionOfCostsForOutputProducts();
	
EndProcedure

&AtClient
Procedure InformationBarURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	If FormattedStringURL = "DisplacingProductSpecifications" Then
		
		OpenDisplacingSpecificationsForm();
		
	EndIf;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure HideInfoBarClick(Item)
	
	Items.InfoBarPages.CurrentPage = Items.InfoBarPageHide;
	
EndProcedure

&AtClient
Procedure MainProductTextHyperlinkClick(Item)
	
	MainProductGroupIsRolledUp = Not MainProductGroupIsRolledUp;
	
	SetPropertiesOfCollapsibleGroup(
		Items.GroupMainProduct,
		Items.MainProductTextHyperlink,
		MainProductGroupIsRolledUp);
	
EndProcedure

&AtClient
Procedure HyperlinkCaptionParametersOfTheProductionProcessClick(Item)
	
	TheProductionProcessParametersGroupIsCollapsed = Not TheProductionProcessParametersGroupIsCollapsed;
	
	SetPropertiesOfCollapsibleGroup(
		Items.ProductionProcessParametersGroup,
		Items.HyperlinkCaptionParametersOfTheProductionProcess,
		TheProductionProcessParametersGroupIsCollapsed);
	
EndProcedure

&AtClient
Procedure PurposeParametersTextHyperlinkClick(Item)
	
	PurposeParametersGroupIsRolledUp = Not PurposeParametersGroupIsRolledUp;
	
	SetPropertiesOfCollapsibleGroup(
		Items.DestinationSettingsGroup,
		Items.PurposeParametersTextHyperlink,
		PurposeParametersGroupIsRolledUp);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersManufacturedProduct

&AtClient
Procedure ManufacturedProductSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessFieldSelectionInTable("ManufacturedProduct", Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductOnActivateRow(Item)
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	SetAvailabilityOfProductLineParameterizationCommands(CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ManufacturedProductBeforeDeleteRow(Item, Cancel)
	ProductDataManagementClient.ClearProductSelectionSettings(
		Items.ManufacturedProduct,
		Items.ManufacturedProduct.SelectedRows,
		Object.PropertyMapping);
		
	ProductDataManagementClient.ClearSelectionSettingsByProperties(
		Items.ManufacturedProduct,
		Items.ManufacturedProduct.SelectedRows,
		Object.SelectionByProperties);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ManufacturedProductOnStartEdit(Item, NewRow, Copy)
	
	TSName = Item.Name;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items[TSName], ThisObject);
	
	If NewRow Then
		
		WhenEnteringNewSpecificationLine(ThisObject, TSName, Items[TSName].CurrentData, Copy);
		
	EndIf;

EndProcedure

&AtClient
Procedure ManufacturedProductOnEditEnd(Item, NewRow, CancelEdit)
	
	If NewRow Then
		
		CalculatePercentageOfCostAllocationForOutputProducts();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductAfterDeleteRow(Item)
	
	CalculatePercentageOfCostAllocationForOutputProducts();
	
	UpdateMainProductSpecificationDataDuringAssembly(ThisObject);
	
EndProcedure

&AtClient
Procedure ManufacturedProductOnChange(Item)
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	CheckClearProductParameterizationSettings();
	
	SetAvailabilityOfProductLineParameterizationCommands(CurrentData);
	
	UpdateMainProductSpecificationDataDuringAssembly(ThisObject);
	
	If ProductionClient.ItIsNecessaryToCalculatePercentageOfDistributionOfCostsForOutputProducts(
			Item, CostAllocationParameters, ProcessingOfTabularFormsClientServer.LineCache(Items.ManufacturedProduct, ThisObject)) Then
		
		CalculatePercentageOfCostAllocationForOutputProducts();
		
	EndIf;
	CheckClearWayToReflectMaterialTransferBetweenStages(ThisObject);
	ConfigureDependentFormElements(ThisObject, "MainProduct,RecordMethodOfMaterialTransferBetweenStagesLots");
	
EndProcedure

&AtClient
Procedure ManufacturedProductProductsOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentRow;
	
	ProductsProductListWhenChangedOnServer(CurrentRow, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductCharacteristicOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentRow;
	
	OutputCharacteristicWhenChangedOnServer(CurrentRow, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentRow;
	
	ProductsPackagingNumberOfPackagesWhenChangedOnServer(CurrentRow, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductPackageOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentRow;
	
	ProductsPackagingNumberOfPackagesWhenChangedOnServer(CurrentRow, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductBatchIndicationRequiredOnChange(Item)
	
	CurrentRow = Items.ManufacturedProduct.CurrentRow;
	ProductsAreRequiredToSpecifySeriesWhenChangingOnServer(CurrentRow);
	
EndProcedure

&AtClient
Procedure ProductsAreElementOfProductionProcessAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Not IsBlankString(Text) Then
		StandardProcessing = False;
		ChoiceData = DataForSelectingElementOfProductionProcess("ManufacturedProduct", Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsAreElementOfProductionProcessChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingSelectionOfProductionProcessElement("ManufacturedProduct", ValueSelected);
	
EndProcedure

&AtClient
Procedure ProductsAreElementOfProductionProcessClearing(Item, StandardProcessing)
	
	ProductionProcessCleanSelectedItem(ThisObject, Items.ManufacturedProduct.CurrentData);
	
EndProcedure

&AtClient
Procedure ProductsAreElementOfProductionProcessOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	ProductionProcessOpenShapeOfElement(Items.ManufacturedProduct.CurrentData);
	
EndProcedure

&AtClient
Procedure ProductsAreElementOfProductionProcessStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	TSName = "ManufacturedProduct";
	ProductionProcessOpenItemSelectionForm(TSName, Items[TSName].CurrentData);
	
EndProcedure

&AtClient
Procedure ProductsAreElementOfProductionProcessTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	TSName = "ManufacturedProduct";
	ProcessingSelectionOfElementOfProductionProcessByPresentation(TSName, Items[TSName].CurrentData, Text, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersManufacturedProducts

&AtClient
Procedure ManufacturedProductsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessFieldSelectionInTable("ManufacturedProducts", Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsOnStartEdit(Item, NewRow, Copy)
	
	TSName = Item.Name;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items[TSName], ThisObject);
	
	If NewRow Then
		
		WhenEnteringNewSpecificationLine(ThisObject, TSName, Items[TSName].CurrentData, Copy);
		
		CalculateNumberOfOutputByProducts(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsProductsOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentData.Package);
	StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInSeriesAttribute", New Structure("Products", "SeriesAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute", New Structure("Products", "ProductKind"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "ManufacturedProducts"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	WhenChangingProductListInOutputProductLine(CurrentData);
	If Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly") Then
		ProductDataManagementClientServer.ClearSpecificationRefinementSettings(Object);
	EndIf;
EndProcedure

&AtClient
Procedure ManufacturedProductsBeforeDeleteRow(Item, Cancel)
	ProductDataManagementClient.ClearProductSelectionSettings(
		Items.ManufacturedProducts,
		Items.ManufacturedProducts.SelectedRows,
		Object.PropertyMapping);
		
	ProductDataManagementClient.ClearSelectionSettingsByProperties(
		Items.ManufacturedProducts,
		Items.ManufacturedProducts.SelectedRows,
		Object.SelectionByProperties);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ManufacturedProductsCharacteristicOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	ProductDataManagementClientServer.WhenChangingCharacteristicInLineWithAutoSelection(CurrentData, Object);
	If Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly") Then
		ProductDataManagementClientServer.ClearSpecificationRefinementSettings(Object, "Characteristic");
	EndIf;
EndProcedure

&AtClient
Procedure ManufacturedProductsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.ManufacturedProducts.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	StructureOfActions.Insert("RecalculateCostShare", CostAllocationParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsPackageOnChange(Item)
	
	CurrentRow = Items.ManufacturedProducts.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	StructureOfActions.Insert("RecalculateCostShare", CostAllocationParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsOnEditEnd(Item, NewRow, CancelEdit)
	
	If ProductionClient.ItIsNecessaryToCalculatePercentageOfDistributionOfCostsForOutputProducts(
			Item, CostAllocationParameters, ProcessingOfTabularFormsClientServer.LineCache(Items.ManufacturedProducts, ThisObject), NewRow) Then
		
		CalculatePercentageOfCostAllocationForOutputProducts();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsAfterDeleteRow(Item)
	
	CalculateNumberOfOutputByProducts(ThisObject);
	
	CalculatePercentageOfCostAllocationForOutputProducts();
	
EndProcedure

&AtClient
Procedure OutputProductsAreElementOfProductionProcessAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Not IsBlankString(Text) Then
		StandardProcessing = False;
		ChoiceData = DataForSelectingElementOfProductionProcess("ManufacturedProducts", Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure OutputProductsAreElementOfProductionProcessChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingSelectionOfProductionProcessElement("ManufacturedProducts", ValueSelected);
	
EndProcedure

&AtClient
Procedure OutputProductsAreElementOfProductionProcessClearing(Item, StandardProcessing)
	
	ProductionProcessCleanSelectedItem(ThisObject, Items.ManufacturedProducts.CurrentData);
	
EndProcedure

&AtClient
Procedure OutputProductsAreElementOfProductionProcessOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	ProductionProcessOpenShapeOfElement(Items.ManufacturedProducts.CurrentData);
	
EndProcedure

&AtClient
Procedure OutputProductsAreElementOfProductionProcessStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	TSName = "ManufacturedProducts";
	ProductionProcessOpenItemSelectionForm(TSName, Items[TSName].CurrentData);
	
EndProcedure

&AtClient
Procedure OutputProductsAreElementOfProductionProcessTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	TSName = "ManufacturedProducts";
	ProcessingSelectionOfElementOfProductionProcessByPresentation(TSName, Items[TSName].CurrentData, Text, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRecyclableWaste

&AtClient
Procedure RecyclableWasteSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessFieldSelectionInTable("RecyclableWaste", Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure RecyclableWasteProductsOnChange(Item)
	
	CurrentData = Items.RecyclableWaste.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentData.Package);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInSeriesAttribute", New Structure("Products", "SeriesAreUsed"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	WhenChangingProductListInOutputProductLine(CurrentData);
	
EndProcedure

&AtClient
Procedure RecyclableWasteCharacteristicOnChange(Item)
	
	CurrentRow = Items.RecyclableWaste.CurrentData;
	
	ProductDataManagementClientServer.WhenChangingCharacteristicInLineWithAutoSelection(CurrentRow, Object);
	
EndProcedure

&AtClient
Procedure RecyclableWasteBeforeDeleteRow(Item, Cancel)
	ProductDataManagementClient.ClearProductSelectionSettings(
		Items.RecyclableWaste,
		Items.RecyclableWaste.SelectedRows,
		Object.PropertyMapping);
		
	ProductDataManagementClient.ClearSelectionSettingsByProperties(
		Items.RecyclableWaste,
		Items.RecyclableWaste.SelectedRows,
		Object.SelectionByProperties);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure RecyclableWasteOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		WhenEnteringNewSpecificationLine(ThisObject, Item.Name, Items[Item.Name].CurrentData, Copy);
		
		CalculateNumberOfOutputByProducts(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecyclableWasteAfterDeleteRow(Item)
	
	CalculateNumberOfOutputByProducts(ThisObject);
	
EndProcedure

&AtClient
Procedure ReturnableWasteIsElementOfProductionProcessAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Not IsBlankString(Text) Then
		StandardProcessing = False;
		ChoiceData = DataForSelectingElementOfProductionProcess("RecyclableWaste", Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnableWasteIsElementOfProductionProcessChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingSelectionOfProductionProcessElement("RecyclableWaste", ValueSelected);
	
EndProcedure

&AtClient
Procedure ReturnableWasteIsElementOfProductionProcessClearing(Item, StandardProcessing)
	
	ProductionProcessCleanSelectedItem(ThisObject, Items.RecyclableWaste.CurrentData);
	
EndProcedure

&AtClient
Procedure ReturnableWasteIsElementOfProductionProcessOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	TSName = "RecyclableWaste";
	ProductionProcessOpenShapeOfElement(Items[TSName].CurrentData);
	
EndProcedure

&AtClient
Procedure ReturnableWasteIsElementOfProductionProcessStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	TSName = "RecyclableWaste";
	ProductionProcessOpenItemSelectionForm(TSName, Items[TSName].CurrentData);
	
EndProcedure

&AtClient
Procedure ReturnableWasteIsElementOfProductionProcessTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	TSName = "RecyclableWaste";
	ProcessingSelectionOfElementOfProductionProcessByPresentation(TSName, Items[TSName].CurrentData, Text, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMaterialsAndServices

&AtClient
Procedure MaterialsAndServicesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "MaterialsAndServicesMethodOfGettingTheMaterialEditing" Then
		
		RowData = Object.MaterialsAndServices.FindByID(RowSelected);
		
		If (RowData.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials")
				And ValueIsFilled(RowData.SourceOfSemiFinishedProduct)
			Or RowData.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage")
				And ValueIsFilled(RowData.BillOfMaterialsRM)
			)Then
			Field.OpenButton = True;
		Else
			
			Field.OpenButton = False;
		EndIf;
		
	EndIf;

	ProcessFieldSelectionInTable("MaterialsAndServices", Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesBeforeDeleteRow(Item, Cancel)
	ProductDataManagementClient.ClearProductSelectionSettings(
				Items.MaterialsAndServices,
				Items.MaterialsAndServices.SelectedRows,
				Object.PropertyMapping);
				
	ProductDataManagementClient.ClearSelectionSettingsByProperties(
				Items.MaterialsAndServices,
				Items.MaterialsAndServices.SelectedRows,
				Object.SelectionByProperties);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		WhenEnteringNewSpecificationLine(ThisObject, Item.Name, Items[Item.Name].CurrentData, Copy);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ProcessingSelectionOfSelectionOnServer(ValueSelected);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesProductsOnChange(Item)
	
	CurrentData = Items.MaterialsAndServices.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentData.Package);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInSeriesAttribute", New Structure("Products", "SeriesAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "MaterialsAndServices"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	WhenChangingProductsInMaterialsLine(CurrentData);

EndProcedure

&AtClient
Procedure MaterialsAndServicesCharacteristicOnChange(Item)
	
	CurrentRow = Items.MaterialsAndServices.CurrentData;
	
	ProductDataManagementClientServer.WhenChangingCharacteristicInLineWithAutoSelection(CurrentRow, Object);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesMethodOfGettingTheMaterialStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.MaterialsAndServices.CurrentData;
	StandardProcessing = False;
	OpenFormForSelectingMaterialReceiptMethod(CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesBatchIndicationRequiredOnChange(Item)
	
	MaterialsAndServicesAreRequiredToSpecifySeriesWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesMethodOfGettingTheMaterialEditingClearing(Item, StandardProcessing)
	
	CurrentData = Items.MaterialsAndServices.CurrentData;
	StandardProcessing = False;
	ProductDataManagementClientServer.FillInDefaultMethodForGettingMaterial(CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesMethodOfGettingTheMaterialEditingOpening(Item, StandardProcessing)
	
	CurrentData = Items.MaterialsAndServices.CurrentData;
	StandardProcessing = False;
	If CurrentData.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials")
			And ValueIsFilled(CurrentData.SourceOfSemiFinishedProduct) Then
		ShowValue(, CurrentData.SourceOfSemiFinishedProduct);
	ElsIf CurrentData.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage")
			And ValueIsFilled(CurrentData.BillOfMaterialsRM) Then
		ShowValue(, CurrentData.BillOfMaterialsRM);
	EndIf;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesApplyingTheMaterialEditingStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.MaterialsAndServices.CurrentData;
	StandardProcessing = False;
	OpenMaterialApplicationSettingsForm(CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesApplyingTheMaterialEditingClearing(Item, StandardProcessing)
	
	CurrentData = Items.MaterialsAndServices.CurrentData;
	StandardProcessing = False;
	
	CurrentData.MaterialApplication = "";
	
	CurrentData.Probability = 0;
	CurrentData.AlternateType = False;
	
	ProductDataManagementClientServer.FillInInformationOnUseOfMaterial(CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesElementOfProductionProcessOnChange(Item)
	
	IDs = New Array;
	IDs.Add(Items.MaterialsAndServices.CurrentRow);
	ProcessStageChangeMaterialsAndServices(IDs);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesElementOfProductionProcessAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Not IsBlankString(Text) Then
		StandardProcessing = False;
		ChoiceData = DataForSelectingElementOfProductionProcess("MaterialsAndServices", Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesElementOfProductionProcessChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingSelectionOfProductionProcessElement("MaterialsAndServices", ValueSelected);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesElementOfProductionProcessClearing(Item, StandardProcessing)
	
	ProductionProcessCleanSelectedItem(ThisObject, Items.MaterialsAndServices.CurrentData);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesElementOfProductionProcessOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	ProductionProcessOpenShapeOfElement(Items.MaterialsAndServices.CurrentData);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesElementOfProductionProcessStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	TSName = "MaterialsAndServices";
	ProductionProcessOpenItemSelectionForm(TSName, Items[TSName].CurrentData);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesElementOfProductionProcessTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	TSName = "MaterialsAndServices";
	ProcessingSelectionOfElementOfProductionProcessByPresentation(TSName, Items[TSName].CurrentData, Text, StandardProcessing);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesToProduceOnChange(Item)
	CurrentData = Items.MaterialsAndServices.CurrentData;
	
	If CurrentData.Produce Then
		CurrentData.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials");
	Else
		CurrentData.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.Provide");
		CurrentData.SourceOfSemiFinishedProduct = PredefinedValue("Catalog.BillsOfMaterials.EmptyRef");
	EndIf;
	
	CurrentData.ProducedInProcess = ProductDataManagementClientServer.SemiFinishedProductProducedInProcess(CurrentData);
	CheckFillOutDefaultCalculationArticle(CurrentData);
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLaborCosts

&AtClient
Procedure LaborCostsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessFieldSelectionInTable("LaborCosts", Field, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LaborCostsBeforeDeleteRow(Item, Cancel)
	ProductDataManagementClient.ClearSelectionSettingsByProperties(
		Items.LaborCosts,
		Items.LaborCosts.SelectedRows,
		Object.SelectionByProperties);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure LaborCostsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		WhenEnteringNewSpecificationLine(ThisObject, Item.Name, Items[Item.Name].CurrentData, Copy);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsAreElementOfProductionProcessStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	TSName = "LaborCosts";
	ProductionProcessOpenItemSelectionForm(TSName, Items[TSName].CurrentData);
	
EndProcedure

&AtClient
Procedure LaborCostsAreElementOfProductionProcessClearing(Item, StandardProcessing)
	
	ProductionProcessCleanSelectedItem(ThisObject, Items.LaborCosts.CurrentData);
	
EndProcedure

&AtClient
Procedure LaborCostsAreElementOfProductionProcessOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	ProductionProcessOpenShapeOfElement(Items.LaborCosts.CurrentData);
	
EndProcedure

&AtClient
Procedure LaborCostsAreElementOfProductionProcessChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	ProcessingSelectionOfProductionProcessElement("LaborCosts", ValueSelected);
	
EndProcedure

&AtClient
Procedure LaborCostsAreElementOfProductionProcessAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Not IsBlankString(Text) Then
		StandardProcessing = False;
		ChoiceData = DataForSelectingElementOfProductionProcess("LaborCosts", Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsAreElementOfProductionProcessTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	TSName = "LaborCosts";
	ProcessingSelectionOfElementOfProductionProcessByPresentation(TSName, Items[TSName].CurrentData, Text, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersManufacturingProcess

&AtClient
Procedure ManufacturingProcessOnActivateRow(Item)
	
	If Items.ManufacturingProcess.CurrentData = Undefined Then
		Items.ProductionProcessPageProperties.CurrentPage = Items.ProductionProcessEmpty;
		Return;
	EndIf;
	
	If ProductionProcessActivationOfElement
		Or Items.ManufacturingProcess.CurrentData.Ref = ProductionProcessCurrentLink Then
		Return;
	EndIf;
	
	AttachIdleHandler("Attachable_ProductionProcessWhenElementIsActivated", 0.1, True);
	
EndProcedure

&AtClient
Procedure ManufacturingProcessBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
	If SavedObjectStatus = CurrentSpecificationStatus Then
		Return;
	EndIf;
	
	CurrentData = Items.ManufacturingProcess.CurrentData;
	
	If Copy Then
		ProductionProcessStartCopyingItem(CurrentData);
	ElsIf CurrentData = Undefined Or CurrentData.ItemKind = TypeOfStageElement() Then
		ProductionProcessStartAddingStage();
	ElsIf CurrentData.ItemKind = TypeOfElementOfOperation() Then
		ProductionProcessStartAddingOperation();
	ElsIf CurrentData.ItemKind = TypeOfWorkElement() Then
		ProductionProcessStartAddingWork();
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturingProcessBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	If SavedObjectStatus = CurrentSpecificationStatus Then
		Return;
	EndIf;
	
	SelectedRows = Items.ManufacturingProcess.SelectedRows;
	
	If CheckPossibilityOfRemovingElementsOfProductionProcess(SelectedRows) Then
		
		ProductionProcessRemoveItems(SelectedRows);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersIntermediateRelease

&AtClient
Procedure IntermediateReleaseOnStartEdit(Item, NewRow, Copy)
	If NewRow Then
		CurrentData = Items.IntermediateRelease.CurrentData;
		CurrentData.StageSender = ProductionProcessCurrentLink;
		CurrentData.ConnectionKey = New UUID;
		IntermediateReleaseNumberOfLines = IntermediateReleaseNumberOfLines + 1;
	EndIf;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure IntermediateReleaseOnEditEnd(Item, NewRow, CancelEdit)
	CurrentData = Items.IntermediateRelease.CurrentData;
	If CurrentData <> Undefined
		And CurrentData.RecipientStage <> CurrentData.StageEditing Then
		CurrentData.RecipientStage = CurrentData.StageEditing;
	EndIf;
	If NewRow And CancelEdit Then
		IntermediateReleaseNumberOfLines = IntermediateReleaseNumberOfLines - 1;
	EndIf;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure IntermediateReleaseBeforeDeleteRow(Item, Cancel)
	IntermediateReleaseNumberOfLines = IntermediateReleaseNumberOfLines - 1;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure IntermediateReleaseSelection(Item, RowSelected, Field, StandardProcessing)
	If Not ReadOnly And AttributeAvailability Then
		Return;
	EndIf;
	
	CurrentData = Items.IntermediateRelease.CurrentData;
	
	If (Field.Name = "IntermediateReleaseProductsSKU"
			Or Field.Name = "IntermediateReleaseProducts")
		And ValueIsFilled(CurrentData.Products)  Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.Products);
		
	ElsIf Field.Name = "IntermediateReleaseCharacteristic"
		And ValueIsFilled(CurrentData.Characteristic)  Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.Characteristic);
		
	EndIf;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure IntermediateReleaseIsElementOfProductionProcessAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	If Not IsBlankString(Text) Then
		StandardProcessing = False;
		ChoiceData = DataForSelectingElementOfProductionProcess("IntermediateRelease", Text);
	EndIf;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure IntermediateReleaseIsElementOfProductionProcessChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	ProcessingSelectionOfProductionProcessElement("IntermediateRelease", ValueSelected);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure IntermediateReleaseIsElementOfProductionProcessClearing(Item, StandardProcessing)
	ProductionProcessCleanSelectedItem(ThisObject, Items.IntermediateRelease.CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure IntermediateReleaseIsElementOfProductionProcessOpening(Item, StandardProcessing)
	StandardProcessing = False;
	ProductionProcessOpenShapeOfElement(Items.IntermediateRelease.CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure IntermediateReleaseIsElementOfProductionProcessStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	TSName = "IntermediateRelease";
	ProductionProcessOpenItemSelectionForm(TSName, Items[TSName].CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure IntermediateReleaseIsElementOfProductionProcessTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	TSName = "IntermediateRelease";
	ProcessingSelectionOfElementOfProductionProcessByPresentation(
		TSName, Items[TSName].CurrentData, Text, StandardProcessing);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure IntermediateIssueItemOnChange(Item)
	CurrentData = Items.IntermediateRelease.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersStageTypesOfWorkCenters

&AtClient
Procedure StageTypesOfWorkCentersBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	CurrentData = Items.StageTypesOfWorkCenters.CurrentData;
	
	ProductionProcessEditorClient.WorkCenterTypesBeforeAddRow(
		CurrentData,
		StageTypesOfWorkCenters,
		Items.StageTypesOfWorkCenters,
		ProductionProcessStage.OperatingProcedureOfWorkCenterTypes,
		TheStageIsSynchronousLoading,
		Cancel,
		ProductionIsUsed22);
	
	ConfigureDependentFormElementsStep(ThisObject, "WorkCenterTypes");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure StageTypesOfWorkCentersOnStartEdit(Item, NewRow, Copy)
	If NewRow Then
		CurrentData = Items.StageTypesOfWorkCenters.CurrentData;
		CurrentData.UnitOfMeasure = PredefinedValue("Enum.TimeMeasureUnits.Minute");
		If Not CurrentData.AlternateType Then
			CurrentData.Use = True;
		EndIf;
	EndIf;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure StageTypesOfWorkCentersOnEditEnd(Item, NewRow, CancelEdit)
	If Not CancelEdit Then
		CalculateStageDuration();
	EndIf;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure StageTypesOfWorkCentersBeforeDeleteRow(Item, Cancel)
	ProductionProcessEditorClient.TypesOfWorkCentersClearSelectionSettingsByProperties(
		Items.StageTypesOfWorkCenters, ProductionProcessStage.SelectionByProperties);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure StageTypesOfWorkCentersAfterDeleteRow(Item)
	
	CollectionOfMainTypesOfRC = StageTypesOfWorkCenters.GetItems();
	
	ProductionProcessEditorClient.TypesOfWorkCentersAndUses(CollectionOfMainTypesOfRC);
	
	WhenChangingCompositionOfTypesOfWorkCenters();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure StageTypesOfWorkCentersSelection(Item, RowSelected, Field, StandardProcessing)
	If Not ReadOnly And AttributeAvailability Then
		Return;
	EndIf;
	
	CurrentData = Items.StageTypesOfWorkCenters.CurrentData;
	
	If (Field.Name = "StageTypesOfWorkCentersWorkCenterType")
		And ValueIsFilled(CurrentData.WorkCenterType)  Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.WorkCenterType);
		
	ElsIf (Field.Name = "StageTypesOfWorkCentersSetupSettings")
		And ValueIsFilled(CurrentData.SetupSettings)  Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.SetupSettings);
		
	EndIf;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure StageTypesOfWorkCentersUseOnChange(Item)
	CurrentData = Items.StageTypesOfWorkCenters.CurrentData;
	
	ProductionProcessEditorClient.WorkCenterTypesUseOnChange(CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure StageTypesOfWorkCentersWorkCenterTypeOnChange(Item)
	StageTypesOfWorkCentersViewOfWorkCenterWhenChangingOnServer();
	TypesOfWorkCentersRecalculateWorkingHours(Items.StageTypesOfWorkCenters.CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure StageTypesOfWorkCentersSetupSettingsOnChange(Item)
	StageTypesOfWorkCentersAdjustmentOptionWhenChangingOnServer();
	TypesOfWorkCentersRecalculateWorkingHours(Items.StageTypesOfWorkCenters.CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure StageTypesOfWorkCentersOperationTimeOnChange(Item)
	TypesOfWorkCentersRecalculateWorkingHours(Items.StageTypesOfWorkCenters.CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure StageTypesOfWorkCentersUnitOfMeasureOnChange(Item)
	TypesOfWorkCentersRecalculateWorkingHours(Items.StageTypesOfWorkCenters.CurrentData);
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersProcessorServiceStage

&AtClient
Procedure StageProcessorServicesProductRangeOnChange(Item)
	
	CurrentData = Items.ProcessorServiceStage.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperationAddAttributes

&AtClient
Procedure OperationAddAttributesSelection(Item, RowSelected, Field, StandardProcessing)
	If Field.Name = "OperationAddAttributesTitle" Then
		
		StandardProcessing = False;
	
		ShowValue(, Items.OperationAddAttributes.CurrentData.Property);
		
	EndIf;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationAddAttributesOnStartEdit(Item, NewRow, Copy)
	ProductionProcessEditorClient.AdditionalDetailsSetFormatForEditingStandards(ThisObject, "Operation");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationAddAttributesValueMinOnChange(Item)
	Modified = True;
	
	CurrentData = Items.OperationAddAttributes.CurrentData;
	
	ProductionProcessEditorClient.AdditionalValueOfStandardWhenChanging(CurrentData, "ValueMin");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationAddAttributesValueMaxOnChange(Item)
	Modified = True;
	
	CurrentData = Items.OperationAddAttributes.CurrentData;
	
	ProductionProcessEditorClient.AdditionalValueOfStandardWhenChanging(CurrentData, "ValueMax");
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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

#Region IsMain

&AtClient
Procedure FormWrite(Command)
	
	WriteSpecification();
	
EndProcedure

&AtClient
Procedure FormWriteAndClose(Command)
	
	If WriteSpecification() Then
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure FormCopy(Command)
	
	RowsArray = New Array;
	RowsArray.Add(NStr("vi = 'Sẽ tạo và ghi bản sao của bảng kê chi tiết nguồn lực.';
						|ru = 'Будет создана и записана копия ресурсной спецификации.';
						|en = 'A BOM copy will be created and saved.'; fa = 'A BOM copy will be created and saved.';
						|it = 'Будет создана и записана копия ресурсной спецификации.';
						|pl = 'A BOM copy will be created and saved.';
						|tr = 'Ürün reçetesinin kopyası oluşturulacak ve kaydedilecektir.'"));
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		RowsArray.Add(NStr("vi = 'Trước khi thực hiện thao tác, sẽ ghi lại bảng kê chi tiết hiện tại.';
							|ru = 'Перед выполнением операции, текущая спецификация будет записана.';
							|en = 'Before executing the operation, the current BOM will be saved.'; fa = 'Before executing the operation, the current BOM will be saved.';
							|it = 'Перед выполнением операции, текущая спецификация будет записана.';
							|pl = 'Before executing the operation, the current BOM will be saved.';
							|tr = 'İşlem gerçekleştirilmeden önce mevcut ürün reçetesi kaydedilecektir.'"));
	EndIf;
	RowsArray.Add(NStr("vi = 'Sao chép?';
						|ru = 'Скопировать?';
						|en = 'Do you want to copy?'; fa = 'Do you want to copy?';
						|it = 'Скопировать?';
						|pl = 'Do you want to copy?';
						|tr = 'Kopyalansın mı?'"));
	
	ShowQueryBox(
		New CallbackDescription("FormCopyCompletion", ThisObject),
		StrConcat(RowsArray, " "),
		QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure OpenProductSpecificationsCommand(Command)
	Products = CheckGetMainProductSpecifications();
	If Products.IsEmpty() Then
		Return;
	EndIf;
	OpenFormApplicationOfProductsInProduction(Products);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure TheCommandFillInTheRouteMapsOfTheStages(Command)
	
	QueryText = NStr("vi = 'Điền bảng kê chi tiết nguồn lực sản xuất theo sơ đồ quy trình công đoạn?';
					|ru = 'Заполнить спецификацию по маршрутным картам этапов?';
					|en = 'Fill in BOM using the route sheets for stages?'; fa = 'Fill in BOM using the route sheets for stages?';
					|it = 'Compilare le specifiche delle schede di lavoraizone delle fasi?';
					|pl = 'Wypełnić specyfikację wg kart technologicznych etapów?';
					|tr = 'Aşamaların rotalarına göre ürün reçetesi doldurulsun mu?'");
	CallbackDescription = New CallbackDescription("FillInUsingOperationsSheetsForStagesCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure TheSetStatusInDevelopmentCommand(Command)
	
	If Not AttributeAvailability Then
		
		CallbackDescription = New CallbackDescription("HandlerSetStatusUnderDevelopment", ThisObject);
		OpenForm("Catalog.BillsOfMaterials.Form.AttributeUnlocking", 
								New Structure("Object", Object.Ref),,,,,
								CallbackDescription,
								FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TheSetStatusCommandIsActive(Command)
	
	SetNewStatusAndRecord(PredefinedValue("Enum.BOMStatuses.Valid"));
	
EndProcedure

&AtClient
Procedure TheSetStatusClosedCommand(Command)
	
	SetNewStatusAndRecord(PredefinedValue("Enum.BOMStatuses.Closed_"));
	
EndProcedure

&AtClient
Procedure CheckFillInCommand(Command)
	
	ClearMessages();
	
	TitleText = NStr("vi = 'Kiểm tra bảng kê chi tiết các nguồn lực sản xuất';
					|ru = 'Проверка спецификации';
					|en = 'Check bill of materials'; fa = 'Check bill of materials';
					|it = 'Verifica della specifica';
					|pl = 'Weryfikacja specyfikacji';
					|tr = 'Ürün reçetesi kontrolü'");
	
	If Object.DeletionMark Then
		WarningText = NStr("vi = 'Bảng kê chi tiết các nguồn lực bị đánh dấu xóa không thể có hiệu lực.';
							|ru = 'Помеченная на удаление спецификация не может быть действующей.';
							|en = 'The bill of materials marked for deletion cannot be valid.'; fa = 'The bill of materials marked for deletion cannot be valid.';
							|it = 'Помеченная на удаление спецификация не может быть действующей.';
							|pl = 'The bill of materials marked for deletion cannot be valid.';
							|tr = 'Silinmek üzere işaretlenen ürün reçetesi geçerli olamaz.'");
		ShowMessageBox(,WarningText,, TitleText);
		Return;
	EndIf;
	
	If CheckFillingCommandWithValidStatus() Then
		WarningText = NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất có thể được thực hiện hiện tại.';
							|ru = 'Спецификацию можно сделать действующей.';
							|en = 'Bill of materials can be made valid.'; fa = 'Bill of materials can be made valid.';
							|it = 'È possibile rendere la specifica attiva.';
							|pl = 'Specyfikacja może być ustawiona jako aktualna.';
							|tr = 'Ürün reçetesi aktif hale getirilebilir.'");
	Else
		WarningText = NStr("vi = 'Bảng kê chi tiết không thể có hiệu lực.
										|Cần điền các mục tin chỉ ra.';
										|ru = 'Спецификация не может быть действующей.
										|Необходимо заполнить указанные реквизиты.';
										|en = 'Bill of materials cannot be valid. 
										|Fill in the specified attributes.'; fa = 'Bill of materials cannot be valid. 
										|Fill in the specified attributes.';
										|it = 'La specifica non può essere attiva.
										|È necessario compilare i requisiti indicati.';
										|pl = 'Specyfikacja nie może być ustawiona jako aktualna.
										|Należy wypełnić wskazane atrybuty.';
										|tr = 'Ürün reçetesi aktif olamaz.
										|Belirtilen öznitelikleri doldurmanız gerekmektedir.'");
	EndIf;
	
	ShowMessageBox(,WarningText,, TitleText);
	
EndProcedure

&AtClient
Procedure CommandToSetTheValidityPeriod(Command)
	
	Dialog = New StandardPeriodEditDialog();
	
	Dialog.Period.StartDate = Object.ValidOnDate;
	Dialog.Period.EndDate = Object.ValidToDate;
	
	Notification = New CallbackDescription(
		"SetValidityPeriodCompletion", 
		ThisObject,
		New Structure());
	
	Dialog.Show(Notification);
	
EndProcedure

&AtClient
Procedure ProductsSetUpItemSelection(Command)
	
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		MessageText = NStr("vi = 'Hàng của bảng ""Sản phẩm"" không được chọn.';
							|ru = 'Не выбрана строка таблицы ""Продукция"".';
							|en = 'Line of the ""Manufactured products"" table is not selected.'; fa = 'Line of the ""Manufactured products"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Produzione"".';
							|pl = 'Nie wybrano wiersza tabeli ""Wiersze pozycji"".';
							|tr = '""İmal Edilen Ürünler"" tablosunun satırı seçilmedi.'");
		CommonClient.MessageToUser(MessageText,, "Object.ManufacturedProducts", "Object");
		
		Return;
	EndIf;
	
	If CurrentData.LineNumber = 1 Then
		Return;
	EndIf;
	
	MainProductSpecifications = CheckGetMainProductSpecifications();
	If MainProductSpecifications.IsEmpty() Then
		Return;
	EndIf;
	
	PropertyMapping = ProductDataManagementClient.DetailsOfSettingsByLineInArray(
		CurrentData,
		Object.PropertyMapping,
		ProductDataManagementClientServer.DetailsSettingUpPropertyMatching());
	
	ProductDataManagementClient.ConfigureProductsAutoselection(
							ThisObject,
							"ManufacturedProduct",
							PropertyMapping, 
							MainProductSpecifications,
							NStr("vi = 'Chỉ ra trong bảng kê chi tiết các nguồn lực sản xuất';
								|ru = 'Указывается в спецификации';
								|en = 'Specified in BOM'; fa = 'Specified in BOM';
								|it = 'Viene indicato nella specifica';
								|pl = 'Wskazuje się w specyfikacji';
								|tr = 'Ürün reçetesinde belirtilmektedir'"),
							Not AttributeAvailability);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ProductsSettingUpSelectionByPropertiesAndCalculationByFormulas(Command)
	CurrentData = Items.ManufacturedProduct.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		
		MessageText = NStr("vi = 'Hàng của bảng ""Sản phẩm"" không được chọn.';
							|ru = 'Не выбрана строка таблицы ""Продукция"".';
							|en = 'Line of the ""Manufactured products"" table is not selected.'; fa = 'Line of the ""Manufactured products"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Produzione"".';
							|pl = 'Nie wybrano wiersza tabeli ""Wiersze pozycji"".';
							|tr = '""İmal Edilen Ürünler"" tablosunun satırı seçilmedi.'");
		CommonClient.MessageToUser(MessageText,, "ManufacturedProduct", "Object");
		
		Return;
	EndIf;
	
	If CurrentData.LineNumber = 1 Then
		Return;
	EndIf;
	
	OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(CurrentData, "ManufacturedProduct");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure UsageClarificationProduct(Command)
	OpenSpecificationRefinementSetting("Products");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure UsageClarificationCharacteristic(Command)
	OpenSpecificationRefinementSetting("Characteristic");
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region Stages

&AtClient
Procedure StageCalculateTheCoefficientOfTheRouteMap(Command)
	ProductionProcessStage.RouteSheetFactor =
		RouteSheetFactor(ProductionProcessStage.RouteSheet);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure StepAddAnAlternativeViewOfTheRC(Command)
	CurrentData = Items.StageTypesOfWorkCenters.CurrentData;
	
	ProductionProcessEditorClient.AddAnAlternativeTypeOfRC(
				CurrentData, 
				StageTypesOfWorkCenters, 
				Items.StageTypesOfWorkCenters,
				ProductionProcessStage.OperatingProcedureOfWorkCenterTypes,
				TheStageIsSynchronousLoading,
				ProductionIsUsed22);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure StageSettingUpSelectionByPropertiesAndCalculationByFormulas(Command)
	CurrentData = Items.StageTypesOfWorkCenters.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		
		MessageText = NStr("vi = 'Chưa chọn dòng của bảng ""Dạng nguồn lực sản xuất"".';
							|ru = 'Не выбрана строка таблицы ""Виды рабочих центров"".';
							|en = 'No line of the ""Work center types"" table is selected.'; fa = 'No line of the ""Work center types"" table is selected.';
							|it = 'Non è selezionata alcuna riga nella tabella ""Tipi di centro di lavoro"".';
							|pl = 'Nie wybrano wiersza tabeli ""Rodzaje centrów wykonania pracy"".';
							|tr = '""İş Merkezi Türleri"" tablosunun satırı seçilmedi.'");
		CommonClient.MessageToUser(MessageText,, "WorkCenterTypes");
		
		Return;
	EndIf;
	
	If CurrentData.ConnectionKey = New UUID("00000000-0000-0000-0000-000000000000") Then
		CurrentData.ConnectionKey = New UUID;
	EndIf;
	
	If CurrentData.SynchronousLoad Or TheStageIsSynchronousLoading Then
		CompositionOfSettings = New Structure("SelectionByProperties");
	Else
		CompositionOfSettings = Undefined;
	EndIf;
	
	OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(
		CurrentData, "StageTypesOfWorkCenters", ProductionProcessStage.SelectionByProperties, CompositionOfSettings);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure StageFillInTypesOfWorkCenters(Command)
	If StoreOperationsInBillsOfMaterials Then
		Step2TypesOfWorkCentersForOperationsOnServer();
	Else
		StageFillInTypesOfWorkCentersOnRouteMapOnServer();
	EndIf;
	
	WhenChangingCompositionOfTypesOfWorkCenters();
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region Operations

&AtClient
Procedure OperationCalculateTheCoefficientOfTheTechnologicalProcess(Command)
	ProductionProcessOperation.TechnologicalProcessFactor =
		TechnologicalProcessFactor(ProductionProcessOperation.TechnologicalProcess);
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region ManufacturedProduct

&AtClient
Procedure ProductsToInsertRows(Command)
	
	GetLinesFromClipboard("ManufacturedProduct", "ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ProductsCopyLines_3(Command)
	
	CopyTSLines("ManufacturedProduct", "ManufacturedProducts");
	
EndProcedure

#EndRegion

#Region ManufacturedProducts

&AtClient
Procedure OutputItemsSetUpItemSelection(Command)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		MessageText = NStr("vi = 'Hàng của bảng ""Sản phẩm đầu ra"" không được chọn.';
							|ru = 'Не выбрана строка таблицы ""Выходные изделия"".';
							|en = 'Line of the ""Finished products"" table is not selected.'; fa = 'Line of the ""Finished products"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Prodotti di output"".';
							|pl = 'Nie wybrano wiersza tabeli ""Wyroby wyjściowe"".';
							|tr = '""Üretilen Nihai Ürünler"" tablosunun satırı seçilmedi.'");
		CommonClient.MessageToUser(MessageText,, "Object.ManufacturedProducts", "Object");
		
		Return;
	EndIf;
	
	If Not CheckFillingOfMainProduct() Then
		Return;
	EndIf;
	
	MainProductSpecifications = CheckGetMainProductSpecifications();
	If MainProductSpecifications.IsEmpty() Then
		Return;
	EndIf;
	
	PropertyMapping = ProductDataManagementClient.DetailsOfSettingsByLineInArray(
		CurrentData,
		Object.PropertyMapping,
		ProductDataManagementClientServer.DetailsSettingUpPropertyMatching());
	
	ProductDataManagementClient.ConfigureProductsAutoselection(
							ThisObject,
							"ManufacturedProducts",
							PropertyMapping, 
							MainProductSpecifications,
							NStr("vi = 'Chỉ ra trong bảng kê chi tiết các nguồn lực sản xuất';
								|ru = 'Указывается в спецификации';
								|en = 'Specified in BOM'; fa = 'Specified in BOM';
								|it = 'Viene indicato nella specifica';
								|pl = 'Wskazuje się w specyfikacji';
								|tr = 'Ürün reçetesinde belirtilmektedir'"),
							Not AttributeAvailability);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OutputItemsSettingUpSelectionByPropertiesAndCalculationByFormulas_5(Command)
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		
		MessageText = NStr("vi = 'Hàng của bảng ""Sản phẩm đầu ra"" không được chọn.';
							|ru = 'Не выбрана строка таблицы ""Выходные изделия"".';
							|en = 'Line of the ""Finished products"" table is not selected.'; fa = 'Line of the ""Finished products"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Prodotti di output"".';
							|pl = 'Nie wybrano wiersza tabeli ""Wyroby wyjściowe"".';
							|tr = '""Üretilen Nihai Ürünler"" tablosunun satırı seçilmedi.'");
		CommonClient.MessageToUser(MessageText,, "Object.ManufacturedProducts", "Object");
		
		Return;
	EndIf;
	
	OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(CurrentData, "ManufacturedProducts");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OutputProducts_FillInStage(Command)
	
	FillStageInLines("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProducts_InsertRows(Command)
	
	GetLinesFromClipboard("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProducts_CopyLines(Command)
	
	CopyTSLines("ManufacturedProducts");
	
EndProcedure

#EndRegion

#Region RecyclableWaste

&AtClient
Procedure ReturnableWasteSetUpItemSelection(Command)
	
	CurrentData = Items.RecyclableWaste.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		MessageText = StrTemplate(
			NStr("vi = 'Chưa chọn dòng của bảng ""%1"".';
				|ru = 'Не выбрана строка таблицы ""%1"".';
				|en = 'The ""%1"" table row is not selected.'; fa = 'The ""%1"" table row is not selected.';
				|it = 'Non è stata selezionata la riga della tabella ""%1"".';
				|pl = 'Nie wybrano wiersza tabeli ""%1"".';
				|tr = '""%1"" tablosunun satırı seçilmedi.'"),
			PresentationOfTabularPartReturnableWaste(ThisObject));
		CommonClient.MessageToUser(MessageText,, "Object.RecyclableWaste", "Object");
		Return;
	EndIf;
	
	MainProductSpecifications = CheckGetMainProductSpecifications();
	If MainProductSpecifications.IsEmpty() Then
		Return;
	EndIf;
	
	PropertyMapping = ProductDataManagementClient.DetailsOfSettingsByLineInArray(
		CurrentData,
		Object.PropertyMapping,
		ProductDataManagementClientServer.DetailsSettingUpPropertyMatching());
	
	ProductDataManagementClient.ConfigureProductsAutoselection(
							ThisObject,
							"RecyclableWaste",
							PropertyMapping, 
							MainProductSpecifications,
							NStr("vi = 'Chỉ ra trong bảng kê chi tiết các nguồn lực sản xuất';
								|ru = 'Указывается в спецификации';
								|en = 'Specified in BOM'; fa = 'Specified in BOM';
								|it = 'Viene indicato nella specifica';
								|pl = 'Wskazuje się w specyfikacji';
								|tr = 'Ürün reçetesinde belirtilmektedir'"),
							Not AttributeAvailability);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure RecyclableWasteConfigureFilterByPropertiesAndCalculationUsingFormulas(Command)
	CurrentData = Items.RecyclableWaste.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		
		MessageText = StrTemplate(
			NStr("vi = 'Chưa chọn dòng của bảng ""%1"".';
				|ru = 'Не выбрана строка таблицы ""%1"".';
				|en = 'The ""%1"" table row is not selected.'; fa = 'The ""%1"" table row is not selected.';
				|it = 'Non è stata selezionata la riga della tabella ""%1"".';
				|pl = 'Nie wybrano wiersza tabeli ""%1"".';
				|tr = '""%1"" tablosunun satırı seçilmedi.'"),
			PresentationOfTabularPartReturnableWaste(ThisObject));
		CommonClient.MessageToUser(MessageText,, "Object.RecyclableWaste", "Object");
		
		Return;
	EndIf;
	
	OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(CurrentData, "RecyclableWaste");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ReturnableWasteFillStage(Command)
	
	FillStageInLines("RecyclableWaste");
	
EndProcedure

&AtClient
Procedure ReturnableWasteFillOutTheCalculationArticle(Command)
	
	FillInCalculationArticleInLines("RecyclableWaste");
	
EndProcedure

&AtClient
Procedure RecyclableWasteToInsertRows(Command)
	
	GetLinesFromClipboard("RecyclableWaste");
	
EndProcedure

&AtClient
Procedure RecyclableWasteToCopyRows(Command)
	
	CopyTSLines("RecyclableWaste");
	
EndProcedure

#EndRegion

#Region MaterialsAndServices

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.MaterialsAndServices;
	TableData = Object.MaterialsAndServices;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure EnterSubstitutionPermission(Command)
	
	MainProductSpecifications = CheckGetMainProductSpecifications();
	If MainProductSpecifications.IsEmpty() Then
		Return;
	EndIf;
	
	If Items.MaterialsAndServices.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ClearMessages();
	
	Cancel = False;
	UsedMaterials = New Array;
	
	ItemsTypes = New Array;
	ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	ItemsTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	
	For Each AlCollections In Items.MaterialsAndServices.SelectedRows Do
		
		RowData = Items.MaterialsAndServices.RowData(AlCollections);
		
		If RowData.MethodOfItemVariantAutoselection <> PredefinedValue("Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData")
			Or RowData.MethodOfProductsAutoselection <> PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData") Then
			
			Cancel = True;
			Break;
			
		EndIf;
		
		If ItemsTypes.Find(RowData.ItemsType) = Undefined Then
			
			Cancel = True;
			Break;
			
		EndIf;
		
		MaterialStructure = New Structure;
		
		MaterialStructure.Insert("Products", RowData.Products);
		MaterialStructure.Insert("Characteristic", RowData.Characteristic);
		MaterialStructure.Insert("NumberOfPackages", RowData.NumberOfPackages);
		MaterialStructure.Insert("Package", RowData.Package);
		
		UsedMaterials.Add(MaterialStructure);
		
	EndDo;
	
	If Cancel Then
		
		MessageText = NStr("vi = 'Các dòng chọn phải thỏa mãn các điều kiện sau:
		|	- không sử dụng chọn tự động mặt hàng hoặc đặc tính;
		|	- kiểu mặt hàng: hàng hóa, bao bì hoặc công việc;';
		|ru = 'Выбранные строки должны удовлетворять следующим условиям:
		|	- не используется автовыбор номенклатуры или характеристики;
		|	- тип номенклатуры: товар, тара или работа;';
		|en = 'Selected lines must meet the following conditions:
		|	- auto selection of the item or variant is not used;
		|	- item type: goods, reusable packaging, or work.'; fa = 'Selected lines must meet the following conditions:
		|	- auto selection of the item or variant is not used;
		|	- item type: goods, reusable packaging, or work.';
		|it = 'Le righe selezionate devono soddisfare i seguenti requisiti:
		|	- non viene utilizzata la selezione automatica di nomenclatura o caratteristiche;
		|	- tipo di nomenclatura: articolo, tara o lavoro;';
		|pl = 'Wybrane wiersze powinny spełniać następujące warunki:
		|	- nie jest używany wybór automatyczny produktu lub charakterystyki;
		|	- typ produktu: towar, opakowanie lub praca;';
		|tr = 'Seçili satırlar aşağıdaki koşulları karşılamalıdır:
		|	 - Ürün veya varyant otomatik seçimi kullanılmayan;
		|	- Ürün türü: ürün, ambalaj veya iş olan;'");
		
		CommonClient.MessageToUser(MessageText,, "Object.MaterialsAndServices", "Object");
		
		Return;
		
	EndIf;
	
	FillingValues = New Structure;
	FillingValues.Insert("BillOfMaterials", Object.Ref);
	FillingValues.Insert("UsedMaterials", UsedMaterials);
	
	FormParameters = New Structure("FillingValues", FillingValues);
	
	OpenForm("Document.EngineeringChangeOrder.ObjectForm", FormParameters, , True);
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesSetUpItemSelection(Command)
	
	CurrentData = Items.MaterialsAndServices.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		MessageText = NStr("vi = 'Hàng của bảng ""Vật liệu và công trình"" không được chọn.';
							|ru = 'Не выбрана строка таблицы ""Материалы и работы"".';
							|en = 'Row of the ""Materials and works"" table is not selected.'; fa = 'Row of the ""Materials and works"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Materiali e lavori"".';
							|pl = 'Nie wybrano wiersza tabeli ""Materiały i prace"".';
							|tr = '""Malzemeler ve İşler"" tablosunun satırı seçilmedi.'");
		CommonClient.MessageToUser(MessageText,, "Object.MaterialsAndServices", "Object");
		Return;
	EndIf;
	
	MainProductSpecifications = CheckGetMainProductSpecifications();
	If MainProductSpecifications.IsEmpty() Then
		Return;
	EndIf;
	
	PropertyMapping = ProductDataManagementClient.DetailsOfSettingsByLineInArray(
		CurrentData,
		Object.PropertyMapping,
		ProductDataManagementClientServer.DetailsSettingUpPropertyMatching());
	
	ProductDataManagementClient.ConfigureProductsAutoselection(
							ThisObject,
							"MaterialsAndServices",
							PropertyMapping, 
							MainProductSpecifications,
							NStr("vi = 'Chỉ ra trong bảng kê chi tiết các nguồn lực sản xuất';
								|ru = 'Указывается в спецификации';
								|en = 'Specified in BOM'; fa = 'Specified in BOM';
								|it = 'Viene indicato nella specifica';
								|pl = 'Wskazuje się w specyfikacji';
								|tr = 'Ürün reçetesinde belirtilmektedir'"),
							Not AttributeAvailability);
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure MaterialsAndServices_SettingUpFilterByPropertiesAndCalculationByFormulas(Command)
	CurrentData = Items.MaterialsAndServices.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		
		MessageText = NStr("vi = 'Hàng của bảng ""Vật liệu và công trình"" không được chọn.';
							|ru = 'Не выбрана строка таблицы ""Материалы и работы"".';
							|en = 'Row of the ""Materials and works"" table is not selected.'; fa = 'Row of the ""Materials and works"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Materiali e lavori"".';
							|pl = 'Nie wybrano wiersza tabeli ""Materiały i prace"".';
							|tr = '""Malzemeler ve İşler"" tablosunun satırı seçilmedi.'");
		CommonClient.MessageToUser(MessageText,, "Object.MaterialsAndServices", "Object");
		
		Return;
	EndIf;
	
	OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(CurrentData, "MaterialsAndServices");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OpenSelectionOfMaterialsCommand(Command)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("SelectionModeWithoutAmountParameters",         True);
	FormParameters.Insert("HideTheViewPriceColumn",                    True);
	FormParameters.Insert("HideTheItemPricesCommand",           True);
	FormParameters.Insert("AllWarehouseBalance",                      True);
	 
	FormParameters.Insert("Document",                                  Object.Ref);
	FormParameters.Insert("FilterByProductType", ProductDataManagementClientServer.ArrayOfAvailableItemTypes(ThisObject, "MaterialsAndServices"));
	FormParameters.Insert("HideManualDiscounts", True);

	OpenForm("DataProcessor.SelectGoodsToPurchaseDocument.Form",
			FormParameters,
			Items.MaterialsAndServices,
			UUID,,,,
			FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesInsertLines(Command)
	
	GetLinesFromClipboard("MaterialsAndServices");
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesCopyLines(Command)
	
	CopyTSLines("MaterialsAndServices");

EndProcedure

&AtClient
Procedure MaterialsAndServicesFillOutTheStage(Command)
	
	FillStageInLines("MaterialsAndServices");
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesFillOutTheCalculationArticle(Command)
	
	FillInCalculationArticleInLines("MaterialsAndServices");
	
EndProcedure

#EndRegion

#Region LaborCosts

&AtClient
Procedure LaborCostsSettingUpSelectionByPropertiesAndCalculationByFormulas_3(Command)
	CurrentData = Items.LaborCosts.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		
		MessageText = NStr("vi = 'Hàng của bảng ""Chi phí nhân công""chưa được chọn.';
							|ru = 'Не выбрана строка таблицы ""Трудозатраты"".';
							|en = 'Line of the ""Labor costs"" table is not selected.'; fa = 'Line of the ""Labor costs"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Costi di manodopera"".';
							|pl = 'Nie wybrano wiersza tabeli ""Nakłady pracy"".';
							|tr = '""İş Gücü Maliyetleri"" tablosunun satırı seçilmedi.'");
		CommonClient.MessageToUser(MessageText,, "Object.LaborCosts", "Object");
		
		Return;
	EndIf;
	
	OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(CurrentData, "LaborCosts");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure LaborCostsCompleteTheStage(Command)
	
	FillStageInLines("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsFillInTheCalculationArticle(Command)
	
	FillInCalculationArticleInLines("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsInsertLines(Command)
	
	GetLinesFromClipboard("LaborCosts");
	
EndProcedure

&AtClient
Procedure TheEffortToCopyRows(Command)
	
	CopyTSLines("LaborCosts");
	
EndProcedure

#EndRegion

#Region ManufacturingProcess

&AtClient
Procedure ProductionProcessCollapse(Command)
	
	ProductionProcessConvolution(True);
	
EndProcedure

&AtClient
Procedure TheProductionProcessToDeploy(Command)
	
	ProductionProcessConvolution(False)
	
EndProcedure

&AtClient
Procedure ProductionProcessIsToMoveUp(Command)
	
	ProductionProcessMoveElement(Items.ManufacturingProcess.CurrentData, -1);
	
EndProcedure

&AtClient
Procedure ProductionProcessMoveDown(Command)
	
	ProductionProcessMoveElement(Items.ManufacturingProcess.CurrentData, 1);
	
EndProcedure

&AtClient
Procedure ProductionProcessIsToAddAPhase(Command)
	
	ProductionProcessStartAddingStage();
	
EndProcedure

&AtClient
Procedure ProductionProcessAddWorkPlanningStage(Command)
	
	ProductionProcessStartAddingStage(New Structure("WorkPlanning", True));
	
EndProcedure

&AtClient
Procedure ProductionProcessAddOperation(Command)
	ProductionProcessStartAddingOperation();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ProductionProcessAddAGroupOfOperations(Command)
	SelectTechnologicalProcess("Template");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure AddATypicalProductionProcess(Command)
	SelectTechnologicalProcess("Typical");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ProductionProcessAddWork(Command)
	ProductionProcessStartAddingWork();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ProductionProcessPropertiesCollapse(Command)
	
	ManufacturingProcessPropertiesConvolution(True);
	
EndProcedure

&AtClient
Procedure ProductionProcessPropertiesExpand(Command)
	
	ManufacturingProcessPropertiesConvolution(False);
	
EndProcedure

&AtClient
Procedure TheProductionProcessForMoreInformation(Command)
	
	ProductionProcessEditAdditionalInformation();
	
EndProcedure

&AtClient
Procedure ProductionProcessIsDividedIntoTechnologicalProcess(Command)
	SelectedRows = Items.ManufacturingProcess.SelectedRows;
	
	AdditionalParameters = New Structure;
	
	If CheckPossibilityToAllocateToTechnologicalProcess(SelectedRows, AdditionalParameters) Then
		
		Notification = New CallbackDescription("AllocateToTechnologicalProcessCompletion", ThisObject, AdditionalParameters);
	
		OpenForm("Catalog.BillsOfMaterials.Form.FormIsIncludedInTechnologicalProcess",
			AdditionalParameters,
			ThisObject,,,, Notification);
		
	EndIf;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ProductionProcessFillInDivision(Command)
	
	If SavedObjectStatus = CurrentSpecificationStatus Then
		Return;
	EndIf;
	
	SelectedRows = Items.ManufacturingProcess.SelectedRows;
	
	If CheckPossibilityOfFillingInDivisionOfStages(SelectedRows) Then
		
		Filter = New Structure;
		Filter.Insert("ProductionBusinessUnit", True);
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", Filter);
		FormParameters.Insert("MultipleChoice", False);
		
		CallbackDescription = New CallbackDescription(
			"FillInDivisionOfStagesCompletion", ThisObject, SelectedRows);
		
		OpenForm(
			"Catalog.BusinessStructure.Form.ChoiceForm",
			FormParameters,
			ThisObject,,,,
			CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionProcessToPickUpByWHO(Command)
	
	If SavedObjectStatus = CurrentSpecificationStatus Then
		Return;
	EndIf;
	StageLineData = ProductionProcessGetCurStage(ThisObject);
	
	If Not CheckIfOperationCanBeAdded(StageLineData) Then
		Return;
	EndIf;
	
	ProductionProcessEditorClient.OpenFormForSelectingOperationsByClassifier(
		ThisObject,,
		False);
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region UniversalMechanisms

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

#EndRegion

#Region ImportDataFromFile

&AtClient
Procedure DownloadMaterialsAndServicesFromFile(Command)
	
	LoadFromFile("MaterialsAndServices", NStr("vi = 'Nguyên vật liệu và dịch vụ';
												|ru = 'Материалы и услуги';
												|en = 'Materials and services'; fa = 'مواد و خدمات';
												|it = 'Materiali e servizi';
												|pl = 'Materiały i usługi';
												|tr = 'Malzemeler ve hizmetler'"));
	
EndProcedure

&AtClient
Procedure LaborCostsUploadFromFile(Command)
	
	LoadFromFile("LaborCosts", NStr("vi = 'Chi phí nhân công';
									|ru = 'Трудозатраты';
									|en = 'Labor costs'; fa = 'هزینه‌های دستمزد';
									|it = 'Costi di manodopera';
									|pl = 'Labor costs';
									|tr = 'İş gücü maliyetleri'"));
	
EndProcedure

&AtClient
Procedure ReturnableWasteLoadFromFile(Command)
	
	LoadFromFile("RecyclableWaste", PresentationOfTabularPartReturnableWaste(ThisObject));
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region UniversalMechanisms

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

// End StandardSubsystems.Properties

#EndRegion

#Region WorkingWithClipboard

&AtClient
Procedure CopyTSLines(Val TSName, Val DataPath = "")

	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items[TSName]) Then
		CopyLinesOnServer(TSName, DataPath);
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items[TSName].SelectedRows.Count());
	EndIf;

EndProcedure

&AtServer
Procedure CopyLinesOnServer(Val TSName, Val DataPath = "")
	
	If IsBlankString(DataPath) Then
		ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	Else
		ProcessingOfTabularForms.CopyRowsToClipboard(Object[DataPath], Items[TSName].SelectedRows);
	EndIf;
	
EndProcedure

&AtClient
Procedure GetLinesFromClipboard(Val TSName, Val DataPath = "")
	
	If IsBlankString(DataPath) Then
		Receiver = Object[TSName];
	Else
		Receiver = Object[DataPath]
	EndIf;
	
	NumberOfRowsBeforeInsertion = Receiver.Count();
	
	GetLinesFromClipboardOnServer(TSName, DataPath);
	
	NumberOfInserted = Receiver.Count() - NumberOfRowsBeforeInsertion;
	
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboardOnServer(TSName, DataPath = "")
	
	CompositionOfLines     = Undefined;
	FilterParameters = Undefined;
	
	If IsBlankString(DataPath) Then
		Receiver = Object[TSName]; // TabularSection
	Else
		Receiver = Object[DataPath];
	EndIf;
	
	If TSName = "ManufacturedProduct" Or TSName = "ManufacturedProducts" Then
		CompositionOfLines = "Products,Characteristic,Package,NumberOfPackages";
	ElsIf TSName = "MaterialsAndServices" Or TSName = "RecyclableWaste" Then
		CompositionOfLines = "Products,Characteristic,Package,NumberOfPackages,ProductCostElement";
	ElsIf TSName = "LaborCosts" Then
		CompositionOfLines = "WorkKind,Count,ProductCostElement";
	EndIf;
	
	SelectGoods = TSName <> "LaborCosts";
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	If SelectGoods Then
		
		ArrayOfProductTypes = ProductDataManagementClientServer.ArrayOfAvailableItemTypes(ThisObject, TSName);
		FilterParameters = New Map;
		FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
		
		If TSName = "ManufacturedProduct" Or TSName = "ManufacturedProducts" Then
			StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
			StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
			StructureOfActions.Insert("FillInProductTypeAttribute", New Structure("Products", "ProductKind"));
		EndIf;
		
		If TSName = "ManufacturedProduct" Or TSName = "ManufacturedProducts" Or TSName = "MaterialsAndServices" Then
			StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		EndIf;
		
		StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		
	EndIf;
	
	LinesFromBuffer = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, CompositionOfLines);
	
	If Not ValueIsFilled(LinesFromBuffer) Then
		Return;
	EndIf;
	
	RowsToProcess = New Array();
	
	For Each LineFromBuffer In LinesFromBuffer Do
		
		NewRow = Receiver.Add();
		FillPropertyValues(NewRow, LineFromBuffer);
		
		WhenEnteringNewSpecificationLine(ThisObject, TSName, NewRow);
		
		If SelectGoods Then
			RowsToProcess.Add(NewRow);
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Receiver);
	
	If TSName = "ManufacturedProduct" Then
		UpdateMainProductSpecificationDataDuringAssembly(ThisObject);
	EndIf;
	
	FillInServiceDetails();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfClipboardCommands(Form, BankingDetailsAreAvailable)
	
	Form.Items.ProductsToInsertRows.Enabled = BankingDetailsAreAvailable;
	Form.Items.ContextMenuProductsInsertLines.Enabled = BankingDetailsAreAvailable;
	
	Form.Items.ManufacturedProducts_InsertRows.Enabled = BankingDetailsAreAvailable;
	Form.Items.ContextMenuOutputItemsInsertLines.Enabled = BankingDetailsAreAvailable;
	
	Form.Items.RecyclableWasteToInsertRows.Enabled = BankingDetailsAreAvailable;
	Form.Items.ContextMenuReturnableWasteInsertRows.Enabled = BankingDetailsAreAvailable;
	
	Form.Items.MaterialsAndServicesInsertLines.Enabled = BankingDetailsAreAvailable;
	Form.Items.ContextMenuMaterialsAndServicesInsertLines.Enabled = BankingDetailsAreAvailable;
	
	Form.Items.LaborCostsInsertLines.Enabled = BankingDetailsAreAvailable;
	Form.Items.ContextMenuLaborCostsInsertLines.Enabled = BankingDetailsAreAvailable;
	
EndProcedure

#EndRegion

#Region MainProduct

&AtClientAtServerNoContext
Function MainProductEditingModeIsUsed(Form)
	If (Form.Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly")
			And Form.Object.AssignmentOption = PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.ItemList")
				Or Form.ProductionIsUsed21)Then
		Return False;
	Else
		Return True;
	EndIf;
EndFunction

&AtServer
Procedure ReadMainProductSpecificationData()
	
	If Not MainProductEditingModeIsUsed(ThisObject) Then
		Return;
	EndIf;
	
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
		Or Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
		Or Object.ProductionProcessType = Enums.ProductionProcessTypes.Repair Then
		
		AttributesList = ListOfPropsMainOutputProduct();
		
		If Object.ManufacturedProducts.Count() <> 0 Then
			
			For Each KeyValue In AttributesList Do
				ThisObject[KeyValue.Value] = Object.ManufacturedProducts[0][KeyValue.Key];
			EndDo;
			
		Else
			
			For Each KeyValue In AttributesList Do
				ThisObject[KeyValue.Value] = Undefined;
			EndDo;
			
		EndIf;
		
	Else
		
		AttributesList = ListOfPropsMainProductSpecifications();
		For Each KeyValue In AttributesList Do
			ThisObject[KeyValue.Value] = Object[KeyValue.Value];
		EndDo;
		
	EndIf;
	
	MainProductItemsType = Common.ObjectAttributeValue(MainProductProductKind, "ItemsType");
	
EndProcedure

&AtClientAtServerNoContext
Function ListOfFormDetailsMainProductSpecifications()
	
	Result = New Map;
	
	Result.Insert("ItemsType",            "MainProductItemsType");
	Result.Insert("ProductKind",            "MainProductProductKind");
	Result.Insert("Products",               "MainProductProducts");
	Result.Insert("ProductsHasPropeties",   "MainProductProductsHasPropeties");
	Result.Insert("ItemVariantsAreUsed", "MainProductItemVariantsAreUsed");
	Result.Insert("Characteristic",             "MainProductCharacteristic");
	Result.Insert("CharacteristicHasPropeties", "MainProductCharacteristicHasPropeties");
	Result.Insert("Package",                   "MainProductPackage");
	Result.Insert("NumberOfPackages",         "MainProductNumberOfPackages");
	Result.Insert("Count",                 "MainProductCount");
	Result.Insert("ShareOfNonconformity",               "MainProductShareOfNonconformity");
	
	Return Result;

EndFunction

&AtClientAtServerNoContext
Function ListOfPropsMainOutputProduct()
	
	Result = New Structure;
	
	Result.Insert("ProductKind",    "MainProductProductKind");
	Result.Insert("Products",       "MainProductProducts");
	Result.Insert("Characteristic",     "MainProductCharacteristic");
	Result.Insert("Package",           "MainProductPackage");
	Result.Insert("NumberOfPackages", "MainProductNumberOfPackages");
	Result.Insert("Count",         "MainProductCount");
	Result.Insert("ShareOfNonconformity",       "MainProductShareOfNonconformity");
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ListOfPropsMainProductSpecifications()
	
	Result = New Structure;
	
	Result.Insert("ProductKind",    "MainProductProductKind");
	Result.Insert("Products",       "MainProductProducts");
	Result.Insert("Characteristic",     "MainProductCharacteristic");
	Result.Insert("Package",           "MainProductPackage");
	Result.Insert("NumberOfPackages", "MainProductNumberOfPackages");
	
	Return Result;

EndFunction

&AtClientAtServerNoContext
Function MainProductSpecificationStructure(Form)
	
	StringStructure = New Structure();
	
	AttributesList = ListOfFormDetailsMainProductSpecifications();
	
	For Each KeyValue In AttributesList Do
		StringStructure.Insert(KeyValue.Key,  Form[KeyValue.Value]);
	EndDo;
	
	Return StringStructure;
	
EndFunction

&AtClientAtServerNoContext
Procedure ProcessChangeOfMainProductData(Form, StringStructure = Undefined) 
	
	AttributesList = ListOfFormDetailsMainProductSpecifications();
	
	If StringStructure <> Undefined Then
		For Each KeyAndValue In StringStructure Do
			Form[AttributesList.Get(KeyAndValue.Key)] = KeyAndValue.Value;
		EndDo;
	EndIf;
	
	FillInDetailsOfObjectAccordingToMainProduct(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInDetailsOfObjectAccordingToMainProduct(Form)
	
	Object = Form.Object;
	
	TSName  = "ManufacturedProducts";
	
	If Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly")
		Or Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Repair")
		Or Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM") Then
		
		AttributesList = ListOfPropsMainOutputProduct();
		
		If Object[TSName].Count() <> 0 Then
			RowData = Object[TSName][0];
		Else
			RowData = Object[TSName].Add();
			WhenEnteringNewSpecificationLine(Form, TSName, RowData);
		EndIf;
		
		For Each KeyValue In AttributesList Do
			RowData[KeyValue.Key] = Form[KeyValue.Value];
		EndDo;
	
	EndIf;
	
	AttributesList = ListOfPropsMainProductSpecifications();
	For Each KeyValue In AttributesList Do
		Object[KeyValue.Value] = Form[KeyValue.Value];
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateInformationOnMainProductSpecification()
	
	If Not MainProductEditingModeIsUsed(ThisObject) Then
		Return;
	EndIf;
	AvailabilityOfApplicationRefinements = New Structure("Products,Characteristic",True,True);
	ConnectionsOfPackingSelectionParameters  = New Array;
	
	AssignmentOptionTypeOfProduct = (Object.AssignmentOption = PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.ProductKind"));
	AssignmentOptionProducts = (Object.AssignmentOption = PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.Products"));
	
	Items.GroupMainProductCharacteristics.Visible     = GetFunctionalOption("UseItemVariants");
	Items.MainProductProductKind.Visible          = AssignmentOptionTypeOfProduct;
	Items.MainProductProducts.Enabled           = Not AssignmentOptionTypeOfProduct;
	Items.MainProductPackage.MarkIncomplete     = False;
	Items.MainProductPackage.AutoMarkIncomplete = AssignmentOptionTypeOfProduct;
	Items.MainProductProducts.Title             = MainFinishedProductItemTitle(ThisObject);
	
	If AssignmentOptionTypeOfProduct Then
		Items.MainProductProducts.InputHint    = NStr("vi = '<bất kỳ mặt hàng>';
														|ru = '<любая номенклатура>';
														|en = '<any items>'; fa = '<any items>';
														|it = '<qualsiasi nomenclatura>';
														|pl = '<dowolny produkt>';
														|tr = '<herhangi bir öğe>'");
	Else
		Items.MainProductProducts.InputHint    = "";
		AvailabilityOfApplicationRefinements.Products            = False;
		ConnectionsOfPackingSelectionParameters                          = CommonClientServer.ValueInArray(
			New ChoiceParameterLink(
				"Products",
				"MainProductProducts",
				LinkedValueChangeMode.Clear));
	EndIf;
	
	If MainProductItemVariantsAreUsed Then
		Items.MainProductCharacteristic.Enabled     = AssignmentOptionProducts;
		Items.MainProductCharacteristic.InputHint  = NStr("vi = '<đặc tính bất kỳ>';
															|ru = '<любая характеристика>';
															|en = '<any variant>'; fa = '<any variant>';
															|it = '<qualsiasi caratteristica>';
															|pl = '<dowolna charakterystyka>';
															|tr = '<herhangi bir varyant>'");
	Else
		Items.MainProductCharacteristic.Enabled     = False;
		Items.MainProductCharacteristic.InputHint  = NStr("vi = '<không sử dụng đặc tính>';
															|ru = '<характеристики не используются>';
															|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
															|it = '<le caratteristiche non vengono usate>';
															|pl = '<charakterystyki nie dotyczą>';
															|tr = '<varyantlar kullanılmamaktadır>'");
		AvailabilityOfApplicationRefinements.Characteristic          = False;
	EndIf;
	
	For Each KeyAndValue In AvailabilityOfApplicationRefinements Do
		
		SetSettingsForApplicationRefinementElements(ThisObject, KeyAndValue.Key, KeyAndValue.Value);
		
	EndDo;
	
	Items.MainProductPackage.ChoiceParameterLinks = New FixedArray(ConnectionsOfPackingSelectionParameters);
	Catalogs.PackagesAndUnitsOfMeasure.DisplayInformationAboutStorageUnit(MainProductProducts, Items.MainProductPackage);
EndProcedure

&AtServer
Function CheckFillingOfMainProduct()
	
	HasErrors = False;
	If MainProductEditingModeIsUsed(ThisObject) Then
		
		AssignmentOptionTypeOfProduct =
			(Object.AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ProductKind);
		
		If Not ValueIsFilled(MainProductProducts) 
			And Not AssignmentOptionTypeOfProduct Then
			
			MessageText = CommonClientServer.FillingErrorText("Field", "FillType", MainFinishedProductItemTitle(ThisObject));
			Common.MessageToUser(MessageText,, "MainProductProducts",, HasErrors);
			
		EndIf;
		
		If Not ValueIsFilled(MainProductProductKind)
			And AssignmentOptionTypeOfProduct Then
				
			MessageText = CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Dạng mặt hàng';
																						|ru = 'Вид номенклатуры';
																						|en = 'Item kind'; fa = 'نوع قلم';
																						|it = 'Tipo di articolo';
																						|pl = 'Rodzaj pozycji';
																						|tr = 'Ürün türü'"));
			Common.MessageToUser(MessageText,, "MainProductProductKind",, HasErrors);
				
		EndIf;
		
		If Not ValueIsFilled(MainProductNumberOfPackages) Then
			
			MessageText = CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Số lượng';
																						|ru = 'Количество';
																						|en = 'Quantity'; fa = 'مقدار';
																						|it = 'Quantità';
																						|pl = 'Ilość';
																						|tr = 'Miktar'"));
			Common.MessageToUser(MessageText,, "MainProductNumberOfPackages",, HasErrors);
			
		EndIf;
		
		If Not ValueIsFilled(MainProductPackage)
			And AssignmentOptionTypeOfProduct Then
			
			MessageText = CommonClientServer.FillingErrorText("Field", "FillType", NStr("vi = 'Đơn vị tính';
																						|ru = 'Единица измерения';
																						|en = 'Unit of measure'; fa = 'واحد اندازه‌گیری';
																						|it = 'Unità di misura';
																						|pl = 'Jednosta miary';
																						|tr = 'Ölçü birimi'"));
			Common.MessageToUser(MessageText,, "MainProductPackage",, HasErrors);
			
		EndIf;
	
	EndIf;
	Return Not HasErrors;
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateMainProductSpecificationDataDuringAssembly(Form)
	
	Object = Form.Object;
	
	If Object.ProductionProcessType <> PredefinedValue("Enum.ProductionProcessTypes.Assembly") Then
		Return;
	EndIf;
	
	ThereIsBasicProduct = (Object.ManufacturedProducts.Count() > 0);
	
	AttributesList = ListOfPropsMainProductSpecifications();
	For Each KeyValue In AttributesList Do
		Object[KeyValue.Value] = ?(ThereIsBasicProduct, Object.ManufacturedProducts[0][KeyValue.Key], Undefined);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function ThisIsTechnologicalSet(Form)
	
	Result = False;
	Result = Form.MainProductItemsType
		= PredefinedValue("Enum.ItemsTypes.Set");
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ThisIsPerformanceOfRepairWork(Form)
	
	Result = False;
	Result = Form.Object.ProductionProcessType
		= PredefinedValue("Enum.ProductionProcessTypes.PerformRM");
	Return Result;
	
EndFunction

&AtServerNoContext
Procedure MainProductPackagingAutoSelectionOnServer(SearchString, ChoiceData)
	
	Query = New Query;
	Query.Text = Catalogs.BillsOfMaterials.RequestTextAvailablePackagingSpecificationsForProductType(True);
	Query.SetParameter("UseItemPackages", GetFunctionalOption("UseItemPackages"));
	Query.SetParameter("SearchString", TrimAll(SearchString)+"%");
	
	Selection = Query.Execute().Select();
	
	ChoiceData = New ValueList;
	While Selection.Next() Do
		ChoiceData.Add(Selection.Ref, Selection.Presentation);
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckClearDetailsWhenChangingDestinationOption()
	
	If Object.AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ProductKind Then
		MainProductProducts   = Undefined;
		MainProductCharacteristic = Undefined;
		MainProductPackage       = Undefined;
	Else
		If Not ValueIsFilled(MainProductProducts) Then
			MainProductPackage = Undefined;
		EndIf;
	EndIf;
	
	If Object.AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.Products Then
		If Not ValueIsFilled(MainProductProducts) Then
			ProductDataManagementClientServer.ClearSpecificationRefinementSettings(Object);
		EndIf;
	EndIf;
	
	FillInServiceDetailsOfMainFINISHEDProduct();
	
EndProcedure

&AtServer
Procedure CalculateQuantityOfMainProduct(StringStructure, CachedValues)
	
	If Object.AssignmentOption = PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.ProductKind") Then
	
		If ValueIsFilled(StringStructure.Package) Then
			
			ValueOfBankingDetails = Common.ObjectAttributesValues(StringStructure.Package, "Numerator,Denominator");
			
			ZoomRatio = ?(ValueOfBankingDetails.Denominator = 0, 1, ValueOfBankingDetails.Numerator / ValueOfBankingDetails.Denominator);
			
		Else
			
			ZoomRatio = 1;
			
		EndIf;
		
		StringStructure.Count = StringStructure.NumberOfPackages * ZoomRatio;
		
	Else
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
		BatchProcessingOfTablePartServer.ProcessTSString(StringStructure, StructureOfActions, CachedValues);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CheckClearWayToReflectMaterialTransferBetweenStages(Form)
	
	Object = Form.Object;
	
	If Object.RecordMethodOfMaterialTransferBetweenStagesLots <>
			PredefinedValue("Enum.RecordMethodsOfMaterialTransferBetweenStagesLots.NotUsed")
		And Not IntermediateReleaseIsAvailable(Form) Then
		Object.RecordMethodOfMaterialTransferBetweenStagesLots =
			PredefinedValue("Enum.RecordMethodsOfMaterialTransferBetweenStagesLots.NotUsed");
		Form.ThereIsIntermediateRelease = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure DestinationOptionWhenChangedOnServer();
	
	ReadMainProductSpecificationData();
	
	CheckClearDetailsWhenChangingDestinationOption();
	
	ProcessChangeOfMainProductData(ThisObject);
	
	SetAvailabilityOfProductEditingElements();
	
	UpdateInformationOnMainProductSpecification();
	
	If Object.AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ItemList Then
		FillInServiceAttributesOutputProduct();
	EndIf;
	
	DetailsOfReleaseBatchDescriptionWhenChanging();
	
	CheckClearWayToReflectMaterialTransferBetweenStages(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "AssignmentOption,RecordMethodOfMaterialTransferBetweenStagesLots");
	
EndProcedure

&AtServer
Procedure MainProductProductTypeWhenChangedOnServer()
	
	AttributesValues = Common.ObjectAttributesValues(
		MainProductProductKind, "ItemsType,UnitOfMeasure");
	
	MainProductItemsType = AttributesValues.ItemsType;
	If Not ValueIsFilled(MainProductPackage) Then
		MainProductPackage = AttributesValues.UnitOfMeasure;
	EndIf;
	
	FillInServiceDetailsOfMainFINISHEDProduct();
	
	ProductDataManagementClientServer.ClearSpecificationRefinementSettings(Object);
	
	ProcessChangeOfMainProductData(ThisObject);
	
	UpdateInformationOnMainProductSpecification();
	
	DetailsOfReleaseBatchDescriptionWhenChanging();
	
	CheckClearWayToReflectMaterialTransferBetweenStages(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "MainProduct,ManufacturingProcess,RecordMethodOfMaterialTransferBetweenStagesLots");
	
EndProcedure

&AtServer
Procedure MainProductProductsWhenChangedOnServer(CachedValues)
	
	StringStructure = MainProductSpecificationStructure(ThisObject);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner", StringStructure.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", StringStructure.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	StructureOfActions.Insert("FillInProductTypeAttribute", New Structure("Products", "ProductKind"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));

	BatchProcessingOfTablePartServer.ProcessTSString(StringStructure, StructureOfActions, CachedValues);
	
	ProcessChangeOfMainProductData(ThisObject, StringStructure);
	
	FillInServiceDetailsOfMainFINISHEDProduct();
	 
	ProductDataManagementClientServer.ClearSpecificationRefinementSettings(Object, "Characteristic");
	
	UpdateInformationOnMainProductSpecification();
	
	DetailsOfReleaseBatchDescriptionWhenChanging();
	
	CheckClearWayToReflectMaterialTransferBetweenStages(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "MainProduct,ManufacturingProcess,RecordMethodOfMaterialTransferBetweenStagesLots");
	
EndProcedure

&AtServer
Procedure MainProductCharacteristicWhenChangingOnServer()
	
	ProcessChangeOfMainProductData(ThisObject);
	
	ProductDataManagementClientServer.ClearSpecificationRefinementSettings(Object, "Characteristic");
	SetSettingsForApplicationRefinementElements(ThisObject, "Characteristic");
	
	DetailsOfReleaseBatchDescriptionWhenChanging();
	
EndProcedure

&AtServer
Procedure MainProductPackagingNumberOfPackagesWhenChangedOnServer(CachedValues)
	
	StringStructure = MainProductSpecificationStructure(ThisObject);
	
	CalculateQuantityOfMainProduct(StringStructure, CachedValues);
	
	ProcessChangeOfMainProductData(ThisObject, StringStructure);
	
	DetailsOfReleaseBatchDescriptionWhenChanging();
	
EndProcedure

&AtClient
Procedure MainProductPackageStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Modified = True;
	
	MainProductPackage = Result;
	
	MainProductPackagingNumberOfPackagesWhenChangedOnServer(CachedValues);
	
EndProcedure

&AtClientAtServerNoContext
Function MainFinishedProductItemTitle(Form)
	
	Return ?(ThisIsPerformanceOfRepairWork(Form),
		NStr("vi = 'Công việc được thực hiện';
			|ru = 'Выполняемая работа';
			|en = 'Work to perform'; fa = 'کار قابل انجام';
			|it = 'Work to perform';
			|pl = 'Work to perform';
			|tr = 'Yapılan iş'"),
		NStr("vi = 'Mặt hàng';
			|ru = 'Номенклатура';
			|en = 'Item'; fa = 'قلم';
			|it = 'Item';
			|pl = 'Item';
			|tr = 'Öğe'"));
	
EndFunction

#Region FinishedProductBeingRepaired

&AtServer
Procedure FillInServiceAttributesOfFINISHEDProductBeingRepaired()
	
	If Not ThisIsPerformanceOfRepairWork(ThisObject) Then
		Return;
	EndIf;
	
	If RepairedFinishedProductDestinationOption = RepairedFinishedProductDestinationOptionTypeOfItem() Then
		TableName = "ItemKinds";
		AttributeName = "ItemKindOfProductUnderRM";
	Else
		TableName = "Products";
		AttributeName = "UnderRepairProduct";
	EndIf;
	
	QueryText = "
	|
	|SELECT
	|	CASE
	|		WHEN T.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE FALSE
	|	END           AS FinishedProductBeingRepairedCharacteristicsAreUsed
	|
	|FROM
	|	&Table AS T
	|WHERE
	|	T.Ref = &Ref
	|
	|";
	
	QueryText = StrReplace(QueryText, "&Table", StrTemplate("Catalog.%1", TableName));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", Object[AttributeName]);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(ThisObject, Selection);
	Else
		FinishedProductBeingRepairedCharacteristicsAreUsed = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function FinishedProductBeingRepairedBillOfMaterialsStructure(Form)
	
	Result = New Structure();
	
	Result.Insert("ProductKind",            Form.Object.ItemKindOfProductUnderRM);
	Result.Insert("Products",               Form.Object.UnderRepairProduct);
	Result.Insert("Characteristic",             Form.Object.UnderRepairVariant);
	Result.Insert("ItemVariantsAreUsed", Form.FinishedProductBeingRepairedCharacteristicsAreUsed);
	
	Return Result;
	
EndFunction

&AtServer
Procedure CustomizeElementsOfFinishedProductBeingRepaired()
	
	If Not ThisIsPerformanceOfRepairWork(ThisObject) Then
		Return;
	EndIf;
	
	RepairedFinishedProductDestinationOption = ?(
		ValueIsFilled(Object.ItemKindOfProductUnderRM)
			And Not ValueIsFilled(Object.UnderRepairProduct),
		RepairedFinishedProductDestinationOptionTypeOfItem(),
		RepairedFinishedProductDestinationOptionItem());
		
	UpdateInformationOnFinishedProductBeingRepairedBillOfMaterials();
	
EndProcedure

&AtServer
Procedure UpdateInformationOnFinishedProductBeingRepairedBillOfMaterials()
	
	If Not ThisIsPerformanceOfRepairWork(ThisObject) Then
		Return;
	EndIf;
	
	Items.UnderRepairVariant.Visible = GetFunctionalOption("UseItemVariants");
	
	If FinishedProductBeingRepairedCharacteristicsAreUsed Then
		Items.UnderRepairVariant.Enabled    = RepairedFinishedProductDestinationOption = RepairedFinishedProductDestinationOptionItem();
		Items.UnderRepairVariant.InputHint = NStr("vi = '<đặc tính bất kỳ>';
													|ru = '<любая характеристика>';
													|en = '<any variant>'; fa = '<any variant>';
													|it = '<qualsiasi caratteristica>';
													|pl = '<dowolna charakterystyka>';
													|tr = '<herhangi bir varyant>'");
	Else
		Items.UnderRepairVariant.Enabled    = False;
		Items.UnderRepairVariant.InputHint = NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'");
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function RepairedFinishedProductDestinationOptionTypeOfItem()
	
	Return 0;
	
EndFunction

&AtClientAtServerNoContext
Function RepairedFinishedProductDestinationOptionItem()
	
	Return 1;
	
EndFunction

&AtServer
Procedure ProcessChangeInDataOfFINISHEDProductBeingRepaired()
	
	StructureOfData = FinishedProductBeingRepairedBillOfMaterialsStructure(ThisObject);
	
	If RepairedFinishedProductDestinationOption = RepairedFinishedProductDestinationOptionTypeOfItem() Then
		StructureOfData.Products   = Undefined;
		StructureOfData.Characteristic = Undefined;
	Else
		StructureOfActions = New Structure;
		StructureOfActions.Insert("CheckCharacteristicsByOwner");
		StructureOfActions.Insert("FillInProductTypeAttribute", New Structure("Products", "ProductKind"));
		BatchProcessingOfTablePartServer.ProcessTSString(StructureOfData, StructureOfActions, Undefined);
	EndIf;
	
	Object.ItemKindOfProductUnderRM = StructureOfData.ProductKind;
	Object.UnderRepairProduct    = StructureOfData.Products;
	Object.UnderRepairVariant  = StructureOfData.Characteristic;
	
	FillInServiceAttributesOfFINISHEDProductBeingRepaired();
	
	UpdateInformationOnFinishedProductBeingRepairedBillOfMaterials();
	
	ConfigureDependentFormElements(ThisObject, "MainProduct");
	
	Modified = True;
	
EndProcedure

#EndRegion

#EndRegion

#Region ManufacturedProduct

&AtServer
Procedure ProductsProductListWhenChangedOnServer(CurrentRow, CachedValues)
	
	CurrentData = Object.ManufacturedProducts.FindByID(CurrentRow);
	
	ProductDataManagementClientServer.WhenChangingProductsInLineWithAutoSelection(
		CurrentData,
		Object);
		
	ProductDataManagementClientServer.WhenChangingCharacteristicInLineWithAutoSelection(
		CurrentData,
		Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentData.Package);
	StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInSeriesAttribute", New Structure("Products", "SeriesAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute", New Structure("Products", "ProductKind"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "ManufacturedProducts"));
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	UpdateFlagRequiresSeriesToBeSpecified(
		"ManufacturedProducts",
		CurrentData.Products,
		CurrentData.BatchIndicationRequired,
		ThisObject);
		
	DetailsOfReleaseBatchDescriptionWhenChanging();
	
EndProcedure

&AtServer
Procedure OutputCharacteristicWhenChangedOnServer(CurrentRow, CachedValues)
	
	CurrentData = Object.ManufacturedProducts.FindByID(CurrentRow);
	
	ProductDataManagementClientServer.WhenChangingCharacteristicInLineWithAutoSelection(CurrentData, Object);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	DetailsOfReleaseBatchDescriptionWhenChanging();
	
EndProcedure

&AtServer
Procedure ProductsPackagingNumberOfPackagesWhenChangedOnServer(CurrentRow, CachedValues)
	
	CurrentData = Object.ManufacturedProducts.FindByID(CurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	StructureOfActions.Insert("RecalculateCostShare", CostAllocationParameters);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	DetailsOfReleaseBatchDescriptionWhenChanging();
	
EndProcedure

&AtServer
Procedure ProductsAreRequiredToSpecifySeriesWhenChangingOnServer(Id)

	CurrentData = Object.ManufacturedProducts.FindByID(Id);
	
	UpdateFlagRequiresSeriesToBeSpecified(
		"ManufacturedProducts",
		CurrentData.Products,
		CurrentData.BatchIndicationRequired,
		ThisObject);
	
EndProcedure

&AtClient
Procedure CheckClearProductParameterizationSettings()
	
	If Object.ManufacturedProducts.Count() = 0 Then
		Return;
	EndIf;
	
	MainProductLine = Object.ManufacturedProducts[0];
	IDRow    = MainProductLine.GetID();
	
	If MainProductLine.MethodOfProductsAutoselection <> PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData") Then
		MainProductLine.PropertyThatContainsProducts = Undefined;
		MainProductLine.MethodOfProductsAutoselection   = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData");
	EndIf;
	
	If MainProductLine.MethodOfItemVariantAutoselection <> PredefinedValue("Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData") Then
		ProductDataManagementClient.ClearProductSelectionSettings(
			Items.ManufacturedProduct,
			CommonClientServer.ValueInArray(IDRow),
			Object.PropertyMapping);
		MainProductLine.ItemVariantAutoSelectionAlgorithm = "";
		MainProductLine.MethodOfItemVariantAutoselection   = PredefinedValue("Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData");
	EndIf;
	
	If MainProductLine.FilterByPropertiesIsSet Then
		ProductDataManagementClient.ClearSelectionSettingsByProperties(
			Items.ManufacturedProduct,
			CommonClientServer.ValueInArray(IDRow),
			Object.SelectionByProperties);
		MainProductLine.FilterByPropertiesIsSet = False;
	EndIf;
	
	If MainProductLine.CalculationByFormula Then
		MainProductLine.QuantityCalculationAlgorithm = "";
		MainProductLine.CalculationByFormula           = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfProductLineParameterizationCommands(CurrentData)
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	StringParameterizationIsAvailable = (CurrentData.LineNumber > 1);
	
	Items.ProductsSetUpItemSelection.Enabled                  = StringParameterizationIsAvailable;
	Items.ProductsSettingUpSelectionByPropertiesAndCalculationByFormulas.Enabled = StringParameterizationIsAvailable;
	
EndProcedure

#EndRegion

#Region ManufacturedProducts

&AtClient
Procedure WhenChangingProductListInOutputProductLine(CurrentData)
	
	ProductDataManagementClientServer.WhenChangingProductsInLineWithAutoSelection(CurrentData, Object);
	ProductDataManagementClientServer.WhenChangingCharacteristicInLineWithAutoSelection(CurrentData, Object);
	
	ClearProcessBySpecificationSetting(CurrentData);
	
EndProcedure

#EndRegion

#Region MaterialsAndServices

&AtServer
Procedure MaterialsAndServicesAreRequiredToSpecifySeriesWhenChangingOnServer()

	CurrentRow = Items.MaterialsAndServices.CurrentRow;
	CurrentData = Object.MaterialsAndServices.FindByID(CurrentRow);
	
	UpdateFlagRequiresSeriesToBeSpecified(
		"MaterialsAndServices", 
		CurrentData.Products, 
		CurrentData.BatchIndicationRequired,
		ThisObject);
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	If NewRow <> Undefined Then
		
		TSName = "MaterialsAndServices";
		
		WhenEnteringNewSpecificationLine(ThisObject, TSName, NewRow, True);
		
	EndIf;
	
EndProcedure

#Region MethodOfReceivingMaterial

&AtClient
Procedure ProcessingSelectionOfMethodOfObtainingMaterial(RowData, ValueSelected)
	
	MethodOfObtainingMaterialBeforeChange = RowData.MethodOfReceivingMaterial;
	
	FillPropertyValues(RowData, ValueSelected);
	FillInServiceDetailsInMaterialsAndServicesLine(RowData);
	
	FillInAttributeSeparatelyInContentLine(RowData, MethodOfObtainingMaterialBeforeChange <> RowData.MethodOfReceivingMaterial);
	CheckFillOutDefaultCalculationArticle(RowData);
	CheckAddIntermediateSemiFinishedProductRelease(RowData, ValueSelected);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CheckDefaultMethodForGettingContent(String)
	
	If (String.MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInProductsProperty")
			And String.ProducedInProcess
			And String.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage")
		
		Or String.MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInProductionProcess")
			And String.ProducedInProcess
		) Then
	
		ProductDataManagementClientServer.FillInDefaultMethodForGettingMaterial(String);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInPresentationOfMaterialReceiptMethod(String, Form)
	
	If Not Form.Items.MaterialsAndServicesMethodOfGettingTheMaterialEditing.Visible Then
		Return;
	EndIf;
	
	Result = "";
	If String.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials") Then
		
		If ValueIsFilled(String.SourceOfSemiFinishedProduct) Or Form.ProductionIsUsed21 Then
			
			Result = StrTemplate(NStr("vi = 'Sản xuất theo bảng kê chi tiết các nguồn lực sản xuất ""%1""';
										|ru = 'Произвести по спецификации ""%1""';
										|en = 'Produce by the ""%1"" BOM'; fa = 'Produce by the ""%1"" BOM';
										|it = 'Produrre secondo la specifica ""%1""';
										|pl = 'Wyprodukuj wg specyfikacji ""%1""';
										|tr = '""%1"" ürün reçetesine göre üret'"), String.SourceOfSemiFinishedProductPresentation);
			
		Else
			
			Result = NStr("vi = 'Sản xuất';
							|ru = 'Произвести';
							|en = 'Produce'; fa = 'تولید';
							|it = 'Produrre';
							|pl = 'Dokonać';
							|tr = 'Üret'");
			
		EndIf;
		
		If Not Form.DynamicStructureOfProductionOrders // outdated "Plan after Stage" setting
			And ValueIsFilled(String.PlanNotEarlierThan) Then
			
			Result = Result + StrTemplate(NStr("vi = ', kế hoạch sau công đoạn ""%1""';
												|ru = ', планировать после этапа ""%1""';
												|en = ', schedule after the ""%1"" stage'; fa = ', schedule after the ""%1"" stage';
												|it = ', pianificare dopo la fase ""%1""';
												|pl = ', planuj po etapie ""%1""';
												|tr = ', ""%1"" aşamasından sonra planla'"), String.PlanNotEarlierThanPresentation);
			
		EndIf;
		
	ElsIf String.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage") Then
		
		If ValueIsFilled(String.BillOfMaterialsRM) Then
			
			Result = StrTemplate(NStr("vi = 'Sửa chữa theo bảng kê chi tiết các nguồn lực sản xuất""%1""';
										|ru = 'Ремонт по спецификации ""%1""';
										|en = 'R&M according to the ""%1"" BOM'; fa = 'R&M according to the ""%1"" BOM';
										|it = 'Riparazione secondo la specifica ""%1""';
										|pl = 'Remont wg specyfikacji ""%1""';
										|tr = '""%1"" ürün reçetesine göre bakım-onarım'"), String.BillOfMaterialsRMPresentation);
			
		Else
			
			Result = StrTemplate(NStr("vi = 'Nhận từ bước ""%1""';
										|ru = 'Получить с этапа ""%1""';
										|en = 'Receive from the stage ""%1""'; fa = 'Receive from the stage ""%1""';
										|it = 'Ricevere dalla fase ""%1""';
										|pl = 'Pobierz z etapu ""%1""';
										|tr = '""%1"" aşamasından al'"), String.SourceOfSemiFinishedProductPresentation);
			
		EndIf;
		
	ElsIf String.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.Provide")
		And String.ItemsType = PredefinedValue("Enum.ItemsTypes.Set")
		And ValueIsFilled(String.SourceOfSemiFinishedProduct) Then
		
		Result = StrTemplate(NStr("vi = 'Thành phần theo bảng kê chi tiết ""%1""';
									|ru = 'Состав по спецификации ""%1""';
									|en = 'Content by the ""%1"" bill of materials'; fa = 'Content by the ""%1"" bill of materials';
									|it = 'Composizione per specifica ""%1""';
									|pl = 'Skład według specyfikacji ""%1""';
									|tr = '""%1"" ürün reçetesine göre içerik'"), String.SourceOfSemiFinishedProductPresentation);
		
	Else
		
		Result = NStr("vi = 'Đảm bảo';
						|ru = 'Обеспечивать';
						|en = 'Supply'; fa = 'Supply';
						|it = 'Fornire';
						|pl = 'Zapewniaj';
						|tr = 'Sağla'");
		
	EndIf;
	String.MethodOfGettingTheMaterialEditing = Result;
	
EndProcedure

#EndRegion

#Region ProductCostElement

&AtClientAtServerNoContext
Procedure FillInDefaultCostingArticle(RowData)
	
	If ProductDataManagementClientServer.SemiFinishedProductProducedInProcess(RowData) Then
		
		RowData.ProductCostElement = PredefinedValue("Catalog.ProductCostElements.SemiFinishedProductsProducedInProcess");
		
	Else
		
		RowData.ProductCostElement = PredefinedValue("Catalog.ProductCostElements.EmptyRef");
		
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure CheckFillOutDefaultCalculationArticle(RowData)
	
	If (RowData.ProductCostElement <> PredefinedValue("Catalog.ProductCostElements.SemiFinishedProductsProducedInProcess")
			And ProductDataManagementClientServer.SemiFinishedProductProducedInProcess(RowData)
			
		Or RowData.ProductCostElement = PredefinedValue("Catalog.ProductCostElements.SemiFinishedProductsProducedInProcess")
			And Not ProductDataManagementClientServer.SemiFinishedProductProducedInProcess(RowData))
			
		Then
		FillInDefaultCostingArticle(RowData);
	EndIf;

EndProcedure

#EndRegion

#Region Other

&AtClientAtServerNoContext
Procedure WhenEnteringNewSpecificationLine(Form, TSName, LineOfATabularSection, Copy = False)
	
	SourceLinkKey = ?(Copy, LineOfATabularSection.ConnectionKey, Undefined);
	
	LineOfATabularSection.ConnectionKey = New UUID;
	
	If TSName <> "LaborCosts" Then
	
		ProductDataManagementClientServer.WhenEnteringNewLineWithAutoSelection(
				LineOfATabularSection,
				SourceLinkKey,
				Form.Object.PropertyMapping);
			
	EndIf;
	
	ProductDataManagementClientServer.WhenEnteringNewLineWithSelectionByProperties(
			LineOfATabularSection,
			SourceLinkKey,
			Form.Object.SelectionByProperties);
			
	If TSName = "MaterialsAndServices" Then
		
		FillPropertyValues(LineOfATabularSection, Form.FirstStageData, "ThisIsTheFirstStep,ProductionByThirdParty");
		ProductDataManagementClientServer.FillInDefaultMethodForGettingMaterial(LineOfATabularSection);
		
		CheckFillOutDefaultCalculationArticle(LineOfATabularSection);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingProductsInMaterialsLine(CurrentData)
	
	ProductDataManagementClientServer.WhenChangingProductsInLineWithAutoSelection(
		CurrentData,
		Object);
		
	ProductDataManagementClientServer.WhenChangingCharacteristicInLineWithAutoSelection(
		CurrentData,
		Object);

	ProductDataManagementClientServer.FillInDefaultMethodForGettingMaterial(CurrentData);
	FillInAttributeSeparatelyInContentLine(CurrentData);
	FillInProduceAttributeInMaterialsLine(ThisObject, CurrentData);
	CheckFillOutDefaultCalculationArticle(CurrentData);
	
	UpdateFlagRequiresSeriesToBeSpecified(
		"MaterialsAndServices", 
		CurrentData.Products, 
		CurrentData.BatchIndicationRequired,
		ThisObject);

EndProcedure

&AtServer
Procedure ProcessStageChangeMaterialsAndServices(IDs)
	
	FillInServiceDetailsMaterialsAndServices(IDs);
	
	For Each Id In IDs Do
		
		String = Object.MaterialsAndServices.FindByID(Id);
		
		If Not String.ProducedInProcess Then
			Continue;
		EndIf;
		
		If String.ThisIsTheFirstStep And String.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage")
			Or String.ThisIsTheFirstStep And ValueIsFilled(String.PlanNotEarlierThan)
			Or String.ProductionByThirdParty And Not ProductionIsUsed22 Then
			ProductDataManagementClientServer.FillInDefaultMethodForGettingMaterial(String);
			FillInAttributeSeparatelyInContentLine(String);
			FillInDefaultCostingArticle(String);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInAttributeSeparatelyInContentLine(RowData, Reset = True)
	
	If RowData.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage") Then
		RowData.WithAssignment = True;
	ElsIf RowData.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
		RowData.WithAssignment = False;
	ElsIf Reset Then
		RowData.WithAssignment = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInProduceAttributeInMaterialsLine(Form, RowData)
	
	Produce = False;
	
	If RowData.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials") Then
		Produce = True;
	EndIf;
	
	If RowData.ItemsType = PredefinedValue("Enum.ItemsTypes.Set")
		And (Form.SourceOfCompositionOfSetsInProduction = PredefinedValue("Enum.SourcesOfCompositionOfSetsInProduction.Specifications")
				Or Form.SourceOfCompositionOfSetsInProduction = PredefinedValue("Enum.SourcesOfCompositionOfSetsInProduction.SpecificationsOrConfigurationOptions")
				Or ValueIsFilled(RowData.SourceOfSemiFinishedProduct)) Then
		Produce = True;
	EndIf;
	
	RowData.Produce = Produce;
	
EndProcedure

#EndRegion

#EndRegion

#Region AssignmentParameters

&AtServer
Procedure ProcessSpecificationAssignmentParameters()
	
	If Not GetFunctionalOption("UseBOMAssignmentParameters") Then
		Return;
	EndIf;
	
	ClearSpecificationAssignmentParameters();
	
	CreateDetailsOfSpecificationAssignmentParametersForm();
	
	CreateFormElementsForSpecificationAssignmentParameters();
	
	FillInValuesOfSpecificationAssignmentParameters();
	
EndProcedure

&AtServer
Procedure RecordSpecificationAssignmentParameters(CurrentObject)
	
	If Not GetFunctionalOption("UseBOMAssignmentParameters") Then
		Return;
	EndIf;
	
	BillOfMaterials = CurrentObject.Ref;
	
	RecordSet = InformationRegisters.ValuesOfBOMAssignmentParameters.CreateRecordSet();
	RecordSet.Filter.BillOfMaterials.Set(BillOfMaterials);
	
	For Each Parameter In AssignmentParameters Do
		
		If Not ThisObject[Parameter.AttributeUse] Then
			Continue;
		EndIf;
		
		Condition = PurposeParametersConditions[ThisObject[Parameter.AttributeCondition]]; // See ProductDataManagementClientServer.StructureOfSelectionConditionByProductProperties
		
		If Condition.Interval Then
			
			AddDestinationParameterToRecordset(RecordSet, BillOfMaterials, Parameter,
				?(Condition.Id = "InIntervalIncluding","GreaterOrEqual","Greater"),
				ThisObject[Parameter.AttributeValue+"1"], 1);
				
			AddDestinationParameterToRecordset(RecordSet, BillOfMaterials, Parameter,
				?(Condition.Id = "InIntervalIncluding","LessOrEqual","Less"),
				ThisObject[Parameter.AttributeValue+"2"], 2);
				
		Else
			
			If Condition.List Then
				For IndexOf = 0 To ThisObject[Parameter.AttributeValue].Count()-1 Do
					AddDestinationParameterToRecordset(RecordSet, BillOfMaterials,
						Parameter, Condition.Id, ThisObject[Parameter.AttributeValue][IndexOf].Value, IndexOf+1);
				EndDo;
			Else
				AddDestinationParameterToRecordset(RecordSet, BillOfMaterials,
					Parameter, Condition.Id, ThisObject[Parameter.AttributeValue]);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	RecordSet.Write();
	
EndProcedure

&AtServer
Procedure CheckFillingOfSpecificationAssignmentParameters(Cancel = False)
	
	If Not GetFunctionalOption("UseBOMAssignmentParameters") Then
		Return;
	EndIf;
	
	TemplateNotFilledIn      = NStr("vi = 'Chưa điền %1 giá trị tham số ""%2"".';
									|ru = 'Не заполнено %1значение параметра ""%2"".';
									|en = 'The %1 value of the ""%2"" parameter is not filled in.'; fa = 'The %1 value of the ""%2"" parameter is not filled in.';
									|it = 'Non è stato compilato %1 il valore del parametro ""%2"".';
									|pl = 'Nie wypełniono %1wartości parametru""%2"".';
									|tr = '""%2"" parametresinin %1 değeri doldurulmadı.'");
	TemplateInvalidInterval = NStr("vi = 'Giá trị bên trái của tham số ""%1"" không thể lớn hơn giá trị bên phải.';
									|ru = 'Левое значение параметра ""%1"" не может быть больше правого.';
									|en = 'The left value of the parameter ""%1"" cannot be greater than the right value.'; fa = 'The left value of the parameter ""%1"" cannot be greater than the right value.';
									|it = 'Valore sinistro del parametro ""%1"" non deve essere superiore del destro.';
									|pl = 'Lewa wartość parametru ""%1"" nie może być większa od prawej.';
									|tr = '""%1"" parametresinin sol değeri, sağdakinden büyük olamaz.'");
	
	For Each Parameter In AssignmentParameters Do
		
		If Not ThisObject[Parameter.AttributeUse] Then
			Continue;
		EndIf;
		
		Condition = PurposeParametersConditions[ThisObject[Parameter.AttributeCondition]];
		
		If Condition.Interval Then
			
			For IndexOf = 1 To 2 Do
				If Parameter.FillingIsMandatory And Not ValueIsFilled(ThisObject[Parameter.AttributeValue+IndexOf]) Then
					Common.MessageToUser(
						StrTemplate(TemplateNotFilledIn,?(IndexOf=1,NStr("vi = 'bên trái';
																		|ru = 'левое';
																		|en = 'left'; fa = 'left';
																		|it = 'a sinistra';
																		|pl = 'lewe';
																		|tr = 'sol'"),NStr("vi = 'bên phải';
																							|ru = 'правое';
																							|en = 'right'; fa = 'right';
																							|it = 'a destra';
																							|pl = 'prawe';
																							|tr = 'sağ'"))+" ",Parameter.Presentation),,
						Parameter.AttributeValue+IndexOf,,
						Cancel);
				EndIf;
			EndDo;
			
			If ThisObject[Parameter.AttributeValue+"1"] <> Undefined
				And ThisObject[Parameter.AttributeValue+"2"] <> Undefined
				And ThisObject[Parameter.AttributeValue+"1"] > ThisObject[Parameter.AttributeValue+"2"] Then
				Common.MessageToUser(
					StrTemplate(TemplateInvalidInterval,Parameter.Presentation),,
					Parameter.AttributeValue+"1",,
					Cancel);
			EndIf;
			
		Else
			
			If Parameter.FillingIsMandatory And Not ValueIsFilled(ThisObject[Parameter.AttributeValue]) Then
				Common.MessageToUser(
					StrTemplate(TemplateNotFilledIn,"",Parameter.Presentation),,
					Parameter.AttributeValue,,
					Cancel);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearSpecificationAssignmentParameters()
	
	If AssignmentParameters.Count() = 0 Then
		Return;
	EndIf;
	
	DeleteBankingDetails = New Array;
	DeleteItems  = New Array;
	For Each Parameter In AssignmentParameters Do
		
		DeleteItems.Add("Group"+Parameter.Id);
		DeleteBankingDetails.Add(Parameter.AttributeUse);
		DeleteBankingDetails.Add(Parameter.AttributeCondition);
		DeleteBankingDetails.Add(Parameter.AttributeValue);
		If Parameter.IntervalIsAvailable Then
			DeleteItems.Add("IntervalGroup"+Parameter.Id);
			DeleteBankingDetails.Add(Parameter.AttributeValue+"1");
			DeleteBankingDetails.Add(Parameter.AttributeValue+"2");
		EndIf;
		
	EndDo;
	
	ChangeAttributes(,DeleteBankingDetails);
	
	CommonClientServer.SupplementArray(DeleteItems, DeleteBankingDetails);
	
	For Each TagName In DeleteItems Do
		Item = Items.Find(TagName);
		If Item <> Undefined Then
			Items.Delete(Item);
		EndIf;
	EndDo;
	
	AssignmentParameters.Clear();
	
EndProcedure

&AtServer
Procedure CreateDetailsOfSpecificationAssignmentParametersForm()
	
	Attributes = New Array;
	
	TypesArray = New Array;
	TypesArray.Add("Date");
	TypesArray.Add("Number");
	
	TypeOfValuePropsCompared = New TypeDescription(TypesArray);
	
	TypesArray.Add("AnyRef");
	TypesArray.Add("ValueList");
	TypesArray.Add("Boolean");
	TypesArray.Add("String");
	
	TypeOfValueSPropsIsGeneral        = New TypeDescription(TypesArray);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	T.Attribute.Title AS Title
	|INTO
	|	FullPresentation
	|FROM
	|	InformationRegister.BOMAssignmentParameters AS T
	|WHERE
	|	T.Attribute <> VALUE(ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.EmptyRef)
	|GROUP BY
	|	T.Attribute.Title
	|HAVING
	|	COUNT(1) > 1
	|
	|INDEX BY
	|	Title
	|;
	|
	|SELECT
	|	T.ParameterKind                                  AS ParameterKind,
	|	T.Attribute                                      AS Attribute,
	|	T.Attribute.ValueType                          AS PropsValueType,
	|	(NOT FullPresentation.Title IS NULL)    AS FullPresentation
	|FROM
	|	InformationRegister.BOMAssignmentParameters AS T
	|
	|		LEFT JOIN FullPresentation AS FullPresentation
	|		ON T.Attribute.Title = FullPresentation.Title
	|
	|ORDER BY
	|	T.Priority DESC";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewParameter1 = AssignmentParameters.Add();
		NewParameter1.ParameterKind     = Selection.ParameterKind;
		NewParameter1.Attribute         = ?(ValueIsFilled(Selection.Attribute), Selection.Attribute, Selection.ParameterKind);
		NewParameter1.ValueType      = ProductDataManagementClientServer.TypeOfValueOfDestinationParameter(
												Selection.ParameterKind,
												Selection.PropsValueType);
		NewParameter1.Presentation    = ProductDataManagement.PresentationOfDestinationParameter(
												Selection.ParameterKind,
												Selection.Attribute,
												Selection.FullPresentation);
		NewParameter1.IntervalIsAvailable = ProductDataManagementClientServer.IntervalOfDestinationParameterIsAvailable(
												NewParameter1.ValueType);
		
		Id = "DestinationParameter_"+AssignmentParameters.Count();
		
		NewParameter1.Id         = Id;
		NewParameter1.AttributeUse = Id+"_Use";
		NewParameter1.AttributeCondition       = Id+"_Condition";
		NewParameter1.AttributeValue      = Id+"_Value";
		
		Attributes.Add(New FormAttribute(NewParameter1.AttributeUse, New TypeDescription("Boolean"),,,True));
		Attributes.Add(New FormAttribute(NewParameter1.AttributeCondition,       New TypeDescription("String"),,,True));
		Attributes.Add(New FormAttribute(NewParameter1.AttributeValue,      TypeOfValueSPropsIsGeneral,,,True));
		
		If NewParameter1.IntervalIsAvailable Then
			Attributes.Add(New FormAttribute(NewParameter1.AttributeValue+"1", TypeOfValuePropsCompared,,,True));
			Attributes.Add(New FormAttribute(NewParameter1.AttributeValue+"2", TypeOfValuePropsCompared,,,True));
		EndIf;
		
	EndDo;
	
	ChangeAttributes(Attributes);
	
EndProcedure

&AtServer
Procedure CreateFormElementsForSpecificationAssignmentParameters()
	
	For Each Parameter In AssignmentParameters Do
		
		// usage element
		Item = Items.Add(Parameter.AttributeUse, Type("FormField"), Items.LeftPurposeParameters);
		Item.Type = FormFieldType.CheckBoxField;
		Item.DataPath = Parameter.AttributeUse;
		Item.Title = Parameter.Presentation;
		Item.TitleLocation = FormItemTitleLocation.Right;
		
		Item.SetAction("OnChange", "Attachable_UsingDestinationParameterWhenChanging");
		
		// parameter group
		DestinationParameterGroup = Items.Add("Group"+Parameter.Id, Type("FormGroup"), Items.RightPurposeParameters);
		DestinationParameterGroup.Type = FormGroupType.UsualGroup;
		DestinationParameterGroup.Group = ChildFormItemsGroup.Horizontal;
		DestinationParameterGroup.Representation = UsualGroupRepresentation.None;
		DestinationParameterGroup.ShowTitle = False;
		DestinationParameterGroup.EnableContentChange = False;
		
		// condition element
		Item = Items.Add(Parameter.AttributeCondition, Type("FormField"), DestinationParameterGroup);
		Item.Type = FormFieldType.InputField;
		Item.DataPath = Parameter.AttributeCondition;
		Item.TitleLocation = FormItemTitleLocation.None;
		Item.TextEdit = False;
		Item.ListChoiceMode = True;
		Item.Width = 14;
		Item.HorizontalStretch = False;
		Item.DropListButton = True;
		
		Item.SetAction("OnChange", "Attachable_ConditionOfDestinationParameterWhenChanging");
		Item.SetAction("Clearing"     , "Attachable_ConditionOfDestinationParameterCleanup");
		
		FillInConditionItemSelectionList(Item.ChoiceList, Parameter.ValueType);
		
		// value element
		Item = Items.Add(Parameter.AttributeValue, Type("FormField"), DestinationParameterGroup);
		Item.Type = FormFieldType.InputField;
		Item.DataPath = Parameter.AttributeValue;
		Item.TitleLocation = FormItemTitleLocation.None;
		Item.Width = 32;
		Item.HorizontalStretch = False;
		Item.ChoiceButton   = True;
		Item.ClearButton  = True;
		Item.OpenButton = False;
		
		Item.SetAction("OnChange", "Attachable_ValueOfDestinationParameterWhenChanging");
		
		ItemSelectionOptions_ = New Array;
		If Parameter.ParameterKind = Enums.TypesOfBOMAssignmentParameters.ProductionDispatcherBusinessUnit Then
			ItemSelectionOptions_.Add(New ChoiceParameter("Filter.ProductionDispatcherBusinessUnit",True));
		ElsIf Parameter.ParameterKind = Enums.TypesOfBOMAssignmentParameters.LineOfBusiness Then
			ItemSelectionOptions_.Add(New ChoiceParameter("Filter.Status", Enums.LineOfBusinessStatuses.Used));
			ItemSelectionOptions_.Add(New ChoiceParameter("Filter.CostAccounting", True));
		ElsIf Parameter.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues")) Then
			ItemSelectionOptions_.Add(New ChoiceParameter("Filter.Owner", Parameter.Attribute));
		EndIf;
		Item.ChoiceParameters = New FixedArray(ItemSelectionOptions_);
		
		// interval elements
		If Parameter.IntervalIsAvailable Then
			
			IntervalGroup = Items.Add("IntervalGroup"+Parameter.Id, Type("FormGroup"), DestinationParameterGroup);
			IntervalGroup.Type = FormGroupType.UsualGroup;
			IntervalGroup.Group = ChildFormItemsGroup.Horizontal;
			IntervalGroup.Representation = UsualGroupRepresentation.None;
			IntervalGroup.ShowTitle = False;
			IntervalGroup.HorizontalSpacing = FormItemSpacing.Half;
			IntervalGroup.EnableContentChange = False;
			
			For IndexOf = 1 To 2 Do
				
				Item = Items.Add(Parameter.AttributeValue+IndexOf, Type("FormField"), IntervalGroup);
				Item.Type = FormFieldType.InputField;
				Item.DataPath = Parameter.AttributeValue+IndexOf;
				Item.TitleLocation = FormItemTitleLocation.None;
				Item.Width = 14;
				Item.HorizontalStretch = False;
				Item.ChoiceButton   = True;
				Item.ClearButton  = True;
				
				Item.SetAction("OnChange", "Attachable_ValueOfDestinationParameterWhenChanging");
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInValuesOfSpecificationAssignmentParameters()
	
	DestinationParameterValues = Catalogs.BillsOfMaterials.ValuesOfBOMAssignmentParameters(
		CommonClientServer.ValueInArray(Object.Ref)).Get(Object.Ref);
	
	TheStructureOfTheSearch = New Structure("ParameterKind,Attribute");
	
	For Each Parameter In AssignmentParameters Do
		
		Condition = PurposeParametersConditions["Equal"]; // See ProductDataManagementClientServer.StructureOfSelectionConditionByProductProperties
		
		DetailsOfValues = New Structure("Value", Parameter.ValueType.AdjustValue(Undefined));
		If Parameter.IntervalIsAvailable Then
			DetailsOfValues.Insert("Value1", Parameter.ValueType.AdjustValue(Undefined));
			DetailsOfValues.Insert("Value2", Parameter.ValueType.AdjustValue(Undefined));
		EndIf;
		
		TheStructureOfTheSearch.ParameterKind = Parameter.ParameterKind;
		TheStructureOfTheSearch.Attribute     = ?(Parameter.ParameterKind = Parameter.Attribute,
			ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.EmptyRef(), Parameter.Attribute);
		
		FoundRows = DestinationParameterValues.FindRows(TheStructureOfTheSearch);
		If ValueIsFilled(FoundRows) Then
			
			ParameterValue = FoundRows[0].ValueStructure;
			
			Condition = ParameterValue.Condition; // See ProductDataManagementClientServer.StructureOfSelectionConditionByProductProperties
			
			If Condition.List Then
				DetailsOfValues.Value = New ValueList;
				DetailsOfValues.Value.ValueType = Parameter.ValueType;
				DetailsOfValues.Value.LoadValues(ParameterValue.Value.UnloadValues());
			Else
				For Each KeyAndValue In DetailsOfValues Do
					DetailsOfValues[KeyAndValue.Key] = Parameter.ValueType.AdjustValue(ParameterValue[KeyAndValue.Key]);
				EndDo;
			EndIf;
			
			ThisObject[Parameter.AttributeUse] = True;
			
		Else
			
			ThisObject[Parameter.AttributeUse] = False;
			
		EndIf;
		
		ThisObject[Parameter.AttributeCondition] = Condition.Id;
		For Each KeyAndValue In DetailsOfValues Do
			ThisObject[Parameter.Id+"_"+KeyAndValue.Key] = KeyAndValue.Value;
		EndDo;
		
		UpdateWhetherDestinationParameterMustBeFilledIn(Parameter, Condition, Parameter.ValueType);
		
		ConfigureDestinationParameterElements(ThisObject, Parameter);
		
	EndDo;
	
EndProcedure

// Fills in the list of conditions to select
// 
// Parameters:
// 	ChoiceList - ValueList of String - selection list to fill in
// 	ValueType - TypeDescription - Value type
&AtServer
Procedure FillInConditionItemSelectionList(ChoiceList, ValueType)
	
	If PurposeParametersConditions = Undefined Then
		
		PurposeParametersConditions = ProductDataManagementClientServer.StructureOfSelectionConditionsByProductProperties();
		
	EndIf;
	
	For Each KeyAndValue In PurposeParametersConditions Do
		Condition = KeyAndValue.Value; // See ProductDataManagementClientServer.StructureOfSelectionConditionByProductProperties
		If Condition.Comparison 
			And Not ValueType.ContainsType(Type("Number"))
			And Not ValueType.ContainsType(Type("Date"))
		Then
			Continue;
		EndIf;
		ChoiceList.Add(Condition.Id, Condition.Presentation);
	EndDo;
	
EndProcedure

// Configures the specification assignment parameter element
// 
// Parameters:
// 	Form - ClientApplicationForm - Form
// 	Parameter - FormDataCollectionItem - destination parameter data
//
&AtClientAtServerNoContext
Procedure ConfigureDestinationParameterElements(Form, Parameter)
	
	Items = Form.Items; // FormAllItems
	
	GroupItem = Items["Group"+Parameter.Id]; // FormGroup
	GroupItem.Enabled = Form[Parameter.AttributeUse];
	
	Condition = Form.PurposeParametersConditions[Form[Parameter.AttributeCondition]];
	
	ValueTypeParameter = AdjustedTypeOfAssignmentParameterByCondition(Parameter.ValueType, Condition);
	
	If Condition.Interval Then
		
		For IndexOf = 1 To 2 Do
			ValueElement = Items[Parameter.AttributeValue+IndexOf]; // TextBox
			ValueElement.TypeRestriction           = ValueTypeParameter;
			ValueElement.AutoMarkIncomplete = Parameter.FillingIsMandatory;
		EndDo;
		
	Else
		
		ValueElement = Items[Parameter.AttributeValue]; // TextBox
		ValueElement.Enabled               = Not Condition.Fullness;
		ValueElement.AutoMarkIncomplete = Parameter.FillingIsMandatory;
		
		If Condition.List Then
			ValueElement.TypeRestriction = New TypeDescription("ValueList");
		Else
			ValueElement.TypeRestriction = ValueTypeParameter;
		EndIf;
		
	EndIf;
	
	If Parameter.IntervalIsAvailable Then
		Items[Parameter.AttributeValue].Visible               = Not Condition.Interval;
		Items["IntervalGroup"+Parameter.Id].Visible = Condition.Interval;
	EndIf;
	
EndProcedure

&AtServer
Procedure AddDestinationParameterToRecordset(RecordSet, BillOfMaterials, Parameter, Condition, Value, NumberInList = 0)
	
	SetRecord = RecordSet.Add();
	
	SetRecord.BillOfMaterials = BillOfMaterials;
	SetRecord.ParameterKind = Parameter.ParameterKind;
	SetRecord.Attribute     = Parameter.Attribute;
	SetRecord.Condition      = Condition;
	SetRecord.Value     = Value;
	SetRecord.NumberInList = NumberInList;
	
EndProcedure

&AtClientAtServerNoContext
Function AdjustedTypeOfAssignmentParameterByCondition(ParameterType, Condition = Undefined)
	
	If Not ValueIsFilled(Condition) Then
		Return ParameterType;
	EndIf;
	
	If Not Condition.Comparison Then
		Return ParameterType;
	EndIf;
	
	Return ParameterTypeWithoutNonEquatableTypes(ParameterType);
	
EndFunction

&AtClientAtServerNoContext
Function ParameterTypeWithoutNonEquatableTypes(ParameterType)
	
	RemovedTypes = New Array;
	For Each Type In ParameterType.Types() Do
		If Not Type = Type("Date") And Not Type = Type("Number") Then
			RemovedTypes.Add(Type);
		EndIf;
	EndDo;
	
	Return New TypeDescription(ParameterType,,RemovedTypes);
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateHeaderOfDestinationParameterGroup(Form)
	
	GroupVisibility = (Form.AssignmentParameters.Count() > 0);
	If GroupVisibility <> Form.Items.GroupAssignmentParametersHeader.Visible Then
		Form.Items.GroupAssignmentParametersHeader.Visible = GroupVisibility;
	EndIf;
	
	If Not GroupVisibility Then
		Return;
	EndIf;
	
	Use = 0;
	For Each Parameter In Form.AssignmentParameters Do
		Use = Use + ?(Form[Parameter.AttributeUse],1,0);
	EndDo;
	
	Form.PurposeParametersText =
		StrTemplate("%1%2", NStr("vi = 'Tùy chọn đích';
								|ru = 'Параметры назначения';
								|en = 'Assignment parameters'; fa = 'پارامترهای تخصیص';
								|it = 'Parametri di assegnazione';
								|pl = 'Parametry przeznaczenia';
								|tr = 'Atama parametreleri'"), ?(Use > 0," ("+Use+")", ""));
	
EndProcedure
	
&AtClientAtServerNoContext
Procedure UpdateWhetherDestinationParameterMustBeFilledIn(Parameter, Condition, ValueTypeParameter)
	
	Parameter.FillingIsMandatory =
		ProductDataManagementClientServer.FillingInValueOfDestinationParameterIsMandatory(Condition, ValueTypeParameter);
	
EndProcedure

#EndRegion

#Region AutoSelection_SelectionByProperties_CalculationOfQuantity

&AtClient
Procedure ProcessingSelectionSettingUpAutomaticSelectionOfProducts(TSName, ValueSelected)
	
	CurrentData = Items[TSName].CurrentData;
	
	MethodOfProductsAutoselection = CurrentData.MethodOfProductsAutoselection;
	
	If ProductDataManagementClient.ConfigureProductsAutoselectionCompletion(
			ValueSelected,
			CurrentData,
			Object.PropertyMapping) Then
			
		If MethodOfProductsAutoselection <> CurrentData.MethodOfProductsAutoselection Then
			
			If TSName = "MaterialsAndServices" Then
				CheckDefaultMethodForGettingContent(CurrentData);
				FillInAttributeSeparatelyInContentLine(CurrentData);
				FillInProduceAttributeInMaterialsLine(ThisObject, CurrentData);
			ElsIf TSName = "ManufacturedProducts" Then
				ClearProcessBySpecificationSetting(CurrentData);
			ElsIf TSName = "RecyclableWaste" Then
				ClearProcessBySpecificationSetting(CurrentData);
			EndIf;
			
		EndIf;
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		StructureOfActions.Insert("FillInSeriesAttribute", New Structure("Products", "SeriesAreUsed"));
		
		If TSName = "ManufacturedProduct" Or TSName = "ManufacturedProducts" Or TSName = "MaterialsAndServices" Then
			StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		EndIf;
		
		If TSName = "ManufacturedProduct" Or TSName = "ManufacturedProducts" Then
			StructureOfActions.Insert("FillInProductTypeAttribute", New Structure("Products", "ProductKind"));
			StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
			CalculatePercentageOfCostAllocationForOutputProducts();
		Else
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		EndIf;
		
		If TSName = "MaterialsAndServices" Then
			ProductDataManagementClientServer.FillInInformationOnUseOfMaterial(CurrentData);
		EndIf;
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionProcessingSettingUpSelectionByPropertiesAndCalculationByFormulas(TSName, ValueSelected)
	
	CurrentData = Items[TSName].CurrentData;
	
	SelectionByProperties = ?(TSName = "StageTypesOfWorkCenters",
		ProductionProcessStage.SelectionByProperties,
		Object.SelectionByProperties);
	
	If ProductDataManagementClient.ConfigureSelectionByPropertiesAndCalculationByFormulasCompletion(
		ValueSelected,
		CurrentData,
		SelectionByProperties) Then
		
		If TSName = "ManufacturedProduct" Or TSName = "ManufacturedProducts" Then
			If TypeOf(ValueSelected) = Type("Structure")
					And ValueSelected.Property("QuantityCalculationAlgorithm")
					And Not IsBlankString(ValueSelected.QuantityCalculationAlgorithm) Then
					
				CurrentData.Count = 0;
				CurrentData.NumberOfPackages = 0;
				If Object.MethodOfAllocatingFinishedProductCosts <> PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares") Then
					CurrentData.CostShare = 0;
				EndIf;
				
			EndIf;
			CalculatePercentageOfCostAllocationForOutputProducts();
		EndIf;
		
		If TSName = "StageTypesOfWorkCenters" Then
			TypesOfWorkCentersRecalculateWorkingHours(CurrentData);
			CalculateStageDuration();
		EndIf;
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(
	CurrentData, TSName, SelectionByPropertiesSource = Undefined, CompositionOfSettings = Undefined)
	
	MainProductSpecifications = CheckGetMainProductSpecifications();
	If MainProductSpecifications.IsEmpty() Then
		Return;
	EndIf;
	
	AddressInStorage = PutDataForCalculationByFormulasInRepository(TSName);
	
	SelectionByProperties = ProductDataManagementClient.DetailsOfSettingsByLineInArray(
		CurrentData,
		?(SelectionByPropertiesSource = Undefined, Object.SelectionByProperties, SelectionByPropertiesSource),
		ProductDataManagementClientServer.DetailsSettingUpSelectionByProperties());
	
	ProductDataManagementClient.ConfigureSelectionByPropertiesAndCalculationByFormulas(
						ThisObject,
						TSName,
						SelectionByProperties,
						MainProductSpecifications,
						Not AttributeAvailability,
						CompositionOfSettings,
						AddressInStorage);
	
EndProcedure

&AtServer
Function PutDataForCalculationByFormulasInRepository(TableName)
	
	TSName = StrReplace(Items[TableName].DataPath,"Object.","");
	
	CurrentRow = ?(TableName = "StageTypesOfWorkCenters", Undefined, Object[TSName].FindByID(Items[TableName].CurrentRow));
	
	DataForCalculation = Catalogs.BillsOfMaterials.UploadDataForFormulaConstructor(
		Object,
		TSName,
		CurrentRow);
	
	Result = PutToTempStorage(DataForCalculation, UUID);
	Return Result;
	
EndFunction

#EndRegion

#Region ManufacturingProcess

&AtServer
Procedure WhenChangingStructureOfProductionProcess()
	
	If Not Object.MultiStageProductionProcess Then
		For Each String In Object.MaterialsAndServices Do
			If String.ProducedInProcess Then
				If String.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage")
					Or ValueIsFilled(String.PlanNotEarlierThan) Then
					ProductDataManagementClientServer.FillInDefaultMethodForGettingMaterial(String);
					FillInAttributeSeparatelyInContentLine(String);
					FillInDefaultCostingArticle(String);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	FillInServiceDetails();
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Function RequiredToClearPropsWhenChangingReleaseBatchDescription(AttributesList)
	
	If Not Object.ProductionIssueByCustomPortions Then
		
		If Object.MinimumReleaseLot <> 0 Then
			AttributesList.Add(NStr("vi = '''''Xuất xưởng tối thiểu''''';
									|ru = '""Минимальный выпуск""';
									|en = '""Minimum release""'; fa = '""Minimum release""';
									|it = '""Produzione minima""';
									|pl = '""Minimalne wydanie""';
									|tr = '""Minimum ürün çıkışı""'"));
		EndIf;
		
		If Object.EconomicReleaseLot <> 0 Then
			AttributesList.Add(NStr("vi = '''Xuất xưởng tối ưu''''';
									|ru = '""Оптимальный выпуск""';
									|en = '""Optimal release""'; fa = '""Optimal release""';
									|it = '""Produzione ottimale""';
									|pl = '""Optymalne wydanie""';
									|tr = '""Optimum ürün çıkışı""'"));
		EndIf;
		
		If Object.PermissibleExcessOfOptimalReleaseLot <> 0 Then
			AttributesList.Add(NStr("vi = '""Vượt quá mức cho phép của đợt xuất xưởng tối ưu""';
									|ru = '""Допустимое превышение оптимальной партии выпуска""';
									|en = '""Permissible excess of the economic release lot""'; fa = '""Permissible excess of the economic release lot""';
									|it = '""Eccesso ammissibile del lotto di rilascio ottimale""';
									|pl = '""Dopuszczalne przewyższenie optymalnej partii produkcji""';
									|tr = '""Optimum ürün çıkış lotunun kabul edilebilir aşımı""'"));
		EndIf;
		If RequiredToClearPropsSimultaneouslyProducedQuantity(Object.Ref) Then
			AttributesList.Add(NStr("vi = '""Số lượng sản xuất đồng thời""';
									|ru = '""Одновременно производимое количество""';
									|en = '""Simultaneously manufactured quantity""'; fa = '""Simultaneously manufactured quantity""';
									|it = '""Quantità prodotta simultaneamente""';
									|pl = '""Ilość produkowana jednocześnie""';
									|tr = '""Eş zamanlı üretim miktarı""'"));
		EndIf;
	EndIf;
	
	Return AttributesList.Count() > 0;
	
EndFunction
&AtServerNoContext
Function RequiredToClearPropsSimultaneouslyProducedQuantity(BillOfMaterials)
	
	If BillOfMaterials.IsEmpty() Then
		Return False;
	EndIf;
	
	StageList = Catalogs.ProductionStages.ListOfStagesForWhichSimultaneouslyProducedQuantityIsSpecified(BillOfMaterials);
	Return StageList.Count() > 0;
	
EndFunction
&AtClient
Procedure ClearDetailsWhenChangingReleaseBatchDescription(QuestionResult, AdditionalParameters) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Object.ProductionIssueByCustomPortions = ReleaseInCustomPortionsBeforeChange;
		Return;
	EndIf;
	ClearDetailsWhenChangingReleaseBatchDescriptionOnServer();
	
EndProcedure

&AtServer
Procedure ClearDetailsWhenChangingReleaseBatchDescriptionOnServer()
	ProcedureName = "Catalogs.ProductionStages.ClearPropsSimultaneouslyProducedQuantity";
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	
	TimeConsumingOperations.ExecuteInBackground(ProcedureName, Object.Ref, ExecutionParameters);
	If Object.MinimumReleaseLot <> 0 Then
		Object.MinimumReleaseLot = 0;
	EndIf;
	
	If Object.EconomicReleaseLot <> 0 Then
		Object.EconomicReleaseLot = 0;
	EndIf;
	
	If Object.PermissibleExcessOfOptimalReleaseLot <> 0 Then
		Object.PermissibleExcessOfOptimalReleaseLot = 0;
	EndIf;
	
	FillInReleaseBatchDescription();
	ConfigureDependentFormElements(ThisObject, "ProductionIssueByCustomPortions,MinimumReleaseLot,EconomicReleaseLot");
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceOfProductionProcess()
	
	// Technological process
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturingProcess.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ManufacturingProcess.ReadOnly");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
	// Operation number
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturingProcessNumber.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturingProcessTheNumberOfTheNextOne.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ManufacturingProcess.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = TypeOfElementOfOperation();
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightGray);
	
	// work center
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturingProcessWorkCenter.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ManufacturingProcess.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = TypeOfElementOfOperation();
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
	// Types of work centers
	ProductDataManagement.EstablishConditionalAppearanceOfSelectionByPropertiesAndCalculationByFormulas(
		ThisObject, "", "StageTypesOfWorkCenters", "OperationTime");
	ProductionProcessEditor.EstablishConditionalAppearanceTypesOfWorkCenters(
		ThisObject, "StageTypesOfWorkCenters");
	ProductionProcessEditor.SetConditionalAppearanceOfBankingDetailsForSynchronousUploading(
		ThisObject, "StageTypesOfWorkCenters", "ProductionProcessStage", "Stage");
		
	// The invested work on the R&M
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturingProcessDescription.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ManufacturingProcess.ItemKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = TypeOfWorkElement();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ManufacturingProcess.Description");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chỉ định công việc>';
													|ru = '<укажите работу>';
													|en = '<specify work>'; fa = '<specify work>';
													|it = '<specify work>';
													|pl = '<specify work>';
													|tr = '<işi belirtin>'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
	// Processing
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject,
		"ProcessorServiceStageCharacteristics",
		"ProductionProcessStage.SubcontractorServices.ItemVariantsAreUsed");
	
EndProcedure

&AtServer
Procedure CustomizeProductionProcessElements()
	
	OperationsAvailable = (EnterpriseManagement And StoreOperationsInBillsOfMaterials);
	
	Items.ManufacturingProcessAdd.Visible                        = Not OperationsAvailable;
	Items.ProductionProcessContextAdd.Visible                = Not OperationsAvailable;
	Items.ProductionProcessGroupAdd.Visible                  = OperationsAvailable;
	Items.ProductionProcessContextGroupAdd.Visible          = OperationsAvailable;
	Items.ProductionProcessGroupWorkPlanning.Visible         = ThisIsPerformanceOfRepairWork(ThisObject);
	Items.ProductionProcessContextGroupWorkPlanning.Visible = ThisIsPerformanceOfRepairWork(ThisObject);
	If OperationsAvailable Then
		Items.ProductionProcessGroupADivisionOfRTS.Title = NStr("vi = 'Bộ phận / Nguồn lực sản xuất';
																|ru = 'Подразделение / Рабочий центр';
																|en = 'Business unit / Work center'; fa = 'واحد تجاری / مرکز کاری';
																|it = 'Reparto / Centro lavorativo';
																|pl = 'Dział / Centrum wykonania pracy';
																|tr = 'Departman / İş merkezi'");
		For Each KeyAndValue In NamesOfEditingElements() Do
			Items[KeyAndValue.Value].Title = NStr("vi = 'Công đoạn / Thao tác';
													|ru = 'Этап / Операция';
													|en = 'Stage / Operation'; fa = 'Stage / Operation';
													|it = 'Fase / Operazione';
													|pl = 'Etap / Operacja';
													|tr = 'Aşama / İşlem'");
		EndDo;
		For Each KeyAndValue In NamesOfCommandsForSelectingElementOfProductionProcess() Do
			Items[KeyAndValue.Value].Title = NStr("vi = 'Công đoạn / Thao tác';
													|ru = 'Этап / Операция';
													|en = 'Stage / Operation'; fa = 'Stage / Operation';
													|it = 'Fase / Operazione';
													|pl = 'Etap / Operacja';
													|tr = 'Aşama / İşlem'");
		EndDo;
	EndIf;
	DescriptionOfElementProperties_ = ProductionProcessCache.DescriptionOfElementProperties_; // Map
	
	For Each ItemKind In ProductionProcessEditorClientServer.ItemsKinds() Do
		ItemsProperties = DescriptionOfElementProperties_.Get(ItemKind);
		If ItemsProperties.ContainsObject Then
			For Each AdditionalDetailsElement In ItemsProperties["AdditionalDetailsElements"] Do
				Items[AdditionalDetailsElement].Visible = ProductionProcessCache[ItemsProperties["UseAddlAttributes"]];
			EndDo;
		EndIf;
	EndDo;
	
	Items.TheProductionProcessForMoreInformation.Visible = GetFunctionalOption("UseAdditionalAttributesAndInfo");
	
	UseTechnologicalProcesses = False;
	UseTechnologicalProcesses = GetFunctionalOption("UseTechnologicalProcesses");
	ItemArray = New Array;
	ItemArray.Add("ProductionProcessAddAGroupOfOperations");
	ItemArray.Add("ProductionProcessContextAddGroupOfOperations");
	ItemArray.Add("AddATypicalProductionProcess");
	ItemArray.Add("ProductionProcessContextAddTypical");
	ItemArray.Add("ProductionProcessIsDividedIntoTechnologicalProcess");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, ItemArray, "Visible", UseTechnologicalProcesses);
	If ThisIsPerformanceOfRepairWork(ThisObject) Then
		CommandTitle = NStr("vi = 'Công đoạn sản xuất';
							|ru = 'Этап производства';
							|en = 'Production stage'; fa = 'مرحله تولید';
							|it = 'Fase di produzione';
							|pl = 'Etap produkcji';
							|tr = 'Üretim aşaması'");
		Items.ProductionProcessIsToAddAPhase.Title = CommandTitle;
		Items.ProductionProcessContextAddStage.Title = CommandTitle;
	EndIf;
	EstablishAvailabilityOfProductionProcessElements();
	
EndProcedure

&AtServer
Procedure EstablishAvailabilityOfProductionProcessElements()
	
	AvailabilityOfPPDetails = AttributeAvailability And ProductionProcessRead;
	
	Items.ManufacturingProcess.ChangeRowSet = AvailabilityOfPPDetails;
	
	ItemArray = New Array;
	ItemArray.Add("ProductionProcessIsToAddAPhase");
	ItemArray.Add("ProductionProcessContextAddStage");
	ItemArray.Add("ProductionProcessAddWorkPlanning");
	ItemArray.Add("ProductionProcessContextAddWorkPlanning");
	ItemArray.Add("ProductionProcessAddWork");
	ItemArray.Add("ProductionProcessContextAddWork");
	ItemArray.Add("ProductionProcessIsToMoveUp");
	ItemArray.Add("ProductionProcessMoveDown");
	ItemArray.Add("ProductionProcessFillInDivision");
	ItemArray.Add("OutputProducts_FillInStage");
	ItemArray.Add("ReturnableWasteFillStage");
	ItemArray.Add("MaterialsAndServicesFillOutTheStage");
	ItemArray.Add("LaborCostsCompleteTheStage");
	ItemArray.Add("ProductionProcessAddOperation");
	ItemArray.Add("ProductionProcessContextAddOperation");
	ItemArray.Add("ProductionProcessAddAGroupOfOperations");
	ItemArray.Add("ProductionProcessContextAddGroupOfOperations");
	ItemArray.Add("AddATypicalProductionProcess");
	ItemArray.Add("ProductionProcessContextAddTypical");
	ItemArray.Add("ProductionProcessToPickUpByWHO");
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, ItemArray, "Enabled",
		AvailabilityOfPPDetails);
	ItemArray = New Array;
	ItemArray.Add("ProductionProcessIsDividedIntoTechnologicalProcess");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, ItemArray, "Enabled",
		ProductionProcessRead And AccessRight("Update", Metadata.Catalogs.TechnologicalProcesses));
EndProcedure

&AtServer
Procedure StartFillingProductionProcess()
	
	ProductionProcessInitializeCache();
	
	If Not ValueIsFilled(Object.Ref) Then
		ProductionProcessRead = True;
		ProductionProcessUpdateDashboards();
		Return;
	EndIf;
	
	ProductionProcessTree = FormAttributeToValue("ManufacturingProcess"); // ValueTree
	ProductionProcessTree.Rows.Clear();
	
	IsFileInfobase = Common.FileInfobase();
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunNotInBackground1            = ProductionProcessRead Or IsFileInfobase;
	ExecutionParameters.RunInBackground              = Not ProductionProcessRead And Not IsFileInfobase;
	ExecutionParameters.WaitCompletion           = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Điền cây quy trình sản xuất.';
														|ru = 'Заполнение дерева производственного процесса.';
														|en = 'Production process tree population.'; fa = 'Production process tree population.';
														|it = 'Compilazione dell''albero del processo di produzione.';
														|pl = 'Wypełnienie drzewa procesu produkcyjnego.';
														|tr = 'Üretim süreci ağacının doldurulması.'");
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("BillOfMaterials", Object.Ref);
	ProcedureParameters.Insert("ProductionProcessTree", ProductionProcessTree);
	
	ProductionProcessLongOperation = TimeConsumingOperations.ExecuteInBackground(
		"ProductionProcessEditor.StructureOfProductionProcessInBackground",
		ProcedureParameters,
		ExecutionParameters);
		
	If ProductionProcessLongOperation.Status <> "Running" Then
		
		ProcessResultOfFillingProductionProcess(ProductionProcessLongOperation);
		ProductionProcessLongOperation = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StartWaitingForProductionProcessToFill()
	
	If ProductionProcessLongOperation <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"StartWaitingForProductionProcessToFillCompletion",
			ThisObject);
			
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
			
		TimeConsumingOperationsClient.WaitCompletion(
			ProductionProcessLongOperation,
			CallbackDescription,
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StartWaitingForProductionProcessToFillCompletion(Result, AdditionalParameters) Export
	
	PerformanceMonitorClient.TimeMeasurement(
		"Catalog.BillsOfMaterials.Form.ItemForm.StartWaitingForProductionProcessToFillCompletion");
	
	ProductionProcessLongOperation = Undefined;
	
	If Result <> Undefined Then
		ProcessResultOfFillingProductionProcess(Result);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultOfFillingProductionProcess(Result)
	
	If Not Result.Status = "Completed2" Then
		Return;
	EndIf;
	
	ResultData = GetFromTempStorage(Result.ResultAddress);
	
	If ValueIsFilled(ResultData) Then
		
		ValueToFormAttribute(ResultData.ProductionProcessTree, "ManufacturingProcess");
		
		ArrayOfDivisions = ResultData.ArrayOfDivisions; // Array
		If ValueIsFilled(ArrayOfDivisions) Then
			ProductionProcessCache.UnitParameters =
				ProductionServer.ParametersOfProductionUnits(ArrayOfDivisions);
		EndIf;
		FillPropertyValues(ProductionProcessCache, ResultData);
		
		ProductionProcessRead = True;
		DisplayWorksInProductionProcessTree();
		FillPropertyValues(ThisObject, DescriptionManufacturingProcess());
		
		EstablishAvailabilityOfProductionProcessElements();
		
		ProductionProcessUpdateDashboards();
		
		ConfigureDependentFormElements(ThisObject, "ManufacturingProcess");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckFillingOfProductionProcess(Cancel = False)
	
	If Not ProductionProcessRead
			Or ThisIsTechnologicalSet(ThisObject) Then
		Return;
	EndIf;
	
	RowsStages             = ManufacturingProcess.GetItems();
	Messages               = New Array;
	ArrayOfStages            = New Array;
	ArrayOfStagesOnSide   = New Array;
	StageVerificationTable   = Undefined;
	OperationVerificationTable = Undefined;
	SpecificationStatus_      = ?(StatusCheckModeIsValid, Enums.BOMStatuses.Valid, Object.Status);
	
	If SpecificationStatus_ = Enums.BOMStatuses.Valid Then
		If RowsStages.Count() = 0 Then
			MessageText = NStr("vi = 'Cần tạo công đoạn sản xuất.';
								|ru = 'Необходимо создать этап производства.';
								|en = 'Create a production stage.'; fa = 'Create a production stage.';
								|it = 'È necessario creare una fase di produzione.';
								|pl = 'Należy utworzyć etap produkcji.';
								|tr = 'Üretim aşamasının oluşturulması gerekmektedir.'");
			Common.MessageToUser(MessageText,,,,Cancel);
			Return;
		ElsIf RowsStages.Count() > 1
				And Not ProductDataManagementClientServer.MultiStageProductionProcessIsAvailable()
				And Not SpecificationStatus_ = SavedObjectStatus Then
			MessageText = ProductDataManagementClientServer.MultiStageProductionProcessErrorText();
			Common.MessageToUser(MessageText,,,,Cancel);
			Return;
		EndIf;
		StageVerificationTable   = ProductionProcessEditor.TableOfVerificationOfOrderOfElementsOfProductionProcessDesigner();
		OperationVerificationTable = ProductionProcessEditor.TableOfVerificationOfOrderOfElementsOfProductionProcessDesigner();
	EndIf;
	
	ElementCache_ = ProductionProcessGetCacheItems();
	
	ProductionProcessCacheCurItem(ElementCache_);
	
	For IndexStage = 0 To RowsStages.Count() - 1 Do
			
		StageString = RowsStages[IndexStage];
		
		StageObject = ProductionProcessGetItemCache(ElementCache_, StageString, True).Object; // CatalogObject.ProductionStages
		
		StageObject.AdditionalProperties.Insert("SpecificationStatus_", SpecificationStatus_);
		ProductionProcessEditor.CheckStageDetails(
			StageObject, Cancel, Messages);
		
		DivisionParameters = ProductionProcessGetUnitParameters(ThisObject, StageObject.Department);
		
		If Not StageObject.WorkPlanning Then
			
			OperationLines = StageString.GetItems();
			For IndexOperation = 0 To OperationLines.Count() - 1 Do
				
				LineOperation = OperationLines[IndexOperation];
				
				OperationObject = ProductionProcessGetItemCache(ElementCache_, LineOperation, True).Object; // CatalogObject.ManufacturingOperations
				
				OperationObject.AdditionalProperties.Insert("SpecificationStatus_", SpecificationStatus_);
				ProductionProcessEditor.CheckOperationDetails(
					OperationObject, StageObject, DivisionParameters, Cancel, Messages);
					
				If SpecificationStatus_ <> Enums.BOMStatuses.Valid Then
					Continue;
				EndIf;
				
				NewRow = OperationVerificationTable.Add();
				NewRow.Object                 = OperationObject;
				NewRow.Operation               = LineOperation.Ref;
				NewRow.Presentation          = LineOperation.Description;
				NewRow.OperationNumber          = LineOperation.Number;
				NewRow.NextOperation = LineOperation.TheNumberOfTheNextOne;
				
			EndDo;
			
		EndIf;
		
		If SpecificationStatus_ <> Enums.BOMStatuses.Valid Then
			Continue;
		EndIf;
		
		ArrayOfStages.Add(StageObject);
		
		If StageObject.ProductionByThirdParty Then
			ArrayOfStagesOnSide.Add(StageObject);
		EndIf;
		
		NewRow = StageVerificationTable.Add();
		NewRow.Object                 = StageObject;
		NewRow.Operation               = StageString.Ref;
		NewRow.Presentation          = StageString.Description;
		NewRow.OperationNumber          = StageString.Number;
		NewRow.NextOperation = StageString.TheNumberOfTheNextOne;
		ProductionProcessEditor.CheckOrderOfProductionProcessElements(
			OperationVerificationTable,
			ProductionProcessEditor.StructureOfOperationSequenceChecks(, DivisionParameters),
			Cancel,
			Messages,
			StageObject);
			
		OperationVerificationTable.Clear();
	EndDo;
	
	If SpecificationStatus_ = Enums.BOMStatuses.Valid Then
		
		ObjectSpecification = FormAttributeToValue("Object");
		
		ProductionProcessEditor.CheckOrderOfProductionProcessElements(
			StageVerificationTable,
			ProductionProcessEditor.StructureOfStageSequenceChecks(ObjectSpecification.ProductionProcessType),
			Cancel,
			Messages);
		
		If ArrayOfStagesOnSide.Count() Then
			ProductionProcessEditor.CheckProductionStepsOnSide(
				ArrayOfStagesOnSide, ObjectSpecification, Cancel, Messages);
		EndIf;
		If UseBillOfMaterialsParameterization Then
			ProductionProcessEditor.CheckComplianceOfSelectionByProperties(
				ArrayOfStages, ObjectSpecification, Cancel, Messages);
			ProductionProcessEditor.CheckQuantityCalculationAlgorithm(
				ArrayOfStages, ObjectSpecification, Cancel, Messages);
		EndIf;
		
		If Not StoreOperationsInBillsOfMaterials Then
			ProductionProcessEditor.CheckRouteMapsOfStages(
				ArrayOfStages, Object.ValidOnDate, Object.ValidToDate, Cancel, Messages);
		EndIf;
		
		ObjectSpecification.CheckReverseKittingInStatusValid(Cancel, ArrayOfStages);
		ObjectSpecification.CheckCompletionOfInterimIssueInStatusValid(Cancel);
		ObjectSpecification.CheckCompletionOfWorkInProgressInStatusValid(Cancel, WorksPerformedInTable());
		CommonClientServer.SupplementArray(Messages, GetUserMessages(True));
	EndIf;
	
	ProductionProcessProcessMessagesToUser(Messages);
	
	ProductionProcessSaveCacheItems(ElementCache_);
	
EndProcedure

&AtServer
Procedure ProductionProcessProcessMessagesToUser(UserMessages)
	
	MessagesKeys = New Map;
	
	For Each Message In UserMessages Do
		
		DataKey     = Undefined;
		DataKeyType = TypeOf(Message.DataKey);
		
		If ValueIsFilled(Message.DataKey)
			And (DataKeyType= Type("CatalogRef.ProductionStages")
				Or DataKeyType= Type("CatalogRef.ManufacturingOperations")
				) Then
				
			DataKey = Message.DataKey;
				
		ElsIf ValueIsFilled(Message.DataKey)
			And (DataKeyType= Type("CatalogObject.ProductionStages")
				Or DataKeyType= Type("CatalogObject.ManufacturingOperations")
				) Then
				
			If Message.DataKey.IsNew() Then
				DataKey = Message.DataKey.GetNewObjectRef();
			Else
				DataKey = Message.DataKey.Ref;
			EndIf;
				
		Else
			
			Message.DataKey  = Undefined;
			Message.Field        = "";
			Message.DataPath = "ManufacturingProcess";
			Message.TargetID = UUID;
			Message.Message();
			Continue;
			
		EndIf;
		
		ArrayOfMessages = MessagesKeys.Get(DataKey); // Array
		If ArrayOfMessages = Undefined Then
			ArrayOfMessages = New Array;
			MessagesKeys.Insert(DataKey, ArrayOfMessages);
		EndIf;
		ArrayOfMessages.Add(Message);
		
	EndDo;
	
	Templates = New Map;
	Templates.Insert(TypeOfStageElement(), NStr("vi = '%1 (công đoạn: %2)';
												|ru = '%1 (этап: %2)';
												|en = '%1 (stage: %2)'; fa = '%1 (stage: %2)';
												|it = '%1 (fase: %2)';
												|pl = '%1 (etap: %2)';
												|tr = '%1 (aşama: %2)'"));
	Templates.Insert(TypeOfElementOfOperation(), NStr("vi = '%1 (công đoạn: %2, giao dịch: %3)';
														|ru = '%1 (этап: %2, операция: %3)';
														|en = '%1 (stage: %2, operation: %3)'; fa = '%1 (stage: %2, operation: %3)';
														|it = '%1 (fase: %2, operazione: %3)';
														|pl = '%1 (etap: %2, operacja: %3)';
														|tr = '%1 (aşama: %2, işlem: %3)'"));
	Templates.Insert(TypeOfWorkElement(), NStr("vi = '%1 (công đoạn: %2, công việc: %3)';
												|ru = '%1 (этап: %2, работа: %3)';
												|en = '%1 (stage: %2, work: %3)'; fa = '%1 (stage: %2, work: %3)';
												|it = '%1 (stage: %2, work: %3)';
												|pl = '%1 (stage: %2, work: %3)';
												|tr = '%1 (aşama: %2, iş: %3)'"));
	StageName_2 = Undefined;
	RowData     = Undefined;
	While ProductionProcessIsFollowingElement(ThisObject, RowData) Do
		
		Messages = MessagesKeys.Get(RowData.Ref);
		If Messages <> Undefined Then
			
			MessageTemplate = Templates.Get(RowData.ItemKind);
			
			For Each Message In Messages Do
				
				If RowData.ItemKind = TypeOfStageElement() Then
					StageName_2 = RowData.Description;
					MessageText = ?(StrFind(Message.Text, StageName_2) > 0,
						Message.Text,
						StrTemplate(MessageTemplate, Message.Text, StageName_2));
				Else
					MessageText = StrTemplate(MessageTemplate,
						Message.Text, StageName_2, RowData.Description);
				EndIf;
				
				Message.Text = MessageText;
				Message.DataKey  = Undefined;
				Message.Field        = "";
				Message.DataPath = "ManufacturingProcess";
				Message.TargetID = UUID;
				Message.Message();
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure RecordProductionProcess(Cancel, CurrentObject)
	
	If Not ProductionProcessRead
			Or ThisIsTechnologicalSet(ThisObject) Then
		Return;
	EndIf;
	
	ElementCache_ = ProductionProcessGetCacheItems();
	
	WriteObjects_ = New Structure;
	DeleteObjects  = New Array;
	
	For Each KeyAndValue In ElementCache_ Do
		
		ElementCache = KeyAndValue.Value;
		
		If Not ElementCache.ContainsObject Then
			Continue;
		ElsIf ElementCache.Write
			And Not ElementCache.Removed Then
			
			ObjectsArray = Undefined;
			If Not WriteObjects_.Property(ElementCache.ItemKind, ObjectsArray) Then
				ObjectsArray = New Array;
				WriteObjects_.Insert(ElementCache.ItemKind, ObjectsArray);
			EndIf;
			ObjectsArray.Add(ElementCache.Object);
			
		ElsIf ElementCache.Removed
			And Not (ElementCache.Object <> Undefined And ElementCache.Object.IsNew()) Then
			
			ObjectElement = KeyAndValue.Key.GetObject();
			If ElementCache.ItemKind = TypeOfElementOfOperation() Then
				OwnerCache = ElementCache_.Get(ObjectElement.Owner);
				If OwnerCache <> Undefined And OwnerCache.Removed Then
					Continue;
				EndIf;
			EndIf;
			ObjectElement.AdditionalProperties.Insert("AllowRecording");
			
			DeleteObjects.Add(ObjectElement);
			
		EndIf;
		
	EndDo;
	
	BeginTransaction();
	
	Try
		
		ItemsKinds = ProductionProcessEditorClientServer.ItemsKinds();
		For IndexOf = 0 To ItemsKinds.UBound() Do
			ObjectsArray = Undefined;
			If WriteObjects_.Property(ItemsKinds[IndexOf], ObjectsArray) Then
				For Each ObjectWrite In ObjectsArray Do // CatalogObject.ProductionStages
					ObjectWrite.Write();
				EndDo;
			EndIf;
		EndDo;
		
		For Each ObjectDelete In DeleteObjects Do
			ObjectDelete.SetDeletionMark(True);
		EndDo;
		
		ProductionProcessClearItemCache();
		
		ProductionProcessCurrentLink = Undefined;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		Cancel = True;
		
		WriteLogEvent(
			NStr("vi = 'Không thể ghi lại quy trình sản xuất.';
				|ru = 'Не удалось записать производственный процесс.';
				|en = 'Cannot save production process.'; fa = 'Cannot save production process.';
				|it = 'Non è stato possibile salvare il processo di produzione.';
				|pl = 'Nie udało się zapisać procesu produkcyjnego.';
				|tr = 'Üretim süreci kaydedilemedi.'"),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	If Cancel Then
		Return;
	EndIf;
	If ThisIsPerformanceOfRepairWork(ThisObject) Then
		CurrentObject.WorksToPerform.Load(WorksPerformedInTable());
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_ProductionProcessWhenElementIsActivated()
	
	ProductionProcessActivationOfElement = True;
	
	CurrentRow = Items.ManufacturingProcess.CurrentRow;
	
	ProductionProcessWhenActivatingItemOnServer();
	
	If Items.ManufacturingProcess.CurrentRow <> CurrentRow Then
		Items.ManufacturingProcess.CurrentRow = CurrentRow;
	EndIf;
	
	ProductionProcessActivationOfElement = False;
	
EndProcedure

&AtServer
Procedure ProductionProcessWhenActivatingItemOnServer()
	
	ElementCache_ = ProductionProcessGetCacheItems();
	
	ProductionProcessCacheCurItem(ElementCache_);
	
	ProductionProcessInitializeNewItem(ElementCache_);
	
	ProductionProcessSaveCacheItems(ElementCache_);
	
EndProcedure

&AtServer
Procedure ProductionProcessCacheCurItem(ElementCache_)
	
	If Not ValueIsFilled(ProductionProcessCurrentLink) Then
		Return;
	EndIf;
	
	DescriptionOfElementProperties_ = ProductionProcessCache.DescriptionOfElementProperties_; // Map
	
	ElementCache = ElementCache_.Get(ProductionProcessCurrentLink);
	If ElementCache <> Undefined Then
		
		ItemKind      = ElementCache.ItemKind;
		ItemProperties = DescriptionOfElementProperties_.Get(ItemKind);
		CurrentObject    = Undefined;
		
		If ElementCache.ContainsObject Then
		
			Try
				CurrentObject = FormAttributeToValue(ItemProperties.ObjectAttributeName);
			Except
				ObjectData = ThisObject[ItemProperties.ObjectAttributeName]; // CatalogObject.ProductionStages 
				Template = NStr("vi = 'Đối tượng ""%1"" có thể đã thay đổi bởi người sử dụng khác. Sẽ đọc lại dữ liệu của đối tượng.';
								|ru = 'Объект ""%1"" возможно был изменен другим пользователем. Данные объекта будут прочитаны повторно.';
								|en = 'Object ""%1"" may have been modified by another user. The object data will be re-read.'; fa = 'Object ""%1"" may have been modified by another user. The object data will be re-read.';
								|it = 'L''oggetto ""%1"" potrebbe essere stato modificato da un altro utente. I dati dell''oggetto verranno riletti.';
								|pl = 'Obiekt ""%1"" mógł być zmieniony przez innego użytkownika. Dane obiektu zostaną przeczytane ponownie.';
								|tr = '""%1"" nesnesi başka bir kullanıcı tarafından değiştirilmiş olabilir. Nesne verileri tekrar okunacaktır.'");
				Common.MessageToUser(StrTemplate(Template, ObjectData.Description));
				ElementCache_.Delete(ProductionProcessCurrentLink);
				Return;
			EndTry;
				
			If CurrentObject.IsNew() Then
				CurrentObject.SetNewObjectRef(ProductionProcessCurrentLink);
			EndIf;
		
		EndIf;
		
		If ItemKind = TypeOfStageElement() Then
		
			CurrentObject.MaximumNumberOfProductUnitsLots = StageMaximumNumberOfUnitsOfProductBatches;
			ProductionProcessEditor.SaveTypesOfWorkCenters(
						StageTypesOfWorkCenters,
						CurrentObject.PlanOperationsOfWorkCenterTypes,
						CurrentObject.WorkCenterTypes,
						CurrentObject.AlternateWorkCenterTypes);
			
		ElsIf ItemKind = TypeOfElementOfOperation() Then
			
			ProductionProcessEditorClientServer.UploadOperationTypeStandards(CurrentObject, OperationAddAttributes);
		EndIf;
		
		ElementCache.Object = CurrentObject;
		ProductionProcessCacheFormDetails(ElementCache);
		ElementCache_.Insert(ProductionProcessCurrentLink, ElementCache);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProductionProcessInitializeNewItem(ElementCache_)
	
	CurrentRow = Items.ManufacturingProcess.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	CurrentData = ManufacturingProcess.FindByID(CurrentRow);
	
	DescriptionOfElementProperties_ = ProductionProcessCache.DescriptionOfElementProperties_; // Map
	ItemProperties    = DescriptionOfElementProperties_.Get(CurrentData.ItemKind);
	
	ElementCache = ProductionProcessGetItemCache(ElementCache_, CurrentData, True);
	
	ProductionProcessCurrentLink = CurrentData.Ref;
	
	If ElementCache.ContainsObject Then
		ValueToFormAttribute(ElementCache.Object, ItemProperties.ObjectAttributeName);
	EndIf;
	
	UpdateObjectAttributeValuesInTree(ThisObject, CurrentData);
	
	If CurrentData.ItemKind = TypeOfStageElement() Then
		
		ProductionProcessInitializeStage(CurrentData, ElementCache);
	ElsIf CurrentData.ItemKind = TypeOfElementOfOperation() Then
		
		ProductionProcessInitializeOperation(CurrentData, ElementCache);
		
	ElsIf CurrentData.ItemKind = TypeOfWorkElement() Then
		
		ProductionProcessInitializeWork(CurrentData, ElementCache);
	EndIf;
	
	Items[ItemProperties.NameOfPropertiesPage].ReadOnly = CurrentData.ReadOnly;
	Items.ProductionProcessPageProperties.CurrentPage = Items[ItemProperties.NameOfPropertiesPage];
	
EndProcedure

&AtServer
Procedure ProductionProcessInitializeStage(RowData, ElementCache)
	
	ItemKind = RowData.ItemKind;
	
	If ElementCache.FilledIn_ Then
		ProductionProcessRecoverFormDetailsFromCache(ElementCache);
	Else
		PlanningIntervalStage = ProductionProcessGetUnitParameters(
			ThisObject, ProductionProcessStage.Department).PlanningInterval;
		ReadRouteMapSettings(ProductionProcessStage, ThisObject);
	EndIf;
	
	StageProductionMethod = Number(ProductionProcessStage.ProductionByThirdParty);
	
	FillInSelectionOfBuffersUnit(True);
	ProductionProcessEditor.FillInTheTypesOfWorkCenters(
		ProductionProcessStage, StageTypesOfWorkCenters, StageIsParallelLoading, TheStageIsSynchronousLoading);
	If Object.RecordMethodOfMaterialTransferBetweenStagesLots =
			Enums.RecordMethodsOfMaterialTransferBetweenStagesLots.SetUpManually Then
		TheStructureOfTheSearch = New Structure("StageSender", ProductionProcessCurrentLink);
		Items.IntermediateRelease.RowFilter = New FixedStructure(TheStructureOfTheSearch);
		IntermediateReleaseNumberOfLines = Object.IntermediateRelease.FindRows(TheStructureOfTheSearch).Count();
	EndIf;
	SetBlankMarkForBuffers(ThisObject);
	
	FillInServiceDetailsOfProcessorSService();
	
	ProductionProcessEditorClientServer.FillInExplanationOfBasicSettings(ProductionProcessStage, ThisObject, ItemKind);
	
	ProductionProcessEditor.SetAvailabilityOfStageElementsByStatus(ThisObject, AttributeAvailability, BillOfMaterialsIsClosed, ItemKind);
	
	CustomizeFormElementsStep(ProductionProcessStage, RowData);
	
EndProcedure

&AtServer
Procedure ProductionProcessInitializeOperation(RowData, ElementCache)
	
	ItemKind       = RowData.ItemKind;
	StageLineData = ProductionProcessGetCurStage(ThisObject);
	If StageLineData <> Undefined Then
		Department = StageLineData.Department;
	EndIf;
	
	If ElementCache.FilledIn_ Then
		ProductionProcessRecoverFormDetailsFromCache(ElementCache);
		ProductionProcessEditor.SetConditionalAppearanceOfTransactionTypeDetails(ThisObject, ItemKind);
	Else
		ProductionProcessEditor.ReadTransactionTypeDetails(
			ProductionProcessOperation, ThisObject, ItemKind);
		ProductionProcessEditor.ReadDetailsOfWorkCenter(
			ProductionProcessOperation, ThisObject, ItemKind);
		ReadProcessSettings(ProductionProcessOperation, ThisObject);
	EndIf;
	
	OperationItemAvailability = ProductionProcessEditor.DetermineAvailabilityOfOperationElements(Object.Status);
	
	ProductionProcessEditor.ConfigureVisibilityAvailabilityOfOperationElements(
		ProductionProcessOperation,
		ThisObject,
		ProductionProcessGetUnitParameters(ThisObject, Department),
		ItemKind);
		
	ProductionProcessEditor.ConfigureSettingsForSelectingWorkCenters(
		ProductionProcessOperation,
		ThisObject,
		Department,
		ItemKind);
		
	ProductionProcessEditor.ConfigureSiteSelectionParameters(
		ProductionProcessOperation,
		ThisObject,
		Department,
		ItemKind);
	
	Items.OperationPlot.InputHint = ProductionProcessEditor.PlotPresentation(ProductionProcessOperation, Items.OperationPlot.Visible);
	
	Items.OperationUnitOfMeasure.InputHint = ProductionManagementClientServer.PresentationOfUnitOfOperation(
		ProductionProcessOperation.UnitOfMeasure, ProductionProcessOperation.Count);
	ProductionProcessEditorClientServer.FillInUnitOfMeasurementOfTransferBatch(
		ProductionProcessOperation, OperationTransferBatchUnitOfMeasurement);
	
	OperationTypeOfOperation = ProductionProcessOperation.OperationKind;
	
	ConfigureOperationFormElements(ProductionProcessOperation, RowData);
	
EndProcedure

&AtServer
Procedure ProductionProcessInitializeWork(TreeRowData, ElementCache)
	
	TheseLinesWork = ProductionProcessElementData(ThisObject, TreeRowData);
	
	Items.WorksToPerform.CurrentRow = TheseLinesWork.GetID();
	
	ProductionProcessEditor.AdjustVisibilityAvailabilityOfWorkItems(
		ThisObject,
		AttributeAvailability);
	
	CustomizeWorkFormElements(TheseLinesWork, TreeRowData);
	
EndProcedure

&AtServerNoContext
Procedure ReadProcessSettings(Object, Form)
	
	CalculateFactor = Catalogs.TechnologicalProcesses.CoefficientOfTechnologicalProcessIsCalculated(
		Object.TechnologicalProcess);
		
	Form.OperationCalculateCoefficient = CalculateFactor;
	
EndProcedure

&AtClientAtServerNoContext
Function ProductionProcessDescriptionOfElementProperties(ItemKind)
	
	Result = New Structure("ItemKind", ItemKind);
	
	If ItemKind = TypeOfStageElement() Then
		
		Result.Insert("ItemKindPresentation",    NStr("vi = 'Công đoạn';
														|ru = 'Этап';
														|en = 'Stage'; fa = 'مرحله';
														|it = 'Fase';
														|pl = 'Stage';
														|tr = 'Aşama'"));
		Result.Insert("NameOfPropertiesPage",          "ProductionProcessStage");
		Result.Insert("Counter",                     "StageCount");
		
		Result.Insert("ContainsObject",              True);
		Result.Insert("ItemTypeName",             "ProductionStages");
		Result.Insert("ObjectAttributeName",         "ProductionProcessStage");
		Result.Insert("Number",                       "StageNumber");
		Result.Insert("TheNumberOfTheNextOne",             "NextStageNo");
		Result.Insert("Edit",              "StageEditing");
		Result.Insert("EditPresentation", "StageEditingPresentation");
		
		Result.Insert("UnitOfMeasureOfFollowUpBuffer",        "StageTheUnitOfMeasurementOfTheTerminatingBuffer");
		Result.Insert("UnitOfMeasureOfPreliminaryBuffer",    "StagePreBufferUnitOfMeasurement");
		Result.Insert("MaximumNumberOfProductUnitsLots", "StageMaximumNumberOfUnitsOfProductBatches");
		Result.Insert("SplitRouteSheets",                  "TheSplitRouteSheetsStage");
		Result.Insert("CalculateFactor",                   "StepCalculateCoefficient");
		Result.Insert("SplitRouteSheetsByRouteMap", "StageSplitRouteSheetsByRouteMap");
		
		Result.Insert("TreeDetails",  "Description,Number,TheNumberOfTheNextOne,Department,WorkPlanning");
		
		AddtlDetailsElements = New Array;
		AddtlDetailsElements.Add("StageAdditionalBankingDetails");
		Result.Insert("AdditionalDetailsElements", AddtlDetailsElements);
		Result.Insert("AdditionalAttributes",         "StageAdditionalBankingDetails");
		Result.Insert("UseAddlAttributes",        "HowToUseAdditionalBankingDetails");
	ElsIf ItemKind = TypeOfElementOfOperation() Then
		
		Result.Insert("ItemKindPresentation",    NStr("vi = 'Giao dịch';
														|ru = 'Операция';
														|en = 'Operation'; fa = 'عملیات';
														|it = 'Operazione';
														|pl = 'Operation';
														|tr = 'İşlem'"));
		Result.Insert("NameOfPropertiesPage",          "ProductionProcessOperation");
		Result.Insert("Counter",                     "OperationQuantity");
		
		Result.Insert("ContainsObject",              True);
		Result.Insert("ItemTypeName",             "ManufacturingOperations");
		Result.Insert("ObjectAttributeName",         "ProductionProcessOperation");
		Result.Insert("Number",                       "OperationNumber");
		Result.Insert("TheNumberOfTheNextOne",             "NextOperation");
		Result.Insert("Edit",              "OperationEdit");
		Result.Insert("EditPresentation", "OperationEditPresentation");
		
		Result.Insert("TreeDetails",  "Description,Number,TheNumberOfTheNextOne,WorkCenter");
		
		AddtlDetailsElements = New Array;
		AddtlDetailsElements.Add("OperationAdditionalAttributes");
		AddtlDetailsElements.Add("OperationAdditionalDetailsOfTP");
		Result.Insert("AdditionalDetailsElements", AddtlDetailsElements);
		Result.Insert("AdditionalAttributes",         "OperationAdditionalAttributes");
		Result.Insert("UseAddlAttributes",        "OperationUseAdditionalBankingDetails");
	
	ElsIf ItemKind = TypeOfWorkElement() Then
		
		Result.Insert("ItemKindPresentation",    NStr("vi = 'Công việc lồng nhau';
														|ru = 'Вложенная работа';
														|en = 'Nested work'; fa = 'Nested work';
														|it = 'Nested work';
														|pl = 'Nested work';
														|tr = 'Yatırım yapılan iş'"));
		Result.Insert("NameOfPropertiesPage",          "ManufacturingProcessWork");
		Result.Insert("Counter",                     "Work_Quantity");
		
		Result.Insert("ContainsObject",              False);
		Result.Insert("Description",                "Work_5Presentation");
		
		Result.Insert("TreeDetails",             "Description");
		
		Result.Insert("UseAddlAttributes",    "WorkUseAdditionalAttributes");
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure ProductionProcessConvolution(GroupBy = True, RowsCollection = Undefined)
	
	If RowsCollection = Undefined Then
		RowsCollection = ManufacturingProcess;
	EndIf;
	
	For Each TreeRow In RowsCollection.GetItems() Do
		If GroupBy Then
			ProductionProcessConvolution(GroupBy, TreeRow);
			Items.ManufacturingProcess.Collapse(TreeRow.GetID());
		Else
			Items.ManufacturingProcess.Expand(TreeRow.GetID(), True);
		EndIf;
	EndDo;

EndProcedure

&AtClient
Procedure ManufacturingProcessPropertiesConvolution(GroupBy = True)
	
	CurrentData = Items.ManufacturingProcess.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	DescriptionOfElementProperties_ = ProductionProcessCache.DescriptionOfElementProperties_; // Map
	SectionName = DescriptionOfElementProperties_.Get(CurrentData.ItemKind).NameOfPropertiesPage;
	ProductionProcessCollapseNestedGroups(Items[SectionName], GroupBy);
	
EndProcedure

&AtClient
Procedure ProductionProcessCollapseNestedGroups(Item, GroupBy)
	
	For Each FormItem In Item.ChildItems Do
		
		If Not TypeOf(FormItem) = Type("FormGroup") Then
			Continue;
		EndIf;
		
		If FormItem.Type = FormGroupType.Pages Then
			ProductionProcessCollapseNestedGroups(FormItem.CurrentPage, GroupBy);
		Else
			If GroupBy Then
				FormItem.Hide();
			Else
				FormItem.Show();
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function ProductionProcessCheckCleanItemUsage(ItemKind, Ref, Clear = False)
	
	NamesOfTS = TabularSectionNames();
	
	DescriptionOfElementProperties_ = ProductionProcessCache.DescriptionOfElementProperties_; // Map
	ItemsProperties = DescriptionOfElementProperties_.Get(ItemKind);
	
	TheStructureOfTheSearch = New Structure(ItemsProperties["Edit"], Ref);
	
	For Each TSName In NamesOfTS Do
		FoundRows = Object[TSName].FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() > 0 Then
			If Clear Then
				For Each String In FoundRows Do
					String[ItemsProperties["Edit"]]              = Undefined;
					String[ItemsProperties["EditPresentation"]] = "";
					String.ElementOfProductionProcessPresentation     = RepresentationOfProductionProcessElement(ThisObject, String);
				EndDo;
			Else
				Return False;
			EndIf;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

&AtClientAtServerNoContext
Function ProductionProcessGetNewNumber(ItemsCollection)
	
	NewNumber = 1;
	
	If ItemsCollection.Count() > 0 Then
		NewNumber = ItemsCollection[ItemsCollection.Count()-1].Number + 1;
	EndIf;
	
	Return NewNumber;
	
EndFunction

&AtServer
Procedure ProductionProcessUpdateDashboards()
	
	InformationLineMaterials = "";
	InformationLineLaborCosts = "";
	InformationLineProductionProcess = "";
	
	TechnologicalProcesses = New Array;
	
	If GetFunctionalOption("UseTechnologicalProcesses") Then
		RowData = Undefined;
		While ProductionProcessIsFollowingElement(ThisObject, RowData) Do
			If RowData.ItemKind = TypeOfElementOfOperation()
				And ValueIsFilled(RowData.TechnologicalProcess) Then
				TechnologicalProcesses.Add(RowData.TechnologicalProcess);
			EndIf;
		EndDo;
	EndIf;
	
	If TechnologicalProcesses.Count() > 0 Then
		
		LabelPattern = NStr("vi = '+ hơn nữa %1 theo quy trình kỹ thuật';
							|ru = '+ еще %1 согласно технологическим процессам';
							|en = '+ %1 more according to technological processes'; fa = '+ %1 more according to technological processes';
							|it = '+ ancora %1 in conformità con i processi tecnologici';
							|pl = '+ jeszcze %1 zgodnie z procesem technologicznym';
							|tr = '+ teknolojik süreçlere göre %1 daha'"); 
		
		QueryText = "
		|SELECT DISTINCT
		|	Table.Products,
		|	Table.Characteristic
		|FROM
		|	Catalog.TechnologicalProcesses.MaterialsAndServices AS Table
		|WHERE
		|	Table.Ref IN (&TechnologicalProcesses)
		|;
		|
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Table.WorkKind
		|FROM
		|	Catalog.TechnologicalProcesses.LaborCosts AS Table
		|WHERE
		|	Table.Ref IN (&TechnologicalProcesses)
		|";
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("TechnologicalProcesses", TechnologicalProcesses);
		
		SetPrivilegedMode(True);
		QueryResults = Query.ExecuteBatch();
		SetPrivilegedMode(False);
		
		QuantityOfMaterials = QueryResults[0].Select().Count();
		If QuantityOfMaterials > 0 Then
			InformationLineMaterials = StrTemplate(LabelPattern, QuantityOfMaterials); 
		EndIf;
		
		NumberOfLaborCosts = QueryResults[1].Select().Count();
		If NumberOfLaborCosts > 0 Then
			InformationLineLaborCosts = StrTemplate(LabelPattern, NumberOfLaborCosts); 
		EndIf;
		
	EndIf;
	
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
		And Not StoreOperationsInBillsOfMaterials Then
		MessageText = NStr("vi = 'Chỉ có thể thêm các công đoạn lập kế hoạch công việc sau khi chuyển sang quản lý các giao dịch trong bảng kê chi tiết các nguồn lực sản xuất';
							|ru = 'Добавление этапов планирования работ возможно только после перехода на ведение операций в ресурсных спецификациях';
							|en = 'Adding work planning stages is only available after switching to operations in BOMs'; fa = 'Adding work planning stages is only available after switching to operations in BOMs';
							|it = 'Adding work planning stages is only available after switching to operations in BOMs';
							|pl = 'Adding work planning stages is only available after switching to operations in BOMs';
							|tr = 'İş planlama aşamalarının eklenmesi ancak kaynak özelliklerinde operasyonların sürdürülmesine geçildikten sonra mümkün olur'");
		If Users.IsFullUser(, True) Then
			MessageText = StrTemplate(NStr("vi = '%1 (Danh mục và quản trị - Sản xuất)';
											|ru = '%1 (НСИ и администрирование - Производство)';
											|en = '%1 (Master data and settings - Manufacturing)'; fa = '%1 (Master data and settings - Manufacturing)';
											|it = '%1 (Master data and settings - Manufacturing)';
											|pl = '%1 (Master data and settings - Manufacturing)';
											|tr = '%1 (Master veri ve yönetim - Üretim)'"), MessageText);
		EndIf;
		InformationLineProductionProcess = MessageText;
	EndIf;
	Items.MaterialsInformationPanel.Visible = ValueIsFilled(InformationLineMaterials);
	Items.InformationPanelLaborCosts.Visible = ValueIsFilled(InformationLineLaborCosts);
	Items.ProductionProcessInformationPanel.Visible = ValueIsFilled(InformationLineProductionProcess);
	
EndProcedure

&AtServer
Procedure UpgradePropsMultiStageProductionProcess()
	
	MultiStageProductionProcess = ?(ProductionProcessCache.StageCount > 1, True, False);
	
	If MultiStageProductionProcess <> Object.MultiStageProductionProcess Then
		
		Object.MultiStageProductionProcess = MultiStageProductionProcess;
		WhenChangingStructureOfProductionProcess();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionProcessOpenShapeOfElement(RowData)
	
	CurrentRef = RowData.StageEditing;
	If ValueIsFilled(RowData.OperationEdit)
			And StoreOperationsInBillsOfMaterials Then
		CurrentRef = RowData.OperationEdit;
	EndIf;
	If Not ValueIsFilled(CurrentRef) Then
		Return;
	EndIf;
	
	If ProductionProcessOfItemIsRecorded(CurrentRef) Then
		FormParameters = New Structure("Key,ReadOnly", CurrentRef, True);
		ElementFormName = StrTemplate("Catalog.%1.ObjectForm", ProductionProcessEditorClientServer.NameOfElementTypeByReference(CurrentRef));
		OpenForm(ElementFormName, FormParameters);
	Else
		ShowMessageBox(, NStr("vi = 'Chỉ có thể mở phần tử sau khi ghi lại.';
								|ru = 'Открыть элемент можно только после его записи.';
								|en = 'Element can be opened after it has been saved.'; fa = 'Element can be opened after it has been saved.';
								|it = 'L''elemento può essere aperto previo salvataggio.';
								|pl = 'Otwórz element można tylko po jego zapisaniu.';
								|tr = 'Öğeyi sadece kaydettikten sonra açabilirsiniz.'"));
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ProductionProcessOfItemIsRecorded(Ref)
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.Text = "
	|SELECT
	|	Table.Ref
	|FROM
	|	&Table AS Table
	|WHERE
	|	Table.Ref = &Ref";
	
	TypeName = ProductionProcessEditorClientServer.NameOfElementTypeByReference(Ref);
	If TypeName <> Undefined Then
		Query.Text = StrReplace(Query.Text, "&Table", "Catalog."+TypeName);
		Return (Query.Execute().IsEmpty() = False);
	Else
		Return False;
	EndIf;
	
EndFunction

&AtServerNoContext
Function TableOfElementsOfProductionProcessDesigner()
	
	Result = New ValueTable;
	
	DataTypes = New Array;
	DataTypes.Add("CatalogRef.ProductionStages");
	DataTypes.Add("CatalogRef.ManufacturingOperations");
	Result.Columns.Add("Ref",                New TypeDescription(StrConcat(DataTypes, ",")));
	Result.Columns.Add("Number",                 New TypeDescription("Number"));
	Result.Columns.Add("TheNumberOfTheNextOne",       New TypeDescription("Number"));
	Result.Columns.Add("Description",          New TypeDescription("String",, New StringQualifiers(150)));
	Result.Columns.Add("Department",         New TypeDescription("CatalogRef.BusinessStructure"));
	Result.Columns.Add("ProductionByThirdParty", New TypeDescription("Boolean"));
	Result.Columns.Add("Owner",              New TypeDescription(StrConcat(DataTypes, ",")));
	Result.Columns.Add("WorkCenter", New TypeDescription("CatalogRef.WorkCenterTypes,CatalogRef.WorkCenters"));
	Return Result;
	
EndFunction

&AtServer
Function TableOfProductionProcessElements(Filter)
	
	Result = TableOfElementsOfProductionProcessDesigner();
	
	AddRowsToProductionProcessElementTable(
		Result,
		TreeOfProductionProcessElementsForSelection(Filter).Rows);
		
	Return Result;
	
EndFunction

&AtServer
Procedure AddRowsToProductionProcessElementTable(TableOfElements, TreeRows)
	
	If TreeRows.Count() = 0 Then
		Return;
	EndIf;
	
	For Each TreeRow In TreeRows Do
		
		NewRow = TableOfElements.Add();
		FillPropertyValues(NewRow, TreeRow);
		If TreeRow.Parent <> Undefined Then
			NewRow.Owner = TreeRow.Parent.Ref;
		EndIf;
		
		AddRowsToProductionProcessElementTable(TableOfElements, TreeRow.Rows);
	
	EndDo;
	
EndProcedure

&AtServer
Function TableOfPredecessorStages(CurrentStep)
	
	StepsTable = TableOfElementsOfProductionProcessDesigner();
	StepsTable.Columns.Add("Predecessor", New TypeDescription("Boolean"));
	
	TheStructureOfTheSearch = New Structure("TheNumberOfTheNextOne,Predecessor", -1, False);
	
	For Each StageString In ManufacturingProcess.GetItems() Do
		
		If StageString.Ref = CurrentStep Then
			TheStructureOfTheSearch.TheNumberOfTheNextOne = StageString.Number;
			Break;
		EndIf;
		
		FillPropertyValues(StepsTable.Add(), StageString);
		
	EndDo;
	
	StepsTable.Indexes.Add("TheNumberOfTheNextOne");
	
	FoundRows = StepsTable.FindRows(TheStructureOfTheSearch);
	While FoundRows.Count() > 0 Do
		
		TheStructureOfTheSearch.TheNumberOfTheNextOne = FoundRows[0].Number;
		For Each FoundRow In StepsTable.FindRows(TheStructureOfTheSearch) Do
			If FoundRows.Find(FoundRow) = Undefined Then
				FoundRows.Add(FoundRow);
			EndIf;
		EndDo;
		
		FoundRows[0].Predecessor = True;
		FoundRows.Delete(0);
		
	EndDo;
	
	Return StepsTable.Copy(New Structure("Predecessor", True));
	
EndFunction

&AtClientAtServerNoContext
Procedure ProductionProcessUpdatePresentation(ItemKind, Ref, Presentation, Form)
	
	DescriptionOfElementProperties_ = Form.ProductionProcessCache.DescriptionOfElementProperties_; // Map
	ItemsProperties = DescriptionOfElementProperties_.Get(ItemKind);
	
	NamesOfTS = TabularSectionNames();
	
	Object          = Form.Object;
	AttributeName    = ItemsProperties["Edit"];
	TheStructureOfTheSearch = New Structure(AttributeName, Ref);
	
	For Each TSName In NamesOfTS Do
		
		FoundRows = Object[TSName].FindRows(TheStructureOfTheSearch);
		For Each String In FoundRows Do
			String[ItemsProperties["EditPresentation"]] = Presentation;
			String.ElementOfProductionProcessPresentation = RepresentationOfProductionProcessElement(Form, String);
		EndDo;
		
		If TSName = "MaterialsAndServices" And ItemKind = TypeOfStageElement() Then
			FoundRows = Object[TSName].FindRows(New Structure("SourceOfSemiFinishedProduct", Ref));
			For Each String In FoundRows Do
				String.SourceOfSemiFinishedProductPresentation = Presentation;
				FillInPresentationOfMaterialReceiptMethod(String, Form);
			EndDo;
			FoundRows = Object[TSName].FindRows(New Structure("PlanNotEarlierThan", Ref));
			For Each String In FoundRows Do
				String.PlanNotEarlierThanPresentation = Presentation;
				FillInPresentationOfMaterialReceiptMethod(String, Form);
			EndDo;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function ProductionProcessIsFollowingElement(Form, Cursor, NestedLevels = True)
	
	ItemsList = Form.ManufacturingProcess.GetItems(); // TreeRowsCollection
	
	If Cursor = Undefined Then
		If ItemsList.Count() > 0 Then
			Cursor = ItemsList[0];
		EndIf;
		Return Cursor <> Undefined; // Boolean
	EndIf;
	
	ListOfElementsIsNested = Cursor.GetItems();
	If ListOfElementsIsNested.Count() > 0 And NestedLevels Then
		Cursor = ListOfElementsIsNested[0];
	Else
		Parent = Cursor.GetParent();
		If Parent <> Undefined Then
			ItemsList = Parent.GetItems();
		EndIf;
		CurrentIndex = ItemsList.IndexOf(Cursor);
		If CurrentIndex < ItemsList.Count()-1 Then
			Cursor = ItemsList[CurrentIndex+1];
		ElsIf Parent <> Undefined Then
			Cursor = Parent;
			Return ProductionProcessIsFollowingElement(Form, Cursor, False);
		Else
			Cursor = Undefined;
		EndIf;
	EndIf;
	
	Result = Cursor <> Undefined; // Boolean
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function ProductionProcessLineHighlighted(Form, RowData, SelectedRows)
	
	RowID = RowData.GetID();
	If SelectedRows.Find(RowID) <> Undefined Then
		Return True;
	EndIf;
	
	ParentRowData = RowData.GetParent();
	If ParentRowData <> Undefined Then
		Return ProductionProcessLineHighlighted(Form, ParentRowData, SelectedRows); // Boolean
	Else
		Return False;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function StageElementTitle(Form, StageObject)
	
	If StageObject.WorkPlanning Then
		Result = NStr("vi = 'Giai đoạn lập kế hoạch công việc';
						|ru = 'Этап планирования работ';
						|en = 'Work planning stage'; fa = 'مرحله برنامه‌ریزی کار';
						|it = 'Work planning stage';
						|pl = 'Work planning stage';
						|tr = 'İş planlama etabı'");
	Else
		Result = TitleOfProductionStageElement(Form);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function TitleOfProductionStageElement(Form)
	
	If Not Form.Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM") Then
		Result = ProductionProcessEditorClientServer.NameOfNewItem(TypeOfStageElement());
	Else
		Result = NStr("vi = 'Công đoạn sản xuất';
						|ru = 'Этап производства';
						|en = 'Production stage'; fa = 'مرحله تولید';
						|it = 'Fase di produzione';
						|pl = 'Etap produkcji';
						|tr = 'Üretim aşaması'");
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure ProductionProcessRemoveStageOperation(StageLineData)
	
	OperationLines = StageLineData.GetItems();
	If OperationLines.Count() = 0 Then
		Return;
	EndIf;
	
	ElementCache_ = ProductionProcessGetCacheItems();
	OperationsCount = OperationLines.Count();
	
	For Each LineOperation In OperationLines Do
		
		ElementCache = ProductionProcessGetItemCache(ElementCache_, LineOperation);
		ElementCache.Removed = True;
		
		ProductionProcessCheckCleanItemUsage(TypeOfElementOfOperation(), LineOperation.Ref, True);
		
	EndDo;
	
	OperationLines.Clear();
	
	ProductionProcessONChangesInCompositionOfElements(TypeOfElementOfOperation(), -OperationsCount);
	
	ProductionProcessSaveCacheItems(ElementCache_);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfWorkPerformed()
	
	If Not ThisIsPerformanceOfRepairWork(ThisObject)
		Or Not ProductionProcessRead Then
		Return;
	EndIf;
	
	QueryText = "
	|SELECT
	|	T.LineNumber                      AS LineNumber,
	|	T.Products                     AS Products,
	|	T.Characteristic                   AS Characteristic,
	|	T.UnderRepairProduct AS UnderRepairProduct
	|INTO WorksToPerform
	|FROM
	|	&WorksToPerform AS T
	|
	|;
	|
	|SELECT
	|	WorksToPerform.LineNumber                    AS LineNumber,
	|	PRESENTATION(WorksToPerform.Products)    AS ProductsPresentation,
	|	PRESENTATION(WorksToPerform.Characteristic)  AS CharacteristicPresentation,
	|	CASE
	|		WHEN T1.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                            AS ItemVariantsAreUsed,
	|	CASE
	|		WHEN T2.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                            AS FinishedProductBeingRepairedCharacteristicsAreUsed
	|
	|FROM
	|	WorksToPerform AS WorksToPerform
	|
	|	LEFT JOIN Catalog.Products AS T1
	|	ON WorksToPerform.Products = T1.Ref
	|
	|	LEFT JOIN Catalog.Products AS T2
	|	ON WorksToPerform.UnderRepairProduct = T2.Ref
	|
	|ORDER BY
	|	WorksToPerform.LineNumber
	|
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("WorksToPerform", Object.WorksToPerform.Unload());
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RowData = Object.WorksToPerform[Selection.LineNumber-1];
		RowData.ItemVariantsAreUsed = Selection.ItemVariantsAreUsed;
		RowData.FinishedProductBeingRepairedCharacteristicsAreUsed = Selection.FinishedProductBeingRepairedCharacteristicsAreUsed;
		RowData.Work_5Presentation = ProductsClientServer.ProductPresentation(
								Selection.ProductsPresentation, Selection.CharacteristicPresentation);
	EndDo;
	
EndProcedure

&AtServer
Procedure ProductionProcessToClean()
	
	ManufacturingProcess.GetItems().Clear();
	
	ProductionProcessClearItemCache();
	
	DescriptionOfElementProperties_ = ProductionProcessCache.DescriptionOfElementProperties_; // Map
	
	For Each ItemKind In ProductionProcessEditorClientServer.ItemsKinds() Do
		ItemsProperties = DescriptionOfElementProperties_.Get(ItemKind);
		ProductionProcessCache[ItemsProperties.Counter] = 0;
	EndDo;
	
	ProductionProcessCache.ThereIsMultioperativeStage = False;
	
EndProcedure

&AtServer
Procedure ProductionProcessONChangesInCompositionOfElements(ItemKind, Update)
	
	DescriptionOfElementProperties_ = ProductionProcessCache.DescriptionOfElementProperties_; // Map
	ItemsProperties = DescriptionOfElementProperties_.Get(ItemKind);
	
	ProductionProcessCache[ItemsProperties.Counter] = ProductionProcessCache[ItemsProperties.Counter] + Update;
	
	If ItemKind = TypeOfStageElement() Then
		
		UpgradePropsMultiStageProductionProcess();
	ElsIf ItemKind = TypeOfElementOfOperation() Then
		
		ThereIsMultioperativeStage = ProductionProcessCache.ThereIsMultioperativeStage;
		PropertiesOfStageElements = DescriptionOfElementProperties_.Get(TypeOfStageElement());
		
		If ProductionProcessCache[ItemsProperties.Counter] > ProductionProcessCache[PropertiesOfStageElements.Counter] Then
			
			ThereIsMultioperativeStage = True;
			
		ElsIf (ThereIsMultioperativeStage And Update < 0)
			Or (Not ThereIsMultioperativeStage And Update > 0) Then
			
			ThereIsMultioperativeStage = False;
			For Each StageString In ManufacturingProcess.GetItems() Do
				If StageString.GetItems().Count() > 1 Then
					ThereIsMultioperativeStage = True;
					Break;
				EndIf;
			EndDo;
			
		EndIf;
		
		If ThereIsMultioperativeStage <> ProductionProcessCache.ThereIsMultioperativeStage Then
			ProductionProcessCache.ThereIsMultioperativeStage = ThereIsMultioperativeStage;
			If Not ThereIsMultioperativeStage Then
				For Each TSName In TabularSectionNames() Do
					For Each String In Object[TSName] Do
						String.OperationEdit              = Undefined;
						String.OperationEditPresentation = "";
						String.ElementOfProductionProcessPresentation = RepresentationOfProductionProcessElement(ThisObject, String);
					EndDo;
				EndDo;
			EndIf;
		EndIf; 
	EndIf;
	
EndProcedure

// Gets the parent of the specified tree row
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	RowData - FormDataTreeItem
// Returns:
// 	FormDataTreeItem - parent of the specified string
&AtClientAtServerNoContext
Function ProductionProcessGetParent(Form, RowData)
	
	ItemParent = RowData.GetParent();
	If ItemParent = Undefined Then
		ItemParent = Form.ManufacturingProcess;
	EndIf;
	
	Return ItemParent;
	
EndFunction

&AtClient
Function CheckPossibilityOfFillingInDivisionOfStages(RowsIDs)
	
	WarningText = "";
	StagesAreHighlighted = False;
	
	If ValueIsFilled(RowsIDs) Then
		For Each RowID In RowsIDs Do
			If ManufacturingProcess.FindByID(RowID).ItemKind = TypeOfStageElement() Then
				StagesAreHighlighted = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If Not StagesAreHighlighted Then
		WarningText = NStr("vi = 'Cần chọn các công đoạn để điền bộ phận.';
							|ru = 'Необходимо выделить этапы для заполнения подразделения.';
							|en = 'Select the stage to fill the business unit.'; fa = 'Select the stage to fill the business unit.';
							|it = 'È necessario evidenziare le fasi per la compilazione del reparto.';
							|pl = 'Należy wybrać etapy do wypełnienia działu.';
							|tr = 'Departman doldurulması için aşamaları ayırmanız gerekmektedir.'");
	EndIf;
	
	If Not IsBlankString(WarningText) Then
		ShowMessageBox(, WarningText);
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateObjectAttributeValuesInTree(Form, TreeRowData, AttributesList = "", ElementData = Undefined)
	
	If ElementData = Undefined Then
		ElementData = ProductionProcessElementData(Form, TreeRowData);
		If ElementData = Undefined Then
			Return;
		EndIf;
	EndIf;
	
	DescriptionOfElementProperties_ = Form.ProductionProcessCache.DescriptionOfElementProperties_; // Map
	ItemsProperties = DescriptionOfElementProperties_.Get(TreeRowData.ItemKind);
	
	AttributesStructure1 = New Structure();
	If ValueIsFilled(AttributesList) Then
		AttributesStructure1 = StrSplit(AttributesList, ",");
	ElsIf ValueIsFilled(ItemsProperties.TreeDetails) Then
		AttributesStructure1 = StrSplit(ItemsProperties.TreeDetails, ",");
	EndIf;
	
	NameOfAttributeInObject = Undefined;
	For Each AttributeName In AttributesStructure1 Do
		
		If Not ItemsProperties.Property(AttributeName, NameOfAttributeInObject) Then
			NameOfAttributeInObject = AttributeName;
		EndIf;
		
		TreeRowData[AttributeName] = ElementData[NameOfAttributeInObject];
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function ProductionProcessElementData(Form, TreeRowData)
	
	Result = Undefined;
	
	If TreeRowData <> Undefined Then
	
		DescriptionOfElementProperties_ = Form.ProductionProcessCache.DescriptionOfElementProperties_; // Map
		ItemsProperties = DescriptionOfElementProperties_.Get(TreeRowData.ItemKind);
		
		If ItemsProperties.ContainsObject
				And TreeRowData.Ref = Form.ProductionProcessCurrentLink Then
			Result = Form[ItemsProperties.ObjectAttributeName];
		ElsIf TreeRowData.ItemKind = TypeOfWorkElement() Then
			FoundRows = Form.Object.WorksToPerform.FindRows(New Structure("ConnectionKey", TreeRowData.Ref));
			If ValueIsFilled(FoundRows) Then
				Result = FoundRows[0];
			EndIf;
		EndIf;
	
	EndIf;
	
	Return Result;
	
EndFunction

// Gets a string of the current phase
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	CurrentData - FormDataTreeItem
// Returns:
// 	FormDataCollectionItem - Stage string
&AtClientAtServerNoContext
Function ProductionProcessGetCurStage(Form, CurrentData = Undefined)
	
	If CurrentData = Undefined Then
	
		CurrentRow = Form.Items.ManufacturingProcess.CurrentRow;
		If CurrentRow = Undefined Then
			Return Undefined;
		EndIf;
		
		CurrentData = Form.ManufacturingProcess.FindByID(CurrentRow);
	
	EndIf;
	
	RowData = CurrentData;
	
	While RowData <> Undefined And RowData.ItemKind <> TypeOfStageElement() Do
		RowData = RowData.GetParent();
	EndDo;
	
	Return RowData;
	
EndFunction

#Region AddingItems

&AtClient
Function CheckPossibilityOfAddingStage()
	
	WarningText = "";
	
	If ProductionProcessCache.StageCount > 0
			And Not ProductDataManagementClientServer.MultiStageProductionProcessIsAvailable() Then
		WarningText = ProductDataManagementClientServer.MultiStageProductionProcessErrorText();
	EndIf;
	
	If Not IsBlankString(WarningText) Then
		ShowMessageBox(, WarningText);
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

&AtClient
Procedure ProductionProcessStartAddingStage(FillingData = Undefined)
	
	If Not CheckPossibilityOfAddingStage() Then
		Return;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		
		QueryText = NStr("vi = 'Chỉ có thể thêm sau khi ghi lại bảng kê chi tiết.
		|Ghi lại và tiếp tục?';
		|ru = 'Добавление возможно только после записи спецификации.
		|Записать и продолжить?';
		|en = 'You can add only after saving the BOM. 
		|Save and continue?'; fa = 'You can add only after saving the BOM. 
		|Save and continue?';
		|it = 'You can add only after saving the BOM. 
		|Save and continue?';
		|pl = 'You can add only after saving the BOM. 
		|Save and continue?';
		|tr = 'Ekleme ancak ürün reçetesinin kaydedilmesinden sonra mümkündür.
		|Kaydedilip devam edilsin mi?'");
		
		CallbackDescription = New CallbackDescription("ProductionProcessStartAddingStageCompletion",
			ThisObject, FillingData);
			
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
		Return;
		
	EndIf;
	
	ProductionProcessAddStageOnServer(FillingData);
	
EndProcedure

&AtClient
Procedure ProductionProcessStartAddingStageCompletion(QuestionResult, Var_Parameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Write() Then
		
		ProductionProcessAddStageOnServer(Var_Parameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProductionProcessAddStageOnServer(FillingData = Undefined)
	
	ItemsCollection = ManufacturingProcess.GetItems();
	
	StageNumber = ProductionProcessGetNewNumber(ItemsCollection);
	
	ElementCache_ = ProductionProcessGetCacheItems();
	
	StageObject = Catalogs.ProductionStages.CreateItem();
	StageObject.SetNewObjectRef(Catalogs.ProductionStages.GetRef());
	StageObject.Fill(FillingData);
	StageObject.Owner             = Object.Ref;
	StageObject.StageNumber           = StageNumber;
	StageObject.NextStageNo = 0;
	StageObject.Partner              = Catalogs.Companies.EmptyRef();
	
	StageObject.Description = StrTemplate("%1 %2", StageElementTitle(ThisObject, StageObject), StageNumber);
	
	AddingOptions = New Structure;
	AddingOptions.Insert("CorrectNumbering");
	
	NewRow = ProductionProcessAddStageToTree(StageObject, ElementCache_, ItemsCollection, AddingOptions);
	
	Items.ManufacturingProcess.CurrentRow = NewRow;
	
	ProductionProcessSaveCacheItems(ElementCache_);
	If StageObject.WorkPlanning
		And FillingData <> Undefined
		And FillingData.Property("AddWork") Then
		ProductionProcessAddWorkATServer(NewRow);
	EndIf;
	ProcessManufacturingProcessChange(NewRow);
	
	ConfigureDependentFormElements(ThisObject, "ManufacturingProcess");
	
	Modified = True;
	
EndProcedure

&AtServer
Function ProductionProcessAddStageToTree(StageObject, ElementCache_, Collection, Var_Parameters)
	
	NewRow = Collection.Add();
	NewRow.Ref          = StageObject.GetNewObjectRef();
	NewRow.ItemKind     = TypeOfStageElement();
	
	ElementCache  = ProductionProcessItemCacheConstructor(NewRow.ItemKind);
	ElementCache.Object     = StageObject;
	ElementCache.Write = True;
	ElementCache_.Insert(NewRow.Ref, ElementCache);
	
	UpdateObjectAttributeValuesInTree(ThisObject, NewRow,, StageObject);
	
	If Var_Parameters.Property("CorrectNumbering") Then
		ProductionProcessCorrectNumberingAfterAddingItem(ElementCache_, Collection, StageObject.StageNumber);
	EndIf;
	
	ProductionProcessEditorClientServer.SetItemImage(NewRow);
	
	ProductionProcessONChangesInCompositionOfElements(NewRow.ItemKind, 1);
	
	Return NewRow.GetID();
	
EndFunction

&AtClient
Function CheckIfOperationCanBeAdded(StageLineData)
	
	WarningText = "";
	
	If StageLineData = Undefined Then
		WarningText = NStr("vi = 'Ban đầu cần tạo công đoạn sản xuất.';
							|ru = 'Сначала необходимо создать этап производства.';
							|en = 'Create a production stage first.'; fa = 'Create a production stage first.';
							|it = 'Prima è necessario creare la fase di produzione.';
							|pl = 'Najpierw należy utworzyć etap produkcji.';
							|tr = 'Öncelikle üretim aşamasının oluşturulması gerekmektedir.'");
	ElsIf StageLineData.ProductionByThirdParty Then
		WarningText = NStr("vi = 'Chỉ có thể thêm thao tác đối với các công đoạn sản xuất riêng.';
							|ru = 'Добавление операций возможно только для этапов собственного производства.';
							|en = 'Adding operations is only available for in-house production stages.'; fa = 'Adding operations is only available for in-house production stages.';
							|it = 'Le operazioni possono essere aggiunte solo per le fasi di produzione propria.';
							|pl = 'Dodawanie operacji jest możliwe tylko dla etapów produkcji własnej.';
							|tr = 'Ekleme işlemleri sadece şirket içi üretim aşamalarında mümkündür.'");
	ElsIf StageLineData.WorkPlanning Then
		WarningText = NStr("vi = 'Không thể thêm giao dịch đối với các công đoạn lập kế hoạch công việc.';
							|ru = 'Нельзя добавлять операции для этапов планирования работ.';
							|en = 'Cannot add operations for work planning stages.'; fa = 'Cannot add operations for work planning stages.';
							|it = 'Cannot add operations for work planning stages.';
							|pl = 'Cannot add operations for work planning stages.';
							|tr = 'İş planlama aşamalarına operasyon ekleyemezsiniz.'");
	ElsIf Not ValueIsFilled(StageLineData.Department) Then
		WarningText = NStr("vi = 'Trước khi thêm thao tác, cần chỉ ra bộ phận công đoạn.';
							|ru = 'Перед добавлением операций необходимо указать подразделение этапа.';
							|en = 'Specify the stage business unit before adding operations.'; fa = 'Specify the stage business unit before adding operations.';
							|it = 'Prima di aggiungere le operazioni è necessario indicare il reparto della fase.';
							|pl = 'Przed dodaniem operacji należy wskazać dział etapu.';
							|tr = 'İşlem ekleme öncesinde aşamanın departmanını belirtmeniz gerekmektedir.'");
	EndIf;
	
	If Not IsBlankString(WarningText) Then
		ShowMessageBox(, WarningText);
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

&AtClient
Procedure ProductionProcessStartAddingOperation()
	
	StageLineData = ProductionProcessGetCurStage(ThisObject);
	
	If Not CheckIfOperationCanBeAdded(StageLineData) Then
		Return;
	EndIf;
	
	ProductionProcessAddOperationOnServer(StageLineData.GetID());
	
EndProcedure

&AtServer
Procedure ProductionProcessAddOperationOnServer(RowID, FoundationOfWHO = Undefined)
	
	CurrentData = ManufacturingProcess.FindByID(RowID);
	
	ItemsCollection = CurrentData.GetItems();
	
	OperationNumber = ProductionProcessGetNewNumber(ItemsCollection);
	
	ElementCache_ = ProductionProcessGetCacheItems();
	
	OperationObject = Catalogs.ManufacturingOperations.CreateItem();
	OperationObject.SetNewObjectRef(Catalogs.ManufacturingOperations.GetRef());
	OperationObject.Fill(Undefined);
	OperationObject.Owner      = CurrentData.Ref;
	OperationObject.Description  = ProductionProcessEditorClientServer.NameOfNewItem(TypeOfElementOfOperation(), OperationNumber);
	OperationObject.OperationNumber = OperationNumber;
	OperationObject.NextOperation = 0;
	
	DetailsOfWHO = ProductionProcessEditor.ValuesOfDetailsOfOperationsForWHO(OperationObject, ThisObject, FoundationOfWHO, True);
	FillPropertyValues(OperationObject, DetailsOfWHO);
	
	AddingOptions = New Structure;
	AddingOptions.Insert("CorrectNumbering");
	
	NewRow = ProductionProcessAddOfOperationToTree(OperationObject, ElementCache_, ItemsCollection, AddingOptions);
	
	Items.ManufacturingProcess.CurrentRow = NewRow;
	
	ProductionProcessSaveCacheItems(ElementCache_);
	
	ConfigureDependentFormElements(ThisObject, "ManufacturingProcess");
	
	Modified = True;
	
EndProcedure

&AtServer
Function ProductionProcessAddOfOperationToTree(OperationObject, ElementCache_, Collection, Var_Parameters)
	
	NewRow = Collection.Add();
	NewRow.Ref      = OperationObject.GetNewObjectRef();
	NewRow.ItemKind = TypeOfElementOfOperation();
	
	If OperationObject.ContainsTechnologicalProcess Then
		NewRow.TechnologicalProcess = OperationObject.TechnologicalProcess;
	EndIf;
	
	ElementCache  = ProductionProcessItemCacheConstructor(NewRow.ItemKind);
	ElementCache.Object     = OperationObject;
	ElementCache.Write = True;
	ElementCache_.Insert(NewRow.Ref, ElementCache);
	
	UpdateObjectAttributeValuesInTree(ThisObject, NewRow,, OperationObject);
	
	If Var_Parameters.Property("CorrectNumbering") Then
		ProductionProcessCorrectNumberingAfterAddingItem(ElementCache_, Collection, OperationObject.OperationNumber);
	EndIf;
	
	ProductionProcessEditorClientServer.SetItemImage(NewRow);
	
	ProductionProcessONChangesInCompositionOfElements(NewRow.ItemKind, 1);
	
	Return NewRow.GetID();
	
EndFunction

&AtClient
Procedure ProductionProcessStartAddingWork()
	
	StageLineData = ProductionProcessGetCurStage(ThisObject);
	FillingData  = New Structure("WorkPlanning,AddWork", True);
	
	If StageLineData = Undefined Then
		ProductionProcessStartAddingStage(FillingData);
	ElsIf StageLineData.WorkPlanning Then
		ProductionProcessAddWorkATServer(StageLineData.GetID());
	Else
		ShowQueryBox(New CallbackDescription(
						"ProductionProcessStartAddingWorkCompletion", ThisObject, FillingData),
			NStr("vi = 'Tạo công đoạn mới của việc lập kế hoạch công việc?';
				|ru = 'Создать новый этап планирования работ?';
				|en = 'Create a new work planning stage?'; fa = 'Create a new work planning stage?';
				|it = 'Create a new work planning stage?';
				|pl = 'Create a new work planning stage?';
				|tr = 'Yeni iş planlama aşaması oluşturulsun mu?'"),
			QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionProcessStartAddingWorkCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		ProductionProcessStartAddingStage(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProductionProcessAddWorkATServer(RowID)
	
	CurrentData = ManufacturingProcess.FindByID(RowID);
	
	ItemsCollection = CurrentData.GetItems();
	
	ElementCache_ = ProductionProcessGetCacheItems();
	
	NewWork = Object.WorksToPerform.Add();
	NewWork.ConnectionKey      = New UUID();
	NewWork.Stage           = CurrentData.Ref;
	NewWork.Count     = 1;
	
	NewRow = ProductionProcessAddWorkToTree(NewWork, ElementCache_, ItemsCollection);
	
	Items.ManufacturingProcess.CurrentRow = NewRow;
	
	ProductionProcessSaveCacheItems(ElementCache_);
	
	ConfigureDependentFormElements(ThisObject, "ManufacturingProcess");
	
	Modified = True;
	
EndProcedure

&AtServer
Function ProductionProcessAddWorkToTree(TheseLinesWork, ElementCache_, Collection)
	
	NewRow = Collection.Add();
	NewRow.Ref         = TheseLinesWork.ConnectionKey;
	NewRow.ItemKind    = TypeOfWorkElement();
	
	ElementCache  = ProductionProcessItemCacheConstructor(NewRow.ItemKind);
	ElementCache_.Insert(NewRow.Ref, ElementCache);
	
	UpdateObjectAttributeValuesInTree(ThisObject, NewRow,, TheseLinesWork);
	
	ProductionProcessEditorClientServer.SetItemImage(NewRow);
	
	ProductionProcessONChangesInCompositionOfElements(NewRow.ItemKind, 1);
	
	Return NewRow.GetID();
	
EndFunction

&AtClient
Procedure SelectTechnologicalProcess(Mode)
	
	StageLineData = ProductionProcessGetCurStage(ThisObject);
	
	If Not CheckIfOperationCanBeAdded(StageLineData) Then
		Return;
	EndIf;
	
	KindsOfProducts = New Array;
	KindsOfProducts.Add(MainProductProductKind);
	If ValueIsFilled(MainProductProductKind) Then
		KindsOfProducts.Add(PredefinedValue("Catalog.ItemKinds.EmptyRef"));
	EndIf;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Department",  StageLineData.Department);
	FilterStructure1.Insert("Status",         PredefinedValue("Enum.TechnologicalProcessStatuses.Valid"));
	FilterStructure1.Insert("ForFinishedProductsKind", KindsOfProducts);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterStructure1);
	FormParameters.Insert("UnitViewOnly");
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("Mode", Mode);
	NotificationParameters.Insert("RowID", StageLineData.GetID());
	
	CallbackDescription = New CallbackDescription("SelectTechnologicalProcessCompletion", ThisObject, NotificationParameters);
	
	OpenForm("Catalog.TechnologicalProcesses.ChoiceForm", FormParameters,,,,,CallbackDescription);
	
EndProcedure

&AtClient
Procedure SelectTechnologicalProcessCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	SelectProcessCompletionOnServer(Result, AdditionalParameters);
	
EndProcedure

&AtServer
Procedure SelectProcessCompletionOnServer(TechnologicalProcess, AdditionalParameters)
	
	ElementCache_      = ProductionProcessGetCacheItems();
	StageLineData = ManufacturingProcess.FindByID(AdditionalParameters.RowID);
	FromTemplate         = (AdditionalParameters.Mode = "Template");
	
	SelectionParameters = Catalogs.TechnologicalProcesses.DataSamplingParameters(?(FromTemplate, "", "Operations"));
	SelectionParameters.UpdateCommunicationKeys = True;
	SelectionParameters.ShiftingFormulas     = Object.MaterialsAndServices.Count();
	TAData = Catalogs.TechnologicalProcesses.ProcessData_(TechnologicalProcess, SelectionParameters);
		
	AddingOptions = New Structure;
	AddingOptions.Insert("CorrectNumbering");
		
	If FromTemplate Then
		RowID = AddGroupOfOperationsByTemplate(
			ElementCache_, StageLineData, TAData, AddingOptions);
	Else
		RowID = AddTypicalTechnologicalProcess(
			ElementCache_, StageLineData, TAData, AddingOptions);
	EndIf;
	
	ProductionProcessSaveCacheItems(ElementCache_);
	
	Items.ManufacturingProcess.CurrentRow = RowID;
	
	ProductionProcessUpdateDashboards();
	
	ConfigureDependentFormElements(ThisObject, "ManufacturingProcess");
	
	Modified = True;
	
EndProcedure

&AtServer
Function AddGroupOfOperationsByTemplate(ElementCache_, StageLineData, TAData, Var_Parameters)
	
	Operations = TAData.Operations;
	
	ItemsCollection     = StageLineData.GetItems(); // FormDataCollection
	ItemCount    = ItemsCollection.Count();
	MatchingOperations   = New Map;
	RowID    = Undefined;
	OperationNumberLast = ?(ItemCount = 0, 0, ItemsCollection[ItemCount-1].Number);
	FirstOperation         = ?(Operations.Count(), Operations[0].Operation, Catalogs.ManufacturingOperations.EmptyRef());
	
	For IndexOf = 0 To Operations.Count() - 1 Do
		
		OperationObject = Operations[IndexOf].Operation.Copy();
		
		OperationNumber          = OperationObject.OperationNumber + OperationNumberLast;
		NextOperation = ?(OperationObject.NextOperation = 0, 0, OperationObject.NextOperation + OperationNumberLast);
		
		OperationObject.Owner               = StageLineData.Ref;
		OperationObject.OperationNumber          = OperationNumber;
		OperationObject.NextOperation = NextOperation;
		OperationObject.Basis              = TAData.TechnologicalProcess;
		OperationObject.SetNewObjectRef(Catalogs.ManufacturingOperations.GetRef());
		
		RowID = ProductionProcessAddOfOperationToTree(
			OperationObject, ElementCache_, ItemsCollection, Var_Parameters);
		
		MatchingOperations.Insert(Operations[IndexOf].Operation, OperationObject);
		
	EndDo;
	
	For Each TSName In StrSplit("PropertyMapping,SelectionByProperties", ",") Do
		Table = Object[TSName]; // TabularSection
		For Each String In TAData[TSName] Do
			FillPropertyValues(Table.Add(), String);
		EndDo;
	EndDo;
	
	For Each TSName In StrSplit("MaterialsAndServices,LaborCosts", ",") Do
		
		Table = Object[TSName]; // TabularSection
		
		ThereIsAutoselection = False;
		For Each String In TAData[TSName] Do
			
			NewRow = Table.Add();
			FillPropertyValues(NewRow, String,, "Operation");
			NewRow.StageEditing = StageLineData.Ref;
			NewRow.StageEditingPresentation = StageLineData.Description;
			OperationObject = MatchingOperations.Get(
				?(ValueIsFilled(String.Operation), String.Operation, FirstOperation));
			If OperationObject <> Undefined Then
				NewRow.OperationEdit = OperationObject.GetNewObjectRef();
				NewRow.OperationEditPresentation = OperationObject.Description;
			EndIf;
			NewRow.ElementOfProductionProcessPresentation = RepresentationOfProductionProcessElement(ThisObject, NewRow);
			
			If TSName = "MaterialsAndServices" Then
				ProductDataManagementClientServer.FillInDefaultMethodForGettingMaterial(NewRow);
				ThereIsAutoselection = True;
			EndIf;
					
		EndDo;
		
		ProductDataManagement.FillInServiceDetailsOfAutoSelectionAndCalculationOfNumber(
			Table,
			ThereIsAutoselection,
			True,
			Object.SelectionByProperties);
		
	EndDo;
	
	Return RowID;
	
EndFunction

&AtServer
Function AddTypicalTechnologicalProcess(ElementCache_, StageLineData, TAData, Var_Parameters)
	
	ItemsCollection     = StageLineData.GetItems(); // FormDataCollection
	TechnologicalProcess = TAData.TechnologicalProcess;
	
	OperationNumber = ?(Var_Parameters.Property("OperationNumber"),
		Var_Parameters.OperationNumber,
		ProductionProcessGetNewNumber(ItemsCollection));
	NextOperation = ?(Var_Parameters.Property("NextOperation"),
		Var_Parameters.NextOperation,
		0);
	
	// Operation of the technological process
	OperationObject = Catalogs.ManufacturingOperations.CreateItem();
	OperationObject.Fill(Undefined);
	OperationObject.Owner                       = StageLineData.Ref;
	OperationObject.Description                   = String(TechnologicalProcess);
	OperationObject.OperationNumber                  = OperationNumber;
	OperationObject.NextOperation         = NextOperation;
	OperationObject.TechnologicalProcess         = TechnologicalProcess;
	OperationObject.ContainsTechnologicalProcess = True;
	OperationObject.SetNewObjectRef(Catalogs.ManufacturingOperations.GetRef());
	
	OperationObject.TechnologicalProcessFactor = TechnologicalProcessFactor(TechnologicalProcess);
	
	RowID = ProductionProcessAddOfOperationToTree(OperationObject, ElementCache_, ItemsCollection, Var_Parameters);
	
	// Technological process operations
	Operations = TAData.Operations;
	If Operations.Count() Then
		
		ItemsCollection  = ManufacturingProcess.FindByID(RowID).GetItems(); // FormDataCollection
		
		For IndexOf = 0 To Operations.Count() - 1 Do
			
			RowData = Operations[IndexOf];
			
			NewRow = ItemsCollection.Add();
			NewRow.Ref          = RowData.Operation;
			NewRow.Description    = RowData.Description;
			NewRow.Number           = RowData.OperationNumber;
			NewRow.TheNumberOfTheNextOne = RowData.NextOperation;
			NewRow.WorkCenter    = RowData.WorkCenter;
			NewRow.ReadOnly  = True;
			NewRow.ItemKind     = TypeOfElementOfOperation();
			ProductionProcessEditorClientServer.SetItemImage(NewRow);
			
		EndDo;
		
	EndIf;
	
	Return RowID;
	
EndFunction

&AtServer
Procedure ProductionProcessCorrectNumberingAfterAddingItem(ElementCache_, Collection, TheNumberOfTheNextOne)
	
	If Collection.Count() < 2 Then
		Return;
	EndIf;
	
	RowData = Collection[Collection.Count()-2];
	
	If RowData.TheNumberOfTheNextOne <> 0 Then
		Return;
	EndIf;
	
	DescriptionOfElementProperties_ = ProductionProcessCache.DescriptionOfElementProperties_; // Map
	ItemProperties = DescriptionOfElementProperties_.Get(RowData.ItemKind);
	
	If ProductionProcessCurrentLink = RowData.Ref Then
		
		ObjectData = ThisObject[ItemProperties.ObjectAttributeName];
		ObjectData[ItemProperties.TheNumberOfTheNextOne] = TheNumberOfTheNextOne;
		
	Else
		
		ElementCache = ProductionProcessGetItemCache(ElementCache_, RowData, True);
		ElementCache.Object[ItemProperties.TheNumberOfTheNextOne] = TheNumberOfTheNextOne;
		ElementCache.Write = True;
		
	EndIf;
	
	RowData.TheNumberOfTheNextOne = TheNumberOfTheNextOne;
	
EndProcedure

#EndRegion

#Region RemovingElements

&AtClient
Function CheckPossibilityOfRemovingElementsOfProductionProcess(RowsIDs)
	
	WarningText = "";
	NamesOfTS = TabularSectionNames();
	
	If RowsIDs.Count() = 0 Then
		
		WarningText = NStr("vi = 'Cần chọn các phần tử để xóa.';
							|ru = 'Необходимо выделить элементы для удаления.';
							|en = 'Select the items to delete.'; fa = 'Select the items to delete.';
							|it = 'È necessario contrassegnare gli elementi per l''eliminazione.';
							|pl = 'Należy wybrać elementy do usunięcia.';
							|tr = 'Silinecek öğeleri ayırmanız gerekmektedir.'");
		
	Else
		
		ElementsUsed = New Structure;
		For Each ItemKind In ProductionProcessEditorClientServer.ItemsKinds() Do
			ElementsUsed.Insert(ItemKind, New Array);
		EndDo;
		
		For Each RowID In RowsIDs Do
			
			RowData = ManufacturingProcess.FindByID(RowID);
			ItemKind  = RowData.ItemKind;
			
			EditElement = Undefined;
			If Not ProductionProcessCache.DescriptionOfElementProperties_.Get(ItemKind).Property("Edit", EditElement) Then
				Continue;
			EndIf;
			
			FilterStructure1 = New Structure(EditElement, RowData.Ref);
			For Each TSName In NamesOfTS Do
				If Object[TSName].FindRows(FilterStructure1).Count() > 0 Then
					ElementsUsed[ItemKind].Add(RowData.Description);
					Break;
				EndIf;
			EndDo;
			
		EndDo;
		
		For Each ItemKind In ProductionProcessEditorClientServer.ItemsKinds() Do
			NumberOfUsed = ElementsUsed[ItemKind].Count();
			If NumberOfUsed > 0 Then
				If NumberOfUsed = 1 Then
					WarningText = StrTemplate(NStr("vi = '""%1"" đang sử dụng trong bảng kê chi tiết. Không thể xóa.';
													|ru = '""%1"" используется в спецификации. Удаление невозможно.';
													|en = '""%1"" is used in the bill of materials. It cannot be deleted.'; fa = '""%1"" is used in the bill of materials. It cannot be deleted.';
													|it = '""%1"" è usata nella specifica. Impossibile eliminare.';
													|pl = '""%1"" jest wykorzystywany w specyfikacji. Usunięcie nie jest możliwe.';
													|tr = 'Ürün reçetesinde ""%1"" kullanılmaktadır. Silinmesi mümkün değildir.'"),
						ElementsUsed[ItemKind][0]);
				Else
					WarningText = StrTemplate(NStr("vi = 'Các phần tử dưới đây được sử dụng trong bảng kê chi tiết:
						|%1
						|
						|Không thể xóa.';
						|ru = 'Нижеследующие элементы используется в спецификации:
						|%1
						|
						|Удаление невозможно.';
						|en = 'The following items are used in the bill of materials:
						|%1
						|
						|They cannot be deleted.'; fa = 'The following items are used in the bill of materials:
						|%1
						|
						|They cannot be deleted.';
						|it = 'Gli elementi di seguito vengono utilizzati nella specifica:
						|%1
						|
						|Impossibile eliminare.';
						|pl = 'Następujące elementy są używane w specyfikacji:
						|%1
						|
						|Usunięcie jest niemożliwe.';
						|tr = 'Aşağıdaki öğeler ürün reçetesinde kullanılmaktadır:
						|%1
						|
						|Silinmesi mümkün değildir.'"), StrConcat(ElementsUsed[ItemKind], Chars.LF));
				EndIf;
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
	If Not IsBlankString(WarningText) Then
		ShowMessageBox(, WarningText);
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

&AtServer
Procedure ProductionProcessRemoveItems(RowsIDs)
	
	ElementCache_ = ProductionProcessGetCacheItems();
	RemoteCounter = New Structure;
	ThereIsTA = False;
	SenderSelectionStructure = New Structure("StageSender");
	StructureOfSelectionStage = New Structure("Stage");
	SelectionStructureCommunicationKey = New Structure("ConnectionKey");
	While RowsIDs.Count() > 0 Do
		
		CurrentID = RowsIDs[0];
		
		RowData = ManufacturingProcess.FindByID(CurrentID);
		If RowData <> Undefined And Not RowData.ReadOnly Then
			
			ItemKind = RowData.ItemKind;
			
			SubordinateRows = RowData.GetItems();
			If SubordinateRows.Count() > 0 Then
				For Each SubordinateRow In SubordinateRows Do
					If Not SubordinateRow.ReadOnly Then
						RowsIDs.Insert(0, SubordinateRow.GetID())
					EndIf;
				EndDo;
				If RowsIDs[0] <> CurrentID Then
					Continue;
				EndIf;
			EndIf;
			
			ElementCache = ProductionProcessGetItemCache(ElementCache_, RowData);
			ElementCache.Removed = True;
			
			If RemoteCounter.Property(ItemKind) Then
				RemoteCounter[ItemKind] = RemoteCounter[ItemKind] + 1;
			Else
				RemoteCounter.Insert(ItemKind, 1);
			EndIf;
			If ValueIsFilled(RowData.TechnologicalProcess) Then
				ThereIsTA = True;
			EndIf;
			
			If ItemKind = TypeOfStageElement() Then
				If Object.IntermediateRelease.Count() > 0 Then
					SenderSelectionStructure.StageSender = RowData.Ref;
					For Each String In Object.IntermediateRelease.FindRows(SenderSelectionStructure) Do
						Object.IntermediateRelease.Delete(String);
					EndDo;
				EndIf;
				If Object.WorksToPerform.Count() > 0 Then
					StructureOfSelectionStage.Stage = RowData.Ref;
					For Each String In Object.WorksToPerform.FindRows(StructureOfSelectionStage) Do
						Object.WorksToPerform.Delete(String);
					EndDo;
				EndIf;
			ElsIf ItemKind = TypeOfWorkElement() Then
				SelectionStructureCommunicationKey.ConnectionKey = RowData.Ref;
				For Each String In Object.WorksToPerform.FindRows(SelectionStructureCommunicationKey) Do
					Object.WorksToPerform.Delete(String);
				EndDo;
			EndIf;
			ItemsCollection = ProductionProcessGetParent(ThisObject, RowData).GetItems();
			ItemsCollection.Delete(RowData);
			
		EndIf;
		
		RowsIDs.Delete(0);
		
	EndDo;
	
	ProductionProcessSaveCacheItems(ElementCache_);
	
	ProductionProcessCurrentLink = Undefined;
	If ThereIsTA Then
		ProductionProcessUpdateDashboards();
	EndIf;
	For Each KeyAndValue In RemoteCounter Do
		ProductionProcessONChangesInCompositionOfElements(KeyAndValue.Key, -KeyAndValue.Value);
	EndDo;
	
	ConfigureDependentFormElements(ThisObject, "ManufacturingProcess");
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region CopyingElements

&AtClient
Procedure ProductionProcessStartCopyingItem(RowData)
	
	If RowData = Undefined Then
		Return;
	EndIf;
	
	If RowData.ItemKind = TypeOfStageElement()
		And Not CheckPossibilityOfAddingStage() Then
		Return;
	EndIf;
	
	ProductionProcessCopyItemToServer(RowData.GetID());
	
EndProcedure

&AtServer
Procedure ProductionProcessCopyItemToServer(RowID)
	
	RowData = ManufacturingProcess.FindByID(RowID);
	If RowData = Undefined Or RowData.ReadOnly Then
		Return;
	EndIf;
	
	ElementCache_ = ProductionProcessGetCacheItems();
	
	ProductionProcessCacheCurItem(ElementCache_);
	
	NewRow = ProductionProcessCopyElementRecursively(
		ProductionProcessGetParent(ThisObject, RowData).GetItems(), RowData, ElementCache_);
	
	ProductionProcessSaveCacheItems(ElementCache_);
	
	Items.ManufacturingProcess.CurrentRow = NewRow;
	
	ProcessManufacturingProcessChange(NewRow);
	
	Modified = True;
	
EndProcedure

&AtServer
Function ProductionProcessCopyElementRecursively(ItemsCollection, SourceStringData, ElementCache_)
	
	NewRow = ItemsCollection.Add();
	FillPropertyValues(NewRow, SourceStringData);
	
	If Not NewRow.ReadOnly Then
		
		DescriptionOfElementProperties_ = ProductionProcessCache.DescriptionOfElementProperties_; // Map
		ItemProperties = DescriptionOfElementProperties_.Get(SourceStringData.ItemKind);
		
		NewRowParent  = NewRow.GetParent();
		SourceElementCache = ProductionProcessGetItemCache(ElementCache_, SourceStringData, True);
		CacheOfReceiverElement = ProductionProcessItemCacheConstructor(SourceStringData.ItemKind);
		
		If SourceElementCache.ContainsObject Then
			NewObject = SourceElementCache.Object.Copy();
			NewObject.SetNewObjectRef(Catalogs[ItemProperties.ItemTypeName].GetRef());
			FillPropertyValues(NewObject, SourceElementCache.Object, ItemProperties.Number+","+ItemProperties.TheNumberOfTheNextOne);
			If SourceStringData.ItemKind = TypeOfElementOfOperation() Then
				NewObject.Owner = NewRowParent.Ref;
			EndIf;
			NewRow.Ref = NewObject.GetNewObjectRef();
			CacheOfReceiverElement.Write = True;
			CacheOfReceiverElement.Object     = NewObject;
			ProductionProcessAdjustRowPosition(ThisObject, NewRow);
		ElsIf SourceStringData.ItemKind = TypeOfWorkElement() Then
			NewLineWork = Object.WorksToPerform.Add();
			FillPropertyValues(NewLineWork, ProductionProcessElementData(ThisObject, SourceStringData));
			NewLineWork.Stage = NewRowParent.Ref;
			NewLineWork.ConnectionKey = New UUID();
			NewRow.Ref = NewLineWork.ConnectionKey;
		EndIf;
		
		ElementCache_.Insert(NewRow.Ref, CacheOfReceiverElement);
		
		ProductionProcessONChangesInCompositionOfElements(SourceStringData.ItemKind, 1);
		
		For Each SubordinateRow In SourceStringData.GetItems() Do
			ProductionProcessCopyElementRecursively(
				NewRow.GetItems(), SubordinateRow, ElementCache_);
		EndDo;
		
	EndIf;
	
	Return NewRow.GetID();
	
EndFunction

#EndRegion

#Region MovingItems

&AtServerNoContext
Function CompareLinks(Ref1, Ref2)
	
	LinkComparison = New CompareValues();
	Return LinkComparison.Compare(Ref1, Ref2);
	
EndFunction

&AtClient
Procedure ProductionProcessMoveElement(RowData, Offset)
	
	If RowData = Undefined Or RowData.ReadOnly Then
		Return;
	EndIf;
	
	ProductionProcessMoveItemToServer(RowData.GetID(), Offset);
	
EndProcedure

&AtServer
Procedure ProductionProcessMoveItemToServer(RowID, Offset)
	
	DescriptionOfElementProperties_ = ProductionProcessCache.DescriptionOfElementProperties_; // Map
	CurrentData            = ManufacturingProcess.FindByID(RowID);
	
	ItemsCollection      = ProductionProcessGetParent(ThisObject, CurrentData).GetItems();
	ElementIndex          = ItemsCollection.IndexOf(CurrentData);
	IndexOfBoundaryElement = ?(Offset < 0, 0, ItemsCollection.Count()-1);
	
	If ElementIndex = IndexOfBoundaryElement
			Or (Offset < 0 And CurrentData.Number = 1) Then
		Return;
	EndIf;
	
	ElementCache_         = ProductionProcessGetCacheItems();
	ItemProperties     = DescriptionOfElementProperties_.Get(CurrentData.ItemKind);
	OffsetStep          = ?(Offset < 0, -1, 1);
	
	If ItemProperties.ContainsObject Then
	
		NewNumber           = CurrentData.Number + Offset;
		NewNumberIsAsFollows = CurrentData.TheNumberOfTheNextOne;
		
		While True Do
			
			ElementIndex = ElementIndex + OffsetStep;
			If ElementIndex = (IndexOfBoundaryElement + OffsetStep)
					Or ItemsCollection[ElementIndex].Number <> NewNumber Then
				Break;
			EndIf;
			
			String = ItemsCollection[ElementIndex];
			If CurrentData.TheNumberOfTheNextOne = String.Number
					Or CurrentData.Number = String.TheNumberOfTheNextOne Then
				NewNumberIsAsFollows = String.TheNumberOfTheNextOne;
				String.TheNumberOfTheNextOne = CurrentData.TheNumberOfTheNextOne;
			EndIf;
			String.Number = String.Number - OffsetStep;
			
			ElementCache = ProductionProcessGetItemCache(ElementCache_, String, True);
			ElementCache.Object[ItemProperties.Number]           = String.Number;
			ElementCache.Object[ItemProperties.TheNumberOfTheNextOne] = String.TheNumberOfTheNextOne;
			ElementCache.Write = True;
			
		EndDo;
		
		CurrentData.Number           = NewNumber;
		CurrentData.TheNumberOfTheNextOne = NewNumberIsAsFollows;
		
		CurrentObject = ThisObject[ItemProperties.ObjectAttributeName];
		CurrentObject[ItemProperties.Number]           = CurrentData.Number;
		CurrentObject[ItemProperties.TheNumberOfTheNextOne] = CurrentData.TheNumberOfTheNextOne;
		
		ProductionProcessAdjustRowPosition(ThisObject, CurrentData);
	ElsIf CurrentData.ItemKind = TypeOfWorkElement() Then
		
		If (ElementIndex + OffsetStep) <> (IndexOfBoundaryElement + OffsetStep) Then
			
			ItemsCollection.Move(ElementIndex, OffsetStep);
			
		EndIf;
	EndIf;
	
	ProductionProcessSaveCacheItems(ElementCache_);
	
	ProcessManufacturingProcessChange(RowID);
	
	Modified = True;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ProductionProcessAdjustRowPosition(Form, RowData)
	
	ItemParent       = ProductionProcessGetParent(Form, RowData);
	ItemsCollection     = ItemParent.GetItems();
	ItemCount    = ItemsCollection.Count();
	IndexOfCurElement = ItemsCollection.IndexOf(RowData);
	
	While IndexOfCurElement > 0
		And (ItemsCollection[IndexOfCurElement-1].Number > RowData.Number
			Or (ItemsCollection[IndexOfCurElement-1].Number = RowData.Number
				And CompareLinks(ItemsCollection[IndexOfCurElement-1].Ref, RowData.Ref) > 0)) Do
		ItemsCollection.Move(IndexOfCurElement,-1);
		IndexOfCurElement = IndexOfCurElement - 1;
	EndDo;
	
	While IndexOfCurElement < (ItemCount - 1)
		And (ItemsCollection[IndexOfCurElement+1].Number < RowData.Number
			Or (ItemsCollection[IndexOfCurElement+1].Number = RowData.Number
				And CompareLinks(ItemsCollection[IndexOfCurElement+1].Ref, RowData.Ref) < 0)) Do
		ItemsCollection.Move(IndexOfCurElement,1);
		IndexOfCurElement = IndexOfCurElement + 1;
	EndDo;
	
EndProcedure

#EndRegion

#Region AllocateToTechnologicalProcess

&AtClient
Function CheckPossibilityToAllocateToTechnologicalProcess(RowsIDs, AdditionalParameters)
	
	WarningText = "";
	
	If Not ValueIsFilled(RowsIDs) Then
		WarningText = NStr("vi = 'Cần chọn dòng.';
							|ru = 'Необходимо выделить строки.';
							|en = 'Select the lines.'; fa = 'Select the lines.';
							|it = 'Select the lines.';
							|pl = 'Select the lines.';
							|tr = 'Satırların seçilmesi gerekmektedir.'");
	Else
		AdditionalParameters.Insert("RowsIDs", RowsIDs);
		CollectDataForTransferToProcess(AdditionalParameters);
		If AdditionalParameters.OperationsCount = 0 Then
			WarningText = NStr("vi = 'Các dòng được chọn không chứa giao dịch.';
								|ru = 'Выделенные строки не содержат операций.';
								|en = 'The selected lines do not contain operations.'; fa = 'The selected lines do not contain operations.';
								|it = 'The selected lines do not contain operations.';
								|pl = 'The selected lines do not contain operations.';
								|tr = 'Seçilen satırlar işlem içermiyor.'");
		ElsIf AdditionalParameters.Departments.Count() > 1 Then
			WarningText = NStr("vi = 'Không cần tách chọn giao dịch được thực hiện trong các bộ phận khác nhau.';
								|ru = 'Нельзя выделять операции, выполняемые в разных подразделениях.';
								|en = 'Cannot select operations performed in different business units.'; fa = 'Cannot select operations performed in different business units.';
								|it = 'Cannot select operations performed in different business units.';
								|pl = 'Cannot select operations performed in different business units.';
								|tr = 'Farklı departmanlarda gerçekleştirilen işlemler ayrıştırılamaz.'");
		EndIf;
	EndIf;
	
	If Not IsBlankString(WarningText) Then
		ShowMessageBox(, WarningText);
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

// Table of operations to transfer to the process.
// 
// Returns:
//  ValueTable - Table of Operations To Transfer To The Technical Process Constructor:
// * RowData - FormDataTreeItem
// * Ref - CatalogRef.ManufacturingOperations
// * Description - String
// * TechnologicalProcess - CatalogRef.TechnologicalProcesses
// * RelatedMaterials - Boolean
// * RelatedLaborCosts - Boolean
// * OperationObject - CatalogObject.ManufacturingOperations
&AtServer
Function TableOfOperationsToTransferToTechnicalProcessConstructor()
	
	TransactionTable = New ValueTable;
	
	TransactionTable.Columns.Add("RowData");
	TransactionTable.Columns.Add("Ref",                    New TypeDescription("CatalogRef.ManufacturingOperations"));
	TransactionTable.Columns.Add("Description",              New TypeDescription("String"));
	
	TransactionTable.Columns.Add("TechnologicalProcess",    New TypeDescription("CatalogRef.TechnologicalProcesses"));
	TransactionTable.Columns.Add("ZoomRatio",               New TypeDescription("Number"));
	
	TransactionTable.Columns.Add("OperationObject",            New TypeDescription("CatalogObject.ManufacturingOperations"));
	TransactionTable.Columns.Add("RelatedResources",          New TypeDescription());
	
	Return TransactionTable;
	
EndFunction

&AtServer
Procedure CollectDataForTransferToProcess(AdditionalParameters)
	
	ElementCache_ = ProductionProcessGetCacheItems();
	
	Stages                      = New Array;
	Departments              = New Array;
	TechnologicalProcesses    = New Array;
	TransactionTable            = TableOfOperationsToTransferToTechnicalProcessConstructor();
	StageName          = "";
	CanBeConnectedToStage      = True;
	SequenceIsInterrupted = False;
	
	RowData = Undefined;
	While ProductionProcessIsFollowingElement(ThisObject, RowData) Do
		
		If Not RowData.ItemKind = TypeOfElementOfOperation()
				Or ValueIsFilled(RowData.TechnologicalProcess) Then
			Continue;
		EndIf;
		
		If ProductionProcessLineHighlighted(ThisObject, RowData, AdditionalParameters.RowsIDs) Then
		
			StageLineData    = ProductionProcessGetCurStage(ThisObject, RowData);
			ParentRowData = RowData.GetParent();
			
			NewRow = TransactionTable.Add();
			FillPropertyValues(NewRow, RowData);
			NewRow.RowData = RowData;
			
			Stages.Add(StageLineData.Ref);
			Departments.Add(StageLineData.Department);
			StageName = StageLineData.Description;
			
			If ValueIsFilled(ParentRowData.TechnologicalProcess) Then
				ElementCache = ProductionProcessGetItemCache(ElementCache_, ParentRowData, True);
				NewRow.TechnologicalProcess = ElementCache.Object.TechnologicalProcess;
				NewRow.ZoomRatio = ElementCache.Object.TechnologicalProcessFactor;
				TechnologicalProcesses.Add(NewRow.TechnologicalProcess);
			Else
				NewRow.ZoomRatio = 1;
			EndIf;
			
			ReadRelatedResourcesOfOperations(NewRow, AdditionalParameters);
			
			If SequenceIsInterrupted Then
				CanBeConnectedToStage = False;
			EndIf;
			
		Else
			
			If TransactionTable.Count() > 0 Then
				SequenceIsInterrupted = True;
			EndIf;
		
		EndIf;
		
	EndDo;
	
	AdditionalParameters.Insert("AddressOfOFOperationsTable",    PutToTempStorage(TransactionTable, UUID));
	AdditionalParameters.Insert("Stages",                   CommonClientServer.CollapseArray(Stages));
	AdditionalParameters.Insert("Departments",           CommonClientServer.CollapseArray(Departments));
	AdditionalParameters.Insert("TechnologicalProcesses", CommonClientServer.CollapseArray(TechnologicalProcesses));
	AdditionalParameters.Insert("StageName",       StageName);
	AdditionalParameters.Insert("AttributeAvailability",   AttributeAvailability);
	AdditionalParameters.Insert("TechProcessesData",      Undefined);
	AdditionalParameters.Insert("OperationsCount",      TransactionTable.Count());
	
	CanBeConnectedToStage = CanBeConnectedToStage
								And AdditionalParameters.Stages.Count() = 1
								And AdditionalParameters.TechnologicalProcesses.Count() = 0;
	AdditionalParameters.Insert("CanBeConnectedToStage",   CanBeConnectedToStage);
	
	ProductionProcessSaveCacheItems(ElementCache_);
	
EndProcedure

&AtClientAtServerNoContext
Function RelatedResourcesConstructor()
	
	Result = New Structure;
	
	Result.Insert("MainTS",  "MaterialsAndServices,LaborCosts");
	Result.Insert("DependentTS", "PropertyMapping,SelectionByProperties");
	
	Return Result;
	
EndFunction

&AtServer
Procedure ReadRelatedResourcesOfOperations(RowOfOperationsTable, AdditionalParameters)
	
	RelatedResources = RelatedResourcesConstructor();
	FilterOperation    = New Structure("OperationEdit", RowOfOperationsTable.Ref);
	FilterConnectionKey   = New Structure("ConnectionKey");
	
	If ValueIsFilled(RowOfOperationsTable.TechnologicalProcess) Then
		TechProcessesData = Undefined;
		If Not AdditionalParameters.Property("TechProcessesData", TechProcessesData) Then
			TechProcessesData = New Map;
			AdditionalParameters.Insert("TechProcessesData", TechProcessesData);
		EndIf;
		DataSource = TechProcessesData.Get(RowOfOperationsTable.TechnologicalProcess);
		If DataSource = Undefined Then
			SelectionParameters = Catalogs.TechnologicalProcesses.DataSamplingParameters();
			SelectionParameters.UpdateCommunicationKeys = True;
			DataSource = Catalogs.TechnologicalProcesses.ProcessData_(
				RowOfOperationsTable.TechnologicalProcess, SelectionParameters);
			TechProcessesData.Insert(RowOfOperationsTable.TechnologicalProcess, DataSource);
		EndIf;
	Else
		DataSource = Object;
	EndIf;
	
	For Each TSName In StrSplit(RelatedResources.MainTS, ",") Do
		FoundRows = DataSource[TSName].FindRows(FilterOperation);
		If ValueIsFilled(FoundRows) Then
			RelatedResources.Insert(TSName, FoundRows);
			For Each String In FoundRows Do
				FilterConnectionKey.ConnectionKey = String.ConnectionKey;
				For Each NameOfDependentPM In StrSplit(RelatedResources.DependentTS, ",") Do
					DependentStringsFound = DataSource[NameOfDependentPM].FindRows(FilterConnectionKey);
					If ValueIsFilled(DependentStringsFound) Then
						If Not RelatedResources.Property(NameOfDependentPM) Then
							RelatedResources.Insert(NameOfDependentPM, New Array);
						EndIf;
						CommonClientServer.SupplementArray(RelatedResources[NameOfDependentPM], DependentStringsFound);
					EndIf;
				EndDo;
			EndDo;
			AdditionalParameters.Insert(TSName, True);
			RowOfOperationsTable.RelatedResources = RelatedResources;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure MigrateRelatedResourcesOfOperations(RowOfOperationsTable, TechnicalProcessObject, SettingsResult)
	
	RelatedResources = RowOfOperationsTable.RelatedResources;
	If Not ValueIsFilled(RelatedResources) Then
		Return;
	EndIf;
	
	OperationRef     = RowOfOperationsTable.OperationObject.GetNewObjectRef();
	MatchingKeys = New Map();
	
	For Each TSName In StrSplit(RelatedResources.MainTS, ",") Do
		If SettingsResult[TSName] And RelatedResources.Property(TSName) Then
			For Each TSRow In RelatedResources[TSName] Do
				TabularSection = TechnicalProcessObject[TSName]; // TabularSection
				NewRow = TabularSection.Add();
				FillPropertyValues(NewRow, TSRow);
				NewRow.OperationEdit = OperationRef;
				NewRow.ConnectionKey = New UUID();
				MatchingKeys.Insert(TSRow.ConnectionKey, NewRow.ConnectionKey);
				AttributeName = "NumberOfPackages";
				If Not CommonClientServer.HasAttributeOrObjectProperty(NewRow, AttributeName) Then
					AttributeName = "Count";
				EndIf;
				NewRow[AttributeName] = NewRow[AttributeName] * RowOfOperationsTable.ZoomRatio;
			EndDo;
		EndIf;
	EndDo;
	
	For Each NameOfDependentPM In StrSplit(RelatedResources.DependentTS, ",") Do
		If RelatedResources.Property(NameOfDependentPM) Then
			For Each TSRow In RelatedResources[NameOfDependentPM] Do
				TabularSection = TechnicalProcessObject[NameOfDependentPM]; // TabularSection
				NewKey = MatchingKeys.Get(TSRow.ConnectionKey);
				If ValueIsFilled(NewKey) Then
					NewRow = TabularSection.Add();
					FillPropertyValues(NewRow, TSRow);
					NewRow.ConnectionKey = NewKey;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure ReassignExcludeRelatedResources(RowOfOperationsTable, ContainerLinkOperation, SettingsResult)
	
	RelatedResources = RowOfOperationsTable.RelatedResources;
	If Not ValueIsFilled(RelatedResources)
			Or ValueIsFilled(RowOfOperationsTable.TechnologicalProcess) Then
		Return;
	EndIf;
	
	For Each TSName In StrSplit(RelatedResources.MainTS, ",") Do
		If RelatedResources.Property(TSName) Then
			For Each TSRow In RelatedResources[TSName] Do
				If SettingsResult[TSName] Then
					Object[TSName].Delete(TSRow);
				Else
					TSRow.OperationEdit = ContainerLinkOperation;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure AllocateToTechnologicalProcessCompletion(SettingsResult, AdditionalParameters) Export
	
	If ValueIsFilled(SettingsResult) Then
		
		Result = AllocateToTechnologicalProcess(SettingsResult, AdditionalParameters);
		
		If ValueIsFilled(Result) Then
			If Not SettingsResult.ConnectToStage
				Or Result.Status <> PredefinedValue("Enum.TechnologicalProcessStatuses.Valid") Then
				ShowValue(, Result.TechnologicalProcess);
			EndIf;
		Else
			WarningText = NStr("vi = 'Không thể tạo quy trình công nghệ.
			|Chi tiết xem trong nhật ký sự kiện.';
			|ru = 'Не удалось создать технологический процесс.
			|Подробности см. в журнале регистрации.';
			|en = 'Cannot create the technological process.
			|For more information, see the event log.'; fa = 'Cannot create the technological process.
			|For more information, see the event log.';
			|it = 'Non è stato possibile creare il processo tecnologico.
			|Per maggiori dettagli, consultare il registro.';
			|pl = 'Nie udało się utworzyć procesu technologicznego..
			|Więcej patrz w dzienniku rejestracji.';
			|tr = 'Teknolojik süreç oluşturulamadı.
			|Ayrıntılar için olay günlüğüne bakın.'");
			ShowMessageBox(,WarningText);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function AllocateToTechnologicalProcess(SettingsResult, AdditionalParameters)
	
	ElementCache_ = ProductionProcessGetCacheItems();
	ProductionProcessCacheCurItem(ElementCache_);
	
	TechProcessLink = Catalogs.TechnologicalProcesses.GetRef();
	
	TechnicalProcessObject = Catalogs.TechnologicalProcesses.CreateItem();
	TechnicalProcessObject.SetNewObjectRef(TechProcessLink);
	TechnicalProcessObject.Fill(Undefined);
	
	TechnicalProcessObject.Description   = SettingsResult.NameOfProcessTechnology;
	TechnicalProcessObject.Department  = AdditionalParameters.Departments[0];
	TechnicalProcessObject.ForFinishedProductsKind = MainProductProductKind;
	
	TransactionTable = GetFromTempStorage(AdditionalParameters.AddressOfOFOperationsTable); // TableOfOperationsToTransferToTechnicalProcessConstructor
	
	#Region DataPreparation
	
	For IndexOf = 0 To TransactionTable.Count() - 1 Do
		
		TableRow = TransactionTable[IndexOf];
		
		ElementCache = ProductionProcessGetItemCache(ElementCache_, TableRow.RowData, True);
		
		OperationObject = ElementCache.Object.Copy(); // CatalogObject.ManufacturingOperations
		TableRow.OperationObject = OperationObject;
		
		OperationObject.SetNewObjectRef(Catalogs.ManufacturingOperations.GetRef());
		OperationObject.Owner   = TechProcessLink;
		OperationObject.Count = OperationObject.Count * TableRow.ZoomRatio;
		
		If SettingsResult.Renumber Then
			OperationObject.OperationNumber          = IndexOf + 1;
			OperationObject.NextOperation = 0;
			If IndexOf > 0 Then
				TransactionTable[IndexOf-1].OperationObject.NextOperation = IndexOf + 1;
			EndIf;
		EndIf;
		
		MigrateRelatedResourcesOfOperations(TableRow, TechnicalProcessObject, SettingsResult);
		
	EndDo;
	
	#EndRegion
	
	#Region DataWriter
	
	BeginTransaction();
	Try
		
		TechnicalProcessObject.Write();
		
		For IndexOf = 0 To TransactionTable.Count() - 1 Do
			
			OperationObject = TransactionTable[IndexOf].OperationObject; // CatalogObject
			OperationObject.Write();
			
		EndDo;
		
		TechnicalProcessObject.Status = Enums.TechnologicalProcessStatuses.Valid;
		If TechnicalProcessObject.CheckFilling() Then
			TechnicalProcessObject.Write();
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		EventName = NStr("vi = 'Không thể ghi lại quy trình công nghệ.';
						|ru = 'Не удалось записать технологический процесс.';
						|en = 'Cannot save the technological process.'; fa = 'Cannot save the technological process.';
						|it = 'Impossibile registrare il processo tecnologico.';
						|pl = 'Nie udało się zapisać procesu technologicznego.';
						|tr = 'Teknolojik süreç kaydedilemedi.'", Common.DefaultLanguageCode());
		WriteLogEvent(
			EventName,
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		Return Undefined;
		
	EndTry;
	
	#EndRegion
	
	#Region ConnectingToStage
	
	ConnectTechnologicalProcessToStage(ElementCache_, TechProcessLink, TransactionTable, SettingsResult);
	
	#EndRegion
	
	Result = New Structure;
	Result.Insert("TechnologicalProcess", TechProcessLink);
	Result.Insert("Status",                 TechnicalProcessObject.Status);
	
	Return Result;
	
EndFunction

&AtServer
Procedure ConnectTechnologicalProcessToStage(ElementCache_, TechProcessLink, TransactionTable, SettingsResult)
	
	If Not SettingsResult.ConnectToStage Then
		Return;
	EndIf;
	
	StageLineData     = TransactionTable[0].RowData.GetParent(); // FormDataTreeItem
	ItemsCollection    = StageLineData.GetItems(); // FormDataTreeItemCollection
	DataOfFirstLine    = TransactionTable[0].RowData;
	LastRowData = TransactionTable[TransactionTable.Count()-1].RowData;
	OffsetNumbering     = TransactionTable.Count() - 1;
	
	AddingOptions = New Structure("OperationNumber,NextOperation", DataOfFirstLine.Number, DataOfFirstLine.TheNumberOfTheNextOne);
	If ItemsCollection.IndexOf(LastRowData) = ItemsCollection.Count()-1 Then
		AddingOptions.NextOperation = 0;
	EndIf;
	
	TAData = Catalogs.TechnologicalProcesses.ProcessData_(
		TechProcessLink, Catalogs.TechnologicalProcesses.DataSamplingParameters("Operations"));
	RowID = AddTypicalTechnologicalProcess(ElementCache_, StageLineData, TAData, AddingOptions);
	TPLineData = ManufacturingProcess.FindByID(RowID);
	
	For IndexOf = 0 To TransactionTable.Count() - 1 Do
		
		RowOfOperationsTable = TransactionTable[IndexOf];
		
		ElementCache  = ProductionProcessGetItemCache(ElementCache_, RowOfOperationsTable.RowData, True);
		ElementCache.Removed = True;
		ItemsCollection.Delete(RowOfOperationsTable.RowData);
		
		ReassignExcludeRelatedResources(RowOfOperationsTable, TPLineData.Ref, SettingsResult);
		
	EndDo;
	
	ProductionProcessAdjustRowPosition(ThisObject, TPLineData);
	
	If OffsetNumbering > 0 Then
		For RowIndex = ItemsCollection.IndexOf(TPLineData) + 1 To ItemsCollection.Count() - 1 Do
			
			RowData = ItemsCollection.Get(RowIndex);
			
			RowData.Number                        = RowData.Number - OffsetNumbering;
			RowData.TheNumberOfTheNextOne              = RowData.TheNumberOfTheNextOne - OffsetNumbering;
			ElementCache = ProductionProcessGetItemCache(ElementCache_, RowData, True);
			ElementCache.Object.OperationNumber          = RowData.Number;
			ElementCache.Object.NextOperation = RowData.TheNumberOfTheNextOne;
			ElementCache.Write = True;
			
		EndDo;
	EndIf;
	
	ProductionProcessUpdatePresentation(TPLineData.ItemKind, TPLineData.Ref, TPLineData.Description, ThisObject);
	ProductionProcessUpdateDashboards();
	ProductionProcessONChangesInCompositionOfElements(TPLineData.ItemKind, -TransactionTable.Count());
	
	Modified = True;
	ProductionProcessSaveCacheItems(ElementCache_);
	
EndProcedure

#EndRegion

#Region EditingStageProperties

&AtClientAtServerNoContext
Procedure SetBlankMarkForBuffers(Form)
	
	RequiredFilling = ProductionProcessEditorClientServer.MandatoryFillingOfUnitsOfMeasurementOfBuffers(
		Form.ProductionProcessStage);
	
	DescriptionOfElementProperties_ = Form.ProductionProcessCache.DescriptionOfElementProperties_; // Map
	ItemsProperties = DescriptionOfElementProperties_.Get(TypeOfStageElement());
	
	For Each KeyAndValue In RequiredFilling Do
		Form.Items[ItemsProperties[KeyAndValue.Key]].MarkIncomplete = KeyAndValue.Value;
	EndDo;
	
EndProcedure

&AtClient
Procedure CalculateStageDuration()
	
	If ProductionProcessEditorClientServer.CalculateDurationAutomatically(ProductionProcessStage,
		ProductionIsUsed21,
		PlanningByMaterialResourcesIsUsed,
		PlanningByProductionResourcesIsUsed) Then
		CalculateDurationOfStageOnServer();
	EndIf;
	
	Return; // empty handler
	
EndProcedure

&AtServer
Procedure FillInSelectionOfBuffersUnit(ThisIsReadingObject)
	
	ProductionProcessEditor.FillInSelectionOfBufferUnit(
		PlanningIntervalStage,
		Items.StagePreBufferUnitOfMeasurement.ChoiceList);
	
	ProductionProcessEditor.FillInSelectionOfBufferUnit(
		PlanningIntervalStage,
		Items.StageTheUnitOfMeasurementOfTheTerminatingBuffer.ChoiceList);
	
	ProductionProcessEditor.CheckSelectionOfBufferUnit(
		ProductionProcessStage, ThisObject, Not ThisIsReadingObject, "Stage");
	
EndProcedure

&AtServer
Procedure StageProductionMethodWhenModifiedOnServer()
	
	ProductionProcessStage.ProductionByThirdParty = Boolean(StageProductionMethod);
	AttributesList = "ProductionMethod";
	
	If ProductionProcessStage.ProductionByThirdParty Then
		
		ProductionProcessStage.PlanOperationsOfWorkCenterTypes = False;
		ProductionProcessStage.RouteSheet  = Undefined;
		ProductionProcessStage.RouteSheetFactor = 0;
		
		AttributesList = AttributesList+",PlanOperationsOfWorkCenterTypes,RouteSheet";
		
		PartnerField = Items.PartnerStage;
		
	Else
		PartnerField = Items.StepCompany;
	EndIf;
	
	ProductionProcessStage.Partner = PartnerField.TypeRestriction.AdjustValue(ProductionProcessStage.Partner);
	
	ConfigureDependentFormElementsStep(ThisObject, AttributesList);
	
	ProductionProcessEditorClientServer.FillInExplanationOfBasicSettings(ProductionProcessStage, ThisObject, "Stage");
	
	CurrentRow = Items.ManufacturingProcess.CurrentRow;
	CurrentData = ManufacturingProcess.FindByID(CurrentRow);
	
	CurrentData.ProductionByThirdParty = ProductionProcessStage.ProductionByThirdParty;
	If CurrentData.ProductionByThirdParty
		And CurrentData.GetItems().Count() > 0 Then
			
			ProductionProcessRemoveStageOperation(CurrentData);
			
	EndIf;
	ProcessManufacturingProcessChange(CurrentRow);
	
	ConfigureDependentFormElements(ThisObject, "ManufacturingProcess");
	
EndProcedure

&AtServer
Procedure Step3WhenChangingOnServer(CheckClearVRC = True)
	
	CurrentRow = Items.ManufacturingProcess.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	CurrentData = ManufacturingProcess.FindByID(CurrentRow);
	
	UpdateObjectAttributeValuesInTree(ThisObject, CurrentData, "Department");
	DivisionParameters      = ProductionProcessGetUnitParameters(ThisObject, CurrentData.Department);
	PlanningIntervalStage    = DivisionParameters.PlanningInterval;
	
	If CheckClearVRC Then
		ProductionProcessEditor.CheckAllKindsOfWorkCenters(
			ProductionProcessStage, StageTypesOfWorkCenters, StageIsParallelLoading, TheStageIsSynchronousLoading);
	EndIf;
	FillInSelectionOfBuffersUnit(False);
	
	ConfigureDependentFormElements(ThisObject, "ManufacturingProcess");
	
EndProcedure

&AtServer
Procedure StageTypesOfWorkCentersViewOfWorkCenterWhenChangingOnServer()
	
	CurrentRow = Items.StageTypesOfWorkCenters.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	CurrentData = StageTypesOfWorkCenters.FindByID(CurrentRow);
	
	CurrentData.SetupSettings = Catalogs.SetupOptions.EmptyRef();
	
	ProductionProcessEditor.FillInServiceDetailsInLineOfTypesOfRC(
		Undefined,
		Undefined,
		True,
		CurrentData);
	
	ProductionProcessEditorClientServer.CalculateServiceSignsOfLoadingVRC(
		StageTypesOfWorkCenters,
		StageIsParallelLoading,
		TheStageIsSynchronousLoading);
		
	ProductionProcessEditorClientServer.CheckPurifySimultaneouslyProducedQuantity(
		ProductionProcessStage, ThisObject, "Stage");
	
	ConfigureDependentFormElementsStep(ThisObject, "WorkCenterTypes");
	
EndProcedure

&AtServer
Procedure StageTypesOfWorkCentersAdjustmentOptionWhenChangingOnServer()
	
	CurrentRow = Items.StageTypesOfWorkCenters.CurrentRow;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	CurrentData = StageTypesOfWorkCenters.FindByID(CurrentRow);
	
	ProductionProcessEditor.FillInServiceDetailsInLineOfTypesOfRC(
		Undefined,
		Undefined,
		True,
		CurrentData);
	
	ProductionProcessEditorClientServer.CalculateServiceSignsOfLoadingVRC(
		StageTypesOfWorkCenters,
		StageIsParallelLoading,
		TheStageIsSynchronousLoading);
	
EndProcedure

&AtServer
Procedure CalculateDurationOfStageOnServer()
	
	ProductionProcessEditor.CalculateStageDuration(ProductionProcessStage, StageTypesOfWorkCenters);
	
EndProcedure

&AtClient
Procedure WhenChangingCompositionOfTypesOfWorkCenters()
	
	ProductionProcessEditorClient.WhenChangingCompositionOfTypesOfWorkCenters(
		StageTypesOfWorkCenters,
		ProductionProcessStage.OperatingProcedureOfWorkCenterTypes,
		ProductionIsUsed22);
	
	CalculateStageDuration();
	
	ProductionProcessEditorClientServer.CalculateServiceSignsOfLoadingVRC(
		StageTypesOfWorkCenters,
		StageIsParallelLoading,
		TheStageIsSynchronousLoading);
	
	ProductionProcessEditorClientServer.CheckPurifySimultaneouslyProducedQuantity(
		ProductionProcessStage, ThisObject, "Stage");
	
	ConfigureDependentFormElementsStep(ThisObject, "WorkCenterTypes");
	
EndProcedure

&AtClient
Procedure TypesOfWorkCentersRecalculateWorkingHours(CurrentData)
	
	ProductionProcessEditorClient.TypesOfWorkCentersRecalculateWorkingHours(
			CurrentData,
			StageTypesOfWorkCenters,
			ProductionProcessStage.OperatingProcedureOfWorkCenterTypes,
			TheStageIsSynchronousLoading,
			ProductionIsUsed22,
			True);
	
EndProcedure

&AtServer
Procedure CustomizeFormElementsStep(StageObject, RowData)
	
	Items.StageProductionMethod.Visible =
		(ProductionByThirdPartyIsUsed2_5
			Or False)
		And Not Object.MultiStageProductionProcess;
	If (ProductionByThirdPartyIsUsed2_5
			Or False)
		And (Object.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
			Or StageObject.ProductionByThirdParty)
		And Not StageObject.WorkPlanning Then
		Items.StageProductionMethod.Visible = True;
	Else
		Items.StageProductionMethod.Visible = False;
	EndIf;
	
	If StoreOperationsInBillsOfMaterials Then
		Items.StageFillInTypesOfWorkCenters.Enabled = RowData.GetItems().Count() > 0 And AttributeAvailability;
		Items.StageFillInTypesOfWorkCenters.Title = NStr("vi = 'Điền theo giao dịch';
														|ru = 'Заполнить по операциям';
														|en = 'Fill in according to operations'; fa = 'تکمیل بر اساس عملیات';
														|it = 'Compilare per le operazioni';
														|pl = 'Wypełnij według operacji';
														|tr = 'İşlemlere göre doldur'");
	Else
		Items.StageFillInTypesOfWorkCenters.Title = NStr("vi = 'Điền theo tờ lộ trình';
														|ru = 'Заполнить по маршрутной карте';
														|en = 'Fill in from route sheet'; fa = 'پرکردن از برگه مسیر';
														|it = 'Compila in base alla scheda del ciclo di lavorazione';
														|pl = 'Wypełnij wg karty technologicznej';
														|tr = 'Rotaya göre doldur'");
	EndIf;
	Items.StageSettingUpSelectionByPropertiesAndCalculationByFormulas.Visible = Not ProductionIsUsed21;
	
	Items.TheGroupStageRouteMap.ReadOnly = StoreOperationsInBillsOfMaterials;
	
	Items.StepCompany.TypeRestriction = New TypeDescription("CatalogRef.Companies");
	Items.PartnerStage.TypeRestriction     = New TypeDescription("CatalogRef.Partners");
	
	ProductDataManagementClientServer.SetParametersForEnteringNumberOfBatchUnits(
		Object.ProductionIssueByCustomPortions And ReleaseBatchDescriptionIsAvailable,
		Items.TheStageAtTheSameTimeProduceTheNumberOfUnitsOfProductBatches);
	
	Items.StagePageHeader.Title = StageElementTitle(ThisObject, StageObject);
	
	ConfigureAdditionalBankingDetailsAndDetails(StageObject, RowData.ItemKind);
	
	ConfigureDependentFormElementsStep(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsStep(Form, AttributesList = "")
	
	If Not ValueIsFilled(Form.ProductionProcessCurrentLink)
		Or TypeOf(Form.ProductionProcessCurrentLink) <> Type("CatalogRef.ProductionStages") Then
			Return;
	EndIf;
	
	Object = Form.ProductionProcessStage;
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("ProductionMethod")
		Or Initialize Then
		
		OwnProduction = Not Object.ProductionByThirdParty;
		WorkPlanning = Object.WorkPlanning;
		
		Items.TheStageOfPageProcessing.Visible = Not OwnProduction;
		Items.StagePlanTheWorkOfTheTypesOfWorkCenters.Visible = OwnProduction And Not WorkPlanning;
		
		Items.TheGroupStageRouteMap.Visible = Form.EnterpriseManagement
			And Form.UseRouteSheets
			And OwnProduction
			And Not WorkPlanning;
			
		Items.PageStageSplitRouteSheets.Visible = Form.EnterpriseManagement
			And Form.ProductionIsUsed21
			And OwnProduction
			And Not WorkPlanning;
			
		Items.StepCompany.Visible = False;
		Items.StageProductionStage.Visible = False;
		Items.StepCompany.Visible =
			OwnProduction
			And Form.UseInternalSubcontracting
			And Not WorkPlanning;
		Items.StageProductionStage.Visible = True;
	EndIf;
	
	If AttributesStructure1.Property("PlanOperationsOfWorkCenterTypes")
		Or Initialize Then
			
		ProductionProcessEditorClientServer.ConfigureElementsOfWorkCenterViewsGroup(Object, Form, "Stage");
		
		ProductionProcessEditorClientServer.ConfigureGroupItemsStageDuration(Object, Form, "Stage");
		
	EndIf;
	If AttributesStructure1.Property("WorkCenterTypes")
		Or Initialize Then
			
		ProductionProcessEditorClientServer.ConfigureOrderOfWorkCenterViewsElement(Object, Form, "Stage");
		
		ProductionProcessEditorClientServer.ConfigureItemSimultaneouslyProducedQuantity(Object, Form, "Stage");
		
	EndIf;
	If AttributesStructure1.Property("SplitRouteSheets")
		Or Initialize Then
		
		Items.StageMaximumNumberOfUnitsOfProductBatches.ReadOnly = 
			Not (Form.TheSplitRouteSheetsStage And Not Form.BillOfMaterialsIsClosed);
		
	EndIf;
	If AttributesStructure1.Property("RouteSheet")
		Or Initialize Then
		
		ProductionProcessEditorClientServer.ConfigureRouteMapGroupElements(Object, Form, "Stage");
		
		If Not Form.StoreOperationsInBillsOfMaterials Then
			Items.StageFillInTypesOfWorkCenters.Visible = Form.UseRouteSheets;
			Items.StageFillInTypesOfWorkCenters.Enabled = ValueIsFilled(Object.RouteSheet)
																		And Form.AttributeAvailability;
		EndIf;
		
	EndIf;
	// Simultaneously produced number of units/batches of products
	If AttributesStructure1.Property("QuantityOfProductUnitsLotsProducedSimultaneously")
		Or Initialize Then
		
		Items.TheStageAtTheSameTimeProduceTheNumberOfUnitsOfProductBatches.ToolTip =
			ProductDataManagementClientServer.PresentationOfUnitOfMeasurementOfBatchOfRelease(
				Form.ReleaseBatchDescription,
				Object.QuantityOfProductUnitsLotsProducedSimultaneously);
		
	EndIf;
	
	If AttributesStructure1.Property("RecordMethodOfMaterialTransferBetweenStagesLots")
		Or Initialize Then
		
		Items.IntermediateRelease.Visible = IntermediateReleaseIsAvailable(Form)
			And Form.Object.RecordMethodOfMaterialTransferBetweenStagesLots = PredefinedValue(
				"Enum.RecordMethodsOfMaterialTransferBetweenStagesLots.SetUpManually");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfProcessorSService()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		ProductionProcessStage.SubcontractorServices, StructureOfActions);
	
EndProcedure

&AtClient
Procedure FillInDivisionOfStagesCompletion(Department, RowsIDs) Export
	
	If ValueIsFilled(Department) Then
		
		FillInSubdivisionOfCompletionStagesOnServer(Department, RowsIDs);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSubdivisionOfCompletionStagesOnServer(Department, RowsIDs)
	
	ElementCache_ = ProductionProcessGetCacheItems();
	
	For Each RowID In RowsIDs Do
		
		RowData = ManufacturingProcess.FindByID(RowID);
		If RowData.ItemKind <> TypeOfStageElement() Then
			Continue;
		EndIf;
		
		If RowID = Items.ManufacturingProcess.CurrentRow Then
			
			ProductionProcessStage.Department = Department;
			Step3WhenChangingOnServer(False);
			
		Else
			
			RowData.Department = Department;
			
			ElementCache = ProductionProcessGetItemCache(ElementCache_, RowData, True);
			ElementCache.Object.Department = Department;
			
			ElementCache.FilledIn_ = False;
			
		EndIf;
		
	EndDo;
	
	ProductionProcessSaveCacheItems(ElementCache_);
	
EndProcedure

&AtClient
Procedure QuestionMethodOfProductionInCaseOfChange(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		StageProductionMethodWhenModifiedOnServer();
		
	Else
		
		StageProductionMethod = Number(ProductionProcessStage.ProductionByThirdParty);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure Step2TypesOfWorkCentersForOperationsOnServer()
	
	RowData  = ManufacturingProcess.FindByID(Items.ManufacturingProcess.CurrentRow);
	ElementCache_  = ProductionProcessGetCacheItems();
	
	OperationData_  = ProductionProcessEditor.FillInTypesOfWorkCentersForOperationsConstructor();
	
	For Each LineOperation In RowData.GetItems() Do
		NewRow = OperationData_.Add();
		ElementCache = ElementCache_.Get(LineOperation.Ref);
		If ElementCache = Undefined Then
			NewRow.Ref        = LineOperation.Ref;
			NewRow.OperationNumber = LineOperation.Number;
		Else
			FillPropertyValues(NewRow, ElementCache.Object);
			NewRow.FilledIn = True;
		EndIf;
	EndDo;
	
	ProductionProcessEditor.FillInTypesOfWorkCentersForOperations(
		ProductionProcessStage, OperationData_);
		
	// By default, we use the main types of RC
	For Each RowMainViewOfRC In ProductionProcessStage.WorkCenterTypes Do
		RowMainViewOfRC.Use = True;
	EndDo;
		
	ProductionProcessEditor.CheckSelectionOfBufferUnit(
		ProductionProcessStage, ThisObject, True, "Stage");
	ProductionProcessEditor.FillInTheTypesOfWorkCenters(
		ProductionProcessStage, StageTypesOfWorkCenters, StageIsParallelLoading, TheStageIsSynchronousLoading);
	
EndProcedure

&AtServer
Procedure StageFillInTypesOfWorkCentersOnRouteMapOnServer()
	
	ProductionProcessEditor.FillInWorkCenterKindsUsingAnOperationsSheet(
		ProductionProcessStage, ThisObject, StageTypesOfWorkCenters, StageIsParallelLoading, TheStageIsSynchronousLoading, "Stage");
	
EndProcedure

&AtServer
Procedure RouteMapWhenChangedOnServer()
	
	ReadRouteMapSettings(ProductionProcessStage, ThisObject);
	
	If StepCalculateCoefficient Then
		
		ProductionProcessStage.RouteSheetFactor =
			RouteSheetFactor(ProductionProcessStage.RouteSheet);
		
	Else
		
		If Not ValueIsFilled(ProductionProcessStage.RouteSheet) Then
			ProductionProcessStage.RouteSheetFactor = 0;
		ElsIf ProductionProcessStage.RouteSheetFactor = 0 Then
			ProductionProcessStage.RouteSheetFactor = 1;
		EndIf;
		
	EndIf;
	
	ConfigureDependentFormElementsStep(ThisObject, "RouteSheet");
	
EndProcedure

&AtClientAtServerNoContext
Procedure ReadRouteMapSettings(Object, Form)
	
	MKSettings = ProductionProcessEditorClientServer.GetRouteMapSettings(Object);
	
	DescriptionOfElementProperties_ = Form.ProductionProcessCache.DescriptionOfElementProperties_; // Map
	ItemsProperties = DescriptionOfElementProperties_.Get(TypeOfStageElement());
	
	For Each KeyAndValue In MKSettings Do
		Form[ItemsProperties[KeyAndValue.Key]] = KeyAndValue.Value;
	EndDo;
	
EndProcedure

&AtServer
Function RouteSheetFactor(RouteSheet)

	MainProductData = MainProductSpecificationStructure(ThisObject);
	
	CalculateQuantityOfMainProduct(MainProductData, Undefined);
	
	Return Catalogs.RouteSheets.RouteMapCoefficientForSpecification(
		MainProductData, RouteSheet);
	
EndFunction

#EndRegion

#Region EditingOperationProperties

&AtServer
Procedure OperationWorkCenterWhenChangingOnServer()
	
	ProductionProcessEditor.WorkCenterOnChange(ProductionProcessOperation, ThisObject, "Operation");
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfOperationByClassifierATServer(ValueSelected)
	
	ProductionProcessEditor.ClassifierOfTechnologicalOperationsChoiceProcessing(ProductionProcessOperation, ThisObject, ValueSelected, "Operation");
	
	ConfigureDependentOperationFormElements(ThisObject, "OperationKind");
	
EndProcedure

&AtServer
Procedure OperationTypeOfOperationWhenChangingOnServer()
	
	ProductionProcessEditor.OperationKindOnChange(ProductionProcessOperation, ThisObject, "Operation");
	
	ConfigureDependentOperationFormElements(ThisObject, "OperationKind");
	
EndProcedure

&AtServer
Procedure OperationAdjustmentOptionForChangesOnServer()
	
	ProductionProcessEditor.SetupSettingsOnChange(ProductionProcessOperation, ThisObject, "Operation");
	
EndProcedure

&AtServer
Procedure OperationIsPerformedWhenChangesAreMadeOnServer()
	
	ProductionProcessEditor.ProductionAreaOnChange(ProductionProcessOperation, ThisObject, "Operation"); 
	
EndProcedure

&AtClient
Procedure OperationNameONChangeOnClient()
	
	CurrentData = Items.ManufacturingProcess.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	UpdateObjectAttributeValuesInTree(ThisObject, CurrentData, "Description");
	
	ProductionProcessUpdatePresentation(TypeOfElementOfOperation(), CurrentData.Ref, CurrentData.Description, ThisObject);
	
EndProcedure

&AtServer
Function TechnologicalProcessFactor(TechnologicalProcess)
	
	StringStructure = MainProductSpecificationStructure(ThisObject);
	
	CalculateQuantityOfMainProduct(StringStructure, Undefined);
	
	Return Catalogs.TechnologicalProcesses.ProcessRatioForSpecification(StringStructure.Count, TechnologicalProcess);
	
EndFunction

&AtServer
Procedure ConfigureOperationFormElements(OperationObject, RowData)
	
	ConfigureAdditionalBankingDetailsAndDetails(OperationObject, RowData.ItemKind);
	
	If OperationObject.ContainsTechnologicalProcess Then
		
		Items.OperationCalculateTheCoefficientOfTheTechnologicalProcess.Enabled = OperationCalculateCoefficient And AttributeAvailability;
		Items.ProductionProcessPageOperation.CurrentPage = Items.ProductionProcessTPOperation;
		
	Else
		
		Items.ProductionProcessPageOperation.CurrentPage = Items.ProductionProcessOperationNormal;
		
	EndIf;
	
	Items.OperationFoundation.Visible = ValueIsFilled(OperationObject.Basis);
	
	ConfigureDependentOperationFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentOperationFormElements(Form, AttributesList = "")
	
	If Not ValueIsFilled(Form.ProductionProcessCurrentLink)
		Or TypeOf(Form.ProductionProcessCurrentLink) <> Type("CatalogRef.ManufacturingOperations") Then
			Return;
	EndIf;
	
	Object = Form.ProductionProcessOperation;
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("OperationKind")
		Or Initialize Then
			
			Items.OperationPageControlledParameters.Visible = ValueIsFilled(Object.OperationKind);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingSelectionOfOperationByClassifier(ValueSelected, NewOperation = False)
	
	If NewOperation Then
		
		StageLineData = ProductionProcessGetCurStage(ThisObject);
		
		If StageLineData <> Undefined Then
			
			ProductionProcessAddOperationOnServer(StageLineData.GetID(), ValueSelected);
			
		EndIf;
		
	Else
		
		ProcessingSelectionOfOperationByClassifierATServer(ValueSelected);
		
		OperationNameONChangeOnClient();
	
	EndIf;
	
EndProcedure

#EndRegion

#Region EditingWorkProperties

&AtServer
Procedure CustomizeWorkFormElements(TheseLinesWork, TreeRowData)
	
	Items.WorksPerformedCharacteristics.Visible = GetFunctionalOption("UseItemVariants");
	Items.UnderRepairVariant.Visible = GetFunctionalOption("UseItemVariants");
	
	ConfigureAdditionalBankingDetailsAndDetails(TheseLinesWork, TreeRowData.ItemKind);
	
	ConfigureDependentWorkFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentWorkFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	CurrentRow = Items.ManufacturingProcess.CurrentRow;
	CurrentData = Form.ManufacturingProcess.FindByID(CurrentRow);
	
	TheseLinesWork = ProductionProcessElementData(Form, CurrentData);
	
	If TheseLinesWork = Undefined Then
		Return;
	EndIf;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Products")
		Or Initialize Then
			
		FieldsStructure = New Structure;
		FieldsStructure.Insert("WorksPerformedCharacteristics", "ItemVariantsAreUsed");
		FieldsStructure.Insert("WorksPerformedFinishedProductBeingRepairedCharacteristics", "FinishedProductBeingRepairedCharacteristicsAreUsed");
		For Each KeyAndValue In FieldsStructure Do
			
			ProductionClientServer.ConfigureItemVariantsElement(
				Items[KeyAndValue.Key], TheseLinesWork[KeyAndValue.Value]);
			
		EndDo;
		
	EndIf;
	
	If AttributesStructure1.Property("ProducedInProcess")
		Or Initialize Then
		
		Items.WorksBeingPerformedBillOfMaterials.Enabled = TheseLinesWork.ProducedInProcess;
		Items.WorksBeingPerformedBillOfMaterials.ReadOnly = Not ValueIsFilled(TheseLinesWork.Products)
			Or Not TheseLinesWork.ProducedInProcess
			Or Not Form.AttributeAvailability;
			
		If TheseLinesWork.ProducedInProcess Then
			Items.WorksBeingPerformedBillOfMaterials.InputHint = NStr("vi = '<bảng kê chi tiết được chọn tự động>';
																		|ru = '<спецификация подбирается автоматически>';
																		|en = '<bill of materials is picked automatically>'; fa = '<bill of materials is picked automatically>';
																		|it = '<bill of materials is picked automatically>';
																		|pl = '<bill of materials is picked automatically>';
																		|tr = '<ürün reçetesi otomatik olarak seçilir>'")
		Else
			Items.WorksBeingPerformedBillOfMaterials.InputHint = "";
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function DataStructureFinishedProductUnderRepair(TheseLinesWork)
	
	StructureOfData = New Structure;
	
	StructureOfData.Insert("Products", TheseLinesWork.UnderRepairProduct);
	StructureOfData.Insert("Characteristic", TheseLinesWork.UnderRepairVariant);
	StructureOfData.Insert("ItemVariantsAreUsed", TheseLinesWork.FinishedProductBeingRepairedCharacteristicsAreUsed);
	StructureOfData.Insert("BillOfMaterials", TheseLinesWork.BillOfMaterials);
	
	Return StructureOfData;
	
EndFunction

&AtServer
Procedure WorksPerformedItemListOnChangeATServer(CachedValues)
	
	TreeRowData = ManufacturingProcess.FindByID(Items.ManufacturingProcess.CurrentRow);
	TheseLinesWork = ProductionProcessElementData(ThisObject, TreeRowData);
	
	If TheseLinesWork = Undefined Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", TheseLinesWork.Characteristic);
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	
	BatchProcessingOfTablePartServer.ProcessTSString(TheseLinesWork, StructureOfActions, CachedValues);
	
	CheckRepairWorkBillOfMaterials(TheseLinesWork, CachedValues);
	
	TheseLinesWork.Work_5Presentation = ProductsClientServer.ProductPresentation(
												TheseLinesWork.Products, TheseLinesWork.Characteristic);
	
	UpdateObjectAttributeValuesInTree(ThisObject, TreeRowData, "Description");
	
	ConfigureDependentWorkFormElements(ThisObject, "Products,ProducedInProcess");
	
EndProcedure

&AtServer
Procedure WorkPerformedCharacteristicsOnChangeATServer(CachedValues)
	
	TreeRowData = ManufacturingProcess.FindByID(Items.ManufacturingProcess.CurrentRow);
	TheseLinesWork = ProductionProcessElementData(ThisObject, TreeRowData);
	
	If TheseLinesWork = Undefined Then
		Return;
	EndIf;
	
	CheckRepairWorkBillOfMaterials(TheseLinesWork, CachedValues);
	
	TheseLinesWork.Work_5Presentation = ProductsClientServer.ProductPresentation(
												TheseLinesWork.Products, TheseLinesWork.Characteristic);
	
	UpdateObjectAttributeValuesInTree(ThisObject, TreeRowData, "Description");
	
EndProcedure

&AtServer
Procedure WorksPerformedFinishedProductToBeRepairedItemONChangeATServer(CachedValues)
	
	TreeRowData = ManufacturingProcess.FindByID(Items.ManufacturingProcess.CurrentRow);
	TheseLinesWork = ProductionProcessElementData(ThisObject, TreeRowData);
	
	If TheseLinesWork = Undefined Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfData   = DataStructureFinishedProductUnderRepair(TheseLinesWork);
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner", StructureOfData.Characteristic);
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	
	BatchProcessingOfTablePartServer.ProcessTSString(StructureOfData, StructureOfActions, CachedValues);
	
	TheseLinesWork.UnderRepairVariant = StructureOfData.Characteristic;
	TheseLinesWork.FinishedProductBeingRepairedCharacteristicsAreUsed = StructureOfData.ItemVariantsAreUsed;
	
	CheckRepairWorkBillOfMaterials(TheseLinesWork, CachedValues);
	
	ConfigureDependentWorkFormElements(ThisObject, "Products");
	
EndProcedure

&AtServer
Procedure WorksPerformedFinishedProductUnderRepairCharacteristicsOnChangeATServer(CachedValues)
	
	TreeRowData = ManufacturingProcess.FindByID(Items.ManufacturingProcess.CurrentRow);
	TheseLinesWork = ProductionProcessElementData(ThisObject, TreeRowData);
	
	If TheseLinesWork = Undefined Then
		Return;
	EndIf;
	
	CheckRepairWorkBillOfMaterials(TheseLinesWork, CachedValues);
	
	ConfigureDependentWorkFormElements(ThisObject, "Products");
	
EndProcedure

&AtServer
Procedure CheckRepairWorkBillOfMaterials(TheseLinesWork, CachedValues)
	
	If Not ValueIsFilled(TheseLinesWork.BillOfMaterials) Then
		Return;
	EndIf;
	
	StructureOfSpecificationFilling = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		Object, TheseLinesWork, BOMSelectionParameters.PerformRM);
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillSpecification", StructureOfSpecificationFilling);
	
	BatchProcessingOfTablePartServer.ProcessTSString(TheseLinesWork, StructureOfActions, CachedValues);
	
	If StructureOfSpecificationFilling.ProductData.CurrentSpecification <> TheseLinesWork.BillOfMaterials Then
		TheseLinesWork.BillOfMaterials = Catalogs.BillsOfMaterials.EmptyRef();
	EndIf;
	
EndProcedure

#EndRegion

#Region WorksToPerform

&AtServer
Procedure DisplayWorksInProductionProcessTree()
	
	If Not ThisIsPerformanceOfRepairWork(ThisObject)
		Or Object.WorksToPerform.Count() = 0 Then
		Return;
	EndIf;
	
	FillInServiceDetailsOfWorkPerformed();
	
	ElementCache_ = ProductionProcessGetCacheItems();
		
	RowData = Undefined;
	While ProductionProcessIsFollowingElement(ThisObject, RowData, False) Do
		
		If Not RowData.WorkPlanning Then
			Continue;
		EndIf;
		
		ItemsCollection = RowData.GetItems();
		ItemsCollection.Clear();
		
		For Each TheseLinesWork In Object.WorksToPerform.Unload(New Structure("Stage", RowData.Ref)) Do
			
			ProductionProcessAddWorkToTree(TheseLinesWork, ElementCache_, ItemsCollection);
			
		EndDo;
		
	EndDo;
	
	ProductionProcessSaveCacheItems(ElementCache_);
	
EndProcedure

&AtServer
Function WorksPerformedInTable()
	
	WorksToPerform = Object.WorksToPerform.Unload(New Array);
	
	RowData = Undefined;
	While ProductionProcessIsFollowingElement(ThisObject, RowData) Do
		If RowData.ItemKind = TypeOfWorkElement() Then
			
			StageLineData  = RowData.GetParent();
			ItemsCollection = StageLineData.GetItems(); // FormDataCollection
			
			NewRow = WorksToPerform.Add();
			FillPropertyValues(NewRow, ProductionProcessElementData(ThisObject, RowData));
			NewRow.LineNumber = ItemsCollection.IndexOf(RowData) + 1;
			
		EndIf;
	EndDo;
	
	Return WorksToPerform;
	
EndFunction

#EndRegion

#Region AdditionalAttributesAndInfo

&AtServer
Procedure ConfigureAdditionalBankingDetailsAndDetails(CurrentObject, ItemKind)
	
	DescriptionOfElementProperties_ = ProductionProcessCache.DescriptionOfElementProperties_; // Map
	ItemsProperties = DescriptionOfElementProperties_.Get(ItemKind);
	
	Items.TheProductionProcessForMoreInformation.Enabled = ItemsProperties.ContainsObject;
	
	If ProductionProcessCache[ItemsProperties["UseAddlAttributes"]] Then
		
		HyperlinkAnchorText = NStr("vi = 'Mục tin bổ sung';
									|ru = 'Дополнительные реквизиты';
									|en = 'Additional attributes'; fa = 'ویژگی‌های تکمیلی';
									|it = 'Requisiti aggiuntivi';
									|pl = 'Atrybuty dodatkowe';
									|tr = 'Ek öznitelikler'")
			+ ?(CurrentObject.AdditionalAttributes.Count() > 0,
				StrTemplate(" (%1)", CurrentObject.AdditionalAttributes.Count()),
				"");
		
		ThisObject[ItemsProperties["AdditionalAttributes"]] = New FormattedString(
			HyperlinkAnchorText,,,,"#AdditionalAttributes");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionProcessEditAdditionalDetails()
	
	DescriptionOfElementProperties_ = ProductionProcessCache.DescriptionOfElementProperties_; // Map
	CurrentData = Items.ManufacturingProcess.CurrentData;
	ItemProperties = DescriptionOfElementProperties_.Get(CurrentData.ItemKind);
	
	FormParameters = New Structure;
	FormParameters.Insert("ItemKind",            CurrentData.ItemKind);
	FormParameters.Insert("ReadOnly",         CurrentData.ReadOnly Or ReadOnly);
	FormParameters.Insert("Title",              CurrentData.Description);
	FormParameters.Insert("ItemTypeName",        ItemProperties.ItemTypeName);
	FormParameters.Insert("AddressOfPropertyTable",    ProductionProcessToPlaceAdditionalAttributes());
	FormParameters.Insert("OwnerID", UUID);
	
	CallbackDescription = New CallbackDescription(
		"ProductionProcessAfterEditingAdditionalDetails",
		ThisObject);
	
	OpenForm("Catalog.BillsOfMaterials.Form.AdditionalAttributesEditingForm",
		FormParameters, ThisObject, CurrentData.Ref,,, CallbackDescription);
	
EndProcedure

&AtServer
Function ProductionProcessToPlaceAdditionalAttributes()
	
	DescriptionOfElementProperties_ = ProductionProcessCache.DescriptionOfElementProperties_; // Map
	CurrentRow    = Items.ManufacturingProcess.CurrentRow;
	CurrentData    = ManufacturingProcess.FindByID(CurrentRow);
	ItemProperties = DescriptionOfElementProperties_.Get(CurrentData.ItemKind);
	
	CurrentObject = ThisObject[ItemProperties.ObjectAttributeName];
	AdditionalAttributes = CurrentObject.AdditionalAttributes.Unload();
	
	Return PutToTempStorage(AdditionalAttributes, UUID);
	
EndFunction

&AtClient
Procedure ProductionProcessAfterEditingAdditionalDetails(Result, AdditionalParameters) Export
	
	If Result <> Undefined And IsTempStorageURL(Result) Then
		
		ProductionProcessAfterEditingAdditionalDetailsOnServer(Result);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProductionProcessAfterEditingAdditionalDetailsOnServer(ResultAddress)
	
	DescriptionOfElementProperties_ = ProductionProcessCache.DescriptionOfElementProperties_; // Map
	CurrentRow    = Items.ManufacturingProcess.CurrentRow;
	CurrentData    = ManufacturingProcess.FindByID(CurrentRow);
	ItemProperties = DescriptionOfElementProperties_.Get(CurrentData.ItemKind);
	
	Result = GetFromTempStorage(ResultAddress);
	
	CurrentObject = ThisObject[ItemProperties.ObjectAttributeName];
	CurrentObject.AdditionalAttributes.Load(Result);
	
	ElementCache_ = ProductionProcessGetCacheItems();
	ElementCache = ProductionProcessGetItemCache(ElementCache_, CurrentData);
	ElementCache.Write = True;
	ProductionProcessSaveCacheItems(ElementCache_);
	
	ConfigureAdditionalBankingDetailsAndDetails(CurrentObject, CurrentData.ItemKind);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ProductionProcessEditAdditionalInformation()
	
	CurrentData = Items.ManufacturingProcess.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ProductionProcessOfItemIsRecorded(CurrentData.Ref) Then
		ProductionProcessEditAdditionalItemDetails(CurrentData.Ref);
		Return;
	EndIf;
	
	QueryText = StrTemplate(NStr("vi = 'Phần tử ""%1"" chưa được ghi lại.
	|Chỉ có thể điều chỉnh thông tin bổ sung sau khi ghi lại quy trình sản xuất.
	|Ghi lại và tiếp tục?';
	|ru = 'Элемент ""%1"" не записан.
	|Редактирование дополнительных сведений возможно только после записи производственного процесса.
	|Записать и продолжить?';
	|en = 'Element ""%1"" is not saved yet.
	|Editing additional information records is only available after the production process has been saved.
	|Save and continue?'; fa = 'Element ""%1"" is not saved yet.
	|Editing additional information records is only available after the production process has been saved.
	|Save and continue?';
	|it = 'L''elemento ""%1"" non è stato salvato.
	|È possibile modificare le informazioni aggiuntive solo dopo il salvataggio del processo di produzione.
	|Salvare e continuare?';
	|pl = 'Element ""%1"" nie jest zapisany.
	|Edytowanie dodatkowych danych jest możliwe tylko po zapisaniu procesu produkcyjnego.
	|Zapisać i kontynuować?';
	|tr = '""%1"" öğesi kaydedilmedi.
	|Ek bilgi kaydının düzenlenmesi sadece üretim süreci kaydedildikten sonra mümkündür.
	|Kaydedilsin ve devam edilsin mi?'"), CurrentData.Description);
	
	CallbackDescription = New CallbackDescription("ProductionProcessEditAdditionalInformationCompletion",
		ThisObject, CurrentData.Ref);
		
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ProductionProcessEditAdditionalInformationCompletion(QuestionResult, Var_Parameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		If Write() Then
			
			ProductionProcessEditAdditionalItemDetails(Var_Parameters);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionProcessEditAdditionalItemDetails(Ref)
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref", Ref);
	
	OpenForm("CommonForm.AdditionalDataEditing", FormParameters, ThisObject, Ref);
	
EndProcedure

#EndRegion

#Region ProcessingSelectionOfElements

&AtClientAtServerNoContext
Function NamesOfEditingElements()
	
	Result = New Map();
	
	Result.Insert("ManufacturedProduct",        "ProductsAreElementOfProductionProcess");
	Result.Insert("ManufacturedProducts",  "OutputProductsAreElementOfProductionProcess");
	Result.Insert("RecyclableWaste", "ReturnableWasteIsElementOfProductionProcess");
	Result.Insert("MaterialsAndServices", "MaterialsAndServicesElementOfProductionProcess");
	Result.Insert("LaborCosts",     "LaborCostsAreElementOfProductionProcess");
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function NamesOfCommandsForSelectingElementOfProductionProcess()
	
	Result = New Map();
	
	Result.Insert("ManufacturedProducts",  "OutputProducts_FillInStage");
	Result.Insert("RecyclableWaste", "ReturnableWasteFillStage");
	Result.Insert("MaterialsAndServices", "MaterialsAndServicesFillOutTheStage");
	Result.Insert("LaborCosts",     "LaborCostsCompleteTheStage");
	
	Return Result;
	
EndFunction

// Generates a tree of elements of the production process for selection, taking into account the specified selection.
// 
// Parameters:
//  Filter - Undefined, Structure - Selection structure:
//   * TSName - String - Table part
//   * ItemKind - String - item type
//   * Stage - CatalogRef.ProductionStages - stage-owner
// 
// Returns:
//  String, ValueTree - The tree of elements of the production process:
//	* Ref - CatalogRef.ProductionStages
&AtServer
Function TreeOfProductionProcessElementsForSelection(Filter = Undefined)
	
	ItemsTree = FormAttributeToValue("ManufacturingProcess"); // ValueTree
	
	If ValueIsFilled(Filter) Then
	
		Result = ItemsTree.Copy();
		Result.Rows.Clear();
		
		For Each StageString In ItemsTree.Rows Do
			
			If Filter.Property("TSName") Then
				If Filter.TSName = "ManufacturedProducts" And StageString.TheNumberOfTheNextOne <> 0 Then
					Continue;
				EndIf;
				If Filter.TSName = "ManufacturedProduct" And StageString.TheNumberOfTheNextOne <> 0 Then
					Continue;
				EndIf;
				If Filter.TSName = "LaborCosts" And StageString.ProductionByThirdParty <> False Then
					Continue;
				EndIf;
			EndIf;
			
			If StageString.WorkPlanning Then
				Continue;
			EndIf;
			
			If Filter.Property("MinimumStageNumber")
				And StageString.Number < Filter.MinimumStageNumber Then
				Continue;
			EndIf;
			
			If Not Filter.Property("ItemKind") Or Filter.ItemKind = TypeOfStageElement() Then
				NewLineStage = Result.Rows.Add();
				FillPropertyValues(NewLineStage, StageString);
			Else
				NewLineStage = Result;
			EndIf;
			If (Not Filter.Property("ItemKind") Or Filter.ItemKind = TypeOfElementOfOperation())
					And (Not Filter.Property("Stage") Or Filter.Stage = StageString.Ref) Then
				For Each LineOperation In StageString.Rows Do
					NewLineOperation = NewLineStage.Rows.Add();
					FillPropertyValues(NewLineOperation, LineOperation);
				EndDo;
			EndIf;
		EndDo;
	
	Else
		
		Result = ItemsTree;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function TableOfProductionProcessElementsInStorage(Filter = Undefined)
	
	Return PutToTempStorage(
		TableOfProductionProcessElements(Filter),
		UUID);
	
EndFunction

&AtServer
Function TreeOfProductionProcessElementsToSelectInRepository(Filter = Undefined)
	
	Return PutToTempStorage(
		TreeOfProductionProcessElementsForSelection(Filter),
		UUID);
	
EndFunction

&AtClientAtServerNoContext
Function RepresentationOfProductionProcessElement(Form, RowData, AutoComplete = False)
	
	Result = "";
	Template    = ?(AutoComplete, "%2 (%1)", "%1 / %2");
	
	If TypeOf(RowData) = Type("FormDataCollectionItem") Then
		
		If ValueIsFilled(RowData.StageEditing) Then
			Result = RowData.StageEditingPresentation;
		EndIf;
		If ValueIsFilled(RowData.OperationEdit)
				And Form.StoreOperationsInBillsOfMaterials Then
			Result = StrTemplate(Template, Result, RowData.OperationEditPresentation);
		EndIf;
	Else
		
		If RowData.ItemKind = TypeOfStageElement() Then
			
			Result = RowData.Description;
		ElsIf Form.StoreOperationsInBillsOfMaterials Then
			
			Result = StrTemplate(Template, RowData.Parent.Description, RowData.Description);
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetValueOfProductionProcessElementInLine(Form, RowData, ValueSelected)
	
	RowData.StageEditing                  = ValueSelected.Stage;
	RowData.StageEditingPresentation     = ValueSelected.StagePresentation;
	RowData.OperationEdit              = ValueSelected.Operation;
	RowData.OperationEditPresentation = ValueSelected.OperationPresentation;
	RowData.ElementOfProductionProcessPresentation = RepresentationOfProductionProcessElement(Form, RowData);
	
EndProcedure

&AtServer
Function DataForSelectingElementOfProductionProcess(TSName, SearchString, Comparison_ = False)
	
	Filter = New Structure;
	Filter.Insert("TSName", TSName);
	If TSName = "IntermediateRelease" Then
		Filter.Insert("ItemKind", TypeOfStageElement());
		Filter.Insert("MinimumStageNumber", ProductionProcessStage.StageNumber + 1);
	EndIf;
	Result = New ValueList();
	
	For Each StageString In TreeOfProductionProcessElementsForSelection(Filter).Rows Do
		
		If Result.Count() > ?(Comparison_, 0, 49) Then
			Break;
		EndIf;
		
		StringPresentation = RepresentationOfProductionProcessElement(ThisObject, StageString, True);
		
		ValueStructure = ProductionProcessEditorClientServer.StructureOfValueOfProductionProcessElementConstructor();
		ValueStructure.Stage              = StageString.Ref;
		ValueStructure.StagePresentation = StageString.Description;
		
		If Comparison_ Then
			If Lower(StringPresentation) = Lower(SearchString) Then
				Result.Add(ValueStructure, StringPresentation);
				Continue;
			EndIf;
		Else
			If Lower(Left(StageString.Description, StrLen(SearchString))) = Lower(SearchString) Then
				Result.Add(ValueStructure, StringPresentation,, StageString.Picture);
			EndIf;
		EndIf;
		For Each LineOperation In StageString.Rows Do
			
			StringPresentation = RepresentationOfProductionProcessElement(ThisObject, LineOperation, True);
			
			ValueStructure = ProductionProcessEditorClientServer.StructureOfValueOfProductionProcessElementConstructor();
			ValueStructure.Stage                  = StageString.Ref;
			ValueStructure.StagePresentation     = StageString.Description;
			ValueStructure.Operation              = LineOperation.Ref;
			ValueStructure.OperationPresentation = LineOperation.Description;
			
			If Comparison_ Then
				If Lower(StringPresentation) = Lower(SearchString) Then
					Result.Add(ValueStructure, StringPresentation);
					Break;
				EndIf;
			Else
				If Lower(Left(LineOperation.Description, StrLen(SearchString))) = Lower(SearchString) Then
					Result.Add(ValueStructure, StringPresentation, , LineOperation.Picture);
				EndIf;
			EndIf;
			
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure ProcessingSelectionOfProductionProcessElement(TSName, ValueSelected)
	
	SelectedRows = Items[TSName].SelectedRows;
	TabularSection = Object[MatchingFormTablesToTSNames()[TSName]];
	
	For Each RowID In SelectedRows Do
		
		RowData = TabularSection.FindByID(RowID);
		
		If ValueSelected <> Undefined Then
			
			RowData = TabularSection.FindByID(RowID);
			SetValueOfProductionProcessElementInLine(ThisObject, RowData, ValueSelected);
			
		Else
			
			ProductionProcessCleanSelectedItem(ThisObject, RowData);
			
		EndIf;
		
	EndDo;
	
	If TSName = "MaterialsAndServices" Then
		
		ProcessStageChangeMaterialsAndServices(SelectedRows);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingSelectionOfElementOfProductionProcessByPresentation(TSName, RowData, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("String") And Not IsBlankString(ValueSelected) Then
		
		ChoiceData = DataForSelectingElementOfProductionProcess(TSName, ValueSelected, True);
		
		If ValueIsFilled(ChoiceData) Then
			ValueSelected = ChoiceData[0].Value;
			SetValueOfProductionProcessElementInLine(ThisObject, RowData, ValueSelected);
		EndIf;
		
	ElsIf TypeOf(ValueSelected) = Type("Structure") Then
		
		ProcessingSelectionOfProductionProcessElement(TSName, ValueSelected);
		
	Else
		
		ProductionProcessCleanSelectedItem(ThisObject, RowData);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ProductionProcessCleanSelectedItem(Form, RowData)
	
	SetValueOfProductionProcessElementInLine(
		Form,
		RowData,
		ProductionProcessEditorClientServer.StructureOfValueOfProductionProcessElementConstructor());
	
EndProcedure

&AtClient
Procedure ProductionProcessOpenItemSelectionForm(TSName, RowData)
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("TSName", TSName);
	ParametersStructure.Insert("CurrentRef", RowData.StageEditing);
	If ValueIsFilled(RowData.OperationEdit)
			And StoreOperationsInBillsOfMaterials Then
		ParametersStructure.Insert("CurrentRef", RowData.OperationEdit);
	EndIf;
	If TSName = "IntermediateRelease" Then
		ParametersStructure.Insert("ItemKind", TypeOfStageElement());
		ParametersStructure.Insert("MinimumStageNumber", ProductionProcessStage.StageNumber + 1);
	EndIf;
	ParametersStructure.Insert("AddressInStorage", TreeOfProductionProcessElementsToSelectInRepository(ParametersStructure));
	
	OpenForm(
		"Catalog.BillsOfMaterials.Form.ProductionProcessElementChoiceForm",
		ParametersStructure,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Cache

&AtServer
Procedure ProductionProcessInitializeCache()
	
	ProductionProcessCache = New Structure;
	
	ProductionProcessCache.Insert("AdditionalDataAddress", Undefined);
	ProductionProcessCache.Insert("UnitParameters",    New Map());
	ProductionProcessCache.Insert("ThereIsMultioperativeStage", False);
	
	PropertiesAvailable = GetFunctionalOption("UseAdditionalAttributesAndInfo")
		And PropertyManager.PropertiesAvailable();
	
	DescriptionOfElementProperties_ = New Map();
	For Each ItemKind In ProductionProcessEditorClientServer.ItemsKinds() Do
		
		PropertiesDetails = ProductionProcessDescriptionOfElementProperties(ItemKind);
		DescriptionOfElementProperties_.Insert(ItemKind, PropertiesDetails);
		
		If PropertiesAvailable And PropertiesDetails.ContainsObject Then
			ValueOfBankingDetails = Common.ObjectAttributesValues(
				PropertyManager.PropertiesSetByName("Catalog_"+PropertiesDetails.ItemTypeName), "AdditionalAttributes");
			UseAddlAttributes = ValueIsFilled(ValueOfBankingDetails.AdditionalAttributes)
				And Not ValueOfBankingDetails.AdditionalAttributes.IsEmpty();
		Else
			UseAddlAttributes = False;
		EndIf;
		ProductionProcessCache.Insert(PropertiesDetails["UseAddlAttributes"], UseAddlAttributes);
		ProductionProcessCache.Insert(PropertiesDetails.Counter, 0);
		
	EndDo;
	ProductionProcessCache.Insert("DescriptionOfElementProperties_", New FixedMap(DescriptionOfElementProperties_));
	
EndProcedure

&AtServer
Function ProductionProcessGetCacheItems()
	
	If IsTempStorageURL(ProductionProcessCache.AdditionalDataAddress) Then
		ElementCache_ = GetFromTempStorage(ProductionProcessCache.AdditionalDataAddress); // Map
		For Each KeyAndValue In ElementCache_ Do
			ElementCache = KeyAndValue.Value;
			If ValueIsFilled(ElementCache.ObjectIsSerialized) Then
				ElementCache.Object = Deserialize(ElementCache.ObjectIsSerialized);
			EndIf;
		EndDo;
	Else
		ElementCache_ = New Map;
	EndIf;
	
	Return ElementCache_;
	
EndFunction

&AtServer
Procedure ProductionProcessSaveCacheItems(ElementCache_)
	
	For Each KeyAndValue In ElementCache_ Do
		ElementCache = KeyAndValue.Value;
		If ElementCache.Object <> Undefined Then
			ObjectIsSerialized = ElementCache.ObjectIsSerialized;
			ElementCache.ObjectIsSerialized = Serialize(ElementCache.Object);
			ElementCache.Object = Undefined;
			ElementCache.Write = ElementCache.Write
					Or (Not ElementCache.ReadOnly
							And ValueIsFilled(ObjectIsSerialized)
							And ObjectIsSerialized <> ElementCache.ObjectIsSerialized);
		EndIf;
	EndDo;
	ProductionProcessCache.AdditionalDataAddress = PutToTempStorage(ElementCache_, UUID);
	ElementCache_ = Undefined;
	
EndProcedure

&AtServer
Procedure ProductionProcessClearItemCache()
	
	ProductionProcessCache.AdditionalDataAddress = PutToTempStorage(New Map, UUID);
	
EndProcedure

&AtServer
Function ProductionProcessItemCacheConstructor(ItemKind)
	
	Result = New Structure;
	
	Result.Insert("ItemKind",           ItemKind);
	Result.Insert("ReadOnly",        False);
	
	Result.Insert("ContainsObject",        False);
	Result.Insert("Object",                Undefined);
	Result.Insert("ObjectIsSerialized", Undefined);
	Result.Insert("FilledIn_",              False);
	Result.Insert("Removed",                False);
	Result.Insert("Write",            False);
	
	FormAttributes = New Structure;
	
	If ItemKind = TypeOfStageElement() Then
		
		FormAttributes.Insert("PlanningIntervalStage");
		
		// MK bank details
		FormAttributes.Insert("StepCalculateCoefficient");
		FormAttributes.Insert("TheSplitRouteSheetsStage");
		FormAttributes.Insert("StageSplitRouteSheetsByRouteMap");
		FormAttributes.Insert("StageMaximumNumberOfUnitsOfProductBatches");
		
		Result.ContainsObject = True;
	ElsIf ItemKind = TypeOfElementOfOperation() Then
		
		// Details of the type of work center
		FormAttributes.Insert("OperationSetupOptionsAreUsed");
		FormAttributes.Insert("ParallelLoadingOperation");
		FormAttributes.Insert("OperationTimeOperationAtSynchronousLoad");
		FormAttributes.Insert("OperationUnitOfMeasurementForSynchronousLoading");
		FormAttributes.Insert("OperationDownloadUnitOfMeasurement");
		FormAttributes.Insert("OperationSynchronousLoading");
		
		// TP details
		FormAttributes.Insert("OperationCalculateCoefficient");
		
		// Additional banking details
		FormAttributes.Insert("OperationAddAttributes");
		FormAttributes.Insert("OperationAdditionalDetailsQuantity");
		
		Result.ContainsObject = True;
		
	ElsIf ItemKind = TypeOfWorkElement() Then
		
		Result.ContainsObject = False; 
	EndIf;
	
	Result.Insert("FormAttributes", FormAttributes);
	
	Return Result;
	
EndFunction

&AtServer
Function ProductionProcessGetItemCache(ElementCache_, RowData, GetObject = False)
	
	ElementCache = ElementCache_.Get(RowData.Ref);
	If ElementCache = Undefined Then
		
		ElementCache = ProductionProcessItemCacheConstructor(RowData.ItemKind);
		
		If ElementCache.ContainsObject And GetObject Then
			ElementCache.Object = RowData.Ref.GetObject();
			ElementCache.ObjectIsSerialized = Serialize(ElementCache.Object);
		EndIf;
		ElementCache.ReadOnly = RowData.ReadOnly;
		
		ElementCache_.Insert(RowData.Ref, ElementCache);
		
	EndIf;
	
	Return ElementCache;
	
EndFunction

&AtServer
Procedure ProductionProcessCacheFormDetails(ElementCache)
	
	FormAttributes = ElementCache.FormAttributes;
	
	For Each KeyAndValue In FormAttributes Do
		
		AttributeName = KeyAndValue.Key;
		
		If TypeOf(ThisObject[AttributeName]) = Type("FormDataCollection") Then
			FormAttributes[AttributeName] = ThisObject[AttributeName].Unload();
		Else
			FormAttributes[AttributeName] = ThisObject[AttributeName];
		EndIf;
		
	EndDo;
	
	ElementCache.FilledIn_ = True;
	
EndProcedure

&AtServer
Procedure ProductionProcessRecoverFormDetailsFromCache(ElementCache)
	
	For Each KeyAndValue In ElementCache.FormAttributes Do
		
		AttributeName      = KeyAndValue.Key;
		AttributeValue = KeyAndValue.Value;
		
		If TypeOf(AttributeValue) = Type("ValueTable") Then
			ThisObject[AttributeName].Load(AttributeValue);
		Else
			ThisObject[AttributeName] = AttributeValue;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function ProductionProcessGetUnitParameters(Form, Department)
	
	UnitParameters = Form.ProductionProcessCache.UnitParameters; // Map
	DivisionParameters = UnitParameters.Get(Department);
	
	If DivisionParameters = Undefined Then
		
		DivisionParameters = DivisionParametersATServer(Department);
		UnitParameters.Insert(Department, DivisionParameters);
		
		Form.ProductionProcessCache.UnitParameters = UnitParameters;
		
	EndIf;
	
	Return DivisionParameters;
	
EndFunction

&AtServerNoContext
Function DivisionParametersATServer(Department)
	
	Return ProductionServer.ProductionBusinessUnitDescription(Department);
	
EndFunction

&AtClient
Procedure UpdateProductionUnitParameters(Department)
	
	DivisionParameters = ProductionProcessCache.UnitParameters.Get(Department);
	If DivisionParameters <> Undefined Then
		ProductionProcessCache.UnitParameters.Delete(Department);
		ProductionProcessGetUnitParameters(ThisObject, Department);
	EndIf;
	
EndProcedure

&AtServer
Function Serialize(Object)
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	WriteXML(XMLWriter, Object);
	Return XMLWriter.Close();
	
EndFunction

&AtServer
Function Deserialize(ObjectIsSerialized)
	
	XMLReader = New XMLReader;
	XMLReader.SetString(ObjectIsSerialized);
	Return ReadXML(XMLReader);
	
EndFunction

#EndRegion

#Region Constants

&AtClientAtServerNoContext
Function TypeOfStageElement()
	Return ProductionProcessEditorClientServer.TypeOfStageElement();
EndFunction
&AtClientAtServerNoContext
Function TypeOfElementOfOperation()
	Return ProductionProcessEditorClientServer.TypeOfElementOfOperation();
EndFunction

&AtClientAtServerNoContext
Function TypeOfWorkElement()
	Return ProductionProcessEditorClientServer.TypeOfWorkElement();
EndFunction
#EndRegion

#EndRegion

#Region InfoBar

&AtClientAtServerNoContext
Procedure ResetDashboard(Form)
	
	Form.InformationBar = Undefined;
	Form.Items.InfoBarPages.CurrentPage = Form.Items.InfoBarPageHide;
	
	If Form.Object.Status <> PredefinedValue("Enum.BOMStatuses.Valid") Then
		Return;
	EndIf;
	
	If Form.Object.ExcludeAutomaticSelection Then
		Form.InformationBar = New FormattedString(
			NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất được loại trừ khỏi lựa chọn tự động trong các chứng từ.';
				|ru = 'Спецификация исключена из автоматического выбора в документы.';
				|en = 'Bill of materials is excluded from the automatic selection to documents.'; fa = 'Bill of materials is excluded from the automatic selection to documents.';
				|it = 'La specifica è esclusa dalla selezione automatica nei documenti.';
				|pl = 'Specyfikacja została wykluczona z automatycznego wyboru w dokumenty.';
				|tr = 'Ürün reçetesi, belgelerdeki otomatik seçimden hariç tutuldu.'"),,
			WebColors.FireBrick);
		Form.Items.InfoBarPages.CurrentPage = Form.Items.InfoBarPageDisplay;
	EndIf;
	
EndProcedure

&AtClient
Procedure StartUpdatingDashboardClient()
	If UpdateOfInformationPanelInBackgroundIsRequired(ThisObject) Then
		
		StartUpdatingDashboard();
		Return;
		
	EndIf;
	ResetDashboard(ThisObject);
	
EndProcedure

&AtServer
Procedure StartUpdatingDashboard()
	
	ResetDashboard(ThisObject);
	If UpdateOfInformationPanelInBackgroundIsRequired(ThisObject) Then
		
		If TimeConsumingOperation <> Undefined Then
			TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
			TimeConsumingOperation = Undefined;
		EndIf;
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.RunInBackground              = True;
		ExecutionParameters.WaitCompletion           = 0;
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Nhận danh sách các bảng kê chi tiết các nguồn lực sản xuất.';
															|ru = 'Получение списка вытесняющих спецификаций.';
															|en = 'Receipt of pushing-out specification list.'; fa = 'Receipt of pushing-out specification list.';
															|it = 'Ricezione dell''elenco delle specifiche prioritarie.';
															|pl = 'Pobieranie listy zastępowanych specyfikacji.';
															|tr = 'Yerine geçen ürün reçetesi listesinin alınması.'");
		
		TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
			"Catalogs.BillsOfMaterials.ListOfPreemptiveSpecificationsInBackground",
			Catalogs.BillsOfMaterials.ListOfPreemptiveSpecificationsCallParameters(Object),
			ExecutionParameters);
		
		If TimeConsumingOperation.Status <> "Running" Then
			
			ProcessResultOfUpdatingDashboard(ThisObject, TimeConsumingOperation);
			TimeConsumingOperation = Undefined;
			
		EndIf;
		
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Function UpdateOfInformationPanelInBackgroundIsRequired(Form)
	
	Return Form.Object.Status = PredefinedValue("Enum.BOMStatuses.Valid")
		And Not Form.Object.ExcludeAutomaticSelection;
	
EndFunction

&AtClient
Procedure StartWaitingForDashboardUpdate()
	
	If TimeConsumingOperation <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"StartUpdatingDashboardCompletion",
			ThisObject);
			
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
			
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			CallbackDescription,
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StartUpdatingDashboardCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		ProcessResultOfUpdatingDashboard(ThisObject, Result);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ProcessResultOfUpdatingDashboard(Form, Result)
	
	If Result.Status = "Completed2"
		And ProcessResultOfUpdatingDashboardOnServer(Result) Then
			
		MessageText = NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất có thể được thay thế bởi ưu tiên cao hơn';
							|ru = 'Спецификация может быть вытеснена более приоритетными';
							|en = 'Bill of materials may be pushed out by more prioritized BOMs'; fa = 'Bill of materials may be pushed out by more prioritized BOMs';
							|it = 'La specifica può essere soppiantata dalle più prioritarie';
							|pl = 'Specyfikacja może być zastąpiona bardziej priorytetowymi';
							|tr = 'Ürün reçetesi daha yüksek öncelikli olabilir'");
		
		RowsArray = New Array;
		RowsArray.Add(New FormattedString(MessageText,, WebColors.FireBrick));
		RowsArray.Add(" ");
		RowsArray.Add(New FormattedString(NStr("vi = '(chi tiết)';
												|ru = '(подробнее)';
												|en = '(more details)'; fa = '(جزئیات بیشتر)';
												|it = '(dettagliatamente)';
												|pl = '(more details)';
												|tr = '(daha fazla bilgi)'"),,,,"DisplacingProductSpecifications"));
		
		Form.InformationBar = New FormattedString(RowsArray);
		Form.Items.InfoBarPages.CurrentPage = Form.Items.InfoBarPageDisplay;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ProcessResultOfUpdatingDashboardOnServer(Result)
	
	Specifications = GetFromTempStorage(Result.ResultAddress);
	
	Return ValueIsFilled(Specifications);
	
EndFunction

#EndRegion

#Region ApplicationClarifications

&AtClient
Procedure OpenSpecificationRefinementSetting(SettingKind)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("ConnectionKey", ProductDataManagementClientServer.SelectionByPropertiesOfCommunicationKey(SettingKind));
	
	SelectionByProperties = ProductDataManagementClient.DetailsOfSettingsByLineInArray(
		FormParameters,
		Object.SelectionByProperties,
		ProductDataManagementClientServer.DetailsSettingUpSelectionByProperties());
		
	FormParameters.Insert("ReadOnly",   Not AttributeAvailability);
	FormParameters.Insert("SelectionByProperties", SelectionByProperties);
	FormParameters.Insert("ProductKind",  MainProductProductKind);
	FormParameters.Insert("SettingKind",     SettingKind);
	FormParameters.Insert("LongDesc",         Object.DescriptionOfUsageSpecification);
	
	CallbackDescription = New CallbackDescription(
		"OpenSpecificationRefinementSettingCompletion",
		ThisObject,
		SettingKind);
	
	OpenForm("Catalog.BillsOfMaterials.Form.SettingsFormOfBOMApplicationSpecification",
		FormParameters,
		ThisObject,,,,
		CallbackDescription);
	
EndProcedure

// Notification when the application refinement configuration is completed
// 
// Parameters:
// 	SettingsResult - Structure - From:
// 		* SelectionByProperties - ValueTable - selection table by properties
// 		* LongDesc - String - configuration description
// 	AdditionalParameters - Structure - advanced setting
&AtClient
Procedure OpenSpecificationRefinementSettingCompletion(SettingsResult, AdditionalParameters) Export
	
	If SettingsResult = Undefined Then
		Return;
	EndIf;
	
	Modified = True;
	
	ConnectionKey = ProductDataManagementClientServer.SelectionByPropertiesOfCommunicationKey(AdditionalParameters);
	
	ProductDataManagementClient.UpdateSelectionSettingsByPropertiesByKey(
		Object.SelectionByProperties,
		SettingsResult.SelectionByProperties,
		ConnectionKey);
		
	Object.DescriptionOfUsageSpecification = SettingsResult.LongDesc;
	
	UpdateInformationOnMainProductSpecification();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfMainFINISHEDProduct()
	
	QueryTexts = New Array;
	QueryTexts.Add("
	|SELECT
	|	CASE
	|		WHEN T.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE FALSE
	|	END           AS MainProductItemVariantsAreUsed,
	|
	|	MAX(CASE
	|		WHEN SetOfProductProperties_.Ref IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END)          AS MainProductProductsHasPropeties,
	|
	|	MAX(CASE
	|		WHEN T.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN (NOT SetPropertiesCharacteristics.Ref IS NULL)
	|		ELSE FALSE
	|	END)          AS MainProductCharacteristicHasPropeties
	|
	|FROM
	|	&Table AS T
	|
	|		LEFT JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS SetOfProductProperties_
	|		ON &UseAdditionalAttributesAndInfo
	|			AND NOT SetOfProductProperties_.DeletionMark
	|			AND (SetOfProductProperties_.Ref = &TypeOfItemSetOfProperties1
	|				OR SetOfProductProperties_.Ref = &Set_Catalog_Products_Overall)
	|
	|		LEFT JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS SetPropertiesCharacteristics
	|		ON &UseAdditionalAttributesAndInfo
	|			AND NOT SetPropertiesCharacteristics.DeletionMark
	|			AND (SetPropertiesCharacteristics.Ref =
	|					CASE
	|						WHEN T.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|							THEN T.ItemVariantsOwner.CharacteristicsPropertySet
	|						ELSE &TypeOfItemSetOfProperties2
	|					END
	|				OR SetPropertiesCharacteristics.Ref = &Set_Catalog_ItemsCharacteristics_Overall)
	|WHERE
	|	T.Ref = &Ref
	|
	|GROUP BY
	|	CASE
	|		WHEN T.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE FALSE
	|	END");
	
	If Object.AssignmentOption = PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.ProductKind") Then
		TableName = "ItemKinds";
		AttributeName = "MainProductProductKind";
		DataSourceTypeOfProduct = "T";
	Else
		TableName = "Products";
		AttributeName = "MainProductProducts";
		DataSourceTypeOfProduct = "T.ProductKind";
		If UseGoodsQuality Then
			QueryTexts.Add("
			|SELECT TOP 1
			|	MainProduct.Presentation AS MainProductPresentation,
			|	ISNULL(AnotherQualityGoods.OtherQualityGoods.Presentation, """") AS MainProductProductsOfDifferentQualityPresentation
			|FROM
			|	Catalog.Products AS MainProduct
			|	
			|	LEFT JOIN InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
			|	ON MainProduct.Ref = AnotherQualityGoods.Products
			|		AND MainProduct.ProductKind = AnotherQualityGoods.OtherQualityGoods.ProductKind
			|		AND MainProduct.UseVariants = AnotherQualityGoods.OtherQualityGoods.UseVariants
			|		AND MainProduct.UnitOfMeasure = AnotherQualityGoods.OtherQualityGoods.UnitOfMeasure
			|		AND MainProduct.UsePackages = AnotherQualityGoods.OtherQualityGoods.UsePackages
			|		AND NOT AnotherQualityGoods.OtherQualityGoods.DeletionMark
			|		AND AnotherQualityGoods.QualityGradation = VALUE(Enum.QualityLevels.SuitableToALimitedExtent)
			|WHERE
			|	MainProduct.Ref = &Ref");
		EndIf;
	EndIf;
	
	Query = New Query;
	QueryText = ProductionManagement.CombineRequestTextsIntoPackage(QueryTexts);
	QueryText = StrReplace(QueryText, "&Table",                      StrTemplate("Catalog.%1", TableName));
	QueryText = StrReplace(QueryText, "&TypeOfItemSetOfProperties1", StrTemplate("%1.PropertiesSet", DataSourceTypeOfProduct));
	QueryText = StrReplace(QueryText, "&TypeOfItemSetOfProperties2", StrTemplate("%1.CharacteristicsPropertySet", DataSourceTypeOfProduct));
	Query.Text = QueryText;
	Query.SetParameter("Ref", ThisObject[AttributeName]);
	Query.SetParameter("UseAdditionalAttributesAndInfo", GetFunctionalOption("UseAdditionalAttributesAndInfo"));
	Query.SetParameter("Set_Catalog_Products_Overall", PropertyManager.PropertiesSetByName("Catalog_Products_Overall"));
	Query.SetParameter("Set_Catalog_ItemsCharacteristics_Overall", PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall"));
	
	QueryResults = Query.ExecuteBatch();
	
	Selection = QueryResults[0].Select();
	If Selection.Next() Then
		FillPropertyValues(ThisObject, Selection);
	Else
		MainProductProductsHasPropeties   = False;
		MainProductCharacteristicHasPropeties = False;
		MainProductItemVariantsAreUsed = False;
	EndIf;
	
	If Object.AssignmentOption = PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.Products")
		And UseGoodsQuality Then
		Selection = QueryResults[1].Select();
		If Selection.Next() Then
			MainProductProductsOfDifferentQualityPresentation = ?(IsBlankString(Selection.MainProductProductsOfDifferentQualityPresentation),
				StrTemplate(NStr("vi = '%1, Dùng được hạn chế';
								|ru = '%1, Ограниченно годен';
								|en = '%1, Limited quality'; fa = '%1, Limited quality';
								|it = '%1, Ограниченно годен';
								|pl = '%1, Limited quality';
								|tr = '%1, Sınırlı geçerli'"), Selection.MainProductPresentation),
				Selection.MainProductProductsOfDifferentQualityPresentation);
		Else
			MainProductProductsOfDifferentQualityPresentation = "";
		EndIf;
	Else
		MainProductProductsOfDifferentQualityPresentation = "";
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSettingsForApplicationRefinementElements(Form, SettingKind, Enabled = True)
	
	Items = Form.Items;
	Object = Form.Object;
	ElementNames = ItemNamesBySettingType(SettingKind);
	
	CurrentCommand = Items[ElementNames.ClarificationOfApplication]; // FormButton
	
	ConnectionKey = ProductDataManagementClientServer.SelectionByPropertiesOfCommunicationKey(SettingKind);
		
	ListOfSelectionLines = Object.SelectionByProperties.FindRows(New Structure("ConnectionKey", ConnectionKey));
	ThereAreAdvancedSettings = (ListOfSelectionLines.Count() > 0);
	
	CurrentCommand.Enabled = Not ValueIsFilled(Form[ElementNames.MainProduct])
		And (Form[ElementNames.ThereAreProperties] Or ThereAreAdvancedSettings)
		And Enabled;
		
	If ThereAreAdvancedSettings Then
		Items[ElementNames.MainProduct].InputHint = NStr("vi = '<với lựa chọn theo thuộc tính>';
														|ru = '<с отбором по свойствам>';
														|en = '<with filter by properties>'; fa = '<with filter by properties>';
														|it = '<con selezione per proprietà>';
														|pl = '<z wyborem wg właściwości>';
														|tr = '<özelliklere göre filtre ile>'");
		CurrentCommand.Picture = PictureLib.FilterByKindsAndPropertiesOfItems;
	Else
		CurrentCommand.Picture = PictureLib.Filters;
	EndIf;
	SetHintTextToClarifyApplicationSpecification(Form, SettingKind, CurrentCommand, ListOfSelectionLines);
	
EndProcedure

&AtClientAtServerNoContext
Function ItemNamesBySettingType(SettingKind)
	
	Result = New Structure;
	
	If SettingKind = "Products" Then
		Result.Insert("ClarificationOfApplication",    "UsageClarificationProduct");
		Result.Insert("MainProduct",        "MainProductProducts");
		Result.Insert("ThereAreProperties",           "MainProductProductsHasPropeties");
	ElsIf SettingKind = "Characteristic" Then
		Result.Insert("ClarificationOfApplication",    "UsageClarificationCharacteristic");
		Result.Insert("MainProduct",        "MainProductCharacteristic");
		Result.Insert("ThereAreProperties",           "MainProductCharacteristicHasPropeties");
	EndIf;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetHintTextToClarifyApplicationSpecification(Form, SettingKind, Command, ListOfSelectionLines)
	
	ToolTipText = "";
	
	If Command.Enabled Then
		
		If ListOfSelectionLines.Count() > 0 Then
			
			PropertiesArray = New Array;
			For Each String In ListOfSelectionLines Do
				If PropertiesArray.Find(String.Property) = Undefined Then
					PropertiesArray.Add(String.Property);
				EndIf;
			EndDo;
			
			ToolTipText = StrTemplate(NStr("vi = 'Đặt lọc theo %1: %2';
											|ru = 'Установлен отбор по %1: %2';
											|en = 'Filter by %1: %2 is set'; fa = 'Filter by %1: %2 is set';
											|it = 'Impostata la selezione per %1:%2';
											|pl = 'Ustalono wybór wg %1: %2';
											|tr = '%1 göre filtre yapılandırıldı: %2'"),
				?(PropertiesArray.Count()>1, NStr("vi = 'thuộc tính';
													|ru = 'свойствам';
													|en = 'properties'; fa = 'properties';
													|it = 'alle proprietà';
													|pl = 'właściwości';
													|tr = 'özelliklere'"), NStr("vi = 'thuộc tính';
																			|ru = 'свойству';
																			|en = 'property'; fa = 'property';
																			|it = 'alla proprietà';
																			|pl = 'właściwości';
																			|tr = 'özelliğe'")),
				StrConcat(PropertiesArray, "; "));
				
		Else
			
			ToolTipText = NStr("vi = 'Đã thiết lập lọc theo thuộc tính';
								|ru = 'Установить отбор по свойствам';
								|en = 'Set filter by properties'; fa = 'Set filter by properties';
								|it = 'Impostare filtro per proprietà';
								|pl = 'Ustaw filtr wg właściwości';
								|tr = 'Özelliklere göre filtre yapılandır'");
			
		EndIf;
		
	Else
		
		AssignmentOptionTypeOfProduct = (Form.Object.AssignmentOption = PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.ProductKind"));
		ElementNames = ItemNamesBySettingType(SettingKind);
		
		If SettingKind = "Products" And Not AssignmentOptionTypeOfProduct Then
			ToolTipText = NStr("vi = 'Cho phép lọc theo các thuộc tính của mặt hàng đối với bảng kê chi tiết trong dạng mặt hàng';
								|ru = 'Отбор по свойствам номенклатуры доступен для спецификаций на вид номенклатуры';
								|en = 'Filter by item properties is available for bills of materials per item kind'; fa = 'Filter by item properties is available for bills of materials per item kind';
								|it = 'Filtro per proprietà di nomenclatura disponibile per le specifiche per tipo di nomenclatura';
								|pl = 'Filtr wg właściwości pozycji jest dostępny dla specyfikacji dla rodzaju pozycji';
								|tr = 'Öğe özelliklerine göre filtre, ürün türüne yönelik ürün reçeteleri için kullanılabilir'");
		ElsIf SettingKind = "Characteristic" And Not Form.MainProductItemVariantsAreUsed Then
			ToolTipText = NStr("vi = 'Không sử dụng đặc tính, không thể lọc theo thuộc tính';
								|ru = 'Характеристики не используются, отбор по свойствам недоступен';
								|en = 'Variants are not used, filter by properties is not available'; fa = 'Variants are not used, filter by properties is not available';
								|it = 'Le caratteristiche non sono utilizzate, il filtro per proprietà non è disponibile';
								|pl = 'Charakterystyki nie są używane, filtr wg właściwości jest niedostępny';
								|tr = 'Varyantlar kullanılmamaktadır, özelliklere göre filtre mevcut değil'");
		ElsIf Not Form[ElementNames.ThereAreProperties] Then
			ToolTipText = NStr("vi = 'Không có thuộc tính để thiết lập bộ lọc';
								|ru = 'Отсутствуют свойства для установки отбора';
								|en = 'Missing properties for setting filter'; fa = 'Missing properties for setting filter';
								|it = 'Mancano le proprietà per l''impostazione del filtro';
								|pl = 'Brak właściwości dla ustawienia filtru';
								|tr = 'Filtre yapılandırmak için özellik bulunmamaktadır'");
		EndIf;
			
	EndIf;
	
	Command.ExtendedTooltip.Title = ToolTipText;
	
EndProcedure

#EndRegion

#Region ImportDataFromFile

&AtClient
Procedure ShowUploadFormFromFile(AdditionalParameters)
	
	FullTabularSectionName = "BillsOfMaterials.%1";
	FullTabularSectionName = StrTemplate(FullTabularSectionName, AdditionalParameters.TSName);
	
	HeaderOfUploadForm = NStr("vi = 'Kết nhập bảng ""%1"" từ tệp';
								|ru = 'Загрузка таблицы ""%1"" из файла';
								|en = 'Download the table ""%1"" from the file'; fa = 'Download the table ""%1"" from the file';
								|it = 'Download della tabella ""%1"" dal file';
								|pl = 'Wczytywanie tabeli „%1” z pliku';
								|tr = 'Dosyadan ""%1"" tablosunun yüklenmesi'");
	HeaderOfUploadForm = StrTemplate(HeaderOfUploadForm, AdditionalParameters.TSSynonym);
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = FullTabularSectionName;
	ImportParameters.Title               = HeaderOfUploadForm;
	ImportParameters.AdditionalParameters = AdditionalParameters;
	
	If AdditionalParameters.TSName = "LaborCosts" Then
		ImportParameters.TemplateColumns = DescriptionOfTemplateColumnsForLoadingLaborCosts();
	Else
		ImportParameters.TemplateColumns = DescriptionOfTemplateColumnsForLoadingProducts(AdditionalParameters.TSName);
	EndIf;
	
	Notification = New CallbackDescription("ShowUploadFormFromFileCompletion", ThisObject, AdditionalParameters);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ShowUploadFormFromFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then
		Return;
	EndIf;
	
	UploadFromFileOnServer(ImportedDataAddress, AdditionalParameters);
	
EndProcedure

&AtClient
Function DescriptionOfTemplateColumnsForLoadingProducts(TSName);
	
	TemplateColumns = New Array;
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Barcode", New TypeDescription("String",, New StringQualifiers(200)), NStr("vi = 'Mã vạch';
																																			|ru = 'Штрихкод';
																																			|en = 'Barcode'; fa = 'بارکد';
																																			|it = 'Codice a barre';
																																			|pl = 'Kod kreskowy';
																																			|tr = 'Barkod'"), 10);
	Column.Position = 1;
	Column.Parent = "Products";
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("SKU", New TypeDescription("String",, New StringQualifiers(50)), NStr("vi = 'Mã hiệu';
																																		|ru = 'Артикул';
																																		|en = 'Item ID'; fa = 'شناسه قلم';
																																		|it = 'Articolo';
																																		|pl = 'Artykuł';
																																		|tr = 'Ürün kodu'"), 10);
	Column.Position = 2;
	Column.Parent = "Products";
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("ProductsAndServicesCode", New TypeDescription("String",, New StringQualifiers(11)), NStr("vi = 'Mã hàng';
																																							|ru = 'Код номенклатуры';
																																							|en = 'Items code'; fa = 'کد اقلام';
																																							|it = 'Codice dell''elenco articoli';
																																							|pl = 'Kod towaru';
																																							|tr = 'Öğe kodu'"), 15);
	Column.Position = 3;
	Column.Parent = "Products";
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Products", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Mặt hàng';
																																				|ru = 'Номенклатура';
																																				|en = 'Item'; fa = 'قلم';
																																				|it = 'Articolo';
																																				|pl = 'Pozycja';
																																				|tr = 'Öğe'"), 15);
	Column.Position = 4;
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Characteristic", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Đặc tính';
																																					|ru = 'Характеристика';
																																					|en = 'Variant'; fa = 'گونه';
																																					|it = 'Caratteristica';
																																					|pl = 'Charakterystyka';
																																					|tr = 'Varyant'"), 15);
	Column.Position = 5;
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("NumberOfPackages", New TypeDescription("Number",, New NumberQualifiers(15, 3)), NStr("vi = 'Số lượng';
																																						|ru = 'Количество';
																																						|en = 'Quantity'; fa = 'مقدار';
																																						|it = 'Quantità';
																																						|pl = 'Ilość';
																																						|tr = 'Miktar'"), 10);
	Column.Position = 6;
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("PackageCode", New TypeDescription("String",, New StringQualifiers(4)), NStr("vi = 'Mã đóng gói';
																																				|ru = 'Код упаковки';
																																				|en = 'Packaging unit code'; fa = 'کد واحد بسته‌بندی';
																																				|it = 'Codice di imballaggio';
																																				|pl = 'Kod opakowania';
																																				|tr = 'Paketleme ünitesi kodu'"), 12);
	Column.Position = 7;
	Column.Parent = "Package";
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Package", New TypeDescription("String",, New StringQualifiers(50)), NStr("vi = 'Đóng gói';
																																			|ru = 'Упаковка';
																																			|en = 'Packaging unit'; fa = 'واحد بسته‌بندی';
																																			|it = 'Imballaggio';
																																			|pl = 'Opakowanie';
																																			|tr = 'Paketleme ünitesi'"), 10);
	Column.Position = 8;
	TemplateColumns.Add(Column);
	
	Position = 8;
	
	If Object.MultiStageProductionProcess Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("StageNumber", New TypeDescription("Number",, New NumberQualifiers(5, 0)), NStr("vi = 'Số công đoạn';
																																						|ru = 'Номер этапа';
																																						|en = 'Stage number'; fa = 'شماره مرحله';
																																						|it = 'Numero della fase';
																																						|pl = 'Numer etapu';
																																						|tr = 'Aşama numarası'"), 10);
		Column.Position = Position + 1;
		Column.Parent = "Stage";
		TemplateColumns.Add(Column);
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Stage", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Công đoạn';
																																				|ru = 'Этап';
																																				|en = 'Stage'; fa = 'مرحله';
																																				|it = 'Fase';
																																				|pl = 'Etap';
																																				|tr = 'Aşama'"), 15);
		Column.Position = Position + 2;
		TemplateColumns.Add(Column);
		
		Position = Position + 2;
	EndIf;
	If StoreOperationsInBillsOfMaterials Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("OperationNumber", New TypeDescription("Number",, New NumberQualifiers(5, 0)), NStr("vi = 'Số giao dịch';
																																							|ru = 'Номер операции';
																																							|en = 'Operation number'; fa = 'شماره عملیات';
																																							|it = 'Numero di operazione';
																																							|pl = 'Numer operacji';
																																							|tr = 'İşlem numarası'"), 13);
		Column.Position = Position + 1;
		Column.Parent = "Operation";
		TemplateColumns.Add(Column);
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Operation", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Giao dịch';
																																					|ru = 'Операция';
																																					|en = 'Operation'; fa = 'عملیات';
																																					|it = 'Operazione';
																																					|pl = 'Operacja';
																																					|tr = 'İşlem'"), 15);
		Column.Position = Position + 2;
		TemplateColumns.Add(Column);
		
		Position = Position + 2;
	EndIf;
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("ProductCostElement", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Dạng tính giá thành';
																																						|ru = 'Статья калькуляции';
																																						|en = 'Product cost element'; fa = 'عنصر بهای تمام‌شده محصول';
																																						|it = 'Voce di calcolo';
																																						|pl = 'Rodzaj kosztu';
																																						|tr = 'Ürün maliyet kalemi'"), 17);
	Column.Position = Position + 1;
	TemplateColumns.Add(Column);
	
	Position = Position + 1;
	
	If TSName = "MaterialsAndServices" Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("MaterialApplication", New TypeDescription("String",, New StringQualifiers(0)), NStr("vi = 'Sử dụng nguyên vật liệu';
																																							|ru = 'Применение материала';
																																							|en = 'Material application'; fa = 'کاربرد ماده';
																																							|it = 'Uso del materiale';
																																							|pl = 'Zastosowanie materiału';
																																							|tr = 'Malzemenin uygulanması'"), 20);
		Column.Position = Position + 1;
		TemplateColumns.Add(Column);
	Else
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("ProductDescription", New TypeDescription("String",, New StringQualifiers(0)), NStr("vi = 'Mô tả sản phẩm';
																																							|ru = 'Описание изделия';
																																							|en = 'Product description'; fa = 'شرح محصول';
																																							|it = 'Descrizione del prodotto';
																																							|pl = 'Opis wyrobu';
																																							|tr = 'Nihai ürün ayrıntıları'"), 20);
		Column.Position = Position + 1;
		TemplateColumns.Add(Column);
	EndIf;
	
	Return TemplateColumns;
	
EndFunction

&AtClient
Function DescriptionOfTemplateColumnsForLoadingLaborCosts();
	
	TemplateColumns = New Array;
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("WorkKindCode", New TypeDescription("String",, New StringQualifiers(11)), NStr("vi = 'Mã dạng công việc';
																																				|ru = 'Код вида работ';
																																				|en = 'Activity kind code'; fa = 'کد نوع فعالیت';
																																				|it = 'Codice del tipo dei lavori';
																																				|pl = 'Kod rodzaju prac';
																																				|tr = 'Etkinlik türü kodu'"), 15);
	Column.Position = 1;
	Column.Parent = "WorkKind";
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("WorkKind", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Dạng công việc';
																																				|ru = 'Вид работ';
																																				|en = 'Activity kind'; fa = 'نوع فعالیت';
																																				|it = 'Tipo di lavori';
																																				|pl = 'Rodzaj prac';
																																				|tr = 'İş türü'"), 15);
	Column.Position = 2;
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("Count", New TypeDescription("Number",, New NumberQualifiers(15, 3)), NStr("vi = 'Số lượng';
																																			|ru = 'Количество';
																																			|en = 'Quantity'; fa = 'مقدار';
																																			|it = 'Quantità';
																																			|pl = 'Ilość';
																																			|tr = 'Miktar'"), 10);
	Column.Position = 3;
	TemplateColumns.Add(Column);
	
	Position = 3;
	
	If Object.MultiStageProductionProcess Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("StageNumber", New TypeDescription("Number",, New NumberQualifiers(5, 0)), NStr("vi = 'Số công đoạn';
																																						|ru = 'Номер этапа';
																																						|en = 'Stage number'; fa = 'شماره مرحله';
																																						|it = 'Numero della fase';
																																						|pl = 'Numer etapu';
																																						|tr = 'Aşama numarası'"), 10);
		Column.Position = Position + 1;
		Column.Parent = "Stage";
		TemplateColumns.Add(Column);
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Stage", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Công đoạn';
																																				|ru = 'Этап';
																																				|en = 'Stage'; fa = 'مرحله';
																																				|it = 'Fase';
																																				|pl = 'Etap';
																																				|tr = 'Aşama'"), 15);
		Column.Position = Position + 2;
		TemplateColumns.Add(Column);
		
		Position = Position + 2;
	EndIf;
	If StoreOperationsInBillsOfMaterials Then
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("OperationNumber", New TypeDescription("Number",, New NumberQualifiers(5, 0)), NStr("vi = 'Số giao dịch';
																																							|ru = 'Номер операции';
																																							|en = 'Operation number'; fa = 'شماره عملیات';
																																							|it = 'Numero di operazione';
																																							|pl = 'Numer operacji';
																																							|tr = 'İşlem numarası'"), 12);
		Column.Position = Position + 1;
		Column.Parent = "Operation";
		TemplateColumns.Add(Column);
		
		Column = ImportDataFromFileClientServer.TemplateColumnDetails("Operation", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Giao dịch';
																																					|ru = 'Операция';
																																					|en = 'Operation'; fa = 'عملیات';
																																					|it = 'Operazione';
																																					|pl = 'Operacja';
																																					|tr = 'İşlem'"), 15);
		Column.Position = Position + 2;
		TemplateColumns.Add(Column);
		
		Position = Position + 2;
	EndIf;
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("ProductCostElement", New TypeDescription("String",, New StringQualifiers(150)), NStr("vi = 'Dạng tính giá thành';
																																						|ru = 'Статья калькуляции';
																																						|en = 'Product cost element'; fa = 'عنصر بهای تمام‌شده محصول';
																																						|it = 'Voce di calcolo';
																																						|pl = 'Rodzaj kosztu';
																																						|tr = 'Ürün maliyet kalemi'"), 17);
	Column.Position = Position + 1;
	TemplateColumns.Add(Column);
	
	Column = ImportDataFromFileClientServer.TemplateColumnDetails("WorkAssignment", New TypeDescription("String",, New StringQualifiers(0)), NStr("vi = 'Chỉ định công việc';
																																					|ru = 'Назначение работ';
																																					|en = 'Work assignment'; fa = 'تخصیص کار';
																																					|it = 'Destinazione lavori';
																																					|pl = 'Przeznaczenie prac';
																																					|tr = 'İş ataması'"), 20);
	Column.Position = Position + 2;
	TemplateColumns.Add(Column);
	
	Return TemplateColumns;
	
EndFunction

&AtServer
Procedure UploadFromFileOnServer(ImportedDataAddress, AdditionalParameters)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress); //ValueTable
	
	TSName = AdditionalParameters.TSName;
	
	TabularSection = Object[TSName];// TabularSection
	TabularSection.Clear();
	
	For Each String In ImportedData Do
		
		NewRow = TabularSection.Add();
		FillPropertyValues(NewRow, String);
		
		NewRow.StageEditingPresentation = String.Stage;
		NewRow.StageEditing               = String.Stage;
		NewRow.OperationEditPresentation = String.Operation;
		NewRow.OperationEdit              = String.Operation;
		NewRow.ElementOfProductionProcessPresentation = RepresentationOfProductionProcessElement(ThisObject, NewRow);
		
		WhenEnteringNewSpecificationLine(ThisObject, TSName, NewRow);
		
	EndDo;
	
	FillInServiceDetails();
	
EndProcedure

&AtClient
Procedure LoadFromFile(TSName, TSSynonym)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName",                              TSName);
	AdditionalParameters.Insert("TSSynonym",                          TSSynonym);
	AdditionalParameters.Insert("BillOfMaterial",              Object.Ref);
	AdditionalParameters.Insert("StagesAreUsed",                  Object.MultiStageProductionProcess);
	AdditionalParameters.Insert("OperationsAreUsed",               StoreOperationsInBillsOfMaterials);
	AdditionalParameters.Insert("AddressOfProductionProcessElements", TableOfProductionProcessElementsInStorage());
	
	ArrayOfProductTypes = ProductDataManagementClientServer.ArrayOfAvailableItemTypes(ThisObject, TSName);
	AvailableProductTypes = New FixedArray(ArrayOfProductTypes);
	
	AdditionalParameters.Insert("AvailableProductTypes", AvailableProductTypes);
	
	If Not Object[TSName].Count() = 0 Then
		
		QueryText = NStr("vi = 'Bảng %1 sẽ được điền lại. Tiếp tục?';
						|ru = 'Таблица %1 будет перезаполнена. Продолжить?';
						|en = 'The table %1 will be refilled. Continue?'; fa = 'The table %1 will be refilled. Continue?';
						|it = 'La tаbellа %1 verrà precompilata. Continuare?';
						|pl = 'Tabela %1 zostanie uzupełniona ponownie. Kontynuować?';
						|tr = '%1 tablosu yeniden doldurulacaktır. Devam edilsin mi?'");
		QueryText = StrTemplate(QueryText, TSSynonym);
		
		Notification = New CallbackDescription("LoadFromFileCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
		
	Else
		ShowUploadFormFromFile(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadFromFileCompletion(Result, AdditionalParameters) Export
	
	If Not Result = DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ShowUploadFormFromFile(AdditionalParameters);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	CurrentSpecificationStatus = Enums.BOMStatuses.Valid;
	SpecificationStatusInDevelopment = Enums.BOMStatuses.UnderDevelopment;
	
	StoreOperationsInBillsOfMaterials = GetFunctionalOption("StoreOperationsInBillsOfMaterials");
	UseRouteSheets            = GetFunctionalOption("UseRouteSheets");
	UseGoodsQuality            = GetFunctionalOption("UseGoodsQuality");
	UseBillOfMaterialsParameterization = GetFunctionalOption("UseBillOfMaterialsParameterization");
	
	StartFillingProductionProcess();
	
	StartUpdatingDashboard();
	
	ReadMainProductSpecificationData();
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(Object, Catalogs.BillsOfMaterials);
	Array = New Array;
	Array.Add(Items.ManufacturedProductsBillOfMaterials);
	Array.Add(Items.RecyclableWasteBillOfMaterials);
	ProductDataManagement.SetSpecificationSelectionParameters(Array, BOMSelectionParameters.Disassembly);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.MaterialsAndServicesSourceOfSemiFinishedProduct, BOMSelectionParameters.Assembly);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.WorksBeingPerformedBillOfMaterials, BOMSelectionParameters.PerformRM);
	
	SetParametersForSelectingResponsibleDepartment();
	
	CostAllocationParameters = New FixedStructure(Catalogs.BillsOfMaterials.CostAllocationParameters(Object));
	
	ProcessingOfTabularForms.InitializeRowCache(Items.ManufacturedProduct);
	ProcessingOfTabularForms.InitializeRowCache(Items.ManufacturedProducts);
	UseInternalSubcontracting = GetFunctionalOption("UseInternalSubcontracting");
	ProcessSpecificationAssignmentParameters();
	FillInServiceDetails();
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// standard design of the nomenclature
	#Region StandardAppearance
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ManufacturedProductProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.ManufacturedProducts.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ManufacturedProductsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.ManufacturedProducts.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "RecyclableWasteProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.RecyclableWaste.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "MaterialsAndServicesProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.MaterialsAndServices.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	SetConditionalAppearanceOfTablePartsWithAutoSelection();
	
	#EndRegion
	
	// Bold font for the first line of products
	#Region BoldFirstLine
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProduct.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.LineNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("Font", StyleFonts.ImportantLabelFont);
	
	#EndRegion

	#Region OnlyViewWhenProductionProcessIsUnread
	
	NamesOfEditingElements = NamesOfEditingElements();
	
	For Each TSName In StrSplit("ManufacturedProduct,ManufacturedProducts,RecyclableWaste,MaterialsAndServices,LaborCosts",",") Do
			
		Item = ConditionalAppearance.Items.Add();
		
		Item.Fields.Items.Add().Field = New DataCompositionField(Items[NamesOfEditingElements[TSName]].Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ProductionProcessRead");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
	EndDo;
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.IntermediateReleaseIsElementOfProductionProcess.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.MaterialsAndServicesMethodOfGettingTheMaterialEditing.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductionProcessRead");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion

	// Text <last stage> or <first stage>
	// during disassembly, several last stages are possible
	// during assembly, several first stages are possible
	
	#Region DesignOfElementsOfProductionProcess
	
	StructureOfElements = New Map();
	StructureOfElements.Insert("ProductsAreElementOfProductionProcess",        "ManufacturedProducts");
	StructureOfElements.Insert("OutputProductsAreElementOfProductionProcess",  "ManufacturedProducts");
	StructureOfElements.Insert("ReturnableWasteIsElementOfProductionProcess", "RecyclableWaste");
	
	TextStage = Lower(TitleOfProductionStageElement(ThisObject));
	
	For Each KeyAndValue In StructureOfElements Do
	
		Item = ConditionalAppearance.Items.Add();
		
		Item.Fields.Items.Add().Field = New DataCompositionField(Items[KeyAndValue.Key].Name);
	
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(StrTemplate("Object.%1.StageEditing", KeyAndValue.Value));
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("StoreOperationsInBillsOfMaterials");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
		ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("SeveralLastSteps");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.ProductionProcessType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = Enums.ProductionProcessTypes.Disassembly;
		
		Item.Appearance.SetParameterValue("Text", StrTemplate(NStr("vi = '<cuối cùng %1>';
																	|ru = '<последний %1>';
																	|en = '<last %1>'; fa = '<last %1>';
																	|it = '<last %1>';
																	|pl = '<last %1>';
																	|tr = '<son %1>'"), TextStage));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		
		Item = ConditionalAppearance.Items.Add();
		
		Item.Fields.Items.Add().Field = New DataCompositionField(Items[KeyAndValue.Key].Name);
	
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(StrTemplate("Object.%1.StageEditing", KeyAndValue.Value));
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("StoreOperationsInBillsOfMaterials");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
		ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("SeveralLastSteps");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.ProductionProcessType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = Enums.ProductionProcessTypes.Disassembly;
		
		Item.Appearance.SetParameterValue("Text", StrTemplate(NStr("vi = '<giao dịch %1 / cuối cùng>';
																	|ru = '<последний %1 / операция>';
																	|en = '<last %1 / operation>'; fa = '<last %1 / operation>';
																	|it = '<last %1 / operation>';
																	|pl = '<last %1 / operation>';
																	|tr = '<son %1 / operasyon>'"), TextStage));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		
	EndDo;
	
	StructureOfElements = New Map();
	StructureOfElements.Insert("MaterialsAndServicesElementOfProductionProcess", "MaterialsAndServices");
	StructureOfElements.Insert("LaborCostsAreElementOfProductionProcess",     "LaborCosts");
	
	For Each KeyAndValue In StructureOfElements Do

		Item = ConditionalAppearance.Items.Add();
	
		Item.Fields.Items.Add().Field = New DataCompositionField(Items[KeyAndValue.Key].Name);
	
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(StrTemplate("Object.%1.StageEditing", KeyAndValue.Value));
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("StoreOperationsInBillsOfMaterials");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
		ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("SeveralFirstSteps");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.ProductionProcessType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = Enums.ProductionProcessTypes.Assembly;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
		Item.Appearance.SetParameterValue("Text", StrTemplate(NStr("vi = '<đầu tiên %1>';
																	|ru = '<первый %1>';
																	|en = '<first %1>'; fa = '<first %1>';
																	|it = '<first %1>';
																	|pl = '<first %1>';
																	|tr = '<ilk %1>'"), TextStage));
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		Item = ConditionalAppearance.Items.Add();
	
		Item.Fields.Items.Add().Field = New DataCompositionField(Items[KeyAndValue.Key].Name);
	
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(StrTemplate("Object.%1.StageEditing", KeyAndValue.Value));
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("StoreOperationsInBillsOfMaterials");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
		OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
		
		ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("SeveralFirstSteps");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Object.ProductionProcessType");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = Enums.ProductionProcessTypes.Assembly;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
		Item.Appearance.SetParameterValue("Text", StrTemplate(NStr("vi = '<giao dịch %1 / đầu tiên>';
																	|ru = '<первый %1 / операция>';
																	|en = '<first %1 / operation>'; fa = '<first %1 / operation>';
																	|it = '<first %1 / operation>';
																	|pl = '<first %1 / operation>';
																	|tr = '<ilk %1 / operasyon>'"), TextStage));
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
	EndDo;
	
	#EndRegion
	
	// Text <any characteristic>
	#Region TextAnyCharacteristic
	Item = ConditionalAppearance.Items.Add();

	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturedProductCharacteristic.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturedProductsCharacteristic.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ProductionProcessType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	
	List = New ValueList;
	List.Add(Enums.ProductionProcessTypes.Assembly);
	List.Add(Enums.ProductionProcessTypes.PerformRM);
	List.Add(Enums.ProductionProcessTypes.Repair);
	ItemFilter.RightValue = List;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.ItemVariantsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.LineNumber");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đặc tính bất kỳ>';
													|ru = '<любая характеристика>';
													|en = '<any variant>'; fa = '<any variant>';
													|it = '<qualsiasi caratteristica>';
													|pl = '<dowolna charakterystyka>';
													|tr = '<herhangi bir varyant>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion

	// It is required to fill in the cost shares
	#Region CostShares
	
	ProductionServer.SetConditionalAppearanceOfShareCostPercentageField(ThisObject, "Object", "ManufacturedProducts", "ManufacturedProduct");
	
	ProductionServer.SetConditionalAppearanceOfShareCostPercentageField(ThisObject, "Object", "ManufacturedProducts", "ManufacturedProducts");
	
	SetConditionalAppearanceOfShareOfCostOfOutputProductsField("ManufacturedProduct");
	SetConditionalAppearanceOfShareOfCostOfOutputProductsField("ManufacturedProducts");
	
	#EndRegion
	
	// Prohibition of editing the "Register series" flag
	#Region SeriesAreUsed
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductBatchIndicationRequired.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.SeriesAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndServicesBatchIndicationRequired.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.SeriesAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	#Region ProductCostElement
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndServicesProductCostElement.Name);
	
	// Prohibition of editing a predefined calculation article
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.ProducedInProcess");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndServicesProductCostElement.Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.ItemsTypes.Set");
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.ProductCostElement");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SourceOfCompositionOfSetsInProduction");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SourcesOfCompositionOfSetsInProduction.Specifications;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<được chỉ ra trong thành phần bộ sản phẩm>';
													|ru = '<указывается в составе набора>';
													|en = '<specified in the set>'; fa = '<specified in the set>';
													|it = '<viene mostrato nella composizione del kit>';
													|pl = '<podaje się w składzie zestawu>';
													|tr = '<küme içeriğinde belirtilmektedir>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
	#Region SourceOfSemiFinishedProduct
	
	// The restriction of the availability of the flag Is performed
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndServicesProduce.Name);
	
	TypesList = New ValueList();
	TypesList.Add(Enums.ItemsTypes.ReusablePackage);
	TypesList.Add(Enums.ItemsTypes.OwnGoods);
	TypesList.Add(Enums.ItemsTypes.Work_5);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = TypesList;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Organizing the availability of the Specification field
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndServicesSourceOfSemiFinishedProduct.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.Produce");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndServicesSourceOfSemiFinishedProduct.Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.Produce");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.SourceOfSemiFinishedProduct");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chọn tự động>';
													|ru = '<подбирается автоматически>';
													|en = '<picked automatically>'; fa = '<picked automatically>';
													|it = '<viene selezionato automaticamente>';
													|pl = '<wybierane automatycznie>';
													|tr = '<otomatik olarak seçilir>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	#EndRegion
	
	#Region WithAssignment
	
	// Prohibition of editing a feature separately during production at the stage
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndServicesWithAssignment.Name);
	
	OrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.MethodOfReceivingMaterial");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage;
	
	AndGroup = OrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.WithAssignment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Design of the "Separate" attribute when dynamic scheduling is disabled
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndServicesWithAssignment.Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	MethodsOfObtainingMaterial = New ValueList;
	MethodsOfObtainingMaterial.Add(Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage);
	MethodsOfObtainingMaterial.Add(Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials);
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.MethodOfReceivingMaterial");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = MethodsOfObtainingMaterial;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseSemiFinishedProductsProducedAtStage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	#EndRegion
	
	// Availability of the "Specification" column of output products
	#Region ProcessByBOM
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsBillOfMaterials.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.ProcessByBOM");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Show", False);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RecyclableWasteBillOfMaterials.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.RecyclableWaste.ProcessByBOM");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Show", False);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
	ProductDataManagement.EstablishConditionalAppearanceOfSelectionByPropertiesAndCalculationByFormulas(
		ThisObject,
		"Object",
		"ManufacturedProduct",
		"NumberOfPackages");
	ProductDataManagement.EstablishConditionalAppearanceOfSelectionByPropertiesAndCalculationByFormulas(
		ThisObject,
		"Object",
		"ManufacturedProducts",
		"NumberOfPackages");
	ProductDataManagement.EstablishConditionalAppearanceOfSelectionByPropertiesAndCalculationByFormulas(
		ThisObject,
		"Object",
		"RecyclableWaste",
		"NumberOfPackages");
	ProductDataManagement.EstablishConditionalAppearanceOfSelectionByPropertiesAndCalculationByFormulas(
		ThisObject,
		"Object",
		"MaterialsAndServices",
		"NumberOfPackages");
	ProductDataManagement.EstablishConditionalAppearanceOfSelectionByPropertiesAndCalculationByFormulas(
		ThisObject,
		"Object",
		"LaborCosts",
		"Count");
	
	#Region IntermediateRelease
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject,
		"IntermediateReleaseCharacteristic",
		"Object.IntermediateRelease.ItemVariantsAreUsed");
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IntermediateReleaseProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IntermediateRelease.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MainProductProductsOfDifferentQualityPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("MainProductProductsOfDifferentQualityPresentation"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IntermediateReleaseProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IntermediateRelease.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MainProductProductsOfDifferentQualityPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseGoodsQuality");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Sản phẩm có chất lượng ""Dùng được hạn chế""';
													|ru = 'Продукция с качеством ""Ограниченно годен""';
													|en = 'Manufactured products with limited quality'; fa = 'محصولات تولیدی با کیفیت محدود';
													|it = 'Продукция с качеством ""Ограниченно годен""';
													|pl = 'Manufactured products with limited quality';
													|tr = '""Sınırlı geçerli"" kaliteye sahip imal edilen ürünler'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IntermediateReleaseCharacteristic.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IntermediateRelease.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IntermediateRelease.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MainProductProductsOfDifferentQualityPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MainProductCharacteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("MainProductCharacteristic"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IntermediateReleaseCharacteristic.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IntermediateRelease.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IntermediateRelease.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseGoodsQuality");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MainProductCharacteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MainProductItemVariantsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đặc tính bất kỳ>';
													|ru = '<любая характеристика>';
													|en = '<any variant>'; fa = '<any variant>';
													|it = '<qualsiasi caratteristica>';
													|pl = '<dowolna charakterystyka>';
													|tr = '<herhangi bir varyant>'"));
	
	#EndRegion
	
	SetConditionalDesignAccordingToProductionSubsystemVersion();
	
	EstablishConditionalAppearanceOfProductionProcess();
	
EndProcedure

&AtServer
Procedure SetParametersForSelectingResponsibleDepartment()
	
	ParametersOfResponsibleDepartment = New Array;
	ChoiceParameter = New ChoiceParameter("Filter.BusinessUnitIsProductionDispatcherOrProductionShopfloor", True);
	ParametersOfResponsibleDepartment.Add(ChoiceParameter);
	ParametersOfResponsibleDepartment = New FixedArray(ParametersOfResponsibleDepartment);
	Items.ResponsibleBusinessUnit.ChoiceParameters = ParametersOfResponsibleDepartment;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfTablePartsWithAutoSelection()
	ProductDataManagement.SetConditionalAppearanceForAutoSelectingProducts(ThisObject, "Object", "ManufacturedProduct");
	ProductDataManagement.SetConditionalAppearanceForAutoSelectingProducts(ThisObject, "Object", "ManufacturedProducts");
	ProductDataManagement.SetConditionalAppearanceForAutoSelectingProducts(ThisObject, "Object", "RecyclableWaste");
	ProductDataManagement.SetConditionalAppearanceForAutoSelectingProducts(ThisObject, "Object", "MaterialsAndServices");
	Return;
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject,
		"ManufacturedProductCharacteristic",
		"Object.ManufacturedProducts.ItemVariantsAreUsed");

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject,
		"ManufacturedProductsCharacteristic",
		"Object.ManufacturedProducts.ItemVariantsAreUsed");
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject,
		"RecyclableWasteCharacteristic",
		"Object.RecyclableWaste.ItemVariantsAreUsed");
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject,
		"MaterialsAndServicesCharacteristic",
		"Object.MaterialsAndServices.ItemVariantsAreUsed");
	
EndProcedure

&AtServer
Procedure SetConditionalDesignAccordingToProductionSubsystemVersion()
	
	// Design of the "Output products" table
	#Region ManufacturedProducts
	
	// In the new production management concept, the output of products 
	// at a calculated cost is possible only at the last stage
	
	Item = ConditionalAppearance.Items.Add();

	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ProductsAreElementOfProductionProcess.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductionIsUsed22");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("YouCanSpecifyStagesInFinishedProducts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	// Design of the "Materials and works" table
	#Region MaterialsAndServices
	
	// if production is on the side, then production in the process is not available
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndServicesMethodOfGettingTheMaterialEditing.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.ProductionByThirdParty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.ProducedInProcess");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductionIsUsed22");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	// editing of the security option is prohibited for kits and containers
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndServicesMethodOfGettingTheMaterialEditing.Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.MethodOfReceivingMaterial");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.MethodsOfReceivingBOMMaterials.Provide;
	
	OrGroup = AndGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	AndGroup = OrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.ItemsTypes.Set");
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.SourceOfSemiFinishedProduct");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	VariantList = New ValueList;
	VariantList.Add(Enums.SourcesOfCompositionOfSetsInProduction.DontUse);
	VariantList.Add(Enums.SourcesOfCompositionOfSetsInProduction.KitConfigurations);
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SourceOfCompositionOfSetsInProduction");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = VariantList;
	
	AndGroup = OrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.ItemsTypes.ReusablePackage");
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductionIsUsed22");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceOfShareOfCostOfOutputProductsField(TableName)
	
	Item = ConditionalAppearance.Items.Add();
	
	TableField = FieldSharesCostOfOutputProducts(ThisObject, TableName, "ProductCostIsUnavailable");
	Item.Fields.Items.Add().Field = New DataCompositionField(TableField.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProducts.ProductCostIsUnavailable");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có sẵn>';
													|ru = '<недоступна>';
													|en = '<unavailable>'; fa = '<unavailable>';
													|it = '<non disponibile>';
													|pl = '<unavailable>';
													|tr = '<mevcut değil>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	Item = ConditionalAppearance.Items.Add();
	
	TableField = FieldSharesCostOfOutputProducts(ThisObject, TableName, "ProductCostIsUnavailable");
	Item.Fields.Items.Add().Field = New DataCompositionField(TableField.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.MethodOfAllocatingFinishedProductCosts");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProducts.ProductCostIsUnavailable");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProducts.ThereAreErrorsOfFillingInCostShare");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProducts.CostSharePercentage");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = ConditionalAppearance.Items.Add();
	
	TableField = FieldSharesCostOfOutputProducts(ThisObject, TableName, "ThereAreErrorsOfFillingInCostShare");
	Item.Fields.Items.Add().Field = New DataCompositionField(TableField.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProducts.ThereAreErrorsOfFillingInCostShare");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProducts.ProductCostIsUnavailable");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

&AtClientAtServerNoContext
Function FieldSharesCostOfOutputProducts(Form, TableName, AttributeName)
	
	Result = Undefined; // FormField
	FormFields = New Structure;
	
	If TableName = "ManufacturedProduct" Then
		
		FormFields.Insert("ProductCostIsUnavailable",           Form.Items["ProductsShareOfCostIsNotAvailable"]);
		FormFields.Insert("ThereAreErrorsOfFillingInCostShare", Form.Items["ManufacturedProductThereAreErrorsOfFillingInCostShare"]);
		
		Result = FormFields[AttributeName];
		
	EndIf;
	
	If TableName = "ManufacturedProducts" Then
		
		FormFields.Insert("ProductCostIsUnavailable",           Form.Items["ManufacturedProductsProductCostIsUnavailable"]);
		FormFields.Insert("ThereAreErrorsOfFillingInCostShare", Form.Items["ManufacturedProductsThereAreErrorsOfFillingInCostShare"]);
		
		Result = FormFields[AttributeName];
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillInServiceDetails()
	
	SubsystemSettingsProduction = ProductionServerCached.SubsystemSettingsProduction();
	FillPropertyValues(ThisObject, SubsystemSettingsProduction);
	
	UseProductionPlanning = GetFunctionalOption("UseProductionPlanning");
	SourceOfCompositionOfSetsInProduction = ProductDataManagementCached.SourceOfCompositionOfSetsInProduction();
	If UseBillOfMaterialsParameterization Then
		
		ProductDataManagement.FillInServiceDetailsOfAutoSelectionAndCalculationOfNumber(
			Object.ManufacturedProducts,
			True,
			True,
			Object.SelectionByProperties);
		ProductDataManagement.FillInServiceDetailsOfAutoSelectionAndCalculationOfNumber(
			Object.RecyclableWaste,
			True,
			True,
			Object.SelectionByProperties);
		ProductDataManagement.FillInServiceDetailsOfAutoSelectionAndCalculationOfNumber(
			Object.MaterialsAndServices,
			True,
			True,
			Object.SelectionByProperties);
		ProductDataManagement.FillInServiceDetailsOfAutoSelectionAndCalculationOfNumber(
			Object.LaborCosts,
			False,
			True,
			Object.SelectionByProperties);
		
	EndIf;
	FillInServiceAttributesOutputProduct();
	
	StructureOfActions = StructureOfActionsForFillingInServiceDetails();
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.RecyclableWaste, StructureOfActions);
		
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.MaterialsAndServices, StructureOfActions);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.IntermediateRelease, StructureOfActions);
	ReleaseBatchDescriptionIsAvailable = ProductDataManagement.ReleaseBatchDescriptionIsAvailable();
	FillInReleaseBatchDescription();
	
	FillInServiceDetailsOfProductionProcess();
	FillInServiceDetailsOfMainFINISHEDProduct();
	FillInServiceAttributesOfFINISHEDProductBeingRepaired();
	FillInServiceDetailsMaterialsAndServices();
	
	FillInSpecificationStatusPresentation();
	
	CalculateAvailableIndicationOfStagesInOutputProducts();
	CalculateNumberOfOutputByProducts(ThisObject);
	
	UseSemiFinishedProductsProducedAtStage = ProductDataManagement.UseSemiFinishedProductsProducedAtStage(Object);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	EnterpriseManagement = False;
	EnterpriseManagement = True;
#Region UP_CA_21_22

	// Collapsible groups
	Items.GroupMainProductTitle.Visible = EnterpriseManagement;
	Items.GroupAssignmentParametersHeader.Visible = EnterpriseManagement;
	
	// The parameters of the production process
	LabelProductionProcessParameters = NStr("vi = 'Thông số quy trình';
											|ru = 'Параметры производственного процесса';
											|en = 'Production process parameters'; fa = 'پارامترهای فرایند تولید';
											|it = 'Parametri del processo industriale';
											|pl = 'Parametry procesu produkcyjnego';
											|tr = 'Üretim süreci parametreleri'");
	
	Items.ProductionIssueByCustomPortions.Visible = ReleaseBatchDescriptionIsAvailable;
	Items.MinimumReleaseLot.Visible = ReleaseBatchDescriptionIsAvailable;
	
	Items.EconomicReleaseLot.Visible = EnterpriseManagement And ProductionIsUsed22;
	Items.PermissibleExcessOfOptimalReleaseLot.Visible = EnterpriseManagement And ProductionIsUsed22;
	
	Items.ProductQueuePeriodIsLimited.Visible    = EnterpriseManagement And ProductionIsUsed22;
	Items.MaximumPeriodOfProductQueue.Visible = EnterpriseManagement And ProductionIsUsed22;
	
	// Responsible division
	Items.ResponsibleBusinessUnit.Visible = EnterpriseManagement And ProductionIsUsed22;
	
	// Replacement Permits
	Items.MaterialsAndServicesEnterSubstitutionPermission.Visible = EnterpriseManagement;
	
	// SetOfSeries
	Items.ManufacturedProductBatchIndicationRequired.Visible = EnterpriseManagement And ProductionIsUsed21;
	Items.MaterialsAndServicesBatchIndicationRequired.Visible = EnterpriseManagement And ProductionIsUsed21;
	
	// Selection of nomenclature, calculation by formulas
	Items.ProductsSetUpItemSelection.Visible                         = EnterpriseManagement;
	Items.ProductsSettingUpSelectionByPropertiesAndCalculationByFormulas.Visible        = EnterpriseManagement;
	Items.OutputItemsSetUpItemSelection.Visible                   = EnterpriseManagement;
	Items.OutputItemsSettingUpSelectionByPropertiesAndCalculationByFormulas_5.Visible  = EnterpriseManagement;
	Items.ReturnableWasteSetUpItemSelection.Visible                  = EnterpriseManagement;
	Items.RecyclableWasteConfigureFilterByPropertiesAndCalculationUsingFormulas.Visible = EnterpriseManagement;
	Items.MaterialsAndServicesSetUpItemSelection.Visible                  = EnterpriseManagement;
	Items.MaterialsAndServices_SettingUpFilterByPropertiesAndCalculationByFormulas.Visible = EnterpriseManagement;
	Items.LaborCostsSettingUpSelectionByPropertiesAndCalculationByFormulas.Visible      = EnterpriseManagement;
	
	SetAvailabilityOfElementsOfMethodOfObtainingMaterial();
	
	// Application of the material
	AvailableDescriptionOfProbabilityOfApplicationOfMaterials = ProductDataManagement.AvailableDescriptionOfProbabilityOfApplicationOfMaterials();
	Items.MaterialsAndServicesApplyingTheMaterialEditing.Visible = AvailableDescriptionOfProbabilityOfApplicationOfMaterials;
	Items.MaterialsAndServicesMaterialApplication.Visible               = Not AvailableDescriptionOfProbabilityOfApplicationOfMaterials;
	
	// Route map
	Items.PrintRouteMapGroup.Visible            = EnterpriseManagement And ProductionIsUsed21;
	Items.FormFillInUsingOperationsSheetsForStages.Visible = EnterpriseManagement And Not StoreOperationsInBillsOfMaterials;
	
	// Adding production process elements
	Items.ManufacturingProcessAdd.Visible               = Not EnterpriseManagement;
	Items.ProductionProcessContextAdd.Visible       = Not EnterpriseManagement;
	Items.ProductionProcessGroupAdd.Visible         = EnterpriseManagement;
	Items.ProductionProcessContextGroupAdd.Visible = EnterpriseManagement;
	
#EndRegion
	If Not AccessRight("Update", Metadata.Documents.EngineeringChangeOrder) Then
		Items.MaterialsAndServicesEnterSubstitutionPermission.Enabled = False;
	EndIf;
	
	If Not AccessRight("View", Metadata.CommonForms.ApplyProductsToManufacturing) Then
		Items.FormOpenProductBOR.Enabled = False;
		Items.ManufacturedProductOpenProductBOR.Enabled = False;
	EndIf; 
	
	ThereIsIntermediateRelease =
		Object.RecordMethodOfMaterialTransferBetweenStagesLots =
			Enums.RecordMethodsOfMaterialTransferBetweenStagesLots.NonconformingProducts
		Or Object.RecordMethodOfMaterialTransferBetweenStagesLots =
			Enums.RecordMethodsOfMaterialTransferBetweenStagesLots.SetUpManually;
	
	UpdateHeaderOfDestinationParameterGroup(ThisObject);
	SetAvailabilityOfItemsByTypeOfProductionProcessServer();
	SetAvailabilityOfProductEditingElements();
	SetAvailabilityOfItemsByStatusServer();
	SetAvailabilityOfStatusChangeCommands();
	
	CustomizeProductionProcessElements();
	
	UpdateInformationOnMainProductSpecification();
	CustomizeElementsOfFinishedProductBeingRepaired();
	ProductDataManagementClientServer.SetMaterialSelectionParameters(
		Items.MaterialsAndServicesProducts, ThisObject);
	
	SetKeyToSaveWindowPosition();
	
	Items.AdvancedGroup.Picture = CommonClientServer.CommentPicture(Object.LongDesc);
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	ReleaseBatchDescription = Form.ReleaseBatchDescription;
	
	ThisIsTechnologicalSet     = ThisIsTechnologicalSet(Form);
	ThisIsPerformanceOfRepairWork = ThisIsPerformanceOfRepairWork(Form);
	ThisIsDisassembly = Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly");
	
	If AttributesStructure1.Property("MainProduct")
		Or Initialize Then
		
		Items.GroupFinishedSideProducts.Visible = Not ThisIsTechnologicalSet;
		Items.LaborCostsGroup.Visible            = Not ThisIsTechnologicalSet;
		Items.GroupManufacturingProcess.Visible = Not ThisIsTechnologicalSet;
		
		Items.MethodOfAllocatingFinishedProductCosts.Visible =        Not ThisIsTechnologicalSet
			And (Form.ProductionIsUsed22 And Not Form.ProductionIsUsed21);
			
		Items.GroupRepairedFinishedProduct.Visible          = ThisIsPerformanceOfRepairWork;
		Items.ItemKindOfProductUnderRM.Visible = Form.RepairedFinishedProductDestinationOption = RepairedFinishedProductDestinationOptionTypeOfItem();
		Items.UnderRepairProduct.Visible    = Form.RepairedFinishedProductDestinationOption = RepairedFinishedProductDestinationOptionItem();
		Items.UnderRepairVariant.Visible  = Form.RepairedFinishedProductDestinationOption = RepairedFinishedProductDestinationOptionItem();
		ConfigureSpecificationAssignmentOptions(Form);
		
	EndIf;
	
	If AttributesStructure1.Property("MainProduct")
		Or AttributesStructure1.Property("AssignmentOption")
		Or Initialize Then
		
		VisibilityIntermediateRelease = IntermediateReleaseIsAvailable(Form);
		
		Items.ThereIsIntermediateRelease.Visible = VisibilityIntermediateRelease;
		Items.WayToReflectMaterialTransferBetweenStagesOfNonconformingProduct.Visible = VisibilityIntermediateRelease;
		Items.MethodOfReflectingMaterialTransferBetweenStagesIsSetUpManually.Visible = VisibilityIntermediateRelease;
		
	EndIf;
	
	// Setting up a mold for a multi-stage production process
	If AttributesStructure1.Property("ManufacturingProcess")
		Or Initialize Then
		
		Items.LongRunningOperationInformationStatus.Visible = Not Form.ProductionProcessRead;
		Items.DescriptionManufacturingProcess.CurrentPage = ?(
			Form.ProductionProcessRead,
			Items.ProductionProcessEditorPage,
			Items.PageEditorOfTheProductionProcessDownload);
		
		AttributeAvailability = Form.AttributeAvailability;
		ThereAreStages = (Form.ProductionProcessCache.StageCount > 0);
		
		Items.ProductionProcessPropertiesPanel.Enabled   = ThereAreStages;
		Items.ProductionProcessCollapse.Enabled         = ThereAreStages;
		Items.TheProductionProcessToDeploy.Enabled       = ThereAreStages;
		Items.ProductionProcessIsToMoveUp.Enabled = ThereAreStages And AttributeAvailability;
		Items.ProductionProcessMoveDown.Enabled  = ThereAreStages And AttributeAvailability;
		
		If Not ThereAreStages Then
			Items.ProductionProcessPageProperties.CurrentPage = Items.ProductionProcessEmpty;
		EndIf;
		
		Items.StatusChangeCommands.Enabled = Form.ProductionProcessRead;
		
		SelectionOfProductionProcessElementIsAvailable = Not ThisIsTechnologicalSet
			And ProductDataManagementClientServer.MultiStageProductionProcessIsAvailable();
		For Each KeyAndValue In NamesOfEditingElements() Do
			Items[KeyAndValue.Value].Visible = SelectionOfProductionProcessElementIsAvailable;
		EndDo;
		For Each KeyAndValue In NamesOfCommandsForSelectingElementOfProductionProcess() Do
			Items[KeyAndValue.Value].Visible = SelectionOfProductionProcessElementIsAvailable;
		EndDo;
		Items.ProductionProcessFillInDivision.Visible = SelectionOfProductionProcessElementIsAvailable;
		
		ProductionProcessParametersAreAvailable = Not (ThisIsTechnologicalSet Or ThisIsPerformanceOfRepairWork Or ThisIsDisassembly);
		Items.GroupProductionProcessParametersHeader.Visible = ProductionProcessParametersAreAvailable;
		Items.ProductionProcessParametersGroup.Visible          = ProductionProcessParametersAreAvailable;
		
	EndIf;
	
	// Setting up a selection list of options for describing resource specifications
	If AttributesStructure1.Property("ReleaseBatchDescription")
		Or Initialize Then
		
		ChoiceList = Items.ProductionIssueByCustomPortions.ChoiceList;
		ChoiceList.Clear();
		ChoiceList.Add(True).Presentation = NStr("vi = 'với số lượng tùy ý';
												|ru = 'в произвольном количестве';
												|en = 'Any quantity'; fa = 'Any quantity';
												|it = 'in quantità desiderata';
												|pl = 'w dowolnej ilości';
												|tr = 'serbest miktarda'");
		If ReleaseBatchDescription <> Undefined
			And ReleaseBatchDescription.NumberOfPackages > 0
			And Not ReleaseBatchDescription.MultipleIssue
			And Not ReleaseBatchDescription.UnitOfProductMeasurement.IsEmpty()
			Then
			CountPresentation = Format(ReleaseBatchDescription.NumberOfPackages, "NZ=; NG=");
			ChoiceList.Add(False).Presentation = StrTemplate(NStr("vi = 'nhiều %1 %2';
																	|ru = 'кратно %1 %2';
																	|en = 'Multiple of %1 %2'; fa = 'Multiple of %1 %2';
																	|it = 'in breve %1 %2';
																	|pl = 'krotne %1 %2';
																	|tr = '%1 %2 katları halinde'"), CountPresentation, ReleaseBatchDescription.UnitOfProductMeasurement);
		Else
			ChoiceList.Add(False).Presentation = NStr("vi = 'trong nhiều lô';
														|ru = 'кратными партиями';
														|en = 'Multiple lots'; fa = 'Multiple lots';
														|it = 'con i lotti multipli';
														|pl = 'krotnymi partiami';
														|tr = 'çoklu lotlar'");
		EndIf;
		
	EndIf;
	
	// The issue of arbitrary portions
	If AttributesStructure1.Property("ProductionIssueByCustomPortions")
		Or Initialize Then
		
		ProductDataManagementClientServer.SetParametersForEnteringNumberOfBatchUnits(
			Object.ProductionIssueByCustomPortions,
			Items.MinimumReleaseLot);
		
		ProductDataManagementClientServer.SetParametersForEnteringNumberOfBatchUnits(
			Object.ProductionIssueByCustomPortions,
			Items.EconomicReleaseLot);
			
		ProductDataManagementClientServer.SetParametersForEnteringNumberOfBatchUnits(
			Object.ProductionIssueByCustomPortions,
			Items.PermissibleExcessOfOptimalReleaseLot);
		
		Form.ReleaseInCustomPortionsBeforeChange = Object.ProductionIssueByCustomPortions;
		
	EndIf;
	
	// The minimum party of the issue
	If AttributesStructure1.Property("MinimumReleaseLot")
		Or AttributesStructure1.Property("ReleaseBatchDescription")
		Or Initialize Then
		
		InputHint = ProductDataManagementClientServer.PresentationOfUnitOfMeasurementOfBatchOfRelease(
			Form.ReleaseBatchDescription,
			Object.MinimumReleaseLot);
		Items.MinimumReleaseLot.ToolTip = InputHint;
		
	EndIf;
	
	// Optimal release batch
	If AttributesStructure1.Property("EconomicReleaseLot")
		Or AttributesStructure1.Property("ReleaseBatchDescription")
		Or Initialize Then
		
		InputHint = ProductDataManagementClientServer.PresentationOfUnitOfMeasurementOfBatchOfRelease(
			Form.ReleaseBatchDescription, 
			Object.EconomicReleaseLot);
		Items.EconomicReleaseLot.ToolTip = InputHint;
		Items.PermissibleExcessOfOptimalReleaseLot.ToolTip = InputHint;
		
	EndIf;
	
	// Maximum shelf life of output products
	If AttributesStructure1.Property("SettingMaximumPeriodOfBedRest")
		Or Initialize Then
		
		Items.MaximumPeriodOfProductQueue.Visible = Object.ProductQueuePeriodIsLimited;
		
	EndIf;
	
	// Intermediate release
	If AttributesStructure1.Property("RecordMethodOfMaterialTransferBetweenStagesLots")
		Or Initialize Then
		
		IntermediateReleaseIsUsed = 
			Object.RecordMethodOfMaterialTransferBetweenStagesLots = PredefinedValue(
				"Enum.RecordMethodsOfMaterialTransferBetweenStagesLots.NonconformingProducts")
			Or Object.RecordMethodOfMaterialTransferBetweenStagesLots = PredefinedValue(
				"Enum.RecordMethodsOfMaterialTransferBetweenStagesLots.SetUpManually");
		
		Items.WayToReflectMaterialTransferBetweenStagesOfNonconformingProduct.Enabled = Form.AttributeAvailability
			And IntermediateReleaseIsUsed
			And Form.UseGoodsQuality;
		
		Items.MethodOfReflectingMaterialTransferBetweenStagesIsSetUpManually.Enabled = Form.AttributeAvailability
			And IntermediateReleaseIsUsed;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function IntermediateReleaseIsAvailable(Form)
	
	Object = Form.Object;
	
	IsItTaraOrWork = False;
	If Object.AssignmentOption <> PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.ItemList") Then
		IsItTaraOrWork = Form.MainProductItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")
			Or Form.MainProductItemsType = PredefinedValue("Enum.ItemsTypes.Work_5");
	ElsIf Object.ManufacturedProducts.Count() > 0 Then
		IsItTaraOrWork = Object.ManufacturedProducts[0].ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")
			Or Object.ManufacturedProducts[0].ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5");
	EndIf;
	
	IntermediateReleaseIsAvailable = Form.DynamicStructureOfProductionOrders
		And Not Form.UseSemiFinishedProductsProducedAtStage
		And Not IsItTaraOrWork;
	
	Return IntermediateReleaseIsAvailable;
	
EndFunction

// Notification when the validity period changes
// 
// Parameters:
// 	Period - StandardPeriod - new period
// 	Context - Structure - other notification parameters
&AtClient
Procedure SetValidityPeriodCompletion(Period, Context = Undefined) Export
	
	If TypeOf(Period) <> Type("StandardPeriod") Then
		Return;
	EndIf;
	Object.ValidOnDate = Period.StartDate;
	Object.ValidToDate = Period.EndDate;
	
	Modified = True;
	FillInSpecificationStatusPresentation();
	
EndProcedure

&AtServer
Procedure WhenChangingMethodOfDistributionOfCostsForOutputProducts()
	
	CostAllocationParametersStructure = Catalogs.BillsOfMaterials.CostAllocationParameters(Object);
	CostAllocationParameters = New FixedStructure(CostAllocationParametersStructure);
	
	ProductionServer.CalculateFractionOfCost(Object, CostAllocationParameters);
	CalculatePercentageOfCostAllocationForOutputProducts();
	
EndProcedure

&AtServer
Function AvailableProductionInProcessForRecycling()
	
	Return ProductionIsUsed22;
		
EndFunction

&AtServer
Function PercentageOfDefectiveGoodsColumnIsAvailable()
	
	Result = False;
	
	For Each String In Object.ManufacturedProducts Do
		If String.ShareOfNonconformity <> 0 Then
			Result = Not ProductionIsUsed21 And Not DynamicStructureOfProductionOrders;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure DetailsOfReleaseBatchDescriptionWhenChanging()
	
	FillInReleaseBatchDescription();
	ConfigureDependentFormElements(ThisObject, "ReleaseBatchDescription,ProductionIssueByCustomPortions");
	
EndProcedure

&AtServer
Procedure FillInReleaseBatchDescription()
	
	If Not ReleaseBatchDescriptionIsAvailable Then
		Return;
	EndIf;
	ReleaseBatchDescription = Catalogs.BillsOfMaterials.ReleaseBatchDescription(Object);
	
EndProcedure

&AtServer
Procedure FillInSpecificationStatusPresentation()
	
	If Object.Status <> Enums.BOMStatuses.Valid Then
		StatusLines = String(Object.Status);
	EndIf;
	
	StatusLines = ProductDataManagementClientServer.SpecificationStatusPresentation(Object.Status);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfProductionProcess()
	
	StageTheBasicUnitOfBufferTime = Catalogs.ProductionStages.BasicBufferTimeUnit();
	StageTheBasicUnitOfTimeForTheDurationOfAUBBWStage = Catalogs.ProductionStages.TheBasicUnitOfTimeForTheDurationOfTheUBBWStage();
	If ValueIsFilled(Object.Ref)
		And StoreOperationsInBillsOfMaterials
		And Not ProductionProcessRead Then
	
		QueryText = "
		|SELECT TOP 1
		|	TRUE
		|FROM
		|	Catalog.ManufacturingOperations AS T
		|WHERE
		|	NOT T.DeletionMark
		|	AND T.BillOfMaterials = &BillOfMaterials
		|GROUP BY
		|	T.Owner
		|
		|HAVING
		|	COUNT(DISTINCT T.Ref) > 1
		|";
		Query = New Query(QueryText);
		Query.SetParameter("BillOfMaterials", Object.Ref);
		
		ProductionProcessCache.ThereIsMultioperativeStage = Not Query.Execute().IsEmpty();
	
	EndIf;
	
	For Each String In Object.IntermediateRelease Do
		String.StageEditing = String.RecipientStage;
	EndDo;
	FillInPresentationDetailsStageOperation();
	
	FillInDataOfFirstAndLastStage();
	FillInServiceDetailsOfWorkPerformed();
EndProcedure

&AtServer
Function DescriptionManufacturingProcess()
		
	NumberOfFirstStages = 0;
	NumberOfLastStages = 0;
	
	RowsStages = ManufacturingProcess.GetItems();
	For Each StageString In RowsStages Do
		If StageString.Number = 1 Then
			NumberOfFirstStages = NumberOfFirstStages + 1;
		EndIf;
		If StageString.TheNumberOfTheNextOne =  0 Then
			NumberOfLastStages = NumberOfLastStages + 1;
		EndIf;
	EndDo;
	
	Return New Structure("SeveralFirstSteps,SeveralLastSteps", NumberOfFirstStages > 1, NumberOfLastStages > 1);
	
EndFunction

// Data structure Constructor of the first/last stage of the specification
// 
// Returns:
// 	Structure - Stage data:
//		* Ref  - CatalogRef.ProductionStages - link to the stage
//		* Description - String - the name of the stage
//		* Department - CatalogRef.BusinessStructure - stage division
//		* ProductionByThirdParty - Boolean - sign of production on the side
//
&AtClientAtServerNoContext
Function StageDataConstructor()
	
	Result = New Structure;
	
	Result.Insert("ThisIsTheFirstStep",         False);
	Result.Insert("Ref",                PredefinedValue("Catalog.ProductionStages.EmptyRef"));
	Result.Insert("Description",          "");
	Result.Insert("Department",         PredefinedValue("Catalog.BusinessStructure.EmptyRef"));
	Result.Insert("ProductionByThirdParty", False);
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillInDataOfFirstAndLastStage()
	
	FirstStageData    = StageDataConstructor();
	LastStageData = StageDataConstructor();
	
	If ProductionProcessRead Then
	
		Stages = ManufacturingProcess.GetItems();
		
		For IndexOf = 0 To Stages.Count() - 1 Do
			If Stages[IndexOf].Number = 1 Then
				FillPropertyValues(FirstStageData, Stages[IndexOf]);
				Break;
			EndIf;
		EndDo;
			
		For IndexOf = -Stages.Count() + 1 To 0 Do
			If Stages[-IndexOf].TheNumberOfTheNextOne = 0 Then
				FillPropertyValues(LastStageData, Stages[-IndexOf]);
				Break;
			EndIf;
		EndDo;
		
	Else
		
		Catalogs.BillsOfMaterials.GetFirstAndLastStage(
			Object.Ref,
			FirstStageData,
			LastStageData,
			"Description,Department,ProductionByThirdParty");
	EndIf;
	
	FirstStageData.ThisIsTheFirstStep = True;
	
EndProcedure

&AtServer
Procedure FillInPresentationDetailsStageOperation()
	
	NamesOfTS = New Map();
	NamesOfTS.Insert("ManufacturedProducts",  False);
	NamesOfTS.Insert("RecyclableWaste", False);
	NamesOfTS.Insert("MaterialsAndServices", False);
	NamesOfTS.Insert("LaborCosts",     False);
	NamesOfTS.Insert("IntermediateRelease", False);
	ReferencesArrray = New Array; // Array of CatalogRef.ProductionStages
	
	For Each KeyAndValue In NamesOfTS Do
		
		TSName = KeyAndValue.Key;
		
		For Each String In Object[TSName] Do
			
			If ValueIsFilled(String.StageEditing) Then
				ReferencesArrray.Add(String.StageEditing);
				NamesOfTS[TSName] = True;
			Else
				String.StageEditingPresentation = "";
			EndIf;
			If ValueIsFilled(String.OperationEdit) Then
				ReferencesArrray.Add(String.OperationEdit);
				NamesOfTS[TSName] = True;
			Else
				String.OperationEditPresentation = "";
			EndIf;
		EndDo;
		
	EndDo;
	
	TMCommonUse.DeleteDuplicateElementsFromArray(ReferencesArrray);
	
	If ProductionProcessRead Then
		
		Presentations    = New Map;
		RefsCount = ReferencesArrray.Count();
		
		RowData = Undefined;
		While ProductionProcessIsFollowingElement(ThisObject, RowData) And (Presentations.Count() < RefsCount) Do
			If (RowData.ItemKind = TypeOfStageElement()
					Or RowData.ItemKind = TypeOfElementOfOperation()
					)
				And ReferencesArrray.Find(RowData.Ref) <> Undefined Then
				Presentations.Insert(RowData.Ref, RowData.Description);
			EndIf;
		EndDo;
		
	Else
	
		Presentations = Common.ObjectsAttributeValue(ReferencesArrray, "Description");
		
	EndIf;
	
	For Each KeyAndValue In NamesOfTS Do
		
		If Not KeyAndValue.Value Then
			Continue;
		EndIf;
		
		TSName = KeyAndValue.Key;
		
		For Each String In Object[TSName] Do
			
			If ValueIsFilled(String.StageEditing) Then
				String.StageEditingPresentation = Presentations.Get(String.StageEditing);
			EndIf;
			If ValueIsFilled(String.OperationEdit) Then
				String.OperationEditPresentation = Presentations.Get(String.OperationEdit);
			EndIf;
			String.ElementOfProductionProcessPresentation = RepresentationOfProductionProcessElement(ThisObject, String);
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ProcessManufacturingProcessChange(CurrentRow)
	
	CurrentData = ManufacturingProcess.FindByID(CurrentRow);
	
	If CurrentData = Undefined
			Or CurrentData.ItemKind <> TypeOfStageElement() Then
		Return;
	EndIf;
	
	FirstStage    = FirstStageData; // See StageDataConstructor
	LastStage = LastStageData; // See StageDataConstructor
	
	UpdateFirstStage = CurrentData.Number = 1
		Or CurrentData.Ref = FirstStage.Ref
		Or Not ValueIsFilled(FirstStage.Ref);
		
	UpdateLastStage = CurrentData.TheNumberOfTheNextOne = 0
		Or CurrentData.Ref = LastStage.Ref
		Or Not ValueIsFilled(LastStage.Ref);
	
	If UpdateFirstStage Or UpdateLastStage Then
		FillInDataOfFirstAndLastStage();
	EndIf;
	
	UpgradePropsMultiStageProductionProcess();
	
	IDs = New Array();
	
	FiltersList = New Array;
	FiltersList.Add(CurrentData.Ref);
	If UpdateFirstStage Then
		FiltersList.Add(Catalogs.ProductionStages.EmptyRef());
	EndIf;
	For Each FilterValue In FiltersList Do
		
		Filter = New Structure("StageEditing", FilterValue);
		FoundRows = Object.MaterialsAndServices.FindRows(Filter);
		
		For Each String In FoundRows Do
			IDs.Add(String.GetID());
		EndDo;
		
	EndDo;
	
	If IDs.Count() > 0 Then
		ProcessStageChangeMaterialsAndServices(IDs);
	EndIf;
	If CurrentData.TheNumberOfTheNextOne = 0
		And Object.IntermediateRelease.Count() > 0 Then
		Filter = New Structure("StageSender", CurrentData.Ref);
		For Each String In Object.IntermediateRelease.FindRows(Filter) Do
			Object.IntermediateRelease.Delete(String);
		EndDo;
		IntermediateReleaseNumberOfLines = 0;
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Function ListOfColumnsFillInServiceDetailsMaterialsAndServices()
	
	FieldsComposition = "LineNumber,StageEditing,MethodOfReceivingMaterial,SourceOfSemiFinishedProduct,BillOfMaterialsRM,PlanNotEarlierThan";
	Return FieldsComposition;
	
EndFunction

&AtClientAtServerNoContext
Function TabularSectionNames()
	
	Result = New Array;
	Result.Add("ManufacturedProducts");
	Result.Add("RecyclableWaste");
	Result.Add("MaterialsAndServices");
	Result.Add("LaborCosts");
	Result.Add("IntermediateRelease");
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function MatchingFormTablesToTSNames()
	
	Result = New Structure;
	
	Result.Insert("ManufacturedProduct",        "ManufacturedProducts");
	Result.Insert("ManufacturedProducts",  "ManufacturedProducts");
	Result.Insert("RecyclableWaste", "RecyclableWaste");
	Result.Insert("MaterialsAndServices", "MaterialsAndServices");
	Result.Insert("LaborCosts",     "LaborCosts");
	Result.Insert("IntermediateRelease", "IntermediateRelease");
	Return Result;
	
EndFunction

&AtServer
Procedure FillInServiceDetailsMaterialsAndServices(IDs = Undefined)
	
	ColumnsList = ListOfColumnsFillInServiceDetailsMaterialsAndServices();
	
	If IDs <> Undefined Then
		StringsList = New Array;
		For Each Id In IDs Do
			StringsList.Add(Object.MaterialsAndServices.FindByID(Id));
		EndDo;
		TabularSection = Object.MaterialsAndServices.Unload(StringsList, ColumnsList);
	Else
		TabularSection = Object.MaterialsAndServices.Unload(, ColumnsList);
	EndIf;
	
	Query = New Query;
	Query.SetParameter("TabularSection",        TabularSection);
	Query.SetParameter("ProductionByThirdParty", FirstStageData.ProductionByThirdParty);
	
	QueryText = StrReplace("
	|SELECT
	|	&ColumnsList
	|INTO TT
	|FROM
	|	&TabularSection AS TabularSection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|", "&ColumnsList", ColumnsList);
	
	If ProductionProcessRead Then
		
		QueryText = QueryText + "
		|SELECT
		|	StepsTable.Ref                AS Ref,
		|	StepsTable.ProductionByThirdParty AS ProductionByThirdParty,
		|	StepsTable.Number                 AS StageNumber,
		|	StepsTable.Description          AS Presentation
		|INTO StepsTable
		|FROM
		|	&StepsTable AS StepsTable
		|
		|INDEX BY
		|	Ref
		|
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	TabularSection.LineNumber                          AS LineNumber,
		|
		|	CASE
		|		WHEN TabularSection.StageEditing = VALUE(Catalog.ProductionStages.EmptyRef)
		|			THEN TRUE
		|		ELSE TableStageEdit.StageNumber = 1
		|	END                                               AS ThisIsTheFirstStep,
		|
		|	CASE
		|		WHEN TabularSection.StageEditing = VALUE(Catalog.ProductionStages.EmptyRef)
		|			THEN &ProductionByThirdParty
		|		ELSE TableStageEdit.ProductionByThirdParty
		|	END                                               AS ProductionByThirdParty,
		|
		|	CASE
		|		WHEN TabularSection.MethodOfReceivingMaterial = VALUE(Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage)
		|			THEN CAST(TableSourceOfSemiFinishedProduct.Presentation AS STRING(100))
		|		ELSE
		|			CAST(TabularSection.SourceOfSemiFinishedProduct AS Catalog.BillsOfMaterials).Description
		|	END                                               AS SourceOfSemiFinishedProductPresentation,
		|	TableIsNotEarlier.Presentation             AS PlanNotEarlierThanPresentation,
		|	PRESENTATION(TabularSection.BillOfMaterialsRM)   AS BillOfMaterialsRMPresentation
		|
		|FROM
		|	TT AS TabularSection
		|
		|	LEFT JOIN StepsTable AS TableStageEdit
		|	ON TabularSection.StageEditing = TableStageEdit.Ref
		|
		|	LEFT JOIN StepsTable AS TableSourceOfSemiFinishedProduct
		|	ON TabularSection.SourceOfSemiFinishedProduct = TableSourceOfSemiFinishedProduct.Ref
		|
		|	LEFT JOIN StepsTable AS TableIsNotEarlier
		|	ON TabularSection.PlanNotEarlierThan = TableIsNotEarlier.Ref
		|
		|";
		
		Query.SetParameter("StepsTable", TableOfProductionProcessElements(New Structure("ItemKind", TypeOfStageElement())));
		
	Else
		
		QueryText = QueryText + "
		|SELECT
		|	TabularSection.LineNumber AS LineNumber,
		|
		|	CASE
		|		WHEN TabularSection.StageEditing = VALUE(Catalog.ProductionStages.EmptyRef)
		|			THEN TRUE
		|		ELSE CAST(TabularSection.StageEditing AS Catalog.ProductionStages).StageNumber = 1
		|
		|	END AS ThisIsTheFirstStep,
		|	CASE
		|		WHEN TabularSection.StageEditing = VALUE(Catalog.ProductionStages.EmptyRef)
		|			THEN &ProductionByThirdParty
		|		ELSE CAST(TabularSection.StageEditing AS Catalog.ProductionStages).ProductionByThirdParty
		|
		|	END AS ProductionByThirdParty,
		|
		|	PRESENTATION(TabularSection.SourceOfSemiFinishedProduct) AS SourceOfSemiFinishedProductPresentation,
		|	PRESENTATION(TabularSection.PlanNotEarlierThan)             AS PlanNotEarlierThanPresentation,
		|	PRESENTATION(TabularSection.BillOfMaterialsRM)            AS BillOfMaterialsRMPresentation
		|
		|FROM
		|	TT AS TabularSection
		|";
	
	EndIf;
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RowData = Object.MaterialsAndServices[Selection.LineNumber - 1];
		FillPropertyValues(RowData, Selection,, "LineNumber");
		FillInPresentationOfMaterialReceiptMethod(RowData, ThisObject);
		ProductDataManagementClientServer.FillInInformationOnUseOfMaterial(RowData);
		FillInProduceAttributeInMaterialsLine(ThisObject, RowData);
	EndDo;

EndProcedure

&AtClient
Procedure FillInServiceDetailsInMaterialsAndServicesLine(String)
	
	IDs = New Array;
	IDs.Add(String.GetID());
	FillInServiceDetailsMaterialsAndServices(IDs);

EndProcedure

&AtServer
Procedure FillInServiceAttributesOutputProduct()
	
	StructureOfActions = StructureOfActionsForFillingInServiceDetails();
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProducts, StructureOfActions, Undefined);
	
	ProductionServer.CalculateFractionOfCost(Object, CostAllocationParameters);
	
	CalculatePercentageOfCostAllocationForOutputProducts();

EndProcedure

&AtServer
Function StructureOfActionsForFillingInServiceDetails()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInSeriesAttribute", New Structure("Products", "SeriesAreUsed"));
	
	Return StructureOfActions;
	
EndFunction

&AtServer
Procedure CalculateAvailableIndicationOfStagesInOutputProducts()
	
	YouCanSpecifyStagesInFinishedProducts = False;
	
	For Each String In Object.ManufacturedProducts Do
		
		If ValueIsFilled(String.StageEditing) Then
			
			YouCanSpecifyStagesInFinishedProducts = True;
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateNumberOfOutputByProducts(Form)
	
	Object = Form.Object;
	
	If Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly") Then
		TotalProductNumber = Object.ManufacturedProducts.Count() + Object.RecyclableWaste.Count();
	Else
		TotalProductNumber = Object.RecyclableWaste.Count();
	EndIf;
	
	Form.TotalOutputByProducts = TotalProductNumber;
	
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
Function GetObjectAttributesToLock()
	
	Result = New Array;
	
	// Header Elements
	Result.Add("Code");
	
	Result.Add("ProductionIssueByCustomPortions");
	Result.Add("AssignmentOption");
	Result.Add("MethodOfAllocatingFinishedProductCosts");
	
	// Main product
	Result.Add("MainProductProductKind");
	Result.Add("MainProductProducts");
	Result.Add("MainProductCharacteristic");
	Result.Add("MainProductNumberOfPackages");
	Result.Add("MainProductPackage");
	Result.Add("MainProductShareOfNonconformity");
	
	// Elements of table parts
	Result.Add("ManufacturedProduct");
	Result.Add("ManufacturedProducts");
	Result.Add("RecyclableWaste");
	Result.Add("MaterialsAndServices");
	Result.Add("LaborCosts");
	Result.Add("IntermediateRelease");
	Result.Add("WorksToPerform");
	
	// The Finished Product being Repaired
	Result.Add("RepairedFinishedProductDestinationOption");
	Result.Add("ItemKindOfProductUnderRM");
	Result.Add("UnderRepairProduct");
	Result.Add("UnderRepairVariant");
	// Commands
	Result.Add("FormFillInUsingOperationsSheetsForStages");
	Result.Add("MaterialsAndServicesSplitRow");
	Result.Add("MaterialsAndServicesOpenMaterialSelection");
	Result.Add("MaterialsAndServicesFillOutTheCalculationArticle");
	Result.Add("DownloadMaterialsAndServicesFromFile");
	Result.Add("ReturnableWasteFillOutTheCalculationArticle");
	Result.Add("ReturnableWasteLoadFromFile");
	Result.Add("LaborCostsFillInTheCalculationArticle");
	Result.Add("LaborCostsUploadFromFile");
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetAvailabilityOfItemsByTypeOfProductionProcessServer()
	
	ThisIsBuild   = True;
	ThisIsRepair   = False;
	ThisIsDisassembly = False;
	ThisIsPerformanceOfRepairWork = False;
	ThisIsBuild   = (Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly"));
	ThisIsRepair   = (Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM")
					Or Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Repair"));
	ThisIsDisassembly = (Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly"));
	ThisIsPerformanceOfRepairWork = (Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM"));
	AttributeAvailability = (Object.Status = PredefinedValue("Enum.BOMStatuses.UnderDevelopment"));
	
	// Headers
	If ThisIsBuild Then
		TextMainProduct = NStr("vi = 'Sản phẩm';
								|ru = 'Продукция';
								|en = 'Manufactured products'; fa = 'محصولات تولیدی';
								|it = 'Prodotti';
								|pl = 'Wiersze pozycji';
								|tr = 'İmal edilen ürünler'");
	ElsIf ThisIsRepair Then
		TextMainProduct = NStr("vi = 'Sửa chữa';
								|ru = 'Ремонт';
								|en = 'R&M'; fa = 'تعمیر و نگهداری';
								|it = 'R&M';
								|pl = 'R&M';
								|tr = 'Bakım-onarım'");
	ElsIf ThisIsDisassembly Then
		TextMainProduct = NStr("vi = 'Sản phẩm tháo rời';
								|ru = 'Разбираемое изделие';
								|en = 'Product being disassembled'; fa = 'Product being disassembled';
								|it = 'Prodotto in fase di smontaggio';
								|pl = 'Demontowany wyrób';
								|tr = 'Sökülen nihai ürün'");
	EndIf;
	Items.GroupFinishedProducts.Visible = ThisIsDisassembly;
	Items.GroupFinishedProducts.ShowTitle = ThisIsDisassembly;
	
	If ThisIsPerformanceOfRepairWork
		Or ThisIsBuild And UseSemiFinishedProductsProducedAtStage
		Or ThisIsRepair And UseSemiFinishedProductsProducedAtStage Then
		Items.GroupFinishedSideProducts.Title = NStr("vi = 'Sản phẩm phụ và xuất xưởng trung gian';
													|ru = 'Побочный и промежуточный выход';
													|en = 'Side and intermediate products'; fa = 'محصولات فرعی و میانی';
													|it = 'Output secondario e intermedio';
													|pl = 'Produkcja uboczna i pośrednia';
													|tr = 'Yan ve ara ürün çıkışı'");
	ElsIf ThisIsBuild Or ThisIsRepair Then
		Items.GroupFinishedSideProducts.Title = NStr("vi = 'Xuất xưởng sản phẩm phụ';
													|ru = 'Побочный выход';
													|en = 'By-product'; fa = 'محصول فرعی';
													|it = 'Produzione collaterale';
													|pl = 'Produkcja poboczna';
													|tr = 'Yan ürün çıkışı'");
	Else
		Items.GroupFinishedSideProducts.Title = NStr("vi = 'Sản phẩm đầu ra';
													|ru = 'Выходные изделия';
													|en = 'Finished products'; fa = 'Finished products';
													|it = 'Prodotti finiti';
													|pl = 'Wyroby gotowe';
													|tr = 'Üretilen nihai ürünler'");
	EndIf;
	
	Items.ReturnableWasteGroup.Visible = ThisIsBuild Or ThisIsDisassembly Or ThisIsRepair;
	Items.ReturnableWasteGroup.ShowTitle = ThisIsDisassembly;
	If UseSemiFinishedProductsProducedAtStage Then
		Items.ReturnableWasteGroup.Title = NStr("vi = 'Sản phẩm phụ và xuất xưởng trung gian theo giá trị cố định';
												|ru = 'Побочный и промежуточный выход по фиксированной стоимости';
												|en = 'Side and intermediate product at fixed cost'; fa = 'محصول فرعی و میانی با بهای ثابت';
												|it = 'Uscita collaterale e intermedia ad un costo fisso';
												|pl = 'Produkcja poboczna i pośrednia po stałej cenie';
												|tr = 'Sabit maliyetle yan ve ara ürün çıkışı'");
	Else
		Items.ReturnableWasteGroup.Title = NStr("vi = 'Xuất xưởng sản phẩm phụ theo giá trị cố định';
												|ru = 'Побочный выход по фиксированной стоимости';
												|en = 'By-products at fixed cost'; fa = 'محصولات فرعی به بهای ثابت';
												|it = 'Sottoprodotti a costo fisso';
												|pl = 'Wyjście uboczne według stałej ceny';
												|tr = 'Sabit maliyetle yan ürün çıkışı'");
	EndIf;
	
	If ThisIsPerformanceOfRepairWork Then
		Items.MaterialsAndServicesGroup.Title = NStr("vi = 'Bộ phận và nguyên vật liệu';
													|ru = 'Узлы и материалы';
													|en = 'Sub-assets and materials'; fa = 'Sub-assets and materials';
													|it = 'Sub-assets and materials';
													|pl = 'Sub-assets and materials';
													|tr = 'Alt varlıklar ve malzemeler'");
	Else
		Items.MaterialsAndServicesGroup.Title = NStr("vi = 'Nguyên vật liệu và công việc';
													|ru = 'Материалы и работы';
													|en = 'Materials and works'; fa = 'Materials and works';
													|it = 'Materiali e lavori';
													|pl = 'Materiały i prace';
													|tr = 'Malzemeler ve işler'");
	EndIf;;
	
	// "process according to specification"
	TheStructureOfTheSearch = New Structure("ProcessByBOM", True);
	Items.OutputProductsGroupSpecification.Visible  = ThisIsDisassembly
		And (Object.ManufacturedProducts.FindRows(TheStructureOfTheSearch).Count() Or Not DynamicStructureOfProductionOrders);
	Items.ReturnableWasteGroupSpecification.Visible = ThisIsDisassembly
		And (Object.RecyclableWaste.FindRows(TheStructureOfTheSearch).Count() Or Not DynamicStructureOfProductionOrders);
	Items.RecyclableWasteIsRepairable.Visible    = ThisIsPerformanceOfRepairWork;
	
	// "% of marriage"
	PercentageOfDefectiveGoodsColumnIsAvailable = False;
	PercentageOfDefectiveGoodsColumnIsAvailable = PercentageOfDefectiveGoodsColumnIsAvailable();
	Items.ManufacturedProductShareOfNonconformity.Visible       = (ThisIsBuild   And PercentageOfDefectiveGoodsColumnIsAvailable);
	Items.MainProductShareOfNonconformity.Visible = (ThisIsBuild   And PercentageOfDefectiveGoodsColumnIsAvailable);
	Items.ManufacturedProductsShareOfNonconformity.Visible = (ThisIsDisassembly And PercentageOfDefectiveGoodsColumnIsAvailable);
	
	// The maximum shelf life of products during repair is limited to stages
	Items.ProductQueuePeriodIsLimited.Visible = (ThisIsBuild Or ThisIsDisassembly) And ProductionIsUsed22;
	SetProductSelectionParameters();
	// Allow the launch of products at a fixed cost
	Items.AllowSelectionForSideOutletProducts.Visible = EnterpriseManagement And ProductionIsUsed22 And ThisIsBuild;
	Items.AllowSelectionForSideOutletProducts.Enabled = Not Object.ContainsResourcesParametrization;
	
EndProcedure
&AtServer
Procedure SetProductSelectionParameters()
	
	TypesArray = New Array;
	
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
		Or Object.ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
		
		TypesArray.Add(Enums.ItemsTypes.OwnGoods);
		TypesArray.Add(Enums.ItemsTypes.ReusablePackage);
		TypesArray.Add(Enums.ItemsTypes.Work_5);
		
		If ProductDataManagementCached.ItIsAvailableToStoreCompositionOfSetInSpecifications() Then
			TypesArray.Add(Enums.ItemsTypes.Set);
		EndIf;
		
	ElsIf Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
		
		TypesArray.Add(Enums.ItemsTypes.Work_5);
		
	Else
		
		TypesArray.Add(Enums.ItemsTypes.OwnGoods);
		
	EndIf;
	
	ItemArray = New Array;
	ItemArray.Add(Items.MainProductProductKind);
	ItemArray.Add(Items.MainProductProducts);
	
	ProductDataManagementClientServer.SetSelectionByItemType(ItemArray, TypesArray);
	
EndProcedure
&AtServer
Procedure SetAvailabilityOfProductEditingElements()
	
	MainProductEditingMode = MainProductEditingModeIsUsed(ThisObject);
	
	// The "Product Specifications" team
	Items.FormOpenProductBOR.Visible     = MainProductEditingMode
		And Not (Object.AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ProductKind);
	Items.ManufacturedProductOpenProductBOR.Visible = Not MainProductEditingMode;
	// One (several) output items
	Items.GroupOneProduct.Visible      = MainProductEditingMode;
	Items.GroupMultipleProducts.Visible = Not MainProductEditingMode;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	If ReadOnly Then
		Return;
	EndIf;
	
	AttributeAvailability = (Object.Status = Enums.BOMStatuses.UnderDevelopment);
	BillOfMaterialsIsClosed = (Object.Status = Enums.BOMStatuses.Closed_);
	
	ItemArray = GetObjectAttributesToLock();
	ItemArray.Add("ThereIsIntermediateRelease");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", Not AttributeAvailability);
	
	// Elements available only in the current specification
	ItemArray.Clear();
	ItemArray.Add("MaterialsAndServicesEnterSubstitutionPermission");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", AttributeAvailability);
	
	// If the specification is closed, then we will make the rest of the details unavailable
	ItemArray.Clear();
	ItemArray.Add("ValidOnDate");
	ItemArray.Add("ValidToDate");
	ItemArray.Add("PrintingARouteMapByStage");
	ItemArray.Add("PrintingARouteMapByRouteMaps");
	ItemArray.Add("EmployeeResponsible");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", BillOfMaterialsIsClosed);
	
	SetAvailabilityOfClipboardCommands(ThisObject, ProcessingOfTabularForms.ThereAreLinesInClipboard() And AttributeAvailability);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfElementsOfMethodOfObtainingMaterial()
	
	AvailableInProcessProduction = EnterpriseManagement
		And Not ThisIsPerformanceOfRepairWork(ThisObject)
		And Not (Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly
				And DynamicStructureOfProductionOrders);
	
	If UseSemiFinishedProductsProducedAtStage Then
		Items.MaterialsAndServicesMethodOfGettingTheMaterialEditing.Visible = AvailableInProcessProduction;
		Items.MaterialsAndServicesGroupProduce.Visible                       = False;
	Else
		Items.MaterialsAndServicesMethodOfGettingTheMaterialEditing.Visible = False;
		Items.MaterialsAndServicesGroupProduce.Visible                       = AvailableInProcessProduction;
	EndIf;
	
	Items.MaterialsAndServicesSourceOfSemiFinishedProduct.TypeRestriction = New TypeDescription("CatalogRef.BillsOfMaterials");
	
EndProcedure

&AtServer
Procedure SetKeyToSaveWindowPosition()
	
	ArrayOfFeatures = New Array;
	ArrayOfFeatures.Add(ProductionIsUsed21);
	ArrayOfFeatures.Add(ProductionIsUsed22);
	ArrayOfFeatures.Add(UseSemiFinishedProductsProducedAtStage);
	
	WindowOptionsKey = StrTemplate("%1_%2", FormName, StrConcat(ArrayOfFeatures));
	
EndProcedure

&AtClientAtServerNoContext
Function PresentationOfTabularPartReturnableWaste(Form)
	
	Return ?(Form.Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly"),
		Form.Items.ReturnableWasteGroup.Title,
		Form.Items.GroupFinishedSideProducts.Title);
	
EndFunction

&AtServer
Function CheckFillingCommandWithValidStatus()
	
	Result = False;
	StatusCheckModeIsValid = True;
	
	If CheckFillingOfMainProduct()
			And CheckFilling() Then
		Result = True;
	EndIf;
	
	StatusCheckModeIsValid = False;
	Return Result;
	
EndFunction

&AtServer
Procedure SetAvailabilityOfStatusChangeCommands()
	
	Items.SetStatusValid.Enabled   = (Object.Status <> Enums.BOMStatuses.Valid);
	Items.SetTheClosedStatus_5.Enabled    = (Object.Status <> Enums.BOMStatuses.Closed_);
	Items.SetStatusUnderDevelopment.Enabled = (Object.Status <> Enums.BOMStatuses.UnderDevelopment);
	Items.CheckFilling.Enabled         = (Object.Status <> Enums.BOMStatuses.Valid);

EndProcedure

&AtClient
Procedure SetNewStatusAndRecord(Status)
	
	ClearMessages();
	
	If Object.DeletionMark Then
		WarningText = NStr("vi = 'Không thể thay đổi trạng thái của một bảng kê chi tiết các nguồn lực sản xuất được đánh dấu để xóa.';
							|ru = 'Нельзя изменить статус помеченной на удаление спецификации.';
							|en = 'Cannot change a status of the bill of materials marked for deletion.'; fa = 'Cannot change a status of the bill of materials marked for deletion.';
							|it = 'È proibito cambiare lo stato della specifica segnata per l''eliminazione.';
							|pl = 'Nie można zmienić statusu specyfikacji zaznaczonej do usunięcia.';
							|tr = 'Silinmek üzere işaretlenen ürün reçetesinin durumu değiştirilemez.'");
		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	If Status = PredefinedValue("Enum.BOMStatuses.Valid") Then
		
		If Not CheckFillingOfMainProduct() Then
			Return;
		EndIf;
		
	EndIf;
	
	If Status = PredefinedValue("Enum.BOMStatuses.Closed_") 
		And Not ValueIsFilled(Object.ValidToDate) Then
		Object.ValidToDate = CommonClient.SessionDate();
	EndIf;
	
	WriteSpecification(Status);
	
EndProcedure

&AtClient
Function WriteSpecification(Status = Undefined)
	
	PerformanceMonitorClient.TimeMeasurement(
		"Catalog.BillsOfMaterials.Form.ItemForm.WriteSpecification");
	
	ClearMessages();
	
	Result = WriteSpecificationOnServer(Status);
	If Result Then
		Notify("Write_BillsOfMaterials");
		NotifyChanged(Object.Ref);
		NotifyChanged(Type("CatalogRef.ProductionStages"));
		NotifyChanged(Type("CatalogRef.ManufacturingOperations"));
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function WriteSpecificationOnServer(Val Status = Undefined)
	
	Result      = False;
	ChangeStatus_ = Status <> Undefined And Object.Status <> Status;
	
	If ChangeStatus_ Then
		CurrentStatus = Object.Status;
		Object.Status = Status;
	EndIf;
	
	Try
		
		Result = Write();
		
	Except
		
		If ChangeStatus_ Then
			EventLogEvent = NStr("vi = 'Không thể thay đổi trạng thái của bảng kê chi tiết';
								|ru = 'Не удалось изменить статус спецификации';
								|en = 'Cannot change the BOM status'; fa = 'Cannot change the BOM status';
								|it = 'Non è stato possibile modificare lo stato della specifica';
								|pl = 'Zmiana statusu specyfikacji nie powiodła się';
								|tr = 'Ürün reçetesi durumu değiştirilemedi'",
				Common.DefaultLanguageCode());
		Else
			EventLogEvent = NStr("vi = 'Không thể ghi lại bảng kê chi tiết';
								|ru = 'Не удалось записать спецификацию';
								|en = 'Cannot save bill of materials'; fa = 'Cannot save bill of materials';
								|it = 'Non è stato possibile salvare la specifica';
								|pl = 'Nie udało się zapisać specyfikacji';
								|tr = 'Ürün reçetesi kaydedilemedi'",
				Common.DefaultLanguageCode());
		EndIf;
		
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Error,
			,
			,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	If ChangeStatus_ And Not Result Then
		Object.Status = CurrentStatus;
	EndIf;
	
	Return Result;

EndFunction

&AtClient
Procedure HandlerSetStatusUnderDevelopment(ClosingResult, AdditionalParameters) Export

	If ClosingResult = True Then
		
		SetNewStatusAndRecord(PredefinedValue("Enum.BOMStatuses.UnderDevelopment"));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)

	If TypeOf(ValueSelected) = Type("Structure") And ValueSelected.Property("GoodsAddressInStorage")
		And IsTempStorageURL(ValueSelected.GoodsAddressInStorage) Then
		GoodsList = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	Else
		Return;
	EndIf;
	
	TSName = "MaterialsAndServices";
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInSeriesAttribute", New Structure("Products", "SeriesAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillPackageByOwner");
	RowsToProcess = New Array();
	
	Table = Object[TSName]; // TabularSection
	For Each RowOfProduct In GoodsList Do
		
		CurrentRow = Table.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		WhenEnteringNewSpecificationLine(ThisObject, TSName, CurrentRow);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Table);
	
	FillInServiceDetailsMaterialsAndServices();

EndProcedure

&AtClient
Procedure ProcessingInputOfFractionOfCost(Item, CurrentData, ValueSelected)
	
	If CurrentData.CostShare <> ValueSelected.CostShare Then
		
		ProductionClientServer.FillInCostFractionInLine(
			CurrentData,
			ValueSelected);
		
		CalculatePercentageOfCostAllocationForOutputProducts();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckAddIntermediateSemiFinishedProductRelease(RowData, ValueSelected)
	
	If ValueSelected.Property("AddIntermediateReleaseOnSelection") And ValueSelected.AddIntermediateReleaseOnSelection Then
		
		Template = NStr("vi = 'Thêm sản xuất trung gian bán thành phẩm vào công đoạn ""%1""?';
						|ru = 'Добавить промежуточный выпуск полуфабриката на этап ""%1""?';
						|en = 'Add intermediate release of semi-finished product to the ""%1"" stage?'; fa = 'Add intermediate release of semi-finished product to the ""%1"" stage?';
						|it = 'Aggiungere la produzione intermedia del semilavorato alla fase ""%1""?';
						|pl = 'Dodać produkcję pośrednią półproduktu do etapu ""%1""?';
						|tr = '""%1"" aşamasına yarı mamul ara ürün çıkışı eklensin mi?'");
		QueryText = StrTemplate(Template, RowData.SourceOfSemiFinishedProductPresentation);
		
		NotificationParameters = New Structure("RowData", RowData);
		
		CallbackDescription = New CallbackDescription("AddIntermediateReleaseOnSelectionCompletion", ThisObject, NotificationParameters);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddIntermediateReleaseOnSelectionCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	TSName = "RecyclableWaste";
	
	ExcludeColumns_ = New Array;
	ExcludeColumns_.Add("Stage");
	ExcludeColumns_.Add("StageEditing");
	ExcludeColumns_.Add("StageEditingPresentation");
	ExcludeColumns_.Add("Operation");
	ExcludeColumns_.Add("OperationEdit");
	ExcludeColumns_.Add("OperationEditPresentation");
	ExcludeColumns_.Add("ElementOfProductionProcessPresentation");
	
	SourceRow = AdditionalParameters.RowData;
	
	IntermediateRelease = Object.RecyclableWaste.Add();
	IntermediateRelease.StageEditing              = SourceRow.SourceOfSemiFinishedProduct;
	IntermediateRelease.StageEditingPresentation = SourceRow.SourceOfSemiFinishedProductPresentation;
	IntermediateRelease.ElementOfProductionProcessPresentation = RepresentationOfProductionProcessElement(ThisObject, IntermediateRelease);
	FillPropertyValues(IntermediateRelease, SourceRow,, StrConcat(ExcludeColumns_, ","));
	
	WhenEnteringNewSpecificationLine(ThisObject, TSName, IntermediateRelease, True);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", IntermediateRelease.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", IntermediateRelease.Package);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInSeriesAttribute", New Structure("Products", "SeriesAreUsed"));
	
	BatchProcessingOfTablePartClient.ProcessTSString(IntermediateRelease, StructureOfActions, CachedValues);
	
	CalculateNumberOfOutputByProducts(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInUsingOperationsSheetsForStagesCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		FillInUsingOperationsSheetsForStages();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInUsingOperationsSheetsForStages()

	Catalogs.BillsOfMaterials.FillInUsingOperationsSheetsForStages(Object);
	
	ReadMainProductSpecificationData();
	
	FillInDetailsOfObjectAccordingToMainProduct(ThisObject);
	
	FillInServiceDetails();
	FillInPresentationDetailsStageOperation();
	SetAvailabilityOfProductEditingElements();
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure ProcessFieldSelectionInTable(TableName, Field, StandardProcessing)

	If AttributeAvailability And Not (ReadOnly Or Field.ReadOnly) Then
		Return;
	EndIf;
	
	FieldName = Field.Name;
	CurrentData = Items[TableName].CurrentData;
	
	If (StrFind(FieldName, "Products") > 0
			Or StrFind(FieldName, "SKU") > 0)
		And ValueIsFilled(CurrentData.Products)  Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.Products);
		
	ElsIf StrFind(FieldName, "BillOfMaterials") > 0
		And ValueIsFilled(CurrentData.BillOfMaterials) Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.BillOfMaterials);
		
	ElsIf StrFind(FieldName, "StageEditing") > 0
		And ValueIsFilled(CurrentData.StageEditing) Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.StageEditing);
		
	ElsIf StrFind(FieldName, "OperationEdit") > 0
		And ValueIsFilled(CurrentData.OperationEdit) Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.OperationEdit);

	ElsIf FieldName = "MaterialsAndServicesMethodOfGettingTheMaterialEditing" Then
		
		StandardProcessing = False;
		OpenFormForSelectingMaterialReceiptMethod(CurrentData);

	ElsIf FieldName = "MaterialsAndServicesApplyingTheMaterialEditing"
		And ValueIsFilled(CurrentData.ApplyingTheMaterialEditing) Then
		
		StandardProcessing = False;
		OpenMaterialApplicationSettingsForm(CurrentData);
		
	ElsIf FieldName = "MaterialsAndServicesSourceOfSemiFinishedProduct"
		And ValueIsFilled(CurrentData.SourceOfSemiFinishedProduct) Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.SourceOfSemiFinishedProduct);
		
	ElsIf FieldName = "LaborCostsProductCostElement"
		And ValueIsFilled(CurrentData.ProductCostElement) Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.ProductCostElement);
		
	ElsIf FieldName = "MaterialsAndServicesProductCostElement"
		And ValueIsFilled(CurrentData.ProductCostElement)
		And Not CurrentData.ProducedInProcess Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.ProductCostElement);
		
	ElsIf (FieldName = "LaborCostsWorkKind")
		And ValueIsFilled(CurrentData.WorkKind)  Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.WorkKind);
		
	ElsIf (StrFind(FieldName, "CostSharePercentage") > 0 Or StrFind(FieldName, "ThereAreErrorsOfFillingInCostShare") > 0)
		And Object.MethodOfAllocatingFinishedProductCosts <> PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares") Then
		
		StandardProcessing = False;
		OpenCostShareEntryForm(CurrentData);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateFlagRequiresSeriesToBeSpecified(ListOfTS, Products, NewValue, Form)
	
	ArrayTS = StrSplit(ListOfTS, ",");
	For Each TSName In ArrayTS Do
		For Each RowData In Form.Object[TSName] Do
			If RowData.Products = Products Then
				RowData.BatchIndicationRequired = NewValue;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtClient
Procedure OpenFormApplicationOfProductsInProduction(Products)
	
	FormParameters = New Structure;
	FormParameters.Insert("Products",             Products);
	FormParameters.Insert("CurrentSpecification",      Object.Ref);
	FormParameters.Insert("ProductSpecificationMode");
	
	OpenForm("CommonForm.ApplyProductsToManufacturing", FormParameters,, UniqueKey);
	
EndProcedure

&AtClient
Function CheckGetMainProductSpecifications()
	
	BasicProps = ProductDataManagementClientServer.MainPropsOfMainProductSpecification(Object);
	
	If BasicProps.Value.IsEmpty() Then
	
		MessageText = NStr("vi = 'Cần xác định bảng kê chi tiết các nguồn lực sản xuất sản phẩm chính.';
							|ru = 'Необходимо указать основное изделие спецификации.';
							|en = 'Specify main BOM product.'; fa = 'Specify main BOM product.';
							|it = 'È necessario indicare il prodotto principale della specifica.';
							|pl = 'Należy wskazać produkt podstawowy specyfikacji.';
							|tr = 'Ürün reçetesinin nihai ana ürününü belirtmeniz gerekmektedir.'");
		
		If Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly")
			And Object.AssignmentOption = PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.ItemList") Then
			Field = "Object.ManufacturedProducts";
		Else
			Field = ?(BasicProps.Name = "ProductKind", "MainProductProductKind", "MainProductProducts");
		EndIf;
		
		CommonClient.MessageToUser(MessageText,, Field);
		
	EndIf;
	
	Return BasicProps.Value;
	
EndFunction

&AtClient
Procedure OpenFormForSelectingMaterialReceiptMethod(RowData)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("ProductionProcessType", Object.ProductionProcessType);
	
	FormParameters.Insert("Products", RowData.Products);
	FormParameters.Insert("Characteristic", RowData.Characteristic);
	
	FormParameters.Insert("MethodOfProductsAutoselection", RowData.MethodOfProductsAutoselection);
	
	FormParameters.Insert("MethodOfReceivingMaterial", RowData.MethodOfReceivingMaterial);
	FormParameters.Insert("SourceOfSemiFinishedProduct", RowData.SourceOfSemiFinishedProduct);
	FormParameters.Insert("SourceOfSemiFinishedProductPresentation", RowData.SourceOfSemiFinishedProductPresentation);
	
	FormParameters.Insert("BillOfMaterialsRM", RowData.BillOfMaterialsRM);
	FormParameters.Insert("PlanNotEarlierThan", RowData.PlanNotEarlierThan);
	FormParameters.Insert("PlanNotEarlierThanPresentation", RowData.PlanNotEarlierThanPresentation);
	
	FormParameters.Insert("ProductionStart", Object.ValidOnDate);
	
	FormParameters.Insert("Stage", RowData.StageEditing);
	FormParameters.Insert("Owner", Object.Ref);
	
	FormParameters.Insert("AddressSemiFinishedProducts", PlaceSemiFinishedProductsOfPreviousStagesInStorage(RowData.GetID()));
	FormParameters.Insert("ReadOnly", Not AttributeAvailability);
	
	Data_Stage = FirstStageData; // See StageDataConstructor
	FormParameters.Insert("ThisIsTheFirstStep", RowData.StageEditing.IsEmpty() Or RowData.StageEditing = Data_Stage.Ref);
	FormParameters.Insert("ThisIsMaterialSet", RowData.ItemsType = PredefinedValue("Enum.ItemsTypes.Set"));
	FormParameters.Insert("ThisIsTechnologicalSet", ThisIsTechnologicalSet(ThisObject));
	
	OpenForm("Catalog.BillsOfMaterials.Form.FormOfMaterialReceiptMethodSelection", FormParameters, ThisObject);

EndProcedure

&AtServer
Function PlaceSemiFinishedProductsOfPreviousStagesInStorage(Id)
	
	StorageAddress = Undefined;
	
	RowData = Object.MaterialsAndServices.FindByID(Id);
	
	If ValueIsFilled(RowData.StageEditing) Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Products", RowData.Products);
		
		If RowData.ItemVariantsAreUsed Then
			
			FilterParameters.Insert("Characteristic", RowData.Characteristic);
			
		EndIf;
		
		QueryText = "
		|SELECT
		|	Stages.Ref                AS Stage,
		|	Stages.Description          AS StageName,
		|	Stages.Number                 AS StageNumber,
		|	Stages.TheNumberOfTheNextOne       AS NextStageNo,
		|	Stages.Department         AS Department,
		|	Stages.ProductionByThirdParty AS ProductionByThirdParty,
		|
		|	//
		|	Stages.Number                 AS Number,
		|	Stages.TheNumberOfTheNextOne       AS TheNumberOfTheNextOne,
		|	Stages.Description          AS Description,
		|	Stages.Ref                AS Ref
		|
		|INTO TTTableOfPredecessorStages
		|
		|FROM
		|	&StepsTable AS Stages
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CAST(Table.StageEditing AS Catalog.ProductionStages) AS Stage,
		|	CAST(Table.Package AS Catalog.PackagesAndUnitsOfMeasure)    AS Package,
		|	Table.NumberOfPackages                                            AS NumberOfPackages,
		|	CAST(Table.QuantityCalculationAlgorithm AS STRING(100)) <> """"   AS CalculationByFormula
		|INTO TTTableOfSemiFinishedProducts
		|FROM
		|	&TableOfSemiFinishedProducts AS Table
		|WHERE
		|	Table.StageEditing <> VALUE(Catalog.ProductionStages.EmptyRef)
		|;
		|
		|SELECT
		|	Table.Stage AS Stage,
		|	Table.CalculationByFormula AS CalculationByFormula,
		|	SUM(CAST(Table.NumberOfPackages * ISNULL(&QueryTextPackagingFactor1, 1) AS NUMBER(15,3))) AS Count
		|INTO TTTableOfSemiFinishedProductsInStages
		|FROM
		|	TTTableOfSemiFinishedProducts AS Table
		|
		|GROUP BY
		|	Table.Stage,
		|	Table.CalculationByFormula
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductionStages.*,
		|	CASE
		|		WHEN &Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN CAST(&Package AS Catalog.PackagesAndUnitsOfMeasure).Presentation
		|		ELSE CAST(&Products AS Catalog.Products).UnitOfMeasure.Presentation
		|	END AS PackagePresentation,
		|	ISNULL(TableOfSemiFinishedProducts.Count, 0) / ISNULL(&QueryTextPackagingFactor2, 1) AS Count,
		|	CASE
		|		WHEN ISNULL(TableOfSemiFinishedProducts.Count, 0) >= CAST(&NumberOfPackages * ISNULL(&QueryTextPackagingFactor2, 1) AS NUMBER(15,3))
		|				OR ISNULL(TableOfSemiFinishedProducts.CalculationByFormula, FALSE)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS QuantityAvailable,
		|	ISNULL(TableOfSemiFinishedProducts.CalculationByFormula, FALSE) AS CalculationByFormula,
		|	CASE
		|		WHEN TableOfSemiFinishedProducts.Count IS NULL 
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS AddIntermediateReleaseOnSelection
		|FROM
		|	TTTableOfPredecessorStages AS ProductionStages
		|		LEFT JOIN TTTableOfSemiFinishedProductsInStages AS TableOfSemiFinishedProducts
		|		ON ProductionStages.Stage = TableOfSemiFinishedProducts.Stage
		|WHERE
		|	(&AvailableProductionInProcessForRecycling 
		|		OR NOT &AvailableProductionInProcessForRecycling AND NOT ProductionStages.ProductionByThirdParty)
		|
		|ORDER BY
		|	StageNumber
		|";
		
		QueryText = StrReplace(
			QueryText,
			"&QueryTextPackagingFactor1",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"Table.Package",
				"CAST(&Products AS Catalog.Products)"));
		
		QueryText = StrReplace(
			QueryText,
			"&QueryTextPackagingFactor2",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"CAST(&Package AS Catalog.PackagesAndUnitsOfMeasure)",
				"CAST(&Products AS Catalog.Products)"));
		
		// TableOfSemiFinishedProducts
		TableOfSemiFinishedProducts = Object.RecyclableWaste.Unload(
			FilterParameters,
			"StageEditing, Package, NumberOfPackages, QuantityCalculationAlgorithm");
		
		Query = New Query;
		Query.Text = QueryText;
		
		Query.SetParameter("StepsTable", TableOfPredecessorStages(RowData.StageEditing));
		Query.SetParameter("TableOfSemiFinishedProducts", TableOfSemiFinishedProducts);
	
		// SemiFinishedProduct
		Query.SetParameter("Products",       RowData.Products);
		Query.SetParameter("Package",           RowData.Package);
		Query.SetParameter("NumberOfPackages", RowData.NumberOfPackages);
		
		Query.SetParameter("AvailableProductionInProcessForRecycling", AvailableProductionInProcessForRecycling());
		
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			
			StorageAddress = PutToTempStorage(QueryResult.Unload(), UUID);
			
		EndIf;
		
	EndIf;
	
	Return StorageAddress;
	
EndFunction

&AtClient
Procedure OpenMaterialApplicationSettingsForm(RowData)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Products", RowData.Products);
	FormParameters.Insert("Characteristic", RowData.Characteristic);
	
	FormParameters.Insert("MaterialApplication", RowData.MaterialApplication);
	FormParameters.Insert("AlternateType", RowData.AlternateType);
	FormParameters.Insert("Probability", RowData.Probability);
	
	FormParameters.Insert("ReadOnly", Not AttributeAvailability);
	
	OpenForm("Catalog.BillsOfMaterials.Form.MaterialUsageSetupForm", FormParameters, ThisObject);

EndProcedure

&AtClient
Procedure ProcessingSelectionOfMaterialApplicationSetting(RowData, ValueSelected)
	
	FillPropertyValues(RowData, ValueSelected);
	
	ProductDataManagementClientServer.FillInInformationOnUseOfMaterial(RowData);
	
EndProcedure

&AtClient
Procedure OpenDisplacingSpecificationsForm()
	
	FormParameters = New Structure;
	FormParameters.Insert("Context", Object);
	
	OpenForm(
		"Catalog.BillsOfMaterials.Form.FormPreemptiveBOM",
		FormParameters,
		ThisObject);
	
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
Procedure ClearProcessBySpecificationSetting(CurrentData)
	
	If CurrentData.ProcessByBOM Then
		CurrentData.ProcessByBOM = False;
		CurrentData.BillOfMaterials = Undefined;
	EndIf;
	
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

&AtClientAtServerNoContext
Procedure ConfigureSpecificationAssignmentOptions(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	
	ThisIsBuild = (Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly"));
	
	Items.AssignmentOption.Visible = False;
	Items.AssignmentOption.Visible = Form.AttributeAvailability
		And Not ThisIsPerformanceOfRepairWork(Form)
		And Not Form.ProductionIsUsed21;
	ChoiceList = Items.AssignmentOption.ChoiceList;
	ChoiceList.Clear();
	
	ChoiceList.Add(PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.ProductKind"), NStr("vi = 'dạng mặt hàng';
																								|ru = 'вид номенклатуры';
																								|en = 'item kind'; fa = 'نوع قلم';
																								|it = 'tipo di articolo';
																								|pl = 'Rodzaj pozycji';
																								|tr = 'Ürün türü'"));
	ChoiceList.Add(PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.Products"),    NStr("vi = 'mặt hàng';
																								|ru = 'номенклатура';
																								|en = 'item'; fa = 'item';
																								|it = 'nomenclatura';
																								|pl = 'pozycja';
																								|tr = 'öğe'"));
	If ThisIsBuild And Not ThisIsTechnologicalSet(Form) Then
		ChoiceList.Add(PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.ItemList"), NStr("vi = 'danh sách mặt hàng';
																								|ru = 'список номенклатуры';
																								|en = 'item list'; fa = 'فهرست اقلام';
																								|it = 'elenco di articoli';
																								|pl = 'lista nomenklatury';
																								|tr = 'Ürün listesi'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure FillStageInLines(TSName)
	
	If Not ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items[TSName]) Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("TSName", TSName);
	FormParameters.Insert("AddressInStorage", TreeOfProductionProcessElementsToSelectInRepository(FormParameters));
	
	OpenForm(
		"Catalog.BillsOfMaterials.Form.ProductionProcessElementChoiceForm",
		FormParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInCalculationArticleInLines(TSName)
	
	If Not ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items[TSName]) Then
		Return;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("ExpenseType", ProductionClient.TypesOfCostsForChoosingCalculationArticle(TSName));
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("MultipleChoice", False);
	
	CallbackDescription = New CallbackDescription("FillInCalculationArticleInLinesCompletion", ThisObject, TSName);
	
	OpenForm(
		"Catalog.ProductCostElements.ChoiceForm",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInCalculationArticleInLinesCompletion(ClosingResult, TSName) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items[TSName].SelectedRows;
	TabularSection = Object[TSName];
	
	For Each RowID In SelectedRows Do
		
		CurrentData = TabularSection.FindByID(RowID);
		If TSName = "MaterialsAndServices"
			And CurrentData.ProducedInProcess Then
				Continue;
		EndIf;
		CurrentData.ProductCostElement = ClosingResult;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FormCopyCompletion(Result, AdditionalParameters) Export
	
	If Not Result = DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	RefResult = FormCopyEndAtServer();
	ProductDataManagementClient.CopyResourceSpecificationAfterCopying(RefResult);
	
EndProcedure

&AtServer
Function FormCopyEndAtServer()
	
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		If Not Write() Then
			Return Undefined;
		EndIf;
	EndIf;
	
	Return ProductDataManagementServerCall.CopyResourceSpecification(Object.Ref);
	
EndFunction

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
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
