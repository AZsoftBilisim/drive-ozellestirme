#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	PaymentTransactions = PeripheralsPaymentSystemsServer.PaymentOfOperationsData(Record.QueryID, Undefined, True);
	If PaymentTransactions.Count() > 0 Then
		QueryText = PaymentTransactions[0].QueryData;
		ResponseText  = PaymentTransactions[0].ResponseData;
	EndIf;                                                                
	
	Items.HeaderGroup.Visible = ValueIsFilled(Record.DocumentBasis); 
	ThisForm.ReadOnly = True;                    
	
	EquipmentManagerServerCallOverridable.PaymentTransactionsInstanceWhenCreatedOnServer(Record, ThisForm, Cancel, StandardProcessing);
	
	If CommonCEL.ThisIsMobilePlatform() Then
		CommonCEL.PrepareControl(Items.TransactionAmount);
		CommonCEL.PrepareControl(Items.OperationID);
		CommonCEL.PrepareControl(Items.QueryID);
		CommonCEL.PrepareControl(Items.FiscalTransactionID);
		CommonCEL.PrepareControl(Items.RequestDate_);
		CommonCEL.PrepareControl(Items.PaymentKindOnTerminal);
		CommonCEL.PrepareControl(Items.ReferenceNumber);
		CommonCEL.PrepareControl(Items.AuthorizationCode);
		CommonCEL.PrepareControl(Items.OperationType);
		CommonCEL.PrepareControl(Items.AcquirerBankID);
		CommonCEL.PrepareControl(Items.PaymentSystemId);
		CommonCEL.PrepareControl(Items.BankTransactionID);
		CommonCEL.PrepareControl(Items.TransactionDateTime);
		CommonCEL.PrepareControl(Items.TerminalId);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// Calling BSP
	// Standard subsystems.Access managementreferences
	If CommonCEL.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = CommonCEL.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// The end of the standard subsystem.Access managementreferences
	// The end of the BSP Challenge
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Calling BSP
	// Standard subsystems.Access managementreferences
	If CommonCEL.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = CommonCEL.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// The end of the standard subsystem.Access managementreferences
	// The end of the BSP Challenge
	
EndProcedure

#EndRegion

