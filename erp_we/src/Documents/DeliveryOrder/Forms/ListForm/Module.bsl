// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		
		CommonClientServer.SetFormItemProperty(
			Items, "FilterOrganization", "Visible", False);
		
	EndIf;
	
	If Not AccessRight("Insert", Metadata.Documents.DeliveryOrder) Then
		
		ItemsNames = New Array; // Array of String
		ItemsNames.Add("FormCreate");
		ItemsNames.Add("FormFormationAccordingToNeeds");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Items,
			ItemsNames,
			"Visible",
			False);
		
	EndIf;
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "Organization", Organization, QuickFilterStructure);
	CommonClientServer.SetFormItemProperty(
		Items, "Organization", "Visible", Not ValueIsFilled(Organization));
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "DeliveryMethod", DeliveryMethod, QuickFilterStructure);
	CommonClientServer.SetFormItemProperty(
		Items, "DeliveryMethod", "Visible", Not ValueIsFilled(DeliveryMethod));
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "DateOfShipment", DateOfShipment, QuickFilterStructure);
	CommonClientServer.SetFormItemProperty(
		Items, "DateOfShipment", "Visible", Not ValueIsFilled(DateOfShipment));
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	SetConditionalAppearance();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)

	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "Organization", Organization, QuickFilterStructure, Settings);
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "DeliveryMethod", DeliveryMethod, QuickFilterStructure, Settings);
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "DateOfShipment", DateOfShipment, QuickFilterStructure, Settings);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	CompanyIsFull = ValueIsFilled(Organization);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,
		,
		CompanyIsFull);
	
	CommonClientServer.SetFormItemProperty(
		Items, "Organization", "Visible", Not CompanyIsFull);
	
EndProcedure

&AtClient
Procedure FilterDeliveryMethodOnChange(Item)
	
	DeliveryMethodFilledIn = ValueIsFilled(DeliveryMethod);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"DeliveryMethod",
		DeliveryMethod,
		DataCompositionComparisonType.Equal,
		,
		DeliveryMethodFilledIn);
	
	CommonClientServer.SetFormItemProperty(
		Items, "DeliveryMethod", "Visible", Not DeliveryMethodFilledIn);
	
EndProcedure

&AtClient
Procedure SelectionDeliveryDateONChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DeliveryDateFilledIn = ValueIsFilled(DateOfShipment);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"DateOfShipment",
		DateOfShipment,
		DataCompositionComparisonType.Equal,
		,
		DeliveryDateFilledIn);
	
	CommonClientServer.SetFormItemProperty(
		Items, "DateOfShipment", "Visible", Not DeliveryDateFilledIn);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure FormationAccordingToNeeds(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.GenerateDeliveryOrders.Form.Opening");
	
	OpenForm("DataProcessor.GenerateDeliveryOrders.Form");
	
EndProcedure

#EndRegion

#Region Private

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
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject);
	
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
	If Item.Name = "sh_ShamsiInput_F_DateOfShipment" Then
		SelectionDeliveryDateONChange(Items.FilterDateOfShipment);
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
