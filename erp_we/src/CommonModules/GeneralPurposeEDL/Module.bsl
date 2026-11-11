
#Region Internal

#Region TransitionalProceduresAndFunctionsOfBSP

// SeeCommon.IsRecordSetAddition
Function IsRecordSetAddition(Mode) Export
	
	Return Mode = False Or Common.IsRecordSetAddition(Mode);
	
EndFunction

// SeeCommon.IsRecordSetReplacement
Function IsRecordSetReplacement(Mode) Export
	
	Return Mode = True Or Common.IsRecordSetReplacement(Mode);
	
EndFunction

// SeeCommon.IsRecordSetUpdate
Function IsRecordSetUpdate(Mode) Export
	
	Return Common.IsRecordSetUpdate(Mode);
	
EndFunction

// SeeCommon.IsRecordSetMerge
Function IsRecordSetMerge(Mode) Export
	
	Return Common.IsRecordSetMerge(Mode);
	
EndFunction

// Checks that the specified mode corresponds to deleting a recordset.
//
// Parameters:
//  RecordSet - InformationRegisterRecordSet
//  Mode - Boolean, Substitution mode
//
// Returns:
//  Boolean
//
Function IsRecordSetDeletion(RecordSet, Mode) Export
	
	Return RecordSet.Count() = 0 Or Common.IsRecordSetDeletion(Mode);
	
EndFunction

#EndRegion

#Region Locks

// Sets a managed lock on field values.
//
// Parameters:
//  Tablespace - String - lock space.
//  Fields - Structure - the key specifies the name of the lock space field, and the value:
//                     1. The source is set: the corresponding source field containing the values for blocking.
//                     2. The source is not specified: directly the value for blocking.
//  Source - QueryResult, TabularSection, ValueTable  - data source.
//  Mode - DataLockMode - lock mode.
//        - Undefined - the default value is "Exceptional".
//
Procedure SetManagedLock(Val Tablespace, Val Fields = Undefined, Val Source = Undefined, Val Mode = Undefined) Export
	
	If Mode = Undefined Then
		Mode = DataLockMode.Exclusive;
	EndIf;
	
	If Fields = Undefined Then
		Fields = New Structure;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add(Tablespace);
	If Source = Undefined Then
		For Each KeyValue In Fields Do
			LockItem.SetValue(KeyValue.Key, KeyValue.Value);
		EndDo;
	Else
		LockItem.DataSource = Source;
		For Each KeyValue In Fields Do
			LockItem.UseFromDataSource(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	LockItem.Mode = Mode;
	Block.Lock();
	
EndProcedure

// Sets a managed lock on an object reference.
//
// Parameters:
//  Ref - AnyRef - the link to use to set the lock.
//  Mode - DataLockMode - lock mode.
//        - String - valid values are "Shared" and "Exclusive".
//        - Undefined - the default value is "Exceptional".
//
Procedure SetManagedLockOnLink(Val Ref, Val Mode = Undefined) Export
	
	ObjectMetadata = Ref.Metadata();
	LockSpace = ObjectMetadata.FullName();
	
	Fields = New Structure("Ref", Ref);
	
	SetManagedLock(LockSpace, Fields,, Mode);
	
EndProcedure

// Sets a managed lock on a set of records.
// The set selections in the set are used.
//
// Parameters:
//  Set - InformationRegisterRecordSet, AccumulationRegisterRecordSet - the set to set the lock on.
//  Mode - DataLockMode - lock mode.
//        - String - valid values are "Shared" and "Exclusive".
//        - Undefined - the default value is "Exceptional".
//
Procedure SetManagedLockOnSetOfRecords(Val Set, Val Mode = Undefined) Export
	
	ObjectMetadata = Set.Metadata();
	LockSpace = ObjectMetadata.FullName();
	
	Fields = New Structure;
	For Each FilterElement In Set.Filter Do
		If FilterElement.Use Then
			Fields.Insert(FilterElement.DataPath, FilterElement.Value);
		EndIf;
	EndDo;
	
	SetManagedLock(LockSpace, Fields,, Mode);
	
EndProcedure

#EndRegion

#Region EventLog

// Returns the parameters of the log entry, See WriteToLog_.
// 
// Returns:
// 	Structure - LongDesc:
// * MetadataObject - MetadataObject - see syntax -an assistant to the log recording method
// * Data - Arbitrary - see syntax -an assistant to the log recording method
// * TransactionMode - EventLogEntryTransactionMode - see syntax -an assistant to the log recording method
Function NewLogEntryOptions() Export
	
	Parameters = New Structure;
	Parameters.Insert("MetadataObject", Undefined);
	Parameters.Insert("Data", Undefined);
	Parameters.Insert("TransactionMode", Undefined);
	
	Return Parameters;
	
EndFunction

// This procedure is used to standardize all event records of the Electronic Interaction subsystem
// in the log. As a result, a grouping of records with a hierarchy is added to the log.
//  Electronic interaction:
//    |_ General subsystem
//    |_ Exchange with banks
//    |_ Exchange with counterparties
//    |_ Sharing with websites
//    |_ Routine tasks
//    |_ Business network.
// Parameters:
//   Comment - String - see syntax -an assistant to the log recording method
//   Subsystem - String - the name of the subsystem, see subsystem, will be added to the event name
//   Level - EventLogLevel - see the syntax helper for the Registration log recording method, the
//                                         default value is Log Log level.A mistake.
//   WriteParameters - See NewLogEntryOptions
Procedure WriteToLog_(Comment, Subsystem, Level = Undefined,
	WriteParameters = Undefined) Export
	
	If WriteParameters = Undefined Then
		WriteParameters = NewLogEntryOptions();
	EndIf;
	
	FullNameOfEvent = "";
	
	If Common.SubsystemExists(Subsystem) Then
		SubsystemsNames = StrSplit(Subsystem, ".", False);
		FullSubsystemName = "";
		For Each SubsystemName In SubsystemsNames Do
			FullSubsystemName = ?(IsBlankString(FullSubsystemName), FullSubsystemName,
				FullSubsystemName + ".") + "Subsystem." + SubsystemName;
			MetadataObjectSubsystem = Metadata.FindByFullName(FullSubsystemName);
			PresentationOfSubsystem = StrTemplate(NStr("vi = '%1';
														|ru = '%1';
														|en = '%1'; fa = '%1';
														|it = '%1';
														|pl = '%1';
														|tr = '%1'", Common.DefaultLanguageCode()),
				Common.ObjectPresentation(MetadataObjectSubsystem));
			FullNameOfEvent = ?(IsBlankString(FullNameOfEvent), FullNameOfEvent,
				FullNameOfEvent + ".") + PresentationOfSubsystem;
		EndDo;
	EndIf;
	
	If IsBlankString(FullNameOfEvent) Then
		FullNameOfEvent = NStr("vi = 'Tương tác trực tuyến.Phân hệ chung';
								|ru = 'Электронное взаимодействие.Общая подсистема';
								|en = 'Electronic interaction.Common subsystem'; fa = 'Electronic interaction.Common subsystem';
								|it = 'Electronic interaction.Common subsystem';
								|pl = 'Electronic interaction.Common subsystem';
								|tr = 'Elektronik etkileşim. Ortak alt sistem'",
			Common.DefaultLanguageCode());
	EndIf;
	
	EventImportanceLevel = ?(TypeOf(Level) = Type("EventLogLevel"),
		Level, EventLogLevel.Error);
	
	WriteLogEvent(FullNameOfEvent, EventImportanceLevel, WriteParameters.MetadataObject,
		WriteParameters.Data, Comment, WriteParameters.TransactionMode);
	
EndProcedure

#EndRegion

#Region ErrorPresentation

// Parameters:
//  ErrorInfo - ErrorInfo
// 
// Returns:
//  String
Function BriefPresentationOfErrorInformation(ErrorInfo) Export
	Return ErrorProcessing.BriefErrorDescription(ErrorInfo)
EndFunction

// Parameters:
//  ErrorInfo - ErrorInfo
// 
// Returns:
//  String
Function DetailedPresentationOfErrorInformation(ErrorInfo) Export
	Return ErrorProcessing.DetailErrorDescription(ErrorInfo)
EndFunction

#EndRegion


#EndRegion

