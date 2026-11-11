
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	SupportedPeripheralTypes = "BarcodeScanner,MagneticStripeCardReaders";
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	SetMapTypeAndPartnerFromSelection();
	
	List.Parameters.SetParameterValue("UpdateDate", BegOfDay(CurrentSessionDate()));

	ListSelectionsClientServer.FillInSelectionSelectionListByRelevance(Items.FilterValidityPeriod.ChoiceList);
	ListSelectionsClientServer.SelectionByRelevanceWhenCreatingOnServer(List, Relevance, Items.FilterValidityPeriod.ChoiceList, EventDate, QuickFilterStructure);

	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	If ListSelectionsClientServer.YouNeedToSelectByStateWhenCreatingOnServer(State, QuickFilterStructure) Then
		CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.ListCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, SupportedPeripheralTypes);

EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
		ElsIf EventName ="TracksData" Then
			ProcessMagneticCardReaderData(Parameter);
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "LoyaltyCardIsRead"
	 And Parameter.OwnerForm = UUID Then
		Items.List.CurrentRow = Parameter.LoyaltyCard;
	EndIf;
	
	If EventName = "Write_LoyaltyCard" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If SetMapTypeAndPartnerFromSelection() Then
		
		TableSavedSettings = New ValueTable;
		TableSavedSettings.Columns.Add("Key");
		TableSavedSettings.Columns.Add("Value");
		
		For Each KeyAndValue In Settings Do
			NewRow = TableSavedSettings.Add();
			NewRow.Key = KeyAndValue.Key;
			NewRow.Value = KeyAndValue.Value;
		EndDo;
		
		SavedSettings = PutToTempStorage(TableSavedSettings, UUID);
		
		Settings.Clear();
		
	Else
		
		Partner = Settings.Get("Partner");
		CardKind = Settings.Get("CardKind");
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List, "Partner", Partner, DataCompositionComparisonType.Equal,, ValueIsFilled(Partner));
	MapViewSelectedWhenChangedOnServer();
	
	ListSelectionsClientServer.SelectionByRelevanceWhenLoadingFromSettings(List, Relevance, Items.FilterValidityPeriod.ChoiceList, EventDate, QuickFilterStructure, Settings);

	If ListSelectionsClientServer.YouNeedToSelectByStateWhenLoadingFromSettings(State, QuickFilterStructure, Settings) Then
		CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	EndIf;
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	If IsTempStorageURL(SavedSettings) Then
		
		TableSavedSettings = GetFromTempStorage(SavedSettings);
		For Each TSRow In TableSavedSettings Do
			Settings.Insert(TSRow.Key, TSRow.Value);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MapTypeSelectionOnChange(Item)
	
	MapViewSelectedWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure PartnerSelection_OnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Partner", Partner, DataCompositionComparisonType.Equal,, ValueIsFilled(Partner));
	
EndProcedure

&AtClient
Procedure FilterStateOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "State", State, DataCompositionComparisonType.Equal,, ValueIsFilled(State));
	
EndProcedure

&AtClient
Procedure FilterValidityPeriodOnChange(Item)
	
	ListSelectionsClientServer.WhenChangingRelevanceSelection(List, Relevance, EventDate, Items.FilterValidityPeriod.ChoiceList);
	
EndProcedure

&AtClient
Procedure FilterValidityPeriodClearing(Item, StandardProcessing)
	
	ListSelectionsClientServer.WhenClearingSelectionByRelevance(List, Relevance, EventDate, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FilterValidityPeriodChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TMCommonUseClient.WhenSelectingRelevanceSelection(
		ValueSelected, 
		StandardProcessing, 
		ThisForm,
		List, 
		"Relevance",
		"FilterValidityPeriod",
		"EventDate");
	
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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure MapViewSelectedWhenChangedOnServer()
	
	Personalized = CardIsPersonalized(CardKind);
	
	If Not Personalized Then
		Partner = Catalogs.Partners.EmptyRef();
		CommonClientServer.SetDynamicListFilterItem(List, "Partner", Partner, DataCompositionComparisonType.Equal,, ValueIsFilled(Partner));
	EndIf;
	
	Items.PartnerSelection_.Enabled = Personalized;
	
	CommonClientServer.SetDynamicListFilterItem(List, "Owner", CardKind, DataCompositionComparisonType.Equal,, ValueIsFilled(CardKind));
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

// ExternalEquipmentMechanism
&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	LoyaltyCardsClient.ProcessBarcodes(ThisForm, BarcodeData_5);
	
EndProcedure

&AtClient
Procedure ProcessMagneticCardReaderData(Data)
	
	LoyaltyCardsClient.ProcessMagneticCardReaderData(ThisForm, Data);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function SetMapTypeAndPartnerFromSelection()
	
	SelectionValueIsSet = False;
	
	If Parameters.Property("Filter")
	   And Parameters.Filter.Property("Owner")
	Then
		CardKind = Parameters.Filter.Owner;
		Items.MapTypeSelection.ReadOnly = True;
		SelectionValueIsSet = True;
	Else
		CardKind = Undefined;
	EndIf;
	
	If Parameters.Property("Filter")
	   And Parameters.Filter.Property("Partner")
	Then
		Partner = Parameters.Filter.Partner;
		Items.PartnerSelection_.ReadOnly = True;
		SelectionValueIsSet = True;
	Else
		Partner = Undefined;
	EndIf;
	
	Return SelectionValueIsSet;
	
EndFunction

&AtServerNoContext
Function CardIsPersonalized(CardKind)
	
	Personalized = False;
	
	Query = New Query(
	"SELECT
	|	LoyaltyCardKinds.Personalized AS Personalized
	|FROM
	|	Catalog.LoyaltyCardKinds AS LoyaltyCardKinds
	|WHERE
	|	LoyaltyCardKinds.Ref = &Ref");
	
	Query.SetParameter("Ref", CardKind);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Personalized = Selection.Personalized;
	EndIf;
	
	Return Personalized;
	
EndFunction

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion
