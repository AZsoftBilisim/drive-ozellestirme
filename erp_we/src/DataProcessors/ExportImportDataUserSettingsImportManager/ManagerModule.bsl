#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Loads the user settings of the information database.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager - 
//		the container manager used in the data upload process. For more information, see the comment
//		on the software interface for processing the unloading of the data of the Manager container.
//	Handlers - DataProcessorObjectDataProcessorName
//	LinkReplacementFlow - DataProcessorObject.ExportImportDataReferenceReplacementStream
//  ReplaceUserInSettings - Map - matching the old and new IB user names.
//
Procedure DownloadInformationDatabaseUserSettings(Container, Handlers, LinkReplacementFlow, 
	ReplaceUserInSettings = Undefined) Export
	
	StorageTypes = ExportImportDataInternal.TypesOfStandardSettingsRepositories();
	
	For Each StoreType In StorageTypes Do
		
		DownloadManager = Create();
		DownloadManager.Initialize(Container, StoreType, Handlers, LinkReplacementFlow);
		DownloadManager.ImportData(ReplaceUserInSettings);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
