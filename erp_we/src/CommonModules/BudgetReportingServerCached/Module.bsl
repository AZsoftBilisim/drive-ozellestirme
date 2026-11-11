
#Region Private

Function ItemMarkedForDeletion_(ItemRef) Export
	
	Return Common.ObjectAttributeValue(ItemRef, "DeletionMark");
	
EndFunction

#EndRegion

