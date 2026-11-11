
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	BusinessTransactionList = New Array;
	
	If Parameters.Filter.Property("CashReceiptsOnly") Then
		
		SelectionAccordingToListOfBusinessOperations = True;

		BusinessTransactionList.Add(Enums.BusinessTransactions.CashReturnByAdvanceHolder);
		BusinessTransactionList.Add(Enums.BusinessTransactions.RefundFromVendor);
		BusinessTransactionList.Add(Enums.BusinessTransactions.CashReceiptFromCashRegister);
		BusinessTransactionList.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
		BusinessTransactionList.Add(Enums.BusinessTransactions.OtherIncome);
		BusinessTransactionList.Add(Enums.BusinessTransactions.OtherCashReceipt);
	EndIf;
	
	If Parameters.Filter.Property("CashFlowOnly") Then
		
		SelectionAccordingToListOfBusinessOperations = True;
		
		BusinessTransactionList = Catalogs.CashFlowReportItems.EconomicOperationsOfCashFlow();
	EndIf;
	
	If Parameters.Filter.Property("BusinessOperation")
		And TypeOf(Parameters.Filter.BusinessOperation) = Type("Array") Then
	
		SelectionAccordingToListOfBusinessOperations = True;
		BusinessTransactionList = Parameters.Filter.BusinessOperation;
	
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
			List,
			"BusinessTransactions.BusinessOperation",
			BusinessTransactionList,
			DataCompositionComparisonType.InList,
			,
			BusinessTransactionList.Count());
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Core	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
