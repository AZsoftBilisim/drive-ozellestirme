
#Region Variables

#Region Variables1

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CalculationObjectCache;

#EndRegion

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
		OnCreatReadAtServer();
	EndIf;
	
	EventLogEntryCalculationError = InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.EventLogEntryCalculationError();
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
	OnCreatReadAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
	If Not CurrentObject.Posted Then
		Items.CalculationOfDemandForMaterials.CurrentPage = Items.PageIsNotCalculated;
	EndIf;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CalculationObjectCache = Object.CostObject;
	ControlOfNeedsCalculation();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	Notify("Write_StandardCosting2_2", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	If Object.Posted Then
		
		ControlOfNeedsCalculation();
		AttachIdleHandler("ControlOfNeedsCalculation", 3);
		
	Else
		
		Items.CalculationOfDemandForMaterials.CurrentPage = Items.PageIsNotCalculated;
		
	EndIf;
	
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	
	FillInServiceDetails();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
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
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return;
	
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


// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

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
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure Pickup(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CloseOnChoice", False);
	
	If Object.CostObject = PredefinedValue("Enum.CostObjects.ProductionOrder") Then
		OpenForm("Document.ProductionOrder2_2.ChoiceForm", FormParameters, Items.CostObjects);
	ElsIf Object.CostObject = PredefinedValue("Enum.CostObjects.BillOfMaterial") Then
		OpenForm("Catalog.BillsOfMaterials.ChoiceForm", FormParameters, Items.CostObjects);
	EndIf;
	
EndProcedure

#EndRegion

#Region HeaderEventHandlers

&AtClient
Procedure CostObjectOnChange(Item)
	
	If Not Object.CostObject = CalculationObjectCache
		And Object.CostObjects.Count() > 0 Then
		
		CalculationObjectParameters = CalculationObjectParameters(CalculationObjectCache);
		QueryText = NStr("vi = 'Phần bảng %1 sẽ bị xóa. Tiếp tục?';
						|ru = 'Табличная часть %1 будет очищена. Продолжить?';
						|en = 'The %1 table will be cleared. Do you want to continue?'; fa = 'The %1 table will be cleared. Do you want to continue?';
						|it = 'La parte tabulare %1 verrà cancellata. Continuare?';
						|pl = 'Część tabelaryczna %1 zostanie wyczyszczona. Kontynuować?';
						|tr = '%1 tablo bölümü temizlenecektir. Devam edilsin mi?'");
		
		ShowQueryBox(New CallbackDescription("CostObjectOnChangeCompletion", ThisObject), 
			StringFunctionsClientServer.SubstituteParametersToString(QueryText, CalculationObjectParameters.PageHeader), 
			QuestionDialogMode.YesNo);
		
		Return;
		
	EndIf;
	
	EditCalculationObjectsPage(ThisForm);
	CalculationObjectCache = Object.CostObject;
	
EndProcedure

&AtClient
Procedure TheNeedIsNotCalculatedThereAreErrorsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(FormattedStringURL) Then
		
		FormParameters = New Structure;
		
		FormParameters.Insert("Data", Object.Ref);
		FormParameters.Insert("EventLogEvent", EventLogEntryCalculationError);
		
		FilterByLevel = New ValueList;
		FilterByLevel.Add("Error", "Error");
		
		FormParameters.Insert("Level", FilterByLevel);
		
		OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
		
	EndIf;

EndProcedure

&AtClient
Procedure TheDemandIsCalculatedWithErrorsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(FormattedStringURL) Then
		
		FormParameters = New Structure("VariantKey, PurposeUseKey, Filter, GenerateOnOpen, ReportOptionsCommandsVisibility");
		FormParameters.Insert("PurposeUseKey",		Undefined);
		FormParameters.Insert("Filter",							New Structure("StandardCostEstimate", Object.Ref));
		FormParameters.Insert("GenerateOnOpen",			True);
		FormParameters.Insert("ReportOptionsCommandsVisibility",	False);
		
		OpenForm("Report.ErrorsOfProductsCostingCalculation.Form", FormParameters);
		
	EndIf;

EndProcedure

#EndRegion

#Region EventHandlersCalculationObjects

&AtClient
Procedure CostObjectsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ErrorText = AddCalculationObjects(ValueSelected);
	
	If ValueIsFilled(ErrorText) Then
		CommonClientServer.MessageToUser(ErrorText);
	EndIf;
	
EndProcedure

&AtClient
Procedure CostObjectsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Not ValueIsFilled(Object.CostObject) Then
		
		MessageText = NStr("vi = 'Trước khi thêm, cần chọn một đối tượng tính giá thành.';
							|ru = 'Перед добавлением требуется выбрать объект калькуляции.';
							|en = 'It is required to select a cost object before adding.'; fa = 'It is required to select a cost object before adding.';
							|it = 'Prima di aggiungere, è necessario selezionare un oggetto di calcolo.';
							|pl = 'Przed dodaniem musisz wybrać obiekt kalkulacji.';
							|tr = 'Eklemeden önce bir maliyet nesnesi seçmeniz gerekmektedir.'");
		CommonClientServer.MessageToUser(MessageText, , "CostObject");
		Cancel = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CostObjectsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If Not NewRow Or NewRow And Not CancelEdit Then
		
		CurrentData = Items.CostObjects.CurrentData;
		
		DuplicatesFilter = New Structure("Products, Characteristic, Purpose, Object");
		FillPropertyValues(DuplicatesFilter, CurrentData);
		
		If Object.CostObjects.FindRows(DuplicatesFilter).Count() > 1 Then
			
			ErrorText = NStr("vi = 'Một danh sách với cùng một bộ giá trị đã tồn tại trong danh sách.';
							|ru = 'В списке уже существует строка с таким же набором значений.';
							|en = 'Line with the same set of values already exists in the list.'; fa = 'Line with the same set of values already exists in the list.';
							|it = 'C''è già una riga nell''elenco con lo stesso insieme di valori.';
							|pl = 'Istnieje już wiersz na liście o tym samym zestawie wartości.';
							|tr = 'Listede zaten aynı değer kümesine sahip bir satır var.'");
			CommonClientServer.MessageToUser(ErrorText);
			Cancel = True;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculationObjectsProductsOnChange(Item)
	
	CurrentRow = Items.CostObjects.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If Not OrderCosting Then
		StructureOfSpecificationFilling = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
			Object, CurrentRow, BOMSelectionParameters,,New Structure("PropsNameSpecification", "Object"));
		StructureOfActions.Insert("CheckFillSpecification", StructureOfSpecificationFilling);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure CostObjectsCharacteristicOnChange(Item)

	If OrderCosting Then
		Return;
	EndIf;
	
	CurrentRow = Items.CostObjects.CurrentData;
	
	StructureOfSpecificationFilling = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		Object, CurrentRow, BOMSelectionParameters,,New Structure("PropsNameSpecification", "Object"));
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillSpecification", StructureOfSpecificationFilling);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure CostObjectsPackageOnChange(Item)
	
	CurrentRow = Items.CostObjects.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure CostObjectsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.CostObjects.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties 

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

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

&AtClient
Procedure CostObjectOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		Object.CostObjects.Clear();
		EditCalculationObjectsPage(ThisForm);
		
		CalculationObjectCache = Object.CostObject;
		
	Else
		
		Object.CostObject = CalculationObjectCache;
		
	EndIf;

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "CostObjectsCharacteristic",
																		     "Object.CostObjects.ItemVariantsAreUsed");
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "CalculationObjectsUnitOfMeasurement";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.CostObjects.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
		
EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	EditCalculationObjectsPage(ThisForm);
	FillInServiceDetails();
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.CostObjects, StructureOfActions);
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(Object, Documents.StandardCosting2_2);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.CostObjectsObject, BOMSelectionParameters);
	
EndProcedure

&AtServer
Function AddCalculationObjects(ValueSelected)
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	DestinationInHeader = False;
	
	If TypeOf(ValueSelected) = Type("CatalogRef.BillsOfMaterials")
		Or TypeOf(ValueSelected) = Type("DocumentRef.ProductionStage2_2") Then
		SourceOfOutputProducts = "ManufacturedProducts";
	ElsIf TypeOf(ValueSelected) = Type("DocumentRef.ProductionOrder2_2") Then
		
		SourceOfOutputProducts = "ManufacturedProduct";
		DestinationInHeader = 
			Common.ObjectAttributeValue(ValueSelected, 
				"ProductionProcessType") = Enums.ProductionProcessTypes.WithoutBillsOfMaterials;
		
	EndIf;	
	
	DuplicatesFilter = New Structure("Products, Characteristic, Object");
	DuplicateCount = 0;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	
	ManufacturedProducts = ValueSelected[SourceOfOutputProducts].Unload();
	For Each ProductionLine In ManufacturedProducts Do
		
		DuplicatesFilter.Products = ProductionLine.Products;
		DuplicatesFilter.Characteristic = ProductionLine.Characteristic;
		DuplicatesFilter.Object = ValueSelected;
		
		If Object.CostObjects.FindRows(DuplicatesFilter).Count() > 0 Then
			
			DuplicateCount = DuplicateCount + 1;
			Continue;
			
		EndIf;
		
		NewCalculationObject = Object.CostObjects.Add();
		FillPropertyValues(NewCalculationObject, ProductionLine);
		NewCalculationObject.Object = ValueSelected;
		
		If DestinationInHeader Then
			NewCalculationObject.Purpose = ValueSelected.AssignmentProducts;
		EndIf;
		
		RowsToProcess.Add(NewCalculationObject);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.CostObjects,
		CachedValues);
	
	ErrorText = "";
	If DuplicateCount = ValueSelected[SourceOfOutputProducts].Count() Then
		ErrorText = NStr("vi = 'Đối tượng hiện tại đã được khớp vào Chứng từ.';
						|ru = 'Текущий объект уже подобран в документ.';
						|en = 'Current object is already picked for the document.'; fa = 'Current object is already picked for the document.';
						|it = 'L''oggetto corrente è già selezionato nel documento.';
						|pl = 'Bieżący obiekt jest już wybrany w dokumencie.';
						|tr = 'Mevcut nesne belgede zaten seçilidir.'");
	EndIf;
	
	Return ErrorText;
	
EndFunction

// Change the headers: page Tranceonjeroen, column Objectchangeconflict.
// Sets the column type for the selected calculation object.
// Parameters:
//	Form - ClientApplicationForm - the form to make changes to.
//
&AtClientAtServerNoContext
Procedure EditCalculationObjectsPage(Form)
	
	Object = Form.Object;
	
	Parameters = CalculationObjectParameters(Object.CostObject);
	
	Form.Items.CostObjectsObject.TypeRestriction = Parameters.TypeDescription;
	Form.Items.CalculationObjectsPage.Title = Parameters.PageHeader;
	Form.Items.CostObjectsObject.Title = Parameters.ColumnTitle;
	
	Form.OrderCosting = Parameters.OrderCosting;
	
	Form.Items.CostObjectsPurpose.Visible = Form.OrderCosting;
	
EndProcedure

&AtClientAtServerNoContext
Function CalculationObjectParameters(CostObject)
	
	Parameters = New Structure;
	Parameters.Insert("OrderCosting", False);
	
	If CostObject = PredefinedValue("Enum.CostObjects.ProductionOrder") Then
		
		Parameters.Insert("PageHeader", NStr("vi = 'Đơn hàng sản xuất';
											|ru = 'Заказы на производство';
											|en = 'Production orders'; fa = 'سفارش‌های تولید';
											|it = 'Ordini di produzione';
											|pl = 'Zamówienia na produkcję';
											|tr = 'Üretim emirleri'"));
		Parameters.Insert("ColumnTitle", NStr("vi = 'Đơn hàng sản xuất';
												|ru = 'Заказ на производство';
												|en = 'Production order'; fa = 'سفارش تولید';
												|it = 'Ordine di produzione';
												|pl = 'Zlecenie produkcyjne';
												|tr = 'Üretim emri'"));
		Parameters.Insert("TypeDescription", New TypeDescription("DocumentRef.ProductionOrder2_2"));
		Parameters.OrderCosting = True;
		
	ElsIf CostObject = PredefinedValue("Enum.CostObjects.BillOfMaterial") Then
		
		Parameters.Insert("PageHeader", NStr("vi = 'Danh sách bảng kê chi tiết các nguồn lực sản xuất';
											|ru = 'Ресурсные спецификации';
											|en = 'Bills of materials'; fa = 'فهرست‌های مواد';
											|it = 'Specifiche di risorse';
											|pl = 'Specyfikacje zasobów';
											|tr = 'Ürün reçeteleri'"));
		Parameters.Insert("ColumnTitle", NStr("vi = 'Danh sách bảng kê chi tiết các nguồn lực sản xuất';
												|ru = 'Ресурсная спецификация';
												|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
												|it = 'Specifica di risorse';
												|pl = 'Specyfikacja';
												|tr = 'Ürün reçetesi'"));
		Parameters.Insert("TypeDescription", New TypeDescription("CatalogRef.BillsOfMaterials"));
		
	Else
		
		TypeDescription = New TypeDescription("DocumentRef.ProductionStage2_2, DocumentRef.ProductionOrder2_2, CatalogRef.BillsOfMaterials");
		Parameters.Insert("PageHeader", NStr("vi = 'Đối tượng tính giá thành';
											|ru = 'Объекты калькуляции';
											|en = 'Cost objects'; fa = 'اشیای بهای تمام‌شده';
											|it = 'Oggetti del calcolo';
											|pl = 'Obiekty kalkulacji';
											|tr = 'Maliyet nesneleri'"));
		Parameters.Insert("ColumnTitle", NStr("vi = 'Đối tượng tính giá thành';
												|ru = 'Объект калькуляции';
												|en = 'Cost object'; fa = 'موضوع بها';
												|it = 'Oggetto di calcolo';
												|pl = 'Obiekt kalkulacji';
												|tr = 'Maliyet nesnesi'"));
		Parameters.Insert("TypeDescription", TypeDescription);
		
	EndIf;
	
	Return Parameters;
	
EndFunction

&AtClient
Procedure CostObjectsObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.CostObjects.CurrentData;
	If Not OrderCosting Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("Products", CurrentData.Products);
	FormParameters.Insert("Characteristic", CurrentData.Characteristic);
	FormParameters.Insert("Purpose", CurrentData.Purpose);
	FormParameters.Insert("Department", Object.ProductionDispatcherBusinessUnit);
	
	OpenForm("Document.StandardCosting2_2.Form.SelectionFormOfProductionOrders", FormParameters, Items.CostObjectsObject);
	
EndProcedure

&AtClient
Procedure ControlOfNeedsCalculation()
	
	If Not Object.Posted Then
		
		Items.CalculationOfDemandForMaterials.CurrentPage = Items.PageIsNotCalculated;
		DetachIdleHandler("ControlOfNeedsCalculation");
		Return;
		
	EndIf;
	
	CalculationResult2 = CalculationResultOfCalculation(Object.Ref);
	
	If CalculationResult2.State = PredefinedValue("Enum.StatesOfStandardCostEstimateCalculation.CalculationError") Then
		
		Items.CalculationOfDemandForMaterials.CurrentPage = Items.PageIsNotCalculatedErrorsOccurred;
		DetachIdleHandler("ControlOfNeedsCalculation");
		
	ElsIf CalculationResult2.State = PredefinedValue("Enum.StatesOfStandardCostEstimateCalculation.Calculated") Then
		
		Items.CalculationOfDemandForMaterials.CurrentPage = Items.PageIsCalculated;
		DetachIdleHandler("ControlOfNeedsCalculation");
		
	ElsIf CalculationResult2.State = PredefinedValue("Enum.StatesOfStandardCostEstimateCalculation.CalculateWithErrors") Then
		
		Items.CalculationOfDemandForMaterials.CurrentPage = Items.PageIsCalculatedWithErrors;		
		DetachIdleHandler("ControlOfNeedsCalculation");
		
	Else
		Items.CalculationOfDemandForMaterials.CurrentPage = Items.CalculatingPage;	
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CalculationResultOfCalculation(StandardCostEstimate)
	
	CalculationResult2 = New Structure("State, ThereAreFormulas", "", False);
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	StatesOfStandardCostEstimates.State
		|FROM
		|	InformationRegister.StatesOfStandardCostEstimates AS StatesOfStandardCostEstimates
		|WHERE
		|	StatesOfStandardCostEstimates.StandardCostEstimate = &StandardCostEstimate";
	
	Query.SetParameter("StandardCostEstimate", StandardCostEstimate);
	
	If Query.Execute().IsEmpty() Then
		
		CalculationResult2.State = Enums.StatesOfStandardCostEstimateCalculation.NotCalculated;
		Return CalculationResult2;
		
	EndIf;
	
	CalculationResult2.State =  Query.Execute().Unload()[0].State;
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	NestedQuery.BillOfMaterials AS BillOfMaterials
		|FROM
		|	(SELECT
		|		MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM AS BillOfMaterials
		|	FROM
		|		InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		|	WHERE
		|		MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate = &StandardCostEstimate
		|		AND VALUETYPE(MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM) = TYPE(Catalog.BillsOfMaterials)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM
		|	FROM
		|		InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		|	WHERE
		|		MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate = &StandardCostEstimate
		|		AND VALUETYPE(MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM) = TYPE(Catalog.BillsOfMaterials)) AS NestedQuery
		|		INNER JOIN Catalog.BillsOfMaterials AS BillsOfMaterials
		|		ON NestedQuery.BillOfMaterials = BillsOfMaterials.Ref
		|WHERE
		|	BillsOfMaterials.ContainsResourcesParametrization";
	
	Query.SetParameter("StandardCostEstimate", StandardCostEstimate);
	
	CalculationResult2.ThereAreFormulas = Not Query.Execute().IsEmpty();
	
	Return CalculationResult2;
	
EndFunction

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
