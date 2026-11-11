// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Parameters:
//  JobID - UUID - id of the background job of the thread for which the object is being obtained
//  ByProcessingPriority - Boolean - Indicates whether an object has been received, taking into account the priority of object processing
// 
// Returns:
//  Structure - Getting An Object To Be Processed:
// * HasObjectsToProcessing - Boolean
// * Object - See InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection
Function GetObjectToProcessing(JobID, ByProcessingPriority = False) Export
	
	Result = New Structure();
	Result.Insert("HasObjectsToProcessing", False);
	Result.Insert("Object", Undefined);
	
	Block = New DataLock();
	LockItem = Block.Add("InformationRegister.ExportImportMetadataObjects");
	LockItem.SetValue("ProcessingProcedure_", 0);
	
	BeginTransaction();
	
	Try
		
		Block.Lock();
		
		ObjectSelection = ObjectsForProcessingSelection(False, 1);
		
		If ObjectSelection.Next() Then
			
			Result.HasObjectsToProcessing = True;
			Result.Object = ObjectSelection;
			
			If ByProcessingPriority Then
				
				ImportPriority = ImportingMetadataObjectPriority();
				ObjectPriority = PriorityFromProcessingOrder(ObjectSelection.ProcessingProcedure_);
				
				If ImportPriority <> ObjectPriority Then
					Result.Object = Undefined;
				EndIf;
				
			EndIf;
			
			If InformationRegisters.ExportImportDataThreads.NeedToCompleteThread(JobID) Then
				Result.HasObjectsToProcessing = False;
				Result.Object = Undefined;
			EndIf;
			
			If Result.Object <> Undefined Then
				CommitObjectProcessingStart(Result.Object);
			EndIf;
		
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	Return Result;
	
EndFunction

// Selecting objects to upload.
// 
// Parameters:
//  InProcessing - Boolean - Indicates the selection of objects that are being processed or not processed before.
//  ObjectCount - Number - Number of objects in the selection
// 
// Returns:
//  QueryResultSelection - Selecting objects to upload:
//  * ProcessingProcedure_ - Number - The number of the object in the order of processing
//  * MetadataObject - String - full name of the metadata object
Function ObjectsForProcessingSelection(InProcessing = False, ObjectCount = 0) Export
	
	Query = New Query();
	Query.SetParameter("InProcessing", InProcessing);
	
	Query.Text = 
	"SELECT TOP 1000
	|	ExportImportMetadataObjects.ProcessingProcedure_ AS ProcessingProcedure_,
	|	ExportImportMetadataObjects.MetadataObject AS MetadataObject
	|FROM
	|	InformationRegister.ExportImportMetadataObjects AS ExportImportMetadataObjects
	|WHERE
	|	ExportImportMetadataObjects.InProcessing = &InProcessing
	|
	|ORDER BY
	|	ExportImportMetadataObjects.ProcessingProcedure_";
	
	TextFirst = ?(ValueIsFilled(ObjectCount), "FIRST " + Format(ObjectCount, "NG=0;"), "");
	Query.Text = StrReplace(Query.Text, "TOP 1000", TextFirst);
	
	Return Query.Execute().Select();
	
EndFunction

// There are processed metadata objects.
// 
// Returns:
//  Boolean - There Are Processed Metadata Objects
Function HasProcessedMetadataObjects() Export
	
	Query = New Query();
	Query.Text = 
	"SELECT TOP 1
	|	TRUE AS Result
	|FROM
	|	InformationRegister.ExportImportMetadataObjects AS ExportImportMetadataObjects
	|WHERE
	|	ExportImportMetadataObjects.InProcessing";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Record the start of object processing.
// 
// Parameters:
//  ObjectSelection - See InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection
Procedure CommitObjectProcessingStart(ObjectSelection) Export
	
	RegisterRecord = GetRecordManager(ObjectSelection);
	RegisterRecord.InProcessing = True;
	RegisterRecord.Write();
	
EndProcedure

// Record the end of object processing.
// 
// Parameters:
//  ObjectSelection - See InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection
Procedure RecordObjectProcessingEnd(ObjectSelection) Export
	
	RegisterRecord = GetRecordManager(ObjectSelection);
	RegisterRecord.InProcessing = False;
	RegisterRecord.Write();
	
EndProcedure

// Delete the entry.
// 
// Parameters:
//  ObjectSelection - See InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection
Procedure DeleteRecord(ObjectSelection) Export
	
	RegisterRecord = CreateRecordManager();
	RegisterRecord.ProcessingProcedure_ = ObjectSelection.ProcessingProcedure_;
	RegisterRecord.Delete();
	
EndProcedure

// Priority of the metadata object being loaded.
// 
// Returns:
//  Undefined, Number - Priority Of The Metadata Object Being Loaded
Function ImportingMetadataObjectPriority() Export
	
	Query = New Query();
	Query.Text = 
	"SELECT TOP 1
	|	ExportImportMetadataObjects.ProcessingProcedure_ AS ProcessingProcedure_
	|FROM
	|	InformationRegister.ExportImportMetadataObjects AS ExportImportMetadataObjects
	|WHERE
	|	ExportImportMetadataObjects.InProcessing
	|
	|ORDER BY
	|	ExportImportMetadataObjects.ProcessingProcedure_";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return PriorityFromProcessingOrder(Selection.ProcessingProcedure_);
	EndIf;
	
	Query.Text = 
	"SELECT TOP 1
	|	ExportImportMetadataObjects.ProcessingProcedure_ AS ProcessingProcedure_
	|FROM
	|	InformationRegister.ExportImportMetadataObjects AS ExportImportMetadataObjects
	|WHERE
	|	NOT ExportImportMetadataObjects.InProcessing
	|
	|ORDER BY
	|	ExportImportMetadataObjects.ProcessingProcedure_";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return PriorityFromProcessingOrder(Selection.ProcessingProcedure_);
	EndIf;
	
	Return Undefined;
	
EndFunction

// The priority of the processing order.
// 
// Parameters:
//  ProcessingProcedure_ - Number - Processing Procedure
// 
// Returns:
//  Number - Priority From The Processing Order
Function PriorityFromProcessingOrder(ProcessingProcedure_) Export
	
	Return Int(ProcessingProcedure_ / 10000);
	
EndFunction

// There are unprocessed metadata objects.
// 
// Returns:
//  Boolean
Function ThereAreUnprocessedMetadataObjects() Export
	
	Query = New Query();
	Query.Text = 
	"SELECT TOP 1
	|	TRUE AS Result
	|FROM
	|	InformationRegister.ExportImportMetadataObjects AS ExportImportMetadataObjects
	|WHERE
	|	NOT ExportImportMetadataObjects.InProcessing";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#Region Private

// Get a record manager.
// 
// Parameters:
//  ObjectSelection - See InformationRegisters.ExportImportMetadataObjects.ObjectsForProcessingSelection
// 
// Returns:
//  InformationRegisterRecordManager.ExportImportMetadataObjects - register entry manager
Function GetRecordManager(ObjectSelection)
	
	RegisterRecord = CreateRecordManager();
	RegisterRecord.ProcessingProcedure_ = ObjectSelection.ProcessingProcedure_;
	RegisterRecord.Read();
	
	If Not RegisterRecord.Selected() Or RegisterRecord.MetadataObject <> ObjectSelection.MetadataObject Then
		
		ErrorText = StrTemplate(
			NStr("vi = 'Đối tượng metadata chọn ''%1'' không tương ứng với giá trị bản ghi ''%2''';
				|ru = 'Объект метаданных выборки ''%1'' не соответствует значению записи ''%2''';
				|en = 'The metadata object of the ''%1'' dataset does not correspond to the ''%2'' record value.'; fa = 'The metadata object of the ''%1'' dataset does not correspond to the ''%2'' record value.';
				|it = 'Объект метаданных выборки ''%1'' не соответствует значению записи ''%2''';
				|pl = 'The metadata object of the ''%1'' dataset does not correspond to the ''%2'' record value.';
				|tr = 'Seçilmiş ''%1'' meta veri nesnesi, ''%2'' kaydı değeriyle eşleşmiyor'"),
			ObjectSelection.MetadataObject,
			?(RegisterRecord.Selected(), RegisterRecord.MetadataObject, NStr("vi = 'Không tìm thấy bản ghi';
																			|ru = 'Запись не найдена';
																			|en = 'Record is not found'; fa = 'Record is not found';
																			|it = 'Запись не найдена';
																			|pl = 'Record is not found';
																			|tr = 'Kayıt bulunamadı'")));
		
		Raise ErrorText;
		
	EndIf;
	
	Return RegisterRecord;
	
EndFunction

#EndRegion

#EndIf
