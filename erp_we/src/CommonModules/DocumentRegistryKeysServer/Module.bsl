
#Region Public

// Performs the launch of a routine task to delete duplicates
// in the Catalog of Keyreestradocuments.
// 
Procedure DeleteDuplicatesOfDocumentRegistryKeys() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DeleteDuplicatesOfDocumentRegistryKeys);
	
	If IsBlankString(UserName()) Then
		SetPrivilegedMode(True);
	EndIf;
	
	Catalogs.DocumentRegistryKeys.FindAndDeleteDuplicates();
	
EndProcedure

#EndRegion
