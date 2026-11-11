
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TMCommonUse.CustomizePeripherals(ThisForm);
	FilterStructure1 = Undefined;	
	If Parameters.Property("Filter") 
		And Parameters.Filter.Property("BusinessOperation") Then
		
		If Parameters.Filter.BusinessOperation = Enums.BusinessTransactions.CashReturnByAdvanceHolder Then
			
			Parameters.Filter.BusinessOperation =  Enums.BusinessTransactions.IssueCashToAdvanceHolder;
			Parameters.Filter.Delete("CurrencyOfConversion");
			Parameters.Filter.Delete("Counterparty");
			
		ElsIf Parameters.Filter.BusinessOperation = Enums.BusinessTransactions.CurrencyConversion Then
			
			Parameters.Filter.Delete("AdvanceHolder");
			
		EndIf;
		
	ElsIf Parameters.Property("Filter", FilterStructure1) And TypeOf(FilterStructure1) = Type("Structure") Then
		
		If FilterStructure1.Property("Organization") Then
			CommonClientServer.SetDynamicListFilterItem(
				List, "Organization", FilterStructure1.Organization);
		EndIf;
		
		If FilterStructure1.Property("Bank") Then
			CommonClientServer.SetDynamicListFilterItem(
				List, "BankAccount.Bank", FilterStructure1.Bank);
		EndIf;
		
		If FilterStructure1.Property("CompaniesList") Then
			CommonClientServer.SetDynamicListFilterItem(
				List, "Organization", FilterStructure1.CompaniesList, DataCompositionComparisonType.InList);
		EndIf;

		If FilterStructure1.Property("ListOfBanks") Then
			CommonClientServer.SetDynamicListFilterItem(
				List, "BankAccount.Bank", FilterStructure1.ListOfBanks, DataCompositionComparisonType.InList);
		EndIf;
			
		If FilterStructure1.Property("Counterparty") Then
			CommonClientServer.SetDynamicListFilterItem(
				List, "Counterparty", FilterStructure1.Counterparty, DataCompositionComparisonType.Equal);
		EndIf;
		
		If FilterStructure1.Property("TranscriptOfPayment_LeaseAgreement") Then
			CommonClientServer.SetDynamicListFilterItem(
				List, "ARAPDetails.LeaseContracts", FilterStructure1.TranscriptOfPayment_LeaseAgreement, DataCompositionComparisonType.Equal);
		EndIf;
			
		If FilterStructure1.Property("DecryptionOfPayment_TypeOfPaymentForRent") Then
			CommonClientServer.SetDynamicListFilterItem(
				List, "ARAPDetails.TypeOfLeasePayment", FilterStructure1.DecryptionOfPayment_TypeOfPaymentForRent, DataCompositionComparisonType.Equal);
		EndIf;
		
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
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

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.BankAccountIssue.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
