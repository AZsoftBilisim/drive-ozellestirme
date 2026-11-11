////////////////////////////////////////////////////////////////////////////////
// Subsystem "Data upload and download".
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns metadata objects with predefined elements.
//
// Returns:
//   FixedArray of String - an array containing the full names of metadata objects.
//
Function MetadataObjectsWithPredefinedElements() Export
	
	Cache = New Array();
	
	For Each MetadataObject In Metadata.Catalogs Do
		Cache.Add(MetadataObject.FullName());
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfAccounts Do
		Cache.Add(MetadataObject.FullName());
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfCharacteristicTypes Do
		Cache.Add(MetadataObject.FullName());
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfCalculationTypes Do
		Cache.Add(MetadataObject.FullName());
	EndDo;
	
	Return New FixedArray(Cache);
	
EndFunction

#EndRegion
