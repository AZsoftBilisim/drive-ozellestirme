
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Partner                       = Parameters.Partner;
	ByPartner                    = ValueIsFilled(Parameters.Partner);
	Items.ByPartner.Visible = ValueIsFilled(Parameters.Partner);
	
	If ValueIsFilled(Partner) Then
		Items.ByPartner.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Theo bạn hàng ""%1""';
																								|ru = 'По партнеру ""%1""';
																								|en = 'By partner ""%1""'; fa = 'By partner ""%1""';
																								|it = 'Tramite il partner ""%1""';
																								|pl = 'Wg partnera ""%1""';
																								|tr = 'İş ortağına göre ""%1""'"), Partner);
	EndIf;
	
	SupportedPeripheralTypes = "BarcodeScanner,MagneticStripeCardReaders";
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	CommonClientServer.SetDynamicListFilterItem(List, "Partner", Partner, DataCompositionComparisonType.Equal,, ByPartner);	
	CommonClientServer.SetDynamicListFilterItem(List, "Owner.Organization", Parameters.Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Parameters.Organization));
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
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

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ByPartnerOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Partner", Partner, DataCompositionComparisonType.Equal,, ByPartner);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

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

#EndRegion
