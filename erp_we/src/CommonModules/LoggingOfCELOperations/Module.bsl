///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// ++ Non-mobile application 

#Region PeripheralLogging

// Returns parameters for logging hardware
// 
// Returns:
//  Structure - Parameters For Logging Hardware of Operations:
//   * UseLogging - Boolean - 
//   * TransferIntervalATServer - Number - transfer interval at server in seconds, minimum 60
//
Function ParametersForLoggingHardwareOfOperations() Export
	
	SetPrivilegedMode(True);
	Result = New Structure();
	Result.Insert("UseLogging", True);
	Result.Insert("TransferIntervalATServer", 60);
	LoggingOfCELOperationsOverridable.WhenDeterminingLoggingParametersOfConnectedEquipment(Result);
	Return Result;
	
EndFunction

Procedure SetShelfLifeOfOperationsWithEquipment() Export
	
	SetPrivilegedMode(True);
	RetentionPeriodOfOperationsWithPeripherals = Constants.RetentionPeriodOfOperationsWithPeripherals.Get();
	If Not ValueIsFilled(RetentionPeriodOfOperationsWithPeripherals) Then
		Constants.RetentionPeriodOfOperationsWithPeripherals.Set(Enums.RetentionPeriodOfTransactionHistory.Month);
	EndIf;
	If RetentionPeriodOfOperationsWithPeripherals <> Enums.RetentionPeriodOfTransactionHistory.AllTime Then
		EnableUseOfRoutineTasks("ClearHistoryOfOperationsWithPeripherals");
	EndIf;
	
EndProcedure

// Returns the storage period of operations with hardware
//
// Returns:
//   EnumRef
//
Function PeriodOfStoringHistoryOfOperationsWithEquipment() Export
	
	StoragePeriod = Constants.RetentionPeriodOfOperationsWithPeripherals.Get();
	Return StoragePeriod;
	
EndFunction

// Will clear the history of operations with equipment
//
Procedure ClearHistoryOfOperationsWithPeripherals() Export
	
	CommonCEL.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ClearHistoryOfOperationsWithPeripherals);
	
	If CommonCEL.LoggingSubsystemIsUsed() Then
		
		StoragePeriod = PeriodOfStoringHistoryOfOperationsWithEquipment();
		ClearDate    = DetermineDateOfCleaningOperations(StoragePeriod);
		If ClearDate = Undefined Then
			Return;
		EndIf;
		
		ModuleOfOperationsWithConnectedEquipment = 
			CommonCEL.CommonModule("InformationRegisters.OperationsWithPeripherals");
		ModuleOfOperationsWithConnectedEquipment.ClearRegisterForPastMonths(ClearDate);
		ModuleOfOperationsWithConnectedEquipment.ClearCurMONTHREGISTER(ClearDate);
		
	EndIf;
	
	
EndProcedure

#EndRegion

#Region ScheduledJobs

// It is called from the routine taskdetermined procedure.When
// defining the settings of the scheduled tasks to set the availability of the scheduled task, determines the dependence on the functional options.
// 
// Parameters:
//  Settings - ValueTable
//  FunctionalOption - MetadataObjectFunctionalOption
Procedure OnDefineScheduledJobSettings(Settings, FunctionalOption = Undefined) Export
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ClearHistoryOfOperationsWithPeripherals;
	Setting.FunctionalOption = FunctionalOption;
	Setting.UseExternalResources = True;
	
EndProcedure

#EndRegion

#Region RoutineTasksServiceTechnology

// See JobsQueueOverridable.OnGetTemplateList
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.ClearHistoryOfOperationsWithPeripherals.Name);
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.ClearHistoryOfOperationsWithPeripherals.MethodName);
	
EndProcedure

#EndRegion

// Will clear the history of payment transactions
//
Procedure ClearHistoryOfPaymentTransactions() Export
	
	CommonCEL.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ClearHistoryOfPaymentTransactions);
	
	If CommonCEL.UsedPaymentSystems() Then
		
		StoragePeriod = RetentionPeriodOfPaymentTransactionHistory();
		ClearDate = DetermineDateOfCleaningOperations(StoragePeriod);
		
		ModuleEquipmentPaymentSystems = CommonCEL.CommonModule("PeripheralsPaymentSystemsServer");
		ModuleEquipmentPaymentSystems.ClearHistoryOfPaymentTransactions(ClearDate);
		
	EndIf;
	
EndProcedure

// Will clear the history of fiscal transactions
//
Procedure ClearHistoryOfFiscalTransactions() Export
	
	CommonCEL.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ClearHistoryOfFiscalTransactions);
	
	If CommonCEL.CheckPrintingDevicesAreUsed() Then
		
		StoragePeriod = PeriodOfStorageOfHistoryOfFiscalTransactions();
		ClearDate = DetermineDateOfCleaningOperations(StoragePeriod);
		
		ModuleEquipmentReceiptPrintingDevices = CommonCEL.CommonModule("PeripheralsReceiptPrinters");
		ModuleEquipmentReceiptPrintingDevices.ClearHistoryOfFiscalTransactions(ClearDate);
		
	EndIf;
	
EndProcedure

// -- Non-mobile application 

Function DetermineDateOfCleaningOperations(StoragePeriod) Export
	
	CurrentDate = CommonCEL.SessionDate();
	If StoragePeriod = Enums.RetentionPeriodOfTransactionHistory.Day Then
		OneDaySeconds = 60*60*24*1;
		ClearDate = CurrentDate - OneDaySeconds;
	ElsIf StoragePeriod = Enums.RetentionPeriodOfTransactionHistory.Week Then
		WeekSeconds = 60*60*24*7;
		ClearDate = CurrentDate - WeekSeconds;
	ElsIf StoragePeriod = Enums.RetentionPeriodOfTransactionHistory.TenDays Then
		DecadeSeconds = 60*60*24*10;
		ClearDate = CurrentDate - DecadeSeconds;
	ElsIf StoragePeriod = Enums.RetentionPeriodOfTransactionHistory.Month Then
		ClearDate = AddMonth(CurrentDate, -1);
	ElsIf StoragePeriod = Enums.RetentionPeriodOfTransactionHistory.Quarter Then
		ClearDate = AddMonth(CurrentDate, -3);
	ElsIf StoragePeriod = Enums.RetentionPeriodOfTransactionHistory.HalfYear Then
		ClearDate = AddMonth(CurrentDate, -6);
	ElsIf StoragePeriod = Enums.RetentionPeriodOfTransactionHistory.Year Then
		ClearDate = AddMonth(CurrentDate, -12);
	Else
		Return Undefined;
	EndIf;
	
	Return ClearDate;
	
EndFunction

#Region AllowedMethodsToBeCalledAsArbitraryCode

// Returns a list of methods that can be called as arbitrary code
// (for routine tasks and background tasks)
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("ClearHistoryOfOperationsWithPeripherals", True);
	Methods.Insert("ClearingHistoryOfOperationsForCheckingKM", True);
	Methods.Insert("ClearHistoryOfReceiptQueueOperations", True);
	Methods.Insert("ClearHistoryOfFiscalTransactions", True);
	Methods.Insert("ClearHistoryOfPaymentTransactions", True);
	Methods.Insert("RecordLogOfOperationsATServer", True);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// ++ Non-mobile application 

// Returns the period for storing fiscal transactions in the information register
//
// Returns:
//   EnumRef.RetentionPeriodOfTransactionHistory
Function PeriodOfStorageOfHistoryOfFiscalTransactions()
	
	StoragePeriod = Undefined;
	If CommonCEL.CheckPrintingDevicesAreUsed() Then
		ModuleEquipmentReceiptPrintingDevices = CommonCEL.CommonModule("PeripheralsReceiptPrinters");
		StoragePeriod = ModuleEquipmentReceiptPrintingDevices.PeriodOfStorageOfHistoryOfFiscalTransactions();
	EndIf;
	Return StoragePeriod;
	
EndFunction

// Returns the period for storing payment transactions in the information register
//
// Returns:
//   EnumRef.RetentionPeriodOfTransactionHistory
Function RetentionPeriodOfPaymentTransactionHistory()
	
	StoragePeriod = Undefined;
	If CommonCEL.UsedPaymentSystems() Then
		ModuleEquipmentPaymentSystems = CommonCEL.CommonModule("PeripheralsPaymentSystemsServer");
		StoragePeriod = ModuleEquipmentPaymentSystems.RetentionPeriodOfPaymentTransactionHistory();
	EndIf;
	Return StoragePeriod;
	
EndFunction


Procedure RecordLogOfOperationsATServer(Records) Export
	
	InformationRegisters.OperationsWithPeripherals.RecordLogOfOperationsATServer(Records);
	
EndProcedure

Procedure RecordLogOfOperationsATServerInBackground(Records) Export
	
	If CommonCEL.BSPIsUsed() Then
		
		ModuleTimeConsumingOperations = CommonCEL.CommonModule("TimeConsumingOperations");
		ProcedureExecutionParameters = ModuleTimeConsumingOperations.ProcedureExecutionParameters();
		ModuleTimeConsumingOperations.ExecuteProcedure(
			ProcedureExecutionParameters,
			"LoggingOfCELOperations.RecordLogOfOperationsATServer",
			Records);
	Else
		RecordLogOfOperationsATServer(Records);
	EndIf;
		
EndProcedure


Function RecordLogOfOperationsATServer_ConversionToJSON(Property, Value, AdditionalParameters, Cancel) Export  
	
	Return String(Value);   
	
EndFunction

Function CollapseOperationLogEntries(Records, CollapsibleOperations) Export
	
	NewRecords = New Array();
	CollapsibleRecord = Undefined;
	
	For IndexOf = 0 To Records.UBound() Do
		
		Record = Records[IndexOf];
		Operation = Record.Operation;
		If StrFind(CollapsibleOperations, Operation)=0 Then
			CollapsibleRecord = Undefined;
			NewRecords.Add(Record);
			Continue;
		EndIf;
		
		If CollapsibleRecord = Undefined Then
			CollapsibleRecord = Record;
			NewRecords.Add(Record);
			Continue;
		EndIf;
		
		If Not SameOperation(CollapsibleRecord, Record) Then
			CollapsibleRecord = Undefined;
			NewRecords.Add(Record);
			Continue;
		EndIf;
		
		// the previous and current of operations are the same
		// , we skip the current entry and fill in the previous (collapsible) one that has already been entered into the array earlier
		If TypeOf(CollapsibleRecord.IncomingParameters) <> Type("Array") Then
			NewParameters = New Array();
			NewParameters.Add(CollapsibleRecord.IncomingParameters);
			CollapsibleRecord.IncomingParameters = NewParameters;
			
			NewParameters = New Array();
			NewParameters.Add(CollapsibleRecord.OutgoingParameters);
			CollapsibleRecord.OutgoingParameters = NewParameters;
		EndIf;
		
		CollapsibleRecord.IncomingParameters.Add(Record.IncomingParameters);
		CollapsibleRecord.OutgoingParameters.Add(Record.OutgoingParameters);
		CollapsibleRecord.RunTime = CollapsibleRecord.RunTime + Record.RunTime;
		
	EndDo;
	Return NewRecords;
	
EndFunction

#Region PeripheralLogging

Function SameOperation(Record1, Record2)
	
	If Record1.Operation = Record2.Operation
		And Record1.Equipment = Record2.Equipment
		And Record1.DriverVersion = Record2.DriverVersion
		And Record1.Result = Record2.Result
		And Record1.EntryType = Record2.EntryType
		And Record1.InterfaceRevision = Record2.InterfaceRevision Then
		Return True;
	EndIf;
	
	Return False;
EndFunction

Function FormatOfLoggingParameter(Text) Export
	
	If Not ValueIsFilled(Text) Then
		Return "";
	EndIf;
	If StrStartsWith(Text, "{") Or StrStartsWith(Text, "[") Then
		Result = "";
		JSONReader = New JSONReader();
		JSONReader.SetString(Text);
		
		Data = ReadJSON(JSONReader, True);
		Result = StringOfValues(Data);
		Return Result;
	Else
		Return Text;
	EndIf;
	
EndFunction

Function StringOfValues(Value, Indent="")
	Result = "";
	If TypeOf(Value) = Type("Array") Then
		For IndexOf = 0 To Value.UBound() Do
			AttributeValue = StringOfValues(Value[IndexOf], Chars.Tab);
			Result = Result + Indent + StrTemplate("[%1]: %2", IndexOf, AttributeValue) + Chars.LF;
		EndDo;
	Else
		For Each KeyValue In Value Do
			Result = Result + Indent + StrTemplate("%1:", KeyValue.Key) + Chars.LF;
			If TypeOf(KeyValue.Value) = Type("Map") Then
				AttributeValue = StringOfValues(KeyValue.Value, Chars.Tab);
				Result = Result + Indent + AttributeValue + Chars.LF;
			ElsIf TypeOf(KeyValue.Value) = Type("Structure") Then
				AttributeValue = StringOfValues(KeyValue.Value, Chars.Tab);
				Result = Result + Indent + AttributeValue + Chars.LF;
			ElsIf TypeOf(KeyValue.Value) = Type("Array") Then
				For Each Item In KeyValue.Value Do
					AttributeValue = StringOfValues(Item, Chars.Tab);
					Result = Result + Indent + "- " + AttributeValue + Chars.LF;
				EndDo;
			ElsIf StrStartsWith(KeyValue.Value, "<?xml") Then
				Result = Result + Indent + XMLFormat(KeyValue.Value) + Chars.LF;
			Else
				Result = Result + Chars.Tab + Indent + KeyValue.Value + Chars.LF;
			EndIf;
		EndDo;
	EndIf;
	Return Result;
	
EndFunction

Function XMLFormat(Text)
	
	XMLReader = New XMLReader();
	XMLReader.SetString(Text);
	XMLReader.Read();
	
	Builder = New DOMBuilder();
	Try
		Value = Builder.Read(XMLReader)
	Except
		Return Text;
	EndTry;
	
	XMLWriter = New XMLWriter();
	XMLWriter.SetString(New XMLWriterSettings("UTF-8",,True, True));
	
	DOMWriter = New DOMWriter();
	DOMWriter.Write(Value, XMLWriter);
	Return XMLWriter.Close();
	
EndFunction

Function RoutineAssignmentByName(JobName)
	
	// Calling BSP
	If CommonCEL.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		
		ModuleScheduledJobsServer = CommonCEL.CommonModule("ScheduledJobsServer");
		FilterParameters = New Structure;
		FilterParameters.Insert("Metadata", JobName);
		TaskReg = ModuleScheduledJobsServer.FindJobs(FilterParameters);
		If TaskReg.Count() > 0 Then
			Return TaskReg[0];
		EndIf;
		
	EndIf;
	// The end of the BSP Challenge
	
	Return Undefined;
	
EndFunction

Procedure EnableUseOfRoutineTasks(JobName)
	
	// Calling BSP
	If CommonCEL.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		
		ModuleScheduledJobsServer = CommonCEL.CommonModule("ScheduledJobsServer");
		
		SchedJob = RoutineAssignmentByName(JobName);
		If SchedJob = Undefined Then
			Return;
		EndIf;

		JobParameters = New Structure;
		JobParameters.Insert("Use", True);
		ModuleScheduledJobsServer.ChangeJob(SchedJob.UUID, JobParameters);
		
	Else
		#If Not MobileAppServer Then
		RegTaskMetadata = Metadata.ScheduledJobs.Find(JobName);
		SchedJob = ScheduledJobs.FindPredefined(RegTaskMetadata);
		SchedJob.Use = True;
		SchedJob.Write();
		#EndIf
	EndIf;
	// The end of the BSP Challenge
	
EndProcedure

#EndRegion

// -- Non-mobile application 

#EndRegion


