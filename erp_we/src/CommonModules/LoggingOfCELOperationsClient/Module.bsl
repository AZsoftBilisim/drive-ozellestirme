///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Performs an update of the logging parameters of the connected equipment, the data is updated
// from the procedure for determining the logging parameters of the connected equipment.
Procedure UpdateParametersOfOperationsLoggingWithConnectedEquipment() Export
	
	Parameters = LoggingOfCELOperationsInternalServerCall.ParametersForLoggingHardwareOfOperations();
	Peripherals = EquipmentManagerClient.Peripherals();
	Peripherals.LoggingSystem = NewLoggingSystem(Parameters);
	
EndProcedure

// Opening the form of the list of operations for checking KM
//
// Parameters:
//  CommandParameter - Arbitrary - the source where the command is implemented
//  CommandExecuteParameters - CommandExecuteParameters
//
Procedure OpenHardwareOperations(CommandParameter, CommandExecuteParameters) Export
	
	// ++ Non-mobile application
#If Not MobileAppClient Then 
	// Performance measurement.
	KeyOperation = "CommonModule.LoggingOfCELOperationsClient.OpenHardwareOperations";
	CommonCELClient.BPOTimeMeasurement(KeyOperation, Undefined, False, True);
#EndIf
	
	FormParameters = New Structure();
	OpenForm("InformationRegister.OperationsWithPeripherals.ListForm", 
		FormParameters, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window);
	// -- Non-mobile application
	
	
EndProcedure

#EndRegion

#Region Internal

Function NewLogEntry() Export
	
	Result = New Structure();
	Result.Insert("Equipment", Undefined);
	Result.Insert("Date", Undefined);
	Result.Insert("OperationNumber",0);
	Result.Insert("IncomingParameters", New Structure());
	Result.Insert("OutgoingParameters", New Structure());
	Result.Insert("ParametersIDs", "");
	Result.Insert("Timecode", 0);
	Result.Insert("RunTime", 0);
	Result.Insert("EntryType", "");
	Result.Insert("InterfaceRevision", 0);
	Result.Insert("DriverVersion", "");
	Result.Insert("VersionAddIn", "");
	Result.Insert("Operation", "");
	Result.Insert("PresentationOperation", "");
	Result.Insert("DeviceID_", "");
	Result.Insert("ErrorCode", 0);
	Result.Insert("ErrorText", "");
	Result.Insert("Result", False);
	Return Result
	
EndFunction

Function NewLoggingSystem(Parameters) Export
	
	If Parameters = Undefined Then
		Return Undefined;
	EndIf;
	
	If Parameters.UseLogging Then
		Result = New Structure();
		Result.Insert("TransferIntervalATServer", 60);
		Result.Insert("LastTransferAtServer", 0);
		Result.Insert("TypesOfEquipment", New Structure());
		Result.Insert("OperationNumber", 0);
		Result.Insert("Records", New Array());
		Result.Insert("CurrentRecord", Undefined);
		Result.Insert("Module", ThisObject);
		Result.Insert("OperationDescriptions", New Map());
		GenerateDescriptionOfOperations(Result);
		
		Result.TransferIntervalATServer = Parameters.TransferIntervalATServer;
		MinimumTransferInterval = 60;
		If Result.TransferIntervalATServer < MinimumTransferInterval Then
			Result.TransferIntervalATServer = MinimumTransferInterval;
		EndIf;
	Else 
		Result = Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

Function StartRecordingOperationLog(LoggingSystem, ConnectionParameters, Operation, ParameterValues = Undefined, StructureIdentifiers = "") Export
	
	Record = NewLogEntry();
	Record.Date = CurrentDate();
	Record.Timecode = CurrentUniversalDateInMilliseconds();
	LoggingSystem.OperationNumber = LoggingSystem.OperationNumber + 1;
	Record.OperationNumber = LoggingSystem.OperationNumber;
	If ConnectionParameters <> Undefined Then
		Record.Equipment = ConnectionParameters.DeviceID;
		If ConnectionParameters.Property("DeviceID_") Then
			Record.DeviceID_ = ConnectionParameters.DeviceID_;
		EndIf;
		Record.DriverVersion = ConnectionParameters.DriverVersion;
		Record.InterfaceRevision = ConnectionParameters.InterfaceRevision;
	EndIf;
	Record.Operation = Operation;
	
	OperationDescription = CommandDetails(LoggingSystem, Operation);
	If OperationDescription = Undefined Then
		Record.PresentationOperation = Operation;
	Else
		Record.PresentationOperation = ?(IsBlankString(OperationDescription.OperationLocalization), OperationDescription.Operation, OperationDescription.OperationLocalization);
	EndIf;
	
	If ParameterValues <> Undefined Then
		TypeOfParameterValue = TypeOf(ParameterValues);
		If TypeOfParameterValue = Type("Array") Then
			RecordIncomingParametersFromArray(LoggingSystem, Record, ParameterValues);
		ElsIf TypeOfParameterValue= Type("Structure") Then
			If IsBlankString(StructureIdentifiers) Then
				Record.IncomingParameters = ParameterValues;
			Else
				RecordParametersOfIncomingDataFromStructure(LoggingSystem, Record, ParameterValues, StructureIdentifiers);
			EndIf;
		Else
			Record.IncomingParameters.Insert(StructureIdentifiers, ParameterValues);
		EndIf;
	EndIf;
	
	LoggingSystem.CurrentRecord = Record;
	Return Record;
	
EndFunction

Procedure CompleteRecordingOfOperationLog(LoggingSystem, Record, CallResult, IdsOfOutgoingParameters = "") Export
	
	If Record = Undefined Then
		Return;
	EndIf;
	
	Record.RunTime = CurrentUniversalDateInMilliseconds() - Record.Timecode;
	Record.EntryType = "Info";
	If CallResult = Undefined Then
		
		If Record <> Undefined Then
			Record.EntryType = "Exception";
			Record.ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			Record.Result = False;
		EndIf;
		
	ElsIf TypeOf(CallResult) = Type("AddInAsyncCallResult") Then
		
		If TypeOf(CallResult.Value) = Type("Boolean") Then
			Record.Result = CallResult.Value;
			RecordParametersComingFromArray(LoggingSystem, Record, CallResult.Parameters);
			If IsBlankString(Record.DeviceID_) And Record.OutgoingParameters.Property("DeviceID") Then
				Record.DeviceID_ = Record.OutgoingParameters.DeviceID;
			EndIf;
			If Not Record.Result Then
				Record.EntryType = "Error";
			EndIf;
			
		Else
			Record.Result = True;
			Record.OutgoingParameters = New Structure("Result", CallResult.Value);
			
		EndIf;
		
	ElsIf TypeOf(CallResult) = Type("Boolean") Then
		Record.Result = CallResult;
		
	ElsIf TypeOf(CallResult) = Type("Structure") Then
		If CallResult.Property("Attached") Then
			Record.Result = CallResult.Attached;
		Else
			Record.Result = True;
		EndIf;
		RecordParametersComingFromStructure(LoggingSystem, Record, CallResult, IdsOfOutgoingParameters);
		
	Else
		Record.Result = True;
		
	EndIf;
	
	LoggingSystem.Records.Add(Record);
	
EndProcedure

// Record the driver error in the operation log of operation.
// 
// Parameters:
//  LoggingSystem - Structure
//  Record  - Structure
//  CallResult - AddInAsyncCallResult
//
Procedure RecordDriverErrorInOperationLogOfOperation(LoggingSystem, Record, CallResult) Export
	
	If Record <> Undefined Then
		Record.ErrorCode = CallResult.Value;
		Record.Result = False;
		If CallResult.Parameters.Count()>0 Then
			Record.ErrorText = CallResult.Parameters[0];
		EndIf;
	EndIf;
	
EndProcedure

Procedure RecordErrorInOperationLog(LoggingSystem, Record, ErrorDescription) Export
	
	If Record <> Undefined Then
		Record.Result = False;
		Record.ErrorText = ErrorDescription;
	EndIf;
	
EndProcedure

Function DataForServer() Export
	
	LoggingSystem = CommonCELClient.LoggingSystem();
	If LoggingSystem = Undefined Then
		Return Undefined;
	EndIf;
	
	If LoggingSystem.Records.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	Records = LoggingSystem.Records;
	LoggingSystem.Records = New Array();
	
	LoggingSystem.LastTransferAtServer = CurrentUniversalDateInMilliseconds();
	Return Records;
	
EndFunction

Procedure EndLogRecordingWithException(LoggingSystem, Record, ErrorText) Export
	
	If Record = Undefined Then
		Return;
	EndIf;
	
	Record.RunTime = CurrentUniversalDateInMilliseconds() - Record.Timecode;
	Record.EntryType = "Exception";
	Record.ErrorText = ErrorText;
	Record.Result = False;
	
	LoggingSystem.OperationNumber = LoggingSystem.OperationNumber + 1;
	Record.OperationNumber = LoggingSystem.OperationNumber;
	LoggingSystem.Records.Add(Record);
	
EndProcedure

#EndRegion

#Region Private

Function CommandDetails(LoggingSystem, Command, MaximumRevision = 0)
	
	LongDesc = LoggingSystem.OperationDescriptions.Get(Command);
	If LongDesc <> Undefined Then
		
		If MaximumRevision <> 0 Then
			Revision = FindInArrayOfStructuresValueGreaterThan(LongDesc.Revisions, "RevisionNumber", MaximumRevision);
			If Revision <> Undefined Then
				Return Revision;
			EndIf;
		EndIf;
		
	EndIf;
	Return LongDesc;
	
EndFunction

Procedure RecordParametersOfIncomingDataFromStructure(LoggingSystem, Record, ParameterValues, ParametersIDs)
	
	Operation = Record.Operation;
	Revision  = Record.InterfaceRevision;
	LongDesc = CommandDetails(LoggingSystem, Operation, Revision);
	If LongDesc = Undefined Then
		LoggingIds = New Array();
	Else
		LoggingIds = LongDesc.IncomingIds;
	EndIf;
	Parameters = Record.IncomingParameters;
	WriteParametersFromStructure(LoggingIds, Parameters, ParameterValues, ParametersIDs);
	
EndProcedure

Procedure RecordParametersComingFromStructure(LoggingSystem, Record, ParameterValues, ParametersIDs)
	
	Operation = Record.Operation;
	Revision  = Record.InterfaceRevision;
	LongDesc = CommandDetails(LoggingSystem, Operation, Revision);
	If LongDesc = Undefined Then
		LoggingIds = New Array();
	Else
		LoggingIds = LongDesc.OutgoingIds;
	EndIf;
	Parameters = Record.OutgoingParameters;
	WriteParametersFromStructure(LoggingIds, Parameters, ParameterValues, ParametersIDs);
	
EndProcedure

Procedure WriteParametersFromStructure(LoggingIds, Parameters, ParameterValues, ParametersIDs)
	
	StructureIdentifiers = StrSplit(ParametersIDs, ",", True);
	
	IndexOf = 0;
	For Each StructureId In StructureIdentifiers Do
		
		If IsBlankString(StructureId) Then
			IndexOf = IndexOf + 1;
			Continue;
		EndIf;
		
		If IndexOf < LoggingIds.Count() Then
			Id = LoggingIds[IndexOf];
		Else
			Id = TrimAll(StructureId);
		EndIf;
		
		Value = Undefined;
		If ParameterValues.Property(StructureId, Value) Then
			If IsBlankString(Id) Then
				Id = StrTemplate(NStr("vi = 'Tham số_%1';
										|ru = 'Параметр_%1';
										|en = 'Parameter_%1'; fa = 'Parameter_%1';
										|it = 'Параметр_%1';
										|pl = 'Parameter_%1';
										|tr = 'Parametre_%1'"), IndexOf);
			EndIf;
			
			If TypeOf(Value) = Type("String") 
				And XMLStringProcessing.FindDisallowedXMLCharacters(Value, 1) > 0 Then
				Value = WriteJSONValue(Value);
			EndIf;
			Parameters.Insert(Id, Value);
		EndIf;
		IndexOf = IndexOf + 1;
		
	EndDo;
	
EndProcedure

Procedure RecordIncomingParametersFromArray(LoggingSystem, Record, ParameterValues)
	
	Operation = Record.Operation;
	Revision  = Record.InterfaceRevision; 
	LongDesc = CommandDetails(LoggingSystem, Operation, Revision);
	If LongDesc = Undefined Then
		LoggingIds = Undefined;
	Else
		LoggingIds = LongDesc.IncomingIds;
	EndIf;
	Parameters = Record.IncomingParameters;
	
	WriteParametersFromArray(LoggingIds, Parameters, ParameterValues);
	
EndProcedure

Procedure RecordParametersComingFromArray(LoggingSystem, Record, ParameterValues)
	
	Operation = Record.Operation;
	Revision  = Record.InterfaceRevision;
	LongDesc = CommandDetails(LoggingSystem, Operation, Revision);
	If LongDesc = Undefined Then
		LoggingIds = Undefined;
	Else
		LoggingIds = LongDesc.OutgoingIds;
	EndIf;
	Parameters = Record.OutgoingParameters;
	
	WriteParametersFromArray(LoggingIds, Parameters, ParameterValues);
	
EndProcedure

Procedure WriteParametersFromArray(LoggingIds, Parameters, ParameterValues)
	
	IndexOf = 0;
	For Each Value In ParameterValues Do
		
		If TypeOf(Value) = Type("String") 
			And XMLStringProcessing.FindDisallowedXMLCharacters(Value, 1) > 0 Then
			Value = WriteJSONValue(Value);
		EndIf;
		If LoggingIds = Undefined Then
			Id = StrTemplate(NStr("vi = 'Tham số_%1';
									|ru = 'Параметр_%1';
									|en = 'Parameter_%1'; fa = 'Parameter_%1';
									|it = 'Параметр_%1';
									|pl = 'Parameter_%1';
									|tr = 'Parametre_%1'"), IndexOf);
			Parameters.Insert(TrimAll(Id), Value);
		ElsIf IndexOf < LoggingIds.Count() Then
			Id = TrimAll(LoggingIds[IndexOf]);
			If ValueIsFilled(Id) Then
				Parameters.Insert(Id, Value);
			EndIf;
		EndIf;
		IndexOf = IndexOf + 1;
	
	EndDo;
	
EndProcedure

Function FindInArrayOfStructuresValueGreaterThan(Array, Id, Value)
	
	For Each Item In Array Do
	
		If Item[Id] > Value Then
			Return Item;
		EndIf;
	
	EndDo;
	
	Return Undefined;
	
EndFunction

Function FindInArrayOfStructuresValueNoGreaterThan(Array, Id, SearchValue, FoundIndex = 0)
	
	Found4 = Undefined;
	Item = Undefined;
	FoundIndex = 0;
	For IndexOf = 0 To Array.UBound() Do
		Found4 = Item;
		Item = Array[IndexOf];
		If Item[Id] >= SearchValue Then
			Break;
		EndIf;
		FoundIndex = IndexOf;
	EndDo;
	Return Found4;
	
EndFunction

Procedure AddOperation(LoggingSystem, MaximumRevision, Operation, OperationLocalization, 
	IncomingIds, IncomingIdsLocalization, OutgoingIds, OutgoingIdsLocalization)
	
	LongDesc = LoggingSystem.OperationDescriptions.Get(Operation);
	If LongDesc = Undefined Then
		LongDesc = New Structure();
		LongDesc.Insert("OperationLocalization", OperationLocalization);
		LongDesc.Insert("IncomingIds", New Array());
		LongDesc.Insert("OutgoingIds", New Array());
		LongDesc.Insert("IncomingIdsLocalization", New Array());
		LongDesc.Insert("OutgoingIdsLocalization", New Array());
		LongDesc.Insert("Revisions", New Array());
	EndIf;
	
	If MaximumRevision = 0 Then
		LongDesc.IncomingIds = StrSplit(IncomingIds,",",True);
		LongDesc.OutgoingIds = StrSplit(OutgoingIds,",",True);
		LongDesc.IncomingIdsLocalization = StrSplit(IncomingIdsLocalization,",",True);
		LongDesc.OutgoingIdsLocalization = StrSplit(OutgoingIdsLocalization,",",True);
	Else
		IndexOf = 0;
		Revisions = LongDesc.Revisions;
		FoundRevision = FindInArrayOfStructuresValueNoGreaterThan(Revisions, "RevisionNumber", MaximumRevision, IndexOf);
		If FoundRevision = Undefined Then
			InsertIndex = 0;
		Else
			InsertIndex = IndexOf + 1;
		EndIf;
		Revision = New Structure();
		Revision.Insert("RevisionNumber", MaximumRevision);
		Revision.Insert("IncomingIds", StrSplit(IncomingIds,",",True));
		Revision.Insert("OutgoingIds", StrSplit(OutgoingIds,",",True));
		Revision.Insert("IncomingIdsLocalization", StrSplit(IncomingIds,",",True));
		Revision.Insert("OutgoingIdsLocalization", StrSplit(OutgoingIds,",",True));
		Revisions.Insert(InsertIndex, Revision);
	EndIf;
	LoggingSystem.OperationDescriptions.Insert(Operation, LongDesc);
	
EndProcedure

Procedure GenerateDescriptionOfOperations(LoggingSystem)
	
	// 2. Mandatory functions and methods related to the use of the plug-in hardware driver in the system
	AddOperation(LoggingSystem, 0, "GetInterfaceRevision", NStr("vi = 'Nhận bản kiểm tra giao diện';
																|ru = 'Получить ревизию интерфейса';
																|en = 'Get an interface revision'; fa = 'Get an interface revision';
																|it = 'Получить ревизию интерфейса';
																|pl = 'Get an interface revision';
																|tr = 'Arayüz revizyonunu al'"), "", "", "", "");
	AddOperation(LoggingSystem, 0, "GetDescription", NStr("vi = 'Nhận mô tả';
															|ru = 'Получить описание';
															|en = 'Get details'; fa = 'Get details';
															|it = 'Получить описание';
															|pl = 'Uzyskaj opis';
															|tr = 'Ayrıntıları al'"), "", "", "DriverDescription", NStr("vi = 'Mô tả Driver';
																													|ru = 'Описание драйвера';
																													|en = 'Driver details'; fa = 'Driver details';
																													|it = 'Описание драйвера';
																													|pl = 'Opis sterownika';
																													|tr = 'Sürücü ayrıntıları'"));
	AddOperation(LoggingSystem, 0, "GetLastError", NStr("vi = 'Nhận lỗi';
														|ru = 'Получить ошибку';
														|en = 'Get an error'; fa = 'Get an error';
														|it = 'Получить ошибку';
														|pl = 'Get an error';
														|tr = 'Hatayı al'"), "", "", "ErrorDescription", NStr("vi = 'Mô tả lỗi';
																												|ru = 'Описание ошибки';
																												|en = 'Error details'; fa = 'جزئیات خطا';
																												|it = 'Описание ошибки';
																												|pl = 'Opis błędu';
																												|tr = 'Hata açıklaması'"));
	AddOperation(LoggingSystem, 0, "EquipmentParameters", NStr("vi = 'Tham số thiết bị';
																|ru = 'Параметры оборудования';
																|en = 'Peripheral parameters'; fa = 'Peripheral parameters';
																|it = 'Параметры оборудования';
																|pl = 'Peripheral parameters';
																|tr = 'Donanım parametreleri'"), "EquipmentType, ", NStr("vi = 'Kiểu thiết bị,';
																														|ru = 'Тип оборудования,';
																														|en = 'Peripherals type,'; fa = 'Peripherals type,';
																														|it = 'Тип оборудования,';
																														|pl = 'Peripherals type,';
																														|tr = 'Тип оборудования,'"), ", TableParameters", NStr("vi = ', Bảng tham số';
																																												|ru = ', Таблица параметров';
																																												|en = ', Parameter table'; fa = ', Parameter table';
																																												|it = ', Таблица параметров';
																																												|pl = ', Parameter table';
																																												|tr = ', Parametre tablosu'"));
	AddOperation(LoggingSystem, 0, "ConnectEquipment", NStr("vi = 'Kết nối thiết bị';
															|ru = 'Подключить оборудование';
															|en = 'Connect peripherals'; fa = 'Connect peripherals';
															|it = 'Подключить оборудование';
															|pl = 'Connect peripherals';
															|tr = 'Donanımı bağla'"), ", EquipmentType, ConnectionParameters", NStr("vi = ', Kiểu thiết bị, Tham số kết nối';
																																		|ru = ', Тип оборудования, Параметры подключения';
																																		|en = ', Peripheral type, Connection parameters'; fa = ', Peripheral type, Connection parameters';
																																		|it = ', Тип оборудования, Параметры подключения';
																																		|pl = ', Peripheral type, Connection parameters';
																																		|tr = ', Ekipman türü, Bağlantı parametreleri'"), "DeviceID, , ", NStr("vi = 'ID thiết bị, ,';
																																																					|ru = 'ИД устройства, ,';
																																																					|en = 'Device ID, ,'; fa = 'Device ID, ,';
																																																					|it = 'ИД устройства, ,';
																																																					|pl = 'Device ID, ,';
																																																					|tr = 'ИД устройства, ,'"));
	AddOperation(LoggingSystem, 0, "DisconnectEquipment", NStr("vi = 'Vô hiệu hóa thiết bị';
																|ru = 'Отключить оборудование';
																|en = 'Disconnect peripherals'; fa = 'Disconnect peripherals';
																|it = 'Отключить оборудование';
																|pl = 'Disconnect peripherals';
																|tr = 'Donanımı kapat'"), "DeviceID", NStr("vi = 'ID thiết bị';
																													|ru = 'ИД устройства';
																													|en = 'Device ID'; fa = 'شناسه دستگاه';
																													|it = 'ИД устройства';
																													|pl = 'Device ID';
																													|tr = 'ИД устройства'"), "", "");
	AddOperation(LoggingSystem, 0, "EquipmentTest", NStr("vi = 'Thử nghiệm thiết bị';
														|ru = 'Тестирования оборудования';
														|en = 'Peripheral testing'; fa = 'Peripheral testing';
														|it = 'Тестирования оборудования';
														|pl = 'Peripheral testing';
														|tr = 'Donanımın denenmesi'"), "EquipmentType, ConnectionParameters, , ", NStr("vi = 'Kiểu thiết bị, Tham số kết nối, ,';
																																		|ru = 'Тип оборудования, Параметры подключения, ,';
																																		|en = 'Peripheral type, Connection parameters, ,'; fa = 'Peripheral type, Connection parameters, ,';
																																		|it = 'Тип оборудования, Параметры подключения, ,';
																																		|pl = 'Peripheral type, Connection parameters, ,';
																																		|tr = 'Тип оборудования, Параметры подключения, ,'"), ", , Description, DemoModeIsActivated", NStr("vi = ', , Mô tả, Đã kích hoạt chế độ minh họa';
																																																										|ru = ', , Описание, Активирован демо режим';
																																																										|en = ', , Details, Demo profile is activated'; fa = ', , Details, Demo profile is activated';
																																																										|it = ', , Описание, Активирован демо режим';
																																																										|pl = ', , Details, Demo profile is activated';
																																																										|tr = ', , Ayrıntılar, Demo modu aktive edildi'"));
	AddOperation(LoggingSystem, 0, "EquipmentAutoSetup", NStr("vi = 'Tự động tùy chỉnh thiết bị';
																|ru = 'Автонастройка оборудования';
																|en = 'Equipment autosetup'; fa = 'Equipment autosetup';
																|it = 'Автонастройка оборудования';
																|pl = 'Equipment autosetup';
																|tr = 'Otomatik ekipman ayarlamaları'"), ", ConnectionParameters, , ShowAutoSetupWindow, Timeout", NStr("vi = ', Tham số kết nối, , Hiển thị cửa sổ tự động tùy chỉnh, Hết giờ';
																																							|ru = ', Параметры подключения, , Показывать окно автонастройки, Таймаут';
																																							|en = ', Connection parameters, , Show autosetup window, Timeout'; fa = ', Connection parameters, , Show autosetup window, Timeout';
																																							|it = ', Параметры подключения, , Показывать окно автонастройки, Таймаут';
																																							|pl = ', Connection parameters, , Show autosetup window, Timeout';
																																							|tr = ', Bağlantı parametreleri, , Otomatik ayarlama penceresini göster, Zaman aşımı'"), "EquipmentType, , ConnectionParameters, , ", NStr("vi = 'Kiểu thiết bị, Tham số kết nối, ,';
																																																																					|ru = 'Тип оборудования, , Параметры подключения, ,';
																																																																					|en = 'Peripheral type, , Connection parameters, ,'; fa = 'Peripheral type, , Connection parameters, ,';
																																																																					|it = 'Тип оборудования, , Параметры подключения, ,';
																																																																					|pl = 'Peripheral type, , Connection parameters, ,';
																																																																					|tr = 'Тип оборудования, , Параметры подключения, ,'"));
	AddOperation(LoggingSystem, 0, "SetApplicationInformation", NStr("vi = 'Cài đặt thông tin ứng dụng';
																	|ru = 'Установить информацию приложения';
																	|en = 'Set application information'; fa = 'Set application information';
																	|it = 'Установить информацию приложения';
																	|pl = 'Set application information';
																	|tr = 'Uygulama bilgilerini kur'"), "ApplicationSettings", NStr("vi = 'Tham số ứng dụng';
																																		|ru = 'Параметры приложения';
																																		|en = 'Application parameters'; fa = 'پارامترهای برنامه';
																																		|it = 'Параметры приложения';
																																		|pl = 'Application parameters';
																																		|tr = 'Uygulama parametreleri'"), "", "");
	AddOperation(LoggingSystem, 0, "GetAdditionalActions", NStr("vi = 'Nhận thao tác bổ sung';
																|ru = 'Получить дополнительные действия';
																|en = 'Get additional actions'; fa = 'Get additional actions';
																|it = 'Получить дополнительные действия';
																|pl = 'Get additional actions';
																|tr = 'Ek eylemleri al'"), "", "", "TableActions", NStr("vi = 'Bảng thao tác';
																																|ru = 'Таблица действий';
																																|en = 'Action table'; fa = 'Action table';
																																|it = 'Таблица действий';
																																|pl = 'Action table';
																																|tr = 'Eylem tablosu'"));
	AddOperation(LoggingSystem, 0, "DoAdditionalAction", NStr("vi = 'Thực hiện thao tác bổ sung';
																|ru = 'Выполнить дополнительное действие';
																|en = 'Perform an additional action'; fa = 'Perform an additional action';
																|it = 'Выполнить дополнительное действие';
																|pl = 'Perform an additional action';
																|tr = 'Ek eylemleri gerçekleştir'"), "ActionName", NStr("vi = 'Tên thao tác';
																														|ru = 'Имя действия';
																														|en = 'Action name'; fa = 'Action name';
																														|it = 'Имя действия';
																														|pl = 'Action name';
																														|tr = 'Eylem adı'"), "", "");
	AddOperation(LoggingSystem, 0, "GetLocalizationPattern", NStr("vi = 'Nhận khuôn mẫu bản địa hóa';
																	|ru = 'Получить шаблон локализации';
																	|en = 'Get a localization template'; fa = 'Get a localization template';
																	|it = 'Получить шаблон локализации';
																	|pl = 'Get a localization template';
																	|tr = 'Yerelleştirme şablonunu al'"), "", "", "LocalizationPattern", NStr("vi = 'Khuôn mẫu bản địa hóa';
																																			|ru = 'Шаблон локализации';
																																			|en = 'Localization template'; fa = 'الگوی محلی‌سازی';
																																			|it = 'Шаблон локализации';
																																			|pl = 'Localization template';
																																			|tr = 'Yerelleştirme şablonu'"));
	AddOperation(LoggingSystem, 0, "SetLocalization", NStr("vi = 'Cài đặt bản địa hóa';
															|ru = 'Установить локализацию';
															|en = 'Set localization'; fa = 'Set localization';
															|it = 'Установить локализацию';
															|pl = 'Set localization';
															|tr = 'Yerelleştirmeyi kur'"), "LanguageCode, LocalizationPattern", NStr("vi = 'Mã ngôn ngữ, Khuôn mẫu bản địa hóa';
																																|ru = 'Код языка, Шаблон локализации';
																																|en = 'Language code, Localization template'; fa = 'Language code, Localization template';
																																|it = 'Код языка, Шаблон локализации';
																																|pl = 'Language code, Localization template';
																																|tr = 'Dil kodu, Yerelleştirme şablonu'"), "", "");
	AddOperation(LoggingSystem, 0, "GetParameters", NStr("vi = 'Nhận tham số';
														|ru = 'Получить параметры';
														|en = 'Get parameters'; fa = 'Get parameters';
														|it = 'Получить параметры';
														|pl = 'Get parameters';
														|tr = 'Parametreleri al'"), "", "", "TableParameters", NStr("vi = 'Bảng thông số';
																													|ru = 'Таблица параметров';
																													|en = 'Parameter table'; fa = 'جدول پارامترها';
																													|it = 'Таблица параметров';
																													|pl = 'Tabela parametrów';
																													|tr = 'Parametre tablosu'"));
	AddOperation(LoggingSystem, 0, "SetParameter", NStr("vi = 'Cài đặt tham số';
														|ru = 'Установить параметр';
														|en = 'Set the parameter'; fa = 'Set the parameter';
														|it = 'Установить параметр';
														|pl = 'Set the parameter';
														|tr = 'Parametre ayarla'"), "Name, Value", NStr("vi = 'Tên, Giá trị';
																										|ru = 'Имя, Значение';
																										|en = 'Name, Value'; fa = 'Name, Value';
																										|it = 'Имя, Значение';
																										|pl = 'Name, Value';
																										|tr = 'Ad, Değer'"), "", "");
	AddOperation(LoggingSystem, 0, "Open", NStr("vi = 'Kết nối';
												|ru = 'Подключить';
												|en = 'Connect'; fa = 'اتصال';
												|it = 'Подключить';
												|pl = 'Connect';
												|tr = 'Etkinleştir'"), "", "", "DeviceID", NStr("vi = 'ID thiết bị';
																							|ru = 'ИД устройства';
																							|en = 'Device ID'; fa = 'شناسه دستگاه';
																							|it = 'ИД устройства';
																							|pl = 'Device ID';
																							|tr = 'ИД устройства'"));
	AddOperation(LoggingSystem, 0, "Close", NStr("vi = 'Ngắt bỏ';
												|ru = 'Отключить';
												|en = 'Disconnect'; fa = 'قطع اتصال';
												|it = 'Отключить';
												|pl = 'Disconnect';
												|tr = 'Devre dışı bırak'"), "DeviceID", NStr("vi = 'ID thiết bị';
																						|ru = 'ИД устройства';
																						|en = 'Device ID'; fa = 'شناسه دستگاه';
																						|it = 'ИД устройства';
																						|pl = 'Device ID';
																						|tr = 'ИД устройства'"), "", "");
	AddOperation(LoggingSystem, 0, "DeviceTest", NStr("vi = 'Kiểm thử thiết bị';
														|ru = 'Тест устройства';
														|en = 'Device test'; fa = 'Device test';
														|it = 'Тест устройства';
														|pl = 'Test urządzenia';
														|tr = 'Cihaz testi'"), "", "", "Description, DemoModeIsActivated", NStr("vi = 'Mô tả, Đã kích hoạt chế độ minh họa';
																																|ru = 'Описание, Активирован демо режим';
																																|en = 'Details, Demo profile is activated'; fa = 'Details, Demo profile is activated';
																																|it = 'Описание, Активирован демо режим';
																																|pl = 'Details, Demo profile is activated';
																																|tr = 'Ayrıntılar, Demo modu aktive edildi'"));
	
	// 3.1. Requirements for the development of drivers for electronic scales
	AddOperation(LoggingSystem, 0, "ScaleOptions", NStr("vi = 'Tham số trọng lượng';
														|ru = 'Параметры весов';
														|en = 'Scales parameters'; fa = 'Scales parameters';
														|it = 'Параметры весов';
														|pl = 'Scales parameters';
														|tr = 'Ağırlık parametreleri'"), "DeviceID, ", NStr("vi = 'ID thiết bị,';
																										|ru = 'ИД устройства,';
																										|en = 'Device ID,'; fa = 'Device ID,';
																										|it = 'ИД устройства,';
																										|pl = 'Device ID,';
																										|tr = 'ИД устройства,'"), ", ScaleOptions", NStr("vi = ', Tham số trọng lượng';
																																					|ru = ', Параметры весов';
																																					|en = ', Scales parameters'; fa = ', Scales parameters';
																																					|it = ', Параметры весов';
																																					|pl = ', Scales parameters';
																																					|tr = ', Ağırlık parametreleri'"));
	AddOperation(LoggingSystem, 0, "Calibrate", NStr("vi = 'Cài đặt trọng lượng bì';
													|ru = 'Установить вес тары';
													|en = 'Set the package weight'; fa = 'Set the package weight';
													|it = 'Установить вес тары';
													|pl = 'Set the package weight';
													|tr = 'Dara ağırlığını ayarla'"), "DeviceID, TareWeight", NStr("vi = 'ID thiết bị, Trọng lượng bì';
																													|ru = 'ИД устройства, Вес тары';
																													|en = 'Device ID, Package weight'; fa = 'Device ID, Package weight';
																													|it = 'ИД устройства, Вес тары';
																													|pl = 'Device ID, Package weight';
																													|tr = 'ИД устройства, Вес тары'"), "", "");
	AddOperation(LoggingSystem, 0, "GetWeight", NStr("vi = 'Nhận trọng lượng';
													|ru = 'Получить вес';
													|en = 'Receive weight'; fa = 'دریافت وزن';
													|it = 'Получить вес';
													|pl = 'Pobierz wagę';
													|tr = 'Ağırlığı al'"), "DeviceID, ", NStr("vi = 'ID thiết bị,';
																									|ru = 'ИД устройства,';
																									|en = 'Device ID,'; fa = 'Device ID,';
																									|it = 'ИД устройства,';
																									|pl = 'Device ID,';
																									|tr = 'ИД устройства,'"), ", Weight", NStr("vi = ', Trọng lượng hiện tại';
																																		|ru = ', Текущий вес';
																																		|en = ', Current weight'; fa = ', Current weight';
																																		|it = ', Текущий вес';
																																		|pl = ', Current weight';
																																		|tr = ', Mevcut ağırlık'"));
	
	// 3.2. Requirements for the development of drivers for electronic scales with label printing in "OFFLINE" mode
	AddOperation(LoggingSystem, 0, "UploadGoods", NStr("vi = 'Kết xuất hàng hóa';
														|ru = 'Выгрузить товары';
														|en = 'Export goods'; fa = 'خروج کالاها';
														|it = 'Выгрузить товары';
														|pl = 'Eksportuj wiersze pozycji';
														|tr = 'Ürünleri yükle'"), "DeviceID, GoodsTable, PackageStatus", NStr("vi = 'ID thiết bị, Bảng hình ảnh, Trạng thái gói';
																															|ru = 'ИД устройства, Таблица товаров, Статус пакета';
																															|en = 'Device ID, Goods table, Package status'; fa = 'Device ID, Goods table, Package status';
																															|it = 'ИД устройства, Таблица товаров, Статус пакета';
																															|pl = 'Device ID, Goods table, Package status';
																															|tr = 'ИД устройства, Таблица товаров, Статус пакета'"), "", "");
	AddOperation(LoggingSystem, 0, "ClearGoods", NStr("vi = 'Xóa hàng hóa';
														|ru = 'Очистить товары';
														|en = 'Clear goods'; fa = 'Clear goods';
														|it = 'Очистить товары';
														|pl = 'Oczyść wiersze pozycji';
														|tr = 'Ürünleri temizle'"), "DeviceID", NStr("vi = 'ID thiết bị';
																								|ru = 'ИД устройства';
																								|en = 'Device ID'; fa = 'شناسه دستگاه';
																								|it = 'ИД устройства';
																								|pl = 'Device ID';
																								|tr = 'ИД устройства'"), "", "");
	AddOperation(LoggingSystem, 0, "UploadProductImages", NStr("vi = 'Kết xuất hình ảnh hàng hóa';
																|ru = 'Выгрузить изображения товаров';
																|en = 'Export goods images'; fa = 'Export goods images';
																|it = 'Выгрузить изображения товаров';
																|pl = 'Export goods images';
																|tr = 'Ürün görsellerini aktar'"), "DeviceID, TableImages, PackageStatus", NStr("vi = 'ID thiết bị, Bảng hình ảnh, Trạng thái gói';
																																			|ru = 'ИД устройства, Таблица изображений, Статус пакета';
																																			|en = 'Device ID, Image table, Package status'; fa = 'Device ID, Image table, Package status';
																																			|it = 'ИД устройства, Таблица изображений, Статус пакета';
																																			|pl = 'Device ID, Image table, Package status';
																																			|tr = 'ИД устройства, Таблица изображений, Статус пакета'"), "", "");
	
	// 3.3. Requirements for the development of drivers for the buyer's displays
	AddOperation(LoggingSystem, 0, "StringOutputOnCustomerDisplay", NStr("vi = 'Hiển thị dòng ra màn hình khách hàng';
																		|ru = 'Вывести строку на дисплей покупателя';
																		|en = 'Show the line on the customer display'; fa = 'Show the line on the customer display';
																		|it = 'Вывести строку на дисплей покупателя';
																		|pl = 'Show the line on the customer display';
																		|tr = 'Müşteri ekranındaki satırı geri çek'"), "DeviceID, Strings", NStr("vi = 'ID thiết bị, Dòng';
																																					|ru = 'ИД устройства, Строки';
																																					|en = 'Device ID, Lines'; fa = 'Device ID, Lines';
																																					|it = 'ИД устройства, Строки';
																																					|pl = 'Device ID, Lines';
																																					|tr = 'ИД устройства, Строки'"), "", "");
	AddOperation(LoggingSystem, 0, "ClearCustomerDisplay", NStr("vi = 'Xóa màn hình khách hàng';
																|ru = 'Очистить дисплей покупателя';
																|en = 'Clear the customer display'; fa = 'Clear the customer display';
																|it = 'Очистить дисплей покупателя';
																|pl = 'Clear the customer display';
																|tr = 'Müşteri ekranını temizle'"), "DeviceID", NStr("vi = 'ID thiết bị';
																														|ru = 'ИД устройства';
																														|en = 'Device ID'; fa = 'شناسه دستگاه';
																														|it = 'ИД устройства';
																														|pl = 'Device ID';
																														|tr = 'ИД устройства'"), "", "");
	AddOperation(LoggingSystem, 0, "OutputHTML", NStr("vi = 'Hiển thị HTML';
														|ru = 'Вывести HTML';
														|en = 'Output HTML'; fa = 'Output HTML';
														|it = 'Вывести HTML';
														|pl = 'Output HTML';
														|tr = 'HTML çıktısı'"), "DeviceID, HTML", NStr("vi = 'ID thiết bị, HTML';
																									|ru = 'ИД устройства, HTML';
																									|en = 'Device ID, HTML'; fa = 'Device ID, HTML';
																									|it = 'ИД устройства, HTML';
																									|pl = 'Device ID, HTML';
																									|tr = 'ИД устройства, HTML'"), "", "");
	AddOperation(LoggingSystem, 0, "QRCodeOutputOnCustomerDisplay", NStr("vi = 'Hiển thị mã QR ra màn hình khách hàng';
																		|ru = 'Вывести QR код на дисплей покупателя';
																		|en = 'Output the QR code to the customer display'; fa = 'Output the QR code to the customer display';
																		|it = 'Вывести QR код на дисплей покупателя';
																		|pl = 'Output the QR code to the customer display';
																		|tr = 'Вывести QR код на дисплей покупателя'"), "DeviceID, QRCodeValue, QRCodePicture", NStr("vi = 'ID thiết bị, Giá trị mã QR, Hình ảnh mã QR';
																																											|ru = 'ИД устройства, Значение QR кода, Картинка QR кода';
																																											|en = 'Device ID, QR code value, QR code picture'; fa = 'Device ID, QR code value, QR code picture';
																																											|it = 'Device ID, QR code value, QR code picture';
																																											|pl = 'Device ID, QR code value, QR code picture';
																																											|tr = 'Cihaz ID''si, QR Kod Değeri, QR Kod Resmi'"), "", "");
	AddOperation(LoggingSystem, 0, "DisplayOperationStatus", NStr("vi = 'Hiển thị trạng thái giao dịch';
																	|ru = 'Отобразить статус операции';
																	|en = 'Display the transaction status'; fa = 'Display the transaction status';
																	|it = 'Отобразить статус операции';
																	|pl = 'Display the transaction status';
																	|tr = 'İşlem durumunu görüntüle'"), "DeviceID, OperationStatus", NStr("vi = 'ID thiết bị, Trạng thái giao dịch';
																																				|ru = 'ИД устройства, Статус операции';
																																				|en = 'Device ID, Transaction status'; fa = 'Device ID, Transaction status';
																																				|it = 'ИД устройства, Статус операции';
																																				|pl = 'Device ID, Transaction status';
																																				|tr = 'ИД устройства, Статус операции'"), "", "");
	AddOperation(LoggingSystem, 0, "DisplayWorkplaceStatus", NStr("vi = 'Hiển thị trạng thái nơi làm việc';
																	|ru = 'Отобразить статус рабочего места';
																	|en = 'Display the workplace status'; fa = 'Display the workplace status';
																	|it = 'Отобразить статус рабочего места';
																	|pl = 'Display the workplace status';
																	|tr = 'Çalışma alanı durumunu görüntüle'"), "DeviceID, WorkplaceStatus, SoundSignal", NStr("vi = 'IDThiết bị, Trạng thái nơi làm việc, Tín hiệu âm thanh';
																																						|ru = 'ИД устройства, Статус рабочего места, Звуковой сигнал';
																																						|en = 'Device ID, Workplace status, Audio signal'; fa = 'Device ID, Workplace status, Audio signal';
																																						|it = 'ИД устройства, Статус рабочего места, Звуковой сигнал';
																																						|pl = 'Device ID, Workplace status, Audio signal';
																																						|tr = 'Cihaz ID''si, Çalışma alanı durumu, Sesli sinyal'"), "", "");
	AddOperation(LoggingSystem, 0, "GetCustomerDisplayOptions", NStr("vi = 'Nhận tham số màn hình khách hàng';
																	|ru = 'Получить параметры дисплея покупателя';
																	|en = 'Get customer display parameters'; fa = 'Get customer display parameters';
																	|it = 'Получить параметры дисплея покупателя';
																	|pl = 'Get customer display parameters';
																	|tr = 'Müşteri ekranı parametrelerini al'"), "DeviceID, ", NStr("vi = 'ID thiết bị,';
																																	|ru = 'ИД устройства,';
																																	|en = 'Device ID,'; fa = 'Device ID,';
																																	|it = 'ИД устройства,';
																																	|pl = 'Device ID,';
																																	|tr = 'ИД устройства,'"), ", CustomerDisplayOptions", NStr("vi = ', Tham số màn hình khách hàng';
																																															|ru = ', Параметры дисплея покупателя';
																																															|en = ', Customer display parameters'; fa = ', Customer display parameters';
																																															|it = ', Параметры дисплея покупателя';
																																															|pl = ', Customer display parameters';
																																															|tr = ', Müşteri ekranı parametreleri'"));
	
	// 3.4. Requirements for the development of drivers for data collection terminals
	AddOperation(LoggingSystem, 0, "UploadTable", NStr("vi = 'Kết xuất bảng';
														|ru = 'Выгрузить таблицу';
														|en = 'Export the table'; fa = 'Export the table';
														|it = 'Выгрузить таблицу';
														|pl = 'Export the table';
														|tr = 'Tabloyu aktar'"), "DeviceID, GoodsTable, PackageStatus", NStr("vi = 'ID thiết bị, Bảng hình ảnh, Trạng thái gói';
																																|ru = 'ИД устройства, Таблица товаров, Статус пакета';
																																|en = 'Device ID, Goods table, Package status'; fa = 'Device ID, Goods table, Package status';
																																|it = 'ИД устройства, Таблица товаров, Статус пакета';
																																|pl = 'Device ID, Goods table, Package status';
																																|tr = 'ИД устройства, Таблица товаров, Статус пакета'"), "", "");
	AddOperation(LoggingSystem, 0, "DownloadTable", NStr("vi = 'Kết nhập bảng';
														|ru = 'Загрузить таблицу';
														|en = 'Import table'; fa = 'Import table';
														|it = 'Загрузить таблицу';
														|pl = 'Import table';
														|tr = 'Tabloyu indir'"), "DeviceID, ", NStr("vi = 'ID thiết bị,';
																									|ru = 'ИД устройства,';
																									|en = 'Device ID,'; fa = 'Device ID,';
																									|it = 'ИД устройства,';
																									|pl = 'Device ID,';
																									|tr = 'ИД устройства,'"), ", DownloadTable", NStr("vi = ', Bảng kết nhập';
																																					|ru = ', Таблица загрузки';
																																					|en = ', Import table'; fa = ', Import table';
																																					|it = ', Таблица загрузки';
																																					|pl = ', Import table';
																																					|tr = ', Yükleme tablosu'"));
	AddOperation(LoggingSystem, 0, "ClearTable", NStr("vi = 'Xóa bảng';
														|ru = 'Очистить таблицу';
														|en = 'Clear table'; fa = 'Clear table';
														|it = 'Очистить таблицу';
														|pl = 'Wyczyść tabelę';
														|tr = 'Tabloyu temizle'"), "DeviceID", NStr("vi = 'ID thiết bị';
																								|ru = 'ИД устройства';
																								|en = 'Device ID'; fa = 'شناسه دستگاه';
																								|it = 'ИД устройства';
																								|pl = 'Device ID';
																								|tr = 'ИД устройства'"), "", "");
	
	// 3.5. Requirements for the development of drivers for KKT with the function of Transferring to OFD
	AddOperation(LoggingSystem, 0, "GetDataKKT", NStr("vi = 'Nhận tham số KKT';
														|ru = 'Получить параметры ККТ';
														|en = 'Get cash register parameters'; fa = 'Get cash register parameters';
														|it = 'Получить параметры ККТ';
														|pl = 'Get cash register parameters';
														|tr = 'Yazar Kasa Ekipmanları parametrelerini al'"), "DeviceID, ", NStr("vi = 'ID thiết bị,';
																												|ru = 'ИД устройства,';
																												|en = 'Device ID,'; fa = 'Device ID,';
																												|it = 'ИД устройства,';
																												|pl = 'Device ID,';
																												|tr = 'ИД устройства,'"), ", TableParametersKKT", NStr("vi = ', Bảng tham số KKT';
																																									|ru = ', Таблица параметров ККТ';
																																									|en = ', Cash register parameter table'; fa = ', Cash register parameter table';
																																									|it = ', Таблица параметров ККТ';
																																									|pl = ', Cash register parameter table';
																																									|tr = ', Yazar Kasa Ekipmanları parametreleri tablosu'"));
	AddOperation(LoggingSystem, 0, "OperationFN", NStr("vi = 'Giao dịch bộ lưu trữ thuế';
														|ru = 'Операция ФН';
														|en = 'Fiscal storage transaction'; fa = 'Fiscal storage transaction';
														|it = 'Операция ФН';
														|pl = 'Fiscal storage transaction';
														|tr = 'Finansal Hafıza işlemi'"), "DeviceID, OperationType, ParametersFiscal", NStr("vi = 'IDThiết bị, Kiểu giao dịch, Tham số ghi nhận thuế';
																																				|ru = 'ИД устройства, Тип операции, Параметры фискализации';
																																				|en = 'Device ID, Transaction type, Fiscalization parameters'; fa = 'Device ID, Transaction type, Fiscalization parameters';
																																				|it = 'ИД устройства, Тип операции, Параметры фискализации';
																																				|pl = 'Device ID, Transaction type, Fiscalization parameters';
																																				|tr = 'ИД устройства, Тип операции, Параметры фискализации'"), "", "");
	AddOperation(LoggingSystem, 0, "OpenShift", NStr("vi = 'Mở phiên thu ngân';
													|ru = 'Открыть смену';
													|en = 'Open the shift'; fa = 'Open the shift';
													|it = 'Открыть смену';
													|pl = 'Otwórz zmianę';
													|tr = 'Vardiyayı aç'"), "DeviceID, InputParameters, ", NStr("vi = 'ID thiết bị, Tham số đầu vào,';
																													|ru = 'ИД устройства, Входные параметры,';
																													|en = 'Device ID, Input parameters,'; fa = 'Device ID, Input parameters,';
																													|it = 'ИД устройства, Входные параметры,';
																													|pl = 'Device ID, Input parameters,';
																													|tr = 'ИД устройства, Входные параметры,'"), ", , OutputParameters", NStr("vi = ', , Tham số đầu ra';
																																														|ru = ', , Выходные параметры';
																																														|en = ', , Output parameters'; fa = ', , Output parameters';
																																														|it = ', , Выходные параметры';
																																														|pl = ', , Output parameters';
																																														|tr = ', , Çıkış parametreleri'"));
	AddOperation(LoggingSystem, 3000, "OpenShift", NStr("vi = 'Mở phiên thu ngân';
														|ru = 'Открыть смену';
														|en = 'Open the shift'; fa = 'Open the shift';
														|it = 'Открыть смену';
														|pl = 'Otwórz zmianę';
														|tr = 'Vardiyayı aç'"), "DeviceID, InputParameters, , , ", NStr("vi = 'ID thiết bị, Tham số đầu vào, , ,';
																															|ru = 'ИД устройства, Входные параметры, , ,';
																															|en = 'Device ID, Input parameters, , ,'; fa = 'Device ID, Input parameters, , ,';
																															|it = 'ИД устройства, Входные параметры, , ,';
																															|pl = 'Device ID, Input parameters, , ,';
																															|tr = 'ИД устройства, Входные параметры, , ,'"), ", , OutputParameters, SessionNumber, DocumentNumber", NStr("vi = ', , Tham số đầu ra, Số phiên thu ngân, Số chứng từ';
																																																									|ru = ', , Выходные параметры, Номер смены, Номер документа';
																																																									|en = ', , Output parameters, Shift number, Document number'; fa = ', , Output parameters, Shift number, Document number';
																																																									|it = ', , Выходные параметры, Номер смены, Номер документа';
																																																									|pl = ', , Output parameters, Shift number, Document number';
																																																									|tr = ', , Giriş parametreleri, Vardiya numarası, Belge numarası'"));
	AddOperation(LoggingSystem, 0, "CloseShift", NStr("vi = 'Đóng phiên thu ngân';
														|ru = 'Закрыть смену';
														|en = 'Close the shift'; fa = 'Close the shift';
														|it = 'Закрыть смену';
														|pl = 'Zamknij zmianę';
														|tr = 'Vardiyayı kapat'"), "DeviceID, InputParameters, ", NStr("vi = 'ID thiết bị, Tham số đầu vào,';
																													|ru = 'ИД устройства, Входные параметры,';
																													|en = 'Device ID, Input parameters,'; fa = 'Device ID, Input parameters,';
																													|it = 'ИД устройства, Входные параметры,';
																													|pl = 'Device ID, Input parameters,';
																													|tr = 'ИД устройства, Входные параметры,'"), ", , OutputParameters", NStr("vi = ', , Tham số đầu ra';
																																															|ru = ', , Выходные параметры';
																																															|en = ', , Output parameters'; fa = ', , Output parameters';
																																															|it = ', , Выходные параметры';
																																															|pl = ', , Output parameters';
																																															|tr = ', , Çıkış parametreleri'"));
	AddOperation(LoggingSystem, 3000, "CloseShift", NStr("vi = 'Đóng phiên thu ngân';
														|ru = 'Закрыть смену';
														|en = 'Close the shift'; fa = 'Close the shift';
														|it = 'Закрыть смену';
														|pl = 'Zamknij zmianę';
														|tr = 'Vardiyayı kapat'"), "DeviceID, InputParameters, , , ", NStr("vi = 'ID thiết bị, Tham số đầu vào, , ,';
																															|ru = 'ИД устройства, Входные параметры, , ,';
																															|en = 'Device ID, Input parameters, , ,'; fa = 'Device ID, Input parameters, , ,';
																															|it = 'ИД устройства, Входные параметры, , ,';
																															|pl = 'Device ID, Input parameters, , ,';
																															|tr = 'ИД устройства, Входные параметры, , ,'"), ", , OutputParameters, SessionNumber, DocumentNumber", NStr("vi = ', , Tham số đầu ra, Số phiên thu ngân, Số chứng từ';
																																																									|ru = ', , Выходные параметры, Номер смены, Номер документа';
																																																									|en = ', , Output parameters, Shift number, Document number'; fa = ', , Output parameters, Shift number, Document number';
																																																									|it = ', , Выходные параметры, Номер смены, Номер документа';
																																																									|pl = ', , Output parameters, Shift number, Document number';
																																																									|tr = ', , Giriş parametreleri, Vardiya numarası, Belge numarası'"));
	AddOperation(LoggingSystem, 0, "ProcessCheck", NStr("vi = 'Tạo phiếu';
														|ru = 'Сформировать чек';
														|en = 'Generate receipt'; fa = 'ایجاد رسید';
														|it = 'Сформировать чек';
														|pl = 'Generate receipt';
														|tr = 'Çek oluştur'"), "DeviceID, Electronically, CheckPackage, ", NStr("vi = 'IDThiết bị, Điện tử, Dữ liệu của phiếu,';
																																	|ru = 'ИД устройства, Электронно, Данные чека,';
																																	|en = 'Device ID, Electronically, Receipt data,'; fa = 'Device ID, Electronically, Receipt data,';
																																	|it = 'ИД устройства, Электронно, Данные чека,';
																																	|pl = 'Device ID, Electronically, Receipt data,';
																																	|tr = 'ИД устройства, Электронно, Данные чека,'"), ", Electronically, , DocumentOutputParameters", NStr("vi = ', Điện tử, , Tham số đầu ra chứng từ';
																																																												|ru = ', Электронно, , Выходные параметры документа';
																																																												|en = ', Electronically, , Output document parameters'; fa = ', Electronically, , Output document parameters';
																																																												|it = ', Электронно, , Выходные параметры документа';
																																																												|pl = ', Electronically, , Output document parameters';
																																																												|tr = ', Elektronik, , Belge çıkış parametreleri'"));
	AddOperation(LoggingSystem, 3000, "ProcessCheck", NStr("vi = 'Tạo phiếu';
															|ru = 'Сформировать чек';
															|en = 'Generate receipt'; fa = 'ایجاد رسید';
															|it = 'Сформировать чек';
															|pl = 'Generate receipt';
															|tr = 'Çek oluştur'"), "DeviceID, Electronically, CheckPackage, , , , ", NStr("vi = 'IDThiết bị, Điện tử, Dữ liệu của phiếu, , , ,';
																																				|ru = 'ИД устройства, Электронно, Данные чека, , , ,';
																																				|en = 'Device ID, Electronically, Receipt data, , , ,'; fa = 'Device ID, Electronically, Receipt data, , , ,';
																																				|it = 'ИД устройства, Электронно, Данные чека, , , ,';
																																				|pl = 'Device ID, Electronically, Receipt data, , , ,';
																																				|tr = 'ИД устройства, Электронно, Данные чека, , , ,'"), ", Electronically, , CheckNumber, SessionNumber, FiscalSign, VerificationWebsiteAddress", NStr("vi = ', Điện tử, , Số phiếu, Số phiên làm việc, Dấu hiệu thuế, Address Site Inspections';
																																																																										|ru = ', Электронно, , Номер чека, Номер смены, Фискальный признак, Address Site Inspections';
																																																																										|en = ', Electronically, , Receipt number, Shift number, Fiscal flag, Address Site Inspections'; fa = ', Electronically, , Receipt number, Shift number, Fiscal flag, Address Site Inspections';
																																																																										|it = ', Электронно, , Номер чека, Номер смены, Фискальный признак, Address Site Inspections';
																																																																										|pl = ', Electronically, , Receipt number, Shift number, Fiscal flag, Address Site Inspections';
																																																																										|tr = ', Elektronik, , Çek numarası, Vardiya numarası, Mali işaret, Address Site Inspections'"));
	AddOperation(LoggingSystem, 0, "ProcessCorrectionCheck", NStr("vi = 'Tạo phiếu điều chỉnh';
																	|ru = 'Сформировать чек коррекции';
																	|en = 'Generate an adjustment voucher'; fa = 'Generate an adjustment voucher';
																	|it = 'Сформировать чек коррекции';
																	|pl = 'Generate an adjustment voucher';
																	|tr = 'Düzeltme çeki oluştur'"), "DeviceID, CheckPackage, ", NStr("vi = 'IDThiết bị, Dữ liệu của phiếu,';
																																			|ru = 'ИД устройства, Данные чека,';
																																			|en = 'Device ID, Receipt data,'; fa = 'Device ID, Receipt data,';
																																			|it = 'ИД устройства, Данные чека,';
																																			|pl = 'Device ID, Receipt data,';
																																			|tr = 'ИД устройства, Данные чека,'"), ", , DocumentOutputParameters", NStr("vi = ', , Tham số đầu ra của chứng từ';
																																																						|ru = ', , Выходные параметры документа';
																																																						|en = ', , Output document parameters'; fa = ', , Output document parameters';
																																																						|it = ', , Выходные параметры документа';
																																																						|pl = ', , Output document parameters';
																																																						|tr = ', , Belge giriş parametreleri'"));
	AddOperation(LoggingSystem, 3000, "ProcessCorrectionCheck", NStr("vi = 'Tạo phiếu điều chỉnh';
																	|ru = 'Сформировать чек коррекции';
																	|en = 'Generate an adjustment voucher'; fa = 'Generate an adjustment voucher';
																	|it = 'Сформировать чек коррекции';
																	|pl = 'Generate an adjustment voucher';
																	|tr = 'Düzeltme çeki oluştur'"), "DeviceID, CheckCorrectionPackage, , , , ", NStr("vi = 'IDThiết bị, Dữ liệu của phiếu chỉnh sửa, , , ,';
																																								|ru = 'ИД устройства, Данные чека коррекции, , , ,';
																																								|en = 'Device ID, Adjustment voucher data, , , ,'; fa = 'Device ID, Adjustment voucher data, , , ,';
																																								|it = 'ИД устройства, Данные чека коррекции, , , ,';
																																								|pl = 'Device ID, Adjustment voucher data, , , ,';
																																								|tr = 'ИД устройства, Данные чека коррекции, , , ,'"), ", , CheckNumber, SessionNumber, FiscalSign, VerificationWebsiteAddress", NStr("vi = ', , Số phiếu, Số phiên, Dấu hiệu thuế, Address Site Inspections';
																																																																									|ru = ', , Номер чека, Номер смены, Фискальный признак, Address Site Inspections';
																																																																									|en = ', , Receipt number, Shift number, Fiscal flag, Address Site Inspections'; fa = ', , Receipt number, Shift number, Fiscal flag, Address Site Inspections';
																																																																									|it = ', , Номер чека, Номер смены, Фискальный признак, Address Site Inspections';
																																																																									|pl = ', , Receipt number, Shift number, Fiscal flag, Address Site Inspections';
																																																																									|tr = ', , Çek numarası, Vardiya numarası, Mali işaret, Address Site Inspections'"));
	AddOperation(LoggingSystem, 0, "PrintTextDocument", NStr("vi = 'In văn bản thuần';
															|ru = 'Напечатать текстовый документ';
															|en = 'Print the text document'; fa = 'Print the text document';
															|it = 'Напечатать текстовый документ';
															|pl = 'Print the text document';
															|tr = 'Metin belgesi olarak yazdır'"), "DeviceID, DocumentPackage", NStr("vi = 'IDThiết bị, Dữ liệu của chứng từ';
																																	|ru = 'ИД устройства, Данные документа';
																																	|en = 'Device ID, Document data'; fa = 'Device ID, Document data';
																																	|it = 'ИД устройства, Данные документа';
																																	|pl = 'Device ID, Document data';
																																	|tr = 'ИД устройства, Данные документа'"), "", "");
	AddOperation(LoggingSystem, 0, "CashInOutcome", NStr("vi = 'In phiếu nhập tiền rút tiền';
														|ru = 'Напечатать чек внесения выемки';
														|en = 'Print the putting cash in / taking cash out receipt'; fa = 'Print the putting cash in / taking cash out receipt';
														|it = 'Напечатать чек внесения выемки';
														|pl = 'Print the putting cash in / taking cash out receipt';
														|tr = 'İptal fişi yazdır'"), "DeviceID, InputParameters, Amount", NStr("vi = 'ID thiết bị, Tham số đầu vào, Số tiền';
																																									|ru = 'ИД устройства, Входные параметры, Сумма';
																																									|en = 'Device ID, Input parameters, Amount'; fa = 'Device ID, Input parameters, Amount';
																																									|it = 'ИД устройства, Входные параметры, Сумма';
																																									|pl = 'Device ID, Input parameters, Amount';
																																									|tr = 'ИД устройства, Входные параметры, Сумма'"), "", "");
	AddOperation(LoggingSystem, 0, "PrintXReport", NStr("vi = 'In báo cáo tạm thời (X-report)';
														|ru = 'Напечатать отчет без гашения';
														|en = 'Print a report without clearance'; fa = 'Print a report without clearance';
														|it = 'Напечатать отчет без гашения';
														|pl = 'Print a report without clearance';
														|tr = 'İptalsiz rapor yazdır'"), "DeviceID, InputParameters", NStr("vi = 'ID thiết bị, Tham số đầu vào';
																																		|ru = 'ИД устройства, Входные параметры';
																																		|en = 'Device ID, Input parameters'; fa = 'Device ID, Input parameters';
																																		|it = 'ИД устройства, Входные параметры';
																																		|pl = 'Device ID, Input parameters';
																																		|tr = 'ИД устройства, Входные параметры'"), "", "");
	AddOperation(LoggingSystem, 0, "PrintCheckCopy", NStr("vi = 'In bản sao phiếu';
															|ru = 'Напечатать копию чека';
															|en = 'Print the receipt copy'; fa = 'چاپ نسخه رسید';
															|it = 'Напечатать копию чека';
															|pl = 'Print the receipt copy';
															|tr = 'Çekin kopyasını yazdır'"), "DeviceID, CheckNumber", NStr("vi = 'IDThiết bị, Dữ liệu của phiếu';
																															|ru = 'ИД устройства, Номер чека';
																															|en = 'Device ID, Receipt number'; fa = 'Device ID, Receipt number';
																															|it = 'ИД устройства, Номер чека';
																															|pl = 'Device ID, Receipt number';
																															|tr = 'ИД устройства, Номер чека'"), "", "");
	AddOperation(LoggingSystem, 0, "GetCurrentStatus", NStr("vi = 'Nhận trạng thái hiện tại';
															|ru = 'Получить текущее состояние';
															|en = 'Get the current state'; fa = 'Get the current state';
															|it = 'Получить текущее состояние';
															|pl = 'Get the current state';
															|tr = 'Mevcut durumu al'"), "DeviceID, InputParameters, ", NStr("vi = 'ID thiết bị, Tham số đầu vào,';
																																|ru = 'ИД устройства, Входные параметры,';
																																|en = 'Device ID, Input parameters,'; fa = 'Device ID, Input parameters,';
																																|it = 'ИД устройства, Входные параметры,';
																																|pl = 'Device ID, Input parameters,';
																																|tr = 'ИД устройства, Входные параметры,'"), ", , OutputParameters", NStr("vi = ', , Tham số đầu ra';
																																																		|ru = ', , Выходные параметры';
																																																		|en = ', , Output parameters'; fa = ', , Output parameters';
																																																		|it = ', , Выходные параметры';
																																																		|pl = ', , Output parameters';
																																																		|tr = ', , Çıkış parametreleri'"));
	AddOperation(LoggingSystem, 3000, "GetCurrentStatus", NStr("vi = 'Nhận trạng thái hiện tại';
																|ru = 'Получить текущее состояние';
																|en = 'Get the current state'; fa = 'Get the current state';
																|it = 'Получить текущее состояние';
																|pl = 'Get the current state';
																|tr = 'Mevcut durumu al'"), "DeviceID, , , , ", NStr("vi = 'ID thiết bị, , , ,';
																														|ru = 'ИД устройства, , , ,';
																														|en = 'Device ID, , , ,'; fa = 'Device ID, , , ,';
																														|it = 'ИД устройства, , , ,';
																														|pl = 'Device ID, , , ,';
																														|tr = 'ИД устройства, , , ,'"), ", CheckNumber, SessionNumber, SessionState, StatusParameters", NStr("vi = ', Số phiếu, Số phiên, Trạng thái phiên, Tham số trạng thái';
																																																							|ru = ', Номер чека, Номер смены, Статус смены, Параметры состояния';
																																																							|en = ', Receipt number, Shift number, Shift status, State parameters'; fa = ', Receipt number, Shift number, Shift status, State parameters';
																																																							|it = ', Номер чека, Номер смены, Статус смены, Параметры состояния';
																																																							|pl = ', Receipt number, Shift number, Shift status, State parameters';
																																																							|tr = ', Çek numarası, Vardiya numarası, Vardiya durumu, Durum parametreleri'"));
	AddOperation(LoggingSystem, 0, "ReportCurrentStatusOfSettlements", NStr("vi = 'Báo cáo về trạng thái tính toán hiện tại';
																			|ru = 'Отчет о текущем состоянии расчетов';
																			|en = 'AR/AP state report'; fa = 'گزارش وضعیت دریافتنی/پرداختنی';
																			|it = 'Отчет о текущем состоянии расчетов';
																			|pl = 'Raport o bieżącym stanie rozliczeń';
																			|tr = 'Отчет о текущем состоянии расчетов'"), "DeviceID, InputParameters, ", NStr("vi = 'ID thiết bị, Tham số đầu vào,';
																																				|ru = 'ИД устройства, Входные параметры,';
																																				|en = 'Device ID, Input parameters,'; fa = 'Device ID, Input parameters,';
																																				|it = 'ИД устройства, Входные параметры,';
																																				|pl = 'Device ID, Input parameters,';
																																				|tr = 'ИД устройства, Входные параметры,'"), ", , OutputParameters", NStr("vi = ', , Tham số đầu ra';
																																																					|ru = ', , Выходные параметры';
																																																					|en = ', , Output parameters'; fa = ', , Output parameters';
																																																					|it = ', , Выходные параметры';
																																																					|pl = ', , Output parameters';
																																																					|tr = ', , Çıkış parametreleri'"));
	AddOperation(LoggingSystem, 0, "OpenCashDrawer", NStr("vi = 'Mở khay đựng tiền ';
															|ru = 'Открыть денежный ящик';
															|en = 'Open a cash till'; fa = 'Open a cash till';
															|it = 'Открыть денежный ящик';
															|pl = 'Otwórz szufladę na gotówkę';
															|tr = 'Kasa çekmecesini aç'"), "DeviceID", NStr("vi = 'ID thiết bị';
																										|ru = 'ИД устройства';
																										|en = 'Device ID'; fa = 'شناسه دستگاه';
																										|it = 'ИД устройства';
																										|pl = 'Device ID';
																										|tr = 'ИД устройства'"), "", "");
	AddOperation(LoggingSystem, 0, "GetLineLength", NStr("vi = 'Nhận chiều dài của dòng';
														|ru = 'Получить ширину строки';
														|en = 'Receive the line width'; fa = 'Receive the line width';
														|it = 'Получить ширину строки';
														|pl = 'Receive the line width';
														|tr = 'Satır genişliğini al'"), "DeviceID, ", NStr("vi = 'ID thiết bị,';
																												|ru = 'ИД устройства,';
																												|en = 'Device ID,'; fa = 'Device ID,';
																												|it = 'ИД устройства,';
																												|pl = 'Device ID,';
																												|tr = 'ИД устройства,'"), ", LineLength", NStr("vi = ', Chiều dài của dòng';
																																						|ru = ', Ширина строки';
																																						|en = ', Line width'; fa = ', Line width';
																																						|it = ', Ширина строки';
																																						|pl = ', Line width';
																																						|tr = ', Satır genişliği'"));
	AddOperation(LoggingSystem, 0, "OpenSessionRegistrationKM", NStr("vi = 'Mở phiên đăng ký máy tính tiền kiểm soát';
																	|ru = 'Открыть сессию регистрации КМ';
																	|en = 'Open the MC registration session'; fa = 'Open the MC registration session';
																	|it = 'Открыть сессию регистрации КМ';
																	|pl = 'Open the MC registration session';
																	|tr = 'Etiketleme Kodu kayıt oturumunu aç'"), "DeviceID", NStr("vi = 'ID thiết bị';
																																	|ru = 'ИД устройства';
																																	|en = 'Device ID'; fa = 'شناسه دستگاه';
																																	|it = 'ИД устройства';
																																	|pl = 'Device ID';
																																	|tr = 'ИД устройства'"), "", "");
	AddOperation(LoggingSystem, 0, "CloseSessionRegistrationKM", NStr("vi = 'Đóng phiên đăng ký máy tính tiền kiểm soát (KM)';
																		|ru = 'Закрыть сессию регистрации КМ';
																		|en = 'Close the MC registration system'; fa = 'Close the MC registration system';
																		|it = 'Закрыть сессию регистрации КМ';
																		|pl = 'Close the MC registration system';
																		|tr = 'Etiketleme Kodu kayıt oturumunu kapat'"), "DeviceID", NStr("vi = 'ID thiết bị';
																																	|ru = 'ИД устройства';
																																	|en = 'Device ID'; fa = 'شناسه دستگاه';
																																	|it = 'ИД устройства';
																																	|pl = 'Device ID';
																																	|tr = 'ИД устройства'"), "", "");
	AddOperation(LoggingSystem, 0, "RequestKM", NStr("vi = 'Yêu cầu KM';
													|ru = 'Запрос КМ';
													|en = 'MC query'; fa = 'MC query';
													|it = 'Запрос КМ';
													|pl = 'MC query';
													|tr = 'Etiketleme Kodu isteği'"), "DeviceID, RequestKM, ", NStr("vi = 'ID thiết bị, Truy vấn KM,';
																										|ru = 'ИД устройства, Запрос КМ,';
																										|en = 'Device ID, MC request,'; fa = 'Device ID, MC request,';
																										|it = 'ИД устройства, Запрос КМ,';
																										|pl = 'Device ID, MC request,';
																										|tr = 'ИД устройства, Запрос КМ,'"), ", , RequestKMResult", NStr("vi = ', , Kết quả yêu cầu KM';
																																									|ru = ', , Результат запроса КМ';
																																									|en = ', , MC query result'; fa = ', , MC query result';
																																									|it = ', , Результат запроса КМ';
																																									|pl = ', , MC query result';
																																									|tr = ', , Etiketleme Kodu istek sonucu'"));
	AddOperation(LoggingSystem, 0, "GetProcessingKMResult", NStr("vi = 'Nhận kết quả yêu cầu KM';
																|ru = 'Получить результаты запроса КМ';
																|en = 'Receive the MC request results'; fa = 'Receive the MC request results';
																|it = 'Получить результаты запроса КМ';
																|pl = 'Receive the MC request results';
																|tr = 'Etiketleme Kodu isteği sonuçlarını al'"), "DeviceID, , ", NStr("vi = 'ID thiết bị, ,';
																																|ru = 'ИД устройства, ,';
																																|en = 'Device ID, ,'; fa = 'Device ID, ,';
																																|it = 'ИД устройства, ,';
																																|pl = 'Device ID, ,';
																																|tr = 'ИД устройства, ,'"), ", ProcessingKMResult, RequestStatus", NStr("vi = ', Kết quả yêu cầu KM, Trạng thái yêu cầu';
																																																	|ru = ', Результат запроса КМ, Статус запроса';
																																																	|en = ', MC request result, Request status'; fa = ', MC request result, Request status';
																																																	|it = ', Результат запроса КМ, Статус запроса';
																																																	|pl = ', MC request result, Request status';
																																																	|tr = ', Etiketleme Kodu isteği sonucu, İstek durumu'"));
	AddOperation(LoggingSystem, 0, "ConfirmKM", NStr("vi = 'Xác nhận KM';
													|ru = 'Подтвердить КМ';
													|en = 'Confirm MC'; fa = 'Confirm MC';
													|it = 'Подтвердить КМ';
													|pl = 'Confirm MC';
													|tr = 'Etiketleme Kodu''nu onayla'"), "DeviceID, GUID, ConfirmationType", NStr("vi = 'IDThiết bị, ID yêu cầu, Kiểu xác nhận';
																													|ru = 'ИД устройства, Идентификатор запроса, Тип подтверждения';
																													|en = 'Device ID, Request ID, Confirmation type'; fa = 'Device ID, Request ID, Confirmation type';
																													|it = 'ИД устройства, Идентификатор запроса, Тип подтверждения';
																													|pl = 'Device ID, Request ID, Confirmation type';
																													|tr = 'ИД устройства, Идентификатор запроса, Тип подтверждения'"), "", "");
	
	// 3.6. Requirements for the development of drivers for receipt printers
	AddOperation(LoggingSystem, 0, "PrintTextDocument", NStr("vi = 'In văn bản thuần';
															|ru = 'Напечатать текстовый документ';
															|en = 'Print the text document'; fa = 'Print the text document';
															|it = 'Напечатать текстовый документ';
															|pl = 'Print the text document';
															|tr = 'Metin belgesi olarak yazdır'"), "DeviceID, DocumentPackage", NStr("vi = 'IDThiết bị, Dữ liệu của chứng từ';
																																	|ru = 'ИД устройства, Данные документа';
																																	|en = 'Device ID, Document data'; fa = 'Device ID, Document data';
																																	|it = 'ИД устройства, Данные документа';
																																	|pl = 'Device ID, Document data';
																																	|tr = 'ИД устройства, Данные документа'"), "", "");
	AddOperation(LoggingSystem, 0, "OpenCashDrawer", NStr("vi = 'Mở khay đựng tiền ';
															|ru = 'Открыть денежный ящик';
															|en = 'Open a cash till'; fa = 'Open a cash till';
															|it = 'Открыть денежный ящик';
															|pl = 'Otwórz szufladę na gotówkę';
															|tr = 'Kasa çekmecesini aç'"), "DeviceID", NStr("vi = 'ID thiết bị';
																										|ru = 'ИД устройства';
																										|en = 'Device ID'; fa = 'شناسه دستگاه';
																										|it = 'ИД устройства';
																										|pl = 'Device ID';
																										|tr = 'ИД устройства'"), "", "");
	AddOperation(LoggingSystem, 0, "GetLineLength", NStr("vi = 'Nhận chiều dài của dòng';
														|ru = 'Получить ширину строки';
														|en = 'Receive the line width'; fa = 'Receive the line width';
														|it = 'Получить ширину строки';
														|pl = 'Receive the line width';
														|tr = 'Satır genişliğini al'"), "DeviceID, ", NStr("vi = 'ID thiết bị,';
																												|ru = 'ИД устройства,';
																												|en = 'Device ID,'; fa = 'Device ID,';
																												|it = 'ИД устройства,';
																												|pl = 'Device ID,';
																												|tr = 'ИД устройства,'"), ", LineLength", NStr("vi = ', Chiều dài của dòng';
																																						|ru = ', Ширина строки';
																																						|en = ', Line width'; fa = ', Line width';
																																						|it = ', Ширина строки';
																																						|pl = ', Line width';
																																						|tr = ', Satır genişliği'"));
	
	// 3.7. Requirements for the development of drivers for label printers
	AddOperation(LoggingSystem, 0, "InitializePrinter", NStr("vi = 'Khởi tạo máy in';
															|ru = 'Инициализация принтера';
															|en = 'Printer initialization'; fa = 'Printer initialization';
															|it = 'Инициализация принтера';
															|pl = 'Printer initialization';
															|tr = 'Yazıcının başlatılması'"), "DeviceID", NStr("vi = 'ID thiết bị';
																												|ru = 'ИД устройства';
																												|en = 'Device ID'; fa = 'شناسه دستگاه';
																												|it = 'ИД устройства';
																												|pl = 'Device ID';
																												|tr = 'ИД устройства'"), "", "");
	AddOperation(LoggingSystem, 0, "PrintLabels", NStr("vi = 'In nhãn tem';
														|ru = 'Печать этикеток';
														|en = 'Print labels'; fa = 'چاپ برچسب‌ها';
														|it = 'Печать этикеток';
														|pl = 'Drukowanie etykiet';
														|tr = 'Etiketleri yazdır'"), "DeviceID, LabelsTable, PackageStatus", NStr("vi = 'ID thiết bị, Bảng hình ảnh, Trạng thái gói';
																															|ru = 'ИД устройства, Таблица этикеток, Статус пакета';
																															|en = 'Device ID, Label table, Package status'; fa = 'Device ID, Label table, Package status';
																															|it = 'ИД устройства, Таблица этикеток, Статус пакета';
																															|pl = 'Device ID, Label table, Package status';
																															|tr = 'ИД устройства, Таблица этикеток, Статус пакета'"), "", "");
	
	// 3.9. Requirements for the development of drivers for acquiring terminals
	AddOperation(LoggingSystem, 0, "TerminalParamters", NStr("vi = 'Tham số thiết bị';
															|ru = 'Параметры терминала';
															|en = 'Terminal parameters'; fa = 'Terminal parameters';
															|it = 'Параметры терминала';
															|pl = 'Terminal parameters';
															|tr = 'Terminal parametreleri'"), "DeviceID, ", NStr("vi = 'ID thiết bị,';
																												|ru = 'ИД устройства,';
																												|en = 'Device ID,'; fa = 'Device ID,';
																												|it = 'ИД устройства,';
																												|pl = 'Device ID,';
																												|tr = 'ИД устройства,'"), ", TerminalParamters", NStr("vi = ', Tham số thiết bị';
																																								|ru = ', Параметры терминала';
																																								|en = ', Terminal parameters'; fa = ', Terminal parameters';
																																								|it = ', Параметры терминала';
																																								|pl = ', Terminal parameters';
																																								|tr = ', Terminal parametreleri'"));
	AddOperation(LoggingSystem, 0, "Pay", NStr("vi = 'Thanh toán';
												|ru = 'Оплатить';
												|en = 'Pay'; fa = 'پرداخت';
												|it = 'Оплатить';
												|pl = 'Pay';
												|tr = 'Öde'"), "DeviceID, OperationParameters, , ", NStr("vi = 'ID thiết bị, Tham số đầu vào, ,';
																										|ru = 'ИД устройства, Входящие параметры, ,';
																										|en = 'Device ID, Input parameters, ,'; fa = 'Device ID, Input parameters, ,';
																										|it = 'Device ID, Input parameters, ,';
																										|pl = 'Device ID, Input parameters, ,';
																										|tr = 'Cihaz ID''si, Giriş parametreleri, ,'"), ", , OperationParameters, Slip", NStr("vi = ', , Tham số đầu ra, Nội dung biên lai';
																																														|ru = ', , Исходящие параметры, Текст квитанции';
																																														|en = ', , Original parameters, Receipt text'; fa = ', , Original parameters, Receipt text';
																																														|it = ', , Исходящие параметры, Текст квитанции';
																																														|pl = ', , Original parameters, Receipt text';
																																														|tr = ', , Giden parametreler, Makbuz metinleri'"));
	AddOperation(LoggingSystem, 0, "ReturnPayment", NStr("vi = 'Trả lại khoản thanh toán';
														|ru = 'Вернуть платеж';
														|en = 'Return the payment'; fa = 'Return the payment';
														|it = 'Вернуть платеж';
														|pl = 'Return the payment';
														|tr = 'Ödemeye dön'"), "DeviceID, OperationParameters, , ", NStr("vi = 'ID thiết bị, Tham số đầu vào, ,';
																																|ru = 'ИД устройства, Входящие параметры, ,';
																																|en = 'Device ID, Input parameters, ,'; fa = 'Device ID, Input parameters, ,';
																																|it = 'Device ID, Input parameters, ,';
																																|pl = 'Device ID, Input parameters, ,';
																																|tr = 'Cihaz ID''si, Giriş parametreleri, ,'"), ", , OperationParameters, Slip", NStr("vi = ', , Tham số đầu ra, Nội dung biên lai';
																																																				|ru = ', , Исходящие параметры, Текст квитанции';
																																																				|en = ', , Original parameters, Receipt text'; fa = ', , Original parameters, Receipt text';
																																																				|it = ', , Исходящие параметры, Текст квитанции';
																																																				|pl = ', , Original parameters, Receipt text';
																																																				|tr = ', , Giden parametreler, Makbuz metinleri'"));
	AddOperation(LoggingSystem, 0, "CancelPayment", NStr("vi = 'Hủy bỏ thanh toán ';
														|ru = 'Отменить платеж';
														|en = 'Cancel the payment'; fa = 'Cancel the payment';
														|it = 'Отменить платеж';
														|pl = 'Cancel the payment';
														|tr = 'Ödemeyi iptal et'"), "DeviceID, OperationParameters, , ", NStr("vi = 'ID thiết bị, Tham số đầu vào, ,';
																																|ru = 'ИД устройства, Входящие параметры, ,';
																																|en = 'Device ID, Input parameters, ,'; fa = 'Device ID, Input parameters, ,';
																																|it = 'Device ID, Input parameters, ,';
																																|pl = 'Device ID, Input parameters, ,';
																																|tr = 'Cihaz ID''si, Giriş parametreleri, ,'"), ", , OperationParameters, Slip", NStr("vi = ', , Tham số đầu ra, Nội dung biên lai';
																																																				|ru = ', , Исходящие параметры, Текст квитанции';
																																																				|en = ', , Original parameters, Receipt text'; fa = ', , Original parameters, Receipt text';
																																																				|it = ', , Исходящие параметры, Текст квитанции';
																																																				|pl = ', , Original parameters, Receipt text';
																																																				|tr = ', , Giden parametreler, Makbuz metinleri'"));
	AddOperation(LoggingSystem, 0, "Authorisation", NStr("vi = 'Xác thực trước';
														|ru = 'Преавторизация';
														|en = 'Preauthorization'; fa = 'Preauthorization';
														|it = 'Преавторизация';
														|pl = 'Preauthorization';
														|tr = 'Ön doğrulama'"), "DeviceID, OperationParameters, , ", NStr("vi = 'ID thiết bị, Tham số đầu vào, ,';
																																|ru = 'ИД устройства, Входящие параметры, ,';
																																|en = 'Device ID, Input parameters, ,'; fa = 'Device ID, Input parameters, ,';
																																|it = 'Device ID, Input parameters, ,';
																																|pl = 'Device ID, Input parameters, ,';
																																|tr = 'Cihaz ID''si, Giriş parametreleri, ,'"), ", , OperationParameters, Slip", NStr("vi = ', , Tham số đầu ra, Nội dung biên lai';
																																																				|ru = ', , Исходящие параметры, Текст квитанции';
																																																				|en = ', , Original parameters, Receipt text'; fa = ', , Original parameters, Receipt text';
																																																				|it = ', , Исходящие параметры, Текст квитанции';
																																																				|pl = ', , Original parameters, Receipt text';
																																																				|tr = ', , Giden parametreler, Makbuz metinleri'"));
	AddOperation(LoggingSystem, 0, "AuthConfirmation", NStr("vi = 'Kết thúc xác thực trước';
															|ru = 'Завершить преавторизацию';
															|en = 'Finish preauthorization'; fa = 'پایان پیش‌احراز مجوز';
															|it = 'Завершить преавторизацию';
															|pl = 'Zakończ autoryzację ponowną';
															|tr = 'Ön doğrulamayı tamamla'"), "DeviceID, OperationParameters, , ", NStr("vi = 'ID thiết bị, Tham số đầu vào, ,';
																																		|ru = 'ИД устройства, Входящие параметры, ,';
																																		|en = 'Device ID, Input parameters, ,'; fa = 'Device ID, Input parameters, ,';
																																		|it = 'Device ID, Input parameters, ,';
																																		|pl = 'Device ID, Input parameters, ,';
																																		|tr = 'Cihaz ID''si, Giriş parametreleri, ,'"), ", , OperationParameters, Slip", NStr("vi = ', , Tham số đầu ra, Nội dung biên lai';
																																																						|ru = ', , Исходящие параметры, Текст квитанции';
																																																						|en = ', , Original parameters, Receipt text'; fa = ', , Original parameters, Receipt text';
																																																						|it = ', , Исходящие параметры, Текст квитанции';
																																																						|pl = ', , Original parameters, Receipt text';
																																																						|tr = ', , Giden parametreler, Makbuz metinleri'"));
	AddOperation(LoggingSystem, 0, "CancelAuthorisation", NStr("vi = 'Hủy bỏ xác thực trước';
																|ru = 'Отменить преавторизацию';
																|en = 'Cancel preauthorization'; fa = 'لغو پیش‌احراز مجوز';
																|it = 'Отменить преавторизацию';
																|pl = 'Anuluj autoryzację ponowną';
																|tr = 'Ön doğrulamayı iptal et'"), "DeviceID, OperationParameters, , ", NStr("vi = 'ID thiết bị, Tham số đầu vào, ,';
																																			|ru = 'ИД устройства, Входящие параметры, ,';
																																			|en = 'Device ID, Input parameters, ,'; fa = 'Device ID, Input parameters, ,';
																																			|it = 'Device ID, Input parameters, ,';
																																			|pl = 'Device ID, Input parameters, ,';
																																			|tr = 'Cihaz ID''si, Giriş parametreleri, ,'"), ", , OperationParameters, Slip", NStr("vi = ', , Tham số đầu ra, Nội dung biên lai';
																																																							|ru = ', , Исходящие параметры, Текст квитанции';
																																																							|en = ', , Original parameters, Receipt text'; fa = ', , Original parameters, Receipt text';
																																																							|it = ', , Исходящие параметры, Текст квитанции';
																																																							|pl = ', , Original parameters, Receipt text';
																																																							|tr = ', , Giden parametreler, Makbuz metinleri'"));
	AddOperation(LoggingSystem, 0, "PayWithCashWithdrawal", NStr("vi = 'Thanh toán có chi tiền';
																|ru = 'Оплата с выдачей наличных';
																|en = 'Payment with cash issue'; fa = 'Payment with cash issue';
																|it = 'Оплата с выдачей наличных';
																|pl = 'Payment with cash issue';
																|tr = 'Оплата с выдачей наличных'"), "DeviceID, OperationParameters, , ", NStr("vi = 'ID thiết bị, Tham số đầu vào, ,';
																																				|ru = 'ИД устройства, Входящие параметры, ,';
																																				|en = 'Device ID, Input parameters, ,'; fa = 'Device ID, Input parameters, ,';
																																				|it = 'Device ID, Input parameters, ,';
																																				|pl = 'Device ID, Input parameters, ,';
																																				|tr = 'Cihaz ID''si, Giriş parametreleri, ,'"), ", , OperationParameters, Slip", NStr("vi = ', , Tham số đầu ra, Nội dung biên lai';
																																																								|ru = ', , Исходящие параметры, Текст квитанции';
																																																								|en = ', , Original parameters, Receipt text'; fa = ', , Original parameters, Receipt text';
																																																								|it = ', , Исходящие параметры, Текст квитанции';
																																																								|pl = ', , Original parameters, Receipt text';
																																																								|tr = ', , Giden parametreler, Makbuz metinleri'"));
	AddOperation(LoggingSystem, 0, "PurchaseWithEnrollment", NStr("vi = 'Mua hàng có tính đến';
																	|ru = 'Покупка с зачислением';
																	|en = 'Purchase with deposit'; fa = 'خرید با واریز';
																	|it = 'Покупка с зачислением';
																	|pl = 'Purchase with deposit';
																	|tr = 'Покупка с зачислением'"), "DeviceID, OperationParameters, , ", NStr("vi = 'ID thiết bị, Tham số đầu vào, ,';
																																			|ru = 'ИД устройства, Входящие параметры, ,';
																																			|en = 'Device ID, Input parameters, ,'; fa = 'Device ID, Input parameters, ,';
																																			|it = 'Device ID, Input parameters, ,';
																																			|pl = 'Device ID, Input parameters, ,';
																																			|tr = 'Cihaz ID''si, Giriş parametreleri, ,'"), ", , OperationParameters, Slip", NStr("vi = ', , Tham số đầu ra, Nội dung biên lai';
																																																							|ru = ', , Исходящие параметры, Текст квитанции';
																																																							|en = ', , Original parameters, Receipt text'; fa = ', , Original parameters, Receipt text';
																																																							|it = ', , Исходящие параметры, Текст квитанции';
																																																							|pl = ', , Original parameters, Receipt text';
																																																							|tr = ', , Giden parametreler, Makbuz metinleri'"));
	AddOperation(LoggingSystem, 0, "GetCardParametrs", NStr("vi = 'Nhận tham số thẻ';
															|ru = 'Получить параметры карты';
															|en = 'Get card details'; fa = 'Get card details';
															|it = 'Получить параметры карты';
															|pl = 'Get card details';
															|tr = 'Kart parametrelerini al'"), "DeviceID, ConsumerPresentedQR, FromLastOperation, , , , , ", NStr("vi = 'IDThiết bị, Mục tin thẻ QR, Từ giao dịch gần nhất, , , , , ';
																																							|ru = 'ИД устройства, Реквизиты карты QR, От последней операции, , , , ,';
																																							|en = 'Device ID, Attributes of QR card, Since last operation, , , , ,'; fa = 'Device ID, Attributes of QR card, Since last operation, , , , ,';
																																							|it = 'ИД устройства, Реквизиты карты QR, От последней операции, , , , ,';
																																							|pl = 'Device ID, Attributes of QR card, Since last operation, , , , ,';
																																							|tr = 'ИД устройства, Реквизиты карты QR, От последней операции, , , , ,'"), ", , , CardNumber, CardNumberHash, PaymentAccountReference, CardType, IsOwnCard", NStr("vi = ', , , Số thẻ, Hash số thẻ, Tham chiếu đến tài khoản thanh toán, Kiểu thẻ, Thẻ riêng';
																																																																															|ru = ', , , Номер карты, Хеш номер карты, Ссылка на платежный счет, Тип карты, Своя карта';
																																																																															|en = ', , ,  Card number, Hash number of the card, reference to the payment account, Card type, Own card'; fa = ', , ,  Card number, Hash number of the card, reference to the payment account, Card type, Own card';
																																																																															|it = ', , , Номер карты, Хеш номер карты, Ссылка на платежный счет, Тип карты, Своя карта';
																																																																															|pl = ', , ,  Card number, Hash number of the card, reference to the payment account, Card type, Own card';
																																																																															|tr = ', , , Kart numarası, Kart önbellek numarası, Ödeme hesabı referansı, Kart türü, Kendi kartım'"));
	AddOperation(LoggingSystem, 0, "PayCertificate", NStr("vi = 'Thanh toán bằng phiếu quà tặng';
															|ru = 'Оплатить сертификатом';
															|en = 'Pay with a certificate'; fa = 'Pay with a certificate';
															|it = 'Оплатить сертификатом';
															|pl = 'Pay with a certificate';
															|tr = 'Sertifikayla öde'"), "DeviceID, OperationParameters, , ", NStr("vi = 'ID thiết bị, Tham số đầu vào, ,';
																																		|ru = 'ИД устройства, Входящие параметры, ,';
																																		|en = 'Device ID, Input parameters, ,'; fa = 'Device ID, Input parameters, ,';
																																		|it = 'Device ID, Input parameters, ,';
																																		|pl = 'Device ID, Input parameters, ,';
																																		|tr = 'Cihaz ID''si, Giriş parametreleri, ,'"), ", , OperationParameters, Slip", NStr("vi = ', , Tham số đầu ra, Nội dung biên lai';
																																																						|ru = ', , Исходящие параметры, Текст квитанции';
																																																						|en = ', , Original parameters, Receipt text'; fa = ', , Original parameters, Receipt text';
																																																						|it = ', , Исходящие параметры, Текст квитанции';
																																																						|pl = ', , Original parameters, Receipt text';
																																																						|tr = ', , Giden parametreler, Makbuz metinleri'"));
	AddOperation(LoggingSystem, 0, "ReturnCertificate", NStr("vi = 'Trả lại bằng phiếu quà tặng';
															|ru = 'Вернуть сертификатом';
															|en = 'Return with a certificate'; fa = 'Return with a certificate';
															|it = 'Вернуть сертификатом';
															|pl = 'Return with a certificate';
															|tr = 'Sertifikaları geri gönder'"), "DeviceID, OperationParameters, , ", NStr("vi = 'ID thiết bị, Tham số đầu vào, ,';
																																			|ru = 'ИД устройства, Входящие параметры, ,';
																																			|en = 'Device ID, Input parameters, ,'; fa = 'Device ID, Input parameters, ,';
																																			|it = 'Device ID, Input parameters, ,';
																																			|pl = 'Device ID, Input parameters, ,';
																																			|tr = 'Cihaz ID''si, Giriş parametreleri, ,'"), ", , OperationParameters, Slip", NStr("vi = ', , Tham số đầu ra, Nội dung biên lai';
																																																							|ru = ', , Исходящие параметры, Текст квитанции';
																																																							|en = ', , Original parameters, Receipt text'; fa = ', , Original parameters, Receipt text';
																																																							|it = ', , Исходящие параметры, Текст квитанции';
																																																							|pl = ', , Original parameters, Receipt text';
																																																							|tr = ', , Giden parametreler, Makbuz metinleri'"));
	AddOperation(LoggingSystem, 0, "EmergencyReversal", NStr("vi = 'Hủy bỏ khẩn cấp một giao dịch';
															|ru = 'Аварийная отмена операции';
															|en = 'Abnormal cancellation of the operation'; fa = 'Abnormal cancellation of the operation';
															|it = 'Аварийная отмена операции';
															|pl = 'Abnormal cancellation of the operation';
															|tr = 'Acil durum iptali işlemi'"), "DeviceID", NStr("vi = 'ID thiết bị';
																																|ru = 'ИД устройства';
																																|en = 'Device ID'; fa = 'شناسه دستگاه';
																																|it = 'ИД устройства';
																																|pl = 'Device ID';
																																|tr = 'ИД устройства'"), "", "");
	AddOperation(LoggingSystem, 0, "GetOperationByCards", NStr("vi = 'Nhận giao dịch theo thẻ';
																|ru = 'Получить операции по картам';
																|en = 'Receive card transactions'; fa = 'Receive card transactions';
																|it = 'Получить операции по картам';
																|pl = 'Receive card transactions';
																|tr = 'Kartlara işlemlerini al'"), "DeviceID, ", NStr("vi = 'ID thiết bị,';
																														|ru = 'ИД устройства,';
																														|en = 'Device ID,'; fa = 'Device ID,';
																														|it = 'ИД устройства,';
																														|pl = 'Device ID,';
																														|tr = 'ИД устройства,'"), ", TableOperations", NStr("vi = ', Bảng giao dịch';
																																										|ru = ', Таблица операций';
																																										|en = ', Transaction table'; fa = ', Transaction table';
																																										|it = ', Таблица операций';
																																										|pl = ', Transaction table';
																																										|tr = ', İşlem tablosu'"));
	AddOperation(LoggingSystem, 0, "Settlement", NStr("vi = 'Tổng số ngày theo thẻ';
														|ru = 'Итоги дня по картам';
														|en = 'Day results by cards'; fa = 'Day results by cards';
														|it = 'Итоги дня по картам';
														|pl = 'Day results by cards';
														|tr = 'Kart günlerinin toplamı'"), "DeviceID, ", NStr("vi = 'ID thiết bị,';
																										|ru = 'ИД устройства,';
																										|en = 'Device ID,'; fa = 'Device ID,';
																										|it = 'ИД устройства,';
																										|pl = 'Device ID,';
																										|tr = 'ИД устройства,'"), ", Slip", NStr("vi = ', Nội dung biên lai';
																																				|ru = ', Текст квитанции';
																																				|en = ', Receipt text'; fa = ', Receipt text';
																																				|it = ', Текст квитанции';
																																				|pl = ', Receipt text';
																																				|tr = ', Makbuz metni'"));

	AddOperation(LoggingSystem, 3005, "PayByPaymentCard", NStr("vi = 'Thanh toán bằng thẻ thanh toán';
																|ru = 'Оплатить платежной картой';
																|en = 'Pay by payment card'; fa = 'پرداخت با کارت پرداخت';
																|it = 'Оплатить платежной картой';
																|pl = 'Zapłać kartą płatniczą';
																|tr = 'Ödeme kartıyla öde'"), "DeviceID, CardNumber, Amount, ReceiptNumber, , , ", NStr("vi = 'IDThiết bị, Số thẻ, Số tiền, Số phiếu, , , ';
																																						|ru = 'ИД устройства, Номер карты, Сумма, Номер чека, , ,';
																																						|en = 'Device ID, Card number, Amount, Receipt number, , ,'; fa = 'Device ID, Card number, Amount, Receipt number, , ,';
																																						|it = 'ИД устройства, Номер карты, Сумма, Номер чека, , ,';
																																						|pl = 'Device ID, Card number, Amount, Receipt number, , ,';
																																						|tr = 'ИД устройства, Номер карты, Сумма, Номер чека, , ,'"), ", CardNumber, , ReceiptNumber, RRNCode, AuthorizationCode, Slip", NStr("vi = ', , , Số thẻ, Số phiếu, Mã RRN, Mã đăng nhập, Nội dung biên lai';
																																																																								|ru = ', Номер карты, , Номер чека, Код RRN, Код авторизации, Текст квитанции';
																																																																								|en = ', Card number, , Receipt number, RRN code, Authorization code, Receipt text'; fa = ', Card number, , Receipt number, RRN code, Authorization code, Receipt text';
																																																																								|it = ', Номер карты, , Номер чека, Код RRN, Код авторизации, Текст квитанции';
																																																																								|pl = ', Card number, , Receipt number, RRN code, Authorization code, Receipt text';
																																																																								|tr = ', Kart numarası, Çek numarası, RPN kodu, Doğrulama kodu, Makbuz metni'"));
	AddOperation(LoggingSystem, 4000, "PayByPaymentCard", NStr("vi = 'Thanh toán bằng thẻ thanh toán';
																|ru = 'Оплатить платежной картой';
																|en = 'Pay by payment card'; fa = 'پرداخت با کارت پرداخت';
																|it = 'Оплатить платежной картой';
																|pl = 'Zapłać kartą płatniczą';
																|tr = 'Ödeme kartıyla öde'"), "DeviceID, MerchantNumber, Amount, CardNumber, ReceiptNumber, , , ", NStr("vi = 'IDThiết bị, Số người bán, Số tiền, Số thẻ, Số phiếu, , , ';
																																										|ru = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, , ,';
																																										|en = 'Device ID, Merchant number, Amount, Card number, Receipt number, , ,'; fa = 'Device ID, Merchant number, Amount, Card number, Receipt number, , ,';
																																										|it = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, , ,';
																																										|pl = 'Device ID, Merchant number, Amount, Card number, Receipt number, , ,';
																																										|tr = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, , ,'"), ", , , CardNumber, ReceiptNumber, RRNCode, AuthorizationCode, Slip", NStr("vi = ', , , Số thẻ, Số phiếu, Mã RRN, Mã đăng nhập, Nội dung biên lai';
																																																																																	|ru = ', , , Номер карты, Номер чека, Код RRN, Код авторизации, Текст квитанции';
																																																																																	|en = ', , , Card number, Receipt number, RRN code, Authorization code, Receipt text'; fa = ', , , Card number, Receipt number, RRN code, Authorization code, Receipt text';
																																																																																	|it = ', , , Номер карты, Номер чека, Код RRN, Код авторизации, Текст квитанции';
																																																																																	|pl = ', , , Card number, Receipt number, RRN code, Authorization code, Receipt text';
																																																																																	|tr = ', , , Kart numarası, Çek numarası, RPN kodu, Doğrulama kodu, Makbuz metni'"));
	AddOperation(LoggingSystem, 0, "PayByPaymentCard", NStr("vi = 'Thanh toán bằng thẻ thanh toán';
															|ru = 'Оплатить платежной картой';
															|en = 'Pay by payment card'; fa = 'پرداخت با کارت پرداخت';
															|it = 'Оплатить платежной картой';
															|pl = 'Zapłać kartą płatniczą';
															|tr = 'Ödeme kartıyla öde'"), "DeviceID, MerchantNumber, Amount, CardNumber, ReceiptNumber, , , ", NStr("vi = 'IDThiết bị, Số người bán, Số tiền, Số thẻ, Số phiếu, , , ';
																																									|ru = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, , ,';
																																									|en = 'Device ID, Merchant number, Amount, Card number, Receipt number, , ,'; fa = 'Device ID, Merchant number, Amount, Card number, Receipt number, , ,';
																																									|it = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, , ,';
																																									|pl = 'Device ID, Merchant number, Amount, Card number, Receipt number, , ,';
																																									|tr = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, , ,'"), ", , , CardNumber, ReceiptNumber, RRNCode, AuthorizationCode, Slip", NStr("vi = ', , , Số thẻ, Số phiếu, Mã RRN, Mã đăng nhập, Nội dung biên lai';
																																																																																|ru = ', , , Номер карты, Номер чека, Код RRN, Код авторизации, Текст квитанции';
																																																																																|en = ', , , Card number, Receipt number, RRN code, Authorization code, Receipt text'; fa = ', , , Card number, Receipt number, RRN code, Authorization code, Receipt text';
																																																																																|it = ', , , Номер карты, Номер чека, Код RRN, Код авторизации, Текст квитанции';
																																																																																|pl = ', , , Card number, Receipt number, RRN code, Authorization code, Receipt text';
																																																																																|tr = ', , , Kart numarası, Çek numarası, RPN kodu, Doğrulama kodu, Makbuz metni'"));
	
	AddOperation(LoggingSystem, 3005, "ReturnPaymentByPaymentCard", NStr("vi = 'Trả lại thanh toán theo thẻ thanh toán';
																		|ru = 'Вернуть платеж по платежной карте';
																		|en = 'Payment return by payment card'; fa = 'Payment return by payment card';
																		|it = 'Вернуть платеж по платежной карте';
																		|pl = 'Payment return by payment card';
																		|tr = 'Kartla ödeme iadesine dön'"), "DeviceID, CardNumber, Amount, ReceiptNumber, RRNCode, AuthorizationCode, ", NStr("vi = 'IDThiết bị, Số thẻ, Số tiền, Số phiếu, Mã RRN, Mã đăng nhập,';
																																																	|ru = 'ИД устройства, Номер карты, Сумма, Номер чека, Код RRN, Код авторизации,';
																																																	|en = 'Device ID, Card number, Amount, Receipt number, RRN code, Authorization code,'; fa = 'Device ID, Card number, Amount, Receipt number, RRN code, Authorization code,';
																																																	|it = 'ИД устройства, Номер карты, Сумма, Номер чека, Код RRN, Код авторизации,';
																																																	|pl = 'Device ID, Card number, Amount, Receipt number, RRN code, Authorization code,';
																																																	|tr = 'ИД устройства, Номер карты, Сумма, Номер чека, Код RRN, Код авторизации,'"), ", CardNumber, , ReceiptNumber, RRNCode, AuthorizationCode, Slip", NStr("vi = ', , , Số thẻ, Số phiếu, Mã RRN, Mã đăng nhập, Nội dung biên lai';
																																																																																										|ru = ', Номер карты, , Номер чека, Код RRN, Код авторизации, Текст квитанции';
																																																																																										|en = ', Card number, , Receipt number, RRN code, Authorization code, Receipt text'; fa = ', Card number, , Receipt number, RRN code, Authorization code, Receipt text';
																																																																																										|it = ', Номер карты, , Номер чека, Код RRN, Код авторизации, Текст квитанции';
																																																																																										|pl = ', Card number, , Receipt number, RRN code, Authorization code, Receipt text';
																																																																																										|tr = ', Kart numarası, Çek numarası, RPN kodu, Doğrulama kodu, Makbuz metni'"));
	AddOperation(LoggingSystem, 4000, "ReturnPaymentByPaymentCard", NStr("vi = 'Trả lại thanh toán theo thẻ thanh toán';
																		|ru = 'Вернуть платеж по платежной карте';
																		|en = 'Payment return by payment card'; fa = 'Payment return by payment card';
																		|it = 'Вернуть платеж по платежной карте';
																		|pl = 'Payment return by payment card';
																		|tr = 'Kartla ödeme iadesine dön'"), "DeviceID, MerchantNumber, Amount, CardNumber, ReceiptNumber, RRNCode, AuthorizationCode, ", NStr("vi = 'IDThiết bị, Số người bán, Số tiền, Số thẻ, Số phiếu, Mã RRN, Mã đăng nhập,';
																																																					|ru = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, Код RRN, Код авторизации,';
																																																					|en = 'Device ID, Merchant number, Amount, Card number, Receipt number, RRN code, Authorization code,'; fa = 'Device ID, Merchant number, Amount, Card number, Receipt number, RRN code, Authorization code,';
																																																					|it = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, Код RRN, Код авторизации,';
																																																					|pl = 'Device ID, Merchant number, Amount, Card number, Receipt number, RRN code, Authorization code,';
																																																					|tr = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, Код RRN, Код авторизации,'"), ", , , CardNumber, ReceiptNumber, RRNCode, , Slip", NStr("vi = ', , , Số thẻ, Số phiếu, Mã RRN, Nội dung biên lai';
																																																																																														|ru = ', , , Номер карты, Номер чека, Код RRN, , Текст квитанции';
																																																																																														|en = ', , , Card number, Receipt number, RRN code, Receipt text'; fa = ', , , Card number, Receipt number, RRN code, Receipt text';
																																																																																														|it = ', , , Номер карты, Номер чека, Код RRN, , Текст квитанции';
																																																																																														|pl = ', , , Card number, Receipt number, RRN code, Receipt text';
																																																																																														|tr = ', , , Kart numarası, Çek numarası, RPN kodu, , Makbuz metni'"));
	AddOperation(LoggingSystem, 0, "ReturnPaymentByPaymentCard", NStr("vi = 'Trả lại thanh toán theo thẻ thanh toán';
																		|ru = 'Вернуть платеж по платежной карте';
																		|en = 'Payment return by payment card'; fa = 'Payment return by payment card';
																		|it = 'Вернуть платеж по платежной карте';
																		|pl = 'Payment return by payment card';
																		|tr = 'Kartla ödeme iadesine dön'"), "DeviceID, MerchantNumber, Amount, CardNumber, ReceiptNumber, RRNCode, AuthorizationCode, ", NStr("vi = 'IDThiết bị, Số người bán, Số tiền, Số thẻ, Số phiếu, Mã RRN, Mã đăng nhập,';
																																																					|ru = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, Код RRN, Код авторизации,';
																																																					|en = 'Device ID, Merchant number, Amount, Card number, Receipt number, RRN code, Authorization code,'; fa = 'Device ID, Merchant number, Amount, Card number, Receipt number, RRN code, Authorization code,';
																																																					|it = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, Код RRN, Код авторизации,';
																																																					|pl = 'Device ID, Merchant number, Amount, Card number, Receipt number, RRN code, Authorization code,';
																																																					|tr = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, Код RRN, Код авторизации,'"), ", , , CardNumber, ReceiptNumber, RRNCode, , Slip", NStr("vi = ', , , Số thẻ, Số phiếu, Mã RRN, Nội dung biên lai';
																																																																																													|ru = ', , , Номер карты, Номер чека, Код RRN, , Текст квитанции';
																																																																																													|en = ', , , Card number, Receipt number, RRN code, Receipt text'; fa = ', , , Card number, Receipt number, RRN code, Receipt text';
																																																																																													|it = ', , , Номер карты, Номер чека, Код RRN, , Текст квитанции';
																																																																																													|pl = ', , , Card number, Receipt number, RRN code, Receipt text';
																																																																																													|tr = ', , , Kart numarası, Çek numarası, RPN kodu, , Makbuz metni'"));

	AddOperation(LoggingSystem, 3005, "CancelPaymentByPaymentCard", NStr("vi = 'Hủy bỏ thanh toán theo thẻ thanh toán';
																		|ru = 'Отменить платеж по платежной карте';
																		|en = 'Cancel payment by payment card'; fa = 'لغو پرداخت با کارت پرداخت';
																		|it = 'Отменить платеж по платежной карте';
																		|pl = 'Cancel payment by payment card';
																		|tr = 'Ödeme kartı ile ödemeyi iptal et'"), "DeviceID, CardNumber, Amount, ReceiptNumber, RRNCode, AuthorizationCode, ", NStr("vi = 'IDThiết bị, Số thẻ, Số tiền, Số phiếu, Mã RRN, Mã đăng nhập,';
																																																	|ru = 'ИД устройства, Номер карты, Сумма, Номер чека, Код RRN, Код авторизации,';
																																																	|en = 'Device ID, Card number, Amount, Receipt number, RRN code, Authorization code,'; fa = 'Device ID, Card number, Amount, Receipt number, RRN code, Authorization code,';
																																																	|it = 'ИД устройства, Номер карты, Сумма, Номер чека, Код RRN, Код авторизации,';
																																																	|pl = 'Device ID, Card number, Amount, Receipt number, RRN code, Authorization code,';
																																																	|tr = 'ИД устройства, Номер карты, Сумма, Номер чека, Код RRN, Код авторизации,'"), ", CardNumber, , ReceiptNumber, RRNCode, AuthorizationCode, Slip", NStr("vi = ', , , Số thẻ, Số phiếu, Mã RRN, Mã đăng nhập, Nội dung biên lai';
																																																																																										|ru = ', Номер карты, , Номер чека, Код RRN, Код авторизации, Текст квитанции';
																																																																																										|en = ', Card number, , Receipt number, RRN code, Authorization code, Receipt text'; fa = ', Card number, , Receipt number, RRN code, Authorization code, Receipt text';
																																																																																										|it = ', Номер карты, , Номер чека, Код RRN, Код авторизации, Текст квитанции';
																																																																																										|pl = ', Card number, , Receipt number, RRN code, Authorization code, Receipt text';
																																																																																										|tr = ', Kart numarası, Çek numarası, RPN kodu, Doğrulama kodu, Makbuz metni'"));
	AddOperation(LoggingSystem, 4000, "CancelPaymentByPaymentCard", NStr("vi = 'Hủy bỏ thanh toán theo thẻ thanh toán';
																		|ru = 'Отменить платеж по платежной карте';
																		|en = 'Cancel payment by payment card'; fa = 'لغو پرداخت با کارت پرداخت';
																		|it = 'Отменить платеж по платежной карте';
																		|pl = 'Cancel payment by payment card';
																		|tr = 'Ödeme kartı ile ödemeyi iptal et'"), "DeviceID, MerchantNumber, Amount, CardNumber, ReceiptNumber, RRNCode, AuthorizationCode, ", NStr("vi = 'IDThiết bị, Số người bán, Số tiền, Số thẻ, Số phiếu, Mã RRN, Mã đăng nhập,';
																																																					|ru = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, Код RRN, Код авторизации,';
																																																					|en = 'Device ID, Merchant number, Amount, Card number, Receipt number, RRN code, Authorization code,'; fa = 'Device ID, Merchant number, Amount, Card number, Receipt number, RRN code, Authorization code,';
																																																					|it = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, Код RRN, Код авторизации,';
																																																					|pl = 'Device ID, Merchant number, Amount, Card number, Receipt number, RRN code, Authorization code,';
																																																					|tr = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, Код RRN, Код авторизации,'"), ", , , CardNumber, ReceiptNumber, , , Slip", NStr("vi = ', , , Số thẻ, Số phiếu, , , Nội dung biên lai';
																																																																																												|ru = ', , , Номер карты, Номер чека, , , Текст квитанции';
																																																																																												|en = ', , , Card number, Receipt number, , , Receipt text'; fa = ', , , Card number, Receipt number, , , Receipt text';
																																																																																												|it = ', , , Номер карты, Номер чека, , , Текст квитанции';
																																																																																												|pl = ', , , Card number, Receipt number, , , Receipt text';
																																																																																												|tr = ', , , Kart numarası, Çek numarası, , , Makbuz metni'"));
	AddOperation(LoggingSystem, 0, "CancelPaymentByPaymentCard", NStr("vi = 'Hủy bỏ thanh toán theo thẻ thanh toán';
																		|ru = 'Отменить платеж по платежной карте';
																		|en = 'Cancel payment by payment card'; fa = 'لغو پرداخت با کارت پرداخت';
																		|it = 'Отменить платеж по платежной карте';
																		|pl = 'Cancel payment by payment card';
																		|tr = 'Ödeme kartı ile ödemeyi iptal et'"), "DeviceID, MerchantNumber, Amount, CardNumber, ReceiptNumber, RRNCode, AuthorizationCode, ", NStr("vi = 'IDThiết bị, Số người bán, Số tiền, Số thẻ, Số phiếu, Mã RRN, Mã đăng nhập,';
																																																					|ru = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, Код RRN, Код авторизации,';
																																																					|en = 'Device ID, Merchant number, Amount, Card number, Receipt number, RRN code, Authorization code,'; fa = 'Device ID, Merchant number, Amount, Card number, Receipt number, RRN code, Authorization code,';
																																																					|it = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, Код RRN, Код авторизации,';
																																																					|pl = 'Device ID, Merchant number, Amount, Card number, Receipt number, RRN code, Authorization code,';
																																																					|tr = 'ИД устройства, Номер мерчанта, Сумма, Номер карты, Номер чека, Код RRN, Код авторизации,'"), ", , , CardNumber, ReceiptNumber, , , Slip", NStr("vi = ', , , Số thẻ, Số phiếu, , , Nội dung biên lai';
																																																																																												|ru = ', , , Номер карты, Номер чека, , , Текст квитанции';
																																																																																												|en = ', , , Card number, Receipt number, , , Receipt text'; fa = ', , , Card number, Receipt number, , , Receipt text';
																																																																																												|it = ', , , Номер карты, Номер чека, , , Текст квитанции';
																																																																																												|pl = ', , , Card number, Receipt number, , , Receipt text';
																																																																																												|tr = ', , , Kart numarası, Çek numarası, , , Makbuz metni'"));
	
	AddOperation(LoggingSystem, 4000, "PayByPaymentCardWithCashWithdrawal", NStr("vi = 'Thanh toán bằng thẻ thanh toán Kèm Chi tiền';
																				|ru = 'Оплатить платежной картой с выдачей наличных';
																				|en = 'Pay by payment card with cash issue'; fa = 'Pay by payment card with cash issue';
																				|it = 'Оплатить платежной картой с выдачей наличных';
																				|pl = 'Pay by payment card with cash issue';
																				|tr = 'Оплатить платежной картой с выдачей наличных'"), "DeviceID, MerchantNumber, AmountPayment, AmountCash, , , , , ", NStr("vi = 'IDThiết bị, Số người bán, Số tiền giao dịch, Số tiền mặt, , , , , ';
																																																		|ru = 'ИД устройства, Номер мерчанта, Сумма операции, Сумма наличных, , , , ,';
																																																		|en = 'Device ID, Merchant number, Transaction amount, Cash amount, , , , ,'; fa = 'Device ID, Merchant number, Transaction amount, Cash amount, , , , ,';
																																																		|it = 'ИД устройства, Номер мерчанта, Сумма операции, Сумма наличных, , , , ,';
																																																		|pl = 'Device ID, Merchant number, Transaction amount, Cash amount, , , , ,';
																																																		|tr = 'ИД устройства, Номер мерчанта, Сумма операции, Сумма наличных, , , , ,'"), ", , , , CardNumber, ReceiptNumber, RRNCode, AuthorizationCode, Slip", NStr("vi = ', , , Số thẻ, Số phiếu, Mã RRN, Mã đăng nhập, Nội dung biên lai';
																																																																																									|ru = ', , , , Номер карты, Номер чека, Код RRN, Код авторизации, Текст квитанции';
																																																																																									|en = ', , , , Card number, Receipt number, RRN Code, Authorization code, Receipt text'; fa = ', , , , Card number, Receipt number, RRN Code, Authorization code, Receipt text';
																																																																																									|it = ', , , , Номер карты, Номер чека, Код RRN, Код авторизации, Текст квитанции';
																																																																																									|pl = ', , , , Card number, Receipt number, RRN Code, Authorization code, Receipt text';
																																																																																									|tr = ', , , Kart numarası, Çek numarası, RPN kodu, Doğrulama kodu, Makbuz metni'"));
	AddOperation(LoggingSystem, 0, "PayByPaymentCardWithCashWithdrawal", NStr("vi = 'Thanh toán bằng thẻ thanh toán Kèm Chi tiền';
																				|ru = 'Оплатить платежной картой с выдачей наличных';
																				|en = 'Pay by payment card with cash issue'; fa = 'Pay by payment card with cash issue';
																				|it = 'Оплатить платежной картой с выдачей наличных';
																				|pl = 'Pay by payment card with cash issue';
																				|tr = 'Оплатить платежной картой с выдачей наличных'"), "DeviceID, MerchantNumber, AmountPayment, AmountCash, , , , , ", NStr("vi = 'IDThiết bị, Số người bán, Số tiền giao dịch, Số tiền mặt, , , , , ';
																																																	|ru = 'ИД устройства, Номер мерчанта, Сумма операции, Сумма наличных, , , , ,';
																																																	|en = 'Device ID, Merchant number, Transaction amount, Cash amount, , , , ,'; fa = 'Device ID, Merchant number, Transaction amount, Cash amount, , , , ,';
																																																	|it = 'ИД устройства, Номер мерчанта, Сумма операции, Сумма наличных, , , , ,';
																																																	|pl = 'Device ID, Merchant number, Transaction amount, Cash amount, , , , ,';
																																																	|tr = 'ИД устройства, Номер мерчанта, Сумма операции, Сумма наличных, , , , ,'"), ", , , , CardNumber, ReceiptNumber, RRNCode, AuthorizationCode, Slip", NStr("vi = ', , , Số thẻ, Số phiếu, Mã RRN, Mã đăng nhập, Nội dung biên lai';
																																																																																								|ru = ', , , , Номер карты, Номер чека, Код RRN, Код авторизации, Текст квитанции';
																																																																																								|en = ', , , , Card number, Receipt number, RRN Code, Authorization code, Receipt text'; fa = ', , , , Card number, Receipt number, RRN Code, Authorization code, Receipt text';
																																																																																								|it = ', , , , Номер карты, Номер чека, Код RRN, Код авторизации, Текст квитанции';
																																																																																								|pl = ', , , , Card number, Receipt number, RRN Code, Authorization code, Receipt text';
																																																																																								|tr = ', , , Kart numarası, Çek numarası, RPN kodu, Doğrulama kodu, Makbuz metni'"));

	AddOperation(LoggingSystem, 3005, "GetCardParametrs", NStr("vi = 'Nhận tham số thẻ';
																|ru = 'Получить параметры карты';
																|en = 'Get card details'; fa = 'Get card details';
																|it = 'Получить параметры карты';
																|pl = 'Get card details';
																|tr = 'Kart parametrelerini al'"), "DeviceID, FromLastOperation, , , , ", NStr("vi = 'IDThiết bị, Từ giao dịch gần nhất, , , , ';
																																		|ru = 'ИД устройства, От последней операции, , , ,';
																																		|en = 'Device ID, From last transaction, , , ,'; fa = 'Device ID, From last transaction, , , ,';
																																		|it = 'ИД устройства, От последней операции, , , ,';
																																		|pl = 'Device ID, From last transaction, , , ,';
																																		|tr = 'ИД устройства, От последней операции, , , ,'"), ", , CardNumber, CardNumberHash, CardType, IsOwnCard", NStr("vi = ', , Số thẻ, Hash số thẻ, Kiểu thẻ, Thẻ riêng';
																																																														|ru = ', , Номер карты, Хеш номер карты, Тип карты, Своя карта';
																																																														|en = ', , Card number, Hash number of the card, Card type, Own card'; fa = ', , Card number, Hash number of the card, Card type, Own card';
																																																														|it = ', , Номер карты, Хеш номер карты, Тип карты, Своя карта';
																																																														|pl = ', , Card number, Hash number of the card, Card type, Own card';
																																																														|tr = ', , Kart numarası, Kart önbellek numarası, Kart türü, Kart türü, Kendi kartım'"));
	AddOperation(LoggingSystem, 4000, "GetCardParametrs", NStr("vi = 'Nhận tham số thẻ';
																|ru = 'Получить параметры карты';
																|en = 'Get card details'; fa = 'Get card details';
																|it = 'Получить параметры карты';
																|pl = 'Get card details';
																|tr = 'Kart parametrelerini al'"), "DeviceID, FromLastOperation, , , , , ", NStr("vi = 'IDThiết bị, Từ giao dịch gần nhất, , , , ';
																																		|ru = 'ИД устройства, От последней операции, , , , ,';
																																		|en = 'Device ID, From last transaction, , , , ,'; fa = 'Device ID, From last transaction, , , , ,';
																																		|it = 'ИД устройства, От последней операции, , , , ,';
																																		|pl = 'Device ID, From last transaction, , , , ,';
																																		|tr = 'ИД устройства, От последней операции, , , , ,'"), ", , CardNumber, CardNumberHash, PaymentAccountReference, CardType, IsOwnCard", NStr("vi = ', , , Số thẻ, Hash số thẻ, Tham chiếu đến tài khoản thanh toán, Kiểu thẻ, Thẻ riêng';
																																																																					|ru = ', , Номер карты, Хеш номер карты, Ссылка на платежный счет, Тип карты, Своя карта';
																																																																					|en = ', , Card number, Hash number of the card, Reference to the payment account, Card type, Own card'; fa = ', , Card number, Hash number of the card, Reference to the payment account, Card type, Own card';
																																																																					|it = ', , Номер карты, Хеш номер карты, Ссылка на платежный счет, Тип карты, Своя карта';
																																																																					|pl = ', , Card number, Hash number of the card, Reference to the payment account, Card type, Own card';
																																																																					|tr = ', , Kart numarası, Kart önbellek numarası, Ödeme hesabı referansı, Kart türü, Kendi kartım'"));

	AddOperation(LoggingSystem, 4000, "PayElectronicCertificate", NStr("vi = 'Thanh toán bằng phiếu quà tặng điện tử';
																		|ru = 'Оплатить электронным сертификатом';
																		|en = 'Pay with digital certificate'; fa = 'Pay with digital certificate';
																		|it = 'Оплатить электронным сертификатом';
																		|pl = 'Pay with digital certificate';
																		|tr = 'Elektronik sertifikayla öde'"), "DeviceID, MerchantNumber, BasketID, ElectronicCertificateAmount, OwnFundsAmount, , , , , , ", NStr("vi = 'IDThiết bị, Số người bán, ID giỏ hàng, Số tiền phiếu quà tặng điện tử, Số tiền phiếu quà tặng điện tử, Số tiền sở hữu riêng, , , , , , ';
																																																					|ru = 'ИД устройства, Номер мерчанта, Идентификатор корзины, Сумма электронного сертификата, Сумма собственных средств, , , , , ,';
																																																					|en = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, , , , , ,'; fa = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, , , , , ,';
																																																					|it = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, , , , , ,';
																																																					|pl = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, , , , , ,';
																																																					|tr = 'Cihaz ID''si, İş yeri numarası, Sepet tanımlayıcısı, E-sertifika tutarı, Özkaynak tutarı, , , , , ,'"), ", , BasketID, , , CardNumber, ReceiptNumber, RRNCode, AuthorizationCode, OperationStatus, Slip", NStr("vi = ', , ID giỏ hàng, , , Số thẻ, Số phiếu, Mã RRN, Mã đăng nhập, Trạng thái giao dịch, Nội dung biên lai';
																																																																																																								|ru = ', , Идентификатор корзины, , , Номер карты, Номер чека, Код RRN, Код авторизации, Статус операции, Текст квитанции';
																																																																																																								|en = ', , Cart ID, , , Card number, Receipt number, RRN Code, Authorization code, Transaction status, Receipt text'; fa = ', , Cart ID, , , Card number, Receipt number, RRN Code, Authorization code, Transaction status, Receipt text';
																																																																																																								|it = ', , Идентификатор корзины, , , Номер карты, Номер чека, Код RRN, Код авторизации, Статус операции, Текст квитанции';
																																																																																																								|pl = ', , Cart ID, , , Card number, Receipt number, RRN Code, Authorization code, Transaction status, Receipt text';
																																																																																																								|tr = ', , Sepet tanımlayıcısı, , , Kart numarası, Çek numarası, RRN kodu, Doğrulama kodu, İşlem durumu, Makbuz metni'"));
	AddOperation(LoggingSystem, 0, "PayElectronicCertificate", NStr("vi = 'Thanh toán bằng phiếu quà tặng điện tử';
																	|ru = 'Оплатить электронным сертификатом';
																	|en = 'Pay with digital certificate'; fa = 'Pay with digital certificate';
																	|it = 'Оплатить электронным сертификатом';
																	|pl = 'Pay with digital certificate';
																	|tr = 'Elektronik sertifikayla öde'"), "DeviceID, MerchantNumber, BasketID, ElectronicCertificateAmount, OwnFundsAmount, , , , , , ", NStr("vi = 'IDThiết bị, Số người bán, ID giỏ hàng, Số tiền phiếu quà tặng điện tử, Số tiền phiếu quà tặng điện tử, Số tiền sở hữu riêng, , , , , , ';
																																																				|ru = 'ИД устройства, Номер мерчанта, Идентификатор корзины, Сумма электронного сертификата, Сумма собственных средств, , , , , ,';
																																																				|en = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, , , , , ,'; fa = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, , , , , ,';
																																																				|it = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, , , , , ,';
																																																				|pl = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, , , , , ,';
																																																				|tr = 'Cihaz ID''si, İş yeri numarası, Sepet tanımlayıcısı, E-sertifika tutarı, Özkaynak tutarı, , , , , ,'"), ", , BasketID, , , CardNumber, ReceiptNumber, RRNCode, AuthorizationCode, OperationStatus, Slip", NStr("vi = ', , ID giỏ hàng, , , Số thẻ, Số phiếu, Mã RRN, Mã đăng nhập, Trạng thái giao dịch, Nội dung biên lai';
																																																																																																								|ru = ', , Идентификатор корзины, , , Номер карты, Номер чека, Код RRN, Код авторизации, Статус операции, Текст квитанции';
																																																																																																								|en = ', , Cart ID, , , Card number, Receipt number, RRN Code, Authorization code, Transaction status, Receipt text'; fa = ', , Cart ID, , , Card number, Receipt number, RRN Code, Authorization code, Transaction status, Receipt text';
																																																																																																								|it = ', , Идентификатор корзины, , , Номер карты, Номер чека, Код RRN, Код авторизации, Статус операции, Текст квитанции';
																																																																																																								|pl = ', , Cart ID, , , Card number, Receipt number, RRN Code, Authorization code, Transaction status, Receipt text';
																																																																																																								|tr = ', , Sepet tanımlayıcısı, , , Kart numarası, Çek numarası, RRN kodu, Doğrulama kodu, İşlem durumu, Makbuz metni'"));
	
	AddOperation(LoggingSystem, 4000, "ReturnElectronicCertificate", NStr("vi = 'Trả lại bằng phiếu quà tặng điện tử';
																			|ru = 'Вернуть электронным сертификатом';
																			|en = 'Return by digital certificate'; fa = 'Return by digital certificate';
																			|it = 'Вернуть электронным сертификатом';
																			|pl = 'Return by digital certificate';
																			|tr = 'E-sertifikaya dön'"), "DeviceID, MerchantNumber, BasketID, ElectronicCertificateAmount, OwnFundsAmount, CardNumber, ReceiptNumber, RRNCode, , , ", NStr("vi = 'IDThiết bị, Số người bán, ID giỏ hàng, Số tiền phiếu quà tặng điện tử, Số tiền phiếu quà tặng điện tử, Số tiền sở hữu riêng, Số thẻ, Số phiếu, Mã RRN, , , ';
																																																													|ru = 'ИД устройства, Номер мерчанта, Идентификатор корзины, Сумма электронного сертификата, Сумма собственных средств, Номер карты, Номер чека, Код RRN, , ,';
																																																													|en = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, Card number, Receipt number, RRN code, , ,'; fa = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, Card number, Receipt number, RRN code, , ,';
																																																													|it = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, Card number, Receipt number, RRN code, , ,';
																																																													|pl = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, Card number, Receipt number, RRN code, , ,';
																																																													|tr = 'Cihaz ID''si, İş yeri numarası, Sepet tanımlayıcısı, E-sertifika tutarı, Öz kaynak tutarı, Kart numarası, Çek numarası, RRN kodu, , ,'"), ", , BasketID, , , CardNumber, ReceiptNumber, RRNCode, AuthorizationCode, OperationStatus, Slip", NStr("vi = ', , ID giỏ hàng, , , Số thẻ, Số phiếu, Mã RRN, Mã đăng nhập, Trạng thái giao dịch, Nội dung biên lai';
																																																																																																																									|ru = ', , Идентификатор корзины, , , Номер карты, Номер чека, Код RRN, Код авторизации, Статус операции, Текст квитанции';
																																																																																																																									|en = ', , Cart ID, , , Card number, Receipt number, RRN Code, Authorization code, Transaction status, Receipt text'; fa = ', , Cart ID, , , Card number, Receipt number, RRN Code, Authorization code, Transaction status, Receipt text';
																																																																																																																									|it = ', , Идентификатор корзины, , , Номер карты, Номер чека, Код RRN, Код авторизации, Статус операции, Текст квитанции';
																																																																																																																									|pl = ', , Cart ID, , , Card number, Receipt number, RRN Code, Authorization code, Transaction status, Receipt text';
																																																																																																																									|tr = ', , Sepet tanımlayıcısı, , , Kart numarası, Çek numarası, RRN kodu, Doğrulama kodu, İşlem durumu, Makbuz metni'"));
	AddOperation(LoggingSystem, 0, "ReturnElectronicCertificate", NStr("vi = 'Trả lại bằng phiếu quà tặng điện tử';
																		|ru = 'Вернуть электронным сертификатом';
																		|en = 'Return by digital certificate'; fa = 'Return by digital certificate';
																		|it = 'Вернуть электронным сертификатом';
																		|pl = 'Return by digital certificate';
																		|tr = 'E-sertifikaya dön'"), "DeviceID, MerchantNumber, BasketID, ElectronicCertificateAmount, OwnFundsAmount, CardNumber, ReceiptNumber, RRNCode, , , ", NStr("vi = 'IDThiết bị, Số người bán, ID giỏ hàng, Số tiền phiếu quà tặng điện tử, Số tiền phiếu quà tặng điện tử, Số tiền sở hữu riêng, Số thẻ, Số phiếu, Mã RRN, , , ';
																																																													|ru = 'ИД устройства, Номер мерчанта, Идентификатор корзины, Сумма электронного сертификата, Сумма собственных средств, Номер карты, Номер чека, Код RRN, , ,';
																																																													|en = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, Card number, Receipt number, RRN code, , ,'; fa = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, Card number, Receipt number, RRN code, , ,';
																																																													|it = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, Card number, Receipt number, RRN code, , ,';
																																																													|pl = 'Device ID, Merchant number, Cart ID, Digital certificate amount, Own fund amount, Card number, Receipt number, RRN code, , ,';
																																																													|tr = 'Cihaz ID''si, İş yeri numarası, Sepet tanımlayıcısı, E-sertifika tutarı, Öz kaynak tutarı, Kart numarası, Çek numarası, RRN kodu, , ,'"), ", , BasketID, , , CardNumber, ReceiptNumber, RRNCode, AuthorizationCode, OperationStatus, Slip", NStr("vi = ', , ID giỏ hàng, , , Số thẻ, Số phiếu, Mã RRN, Mã đăng nhập, Trạng thái giao dịch, Nội dung biên lai';
																																																																																																																								|ru = ', , Идентификатор корзины, , , Номер карты, Номер чека, Код RRN, Код авторизации, Статус операции, Текст квитанции';
																																																																																																																								|en = ', , Cart ID, , , Card number, Receipt number, RRN Code, Authorization code, Transaction status, Receipt text'; fa = ', , Cart ID, , , Card number, Receipt number, RRN Code, Authorization code, Transaction status, Receipt text';
																																																																																																																								|it = ', , Идентификатор корзины, , , Номер карты, Номер чека, Код RRN, Код авторизации, Статус операции, Текст квитанции';
																																																																																																																								|pl = ', , Cart ID, , , Card number, Receipt number, RRN Code, Authorization code, Transaction status, Receipt text';
																																																																																																																								|tr = ', , Sepet tanımlayıcısı, , , Kart numarası, Çek numarası, RRN kodu, Doğrulama kodu, İşlem durumu, Makbuz metni'"));
	
	// 3.10. Requirements for the development of drivers for RFID readers
	AddOperation(LoggingSystem, 0, "OpenSessionRFID", NStr("vi = 'Mở phiên RFID';
															|ru = 'Открыть сессию RFID';
															|en = 'Open the RFID session'; fa = 'Open the RFID session';
															|it = 'Открыть сессию RFID';
															|pl = 'Open the RFID session';
															|tr = 'RFID oturumu aç'"), "DeviceID", NStr("vi = 'ID thiết bị';
																											|ru = 'ИД устройства';
																											|en = 'Device ID'; fa = 'شناسه دستگاه';
																											|it = 'ИД устройства';
																											|pl = 'Device ID';
																											|tr = 'ИД устройства'"), "", "");
	AddOperation(LoggingSystem, 0, "CloseSessionRFID", NStr("vi = 'Đóng phiên RFID';
															|ru = 'Закрыть сессию RFID';
															|en = 'Close the RFID session'; fa = 'Close the RFID session';
															|it = 'Закрыть сессию RFID';
															|pl = 'Close the RFID session';
															|tr = 'RFID oturumunu kapat'"), "DeviceID", NStr("vi = 'ID thiết bị';
																												|ru = 'ИД устройства';
																												|en = 'Device ID'; fa = 'شناسه دستگاه';
																												|it = 'ИД устройства';
																												|pl = 'Device ID';
																												|tr = 'ИД устройства'"), "", "");
	AddOperation(LoggingSystem, 0, "GetDataTagsRFID", NStr("vi = 'Nhận dữ liệu đánh dấu RFID';
															|ru = 'Получить данные меток RFID';
															|en = 'Receive RFID label data'; fa = 'Receive RFID label data';
															|it = 'Получить данные меток RFID';
															|pl = 'Receive RFID label data';
															|tr = 'RFID etiket verilerini al'"), "DeviceID, PackageID, ", NStr("vi = 'ID thiết bị, ID gói';
																															|ru = 'ИД устройства, ИД пакета,';
																															|en = 'Device ID, Package ID,'; fa = 'Device ID, Package ID,';
																															|it = 'ИД устройства, ИД пакета,';
																															|pl = 'Device ID, Package ID,';
																															|tr = 'ИД устройства, ИД пакета,'"), ", , TagsTable", NStr("vi = ', , Bảng đánh dấu';
																																													|ru = ', , Таблица меток';
																																													|en = ', , Label table'; fa = ', , Label table';
																																													|it = ', , Таблица меток';
																																													|pl = ', , Label table';
																																													|tr = ', , İşaret tabloları'"));
	AddOperation(LoggingSystem, 0, "SaveDataTagRFID", NStr("vi = 'Ghi lại dữ liệu vào đánh dấu RFID';
															|ru = 'Записать данные в метку RFID';
															|en = 'Record the data to the RFID tag'; fa = 'Record the data to the RFID tag';
															|it = 'Записать данные в метку RFID';
															|pl = 'Record the data to the RFID tag';
															|tr = 'Записать данные в метку RFID'"), "DeviceID, TID, EPC, Data, MemoryBank, Timeout", NStr("vi = 'ID Thiết bị, TID, EPC, Dữ liệu, Ngân hàng bộ nhớ, Hết giờ';
																																							|ru = 'ИД устройства, TID, EPC, Данные, Банк памяти, Таймаут';
																																							|en = 'Device ID, TID, EPC, Data, Memory bank, Timeout'; fa = 'Device ID, TID, EPC, Data, Memory bank, Timeout';
																																							|it = 'ИД устройства, TID, EPC, Данные, Банк памяти, Таймаут';
																																							|pl = 'Device ID, TID, EPC, Data, Memory bank, Timeout';
																																							|tr = 'ИД устройства, TID, EPC, Данные, Банк памяти, Таймаут'"), ", TID, EPC, , , ", NStr("vi = ', TID, EPC, , ,';
																																																												|ru = ', TID, EPC, , ,';
																																																												|en = ', TID, EPC, , ,'; fa = ', TID, EPC, , ,';
																																																												|it = ', TID, EPC, , ,';
																																																												|pl = ', TID, EPC, , ,';
																																																												|tr = ', TID, EPC, , ,'"));
	
	// 3.11. Requirements for the development of recognition devices
	AddOperation(LoggingSystem, 0, "Recognize", NStr("vi = 'Nhận dạng';
													|ru = 'Распознать';
													|en = 'Recognize'; fa = 'شناسایی';
													|it = 'Распознать';
													|pl = 'Recognize';
													|tr = 'Tanı'"), "DeviceID, Training, Variants, ", NStr("vi = 'ID thiết bị, Đào tạo, Phương án,';
																												|ru = 'ИД устройства, Обучение, Варианты,';
																												|en = 'Device ID, Training, Options,'; fa = 'Device ID, Training, Options,';
																												|it = 'ИД устройства, Обучение, Варианты,';
																												|pl = 'Device ID, Training, Options,';
																												|tr = 'ИД устройства, Обучение, Варианты,'"), ", , , GoodsRecognizeTable", NStr("vi = ', , , Bảng hàng hóa được nhận dạng';
																																															|ru = ', , , Таблица распознанных товаров';
																																															|en = ', , , Table of identified goods'; fa = ', , , Table of identified goods';
																																															|it = ', , , Таблица распознанных товаров';
																																															|pl = ', , , Table of identified goods';
																																															|tr = ', , , Tanınmış ürünler tablosu'"));
	AddOperation(LoggingSystem, 0, "ConfirmRecognize", NStr("vi = 'Xác nhận việc nhận dạng';
															|ru = 'Подтвердить распознавание';
															|en = 'Confirm recognition'; fa = 'Confirm recognition';
															|it = 'Подтвердить распознавание';
															|pl = 'Confirm recognition';
															|tr = 'Tanımayı onayla'"), "DeviceID, Code", NStr("vi = 'ID thiết bị, Mã';
																													|ru = 'ИД устройства, Код';
																													|en = 'Device ID, Code'; fa = 'Device ID, Code';
																													|it = 'ИД устройства, Код';
																													|pl = 'Device ID, Code';
																													|tr = 'ИД устройства, Код'"), "", "");
	
EndProcedure

#EndRegion
