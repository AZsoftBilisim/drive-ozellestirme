
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ConsigneeOrClient = Catalogs.Counterparties.EmptyRef();
	If Parameters.Filter.Property("ConsigneeOrClient", ConsigneeOrClient) Then
		
		Items.ListGoodsServicesSaleCustomerCounterparty.Visible = True;
		
		If Parameters.Filter.Property("Counterparty") Then
			Parameters.Filter.Delete("Counterparty");
		EndIf;
		
		If Parameters.Filter.Property("CustomerCounterparty") Then
			Parameters.Filter.Delete("CustomerCounterparty");
		EndIf;
		
		OrGroup = CommonClientServer.CreateFilterItemGroup(
			ListGoodsServicesSale.SettingsComposer.Settings.Filter.Items, 
			"OrGroup", 
			DataCompositionFilterItemsGroupType.OrGroup);
		
		CommonClientServer.SetFilterItem(
			OrGroup, "Counterparty", ConsigneeOrClient, DataCompositionComparisonType.Equal);
		
		CommonClientServer.SetFilterItem(
			OrGroup, "CustomerCounterparty", ConsigneeOrClient, DataCompositionComparisonType.Equal);
		
		Parameters.Filter.Delete("ConsigneeOrClient");
		
	Else
		Items.ListGoodsServicesSaleCustomerCounterparty.Visible = False;
	EndIf;
	
	VATAccountingERP.SetPropertiesOfFormOfChoiceForVFTSStatform(ThisObject);
	
	SetConditionalAppearance();

	TMCommonUse.CustomizePeripherals(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.ListGoodsServicesSale.CommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject,
		Items.ListGoodsServicesSale.CommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "Write_CustomerInvoice" Then
		// StandardSubsystems.AttachableCommands
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		// End StandardSubsystems.AttachableCommands
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Manager = Settings.Get("Manager");
	
	CommonClientServer.SetDynamicListFilterItem(ListGoodsServicesSale, "Manager", Manager, DataCompositionComparisonType.Equal,, ValueIsFilled(Manager));
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ManagerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListGoodsServicesSale,
		"Manager",
		Manager,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Manager));
	
EndProcedure

&AtClient
Procedure PeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	CommonClientServer.SetDynamicListFilterItem(ListGoodsServicesSale,
		"Date.StartDates.BegOfMonth",
		BegOfMonth(Period),
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Period));
		
EndProcedure

&AtClient
Procedure CountryOfSaleOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListGoodsServicesSale,
		"CountryOfSale",
		CountryOfSale,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(CountryOfSale));
		
EndProcedure

&AtClient
Procedure TaxationOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ListGoodsServicesSale,
		"VATTaxation",
		Taxation,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Taxation));
		
EndProcedure
#EndRegion

#Region FormTableItemsEventHandlersListGoodsServicesSale

&AtClient
Procedure ListGoodsServicesSaleOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ListGoodsServicesSale);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ListGoodsServicesSale, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListGoodsServicesSale);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.ListGoodsServicesSale);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	If Items.ListGoodsServicesSaleCustomerCounterparty.Visible Then
		
		ConditionalAppearance.Items.Clear();
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListGoodsServicesSaleCustomerCounterparty.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ListGoodsServicesSale.CustomerCounterparty");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		
	EndIf;

EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.CustomerInvoice.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.ListGoodsServicesSale.CurrentRow = ReferencesArrray[0];
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
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
	If Item.Name = "sh_ShamsiInput_F_Period" Then
		PeriodOnChange(Items.Period);
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
