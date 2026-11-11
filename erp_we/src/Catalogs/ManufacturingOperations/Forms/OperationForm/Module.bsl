#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not SynchronousLoad Then
		NotCheckedAttributeArray.Add("WorkTimeOnSynchronousLoad");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	// Checking the details of the type of operation
	LineNumber = 1;
	
	For Each String In AddAttributes Do
		
		If String.ValueMin > String.ValueMax And String.ValueMax <> 0 Then
			
			MessageText = StrTemplate(NStr("vi = 'Giá trị tối thiểu của mục tin ""%1"" vượt quá giá trị tối đa';
											|ru = 'Минимальное значение реквизита ""%1"" превышает максимальное значение';
											|en = 'The minimum value of the ""%1"" attribute exceeds the maximum value'; fa = 'The minimum value of the ""%1"" attribute exceeds the maximum value';
											|it = 'Il valore minimo del requisito ""%1"" supera quello massimo';
											|pl = 'Minimalna wartość atrybutu ""%1"" przekracza maksymalną wartość';
											|tr = '""%1"" özniteliğinin minimum değeri, maksimum değeri aşmaktadır'"),
				String.Title);
				
			Path = CommonClientServer.PathToTabularSection("AddAttributes", LineNumber, "ValueMin");
			
			Common.MessageToUser(MessageText,, Path,, Cancel);
			
		EndIf;
		
		LineNumber = LineNumber + 1;
		
	EndDo;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ProductionProcessEditorClientServer.UploadOperationTypeStandards(CurrentObject, AddAttributes);
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ManufacturingOperations", WriteParameters);

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_SetupOptions" Or EventName = "Write_WorkCenterTypes" Then
		ReadDetailsOfWorkCenter();
	EndIf;
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource <> Undefined
		And (ChoiceSource.FormName = "Catalog.ManufacturingOperationClassifier.Form.ListForm") Then
		
		Modified = True;
		
		ProcessingSelectionOfOperationByClassifier(ValueSelected)
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "GroupAdditionalAttributes"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure ProductionAreaOnChange(Item)
	PlotWhenChangedOnServer();
EndProcedure

&AtClient
Procedure WorkCenterOnChange(Item)
	
	WorkCenterWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure SetupSettingsOnChange(Item)
	
	SetupOptionForChangesOnServer();
	
EndProcedure

&AtClient
Procedure SetupSettingsStartChoice(Item, ChoiceData, StandardProcessing)
	
	If ValueIsFilled(Object.WorkCenter) Then
		
		StandardProcessing = False;
		
		ProductionProcessEditorClient.OpenSetupOptionSelectionForm(
			Object.WorkCenter,
			Object.SetupSettings,
			Item);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CountOnChange(Item)
	
	Items.UnitOfMeasure.InputHint = ProductionManagementClientServer.PresentationOfUnitOfOperation(
		Object.UnitOfMeasure, Object.Count);
	ProductionProcessEditorClientServer.FillInUnitOfMeasurementOfTransferBatch(
		Object, UnitOfMeasureOfTransferBatch);
	
EndProcedure

&AtClient
Procedure UnitOfMeasureOnChange(Item)
	
	ProductionProcessEditorClientServer.FillInUnitOfMeasurementOfTransferBatch(
		Object, UnitOfMeasureOfTransferBatch);
	
EndProcedure

&AtClient
Procedure TransferLotOnChange(Item)
	
	ProductionProcessEditorClientServer.FillInUnitOfMeasurementOfTransferBatch(
		Object, UnitOfMeasureOfTransferBatch);
	
EndProcedure

&AtClient
Procedure ClassifierOfTechnologicalOperationsChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	ProcessingSelectionOfOperationByClassifier(ValueSelected);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure OperationKindOnChange(Item)
	
	KindOfOperationWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure RoutePresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "#OpenRoute" Then 
		
		ShowValue(, Route);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DescriptionAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Not ItemsAvailability
		Or Not StoreOperationsInBillsOfMaterials Then
		Return;
	EndIf;
	
	ProductionProcessEditorClient.OperationOnClassifierAutoSelection(Text, ChoiceData, StandardProcessing, "Description");
	
EndProcedure

&AtClient
Procedure DescriptionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	ProcessingSelectionOfOperationByClassifier(ValueSelected);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure DescriptionStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Not ItemsAvailability
		Or Not StoreOperationsInBillsOfMaterials Then
		Return;
	EndIf;
	
	ProductionProcessEditorClient.OpenFormForSelectingOperationsByClassifier(ThisObject, Object);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAddAttributes

&AtClient
Procedure AddAttributesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "AddAttributesTitle" Then
		
		StandardProcessing = False;
	
		ShowValue(, Items.AddAttributes.CurrentData.Property);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddAttributesOnStartEdit(Item, NewRow, Copy)
	
	ProductionProcessEditorClient.AdditionalDetailsSetFormatForEditingStandards(ThisObject);
	
EndProcedure

&AtClient
Procedure AddAttributesValueMinOnChange(Item)
	
	Modified = True;
	
	CurrentData = Items.AddAttributes.CurrentData;
	
	ProductionProcessEditorClient.AdditionalValueOfStandardWhenChanging(CurrentData, "ValueMin");
	
EndProcedure

&AtClient
Procedure AddAttributesValueMaxOnChange(Item)
	
	Modified = True;
	
	CurrentData = Items.AddAttributes.CurrentData;
	
	ProductionProcessEditorClient.AdditionalValueOfStandardWhenChanging(CurrentData, "ValueMax");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region StandardSubsystems_Properties

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

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	// Initialization of service details.
	If TypeOf(Object.Owner) = Type("CatalogRef.ProductionStages") Then
		StatusDetails = "Owner.Status";
	Else
		StatusDetails = "Status";
	EndIf;
	
	SetPrivilegedMode(True);
	
	ConfigureByDivision();
	
	OwnerStatus = Common.ObjectAttributeValue(Object.Owner, StatusDetails);
	ItemsAvailability = ProductionProcessEditor.DetermineAvailabilityOfOperationElements(OwnerStatus);
	
	FillInDetailsOfOperationRoute();
	
	DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(Department);
	
	SubsystemSettings = ProductionServer.SubsystemSettingsProduction();
	ProductionIsUsed21 = SubsystemSettings.ProductionIsUsed21;
	ProductionIsUsed22 = SubsystemSettings.ProductionIsUsed22;
	
	StoreOperationsInBillsOfMaterials = GetFunctionalOption("StoreOperationsInBillsOfMaterials");
	
	ProductionProcessEditor.ReadDetailsOfWorkCenter(Object, ThisObject);
	ProductionProcessEditor.ConfigureVisibilityAvailabilityOfOperationElements(Object, ThisObject, DivisionParameters);
	ProductionProcessEditor.ConfigureSettingsForSelectingWorkCenters(Object, ThisObject, Department);
	ProductionProcessEditor.ConfigureSiteSelectionParameters(Object, ThisObject, Department);
	ProductionProcessEditor.ReadTransactionTypeDetails(Object, ThisObject);
	
	SetPrivilegedMode(False);
	
	If Object.ContainsNestedRoute Then
		// The type of operation is being changed
		Object.ContainsNestedRoute = False;
		Object.WorkCenter = Undefined;
		Object.ProductionArea = Undefined;
		Object.SetupSettings = Undefined;
		Object.OperationKind = Undefined;
		Object.TimePerPiece = 0;
		Object.SetupTime = 0;
		Object.Load = 0;
		Object.Continuous = False;
		Object.Repeatable = False;
		Object.Skippable = False;
		Object.AuxiliaryWorkCenters.Clear();
		Object.OperationKindStandards.Clear();
		Modified = True;
	EndIf;
	
	Items.ProductionArea.InputHint = ProductionProcessEditor.PlotPresentation(Object, Items.ProductionArea.Visible);
	
	Items.UnitOfMeasure.InputHint = ProductionManagementClientServer.PresentationOfUnitOfOperation(
		Object.UnitOfMeasure, Object.Count);
	ProductionProcessEditorClientServer.FillInUnitOfMeasurementOfTransferBatch(
		Object, UnitOfMeasureOfTransferBatch);
	
	OperationKind = Object.OperationKind;
	
	Items.Description.ChoiceButton = StoreOperationsInBillsOfMaterials;
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfOperationByClassifierATServer(ValueSelected)
	
	ProductionProcessEditor.ClassifierOfTechnologicalOperationsChoiceProcessing(Object, ThisObject, ValueSelected);
	
	ConfigureDependentFormElements(ThisObject, "OperationKind");
	
EndProcedure

&AtServer
Procedure KindOfOperationWhenChangingOnServer()
	
	ProductionProcessEditor.OperationKindOnChange(Object, ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "OperationKind");
	
EndProcedure

&AtServer
Procedure WorkCenterWhenChangingOnServer()
	
	ProductionProcessEditor.WorkCenterOnChange(Object, ThisObject);
	
	Items.ProductionArea.InputHint = ProductionProcessEditor.PlotPresentation(Object, Items.ProductionArea.Visible);
	
EndProcedure

&AtServer
Procedure PlotWhenChangedOnServer()
	
	ProductionProcessEditor.ProductionAreaOnChange(Object, ThisObject);
	
EndProcedure

&AtServer
Procedure ConfigureByDivision()
	
	Department = Common.ObjectAttributeValue(Object.Owner, "Department");
	
	If ValueIsFilled(Department) Then
		SetFormFunctionalOptionParameters(New Structure("Department", Department));
	Else
		SetFormFunctionalOptionParameters(New Structure("Department", Undefined));
	EndIf;
	
EndProcedure

&AtServer
Procedure SetupOptionForChangesOnServer()
	
	ProductionProcessEditor.SetupSettingsOnChange(Object, ThisObject);
	
EndProcedure

&AtServer
Procedure ReadDetailsOfWorkCenter()
	
	ProductionProcessEditor.ReadDetailsOfWorkCenter(Object, ThisObject);
	
EndProcedure

&AtServer
Procedure FillInDetailsOfOperationRoute()
	
	RouteDetails = Catalogs.ManufacturingOperations.DetailsOfOperationRoute(Object.Owner);
	
	Route              = RouteDetails.Route;
	RoutePresentation = New FormattedString(
		RouteDetails.RoutePresentation,,,,
		?(RouteDetails.RouteAvailable, "#OpenRoute", ""));
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("OperationKind")
		Or Initialize Then
			
			Items.ControlledParametersPage.Visible = ValueIsFilled(Object.OperationKind);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingSelectionOfOperationByClassifier(ValueSelected)
	
	ProcessingSelectionOfOperationByClassifierATServer(ValueSelected);
	
EndProcedure

#EndRegion

#EndRegion
