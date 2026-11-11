
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If GetFunctionalOption("BaseVersion") Then
		AutoTitle = False;
		Title = NStr("vi = 'Ghi giảm hàng hóa cho nhu cầu kinh doanh';
					|ru = 'Списание товаров на хознужды';
					|en = 'Write off goods to business needs'; fa = 'Write off goods to business needs';
					|it = 'Storno delle merci per fabbisogni economici';
					|pl = 'Rozhód towarów na potrzeby gospodarcze';
					|tr = 'Ev ihtiyaçları için malların gider yazılması'");
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	Products = Undefined;
	Characteristic = Undefined;
	Individual = Undefined;
	ExpenseItem = Undefined;
	DimensionOfExpenses = Undefined;
	If Parameters.Property("Filter") Then
		Parameters.Filter.Property("Products", Products);
		Parameters.Filter.Property("Characteristic", Characteristic);
		Parameters.Filter.Property("Individual", Individual);
		Parameters.Filter.Property("ExpenseItem", ExpenseItem);
		Parameters.Filter.Property("DimensionOfExpenses", DimensionOfExpenses);
	EndIf;
	List.Parameters.SetParameterValue("Products", Products);
	List.Parameters.SetParameterValue("Characteristic", Characteristic);
	List.Parameters.SetParameterValue("Individual", Individual);
	List.Parameters.SetParameterValue("ExpenseItem", ExpenseItem);
	List.Parameters.SetParameterValue("DimensionOfExpenses", DimensionOfExpenses);
	
	CheckForCorrections = Parameters.CheckForCorrections;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
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
Procedure OnClose()
	
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

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If CheckForCorrections Then
		
		TableRow = Items.List.CurrentData;
		If TableRow = Undefined Then
			Return;
		EndIf;

		CorrectiveDocument = DocumentCorrectionServerCall.LastCorrectiveDocument(TableRow.Ref);

		If CorrectiveDocument <> Undefined Then
			StandardProcessing = False;
			ShowQueryBox(
				New CallbackDescription("WhenSelectingEndLine", ThisObject),
				NStr("vi = 'Đối với hóa đơn đã chọn có chỉnh sửa.
				|Chọn những dữ liệu này?';
				|ru = 'Для выбранной накладной имеется исправление.
				|Выполнить выбор этих данных?';
				|en = 'The selected invoice has a correction.
				|Do you want to select this data?'; fa = 'The selected invoice has a correction.
				|Do you want to select this data?';
				|it = 'Для выбранной накладной имеется исправление.
				|Выполнить выбор этих данных?';
				|pl = 'The selected invoice has a correction.
				|Do you want to select this data?';
				|tr = 'Seçilen faturada bir düzeltme var.
				|Bu veriler seçilsin mi?'"), 
				QuestionDialogMode.YesNo);
			Return;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenSelectingEndLine(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		Return;
	EndIf;
	
	Close(Items.List.CurrentData.Ref);

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
Function GetLinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.InventoryConsumption.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = GetLinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

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
