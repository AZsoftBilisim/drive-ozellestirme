#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.AccessManagement
// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
//
// Parameters:
//  Restriction - Structure:
//    * Text                             - String - restricting access for users.
//                                          If the string is empty, it means that access is allowed.
//    * TextForExternalUsers1      - String - restricting access for external users.
//                                          If the string is empty, it means that access is denied.
//    * ByOwnerWithoutSavingAccessKeys - Undefined - to determine automatically.
//                                        - Boolean - if False, then always write access keys,
//                                          if True, then do not write access keys,
//                                          but use the owner's access keys (it is required
//                                          that the restriction be strictly on the owner object).
//   * ByOwnerWithoutSavingAccessKeysForExternalUsers - Undefined, Boolean - the
//                                          same as for the parameter for the owner of the record of the key access.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Manager = "InformationRegister.OperationsWithPeripherals";
	EquipmentManagerServerCallOverridable.OnFillAccessRestriction(Manager, Restriction);
	
EndProcedure
// End StandardSubsystems.AccessManagement

#EndRegion

#Region Internal

// Performs deletion of registry entries for the past months to speed up the cleanup
// 
// Parameters:
//   ClearDate - Date - The date in the month before which the cleanup will be performed, 
//     the deletion of records will be performed before the end of the month of the transmitted date.
Procedure ClearRegisterForPastMonths(ClearDate) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED DISTINCT
		|	OperationsWithPeripherals.YearMonth AS YearMonth
		|FROM
		|	InformationRegister.OperationsWithPeripherals AS OperationsWithPeripherals
		|WHERE
		|	OperationsWithPeripherals.YearMonth < &YearMonthOfCleaning";
	
	YearMonthOfCleaning = Year(ClearDate) * 100 + Month(ClearDate);
	Query.SetParameter("YearMonthOfCleaning", YearMonthOfCleaning);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.OperationsWithPeripherals");
		LockItem.DataSource = QueryResult;
		LockItem.UseFromDataSource("YearMonth","YearMonth");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		RecordSet = CreateRecordSet();
		Selection      = QueryResult.Select();
		While Selection.Next() Do
			RecordSet.Clear();
			RecordSet.Filter.YearMonth.Set(Selection.YearMonth);
			RecordSet.Write(True);
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Xóa giao dịch với thiết bị.';
				|ru = 'Очистка операций с оборудованием.';
				|en = 'Clear peripheral operations.'; fa = 'Clear peripheral operations.';
				|it = 'Очистка операций с оборудованием.';
				|pl = 'Clear peripheral operations.';
				|tr = 'Ekipman işlemleri temizliği.'", CommonCEL.DefaultLanguageCode()));
	EndTry
	
EndProcedure

// Deletes register entries in the month of the transmitted date
// 
// Parameters:
//   ClearDate - Date - The date before which the cleanup will be performed in the month of the date
//     records will be deleted from the beginning of the month, on the transmitted date.
Procedure ClearCurMONTHREGISTER(ClearDate) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	OperationsWithPeripherals.Date AS Date,
		|	OperationsWithPeripherals.Equipment AS Equipment,
		|	OperationsWithPeripherals.OperationNumber AS OperationNumber,
		|	OperationsWithPeripherals.YearMonth AS YearMonth
		|FROM
		|	InformationRegister.OperationsWithPeripherals AS OperationsWithPeripherals
		|WHERE
		|	OperationsWithPeripherals.YearMonth = &YearMonthOfCleaning
		|	AND OperationsWithPeripherals.Date < &ClearDate";
	
	YearMonthOfCleaning = Year(ClearDate) * 100 + Month(ClearDate);
	Query.SetParameter("YearMonthOfCleaning", YearMonthOfCleaning);
	Query.SetParameter("ClearDate",     ClearDate);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.OperationsWithPeripherals");
		LockItem.DataSource = QueryResult;
		LockItem.UseFromDataSource("Equipment","Equipment");
		LockItem.UseFromDataSource("Date","Date");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		RecordSet = CreateRecordSet();
		Selection      = QueryResult.Select();
		If CommonCELCached.SubstitutionModeIsAvailable() Then
			While Selection.Next() Do
				FillPropertyValues(RecordSet.Add(), Selection);
			EndDo;
			RecordSet.Write(CommonCELCached.ReplacementModeDeletion());
		Else
			While Selection.Next() Do
				RecordSet.Clear();
				RecordSet.Filter.Equipment.Set(Selection.Equipment);
				RecordSet.Filter.Date.Set(Selection.Date);
				RecordSet.Write(True);
			EndDo;
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Xóa giao dịch với thiết bị.';
				|ru = 'Очистка операций с оборудованием.';
				|en = 'Clear peripheral operations.'; fa = 'Clear peripheral operations.';
				|it = 'Очистка операций с оборудованием.';
				|pl = 'Clear peripheral operations.';
				|tr = 'Ekipman işlemleri temizliği.'", CommonCEL.DefaultLanguageCode()));
	EndTry
	
EndProcedure

Procedure RecordLogOfOperationsATServer(Records) Export
	
	SetPrivilegedMode(True);
	CompressionDegree = 9;
	
	RecordSet = InformationRegisters.OperationsWithPeripherals.CreateRecordSet();
	OperationNumber = 0;
	For Each Operation In Records Do
		
		Record = RecordSet.Add();
		
		FillPropertyValues(Record, Operation, , "IncomingParameters, OutgoingParameters, ErrorText");
		Record.Millisecond = Operation.Timecode % 1000;
		Record.YearMonth = Year(Record.Date)*100+Month(Record.Date);
		OperationNumber = OperationNumber + 1;
		Record.OperationNumber = OperationNumber;
		Record.InterfaceRevision = CommonCELClientServer.PresentationRevisionOfInterface(Operation.InterfaceRevision);
		If StrFind(Operation.PresentationOperation, " ")=0 Then
			Record.Operation = CommonCELClientServer.IDPresentation(Operation.PresentationOperation);
		Else
			Record.Operation = Operation.PresentationOperation;
		EndIf;
		
		If ValueIsFilled(Operation.IncomingParameters) Then
			JSONWriter = New JSONWriter();
			JSONWriter.SetString();
			WriteJSON(JSONWriter, Operation.IncomingParameters, , "StringInJSON", CommonCEL);
			Record.IncomingParameters = New ValueStorage(JSONWriter.Close(), New Deflation(CompressionDegree));
		EndIf;
		
		If ValueIsFilled(Operation.OutgoingParameters) Then
			JSONWriter = New JSONWriter();
			JSONWriter.SetString();
			WriteJSON(JSONWriter, Operation.OutgoingParameters, , "StringInJSON", CommonCEL);
			Record.OutgoingParameters = New ValueStorage(JSONWriter.Close(), New Deflation(CompressionDegree));
		EndIf;
		
		If ValueIsFilled(Operation.ErrorText) Then
			Record.ErrorText = New ValueStorage(Operation.ErrorText, New Deflation(CompressionDegree));
		EndIf
	EndDo;
	
	RecordSet.Write(False);
	
EndProcedure

Function AdditionalInformationOfOperation(Var_Key) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	OperationsWithPeripherals.IncomingParametersString AS IncomingParametersString,
		|	OperationsWithPeripherals.IncomingParameters AS IncomingParameters,
		|	OperationsWithPeripherals.OutgoingParametersString AS OutgoingParametersString,
		|	OperationsWithPeripherals.OutgoingParameters AS OutgoingParameters,
		|	OperationsWithPeripherals.ErrorTextString AS ErrorTextString,
		|	OperationsWithPeripherals.ErrorText AS ErrorText
		|FROM
		|	InformationRegister.OperationsWithPeripherals AS OperationsWithPeripherals
		|WHERE
		|	OperationsWithPeripherals.Equipment = &Equipment
		|	AND OperationsWithPeripherals.Date = &Date
		|	AND OperationsWithPeripherals.OperationNumber = &OperationNumber
		|	AND OperationsWithPeripherals.YearMonth = &YearMonth";
	
	Query.SetParameter("YearMonth", Var_Key.YearMonth);
	Query.SetParameter("Date", Var_Key.Date);
	Query.SetParameter("OperationNumber", Var_Key.OperationNumber);
	Query.SetParameter("Equipment", Var_Key.Equipment);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	Result = New Structure;
	Result.Insert("IncomingParameters");
	Result.Insert("OutgoingParameters");
	Result.Insert("ErrorText");
	While Selection.Next() Do
		If ValueIsFilled(Selection.IncomingParametersString) Then
			Result.IncomingParameters = Selection.IncomingParametersString;
		Else
			Result.IncomingParameters = Selection.IncomingParameters.Get();
		EndIf;
		
		If ValueIsFilled(Selection.OutgoingParametersString) Then
			Result.OutgoingParameters = Selection.OutgoingParametersString;
		Else
			Result.OutgoingParameters = Selection.OutgoingParameters.Get();
		EndIf;
		If ValueIsFilled(Selection.ErrorTextString) Then
			Result.ErrorText = Selection.ErrorTextString;
		Else
			Result.ErrorText = Selection.ErrorText.Get();
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function ArchiveOfOperationsOfEquipment(Peripherals = Undefined) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	OperationsWithPeripherals.Equipment AS Equipment,
		|	OperationsWithPeripherals.Date AS Date,
		|	OperationsWithPeripherals.OperationNumber AS OperationNumber,
		|	OperationsWithPeripherals.YearMonth AS YearMonth,
		|	OperationsWithPeripherals.IncomingParametersString AS IncomingParametersString,
		|	OperationsWithPeripherals.IncomingParameters AS IncomingParameters,
		|	OperationsWithPeripherals.OutgoingParametersString AS OutgoingParametersString,
		|	OperationsWithPeripherals.OutgoingParameters AS OutgoingParameters,
		|	OperationsWithPeripherals.Result AS Result,
		|	OperationsWithPeripherals.Timecode AS Timecode,
		|	OperationsWithPeripherals.EntryType AS EntryType,
		|	OperationsWithPeripherals.VersionAddIn AS VersionAddIn,
		|	OperationsWithPeripherals.DriverVersion AS DriverVersion,
		|	OperationsWithPeripherals.Operation AS Operation,
		|	OperationsWithPeripherals.DeviceID_ AS DeviceID_,
		|	OperationsWithPeripherals.RunTime AS RunTime,
		|	OperationsWithPeripherals.InterfaceRevision AS InterfaceRevision,
		|	OperationsWithPeripherals.Millisecond AS Millisecond,
		|	OperationsWithPeripherals.ErrorCode AS ErrorCode,
		|	OperationsWithPeripherals.ErrorTextString AS ErrorTextString,
		|	OperationsWithPeripherals.ErrorText AS ErrorText
		|FROM
		|	InformationRegister.OperationsWithPeripherals AS OperationsWithPeripherals
		|WHERE
		|	OperationsWithPeripherals.Equipment = &Equipment";
	
	Query.SetParameter("Equipment", Peripherals);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	Data = New Array;
	While Selection.Next() Do
		DataString1 = GetBinaryDataFromString(LogEntryLine(Selection));
		Data.Add(DataString1);
	EndDo;
	
	Result = New Structure;
	Result.Insert("ArchiveDate", CurrentSessionDate());
	Result.Insert("ArchiveData", ConcatBinaryData(Data));
	Result.Insert("IsArchive", False);
	
	Return Result;
	
EndFunction

Function LogEntryLine(Record) Export
	
	RecordingStart = StrTemplate("%1 : %2; (%3);%4; [%5:%5:%6]; ""%8"";",
		Record.Date,
		Record.Millisecond,
		Record.RunTime,
		Record.EntryType,
		Record.InterfaceRevision,
		Record.DriverVersion,
		Record.VersionAddIn,
		Record.Operation);
		
	If ValueIsFilled(Record.IncomingParametersString) Then
		IncomingParameters = Record.IncomingParametersString;
	Else
		IncomingParameters = Record.IncomingParameters.Get();
	EndIf;
	If ValueIsFilled(Record.OutgoingParametersString) Then
		OutgoingParameters = Record.OutgoingParametersString;
	Else
		OutgoingParameters = Record.OutgoingParameters.Get();
	EndIf;
	If ValueIsFilled(Record.ErrorTextString) Then
		ErrorText = Record.ErrorTextString;
	Else
		ErrorText = Record.ErrorText.Get();
	EndIf;
	IncomingText = LoggingOfCELOperations.FormatOfLoggingParameter(IncomingParameters);
	OutgoingText = LoggingOfCELOperations.FormatOfLoggingParameter(OutgoingParameters);
	RecordingResultAndParameters = StrTemplate("Result: %1; %2; %3; %4",
		Record.Result,
		?(IsBlankString(ErrorText), "", Chars.LF + NStr("vi = ' - Nội dung lỗi:';
														|ru = ' - Текст ошибки:';
														|en = ' - Error text:'; fa = ' - Error text:';
														|it = ' - Error text:';
														|pl = ' - Error text:';
														|tr = ' - Hata metni:'") + Chars.LF + TrimAll(ErrorText)),
		?(IsBlankString(IncomingText), "", Chars.LF + NStr("vi = ' - Đến:';
															|ru = ' - Входящие:';
															|en = ' - Incoming:'; fa = ' - Incoming:';
															|it = ' - Входящие:';
															|pl = ' - Incoming:';
															|tr = ' - Gelen:'") + Chars.LF + TrimAll(IncomingText)),
		?(IsBlankString(OutgoingText), "", Chars.LF + NStr("vi = ' - Đi:';
															|ru = ' - Исходящие:';
															|en = ' - Outgoing:'; fa = ' - Outgoing:';
															|it = ' - Исходящие:';
															|pl = ' - Outgoing:';
															|tr = ' - Giden:'") + Chars.LF + TrimAll(OutgoingText)));
		
	Return StrTemplate("%1 %2", RecordingStart, RecordingResultAndParameters);
	
EndFunction


#EndRegion

#EndIf