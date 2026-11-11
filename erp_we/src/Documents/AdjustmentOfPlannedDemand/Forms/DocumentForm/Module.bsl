#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Parameters.Property("FillingData") Then
		
		FillingData = Parameters.FillingData;
		FillPropertyValues(Object, FillingData);
		
		If FillingData.Property("Products") Then
			NewRow = Object.DecreasedDemands.Add();
			NewRow.Products = FillingData.Products;
			NewRow.Characteristic = FillingData.Characteristic;
			NewRow.Purpose = FillingData.Purpose;
			NewRow.Count = FillingData.Count;
			NewRow.NumberOfPackages = FillingData.Count;
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	Items.GroupPages.CurrentPage = Items.PageAdjustmentOfDemand;
	
	SetAvailabilityOfClipboardCommands(ThisForm, Not Common.EmptyClipboard("Rows"));
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// The end of the standard subsystem.Versioning of objects
	//
	// Standard subsystems.Features
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// End StandardSubsystems.Properties

	SetPresentationOfFoundationDocument();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations 	
	HyperlinkParameters = FilesOperations.FilesHyperlink(); 	
	HyperlinkParameters.Location = "CommandBar"; 	
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters); 	
	// End StandardSubsystems.FilesOperations
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
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

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommands(ThisForm, True);
	EndIf;
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetails();
	
	FillInServiceDetailsOfTableParts();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	If Not Object.AdjustmentInputModeMultiline
		And PlanningProcessManagement
		And FillInByShortage Then 
		AdjustmentStructure = New Structure();
		AdjustmentStructure.Insert("Plan", Object.Plan);
		AdjustmentStructure.Insert("Scenario", Object.Scenario);
		AdjustmentStructure.Insert("PlanProfile", Object.PlanProfile);
		AdjustmentStructure.Insert("Period", Object.Period);
		AdjustmentStructure.Insert("Products", Products);
		AdjustmentStructure.Insert("Characteristic", Characteristic);
		AdjustmentStructure.Insert("Purpose", Purpose);
		AdjustmentStructure.Insert("NomenclatureAdjustment", NomenclatureAdjustment);
		AdjustmentStructure.Insert("FeatureAdjustment", FeatureAdjustment);
		AdjustmentStructure.Insert("PurposeAdjustment", PurposeAdjustment);
		AdjustmentStructure.Insert("ForAdjustment", ForAdjustment);
		AdjustmentStructure.Insert("ToTheAdjustmentOfTheAdjustment", ToTheAdjustmentOfTheAdjustment);
		AdjustmentStructure.Insert("ToSupply", ToSupply);
		AdjustmentStructure.Insert("ToEnsureTheAdjustment", -ToEnsureTheAdjustment);
	
		Notify("Write_AdjustmentOfPlannedDemand", AdjustmentStructure, Object.Ref);
	EndIf;
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not Object.AdjustmentInputModeMultiline Then
		FillInTSNeedsAdjustments(ThisForm, Object);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
		
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Object.AdjustmentInputModeMultiline Then
		
		NotCheckedAttributeArray.Add("Characteristic");
		NotCheckedAttributeArray.Add("FeatureAdjustment");
		
	Else
		
		If Not ItemVariantsAreUsed Or ValueIsFilled(Characteristic) Then
			NotCheckedAttributeArray.Add("Characteristic");
		EndIf;
		
		If Not ItemVariantsAreUsedAdjusting Or ValueIsFilled(FeatureAdjustment) Then
			NotCheckedAttributeArray.Add("FeatureAdjustment");
		EndIf;
		
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ScenarioOnChange(Item)
	ScenarioWhenChangingOnServer();
EndProcedure

&AtServer
Procedure ScenarioWhenChangingOnServer()
	
	ScriptDetails = Common.ObjectAttributesValues(Object.Scenario, "PlanningByAssignments, PlanningProcessManagement");
	PlanningByAssignments = ScriptDetails.PlanningByAssignments;
	PlanningProcessManagement =  ScriptDetails.PlanningProcessManagement;
		
	VisibilityManagement(ThisForm);
	
EndProcedure

&AtClient
Procedure BaseDocumentPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Object.Plan) Then
		
		ShowValue(Undefined, Object.Plan);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AdjustmentInputModeOnChange(Item)
	
	AdjustmentInputModeOnChangeServer();
	
EndProcedure

&AtClient
Procedure ProductsOnChange(Item)
	
	ProductsOnChangeServer();
	
EndProcedure

&AtClient
Procedure CharacteristicOnChange(Item)
	NeedWhenChangingOnServer();
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)
	NeedWhenChangingOnServer();
EndProcedure

&AtClient
Procedure NomenclatureAdjustmentOnChange(Item)
	
	NomenclatureAdjustmentOnChangeServer();
	
EndProcedure

&AtClient
Procedure FeatureAdjustmentOnChange(Item)
	CorrectionWhenChangingOnServer();
EndProcedure

&AtClient
Procedure PurposeAdjustmentOnChange(Item)
	CorrectionWhenChangingOnServer();
EndProcedure

&AtClient
Procedure ToReplaceOnChange(Item)
	
	If Not PlanningProcessManagement Then
		Return;
	EndIf;
	
	ToSupply = Demand - ForAdjustment;
EndProcedure

&AtClient
Procedure ToSupply_OnChange(Item)
	
	ForAdjustment = Demand - ToSupply;
EndProcedure

&AtClient
Procedure ToTheAdjustmentOfTheAdjustmentOnChange(Item)
	
	If Not PlanningProcessManagement Then
		Return;
	EndIf;
	
	ToEnsureTheAdjustment = Balance - ToTheAdjustmentOfTheAdjustment;
	
EndProcedure

&AtClient
Procedure ToEnsureTheAdjustmentOnChange(Item)
	
	ToTheAdjustmentOfTheAdjustment = Balance - ToEnsureTheAdjustment;
	
EndProcedure

#EndRegion

#Region EventHandlersOfTableElementsIncreaseInNeeds

&AtClient
Procedure IncreasedDemandProductsOnChange(Item)
	
	CurrentRow = Items.IncreasedDemand.CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingProducts(StructureOfActions, "IncreasedDemand");
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure IncreasedDemandNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.IncreasedDemand.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure IncreasedDemandPackageOnChange(Item)
	
	CurrentData = Items.IncreasedDemand.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure IncreasingTheNeedToInsertRows(Command)
	
	GetLinesFromClipboard("IncreasedDemand");
	
EndProcedure

&AtClient
Procedure IncreasingTheNeedToCopyLines(Command)
	
	CopyTSLines("IncreasedDemand");
	
EndProcedure

#EndRegion

#Region EventHandlersOfTableElementsReducingNeeds

&AtClient
Procedure DecreasedDemandsProductsOnChange(Item)
	
	CurrentRow = Items.DecreasedDemands.CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingProducts(StructureOfActions, "DecreasedDemands");
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure DecreasedDemandsNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.DecreasedDemands.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure DecreasedDemandsPackageOnChange(Item)
	
	CurrentData = Items.DecreasedDemands.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure DecreasingOfDemandInsertStrings(Command)
	
	GetLinesFromClipboard("DecreasedDemands");
	
EndProcedure

&AtClient
Procedure DecreasingOfDemandCopyStrings(Command)
	
	CopyTSLines("DecreasedDemands");
	
EndProcedure

#EndRegion

#Region EventHandlersForPageElementsAdvanced

&AtClient
Procedure CommentOnChange(Item)
	
	ConfigureDependentFormElements(ThisForm, "Comment");
	
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
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

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

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure MoveTo_(Command)
	ToTheAdjustmentOfTheAdjustment = ForAdjustment;
	
	If Not PlanningProcessManagement Then
		Return;
	EndIf;
	
	ToEnsureTheAdjustment = Balance - ToTheAdjustmentOfTheAdjustment;	
	ToSupply = Demand - ForAdjustment;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	#Region StandardAppearance
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "IncreasedDemandCharacteristic",
																		     "Object.IncreasedDemand.ItemVariantsAreUsed");
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "IncreasedDemandProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.IncreasedDemand.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
																   
	#EndRegion
	
	#Region StandardAppearance
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "DecreasedDemandsCharacteristic",
																		     "Object.DecreasedDemands.ItemVariantsAreUsed");
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "DecreasedDemandsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.DecreasedDemands.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
																   
	#EndRegion
	
	//

EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	
	AdjustmentInputMode = Object.AdjustmentInputModeMultiline;
	
	If Not Object.AdjustmentInputModeMultiline Then
		FillInDetailsOfAdjustment(ThisForm);
		
		FillInServiceDetails();
		
		NeedWhenChangingOnServer();
		CorrectionWhenChangingOnServer();
	EndIf;
	
	ScriptDetails = Common.ObjectAttributesValues(Object.Scenario, "PlanningByAssignments, PlanningProcessManagement");
	PlanningByAssignments = ScriptDetails.PlanningByAssignments;
	PlanningProcessManagement =  ScriptDetails.PlanningProcessManagement;
	
	If ValueIsFilled(Object.Plan) Then
		SetPrivilegedMode(True);
		FillInByShortage = Common.ObjectAttributeValue(Object.Plan, "FillInByShortage");
		SetPrivilegedMode(False);
	Else
		FillInByShortage = False;
	EndIf;
	
	FillInServiceDetailsOfTableParts();
	
	VisibilityManagement(ThisForm);
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure SetPresentationOfFoundationDocument()
	
	BaseDocumentPresentation = Object.Plan;
	Items.BaseDocumentPresentation.TextColor = StyleColors.HyperlinkColor;
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Comment")
		Or Initialize Then
		
		Items.AdditionalPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTableParts()
	
	If Not Object.AdjustmentInputModeMultiline Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	If UseItemVariants Then
		
		StructureOfActions.Insert(
			"FillInFeatureAttribute",
			New Structure("Products", "ItemVariantsAreUsed"));
		
	EndIf;
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.IncreasedDemand, StructureOfActions);
		
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.DecreasedDemands, StructureOfActions)
EndProcedure

&AtServer
Procedure FillInServiceDetails(Adjusting = Undefined)
	
	If Object.AdjustmentInputModeMultiline
	 Or Not UseItemVariants Then
		Return;
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	
	If Adjusting = Undefined Then
		
		DataTable = New ValueTable;
		DataTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		DataTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		DataTable.Columns.Add("ItemVariantsAreUsed", New TypeDescription("Boolean"));
		DataTable.Columns.Add("FieldNameItemVariant", Common.StringTypeDetails(27));
		DataTable.Columns.Add("FieldNameItemVariantsAreUsed", Common.StringTypeDetails(39));
		
		// DecreasedDemands
		TableRow = DataTable.Add();
		TableRow.Products                      = Products;
		TableRow.Characteristic                    = Characteristic;
		TableRow.FieldNameItemVariant             = "Characteristic";
		TableRow.FieldNameItemVariantsAreUsed = "ItemVariantsAreUsed";
		
		// IncreasedDemand
		TableRow = DataTable.Add();
		TableRow.Products                      = NomenclatureAdjustment;
		TableRow.Characteristic                    = FeatureAdjustment;
		TableRow.FieldNameItemVariant             = "FeatureAdjustment";
		TableRow.FieldNameItemVariantsAreUsed = "ItemVariantsAreUsedAdjusting";
		
		BatchProcessingOfTablePartServer.TreatTS(DataTable, StructureOfActions, Undefined);
		
		For Each TableRow In DataTable Do
			
			FieldNameItemVariant             = TableRow.FieldNameItemVariant;
			FieldNameItemVariantsAreUsed = TableRow.FieldNameItemVariantsAreUsed;
			
			ThisObject[FieldNameItemVariantsAreUsed] = TableRow.ItemVariantsAreUsed;
			
			ElementCharacteristic = Items[FieldNameItemVariant];
			
			If TableRow.ItemVariantsAreUsed Then
				ElementCharacteristic.MarkIncomplete = True;
				ElementCharacteristic.Enabled           = True;
				ElementCharacteristic.InputHint        = "";
			Else
				ElementCharacteristic.MarkIncomplete = False;
				ElementCharacteristic.Enabled           = False;
				ElementCharacteristic.InputHint        = NStr("vi = '<không sử dụng đặc tính>';
																|ru = '<характеристики не используются>';
																|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
																|it = '<le caratteristiche non vengono usate>';
																|pl = '<charakterystyki nie dotyczą>';
																|tr = '<varyantlar kullanılmamaktadır>'");
			EndIf;
			
		EndDo;
		
	Else
		
		If Adjusting Then
			FieldNameItemVariant             = "FeatureAdjustment";
			NameOfProductsField               = "NomenclatureAdjustment";
			FieldNameItemVariantsAreUsed = "ItemVariantsAreUsedAdjusting";
		Else
			FieldNameItemVariant             = "Characteristic";
			NameOfProductsField               = "Products";
			FieldNameItemVariantsAreUsed = "ItemVariantsAreUsed";
		EndIf;
		
		StructureOfActions.CheckCharacteristicsByOwner = ThisObject[FieldNameItemVariant];
		
		CurRowStructure = New Structure;
		CurRowStructure.Insert("Products",   ThisObject[NameOfProductsField]);
		CurRowStructure.Insert("Characteristic", ThisObject[FieldNameItemVariant]);
		CurRowStructure.Insert("ItemVariantsAreUsed");
		
		BatchProcessingOfTablePartServer.ProcessTSString(CurRowStructure, StructureOfActions, Undefined);
		
		ThisObject[FieldNameItemVariant]             = CurRowStructure.Characteristic;
		ThisObject[FieldNameItemVariantsAreUsed] = CurRowStructure.ItemVariantsAreUsed;
		
		ElementCharacteristic = Items[FieldNameItemVariant];
		
		If CurRowStructure.ItemVariantsAreUsed Then
			ElementCharacteristic.MarkIncomplete = True;
			ElementCharacteristic.Enabled           = True;
			ElementCharacteristic.InputHint        = "";
		Else
			ElementCharacteristic.MarkIncomplete = False;
			ElementCharacteristic.Enabled           = False;
			ElementCharacteristic.InputHint        = NStr("vi = '<không sử dụng đặc tính>';
															|ru = '<характеристики не используются>';
															|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
															|it = '<le caratteristiche non vengono usate>';
															|pl = '<charakterystyki nie dotyczą>';
															|tr = '<varyantlar kullanılmamaktadır>'");
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingProducts(StructureOfActions, TSName)

	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillPackageByOwner");
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName", "DocumentForm", TSName));
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits());
	
EndProcedure

&AtClientAtServerNoContext
Function ParametersForRecalculatingNumberOfUnits()

	RecalculationParameters = New Structure("MustBeRoundOff", False);
	Return RecalculationParameters;
	
EndFunction

&AtClientAtServerNoContext
Procedure VisibilityManagement(Form)
	
	Form.Items.Demand.Visible = Form.PlanningProcessManagement;
	Form.Items.ToSupply_.Visible = Form.PlanningProcessManagement;
	Form.Items.Balance.Visible = Form.PlanningProcessManagement;
	Form.Items.ToEnsureTheAdjustment.Visible = Form.PlanningProcessManagement;
	Form.Items.ProductsUnitOfMeasure.Visible = Form.PlanningProcessManagement;
	Form.Items.ProductsUnitOfMeasure2.Visible = Form.PlanningProcessManagement;
	Form.Items.NomenclatureAdjustmentUnitOfMeasure.Visible = Form.PlanningProcessManagement;
	Form.Items.NomenclatureAdjustmentUnitOfMeasure2.Visible = Form.PlanningProcessManagement;
	
	Form.Items.Purpose.Visible = Form.PlanningByAssignments;
	Form.Items.PurposeAdjustment.Visible = Form.PlanningByAssignments;
	Form.Items.DecreasedDemandsPurpose.Visible = Form.PlanningByAssignments;
	Form.Items.IncreasedDemandPurpose.Visible = Form.PlanningByAssignments;
	
	Form.Items.Scenario.ReadOnly = ValueIsFilled(Form.Object.Plan);
	Form.Items.PlanProfile.ReadOnly = ValueIsFilled(Form.Object.Plan);
	
	Form.Items.GroupSimplifiedMode.Visible = Form.AdjustmentInputMode = 0;
	Form.Items.GroupDecreasedDemands.Visible = Form.AdjustmentInputMode = 1;
	Form.Items.GroupIncreasingNeeds.Visible = Form.AdjustmentInputMode = 1;
	
	Form.Items.Decoration1.Visible = Form.Object.Status = PredefinedValue("Enum.StatusesOfPlanAdjustments.RolledBack");
	
EndProcedure

#Region WorkingWithClipboard

&AtClient
Procedure CopyTSLines(TSName)

	FormTable = Items[TSName];
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(FormTable) Then
    	CopyLinesOnServer(TSName);
    	ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(FormTable.SelectedRows.Count());
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
	
	FilterParameters = New Map;
  	FilterParameters.Insert("Products.ItemsType", ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False));
  
  	Columns = "Products,Characteristic,Package,NumberOfPackages,Count,Price";
  
  	LinesFromBuffer = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	AddActionsToStructureWhenChangingProducts(StructureOfActions, TSName);
	
	RowsToProcess = New Array();
	TabularSection = Object[TSName]; // FormDataCollection -   
	
	For Each LineFromBuffer In LinesFromBuffer Do
		
		CurrentRow = TabularSection.Add();
		
		FillPropertyValues(CurrentRow, LineFromBuffer, "Products,Characteristic,Package,NumberOfPackages");
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		TabularSection);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfClipboardCommands(Form, AttributeAvailability)
	
	ItemArray = New Array();
	ItemArray.Add("DecreasedDemandsDecreasingOfDemandInsertStrings");
	ItemArray.Add("DecreasedDemandsContextMenuDecreasingOfDemandInsertStrings");
	ItemArray.Add("IncreasedDemandIncreasingTheNeedToInsertRows");
	ItemArray.Add("IncreasedDemandContextMenuIncreasingTheNeedToInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Form.Items, ItemArray, "Enabled", AttributeAvailability);
	
EndProcedure

#EndRegion

// StandardSubsystems.Properties 

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

&AtClientAtServerNoContext
Procedure FillInDetailsOfAdjustment(Form)
	
	If Form.Object.DecreasedDemands.Count() > 0 Then
		StringReductionOfNeeds = Form.Object.DecreasedDemands[0];
		Form.Products = StringReductionOfNeeds.Products;
		Form.Characteristic = StringReductionOfNeeds.Characteristic;
		Form.Purpose = StringReductionOfNeeds.Purpose;
		Form.ForAdjustment = StringReductionOfNeeds.Count;
	EndIf;
	
	If Form.Object.IncreasedDemand.Count() > 0 Then
		StringIncreaseNeeds = Form.Object.IncreasedDemand[0];
		Form.NomenclatureAdjustment = StringIncreaseNeeds.Products;
		Form.FeatureAdjustment = StringIncreaseNeeds.Characteristic;
		Form.PurposeAdjustment = StringIncreaseNeeds.Purpose;
		Form.ToTheAdjustmentOfTheAdjustment = StringIncreaseNeeds.Count;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInTSNeedsAdjustments(Form, CurrentObject)
	
	CurrentObject.DecreasedDemands.Clear();
	CurrentObject.IncreasedDemand.Clear();
	
	StringReductionOfNeeds = CurrentObject.DecreasedDemands.Add();
	StringReductionOfNeeds.Products = Form.Products;
	StringReductionOfNeeds.Characteristic = Form.Characteristic;
	StringReductionOfNeeds.Purpose = Form.Purpose;
	StringReductionOfNeeds.Count = Form.ForAdjustment;
	StringReductionOfNeeds.NumberOfPackages = Form.ForAdjustment;
	
	If ValueIsFilled(Form.NomenclatureAdjustment) Then
		StringIncreaseNeeds = CurrentObject.IncreasedDemand.Add();
		StringIncreaseNeeds.Products = Form.NomenclatureAdjustment;
		StringIncreaseNeeds.Characteristic = Form.FeatureAdjustment;
		StringIncreaseNeeds.Purpose = Form.PurposeAdjustment;
		StringIncreaseNeeds.Count = Form.ToTheAdjustmentOfTheAdjustment;
		StringIncreaseNeeds.NumberOfPackages = Form.ToTheAdjustmentOfTheAdjustment;
	EndIf;
	
EndProcedure

&AtServer
Function GetInitialRemainderOfStage(Scenario, PlanProfile, Period, Products, Characteristic, Purpose) 
	Query = New Query();
	Query.Text = 
	"SELECT
	|	MAX(CalculationOfPlanShortagesByStages.PlanningPeriod) AS PlanningPeriod
	|INTO MaximumDeficitCalculationPeriod
	|FROM
	|	InformationRegister.CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
	|WHERE
	|	CalculationOfPlanShortagesByStages.Scenario = &Scenario
	|	AND CalculationOfPlanShortagesByStages.PlanProfile = &PlanProfile
	|	AND CalculationOfPlanShortagesByStages.PlanningPeriod <= &PlanningPeriod
	|	AND CalculationOfPlanShortagesByStages.Products = &Products
	|	AND CalculationOfPlanShortagesByStages.Characteristic = &Characteristic
	|	AND CalculationOfPlanShortagesByStages.Purpose = &Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationOfPlanShortagesByStages.OpeningBalance AS OpeningBalance
	|FROM
	|	InformationRegister.CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
	|		INNER JOIN MaximumDeficitCalculationPeriod AS MaximumDeficitCalculationPeriod
	|		ON CalculationOfPlanShortagesByStages.PlanningPeriod = MaximumDeficitCalculationPeriod.PlanningPeriod
	|WHERE
	|	CalculationOfPlanShortagesByStages.Scenario = &Scenario
	|	AND CalculationOfPlanShortagesByStages.PlanProfile = &PlanProfile
	|	AND CalculationOfPlanShortagesByStages.PlanningPeriod <= &PlanningPeriod
	|	AND CalculationOfPlanShortagesByStages.Products = &Products
	|	AND CalculationOfPlanShortagesByStages.Characteristic = &Characteristic
	|	AND CalculationOfPlanShortagesByStages.Purpose = &Purpose";
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("Purpose", Purpose);
	Query.SetParameter("Scenario", Scenario);
	Query.SetParameter("PlanProfile", PlanProfile);
	Query.SetParameter("PlanningPeriod", Period);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.OpeningBalance;
	Else
		Return 0;
	EndIf;
	
EndFunction

&AtServer
Function GetOpeningBalance(Scenario, PlanProfile, Period, Products, Characteristic, Purpose) 
	Query = New Query();
	Query.Text = 
	"SELECT
	|	MAX(CalculationOfPlanShortagesByStages.PlanningPeriod) AS PlanningPeriod
	|INTO MaximumDeficitCalculationPeriod
	|FROM
	|	InformationRegister.CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
	|WHERE
	|	CalculationOfPlanShortagesByStages.Scenario = &Scenario
	|	AND CalculationOfPlanShortagesByStages.PlanProfile = &PlanProfile
	|	AND CalculationOfPlanShortagesByStages.PlanningPeriod <= &PlanningPeriod
	|	AND CalculationOfPlanShortagesByStages.Products = &Products
	|	AND CalculationOfPlanShortagesByStages.Characteristic = &Characteristic
	|	AND CalculationOfPlanShortagesByStages.Purpose = &Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationOfPlanShortagesByStages.OpeningBalance AS OpeningBalance
	|FROM
	|	InformationRegister.CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
	|		INNER JOIN MaximumDeficitCalculationPeriod AS MaximumDeficitCalculationPeriod
	|		ON CalculationOfPlanShortagesByStages.PlanningPeriod = MaximumDeficitCalculationPeriod.PlanningPeriod
	|WHERE
	|	CalculationOfPlanShortagesByStages.Scenario = &Scenario
	|	AND CalculationOfPlanShortagesByStages.PlanProfile = &PlanProfile
	|	AND CalculationOfPlanShortagesByStages.PlanningPeriod <= &PlanningPeriod
	|	AND CalculationOfPlanShortagesByStages.Products = &Products
	|	AND CalculationOfPlanShortagesByStages.Characteristic = &Characteristic
	|	AND CalculationOfPlanShortagesByStages.Purpose = &Purpose";
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("Purpose", Purpose);
	Query.SetParameter("Scenario", Scenario);
	Query.SetParameter("PlanProfile", Catalogs.PlanProfiles.EmptyRef());
	Query.SetParameter("PlanningPeriod", Period);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.OpeningBalance;
	Else
		Return 0;
	EndIf;
	
EndFunction

&AtServer
Procedure NeedWhenChangingOnServer()
	Demand = -GetInitialRemainderOfStage(Object.Scenario,
		Object.PlanProfile,
		Object.Period,
		Products,
		Characteristic,
		Purpose);
	
	ToSupply = Demand - ForAdjustment;
EndProcedure

&AtServer
Procedure CorrectionWhenChangingOnServer()
	Balance = GetOpeningBalance(Object.Scenario,
		Object.PlanProfile,
		Object.Period,
		NomenclatureAdjustment,
		FeatureAdjustment,
		PurposeAdjustment);
	ToEnsureTheAdjustment = Balance - ToTheAdjustmentOfTheAdjustment;
EndProcedure

&AtServer
Procedure ProductsOnChangeServer()
	
	FillInServiceDetails(False);
	
	NeedWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure NomenclatureAdjustmentOnChangeServer()
	
	FillInServiceDetails(True);
	
	CorrectionWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure AdjustmentInputModeOnChangeServer()
	
	Object.AdjustmentInputModeMultiline = AdjustmentInputMode;
	
	If Object.AdjustmentInputModeMultiline Then
		
		FillInTSNeedsAdjustments(ThisObject, Object);
		
		FillInServiceDetailsOfTableParts();
		
	Else
		
		FillInDetailsOfAdjustment(ThisObject);
		
		FillInServiceDetails();
		
		NeedWhenChangingOnServer();
		CorrectionWhenChangingOnServer();
		
	EndIf;
	
	VisibilityManagement(ThisObject);
	
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
