//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnCreatReadAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		ReadOnly = True;
		
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnCreatReadAtServer();
	EndIf;
	
	If RebateKindIsUsed Then
		ObjectAttributesLock.LockAttributes(ThisObject);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
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
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
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
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If RebateKindIsUsed Then
		ObjectAttributesLock.LockAttributes(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StatusOnChange(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure StatusClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure WithoutCalculationOnChange(Item)
	
	Object.BonusType = PredefinedValue("Enum.VendorRebateTypes.EmptyRef");
	Object.GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.NotUsed");
	Object.ConditionFrequency = PredefinedValue("Enum.RebatesFrequencies.EmptyRef");
	SetAvailableListOfSalesIndicators(ThisObject);
	SetAvailableListOfSalesCalculationBases(ThisObject);
	Object.ConsiderVAT = False;
	
	SetAvailableListOfParticipants(ThisObject);
	SetAvailableListOfGoods(ThisObject);
	SetAvailableListSelectionOfGoods(ThisObject);
	Object.AccrualFrequency = PredefinedValue("Enum.RebatesFrequencies.Single");
	SetAvailableListOfTimeFenceAccruals(ThisObject);
	
	Object.AllocationProcedure = RebatesClientServer.CheckResetAllocationOrder(
		Object.AllocationProcedure,
		Object.WithoutCalculation,
		Object.BonusType,
		Object.GoodsIndicator,
		Object.BaseOfCalculation);
	
	ConfigureDependentFormElements();
	
EndProcedure

&AtClient
Procedure BonusTypeOnChange(Item)
	
	BonusTypeOnChangeServer();
	
EndProcedure

&AtClient
Procedure BonusTypeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure GoodsIndicatorOnChange(Item)
	
	SetAvailableListOfSalesCalculationBases(ThisObject);
	SetAvailableListOfGoods(ThisObject);
	SetAvailableListSelectionOfGoods(ThisObject);
	
	If Object.GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.NotUsed") Then
		Object.ConditionFrequency = PredefinedValue("Enum.RebatesFrequencies.EmptyRef");
	EndIf;
	
	Object.AllocationProcedure = RebatesClientServer.CheckResetAllocationOrder(
		Object.AllocationProcedure,
		Object.WithoutCalculation,
		Object.BonusType,
		Object.GoodsIndicator,
		Object.BaseOfCalculation);
	
	SetAvailableListOfTimeFenceAccruals(ThisObject);
	
	CheckResetCustomerFulfillmentFlag(ThisObject);
	
	ConfigureDependentFormElements();
	
EndProcedure

&AtClient
Procedure ConditionFrequencyOnChange(Item)
	
	SetAvailableListOfTimeFenceAccruals(ThisObject);
	
EndProcedure

&AtClient
Procedure BaseOfCalculationOnChange(Item)
	
	If Object.BaseOfCalculation = PredefinedValue("Enum.RebateCalculationBases.RevenueBasePrices") Then
		
		Object.ConsiderVAT = False;
		
	EndIf;
	
	Object.AllocationProcedure = RebatesClientServer.CheckResetAllocationOrder(
		Object.AllocationProcedure,
		Object.WithoutCalculation,
		Object.BonusType,
		Object.GoodsIndicator,
		Object.BaseOfCalculation);
	
	SetAvailableListOfGoods(ThisObject);
	SetAvailableListSelectionOfGoods(ThisObject);
	ConfigureDependentFormElements();
	
EndProcedure

&AtClient
Procedure ContentOfGoodsOnChange(Item)
	
	SetAvailableListSelectionOfGoods(ThisObject);
	ConfigureDependentFormElements("ContentOfGoods");
	
EndProcedure

&AtClient
Procedure ProductItemPropertyEditTextChange(Item, Text, StandardProcessing)
	
	If IsBlankString(Text) Then
		
		Modified = True;
		Object.ProductItemProperty = "";
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductItemPropertyStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceList = Items.ProductItemProperty.ChoiceList;
	
	If ChoiceList.Count() = 0 Then
		Return;
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ProductProperties_", ProductProperties_);
	OpeningParameters.Insert("IDOfAttribute", Object.ProductItemProperty);
	
	ChoiceFormName = "CommonForm.ItemPropertyChoiceForm";
	Notification = New CallbackDescription("ProductItemPropertyStartChoiceCompletion", ThisObject);
	OpenForm(ChoiceFormName, OpeningParameters, ThisObject,,,, Notification);
	
EndProcedure

&AtClient
Procedure ProductItemPropertyExtendedTooltipURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "ShowDetailedDescription" Then
		
		ShowMessageBox(, DetailedDescriptionOfBan);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetDateInterval(Command)
	
	TMCommonUseClient.EditPeriod(
		Object, 
		New Structure("StartDate, EndDate", "ValidOnDate", "ValidTo"));
		
EndProcedure

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

// StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem

// Parameters:
//   Command - FormCommand - the command called.
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("RebateKindIsUsed", RebateKindIsUsed);
		
		NameOfUnlockForm = "Catalog.VendorRebateKinds.Form.AttributeUnlocking";
		Notification = New CallbackDescription(
			"Attachable_AllowObjectAttributeEditCompletion",
			ThisObject);
		OpenForm(NameOfUnlockForm, OpeningParameters, ThisObject,,,, Notification);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region EventHandlersForFormHeaderElementsAuxiliary

&AtServer
Procedure BonusTypeOnChangeServer()
	
	Object.ConditionFrequency = Enums.RebatesFrequencies.EmptyRef();
	SetGoodsIndicatorHeader();
	
	SetAvailableListOfParticipants(ThisObject);
	SetAvailableListOfSalesIndicators(ThisObject);
	SetAvailableListOfSalesCalculationBases(ThisObject);
	SetAvailableListOfTimeFenceAccruals(ThisObject);
	SetAvailableListOfGoods(ThisObject);
	SetAvailableListSelectionOfGoods(ThisObject);
	
	CheckResetCustomerFulfillmentFlag(ThisObject);
	
	If Object.GoodsIndicator = PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.NotUsed") Then
		Object.ConditionFrequency = PredefinedValue("Enum.RebatesFrequencies.EmptyRef");
	EndIf;
	
	Object.AllocationProcedure = RebatesClientServer.CheckResetAllocationOrder(
		Object.AllocationProcedure,
		Object.WithoutCalculation,
		Object.BonusType,
		Object.GoodsIndicator,
		Object.BaseOfCalculation);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure SetGoodsIndicatorHeader()
	
	If Object.BonusType = Enums.VendorRebateTypes.Purchases Then
		
		FieldTitle = NStr("vi = 'Chỉ số mục tiêu
						 |mua hàng';
						 |ru = 'Целевой показатель
						 |закупок';
						 |en = 'Target purchase
						 |indicator'; fa = 'Target purchase
						 |indicator';
						 |it = 'Целевой показатель
						 |закупок';
						 |pl = 'Target purchase
						 |indicator';
						 |tr = 'Hedef satış
						 |göstergesi'");
		
	ElsIf Object.BonusType = Enums.VendorRebateTypes.Sales Then
		
		FieldTitle = NStr("vi = 'Mục tiêu
						 |bán hàng';
						 |ru = 'Целевой показатель
						 |продаж';
						 |en = 'Target sales
						 |indicator'; fa = 'شاخص فروش
						 |هدف';
						 |it = 'Целевой показатель
						 |продаж';
						 |pl = 'Target sales
						 |indicator';
						 |tr = 'Hedef satış
						 |göstergesi'");
		
	Else
		
		FieldTitle = "";
		
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items, Items.GoodsIndicator.Name, "Title", FieldTitle);
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisObject, ChangedProps, FormAttributes(ThisObject));
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisObject, ChangedProps, FormAttributes(ThisObject));
	
EndProcedure

// Parameters:
//  Form - See Catalog.VendorRebateKinds.Form.ItemForm
//
&AtClientAtServerNoContext
Procedure SetAvailableListOfSalesIndicators(Form)
	
	Object = Form.Object;
	
	FilterParameters = RebatesClientServer.NewParametersOfAvailableGoodsIndicators();
	FilterParameters.WithoutCalculation = Object.WithoutCalculation;
	FilterParameters.BonusType = Object.BonusType;
	
	ChoiceArray = RebatesClientServer.AvailableListOfGoodsIndicators(FilterParameters);
	Form.Items.GoodsIndicator.ChoiceList.LoadValues(ChoiceArray);
	RebatesClientServer.CheckSetValueOfSelectionList(Object, "GoodsIndicator", ChoiceArray);
	
EndProcedure

// Set An Available List Of Sales Calculation Bases
// 
// Parameters:
//  Form - See Catalog.VendorRebateKinds.Form.ItemForm
//
&AtClientAtServerNoContext
Procedure SetAvailableListOfSalesCalculationBases(Form)
	
	Object = Form.Object;
	
	FilterParameters = RebatesClientServer.NewParametersOfAvailableRebateCalculationBasesOfRetroBonuses();
	FilterParameters.WithoutCalculation = Object.WithoutCalculation;
	FilterParameters.GoodsIndicator = Object.GoodsIndicator;
	FilterParameters.BonusType = Object.BonusType;
	
	ChoiceArray = RebatesClientServer.AvailableListOfRebateCalculationBasesForCalculationOfRetroBonuses(FilterParameters);
	Form.Items.BaseOfCalculation.ChoiceList.LoadValues(ChoiceArray);
	RebatesClientServer.CheckSetValueOfSelectionList(Object, "BaseOfCalculation", ChoiceArray);
	
EndProcedure

// Set an available list of the time fence of accruals
// 
// Parameters:
//  Form - See Catalog.VendorRebateKinds.Form.ItemForm
//
&AtClientAtServerNoContext
Procedure SetAvailableListOfTimeFenceAccruals(Form)
	
	Object = Form.Object;
	
	FilterParameters = RebatesClientServer.NewParametersOfAvailableAccrualTimeFences();
	FilterParameters.ConditionFrequency = Object.ConditionFrequency;
	FilterParameters.GoodsIndicator = Object.GoodsIndicator;
	FilterParameters.BonusType = Object.BonusType;
	
	ChoiceArray = RebatesClientServer.AvailableListOfTimeFenceOfAccruals(FilterParameters);
	Form.Items.AccrualFrequency.ChoiceList.LoadValues(ChoiceArray);
	RebatesClientServer.CheckSetValueOfSelectionList(Object, "AccrualFrequency", ChoiceArray);
	
EndProcedure

// Parameters:
//  Form - See Catalog.VendorRebateKinds.Form.ItemForm
//
&AtClientAtServerNoContext
Procedure SetAvailableListOfGoods(Form)
	
	Object = Form.Object;
	
	FilterParameters = RebatesClientServer.NewParametersOfAvailableGoodsCompositions();
	FilterParameters.WithoutCalculation = Object.WithoutCalculation;
	FilterParameters.UseProductSegments = Form.ProductSegmentsAreUsed;
	FilterParameters.GoodsIndicator = Object.GoodsIndicator;
	FilterParameters.BaseOfCalculation = Object.BaseOfCalculation;
	FilterParameters.BonusType = Object.BonusType;
	
	ChoiceArray = RebatesClientServer.AvailableListCompositionOfGoods(FilterParameters);
	Form.Items.ContentOfGoods.ChoiceList.LoadValues(ChoiceArray);
	RebatesClientServer.CheckSetValueOfSelectionList(Object, "ContentOfGoods", ChoiceArray);
	
EndProcedure

// Parameters:
//  Form - See Catalog.VendorRebateKinds.Form.ItemForm
//
&AtClientAtServerNoContext
Procedure SetAvailableListSelectionOfGoods(Form)
	
	Object = Form.Object;
	
	FilterParameters = RebatesClientServer.NewParametersForAvailableGoodsSelections();
	FilterParameters.WithoutCalculation = Object.WithoutCalculation;
	FilterParameters.GoodsIndicator = Object.GoodsIndicator;
	FilterParameters.BaseOfCalculation = Object.BaseOfCalculation;
	FilterParameters.ContentOfGoods = Object.ContentOfGoods;
	FilterParameters.BonusType = Object.BonusType;
	
	ChoiceArray = RebatesClientServer.AvailableListSelectionOfGoods(FilterParameters);
	Form.Items.FilterOfProducts_.ChoiceList.LoadValues(ChoiceArray);
	RebatesClientServer.CheckSetValueOfSelectionList(Object, "FilterOfProducts_", ChoiceArray);
	
EndProcedure

// Parameters:
//  Form - See Catalog.VendorRebateKinds.Form.ItemForm
//
&AtClientAtServerNoContext
Procedure SetAvailableListOfParticipants(Form)
	
	Object = Form.Object;
	
	FilterParameters = RebatesClientServer.NewParametersOfAvailableParticipantLineups();
	FilterParameters.WithoutCalculation = Object.WithoutCalculation;
	FilterParameters.BonusType = Object.BonusType;
	
	ChoiceArray = RebatesClientServer.AvailableListCompositionOfParticipants(FilterParameters);
	Form.Items.PartyList.ChoiceList.LoadValues(ChoiceArray);
	RebatesClientServer.CheckSetValueOfSelectionList(Object, "PartyList", ChoiceArray);
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("RebateKindIsUsed");
	FormAttributes.Insert("ProductSegmentsAreUsed");
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtServer
Procedure UpdateListOfItemProperties()
	
	ProductProperties_.Clear();
	RebatesServer.FillInListOfOperandsOfNomenclature(ThisObject);
	
EndProcedure

&AtServer
Procedure CheckItemProperty()
	
	If Not ValueIsFilled(Object.ProductItemProperty) Then
		Return;
	EndIf;
	
	IDOfAttribute = Object.ProductItemProperty;
	ChoiceList = Items.ProductItemProperty.ChoiceList; // ValueList of String
	
	PropertyIsNotFound = (ChoiceList.FindByValue(IDOfAttribute) = Undefined);
	DetailedDescriptionOfBan = "";
	HintTitle = "";
	
	If PropertyIsNotFound Then
		
		CheckResult = RebatesServer.ItemPropertyVerificationData(IDOfAttribute);
		ChoiceList.Add(IDOfAttribute, CheckResult.Title);
		
		DescriptionOfReasonForBan = RebatesServer.DescriptionOfReasonForBanItemProperties(
			CheckResult,
			RebateKindIsUsed);
		
		ShortDescription = DescriptionOfReasonForBan.ShortDescription;
		DetailedDescriptionOfBan = DescriptionOfReasonForBan.DetailedDescription;
		HintTitle = StringFunctions.FormattedString(ShortDescription);
		
	EndIf;
	
	Items.ProductItemPropertyExtendedTooltip.Title = HintTitle;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnCreatReadAtServer()
	
	RebateKindIsUsed = Catalogs.VendorRebateKinds.RebateKindIsUsed(Object);
	
	ProductSegmentsAreUsed = GetFunctionalOption("UseProductSegments");
	
	CashServer.ManagingFormElementsWhenReadingCreatingOnServer(ThisObject);
	
	SetAvailableListOfSalesIndicators(ThisObject);
	SetAvailableListOfSalesCalculationBases(ThisObject);
	SetAvailableListOfTimeFenceAccruals(ThisObject);
	SetAvailableListOfGoods(ThisObject);
	SetAvailableListSelectionOfGoods(ThisObject);
	SetAvailableListOfParticipants(ThisObject);
	
	UpdateListOfItemProperties();
	CheckItemProperty();
	
	ConfigureDependentFormElementsOnServer();
	
	SetGoodsIndicatorHeader();
	
EndProcedure

&AtClientAtServerNoContext
Procedure CheckResetCustomerFulfillmentFlag(Form)
	
	Object = Form.Object;
	
	CustomerVerificationIsAvailable =
		(Object.BonusType = PredefinedValue("Enum.VendorRebateTypes.Sales")
		 And Object.GoodsIndicator <> PredefinedValue("Enum.TargetSalesIndicatorsOfRebatesByGoods.NotUsed"));
	If Not CustomerVerificationIsAvailable Then
		
		Object.FulfilConditionsByCustomers = False;
		
	EndIf;
	
EndProcedure

// Parameters:
//  Result - Structure:
//  * IDOfAttribute - String
//  * AttributeRepresentation - String
//  * Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo
//  AdditionalParameters - Structure
//
&AtClient
Procedure ProductItemPropertyStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		Modified = True;
		IDOfAttribute = Result.IDOfAttribute;
		AttributeRepresentation = Result.AttributeRepresentation;
		
		ChoiceList = Items.ProductItemProperty.ChoiceList; // ValueList of String
		If ChoiceList.FindByValue(IDOfAttribute) = Undefined Then
			
			ChoiceList.Add(IDOfAttribute, AttributeRepresentation);
			
		EndIf;
		
		Items.ProductItemPropertyExtendedTooltip.Title = "";
		Object.ProductItemProperty = IDOfAttribute;
		
	EndIf;
	
EndProcedure

// Parameters:
//  Result - Array of String
//  AdditionalParameters - Structure
//
&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array")
	   And Result.Count() > 0 Then
		
		ObjectAttributesLockClient.SetFormItemEnabled(ThisObject, Result);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region StandardSubsystems_PlugInCommands

// StandardSubsystems.AttachableCommands

// The Attachable one continues to execute the Commands on the server.
// 
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
