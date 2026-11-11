#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing the change of details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	BasicBufferTimeUnit = Catalogs.ProductionStages.BasicBufferTimeUnit();
	TheBasicUnitOfTimeForTheDurationOfTheUBBWStage = Catalogs.ProductionStages.TheBasicUnitOfTimeForTheDurationOfTheUBBWStage();
	
	Parameters.Property("Mode", Mode);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	
		Items.AlternativeCommandBar.Visible = False;
		Items.WorkCenterTypesUse.Visible = False;
		
		// StandardSubsystems.Properties
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Object", Object);
		AdditionalParameters.Insert("ItemForPlacementName", "AdditionalAttributesPage");
		AdditionalParameters.Insert("DeferredInitialization", True);
		PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
		// End StandardSubsystems.Properties

	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If Mode <> "OrderSpecification" Then
		// StandardSubsystems.Properties
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		// End StandardSubsystems.Properties
	EndIf;
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.MaximumNumberOfProductUnitsLots = MaximumNumberOfProductUnitsLots;
	ProductionProcessEditor.SaveTypesOfWorkCenters(
				WorkCenterTypes, 
				CurrentObject.PlanOperationsOfWorkCenterTypes,
				CurrentObject.WorkCenterTypes,
				CurrentObject.AlternateWorkCenterTypes);
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ProductionStages",, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillInServiceDetailsOfProcessorSService();
	
	CustomizeFormElements();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_RouteSheets" And Source = Object.RouteSheet Then
		ReadRouteMapSettings(ThisForm);
	EndIf;
	// Some mechanisms are not available in the order specification editing mode
	If Mode <> "OrderSpecification" Then		
		// Subsystem "Properties"
		If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
			UpdateAdditionalAttributesItems();
			PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		EndIf;
	EndIf; 
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	If ChoiceSource <> Undefined 
		And TypeOf(ChoiceSource) = Type("ClientApplicationForm") 
		And ChoiceSource.FormName = "CommonForm.ConfigureFilterByPropertiesAndCalculationUsingFormulas" Then
		
		CurrentData = Items[ChoiceSource.TSName].CurrentData;
		If ProductDataManagementClient.ConfigureSelectionByPropertiesAndCalculationByFormulasCompletion(ValueSelected, CurrentData, Object.SelectionByProperties) Then
			
			TypesOfWorkCentersRecalculateWorkingHours(CurrentData);
			CalculateDuration_();
			
			Modified = True;
			
		EndIf;
	
	EndIf;
	Return;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Mode <> "OrderSpecification" Then
		// StandardSubsystems.Properties
		PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
		// End StandardSubsystems.Properties
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If Not SplitRouteSheets 
		Or Not Object.RouteSheet.IsEmpty() 
		Then
		NotCheckedAttributeArray.Add("MaximumNumberOfProductUnitsLots");
	EndIf; 
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductionMethodOnChange(Item)

	Object.ProductionByThirdParty = Boolean(ProductionMethod);
	AttributesList = "ProductionMethod";
	
	If Object.ProductionByThirdParty Then
		
		Object.PlanOperationsOfWorkCenterTypes = False;
		Object.RouteSheet  = Undefined;
		Object.RouteSheetFactor = 0;
		
		AttributesList = AttributesList + ",PlanOperationsOfWorkCenterTypes,RouteSheet";
		
		PartnerField = Items.Partner;
		
	Else
		PartnerField = Items.Organization;
	EndIf;
	
	Object.Partner = PartnerField.TypeRestriction.AdjustValue(Object.Partner);
	
	ConfigureDependentFormElements(ThisForm, AttributesList);
	
	ProductionProcessEditorClientServer.FillInExplanationOfBasicSettings(Object, ThisObject);
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	DivisionWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure RouteSheetOnChange(Item)
	
	RouteMapWhenChangedOnServer();
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure PlanOperationsOfWorkCenterTypesOnChange(Item)
	
	ConfigureDependentFormElements(ThisForm, "PlanOperationsOfWorkCenterTypes");
	
	CalculateDuration_();
	
	ProductionProcessEditorClientServer.FillInExplanationOfBasicSettings(Object, ThisObject);
	
EndProcedure

&AtClient
Procedure UnitOfMeasureOfStageDurationOnChange(Item)
	
	If Object.UnitOfMeasureOfStageDuration.IsEmpty() Then
		Object.UnitOfMeasureOfStageDuration = TheBasicUnitOfTimeForTheDurationOfTheUBBWStage;
	EndIf;
	
EndProcedure

&AtClient
Procedure UnitOfMeasureOfPreliminaryBufferOnChange(Item)
	
	If Object.UnitOfMeasureOfPreliminaryBuffer.IsEmpty() Then
		
		Object.UnitOfMeasureOfPreliminaryBuffer = BasicBufferTimeUnit;
		
	EndIf;
	
	CalculateDuration_();
	
EndProcedure

&AtClient
Procedure UnitOfMeasureOfFollowUpBufferOnChange(Item)
	
	If Object.UnitOfMeasureOfFollowUpBuffer.IsEmpty() Then
		
		Object.UnitOfMeasureOfFollowUpBuffer = BasicBufferTimeUnit;
		
	EndIf;
	
	CalculateDuration_();
	
EndProcedure

&AtClient
Procedure QuantityOfProductUnitsLotsProducedSimultaneouslyOnChange(Item)
	
	ConfigureDependentFormElements(ThisForm, "QuantityOfProductUnitsLotsProducedSimultaneously");
	
EndProcedure

&AtClient
Procedure SplitRouteSheetsOnChange(Item)
	
	ProductionProcessEditorClient.SetMaximumNumberOfProductBatchUnits(
		SplitRouteSheets, MaximumNumberOfProductUnitsLots);
	
	ConfigureDependentFormElements(ThisForm, "SplitRouteSheets");
	
EndProcedure

&AtClient
Procedure PreliminaryBufferOnChange(Item)
	
	SetBlankMarkForBuffers(ThisObject);
	
	CalculateDuration_();
	
EndProcedure

&AtClient
Procedure FollowUpBufferOnChange(Item)
	
	SetBlankMarkForBuffers(ThisObject);
	
	CalculateDuration_();
	
EndProcedure

&AtClient
Procedure ProcessorServiceOnChange(Item)
	
	CurrentRow = New Structure("Products, Characteristic, ItemVariantsAreUsed");
	CurrentRow.Products = ProcessorService;
	CurrentRow.Characteristic = CharacteristicsOfProcessorSService;
	CurrentRow.ItemVariantsAreUsed = ItemVariantsAreUsed;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CharacteristicsOfProcessorSService);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	ItemVariantsAreUsed = CurrentRow.ItemVariantsAreUsed;
	
	ConfigureDependentFormElements(ThisObject, "Processing");
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalAttributesPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure OperatingProcedureOfWorkCenterTypesOnChange(Item)
	
	ProductionProcessEditorClient.OperatingProcedureOfWorkCenterTypesOnChange(
		WorkCenterTypes,
		Object.OperatingProcedureOfWorkCenterTypes,
		ThereIsSynchronousLoad,
		True);
	
	CalculateDuration_();
	
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersWorkCenterTypes

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
		ProductionIsUsed22 And Mode <> "OrderSpecification");
	
	ConfigureDependentFormElements(ThisObject, "WorkCenterTypes");
	Return; // empty handler
	
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
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WorkCenterTypesOnEditEnd(Item, NewRow, CancelEdit)
	If Not CancelEdit Then
		CalculateDuration_();
	EndIf;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WorkCenterTypesBeforeDeleteRow(Item, Cancel)
	ProductionProcessEditorClient.TypesOfWorkCentersClearSelectionSettingsByProperties(
		Items.WorkCenterTypes, Object.SelectionByProperties);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WorkCenterTypesAfterDeleteRow(Item)
	
	CollectionOfMainTypesOfRC = WorkCenterTypes.GetItems();
	
	ProductionProcessEditorClient.TypesOfWorkCentersAndUses(CollectionOfMainTypesOfRC);
	
	WhenChangingCompositionOfTypesOfWorkCenters();
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WorkCenterTypesSelection(Item, RowSelected, Field, StandardProcessing)
	If Not ReadOnly And AttributeAvailability Then
		Return;
	EndIf;
	
	CurrentData = Items.WorkCenterTypes.CurrentData;
	
	If (Field.Name = "WorkCenterTypesWorkCenterType")
		And ValueIsFilled(CurrentData.WorkCenterType)  Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.WorkCenterType);
		
	ElsIf (Field.Name = "WorkCenterTypesSetupSettings")
		And ValueIsFilled(CurrentData.SetupSettings)  Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.SetupSettings);
		
	EndIf;
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WorkCenterTypesUseOnChange(Item)
	CurrentData = Items.WorkCenterTypes.CurrentData;
	
	ProductionProcessEditorClient.WorkCenterTypesUseOnChange(CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WorkCenterTypesWorkCenterTypeOnChange(Item)
	TypesOfWorkCentersViewOfWorkCenterWhenChangingOnServer();
	TypesOfWorkCentersRecalculateWorkingHours(Items.WorkCenterTypes.CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WorkCenterTypesSetupSettingsOnChange(Item)
	TypesOfWorkCentersAdjustmentOptionWhenChangingOnServer();
	TypesOfWorkCentersRecalculateWorkingHours(Items.WorkCenterTypes.CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WorkCenterTypesOperationTimeOnChange(Item)
	TypesOfWorkCentersRecalculateWorkingHours(Items.WorkCenterTypes.CurrentData);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure WorkCenterTypesUnitOfMeasureOnChange(Item)
	TypesOfWorkCentersRecalculateWorkingHours(Items.WorkCenterTypes.CurrentData);
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSubcontractorServices

&AtClient
Procedure SubcontractorServicesProductsOnChange(Item)
	
	CurrentData = Items.SubcontractorServices.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentData.Characteristic);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TheCommandFillInTheTypesOfWorkCentersOnTheRouteMap(Command)
	If Object.RouteSheet.IsEmpty() Then
		MessageText = NStr("vi = 'Bạn phải chọn bản đồ lộ trình';
							|ru = 'Необходимо выбрать маршрутную карту';
							|en = 'Select a route sheet'; fa = 'Select a route sheet';
							|it = 'È necessario scegliere una scheda di lavorazione';
							|pl = 'Należy wybrać kartę technologiczną';
							|tr = 'Rota seçmeniz gerekmektedir'");
		CommonClientServer.MessageToUser(MessageText,, "Object.RouteSheet");
		Return;
	EndIf; 
	
	FillInWorkCenterKindsUsingAnOperationsSheet();
	
	WhenChangingCompositionOfTypesOfWorkCenters();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ConfigureFilterByPropertiesAndCalculationUsingFormulas(Command)
	CurrentData = Items.WorkCenterTypes.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		
		MessageText = NStr("vi = 'Chưa chọn dòng của bảng ""Dạng nguồn lực sản xuất"".';
							|ru = 'Не выбрана строка таблицы ""Виды рабочих центров"".';
							|en = 'No line of the ""Work center types"" table is selected.'; fa = 'No line of the ""Work center types"" table is selected.';
							|it = 'Non è selezionata alcuna riga nella tabella ""Tipi di centro di lavoro"".';
							|pl = 'Nie wybrano wiersza tabeli ""Rodzaje centrów wykonania pracy"".';
							|tr = '""İş Merkezi Türleri"" tablosunun satırı seçilmedi.'");
		CommonClientServer.MessageToUser(MessageText,, "WorkCenterTypes");
		
		Return;
	EndIf;
	
	If CurrentData.ConnectionKey = New UUID("00000000-0000-0000-0000-000000000000") Then
		CurrentData.ConnectionKey = New UUID;
	EndIf;
	
	OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(CurrentData, "WorkCenterTypes");
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure CompleteEditing(Command)
	
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure AddAlternativeViewOfRCCommand(Command)
	CurrentData = Items.WorkCenterTypes.CurrentData;
	
	ProductionProcessEditorClient.AddAnAlternativeTypeOfRC(
				CurrentData, 
				WorkCenterTypes, 
				Items.WorkCenterTypes,
				Object.OperatingProcedureOfWorkCenterTypes,
				ThereIsSynchronousLoad,
				ProductionIsUsed22);
	Return;
	
EndProcedure

&AtClient
Procedure CalculateOperationsSheetFactor(Command)
	
	Object.RouteSheetFactor = RouteSheetFactor(Object.Owner, Object.RouteSheet);
	
	ShowUserNotification(
		NStr("vi = 'Hệ số tính toán';
			|ru = 'Коэффициент рассчитан';
			|en = 'Factor is calculated'; fa = 'Factor is calculated';
			|it = 'Coefficiente calcolato';
			|pl = 'Współczynnik został obliczony';
			|tr = 'Katsayı hesaplandı'"),
		,
		,
		PictureLib.Information32);
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

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

#Region Private

#Region StandardSubsystems

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

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
#Region AutoSelection_SelectionByProperties_CalculationOfQuantity

&AtClient
Function CheckGetMainProductSpecifications(MainProduct = Undefined)

	MainProductData = MainProductSpecificationData(Object.Owner);
	
	If MainProductData <> Undefined Then
		If MainProductData.AssignmentOption = PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.ProductKind") Then
			MainProduct = MainProductData.ProductKind;
		Else
			MainProduct = MainProductData.Products;
		EndIf;
	Else
		MainProduct = PredefinedValue("Catalog.Products.EmptyRef");
	EndIf;
	
	If MainProduct.IsEmpty() Then
		MessageText = NStr("vi = 'Cần xác định bảng kê chi tiết các nguồn lực sản xuất sản phẩm chính.';
							|ru = 'Необходимо указать основное изделие спецификации.';
							|en = 'Specify main BOM product.'; fa = 'Specify main BOM product.';
							|it = 'È necessario indicare il prodotto principale della specifica.';
							|pl = 'Należy wskazać produkt podstawowy specyfikacji.';
							|tr = 'Ürün reçetesinin nihai ana ürününü belirtmeniz gerekmektedir.'");
		CommonClientServer.MessageToUser(MessageText);
	EndIf;
	
	Return MainProduct;

EndFunction

&AtServerNoContext
Function MainProductSpecificationData(BillOfMaterials)
	
	MainProduct = Catalogs.BillsOfMaterials.MainProductSpecificationData(BillOfMaterials);
	Return MainProduct;
	
EndFunction

&AtClient
Procedure OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(CurrentData, TSName)
	
	MainProductSpecifications = CheckGetMainProductSpecifications();
	If MainProductSpecifications.IsEmpty() Then
		Return;
	EndIf;
	
	AddressInStorage = PutDataForCalculationByFormulasInRepository(TSName);
	
	If CurrentData.SynchronousLoad Or ThereIsSynchronousLoad Then
		CompositionOfSettings = New Structure("SelectionByProperties");
	Else
		CompositionOfSettings = Undefined;
	EndIf;
	
	SelectionByProperties = ProductDataManagementClient.DetailsOfSettingsByLineInArray(
		CurrentData,
		Object.SelectionByProperties,
		ProductDataManagementClientServer.DetailsSettingUpSelectionByProperties());
	
	ProductDataManagementClient.ConfigureSelectionByPropertiesAndCalculationByFormulas(
						ThisForm,
						TSName,
						SelectionByProperties,
						MainProductSpecifications,
						Not AttributeAvailability,
						CompositionOfSettings,
						AddressInStorage);
EndProcedure

&AtServer
Function PutDataForCalculationByFormulasInRepository(TSName)
	
	DataForCalculation = Catalogs.BillsOfMaterials.UploadDataForFormulaConstructor(
		Object.Owner,
		TSName);
	
	Result = PutToTempStorage(DataForCalculation, UUID);
	Return Result;
	
EndFunction

#EndRegion
#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	SubsystemSettingsProduction = ProductionServer.SubsystemSettingsProduction();
	FillPropertyValues(ThisObject, SubsystemSettingsProduction);

	UseProductionPlanning = Constants.UseProductionPlanning.Get();
	EnterpriseManagement = GetFunctionalOption("EnterpriseManagement");
	
	UseBillOfMaterialsParameterization = 
		GetFunctionalOption("UseBillOfMaterialsParameterization");
	
	StoreOperationsInBillsOfMaterials = GetFunctionalOption("StoreOperationsInBillsOfMaterials");
	UseRouteSheets            = GetFunctionalOption("UseRouteSheets");
	
	ProductionMethod = Number(Object.ProductionByThirdParty);
	ReadDetailsOfDivision(True);
	
	ReleaseBatchDescriptionIsAvailable = ProductDataManagement.ReleaseBatchDescriptionIsAvailable();
	FillInReleaseBatchDescription();
	UseInternalSubcontracting = GetFunctionalOption("UseInternalSubcontracting");
	ProductionProcessEditor.FillInTheTypesOfWorkCenters(
		Object, WorkCenterTypes, ThereIsParallelDownload, ThereIsSynchronousLoad);
	ReadRouteMapSettings(ThisObject);
	SetBlankMarkForBuffers(ThisObject);
	
	
	FillInServiceDetailsOfProcessorSService();
	
	ProductionProcessEditorClientServer.FillInExplanationOfBasicSettings(Object, ThisObject);
	
	SetAvailabilityByServerStatus();
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Mark not filled in for a batch of itinerary sheets
	#Region MaximumNumberOfProductBatchUnitsMark
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaximumNumberOfProductUnitsLots.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SplitRouteSheets");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region WorkCenterTypes
	
	If Mode <> "OrderSpecification" Then
		
		ProductDataManagement.EstablishConditionalAppearanceOfSelectionByPropertiesAndCalculationByFormulas(
			ThisForm,
			"",
			"WorkCenterTypes",
			"OperationTime");
		
	EndIf;
	
	ProductionProcessEditor.EstablishConditionalAppearanceTypesOfWorkCenters(
		ThisObject, "WorkCenterTypes");
	ProductionProcessEditor.SetConditionalAppearanceOfBankingDetailsForSynchronousUploading(
		ThisObject, "WorkCenterTypes");
	
	#EndRegion
	
	// The mark of the filled for the coefficient of the route map
	#Region RouteSheetFactor
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RouteSheetFactor.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RouteSheet");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region Other
	

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm,
		"SubcontractorServicesCharacteristic",
		"Object.SubcontractorServices.ItemVariantsAreUsed");
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	SpecificationData = ResourceSpecificationData();
	
	Items.ProductionMethod.Visible =
		(ProductionByThirdPartyIsUsed2_5
			Or False)
		And Not SpecificationData.MultiStageProductionProcess;
	If ProductionByThirdPartyIsUsed
		And (SpecificationData.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
			Or Object.ProductionByThirdParty)
		And Not Object.WorkPlanning Then
		Items.ProductionMethod.Visible = True;
	Else
		Items.ProductionMethod.Visible = False;
	EndIf;
	
	Items.FillInTheTypesOfWorkCenters.Visible = UseRouteSheets;
	Items.ConfigureFilterByPropertiesAndCalculationUsingFormulas.Visible = Not ProductionIsUsed21;
	
	Items.RouteMapGroup.ReadOnly = StoreOperationsInBillsOfMaterials;
	
	Items.Organization.TypeRestriction = New TypeDescription("CatalogRef.Companies");
	Items.Partner.TypeRestriction     = New TypeDescription("CatalogRef.Partners");
	
	ProductDataManagementClientServer.SetParametersForEnteringNumberOfBatchUnits(
		SpecificationData.ProductionIssueByCustomPortions And ReleaseBatchDescriptionIsAvailable,
		Items.QuantityOfProductUnitsLotsProducedSimultaneously);
	
	Items.DetailsPage.Picture = CommonClientServer.CommentPicture(Object.LongDesc);

	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Object = Form.Object;
	Items = Form.Items; // FormItems
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("ProductionMethod")
		Or Initialize Then
		
		OwnProduction = Not Object.ProductionByThirdParty;
		WorkPlanning = Object.WorkPlanning;
		
		Items.RecyclingPage.Visible = Not OwnProduction;
		Items.PlanOperationsOfWorkCenterTypes.Visible = OwnProduction And Not WorkPlanning;
		
		Items.RouteMapGroup.Visible = Form.EnterpriseManagement
			And Form.UseRouteSheets
			And OwnProduction
			And Not WorkPlanning;
			
		Items.PagesSplitRouteSheets.Visible = Form.EnterpriseManagement
			And Form.ProductionIsUsed21
			And OwnProduction
			And Not WorkPlanning;
		
		Items.Organization.Visible = False;
		Items.Production_Stage.Visible = False;
		Items.Organization.Visible =
			OwnProduction
			And Form.UseInternalSubcontracting
			And Not WorkPlanning;
		Items.Production_Stage.Visible = True;
	EndIf;
	
	If AttributesStructure1.Property("PlanOperationsOfWorkCenterTypes")
		Or Initialize Then
		
		ProductionProcessEditorClientServer.ConfigureElementsOfWorkCenterViewsGroup(Object, Form);
		
		ProductionProcessEditorClientServer.ConfigureGroupItemsStageDuration(Object, Form);
		
	EndIf;
	If AttributesStructure1.Property("WorkCenterTypes")
		Or Initialize Then
			
		ProductionProcessEditorClientServer.ConfigureOrderOfWorkCenterViewsElement(Object, Form);
		
		ProductionProcessEditorClientServer.ConfigureItemSimultaneouslyProducedQuantity(Object, Form);
			
	EndIf;
	If AttributesStructure1.Property("SplitRouteSheets")
		Or Initialize Then
		
		Items.MaximumNumberOfProductUnitsLots.ReadOnly = 
			Not (Form.SplitRouteSheets And Not Form.BillOfMaterialsIsClosed);
		
	EndIf;
	If AttributesStructure1.Property("RouteSheet")
		Or Initialize Then
		
		ProductionProcessEditorClientServer.ConfigureRouteMapGroupElements(Object, Form);
		
	EndIf;
	// Simultaneously produced number of units/batches of products
	If AttributesStructure1.Property("QuantityOfProductUnitsLotsProducedSimultaneously")
		Or Initialize Then
		
		Items.QuantityOfProductUnitsLotsProducedSimultaneously.ToolTip =
			ProductDataManagementClientServer.PresentationOfUnitOfMeasurementOfBatchOfRelease(
				Form.ReleaseBatchDescription,
				Object.QuantityOfProductUnitsLotsProducedSimultaneously);
		
	EndIf;
	
	// The page of the processor's details
	If AttributesStructure1.Property("Processing")
		Or Initialize Then
		
		Items.CharacteristicsOfProcessorSService.Enabled = Form.ItemVariantsAreUsed;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityByServerStatus()
	
	If Mode = "OrderSpecification" Or ReadOnly Or Object.Owner.IsEmpty() Then
		Return;
	EndIf;
	
	OwnerStatus = Common.ObjectAttributeValue(Object.Owner, "Status");
	AttributeAvailability = (OwnerStatus = Enums.BOMStatuses.UnderDevelopment);
	BillOfMaterialsIsClosed = (OwnerStatus = Enums.BOMStatuses.Closed_);
	
	Items.RouteSheet.ReadOnly = Not AttributeAvailability;
	Items.RouteSheetFactor.ReadOnly = Not AttributeAvailability;
	
	Items.SplitRouteSheets.ReadOnly = BillOfMaterialsIsClosed;
	Items.MaximumNumberOfProductUnitsLots.ReadOnly = BillOfMaterialsIsClosed;
	
	ProductionProcessEditor.SetAvailabilityOfStageElementsByStatus(ThisObject, AttributeAvailability, BillOfMaterialsIsClosed);
	
EndProcedure

&AtServer
Procedure FillInReleaseBatchDescription()
	
	If Mode <> "OrderSpecification" And ReleaseBatchDescriptionIsAvailable Then
	
		If Parameters.Property("ReleaseBatchDescription")
			And Parameters.ReleaseBatchDescription <> Undefined Then
			
			ReleaseBatchDescription = Parameters.ReleaseBatchDescription;
			
		Else
			
			ReleaseBatchDescription = Catalogs.BillsOfMaterials.ReleaseBatchDescription(Object.Owner);
			
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Function ResourceSpecificationData()
	
	If Mode <> "OrderSpecification" And ValueIsFilled(Object.Owner) Then
		AttributeSet = "ProductionProcessType,ProductionIssueByCustomPortions,MultiStageProductionProcess";
		AttributesValues = Common.ObjectAttributesValues(Object.Owner, AttributeSet);
	Else
		AttributesValues = New Structure("
		|ProductionProcessType,
		|ProductionIssueByCustomPortions,
		|MultiStageProductionProcess",
		Enums.ProductionProcessTypes.Assembly, False, False);
	EndIf;
	
	Return AttributesValues;

EndFunction

&AtServer
Procedure ReadDetailsOfDivision(ThisIsReadingObject)

	DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(Object.Department);
	PlanningInterval = DivisionParameters.PlanningInterval;
	
	If Not ThisIsReadingObject Then
		
		ProductionProcessEditor.CheckAllKindsOfWorkCenters(
			Object, WorkCenterTypes, ThereIsParallelDownload, ThereIsSynchronousLoad);
		
	EndIf; 
	ProductionProcessEditor.FillInSelectionOfBufferUnit(
			PlanningInterval,
			Items.UnitOfMeasureOfPreliminaryBuffer.ChoiceList);
	
	ProductionProcessEditor.FillInSelectionOfBufferUnit(
			PlanningInterval,
			Items.UnitOfMeasureOfFollowUpBuffer.ChoiceList);
	
	ProductionProcessEditor.CheckSelectionOfBufferUnit(Object, ThisObject, Not ThisIsReadingObject);
	
EndProcedure


&AtClientAtServerNoContext
Procedure ReadRouteMapSettings(Form)

	FillPropertyValues(
		Form,
		ProductionProcessEditorClientServer.GetRouteMapSettings(Form.Object));
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetBlankMarkForBuffers(Form)
	
	RequiredFilling = ProductionProcessEditorClientServer.MandatoryFillingOfUnitsOfMeasurementOfBuffers(
		Form.Object);
	For Each KeyAndValue In RequiredFilling Do
		Form.Items[KeyAndValue.Key].MarkIncomplete = KeyAndValue.Value;
	EndDo;
	
EndProcedure

&AtClient
Procedure CalculateDuration_()
	
	If ProductionProcessEditorClientServer.CalculateDurationAutomatically(Object,
		ProductionIsUsed21,
		PlanningByMaterialResourcesIsUsed,
		PlanningByProductionResourcesIsUsed) Then
		CalculateDurationOnServer();
	EndIf;
	
	Return; // empty handler
	
EndProcedure

&AtServer
Procedure FillInWorkCenterKindsUsingAnOperationsSheet()
	
	ProductionProcessEditor.FillInWorkCenterKindsUsingAnOperationsSheet(
		Object,
		ThisObject,
		WorkCenterTypes,
		ThereIsParallelDownload,
		ThereIsSynchronousLoad);
	
EndProcedure

&AtServer
Procedure TypesOfWorkCentersViewOfWorkCenterWhenChangingOnServer()
	
	CurrentData = WorkCenterTypes.FindByID(Items.WorkCenterTypes.CurrentRow);
	
	CurrentData.SetupSettings = Catalogs.SetupOptions.EmptyRef();
	
	ProductionProcessEditor.FillInServiceDetailsInLineOfTypesOfRC(
		Undefined,
		Undefined,
		True,
		CurrentData);
	
	ProductionProcessEditorClientServer.CalculateServiceSignsOfLoadingVRC(
		WorkCenterTypes,
		ThereIsParallelDownload,
		ThereIsSynchronousLoad);
		
	ProductionProcessEditorClientServer.CheckPurifySimultaneouslyProducedQuantity(
		Object, ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "WorkCenterTypes");
	
EndProcedure
 
&AtServer
Procedure TypesOfWorkCentersAdjustmentOptionWhenChangingOnServer()
	
	CurrentData = WorkCenterTypes.FindByID(Items.WorkCenterTypes.CurrentRow);
	
	ProductionProcessEditor.FillInServiceDetailsInLineOfTypesOfRC(
		Undefined,
		Undefined,
		True,
		CurrentData);
	
	ProductionProcessEditorClientServer.CalculateServiceSignsOfLoadingVRC(
		WorkCenterTypes,
		ThereIsParallelDownload,
		ThereIsSynchronousLoad);
	
EndProcedure

&AtServer
Procedure RouteMapWhenChangedOnServer()
	
	ReadRouteMapSettings(ThisForm);
	
	If CalculateFactor Then
		
		Object.RouteSheetFactor = RouteSheetFactor(Object.Owner, Object.RouteSheet);
		
	Else
		
		If Not ValueIsFilled(Object.RouteSheet) Then
			Object.RouteSheetFactor = 0;
		ElsIf Object.RouteSheetFactor = 0 Then
			Object.RouteSheetFactor = 1;
		EndIf;
		
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, "RouteSheet");
	
EndProcedure

&AtServerNoContext
Function RouteSheetFactor(BillOfMaterial, RouteSheet)
	
	SpecificationData = Catalogs.BillsOfMaterials.MainProductSpecificationData(
		BillOfMaterial);
	
	Return Catalogs.RouteSheets.RouteMapCoefficientForSpecification(
		SpecificationData, RouteSheet);
	
EndFunction

&AtServer
Procedure CalculateDurationOnServer()
	
	ProductionProcessEditor.CalculateStageDuration(Object, WorkCenterTypes);
	
EndProcedure

&AtClient
Procedure TypesOfWorkCentersRecalculateWorkingHours(CurrentData)
	
	ProductionProcessEditorClient.TypesOfWorkCentersRecalculateWorkingHours(
			CurrentData,
			WorkCenterTypes,
			Object.OperatingProcedureOfWorkCenterTypes,
			ThereIsSynchronousLoad,
			ProductionIsUsed22,
			True);
	
EndProcedure

&AtClient
Procedure WhenChangingCompositionOfTypesOfWorkCenters()
	
	ProductionProcessEditorClient.WhenChangingCompositionOfTypesOfWorkCenters(
		WorkCenterTypes, 
		Object.OperatingProcedureOfWorkCenterTypes,
		ProductionIsUsed22 And Mode <> "OrderSpecification");
	
	CalculateDuration_();
	
	ProductionProcessEditorClientServer.CalculateServiceSignsOfLoadingVRC(
		WorkCenterTypes,
		ThereIsParallelDownload,
		ThereIsSynchronousLoad);
		
	ProductionProcessEditorClientServer.CheckPurifySimultaneouslyProducedQuantity(
		Object, ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "WorkCenterTypes");
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfProcessorSService()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.SubcontractorServices, StructureOfActions);
	
EndProcedure

&AtServer
Procedure DivisionWhenChangedOnServer()

	ReadDetailsOfDivision(False);

EndProcedure


#EndRegion

#EndRegion
