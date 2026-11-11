
#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CurCurrentCashier = EquipmentManagerClientServer.CurCurrentCashierForFiscalTransactions();  
	Cashier = CurCurrentCashier.Cashier; 
	CashierTIN = CurCurrentCashier.CashierTIN;   
	
	CollectionIsAvailable = EquipmentManager.CollectionInManagementOfFiscalDeviceIsAvailable();
	Items.DepositingMoney.Visible = CollectionIsAvailable;     
	Items.WithdrawalOfMoney.Visible = CollectionIsAvailable; 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OperationCompletion(ExecutionResult, Var_Parameters) Export
	
	Enabled = True;
	
	MessageText = ?(ExecutionResult.Result, NStr("vi = 'Đã hoàn tất giao dịch thành công.';
												|ru = 'Операция успешно завершена.';
												|en = 'Operation completed successfully.'; fa = 'Operation completed successfully.';
												|it = 'Operazione correttamente completata.';
												|pl = 'Operacja została zakończona pomyślnie.';
												|tr = 'İşlem başarıyla tamamlanmıştır.'"), ExecutionResult.ErrorDescription);
	CommonCELClient.MessageToUser(MessageText);
	
EndProcedure

&AtClient
Procedure OpenShift(Command)
	
	ExecuteOperation("OpenShift");
	
EndProcedure

&AtClient
Procedure CloseShift(Command)
	
	ExecuteOperation("CloseShift");
	
EndProcedure

&AtClient
Procedure DepositingMoney(Command)
	
	ExecuteOperation("CashDeposit"); 
	
EndProcedure

&AtClient
Procedure WithdrawalOfMoney(Command)
	
	ExecuteOperation("Withdrawal");     
	
EndProcedure

&AtClient
Procedure ReportCurrentStatusOfSettlements(Command)
	
	ExecuteOperation("ReportCurrentStatusOfSettlements");
	
EndProcedure

&AtClient
Procedure PrintReportWithoutClearance(Command)
	
	ExecuteOperation("PrintReportWithoutClearance");
	
EndProcedure

&AtClient
Procedure ExecuteOperation(Command)
	
	ClearMessages();
	
	SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
	SupportedTypes.ReceiptPrinter = True;
	SupportedTypes.CREWithDataTransfer = True;
	SupportedTypes.CloudCashRegister = True;
	
	AdditionalParameters = New Structure("Command", Command);
	
	If Command = "CashDeposit" Or Command = "Withdrawal" Then
		CallbackDescription = New CallbackDescription("PerformOperationOfDeviceSelectionCollection", ThisObject, AdditionalParameters); 
	Else
		CallbackDescription = New CallbackDescription("PerformDeviceSelectionOperation", ThisObject, AdditionalParameters); 
	EndIf;
	EquipmentManagerClient.SelectDevice(CallbackDescription, SupportedTypes,
		NStr("vi = 'Hãy chọn máy ghi nhận tiền mặt';
			|ru = 'Выберите фискальное устройство';
			|en = 'Select a fiscal device'; fa = 'Select a fiscal device';
			|it = 'Scegliete un dispositivo fiscale';
			|pl = 'Wybierz urządzenie fiskalne';
			|tr = 'Mali cihaz seçiniz'"), 
		NStr("vi = 'Chưa kết nối máy ghi nhận tiền mặt.';
			|ru = 'Фискальное устройство не подключено.';
			|en = 'Fiscal device is not connected.'; fa = 'Fiscal device is not connected.';
			|it = 'Dispositivo fiscale non collegato.';
			|pl = 'Urządzenie fiskalne nie jest podłączone.';
			|tr = 'Mali cihaz bağlı değil.'"), 
		NStr("vi = 'Chưa chọn máy ghi nhận tiền mặt.';
			|ru = 'Фискальное устройство не выбрано.';
			|en = 'Fiscal device is not selected.'; fa = 'Fiscal device is not selected.';
			|it = 'Dispositivo fiscale non selezionato.';
			|pl = 'Nie wybrano urządzenia fiskalnego.';
			|tr = 'Mali cihaz seçili değil.'"));

EndProcedure

&AtClient
Procedure PerformOperationOfDeviceSelectionCollection(SelectionResult, AdditionalParameters) Export
	
	If Not SelectionResult.Result Then
		CommonCELClient.MessageToUser(SelectionResult.ErrorDescription);      
		Return;
	EndIf;  
	
	TransactionAmount = 0;
	
	If AdditionalParameters.Command = "CashDeposit" Then    
		WindowTitle = NStr("vi = 'Số tiền nhập';
							|ru = 'Сумма внесения';
							|en = 'Amount to put in'; fa = 'مبلغ برای واریز';
							|it = 'Importo di versamento';
							|pl = 'Wpłacona wartość';
							|tr = 'Depozito tutarı'");       
	Else     
		WindowTitle = NStr("vi = 'Số tiền rút';
							|ru = 'Сумма выемки';
							|en = 'Cash amount to take out'; fa = 'Cash amount to take out';
							|it = 'Importo prelievo';
							|pl = 'Kwota wyjęcia';
							|tr = 'Para çekme miktarı'");  
	EndIf;
	
	ParametersAfterEnteringNumber = New Structure;
	ParametersAfterEnteringNumber.Insert("TransactionAmount", TransactionAmount);
	ParametersAfterEnteringNumber.Insert("DeviceID", SelectionResult.DeviceID);  
	ParametersAfterEnteringNumber.Insert("Command", AdditionalParameters.Command);
	
	NotificationAfterEnteringNumber = New CallbackDescription("Collection_Completion", ThisObject, ParametersAfterEnteringNumber);
	
	ShowInputNumber(NotificationAfterEnteringNumber, TransactionAmount, WindowTitle, 15, 2);
	
EndProcedure        

&AtClient
Procedure Collection_Completion(Result, AdditionalParameters) Export
	
	TransactionAmount = ?(Result = Undefined, AdditionalParameters.TransactionAmount, Result);
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Enabled = False;   
	
	OperationParametersList = PeripheralsReceiptPrintersClientServer.CollectionParameters();
	OperationParametersList.TypeOfCollection = ?(AdditionalParameters.Command = "CashDeposit" , 1, 0);    
	OperationParametersList.Sum     = TransactionAmount;   
	OperationParametersList.Cashier    = Cashier;   
	OperationParametersList.CashierTIN = CashierTIN;
	
	NotificationOnCompletion = New CallbackDescription("OperationCompletion", ThisObject);
	PeripheralsReceiptPrintersClient.StartCollectionOnFiscalDevice(NotificationOnCompletion, UUID, 
		AdditionalParameters.DeviceID, OperationParametersList);
	
EndProcedure

&AtClient
Procedure PerformDeviceSelectionOperation(SelectionResult, AdditionalParameters) Export
	
	If Not SelectionResult.Result Then
		CommonCELClient.MessageToUser(SelectionResult.ErrorDescription);      
		Return;
	EndIf;
	
	ClearMessages();
	Enabled = False;
	
	OperationParametersList = PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift();
	OperationParametersList.Cashier    = Cashier;   
	OperationParametersList.CashierTIN = CashierTIN;

	NotificationOnCompletion = New CallbackDescription("OperationCompletion", ThisObject);
	
	If AdditionalParameters.Command = "OpenShift" Then 
		If CommonCELClient.CashShiftIsUsed() Then 
			AdditionalParameters = New Structure();
			CashShiftModuleClientOverridable = CommonCELClient.CommonModule("RegisterShiftsClientOverridable");
			CashShiftModuleClientOverridable.FuManagementFillInAdditionalParametersBeforeOpeningShift(SelectionResult.DeviceID, AdditionalParameters);
		Else     
			AdditionalParameters = Undefined;
		EndIf;
		PeripheralsReceiptPrintersClient.StartOpeningShiftOnFiscalDevice(NotificationOnCompletion, 
			UUID, SelectionResult.DeviceID, OperationParametersList, AdditionalParameters);    
	ElsIf AdditionalParameters.Command = "CloseShift" Then
		PeripheralsReceiptPrintersClient.StartClosingShiftOnFiscalDevice(NotificationOnCompletion, 
			UUID, SelectionResult.DeviceID, OperationParametersList);
	ElsIf AdditionalParameters.Command = "ReportCurrentStatusOfSettlements" Then
		PeripheralsReceiptPrintersClient.StartGeneratingReportOnCurStateOfSettlements(NotificationOnCompletion, 
			UUID, SelectionResult.DeviceID, OperationParametersList);
	ElsIf AdditionalParameters.Command = "PrintReportWithoutClearance" Then
		PeripheralsReceiptPrintersClient.StartGeneratingReportWithoutBlanking(NotificationOnCompletion, 
			UUID, SelectionResult.DeviceID, OperationParametersList);
	EndIf;
	
EndProcedure

#EndRegion

