#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Selects the enumeration value corresponding to the value of the DMDocumentStatus enumeration from the XDTO of the DM package.
//
// Parameters:
//   StatusBefore - String - The Status of the document in 1C:Document flow.
//
// Returns:
//   EnumRef.ApprovalStatesIn1CDocumentManagement
//
Function ValueCorrespondingToStatusDM(StatusBefore) Export
	
	If StatusBefore = "AwaitingApproval" Then
		Result = AwaitingApproval;
		
	ElsIf StatusBefore = "Approved" Then
		Result = Approved;
		
	ElsIf StatusBefore = "NotApproved" Then
		Result = NotApproved;
		
	Else
		Result = EmptyRef();
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf