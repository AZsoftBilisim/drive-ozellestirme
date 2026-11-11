#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure UploadInformationDatabaseUserSettings(Container, Handlers, Serializer) Export
	
	StorageTypes = ExportImportDataInternal.TypesOfStandardSettingsRepositories();
	
	For Each StoreType In StorageTypes Do
		
		UploadManager = Create();
		UploadManager.Initialize(Container, StoreType, Handlers, Serializer);
		UploadManager.ExportData();
		UploadManager.Close();
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
