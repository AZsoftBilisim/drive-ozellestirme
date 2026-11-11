#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines the type of settlement record of operation of settlements
// 
// Parameters:
//  SettlementTransaction - EnumRef.SettlementOperations - Settlement Operation
//  ThisIsPrepayment - Boolean - Prepayment or debt of record
//  RecordType - AccumulationRecordType - Type of Registered Recording
// 
// Returns:
//  EnumRef.TypesOfSettlementRecords - Type Of Record of Operation
Function TypeOfRecordOfOperation(SettlementTransaction, ThisIsPrepayment, RecordType) Export
	
	If RecordType = AccumulationRecordType.Receipt Then
		If ThisIsPrepayment Then
			If SettlementTransaction = Enums.SettlementOperations.Payment Then
				Return Enums.TypesOfSettlementRecords.PaymentPrepaymentIncrease;
			ElsIf SettlementTransaction = Enums.SettlementOperations.AdjustmentOfInvoice Then
				Return Enums.TypesOfSettlementRecords.AdjustmentOfInvoicePrepaymentIncrease;
			ElsIf SettlementTransaction = Enums.SettlementOperations.TransferOfSettlements Then
				Return Enums.TypesOfSettlementRecords.TransferOfSettlementsPrepaymentIncrease;
			Else
				Return Enums.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentIncrease;
			EndIf;
		Else
			If SettlementTransaction = Enums.SettlementOperations.Shipment Then
				Return Enums.TypesOfSettlementRecords.ShipmentDebtIncrease;
			ElsIf SettlementTransaction = Enums.SettlementOperations.AdjustmentOfInvoice Then
				Return Enums.TypesOfSettlementRecords.AdjustmentOfInvoiceDebtIncrease;
			ElsIf SettlementTransaction = Enums.SettlementOperations.Refund Then
				Return Enums.TypesOfSettlementRecords.RefundIncreasesDebt;
			ElsIf SettlementTransaction = Enums.SettlementOperations.TransferOfSettlements Then
				Return Enums.TypesOfSettlementRecords.TransferOfSettlementsDebtIncrease;
			Else
				Return Enums.TypesOfSettlementRecords.AdjustmentOfDebtDebtIncrease;
			EndIf;
		EndIf;
	Else
		If ThisIsPrepayment Then
			If SettlementTransaction = Enums.SettlementOperations.Shipment Then
				Return Enums.TypesOfSettlementRecords.ShipmentPrepaymentDecrease;
			ElsIf SettlementTransaction = Enums.SettlementOperations.AdjustmentOfInvoice Then
				Return Enums.TypesOfSettlementRecords.InvoiceAdjustmentPrepaymentDecrease;
			ElsIf SettlementTransaction = Enums.SettlementOperations.Refund Then
				Return Enums.TypesOfSettlementRecords.RefundDecreasesPrepayment;
			ElsIf SettlementTransaction = Enums.SettlementOperations.TransferOfSettlements Then
				Return Enums.TypesOfSettlementRecords.TransferOfSettlementsPrepaymentDecrease;
			Else
				Return Enums.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentDecrease;
			EndIf;
		Else
			If SettlementTransaction = Enums.SettlementOperations.Payment Then
				Return Enums.TypesOfSettlementRecords.PaymentDebtDecrease;
			ElsIf SettlementTransaction = Enums.SettlementOperations.Shipment Then
				Return Enums.TypesOfSettlementRecords.ShipmentDebtDecrease;
			ElsIf SettlementTransaction = Enums.SettlementOperations.AdjustmentOfInvoice Then
				Return Enums.TypesOfSettlementRecords.InvoiceAdjustmentDebtDecrease;
			ElsIf SettlementTransaction = Enums.SettlementOperations.Refund Then
				Return Enums.TypesOfSettlementRecords.RefundDecreasesDebt;
			ElsIf SettlementTransaction = Enums.SettlementOperations.TransferOfSettlements Then
				Return Enums.TypesOfSettlementRecords.TransferOfSettlementsDebtDecrease;
			Else
				Return Enums.TypesOfSettlementRecords.AdjustmentOfDebtDebtDecrease;
			EndIf;
		EndIf;
	EndIf;
	
EndFunction

#EndRegion

#EndIf
