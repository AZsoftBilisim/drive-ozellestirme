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
	
	Manager = "InformationRegister.HardwareDriverLogArchive";
	EquipmentManagerServerCallOverridable.OnFillAccessRestriction(Manager, Restriction);
	
EndProcedure
// End StandardSubsystems.AccessManagement

#EndRegion

#Region Internal

// Record the State of receiving the request
// 
// Parameters:
//  Peripherals - CatalogRef.Peripherals
// 
Procedure RecordStartOfRequestForDriverLogArchive(Peripherals) Export
	
	If Not ValueIsFilled(Peripherals) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Set = CreateRecordSet();
	Record = Set.Add();
	Record.Peripherals = Peripherals;
	Record.RequestDate_ = CurrentSessionDate();
	Set.Write(True);
	
EndProcedure

// Write the logging file to the register
// 
// Parameters:
//  Peripherals - CatalogRef.Peripherals
//  Data - Array of TransferableFileDescription - if the files are transferred to the server for archiving
//         - BinaryData  - if the files were archived on the client
// 
Procedure RecordArchiveOfDriverLogs(Peripherals, Val Data) Export
	
	If Not ValueIsFilled(Peripherals) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		Set = CreateRecordSet();
		Set.Filter.Peripherals.Set(Peripherals); 
		Set.Read();
		If Set.Count() > 0 Then
			Block = New DataLock();
			LockItem = Block.Add("InformationRegister.HardwareDriverLogArchive");
			LockItem.SetValue("Peripherals", Peripherals);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			Record = Set[0];
		Else
			Record = Set.Add();
		EndIf;
		
		Record.Peripherals = Peripherals;
		Record.ArchiveDate = CurrentSessionDate();
		If TypeOf(Data) = Type("BinaryData") Then
			ArchiveData = Data;
			Record.IsArchive = True;
		ElsIf TypeOf(Data) = Type("Array") Then
			ArchiveData = New Array;
			For Each File In Data Do
				FileData = GetFromTempStorage(File.Location);
				
				FileDetails = New Structure;
				FileDetails.Insert("Data", FileData);
				FileDetails.Insert("Name", File.Name);
				
				ArchiveData.Add(FileDetails);
			EndDo;
			Record.IsArchive = False;
		Else
			Raise NStr("vi = 'Sai kiểu dữ liệu';
						|ru = 'Некорректный тип данных';
						|en = 'Invalid data type'; fa = 'Invalid data type';
						|it = 'Invalid data type';
						|pl = 'Invalid data type';
						|tr = 'Geçersiz veri türü'")
		EndIf;
		
		Record.ArchiveData = New ValueStorage(ArchiveData, New Deflation());
		Set.Write(True);
		CommitTransaction();
	Except
		RollbackTransaction();
		CommonCEL.WriteErrorToEventLog(
			EventNameInEventLog(),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()),
			"Error",
			Metadata.InformationRegisters.HardwareDriverLogArchive);
		Raise;
	EndTry;
	
EndProcedure

// Returns information about the driver logs of the specified connected hardware.
//
// Parameters:
//   Peripherals - CatalogRef.Peripherals - link to the 
//   Catalog item of the connected equipment
//
// Returns:
//   Structure - contains information about the date of the hardware driver log archive:
//     * ArchiveDate - Date - Date of the Log Archive
//
Function InformationAboutDriverLogs(Peripherals) Export
	
	If Not ValueIsFilled(Peripherals) Then
		Raise NStr("vi = 'Chưa chỉ định thiết bị kết nối';
					|ru = 'Не указано подключаемое оборудование';
					|en = 'The peripherals are not specified'; fa = 'The peripherals are not specified';
					|it = 'The peripherals are not specified';
					|pl = 'The peripherals are not specified';
					|tr = 'Bağlanabilir donanım belirtilmedi'");
	EndIf;
	
	SetPrivilegedMode(True);
	
	Result = New Structure;
	Result.Insert("ArchiveDate", Date(1,1,1));
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	HardwareDriverLogArchive.ArchiveDate AS ArchiveDate
		|FROM
		|	InformationRegister.HardwareDriverLogArchive AS HardwareDriverLogArchive
		|WHERE
		|	HardwareDriverLogArchive.Peripherals = &Peripherals";
	
	Query.SetParameter("Peripherals", Peripherals);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return Result;
	EndIf;
	Selection = QueryResult.Select();
	Selection.Next();
	Result.ArchiveDate = Selection.ArchiveDate;
	Return Result;
	
EndFunction

// Returns an archive of driver logs for the specified connected hardware.
//
// Parameters:
//   Peripherals - CatalogRef.Peripherals - 
//     Link To The Connected Equipment
//
// Returns:
//   Structure - contains the archive date, archive data, and an indication that it is an archive:
//    * ArchiveDate - Date - Archive Date
//    * ArchiveData - BinaryData, Undefined - Archive Data
//    * IsArchive - Boolean - indicates that it is an archive
//    
Function ArchiveOfDriverLogs(Peripherals) Export
	
	If Not ValueIsFilled(Peripherals) Then
		Raise NStr("vi = 'Khi gửi yêu cầu lấy tệp nén nhật ký, chưa chỉ định thiết bị được kết nối.';
					|ru = 'При запросе архива логов, не указано подключаемое оборудование.';
					|en = 'The peripherals are not specified when requesting the log archive'; fa = 'The peripherals are not specified when requesting the log archive';
					|it = 'The peripherals are not specified when requesting the log archive';
					|pl = 'The peripherals are not specified when requesting the log archive';
					|tr = 'Günlük arşivi istenirken bağlanabilir donanım belirtilmedi.'");
	EndIf;
	
	SetPrivilegedMode(True);
	
	Result = New Structure;
	Result.Insert("ArchiveDate", Date(1,1,1));
	Result.Insert("ArchiveData", Undefined);
	Result.Insert("IsArchive", False);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	HardwareDriverLogArchive.ArchiveDate AS ArchiveDate,
		|	HardwareDriverLogArchive.ArchiveData AS ArchiveData,
		|	HardwareDriverLogArchive.IsArchive AS IsArchive
		|FROM
		|	InformationRegister.HardwareDriverLogArchive AS HardwareDriverLogArchive
		|WHERE
		|	HardwareDriverLogArchive.Peripherals = &Peripherals";
	
	Query.SetParameter("Peripherals", Peripherals);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return Result;
	EndIf;
	Selection = QueryResult.Select();
	Selection.Next();
	Result.ArchiveDate = Selection.ArchiveDate;
	Result.ArchiveData = Selection.ArchiveData.Get();
	Result.IsArchive = Selection.IsArchive;
	Return Result;
	
EndFunction

// Clears the archive of driver logs for the specified connected hardware.
//
// Parameters:
//   Peripherals - CatalogRef.Peripherals - 
//     link to the connected equipment for which you need to clear the log archive
//
Procedure ClearArchiveOfDriverLogs(Peripherals) Export
	
	If Not ValueIsFilled(Peripherals) Then
		Raise NStr("vi = 'Khi gửi yêu cầu lấy tệp nén nhật ký, chưa chỉ định thiết bị được kết nối.';
					|ru = 'При очистке архива логов, не указано подключаемое оборудование.';
					|en = 'The peripherals are not specified when clearing the log archive'; fa = 'The peripherals are not specified when clearing the log archive';
					|it = 'The peripherals are not specified when clearing the log archive';
					|pl = 'The peripherals are not specified when clearing the log archive';
					|tr = 'Günlük arşivi temizlenirken bağlanabilir donanım belirtilmedi.'");
	EndIf;
	
	SetPrivilegedMode(True);
	
	Set = CreateRecordSet();
	Set.Filter.Peripherals.Set(Peripherals); 
	Set.Write(True);
	
EndProcedure

// Returns the State of the request.
//
// Parameters:
//   Peripherals - CatalogRef.Peripherals - 
//     link to the connected equipment for which you need to clear the log archive
//
// Returns:
//  Structure
//
Function QueryStatus(Peripherals) Export
	
	Result = New Structure;
	Result.Insert("State", "Missing");
	Result.Insert("RequestDate_", Date(1,1,1));
	Result.Insert("ArchiveDate", Date(1,1,1));
	
	If Not ValueIsFilled(Peripherals) Then
		Return Result;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	HardwareDriverLogArchive.RequestDate_ AS RequestDate_,
		|	HardwareDriverLogArchive.ArchiveDate AS ArchiveDate,
		|	CASE
		|		WHEN HardwareDriverLogArchive.ArchiveDate = DATETIME(1, 1, 1, 0, 0, 0)
		|			THEN ""Query""
		|		ELSE ""Received""
		|	END AS State
		|FROM
		|	InformationRegister.HardwareDriverLogArchive AS HardwareDriverLogArchive
		|WHERE
		|	HardwareDriverLogArchive.Peripherals = &Peripherals";
	
	Query.SetParameter("Peripherals", Peripherals);
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		Selection.Next();
		FillPropertyValues(Result, Selection);
	EndIf;
	Return Result; 
	
	
EndFunction


#EndRegion

#Region Private

Function EventNameInEventLog()
	Return NStr("vi = 'Bản ghi lưu trữ nhật ký driver thiết bị';
				|ru = 'Запись архива логов драйверов оборудования';
				|en = 'Record hardware driver log archive'; fa = 'Record hardware driver log archive';
				|it = 'Record hardware driver log archive';
				|pl = 'Record hardware driver log archive';
				|tr = 'Donanım sürücüsü günlük dosyalarının arşiv kaydı'");
EndFunction

#EndRegion

#EndIf