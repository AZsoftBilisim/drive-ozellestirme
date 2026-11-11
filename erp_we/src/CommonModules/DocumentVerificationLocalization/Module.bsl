#Region Internal

// Supplements documents that should not be considered as verifiable. See DocumentVerificationServer.ExcludedTypesToCheck
// 
// Parameters:
// 	TypesAreExcluded - Array of Type - Value types that should not be checked.
//
Procedure CompleteExcludedDocumentsForVerification(TypesAreExcluded) Export
	
	
EndProcedure

// Gets an array of details with the type "Organization" from the passed object (link) and supplements the passed parameter "Array of Organizations".
//
//	Parameters:
//		CompanyArray - Array of CatalogRef.Companies - array of Organizations to fill in
//		DocumentSource - DocumentRef, DocumentObject - the object whose Attributes need to be analyzed for compliance with the "Organization" type.
// 															If an object is passed, the Attribute value is read directly from it. 
// 															If a link is passed, the database data is accessed with a request (See Common.ObjectAttributesValues)
//                                                      .
//		TakeIntoAccountManagementOrganization - Boolean - Determines whether there should be a management organization among the returned array. The default value is True;
//
Procedure AddArrayOfOrganizationsToDocument(CompanyArray, DocumentSource, TakeIntoAccountManagementOrganization) Export
	

EndProcedure

#EndRegion