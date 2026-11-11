
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region ProcessingTransitionFromBatchRegisterOfOtherExpensesToBatchRegisterOfNDSKDistribution

// The procedure converts entries in the batch register of other Expenses related to VAT distribution to a separate 
// batch register for distribution.
// 
// Parameters:
// 	Recorder - DocumentRef.VendorInvoice - document Registrar
// 	Set - AccumulationRegisterRecordSet.ItemisedExpensesLots - a set of register entries to process
// 	RecordsSelection - QueryResultSelection - record the set with the calculated additional fields
// 
// Returns:
// 	AccumulationRegisterRecordSet.LotsVATForAllocation - a set of new register entries
//
Function TransferDataFromOtherExpensesBatchRegisterToNDSKDistributionBatchRegister(Recorder, Set, RecordsSelection) Export
	
	SetOfVATLots = AccumulationRegisters.LotsVATForAllocation.CreateRecordSet();
	SetOfVATLots.DataExchange.Load = True;
	SetOfVATLots.Filter.Recorder.Set(Recorder);
	SetOfVATLots.Read();
		
	EntriesToDelete = New Array();
	
	While RecordsSelection.Next() Do
		
		If RecordsSelection.TransferRecording Then
			SetRecord = Set[RecordsSelection.LineNumber - 1];
			EntriesToDelete.Add(SetRecord);
		Else
			Continue;
		EndIf;
		
		VATRecord = SetOfVATLots.Add();
		FillPropertyValues(VATRecord, RecordsSelection);
			
	EndDo;
	
	For Each SetRecord In EntriesToDelete Do
		Set.Delete(SetRecord);
	EndDo;
	
	Return SetOfVATLots;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
