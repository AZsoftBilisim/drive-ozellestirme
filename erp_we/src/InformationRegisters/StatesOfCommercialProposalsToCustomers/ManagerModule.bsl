#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Record the status of a commercial offer
//
// Parameters:
//  CommercialProposal - DocumentRef.CommercialProposalForCustomer           - document whose status is being recorded,
//  State               - DefinedType.StatesOfCommercialProposalsToCustomer - fixed state of the document.
//
Procedure RecordState(CommercialProposal, State) Export
	
	If Not ValueIsFilled(CommercialProposal) Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.StatesOfCommercialProposalsToCustomers.CreateRecordSet();
	
	RecordSet.Filter.CommercialProposalForCustomer.Set(CommercialProposal);
	
	If ValueIsFilled(State) Then
		
		Record = RecordSet.Add();
		Record.CommercialProposalForCustomer = CommercialProposal;
		Record.State                      = State;
		
	EndIf;
	
	RecordSet.Write();
	
EndProcedure

#EndRegion

#EndIf