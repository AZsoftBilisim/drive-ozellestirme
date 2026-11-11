//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Checks for saved area data.
// 
// Parameters:
//  DataArea - Number - The number of the area for which the saved data is checked
// 
// Returns:
//  Boolean - True if the area data is saved
Function AreaDataIsSaved(DataArea) Export
	
	RegisterRecord = CreateRecordManager();
	RegisterRecord.DataArea = DataArea;
	RegisterRecord.Read();
	
	Return RegisterRecord.Selected();
	
EndFunction

// Saves the area data before clearing the area, for later recovery.
// 
// Parameters:
//  DataArea - Number - The number of the area to save the data for
Procedure SaveAreaData(DataArea) Export
	
	StoredData = NewSavedData();
	StoredData.DataAreas = GetDataStructureOfInformationRegister("DataAreas");
	StoredData.RecoveryExtensions = ExtensionsDirectory.ReadDataOfRecoverableExtensions();
	StoredData.DataAreaMessagesChanges = GetDataAreaMessagesChanges();
	StoredData.ExclusiveLockSet = GetFunctionalOption("ExclusiveLockSet");
	
	SavingDataArea = InformationRegisters.DataAreas.CreateRecordManager();
	SavingDataArea.Read();
	
	If SavingDataArea.Selected() Then
		FillPropertyValues(StoredData.DataAreas, SavingDataArea);
	EndIf;
		
	RegisterRecord = CreateRecordManager();
	RegisterRecord.DataArea = DataArea;
	RegisterRecord.Data = New ValueStorage(StoredData);
	RegisterRecord.SaveDate = CurrentUniversalDate();
	RegisterRecord.Write();
	
EndProcedure

// Restores the data of the cleared area.
// 
// Parameters:
//  DataArea - Number - The number of the area to restore data for
Procedure RestoreAreaData(DataArea) Export
	
	RegisterRecord = CreateRecordManager();
	RegisterRecord.DataArea = DataArea;
	RegisterRecord.Read();
	
	If Not RegisterRecord.Selected() Then
		Raise StrTemplate(NStr("vi = 'Không có dữ liệu của vùng đã lưu %1';
								|ru = 'Отсутствуют сохраненные данные области %1';
								|en = 'Saved data of the %1 area is missing'; fa = 'Saved data of the %1 area is missing';
								|it = 'Отсутствуют сохраненные данные области %1';
								|pl = 'Saved data of the %1 area is missing';
								|tr = '%1 alanı için kayıtlı veriler eksik'"), DataArea);
	EndIf;
	
	SavedData = NewSavedData();
	FillPropertyValues(SavedData, RegisterRecord.Data.Get());
	
	BeginTransaction();
	
	Try
		
		SavingDataArea = InformationRegisters.DataAreas.CreateRecordManager();
		FillPropertyValues(SavingDataArea, SavedData.DataAreas);
		SavingDataArea.Write();
			
		If SavedData.RecoveryExtensions <> Undefined Then
			ExtensionsDirectory.RecordDataOfRecoverableAreaExtensions(
				SavedData.RecoveryExtensions);
		EndIf;
		
		If SavedData.ExclusiveLockSet <> Undefined Then
			Constants.ExclusiveLockSet.Set(SavedData.ExclusiveLockSet);
		EndIf;
		
		RestoreDataAreaMessagesChanges(SavedData.DataAreaMessagesChanges);

		RegisterRecord.Delete();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		Raise;
		
	EndTry;
	
EndProcedure

Procedure RecoverInformationAboutDeletedAreas() Export
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	DataOfClearedArea.DataArea AS DataArea,
	|	DataOfClearedArea.Data AS Data
	|FROM
	|	InformationRegister.DataOfClearedArea AS DataOfClearedArea
	|		LEFT JOIN InformationRegister.DataAreas AS DataAreas
	|		ON DataOfClearedArea.DataArea = DataAreas.DataAreaAuxiliaryData
	|WHERE
	|	DataAreas.DataAreaAuxiliaryData IS NULL
	|
	|ORDER BY
	|	DataOfClearedArea.SaveDate";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		Data = Selection.Data; // ValueStorage
		DataArea = Selection.DataArea; // Number
		SavedData = Data.Get(); // See NewSavedData
		
		SavingDataArea = InformationRegisters.DataAreas.CreateRecordManager();
		FillPropertyValues(SavingDataArea, SavedData.DataAreas);
		SavingDataArea.DataAreaAuxiliaryData = DataArea;
		SavingDataArea.Write();
			
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Function GetDataStructureOfInformationRegister(RegisterName)
	
	StructureOfData = New Structure();
	MetadataObject = Metadata.InformationRegisters[RegisterName];
	
	If MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		StructureOfData.Insert("Period");
	EndIf;
	
	If MetadataObject.WriteMode <> Metadata.ObjectProperties.RegisterWriteMode.Independent Then
		StructureOfData.Insert("Recorder");
		StructureOfData.Insert("LineNumber");
	EndIf;
	
	For Each Dimension In MetadataObject.Dimensions Do
		StructureOfData.Insert(Dimension.Name);
	EndDo;
	
	For Each Resource In MetadataObject.Resources Do
		StructureOfData.Insert(Resource.Name);
	EndDo;
	
	For Each Attribute In MetadataObject.Attributes Do
		StructureOfData.Insert(Attribute.Name);
	EndDo;
	
	Return StructureOfData;
	
EndFunction

// Get changes to the messages of data areas.
// 
// Returns:
//  Array of Structure:
//   * Node - ExchangePlanRef.MessagesExchange
//   * Ref - CatalogRef.DataAreaMessages
Function GetDataAreaMessagesChanges()
	
	MessageChanges = New Array; // Array of Structure
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	ChangesTable.Node AS Node,
	|	ChangesTable.Ref AS Ref
	|FROM
	|	Catalog.DataAreaMessages.Changes AS ChangesTable";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Node = Selection.Node; // ExchangePlanRef
		Ref = Selection.Ref; // CatalogRef.DataAreaMessages  
		MessageData = New Structure("Node, Ref", Node, Ref);
		MessageChanges.Add(MessageData);
	EndDo;
	
	Return MessageChanges;
	
EndFunction

// Restore changes to messages of data areas.
// 
// Parameters:
//  MessageChanges - See GetDataAreaMessagesChanges
Procedure RestoreDataAreaMessagesChanges(MessageChanges)
	
	For Each MessageData In MessageChanges Do
		ExchangePlans.RecordChanges(MessageData.Node, MessageData.Ref);
	EndDo;
	
EndProcedure

Function NewSavedData()
	
	StoredData = New Structure();
	StoredData.Insert("DataAreas");
	StoredData.Insert("RecoveryExtensions");
	StoredData.Insert("DataAreaMessagesChanges");
	StoredData.Insert("ExclusiveLockSet");
	
	Return StoredData;
	
EndFunction

#EndRegion

#EndIf
