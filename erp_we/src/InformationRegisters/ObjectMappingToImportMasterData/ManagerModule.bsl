
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds an entry to the object matching register
// 
// Parameters:
//  DataSource - CatalogRef.SourcesToImportProductionMasterData
//  Id - String
//  ObjectReference - AnyRef
// 
// Returns:
//  InformationRegisterRecordManager.ObjectMappingToImportMasterData
//
Function AddRecord(DataSource, Id, ObjectReference) Export
	
	Type = TypeOf(ObjectReference);
	
	Record = CreateRecordManager();
	Record.DataSource    = DataSource;
	Record.Id     = Id;
	Record.MetadataObject  = New(Type);
	Record.ObjectReference    = ObjectReference;
	Record.RecordDate        = CurrentSessionDate();
	
	Record.Write();
	
	Return Record;
	
EndFunction

// Adds an entry to the register of matching objects with field values from the property source
// 
// Parameters:
//  DataSource - CatalogRef.SourcesToImportProductionMasterData
//  SourceOfProperties - Structure
// 
// Returns:
//  InformationRegisterRecordManager.ObjectMappingToImportMasterData
//  
Function AddEntryByProperties(DataSource, SourceOfProperties) Export
	
	Record = CreateRecordManager();
	Record.DataSource = DataSource;
	Record.RecordDate     = CurrentSessionDate();
	FillPropertyValues(Record, SourceOfProperties);
	
	Record.Write();
	
	Return Record;
	
EndFunction

#EndRegion

#EndIf
