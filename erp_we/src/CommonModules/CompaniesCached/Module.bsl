#Region Internal

// See Catalogs.Companies.NamesAsOfDate
Function NamesAsOfDate(Organization, DateOfLastEdit) Export
	
	Return Catalogs.Companies.NamesAsOfDate(Organization, DateOfLastEdit);
	
EndFunction

// Returns the names of Attributes whose type matches the Reference Link type.Organizations.
//
// Parameters:
//		FullMetadataObjectName - String - full name of the metadata object to check.
//
// Returns:
//  Array of String - the names of the details.
//
Function NamesOfBusinessDetails(FullMetadataObjectName) Export
	
	MetadataObject = Metadata.FindByFullName(FullMetadataObjectName);
	
	Result = New Array;
	
	TypeOrganization = Type("CatalogRef.Companies");
	For Each Attribute In MetadataObject.Attributes Do
		If Attribute.Type.ContainsType(TypeOrganization) Then
			Result.Add(Attribute.Name);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion