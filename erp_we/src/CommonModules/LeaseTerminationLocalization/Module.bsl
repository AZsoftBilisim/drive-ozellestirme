////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Termination of the lease agreement".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region EventHandlers

// Called from the corresponding document handler
// 
// Parameters:
//  Object - DocumentObject.LeaseTermination - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  FillingText - String - 
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
Procedure Filling(Object, FillingData, FillingText, StandardProcessing) Export
		
EndProcedure

#EndRegion

#Region Mechanisms

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

#EndRegion

#Region Posting

Function QueryTextTableInitialFixedAssetsInformation() Export

	QueryText = Undefined;
	
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region RegAccountingTransactions

Function TextOfReflectionInLocalAccounting() Export
	
	QueryText = "";
	
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

Procedure AddRequestTexts(Query, QueryTexts, Registers) Export
	
	
EndProcedure

Procedure TablesOfDeferredMotionFormation(QueryTexts) Export
	
	
EndProcedure

#EndRegion


#EndRegion
