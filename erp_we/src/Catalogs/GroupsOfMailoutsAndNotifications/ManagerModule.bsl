#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets the object's details that need to be blocked from being changed
//
// Returns:
//  Array - the blocked details of the object.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("Forced");
	Result.Add("DesignedForEmails");
	Result.Add("DesignedForSMSMessage");
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf