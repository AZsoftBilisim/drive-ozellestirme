///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns the name of the shared attribute that separates the master data.
//
// Returns:
//   String - the name of the shared prop that is the separator of the master data.
//
Function MainDataSeparator() Export
	
	Return Metadata.CommonAttributes.DataAreaMainData.Name;
	
EndFunction

// Returns the name of the shared attribute that is the auxiliary data separator.
//
// Returns:
//   String - the name of the shared prop that is the auxiliary data separator.
//
Function AuxiliaryDataSeparator() Export
	
	Return Metadata.CommonAttributes.DataAreaAuxiliaryData.Name;
	
EndFunction

// Returns a flag for working in the data division mode by area
// (technically, this is a sign of conditional division).
// 
// Returns False if the configuration can't work in data separation mode
// (it doesn't contain General details intended for data separation).
//
// Returns:
//  Boolean - True if separation is enabled.
//  Boolean - False if partitioning is disabled or not supported.
//
Function DataSeparationEnabled() Export
	
	Return SaaSOperationsCached.DataSeparationEnabled();
	
EndFunction

// Returns whether split data (which is part of separators) can be accessed.
// This attribute is specific to the session, but may change during the session if partitioning was enabled
// in the session itself, so you should check it immediately before accessing the split data.
// 
// Returns True if the configuration can't work in data separation mode
// (it doesn't contain any General details intended for data separation).
//
// Returns:
//   Boolean - True, if separation is not supported, either separation is disabled,
//                    or separation is enabled and separators are set.
//   Boolean is false if separation is enabled and separators are not set.
//
Function SeparatedDataUsageAvailable() Export
	
	If Not DataSeparationEnabled() Then
		Return True;
	EndIf;
	
	Return SessionSeparatorUsage();
	
EndFunction

// Clears all session parameters except those related to the shared 
// data area.
//
Procedure ClearAllSessionParametersExceptDelimiters() Export
	
	Common.ClearSessionParameters(, "DataAreaValue,DataAreaUsage");
	
EndProcedure

// Checks if the data area is locked.
//
// Parameters:
//  DataArea -  Number - the value of the data area separator 
//   that you want to check for blocking.
//
// Returns:
//  Boolean - if True, the data area is locked, otherwise not.
//
Function DataAreaLocked(Val DataArea) Export
	
	Var_Key = CreateAuxiliaryDataInformationRegisterEntryKey(
	    InformationRegisters.DataAreas,
	    New Structure(AuxiliaryDataSeparator(), DataArea));
	
	Try
		
		LockDataForEdit(Var_Key);
		
	Except
		
		Return True;
		
	EndTry;
	
	UnlockDataForEdit(Var_Key);
	
	If Not SeparatedDataUsageAvailable() Then
		
		Try
			
			SignInToDataArea(DataArea);
			
		Except
			
			SignOutOfDataArea();
			Return True;
			
		EndTry;
		
		SignOutOfDataArea();
		
	EndIf;
	
	Return False;
	
EndFunction

// Prepares the data area for use. Starts the information security update procedure
// , fills in demo data if necessary, and sets a new status in the data Domain register.
// 
// Parameters: 
//   DataArea - Number - the value of the separator for the data area to prepare for use.
//   UploadFileID - UUID - file identifier.
//   Variant - String - a variant of the initial data.
// 
Procedure PrepareDataAreaForUse(Val DataArea, Val UploadFileID, 
												 Val Variant = Undefined) Export
	
	If Not Users.IsFullUser(, True) Then
		Raise(NStr("vi = 'Không đủ quyền để thực hiện thao tác';
					|ru = 'Недостаточно прав для выполнения операции';
					|en = 'Insufficient rights to perform the operation.'; fa = 'Insufficient rights to perform the operation.';
					|it = 'Diritti insufficienti per eseguire l''operazione';
					|pl = 'Niewystarczające uprawnienia do wykonania operacji';
					|tr = 'İşlem için gerekli yetkiler yok'"));
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	AreaKey = CreateAuxiliaryDataInformationRegisterEntryKey(
		InformationRegisters.DataAreas,
		New Structure(AuxiliaryDataSeparator(), DataArea));
	LockDataForEdit(AreaKey);
	
	Try
		RecordManager = GetDataAreaRecordManager(DataArea, Enums.DataAreaStatuses.IsNew);
		
		If CurrentRunMode() <> Undefined Then
			
			UsersInternal.AuthenticateCurrentUser();
			
		EndIf;
		
		ErrorMessage = "";
		If Not ValueIsFilled(Variant) Then
			
			ResultOfPreparation = PrepareDataAreaForUseFromUpload(DataArea, UploadFileID, 
				ErrorMessage);
			
		Else
			
			ResultOfPreparation = PrepareDataAreaForUseFromReference(DataArea, UploadFileID, 
				Variant, ErrorMessage);
				
		EndIf;
		
		ChangeAreaStatusAndNotifyManager(RecordManager, ResultOfPreparation, ErrorMessage);

	Except
		UnlockDataForEdit(AreaKey);
		Raise;
	EndTry;
	
	UnlockDataForEdit(AreaKey);

EndProcedure

// Copies data from the data area to another data area.
// 
// Parameters: 
//   SourceArea_1 - Number - value of the data source data area separator.
//   ReceivingArea - Number - the delimiter value of the data area of the data receiver.
// 
Procedure CopyAreaData(Val SourceArea_1, Val ReceivingArea) Export
	
	If Not Users.IsFullUser(, True) Then
		Raise(NStr("vi = 'Không đủ quyền để thực hiện thao tác';
					|ru = 'Недостаточно прав для выполнения операции';
					|en = 'Insufficient rights to perform the operation.'; fa = 'Insufficient rights to perform the operation.';
					|it = 'Diritti insufficienti per eseguire l''operazione';
					|pl = 'Niewystarczające uprawnienia do wykonania operacji';
					|tr = 'İşlem için gerekli yetkiler yok'"));
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	SignInToDataArea(SourceArea_1);
	
	UploadFileName = Undefined;
	
	If Not Common.SubsystemExists("CloudTechnology.ExportImportDataAreas") Then
		
		CauseExceptionMissingSubsystemCTL("CloudTechnology.ExportImportDataAreas");
		
	EndIf;
	
	Try
		UploadFileName = ExportImportDataAreas.UploadCurAreaToArchive().FileName;
	Except
		WriteLogEvent(LogEventCopyingDataArea(), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		If UploadFileName <> Undefined Then
			Try
				DeleteFiles(UploadFileName);
			Except
				WriteLogEvent(LogEventCopyingDataArea(), 
					EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndTry;
		EndIf;
		Raise;
	EndTry;
	
	SignOutOfDataArea();
	SignInToDataArea(ReceivingArea);
	
	Try
		ExportImportDataAreas.LoadAreaFromArchive(UploadFileName);
	Except
		WriteLogEvent(LogEventCopyingDataArea(), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Try
			DeleteFiles(UploadFileName);
		Except
			WriteLogEvent(LogEventCopyingDataArea(), 
				EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		Raise;
	EndTry;
	
	Try
		DeleteFiles(UploadFileName);
	Except
		WriteLogEvent(LogEventCopyingDataArea(), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

// Procedure for a routine task of the same name.
// Finds all data areas with statuses that require processing
// by the application, and if necessary, plans to run the Federal
// law on their maintenance.
// 
Procedure DataAreaMaintenance() Export
	
	If Not DataSeparationEnabled() Then
		Return;
	EndIf;
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DataAreaMaintenance);
	
	MaximumNumberOfRepetitions = 3;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	InformationRegisters.ExportImportDataThreads.CheckOperationOfRunningThreads();
	InformationRegisters.DataOfClearedArea.RecoverInformationAboutDeletedAreas();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DataAreas.DataAreaAuxiliaryData AS DataArea,
	|	DataAreas.Status AS Status,
	|	DataAreas.DataExportedID AS DataExportedID,
	|	DataAreas.Variant AS Variant
	|FROM
	|	InformationRegister.DataAreas AS DataAreas
	|WHERE
	|	DataAreas.Status IN (VALUE(Enum.DataAreaStatuses.IsNew), VALUE(Enum.DataAreaStatuses.ForDeletion))
	|	AND DataAreas.ProcessingError = FALSE
	|
	|ORDER BY
	|	DataArea";
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		Var_Key = CreateAuxiliaryDataInformationRegisterEntryKey(
			InformationRegisters.DataAreas,
			New Structure(AuxiliaryDataSeparator(), Selection.DataArea));
		
		Try
			LockDataForEdit(Var_Key);
		Except
			Continue;
		EndTry;
		
		Manager = InformationRegisters.DataAreas.CreateRecordManager();
		Manager.DataAreaAuxiliaryData = Selection.DataArea;
		Manager.Read();
		
		IsAreaClearing = Manager.Status = Enums.DataAreaStatuses.ForDeletion;
		
		If IsAreaClearing Then 
			MethodName = ClearDataAreaMethodName();
		ElsIf Manager.Status = Enums.DataAreaStatuses.IsNew Then
			MethodName = MethodNamePrepareDataAreaForUse();
		Else
			UnlockDataForEdit(Var_Key);
			Continue;
		EndIf;
		
		If Manager.Repeat < MaximumNumberOfRepetitions Then
		
			FilterJobs = New Structure;
			FilterJobs.Insert("MethodName", MethodName);
			FilterJobs.Insert("Key"     , "1");
			FilterJobs.Insert("DataArea", Selection.DataArea);
			
			Jobs = JobsQueue.GetJobs(FilterJobs);
			
			If Jobs.Count() > 0 Then
				UnlockDataForEdit(Var_Key);
				Continue;
			EndIf;
			
			Manager.Repeat = Manager.Repeat + 1;
			
			ManagerSCopy = InformationRegisters.DataAreas.CreateRecordManager();
			FillPropertyValues(ManagerSCopy, Manager);
			Manager = ManagerSCopy;
			
			Manager.Write();
			
			If IsAreaClearing Then
				
				CreateTaskToClearDataArea(Selection.DataArea);
				
			Else

				MethodParameters = New Array;
				MethodParameters.Add(Selection.DataArea);
				MethodParameters.Add(Selection.DataExportedID);
				
				If ValueIsFilled(Selection.Variant) Then
					MethodParameters.Add(Selection.Variant);
				EndIf;
				
				JobParameters = New Structure;
				JobParameters.Insert("MethodName", MethodName);
				JobParameters.Insert("Parameters", MethodParameters);
				JobParameters.Insert("Key", "1");
				JobParameters.Insert("DataArea", Selection.DataArea);
				JobParameters.Insert("ExclusiveExecution", True);
							
				JobsQueue.AddJob(JobParameters);
				
			EndIf;
			
			UnlockDataForEdit(Var_Key);
			
		Else
			
			ChangeAreaStatusAndNotifyManager(Manager, ?(Manager.Status = Enums.DataAreaStatuses.IsNew,
				"FatalError", "DeletionError"), NStr("vi = 'Đã dùng hết số lần thử xử lý vùng';
													|ru = 'Исчерпано количество попыток обработки области';
													|en = 'Number of attempts to process the area is up'; fa = 'Number of attempts to process the area is up';
													|it = 'Il numero di tentativi di elaborazione dell''area è stato esaurito';
													|pl = 'Ilość prób przetworzenia obszaru została wyczerpana';
													|tr = 'Alanı işlemek için deneme sayısı limitine ulaşıldı.'"));
			
			UnlockDataForEdit(Var_Key);
			
		EndIf;
		
	EndDo;
	
	ExtensionsSaaS.ScheduleExtensionUpdatesInAreas();
	
EndProcedure

// Returns the web service proxy for synchronizing administrative actions in the service.
// The calling code must independently set the privileged mode.
// 
// Parameters:
//  UserPassword - String - password for connection.
// 
// Returns: 
//   WSProxy - proxy of the service manager. 
// 
Function GetProxyServiceManager(Val UserPassword = Undefined) Export
	
	AuthorizationParameters = RemoteAdministrationCTLInternal.AuthorizationParametersForManagingApplication(UserPassword);
	MaxVersion = RemoteAdministrationCTLInternal.VersionOfManagementApplicationServiceUsed(AuthorizationParameters);
	If CommonClientServer.CompareVersions(MaxVersion, "1.0.3.1") < 0 Then
		Raise NStr("vi = 'Không hỗ trợ phiên bản cần thiết của ứng dụng được quản lý.';
					|ru = 'Требуемая версия управляющего приложения не поддерживается.';
					|en = 'The required version of the managing application is not supported.'; fa = 'The required version of the managing application is not supported.';
					|it = 'Versione richiesta dell''applicazione gestionale non supportata.';
					|pl = 'Wymagana jest wersja aplikacji zarządzającej nie jest obsługiwa.';
					|tr = 'Yönetilen uygulaması gerekli sürümü desteklenmiyor.'");
	ElsIf CommonClientServer.CompareVersions(MaxVersion, "1.0.3.5") < 0 Then
		Return RemoteAdministrationCTLInternal.ProxyServiceOfManagingApplication(AuthorizationParameters, "1.0.3.1");
	EndIf;

	Return RemoteAdministrationCTLInternal.ProxyServiceOfManagingApplication(AuthorizationParameters);
	
EndFunction

// Deprecated. Depending on the need, one of the following procedures should be used:
// See SaaSOperations.SignInToDataArea 
// See SaaSOperations.SignOutOfDataArea
//
// Parameters:
//  Use - Boolean - using the data Area separator in a session.
//  DataArea - Number - value of the data Area separator.
//
Procedure SetSessionSeparation(Val Use = Undefined, Val DataArea = Undefined) Export
	
	If Not SessionWithoutSeparators() Then
		Raise(NStr("vi = 'Có thể thay đổi phân chia phiên làm việc chỉ từ phiên làm việc đã khởi động mà không chỉ ra đường chia tách';
					|ru = 'Изменить разделение сеанса возможно только из сеанса запущенного без указания разделителей';
					|en = 'Changing separation settings is only allowed from sessions started without separation'; fa = 'Changing separation settings is only allowed from sessions started without separation';
					|it = 'È possibile modificare la separazione della sessione soltanto dalla sessione avviata senza specifica dei separatori';
					|pl = 'Zmiana rozdziału sesji jest możliwa wyłącznie z sesji rozpoczętej bez określania ograniczników';
					|tr = 'Yalnızca sınırlayıcıları belirtmeden çalışan bir oturumdan bir oturum ayırmayı değiştir'"));
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If DataArea <> Undefined Then
		If SessionParameters.DataAreaUsage Then
			// When the use is enabled, you need to exit the area 
			// so that if you enter the area unsuccessfully, an error in the LR is recorded in an undivided session.
			SessionParameters.DataAreaUsage = False;
			OnChangeDataArea();
			SessionParameters.DataAreaValue = DataArea;
			SessionParameters.DataAreaUsage = True;
		Else
			SessionParameters.DataAreaValue = DataArea;
		EndIf;
	EndIf;
	
	If Use <> Undefined Then
		SessionParameters.DataAreaUsage = Use;
	EndIf;
	
	OnChangeDataArea();
	
EndProcedure

// Logs in to the data area. You can only enter the area from an undivided session.
// 
// Parameters:
// 	DataArea - Number - 
Procedure SignInToDataArea(Val DataArea) Export
	
	If Not SessionWithoutSeparators() Then
		Raise(NStr("vi = 'Có thể thay đổi phân chia phiên làm việc chỉ từ phiên làm việc đã khởi động mà không chỉ ra đường chia tách';
					|ru = 'Изменить разделение сеанса возможно только из сеанса запущенного без указания разделителей';
					|en = 'Changing separation settings is only allowed from sessions started without separation'; fa = 'Changing separation settings is only allowed from sessions started without separation';
					|it = 'È possibile modificare la separazione della sessione soltanto dalla sessione avviata senza specifica dei separatori';
					|pl = 'Zmiana rozdziału sesji jest możliwa wyłącznie z sesji rozpoczętej bez określania ograniczników';
					|tr = 'Yalnızca sınırlayıcıları belirtmeden çalışan bir oturumdan bir oturum ayırmayı değiştir'"));
	EndIf;
	
	If DataArea <= 0 Then
		Raise(NStr("vi = 'Số vùng phải lớn hơn 0';
					|ru = 'Номер области должен быть больше 0';
					|en = 'Area number must be greater than 0'; fa = 'Area number must be greater than 0';
					|it = 'Il numero dell''area deve essere superiore a 0';
					|pl = 'Numer obszaru powinien być większy niż 0';
					|tr = 'Alan numarası 0''dan büyük olmak zorunda'"));
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If SessionParameters.DataAreaUsage Then
		Raise NStr("vi = 'Trước khi nhập vùng dữ liệu mới, cần thoát khỏi vùng dữ liệu trước đó';
					|ru = 'Перед входом в новую область данных, нужно выйти из предыдущей';
					|en = 'Before logging in to a new data area, log out of the previous one'; fa = 'Before logging in to a new data area, log out of the previous one';
					|it = 'Prima di entrare in una nuova area dati è necessario uscire da quella precedente';
					|pl = 'Przed wejściem do nowego obszaru danach, należy wyjść z poprzedniego';
					|tr = 'Yeni alana girmeden önce bir öncekiden çıkmak gerekiyor'");
	EndIf;
	
	SessionParameters.DataAreaValue = DataArea;
	SessionParameters.DataAreaUsage = True;
	
	OnChangeDataArea();
	
EndProcedure

// Exits the data area.
//
Procedure SignOutOfDataArea() Export
	
	If Not SessionWithoutSeparators() Then
		Raise(NStr("vi = 'Có thể thay đổi phân chia phiên làm việc chỉ từ phiên làm việc đã khởi động mà không chỉ ra đường chia tách';
					|ru = 'Изменить разделение сеанса возможно только из сеанса запущенного без указания разделителей';
					|en = 'Changing separation settings is only allowed from sessions started without separation'; fa = 'Changing separation settings is only allowed from sessions started without separation';
					|it = 'È possibile modificare la separazione della sessione soltanto dalla sessione avviata senza specifica dei separatori';
					|pl = 'Zmiana rozdziału sesji jest możliwa wyłącznie z sesji rozpoczętej bez określania ograniczników';
					|tr = 'Yalnızca sınırlayıcıları belirtmeden çalışan bir oturumdan bir oturum ayırmayı değiştir'"));
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	SessionParameters.DataAreaUsage = False;
	SessionParameters.DataAreaValue = 0;
	
	OnChangeDataArea();
	
EndProcedure

// Returns the value of the current data area separator.
// If the value is not set, an error is returned.
// 
// Returns: 
//   Number - the value of the separator of the current data area. 
// 
Function SessionSeparatorValue() Export
	
	If Not DataSeparationEnabled() Then
		Return 0;
	Else
		If Not SessionSeparatorUsage() Then
			Raise(NStr("vi = 'Chưa đặt giá trị đường chia tách';
						|ru = 'Не установлено значение разделителя';
						|en = 'The separator value is not specified.'; fa = 'The separator value is not specified.';
						|it = 'Valore del separatore non impostato';
						|pl = 'Nie ustawiono wartości separatora';
						|tr = 'Ayırıcı değeri ayarlanmadı'"));
		EndIf;
		
		// Get the value of the separator of the current data area.
		Return SessionParameters.DataAreaValue;
	EndIf;
	
EndFunction

// Returns the subscriber code of the current data area.
//
// Returns:
//   Number - subscriber code
Function SubscriberCode() Export
	
	If Not DataSeparationEnabled()
		Or Not SeparatedDataUsageAvailable() Then
		Return 0;
	EndIf;
	
	RecordManager = InformationRegisters.DataAreas.CreateRecordManager();
	RecordManager.DataAreaAuxiliaryData = SessionSeparatorValue();
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	RecordManager.Read();
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	If RecordManager.Selected() Then
		Result = RecordManager.SubscriberCode;
	Else
		Result = 0;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the flag for using the data Area separator for the current session.
//
// Returns: 
//  Boolean - if True, separation is used, otherwise not.
//
Function SessionSeparatorUsage() Export
	
	Return SessionParameters.DataAreaUsage;
	
EndFunction

// Adds a parameter description by constant name to the parameter table.
// Returns the added parameter.
//
// Parameters: 
//   ParametersTable - See IBParameters
//   ConstantName - String - name of the constant to add to the is parameters.
//
// Returns: 
//   ValueTableRow - description of the added parameter:
//    * Name - String
//    * LongDesc - String
//    * Type - TypeDescription
// 
Function AddConstantToInformationSecurityParameterTable(Val ParametersTable, Val ConstantName) Export
	
	MetadataConstants = Metadata.Constants[ConstantName]; // MetadataObjectConstant
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = MetadataConstants.Name;
	ParameterString.LongDesc = MetadataConstants.Presentation();
	ParameterString.Type = MetadataConstants.Type;
	
	Return ParameterString;
	
EndFunction

// Gets the name of the app - the way the subscriber set it.
//
// Returns:
//   String - the name of the application.
//
Function GetAppName() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Return Constants.DataAreaPresentation.Get();
	
EndFunction

// Returns the block size in MB for transferring large files in parts.
//
// Returns:
//   Number - file transfer block size in megabytes.
//
Function GetFileTransferBlockSize() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	FileTransferBlockSize = Constants.FileTransferBlockSize.Get(); // mb
	If Not ValueIsFilled(FileTransferBlockSize) Then
		FileTransferBlockSize = 20;
	EndIf;
	Return FileTransferBlockSize;

EndFunction

// Serializes an object of the structural type.
//
// Parameters:
//   MeaningOfStructuralType - Array, Structure, Map - a serializable object.
//
// Returns:
//   String - the serialized value of a structural type object.
//
Function WriteStructureObjectXDTOToString(Val MeaningOfStructuralType) Export
	
	XDTODataObject = StructuralObjectToXDTOObject(MeaningOfStructuralType);
	
	Return WriteValueToString(XDTODataObject);
	
EndFunction

// Encodes a string value using the base64 algorithm.
//
// Parameters:
//   String - String - the source string to encode.
//
// Returns:
//   String - encoded string.
//
Function LineInBase64(Val String) Export
	
	Storage = New ValueStorage(String, New Deflation(9));
	
	Return XMLString(Storage);
	
EndFunction

// Decodes the base64 representation of a string to its original value.
//
// Parameters:
//   Base64Row - String - the source string to be decoded.
//
// Returns:
//   String - decoded string.
//
Function Base64BString(Val Base64Row) Export
	
	Storage = XMLValue(Type("ValueStorage"), Base64Row);
	
	Return Storage.Get();
	
EndFunction

// Returns the time zone of the data area.
// It is intended for calling from sessions with unspecified use
// of delimiters. In sessions with the use of separators
// set, you should use gethourinformation database().
//
// Parameters:
//  DataArea - Number - the value of the data area separator
//   that you want to get the time zone for.
//
// Returns:
//  String, Undefined - the time zone of the data area is undefined
//   if the time zone is not specified.
//
Function GetTimeZoneOfDataArea(Val DataArea) Export
	
	Manager = Constants.DataAreaTimeZone.CreateValueManager();
	Manager.DataAreaAuxiliaryData = DataArea;
	Manager.Read();
	TimeZone = Manager.Value;
	
	If Not ValueIsFilled(TimeZone) Then
		TimeZone = Undefined;
	EndIf;
	
	Return TimeZone;
	
EndFunction

// Returns an indication of whether there is a service manager endpoint setup
//
// Returns:
//  Boolean - True if the endpoint of the service manager is installed and the user name is filled in in the transport settings.
//
Function ServiceManagerEndpointConfigured() Export
	
	Result = False;
	
	Endpoint = ServiceManagerEndpoint();
	If ValueIsFilled(Endpoint) Then
		SettingsStructure = InformationRegisters.MessageExchangeTransportSettings.TransportSettingsWS(Endpoint);
		
		Result = ValueIsFilled(SettingsStructure.WSUserName)
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the internal address of the service Manager.
//
// Returns:
//  String - internal address of the service Manager.
//
Function InternalServiceManagerURL() Export
	
	Return SaaSOperationsCTL.InternalServiceManagerURL();
	
EndFunction

// Returns the address of the authentication provider.
//
// Returns:
//  String - the address of the authentication provider.
//
Function AuthenticationProviderURL() Export
	
	Return SaaSOperationsCTLCached.AuthenticationProviderURL();
	
EndFunction

// Returns a sign of authentication with the access token for internal calls to the program interface.
// 
// Returns:
//  Boolean
Function AccessTokenAuthenticationOfInternalAPIRequests() Export
	
	Return SaaSOperationsCTLCached.AccessTokenAuthenticationOfInternalAPIRequests();
	
EndFunction

// Returns the name of the service manager service user.
// The calling code must independently set the privileged mode.
//
// Returns:
//  String - the name of the service manager's service user.
//
Function ServiceManagerInternalUserName() Export
	
	Return SaaSOperationsCTL.ServiceManagerInternalUserName();
	
EndFunction

// Returns the service manager service user password.
// The calling code must independently set the privileged mode.
//
// Returns:
//  String - the password of the service manager's service user.
//
Function ServiceManagerInternalUserPassword() Export
	
	Return SaaSOperationsCTL.ServiceManagerInternalUserPassword();
	
EndFunction

// Processes error information received from the web service.
// If non-empty error information is passed, writes
// a detailed representation of the error to the log and raises
// an exception with the text of the error summary.
//
// Parameters:
//   ErrorInfo - ErrorInfo - the error information,
//   SubsystemName - String - the name of the subsystem,
//   WebServiceName - String - web service name,
//   OperationName - String - the name of the operation.
//
Procedure HandleWebServiceErrorInfo(Val ErrorInfo, Val SubsystemName = "", Val WebServiceName = "", Val OperationName = "") Export
	
	If ErrorInfo = Undefined Then
		Return;
	EndIf;
	
	If IsBlankString(SubsystemName) Then
		SubsystemName = Metadata.Subsystems.CloudTechnology.Name;
	EndIf;
	
	EventName = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1.Lỗi gọi ra giao dịch của web-service';
			|ru = '%1.Ошибка вызова операции web-сервиса';
			|en = '%1.Error calling the web service operation'; fa = '%1.Error calling the web service operation';
			|it = '%1.Errore di chiamata di funzione dell''operazione del servizio web';
			|pl = '%1.Błąd podczas wywoływania operacji usługi internetowej';
			|tr = '%1. Web servis işlem çağrısı hatası'", Common.DefaultLanguageCode()),
		SubsystemName);
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Lỗi khi gọi thao tác %1 của web-service %2: %3';
			|ru = 'Ошибка при вызове операции %1 веб-сервиса %2: %3';
			|en = 'An error occurred when calling operation %1 of web service %2: %3'; fa = 'An error occurred when calling operation %1 of web service %2: %3';
			|it = 'Errore alla chiamata di funzione dell''operazione %1 del servizio web %2: %3';
			|pl = 'Błąd podczas wywoływania operacji %1 usługi internetowej %2: %3';
			|tr = '%1 Web hizmeti işletimi %2çağrılırken bir hata oluştu: %3'", Common.DefaultLanguageCode()),
		OperationName,
		WebServiceName,
		ErrorInfo.DetailErrorDescription);
	
	WriteLogEvent(
		EventName,
		EventLogLevel.Error,
		,
		,
		ErrorText);
		
	Raise ErrorInfo.BriefErrorDescription;
	
EndProcedure

// Returns the user alias that should be used in the interface.
//
// Parameters:
//   UserIdentificator - UUID - user ID.
//
// Returns:
//   String - the alias of the user of the information base to display in the interface.
//
Function AliasOfUserOfInformationBase(Val UserIdentificator) Export
	
	Alias = "";
	
	CTLSubsystemsIntegration.OnDefineUserAlias(UserIdentificator, Alias);
	Return Alias;
	
EndFunction

// Gets the record Manager for the Scoped data register in the transaction.
//
// Parameters:
//  DataArea - Number - number of the data area.
//  Status - EnumRef.DataAreaStatuses - expected status of the area.
//
// Returns:
//  InformationRegisterRecordManager.DataAreas - data area record manager.
//
Function GetDataAreaRecordManager(Val DataArea, Val Status) Export
	
	BeginTransaction();
	Try
		Block = New DataLock;
		Item = Block.Add("InformationRegister.DataAreas");
		Item.SetValue("DataAreaAuxiliaryData", DataArea);
		Item.Mode = DataLockMode.Shared;
		Block.Lock();
		
		RecordManager = InformationRegisters.DataAreas.CreateRecordManager();
		RecordManager.DataAreaAuxiliaryData = DataArea;
		RecordManager.Read();
		
		If Not RecordManager.Selected() Then
			MessageTemplate = NStr("vi = 'Không tìm thấy vùng dữ liệu %1';
									|ru = 'Область данных %1 не найдена';
									|en = '%1 data area is not found'; fa = '%1 data area is not found';
									|it = 'Area dati %1 non trovata';
									|pl = 'Obszar danych %1 nie znaleziony';
									|tr = 'Veri alanı %1 bulunamadı.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, DataArea);
			Raise(MessageText);
		ElsIf RecordManager.Status <> Status Then
			MessageTemplate = NStr("vi = 'Trạng thái vùng dữ liệu %1 không bằng ""%2""';
									|ru = 'Статус области данных %1 не равен ""%2""';
									|en = 'Status of data area %1 is not ""%2""'; fa = 'Status of data area %1 is not ""%2""';
									|it = 'Lo stato dell''area dati %1 non è pari a ""%2""';
									|pl = 'Status obszaru danych %1 nie równa się ""%2""';
									|tr = '%1 veri alanın durumu ""%2"" eşit değil'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, DataArea, Status);
			Raise(MessageText);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(LogEventPreparingDataArea(), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	Return RecordManager;
	
EndFunction

// Loads data to the "standard" area.
// 
// Parameters: 
//   DataArea - Number - number of the area to fill in.
//   UploadFileID - UUID - ID of the initial data file.
//   Variant - String - a variant of the initial data.
//   ErrorMessage - String - returned, error description.
//
// Returns:
//  String - one of the options is "Success", "Fatal error".
//
Function PrepareDataAreaForUseFromReference(Val DataArea, Val UploadFileID, 
												 		  Val Variant, ErrorMessage) Export
	
	If Constants.CopyDataAreasFromPrototype.Get() Then
		
		SetSafeModeDisabled(True);
		Result = ImportAreaFormSuppliedData(DataArea, UploadFileID, Variant, ErrorMessage);
		SetSafeModeDisabled(False);
		
		If Result <> "Success" Then
			Return Result;
		EndIf;
		
	Else
		
		Result = "Success";
		
	EndIf;
	
	InfobaseUpdate.UpdateInfobase();
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Control of undivided data.

// Handler for subscribing to the event of controldistributed record Objects.
//
Procedure CheckSharedObjectsOnWrite(Source, Cancel) Export
	
	// Deceived.No download is required.
	// Recording of undivided data from a split session is prohibited.
	ControlOfUnsharedDataWhenWriting(Source);
	
EndProcedure

// Handler for subscribing to the event controlselected Recordsetsrecords.
//
Procedure CheckSharedRecordsSetsOnWrite(Source, Cancel, Replacing) Export
	
	// Deceived.No download is required.
	// Recording of undivided data from a split session is prohibited.
	ControlOfUnsharedDataWhenWriting(Source);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Work with files

// Returns the full name of the file obtained from the MS file storage by its ID.
//
// Parameters:
//   FileID_ - UUID - ID of the file in the MS file storage.
//
// Returns:
//   String - full name of the extracted file.
//
Function GetFileFromServiceManagerStorage(Val FileID_) Export

	CauseExceptionMissingExtensionCTL();
	Return Undefined;

EndFunction

// Adds the file to the storage of the service Manager.
//
// Parameters:
//   AddressDataFile - String - address of the file in temporary storage,
//                   - BinaryData - binary file data,
//                   - File - file.
//   FileName - String - the stored file name.
//   AdditionalParameters - Structure - serializable to json data.
//		
// Returns:
//   UUID - id of the file in the repository.
//
Function PlaceFileInStorageOfServiceManager(Val AddressDataFile, Val FileName = "",
	AdditionalParameters = Undefined) Export

	CauseExceptionMissingExtensionCTL();
	Return Undefined;

EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions for determining the types of metadata objects by the full name
// of the metadata object.

// Reference data types

// Determines whether a metadata object belongs to the General "Document" type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the document.
//
Function ThisIsFullNameOfDocument(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "Document", "Document");
	
EndFunction

// Determines whether a metadata object belongs to the General "reference" type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the reference book.
//
Function ThisIsFullNameOfCatalog(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "Catalog", "Catalog");
	
EndFunction

// Determines whether the metadata object belongs to the General "Enumeration" type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the enumeration.
//
Function ThisIsFullNameOfEnumeration(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "Enum", "Enum");
	
EndFunction

// Determines whether the metadata object belongs to the General "exchange Plan" type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the exchange plan.
//
Function ThisIsFullNameOfExchangePlan(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "ExchangePlan", "ExchangePlan");
	
EndFunction

// Determines whether a metadata object belongs to the General type "plan of types of characteristics" by
//  the full name of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the plan of types of characteristics.
//
Function ThisIsFullNameOfKindsOfCharacteristicsPlan(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "ChartOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	
EndFunction

// Determines whether the metadata object belongs to the General "Business process" type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the business process.
//
Function ThisIsFullNameOfBusinessProcess(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "BusinessProcess", "BusinessProcess");
	
EndFunction

// Determines whether the metadata object belongs to the General "Task" type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
// 
// Returns:
//  Boolean - True if the task.
//
Function ThisIsFullNameOfTask(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "Task", "Task");
	
EndFunction

// Determines whether the metadata object belongs to the General chart of accounts type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the chart of accounts.
//
Function ThisIsFullNameOfChartOfAccounts(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "ChartOfAccounts", "ChartOfAccounts");
	
EndFunction

// Determines whether the metadata object belongs to the General type "calculation plan" by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the plan of calculation types.
//
Function ThisIsFullNameOfPlanForCalculation(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "ChartOfCalculationTypes", "ChartOfCalculationTypes");
	
EndFunction

// Registers

// Determines whether the metadata object belongs to the General "data Register" type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the information register.
//
Function ThisIsFullNameOfInformationRegister(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "InformationRegister", "InformationRegister");
	
EndFunction

// Determines whether the metadata object belongs to the General "accumulation Register" type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the accumulation register.
//
Function ThisIsFullNameOfAccumulationRegister(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "AccumulationRegister", "AccumulationRegister");
	
EndFunction

// Determines whether the metadata object belongs to the General accounting Register type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the accounting register.
//
Function ThisIsFullNameOfAccountingRegister(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "AccountingRegister", "AccountingRegister");
	
EndFunction

// Determines whether the metadata object belongs to the General "calculation Register" type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the calculation register.
//
Function ThisIsFullNameOfCalculationRegister(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "CalculationRegister", "CalculationRegister")
		And Not ThisIsFullNameOfRecalculation(FullName);
	
EndFunction

// Recalculations

// Determines whether the metadata object belongs to the "Recalculation" type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if recalculated.
//
Function ThisIsFullNameOfRecalculation(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "Recalculation", "Recalculation", 2);
	
EndFunction

// Constants

// Determines whether a metadata object belongs to the General "Constant" type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if constant.
//
Function ThisIsFullNameOfConstant(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "Constant", "Constant");
	
EndFunction

// Document logs

// Determines whether the metadata object belongs to the General document Log type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the document log.
//
Function ThisIsFullNameOfDocumentLog(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "DocumentJournal", "DocumentJournal");
	
EndFunction

// Sequences

// Determines whether a metadata object belongs to the General "Sequence" type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the sequence.
//
Function ThisIsFullNameOfSequence(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "Sequence", "Sequence");
	
EndFunction

// ScheduledJobs

// Determines whether the metadata object belongs to the General "Routine tasks" type by the full name
//  of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the routine task.
//
Function ThisIsFullNameOfRoutineAssignment(Val FullName) Export
	
	Return CheckingTypeOfMetadataObjectByItsFullName(FullName, "ScheduledJob", "ScheduledJob");
	
EndFunction

// Overall

// Determines whether a metadata object belongs to the register type by the full name of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if case.
//
Function ThisIsFullRegisterName(Val FullName) Export
	
	Return ThisIsFullNameOfInformationRegister(FullName)
		Or ThisIsFullNameOfAccumulationRegister(FullName)
		Or ThisIsFullNameOfAccountingRegister(FullName)
		Or ThisIsFullNameOfCalculationRegister(FullName);
	
EndFunction

// Determines whether the metadata object belongs to the reference type by the full name of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object to determine
//   whether it belongs to the specified type.
//
// Returns:
//  Boolean - True if the reference type.
//
Function ThisIsFullNameOfObjectOfReferenceType(Val FullName) Export
	
	Return ThisIsFullNameOfCatalog(FullName)
		Or ThisIsFullNameOfDocument(FullName)
		Or ThisIsFullNameOfBusinessProcess(FullName)
		Or ThisIsFullNameOfTask(FullName)
		Or ThisIsFullNameOfChartOfAccounts(FullName)
		Or ThisIsFullNameOfExchangePlan(FullName)
		Or ThisIsFullNameOfKindsOfCharacteristicsPlan(FullName)
		Or ThisIsFullNameOfPlanForCalculation(FullName);
	
EndFunction

// Defines the support of predefined data by a metadata object by the full name of the metadata object.
//
// Parameters:
//  FullName - String - the full name of the metadata object for which you want to define
//   support for predefined data.
//
// Returns:
//  Boolean - True if the metadata object supports predefined data.
//
Function IsFullNameOfObjectWithPredefinedData(Val FullName) Export
	
	Return ThisIsFullNameOfCatalog(FullName)
		Or ThisIsFullNameOfChartOfAccounts(FullName)
		Or ThisIsFullNameOfKindsOfCharacteristicsPlan(FullName)
		Or ThisIsFullNameOfPlanForCalculation(FullName);
	
EndFunction

// Selection parameters based on the full name of the metadata object.
// 
// Parameters: 
//  FullMetadataObjectName - String - full name of the metadata object.
// 
// Returns: 
//	Structure - sample parameters:
//	 * Table - String - the name of the metadata object.
//	 * FieldNameLogger - String - name of the Registrar's field.
Function SelectionParameters(Val FullMetadataObjectName) Export
	
	Result = New Structure("Table,FieldNameLogger");
	
	If ThisIsFullRegisterName(FullMetadataObjectName)
			Or ThisIsFullNameOfSequence(FullMetadataObjectName) Then
		
		Result.Table = FullMetadataObjectName;
		Result.FieldNameLogger = "Recorder";
		
	ElsIf ThisIsFullNameOfRecalculation(FullMetadataObjectName) Then
		
		Substrings = StrSplit(FullMetadataObjectName, ".");
		Result.Table = Substrings[0] + "." + Substrings[1] + "." + Substrings[3];
		Result.FieldNameLogger = "RecalculationObject";
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hàm %1 không được sử dụng cho đối tượng %2.';
				|ru = 'Функция %1 не должна использоваться для объекта %2.';
				|en = 'The %1 function cannot be used for the %2 object.'; fa = 'The %1 function cannot be used for the %2 object.';
				|it = 'La funzione dei %1 non deve essere utilizzata per l''oggetto %2.';
				|pl = 'Funkcja %1 nie powinna być stosowana do objektu %2.';
				|tr = '%1 fonksiyonu %2 nesnesi için kullanılmamalıdır.'"),
			"SelectionParameters",
			FullMetadataObjectName);
		
	EndIf;
	
	Return Result;
	
EndFunction

// The name of the event log to record errors for the copy data region.
//
// Returns:
//	String - name of the error event.
//
Function LogEventCopyingDataArea() Export
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Làm việc trong mô hình dịch vụ.Sao chép vùng dữ liệu';
				|ru = 'Работа в модели сервиса.Копирование области данных';
				|en = 'SaaS.Copy data area'; fa = 'SaaS.Copy data area';
				|it = 'Lavoro nel modello di servizio. Duplicazione dell''area dati';
				|pl = 'Praca w modelu usługi.Kopiowanie obszaru danych';
				|tr = 'Servis modelinde çalışma. Veri alanın kopyalanması'", Common.DefaultLanguageCode());
	
EndFunction

// Name of the log event for recording data area lock errors.
//
// Returns:
//	String - name of the error event.
//
Function LogEventDataAreaLock() Export
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Làm việc trong mô hình dịch vụ.Phong tỏa vùng dữ liệu';
				|ru = 'Работа в модели сервиса.Блокировка области данных';
				|en = 'SaaS.Lock data area'; fa = 'SaaS.Lock data area';
				|it = 'Lavoro nel modello di servizio. Blocco dell''area dati';
				|pl = 'Praca w modelu usługi.Blokowanie obszaru danych';
				|tr = 'Servis modelinde çalışma. Veri alanın kilitlenmesi'", Common.DefaultLanguageCode());
	
EndFunction

// The name of the event log to record errors of the training data region.
//
// Returns:
//	String - name of the error event.
//
Function LogEventPreparingDataArea() Export
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Làm việc trong mô hình dịch vụ.Chuẩn bị vùng dữ liệu';
				|ru = 'Работа в модели сервиса.Подготовка области данных';
				|en = 'SaaS.Prepare data area'; fa = 'SaaS.Prepare data area';
				|it = 'Lavoro nel modello di servizio. Preparazione dell''area dati';
				|pl = 'Praca w modelu usługi.Przygotowanie obszaru danych';
				|tr = 'Servis modelinde çalışma. Veri alanın hazırlanması'", Common.DefaultLanguageCode());
	
EndFunction

// Name of the log event to record errors when retrieving a file from storage.
//
// Returns:
//	String - name of the error event.
//
Function LogEventRetrievingFileFromStorage() Export
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Làm việc trong mô hình dịch vụ.Nhận tệp từ kho chứa';
				|ru = 'Работа в модели сервиса.Получение файла из хранилища';
				|en = 'SaaS.Get file from storage'; fa = 'SaaS.Get file from storage';
				|it = 'Lavoro nel modello di servizio. Ricezione del file dall''archivio';
				|pl = 'Praca w modelu usługi.Pobierz plik z magazynu';
				|tr = 'Servis modelinde çalışma. Depolama alanından dosya alma'", Common.DefaultLanguageCode());
	
EndFunction

// The name of the event log to record errors add a file with the exchange through the file system.
//
// Returns:
//	String - name of the error event.
//
Function LogEventAddFileExchangeViaFS() Export
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Làm việc trong mô hình dịch vụ.Thêm tệp.Trao đổi qua tệp';
				|ru = 'Работа в модели сервиса.Добавление файла.Обмен через ФС';
				|en = 'SaaS.Add file.Exchange using file system'; fa = 'SaaS.Add file.Exchange using file system';
				|it = 'Lavoro nel modello di servizio. Aggiunta del file. Scambio attraverso il Fyle System';
				|pl = 'Praca w modelu usługi.Dodawanie pliku.Udostępnianie przez FS';
				|tr = 'Servis modelinde çalışma. Dosya ekleme. DS üzerinden alışveriş'", Common.DefaultLanguageCode());
	
EndFunction

// The name of the event log to record errors the file is added in the exchange are not using the file system.
//
// Returns:
//	String - name of the error event.
//
Function LogEventAddFileExchangeNotViaFS() Export
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Làm việc trong mô hình dịch vụ.Thêm tệp.Trao đổi không qua tệp';
				|ru = 'Работа в модели сервиса.Добавление файла.Обмен не через ФС';
				|en = 'SaaS.Add file.Exchange not using file system'; fa = 'SaaS.Add file.Exchange not using file system';
				|it = 'Lavoro nel modello di servizio. Aggiunta del file. Scambio non attraverso il Fyle System';
				|pl = 'Praca w modelu usługi.Dodawanie pliku.Wymiana poza FS';
				|tr = 'Servis modelinde çalışma. Dosya ekleme. DS üzerinden olmayan alışveriş'", Common.DefaultLanguageCode());
	
EndFunction

// The name of the event log to record errors, the temporary file deletion.
//
// Returns:
//	String - name of the error event.
//
Function TempFileDeletionEventLogEvent() Export
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Làm việc trong mô hình dịch vụ.Xóa tệp tạm thời';
				|ru = 'Работа в модели сервиса.Удаление временного файла';
				|en = 'SaaS.Delete temporary file'; fa = 'SaaS.Delete temporary file';
				|it = 'Lavoro nel modello di servizio. Eliminazione del file temporaneo';
				|pl = 'Praca w modelu usługi.Usuwanie pliku tymczasowego';
				|tr = 'Servis modelinde çalışma. Geçici dosyayı sil'", Common.DefaultLanguageCode());
	
EndFunction

// Other

// See SaaSOperationsOverridable.OnFillIIBParametersTable.
// Parameters:
// 	ParametersTable - See IBParameters
Procedure OnFillIIBParametersTable(Val ParametersTable) Export
	
	If IsSeparatedConfiguration() Then
		AddConstantToInformationSecurityParameterTable(ParametersTable, "UseSeparationByDataAreas");
		
		AddConstantToInformationSecurityParameterTable(ParametersTable, "InfobaseUsageMode");
		
		AddConstantToInformationSecurityParameterTable(ParametersTable, "CopyDataAreasFromPrototype");
		
		AddConstantToInformationSecurityParameterTable(ParametersTable, "CloseSessionsWithoutWarningByDefaultSaaS");
		
	EndIf;
	
	AddConstantToInformationSecurityParameterTable(ParametersTable, "InternalServiceManagerURL");
	AddConstantToInformationSecurityParameterTable(ParametersTable, "AuthenticationProviderURL");
	AddConstantToInformationSecurityParameterTable(ParametersTable, "AccessTokenAuthenticationOfInternalAPIRequests");
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "InternalServiceManagerURL";
	ParameterString.LongDesc = NStr("vi = 'Địa chỉ nội bộ của Bộ quản lý dịch vụ';
									|ru = 'Внутренний адрес Менеджера сервиса';
									|en = 'Internal Service Manager URL'; fa = 'URL داخلی Service Manager';
									|it = 'Indirizzo interno del manager di servizio';
									|pl = 'Adres wewnętrzny Menedżera usług';
									|tr = 'Servis yöneticisinin dahili adresi'");
	ParameterString.Type = New TypeDescription("String");
	
	// For compatibility with previous versions, the "Service URL" parameter is required
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "URLOfService";
	ParameterString.LongDesc = NStr("vi = 'Địa chỉ nội bộ của Bộ quản lý dịch vụ';
									|ru = 'Внутренний адрес Менеджера сервиса';
									|en = 'Internal Service Manager URL'; fa = 'URL داخلی Service Manager';
									|it = 'Indirizzo interno del manager di servizio';
									|pl = 'Adres wewnętrzny Menedżera usług';
									|tr = 'Servis yöneticisinin dahili adresi'");
	ParameterString.Type = New TypeDescription("String");
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "ServiceManagerInternalUserName";
	ParameterString.LongDesc = "ServiceManagerInternalUserName";
	ParameterString.Type = New TypeDescription("String");
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "ServiceManagerInternalUserPassword";
	ParameterString.LongDesc = "ServiceManagerInternalUserPassword";
	ParameterString.Type = New TypeDescription("String");
	ParameterString.ForbiddenReading = True;
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "InternalServiceUserName";
	ParameterString.LongDesc = "InternalServiceUserName";
	ParameterString.Type = New TypeDescription("String");
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "InternalServiceUserPassword";
	ParameterString.LongDesc = "InternalServiceUserPassword";
	ParameterString.Type = New TypeDescription("String");
	ParameterString.ForbiddenReading = True;
	// End For compatibility with previous versions.
	
	ParameterString = ParametersTable.Add();
	ParameterString.Name = "ConfigurationVersion";
	ParameterString.LongDesc = NStr("vi = 'Phiên bản cấu hình';
									|ru = 'Версия конфигурации';
									|en = 'Configuration version'; fa = 'نسخه پیکربندی';
									|it = 'Versione della configurazione';
									|pl = 'Wersja konfiguracji';
									|tr = 'Yapılandırma sürümü'");
	ParameterString.RecordBan = True;
	ParameterString.Type = New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable));
	
	AddConstantToInformationSecurityParameterTable(
		ParametersTable,
		"SetPriorityOfDataProcessingInSpecifiedTimeInterval");
	AddConstantToInformationSecurityParameterTable(
		ParametersTable,
		"BeginningOfDataProcessingPriorityTimeInterval");
	AddConstantToInformationSecurityParameterTable(
		ParametersTable,
		"EndOfDataProcessingPriorityTimeInterval");
	
	NumberOfUpdateThreadsConstantName = "InfobaseUpdateThreadCount";
	If Metadata.Constants.Find(NumberOfUpdateThreadsConstantName) <> Undefined Then
		AddConstantToInformationSecurityParameterTable(
			ParametersTable,
			NumberOfUpdateThreadsConstantName);
	EndIf;
	
	CTLSubsystemsIntegration.OnFillIIBParametersTable(ParametersTable);
	
EndProcedure

// See DataExchangeOverridable.WhenFillingInTypesExcludedFromCheckProblemIsFixed.
// 
// Parameters:
// 	Types - See DataExchangeOverridable.WhenFillingInTypesExcludedFromCheckProblemIsFixed.Types
// 
Procedure WhenFillingInTypesExcludedFromCheckProblemIsFixed(Types) Export

	Types.Add(Metadata.Catalogs.BuiltInExtensionVersions);
	Types.Add(Metadata.Catalogs.DataCheckAndAdjustmentHistory);
	Types.Add(Metadata.Catalogs.InformationReferencesForForms);
	Types.Add(Metadata.Catalogs.DataCheckAndAdjustmentHistoryAttachedFiles);
	Types.Add(Metadata.Catalogs.JobsQueueHandlers);
	Types.Add(Metadata.Catalogs.CommonInformationCenterData);
	Types.Add(Metadata.Catalogs.UsersNotifications);
	Types.Add(Metadata.Catalogs.JobsQueue);
	Types.Add(Metadata.Catalogs.FullPathsToForms);
	Types.Add(Metadata.Catalogs.SuppliedData);
	Types.Add(Metadata.Catalogs.SuppliedExtensions);
	Types.Add(Metadata.Catalogs.SaaSServicesSuppliers);
	Types.Add(Metadata.Catalogs.DataAreaMessages);
	Types.Add(Metadata.Catalogs.SystemMessages);
	Types.Add(Metadata.Catalogs.InformationCenterInformationTypes);
	Types.Add(Metadata.Catalogs.DeleteJobsQueue);
	Types.Add(Metadata.Catalogs.SaaSServices);
	Types.Add(Metadata.Catalogs.QueueJobTemplates);	

EndProcedure

// Writes a test file to disk, returning its name and size.
// The file must be deleted by the caller.
//
// Returns:
//   String - the name of the trial file without a path.
//
Function RecordTrialFile() Export
	
	NewID = New UUID;
	FileProperties = New File(FilesCTL.SharedDirectoryOfTemporaryFiles() + NewID + ".tmp");
	
	Text = New TextWriter(FileProperties.FullName, TextEncoding.ANSI);
	Text.Write(NewID);
	Text.Close();
	
	Return FileProperties.Name;
	
EndFunction

// Additional steps to perform when changing the separation of the session.
//
Procedure OnChangeDataArea() Export
	
	ClearAllSessionParametersExceptDelimiters();
	
	If CurrentRunMode() <> Undefined 
		And SeparatedDataUsageAvailable() Then
		
		RecordManager = InformationRegisters.DataAreas.CreateRecordManager();
		RecordManager.Read();
		
		If RecordManager.Selected() Then
			
			If Not (RecordManager.ProcessingError
				Or RecordManager.Status = Enums.DataAreaStatuses.ForDeletion
				Or RecordManager.Status = Enums.DataAreaStatuses.isDeleted) Then
		
				AuthenticateCurrentUser();
			EndIf;
			
		Else
			AuthenticateCurrentUser();	
		EndIf;
		
	EndIf;
	
EndProcedure

// Registers handlers of delivered data for the day and for the entire time.
//
// Parameters:
//   Handlers - ValueTable - table of handlers.
//
Procedure RegisterSuppliedDataHandlers(Val Handlers) Export
	
	Handler = Handlers.Add();
	Handler.DataKind = "DataAreaPrototype";
	Handler.HandlerCode = "DataAreaPrototype";
	Handler.Handler = SaaSOperations;
	
EndProcedure

// Called when a notification of new data is received.
// In the body, check whether the application needs this data, 
// and if so, select the Upload checkbox.
// 
// Parameters:
//   Descriptor - XDTODataObject, Structure - descriptor.
//   ToImport - Boolean - True if loaded, False otherwise.
//	 JSONDescriptor - Boolean - flag indicating that the handle came in JSON format
//
Procedure NewDataAvailable(Val Descriptor, ToImport, Val JSONDescriptor = False) Export
	
	If Descriptor.DataType = "DataAreaPrototype" Then
		ConfigurationNameCondition = False;
		ConfigurationVersionCondition = False;
		For Each Characteristic In Descriptor.Properties.Property Do
			If Not ConfigurationNameCondition Then
				ConfigurationNameCondition = Characteristic.Code = "ConfigurationName" And Characteristic.Value = Metadata.Name;
			EndIf;
			If Not ConfigurationVersionCondition Then
				ConfigurationVersionCondition = Characteristic.Code = "ConfigurationVersion"
					And CommonClientServer.CompareVersions(Characteristic.Value, Metadata.Version) >= 0;
			EndIf;
		EndDo;
		ToImport = ConfigurationNameCondition And ConfigurationVersionCondition;
	EndIf;
	
EndProcedure

// Called when a notification of new data is received.
// In the body, check whether the application needs this data, 
// and if so, select the Upload checkbox.
// 
// Parameters:
//   Descriptor - Structure - descriptor.
//   ToImport - Boolean - True if loaded, False otherwise.
//
Procedure NewJSONDataAvailable(Val Descriptor, ToImport) Export
	
	NewDataAvailable(Descriptor, ToImport, True);
	
EndProcedure

// Called after calling available Data, allows you to parse the data.
//
// Parameters:
//   Descriptor - XDTODataObject, Structure - descriptor.
//   PathToFile - String - full name of the extracted file. The file will be automatically deleted 
//                  after the procedure is completed. If the
//                  file was not specified in the service Manager, the argument value is Undefined.
//	 JSONDescriptor - Boolean - flag indicating that the handle came in JSON format
//
Procedure ProcessNewData(Val Descriptor, Val PathToFile, Val JSONDescriptor = False) Export
	
	If Descriptor.DataType = "DataAreaPrototype" Then
		ProcessSuppliedConfigurationReference(Descriptor, PathToFile);
	EndIf;
	
EndProcedure

// Called after calling available Data, allows you to parse the data.
//
// Parameters:
//   Descriptor - Structure - descriptor.
//   PathToFile - String - full name of the extracted file. The file will be automatically deleted 
//                  after the procedure is completed. If the
//                  file was not specified in the service Manager, the argument value is Undefined.
//
Procedure ProcessNewJSONData(Val Descriptor, Val PathToFile) Export
	
	ProcessNewData(Descriptor, PathToFile, True);
	
EndProcedure

// Called when data processing is canceled in the event of a failure.
//
// Parameters:
//   Descriptor - XDTODataObject - descriptor.
//
Procedure DataProcessingCanceled(Val Descriptor) Export 
	Return;	
EndProcedure

// For the general module workmodeliservisapovtisp.

// Determines whether the session is started with or without delimiters.
//
// Returns:
//   Boolean - True if the session is started without delimiters.
//
Function SessionWithoutSeparators() Export
	
	Return InfoBaseUsers.CurrentUser().DataSeparation.Count() = 0;
	
EndFunction

// Returns the sign of the presence in the General configuration details-separators.
//
// Returns:
//   Boolean - True if it is a split configuration.
//
Function IsSeparatedConfiguration() Export
	
	Return SaaSOperationsCached.IsSeparatedConfiguration();
	
EndFunction

// Returns an indication that the metadata object is used in shared delimiter details.
//
// Parameters:
//   MetadataObject - String - the name of the metadata object.
//   Separator - String - name of the shared delimiter that the metadata object is checked for.
//
// Returns:
//   Boolean - True if it is a split object.
//
Function IsSeparatedMetadataObject(Val MetadataObject, Val Separator = Undefined) Export
	
	If TypeOf(MetadataObject) = Type("String") Then
		FullMetadataObjectName = MetadataObject;
	Else
		FullMetadataObjectName = MetadataObject.FullName();
	EndIf;
	
	Return SaaSOperationsCached.IsSeparatedMetadataObject(FullMetadataObjectName, Separator);
	
EndFunction

// Returns an array of currently supported serializable structure types.
//
// Returns:
//   FixedArray of Type - array of Type Type.
//
Function SerializableStructuralTypes() Export
	
	Return SaaSOperationsCached.SerializableStructuralTypes();
	
EndFunction

// Returns the endpoint for sending messages to the service Manager.
//
// Returns:
//  ExchangePlanRef.MessagesExchange - the node corresponding to the service manager.
//
Function ServiceManagerEndpoint() Export
	
	Return SaaSOperationsCTL.ServiceManagerEndpoint();
	
EndFunction

// Returns whether the user's contact information types match the types.
// CI of the service model used in the XDTO.
//
// Returns:
//  Map of KeyAndValue- compliance of types of CI:
//  * Key - CatalogRef.ContactInformationKinds
//  * Value - String
//
Function MatchingUserSAITypesToXDTO() Export
	
	Return SaaSOperationsCached.MatchingUserSAITypesToXDTO();
	
EndFunction

// Returns the correspondence of the types of the XDTO contact information to the types of the user's CI.
// 
// Returns: 
//  Map of KeyAndValue -- compliance of types of CI:
//  * Key - String
//  * Value - CatalogRef.ContactInformationKinds
Function ComplianceOfKixdtoTypesWithUserKiTypes() Export
	
	Return SaaSOperationsCached.ComplianceOfKixdtoTypesWithUserKiTypes();
	
EndFunction

// Returns whether the XDTO rights correspond to possible
// actions with the service user used in the service model.
// 
// Returns:
//  Map of KeyAndValue - compliance of rights with actions:
//  * Key - String
//  * Value - String
//
Function ComplianceOfXDTORightsWithActionsWithServiceUser() Export
	
	Return SaaSOperationsCached.ComplianceOfXDTORightsWithActionsWithServiceUser();
	
EndFunction

// Returns a description of the data model that belongs to the data area.
//
// Returns:
//  FixedMap of KeyAndValue - Area Data Model:
//    * Key - MetadataObject - metadata object,
//    * Value - String - the name of the shared separator prop.
//
Function GetAreaDataModel() Export
	
	Return SaaSOperationsCached.GetAreaDataModel();
	
EndFunction

// Returns an array of existing delimiters in the configuration.
//
// Returns:
//   FixedArray of String - an array of names of common requisites that
//     are separators.
//
Function ConfigurationSeparators() Export
	
	Return SaaSOperationsCached.ConfigurationSeparators();
	
EndFunction

// Returns the composition of the shared props with the specified name.
//
// Parameters:
//   Name - String - name of the shared property.
//
// Returns:
//   CommonAttributeContent - a list of metadata objects that include common props.
//
Function CommonAttributeContent(Val Name) Export
	
	Return SaaSOperationsCached.CommonAttributeContent(Name);
	
EndFunction

// Returns the status of the data area.
//
// Parameters:
//  DataArea -  Number - value of the data area separator 
//   to get the status of.
//
// Returns:
//  EnumRef.DataAreaStatuses - the status of the data area.
//
Function DataAreaStatus(DataArea) Export
	
	Query = New Query;
	Query.Text =
		"SELECT TOP 1
		|	DataAreas.Status AS Status
		|FROM
		|	InformationRegister.DataAreas AS DataAreas
		|WHERE
		|	DataAreas.DataAreaAuxiliaryData = &DataArea";
	Query.SetParameter("DataArea", DataArea);
	Result = Query.Execute().Unload();
	If Result.Count() = 0 Then
		Return Undefined;
	Else
		Return Result[0].Status;
	EndIf;
	
EndFunction

// Returns a table describing information security parameters.
//
// Returns:
// ValueTable - information security parameters. Contains columns:
//  * Name - String - parameter name.
//  * LongDesc - String - description of the parameter to display in the user interface.
//  * ForbiddenReading - Boolean - indicates that the IB parameter cannot be read. It can be set, for example, for
//                            passwords.
//  * RecordBan - Boolean - indicates that the IB parameter cannot be changed.
//  * Type - TypeDescription - type of parameter value. You can only use primitive types and
//                          enumerations that are present in the control application.
//
Function IBParameters() Export
	
	ParametersTable = InformationSecurityParameterTemplate();
	
	OnFillIIBParametersTable(ParametersTable);
	
	SaaSOperationsOverridable.OnFillIIBParametersTable(ParametersTable);
	
	Return ParametersTable;
	
EndFunction

// Returns the flag for whether user change actions are available.
//
// Returns:
// 	Boolean - True if the user change is available, otherwise False.
//
Function CanChangeUsers() Export
	
	Return Constants.InfobaseUsageMode.Get() 
		<> Enums.InfobaseUsageModes.Demo;
	
EndFunction

// Returns a collection of used data areas.
//
// Returns:
//   QueryResult - the result of a query containing a list of data areas.
//
Function DataAreasUsed() Export
	Query = New Query();
	Query.Text = 
	"SELECT
	|	DataAreas.DataAreaAuxiliaryData AS DataArea
	|FROM
	|	InformationRegister.DataAreas AS DataAreas
	|WHERE
	|	DataAreas.Status = VALUE(Enum.DataAreaStatuses.Used)
	|ORDER BY
	|	DataArea";
	
	Result = Query.Execute();
	
	Return Result;
EndFunction

// Creates a record key for the information register that is included in the help data Area separator.
//
// Parameters:
//  Manager - InformationRegisterManager - information register Manager for which you want to get a record key,
//  KeyValues - Structure - contains values for filling in the properties of the record key.
//                              The names of the structure elements must match the names of the key fields.
//
// Returns:
//  InformationRegisterRecordKeyInformationRegisterName - the recording key.
//
Function CreateAuxiliaryDataInformationRegisterEntryKey(Val Manager, Val KeyValues) Export
	
	Var_Key = Manager.CreateRecordKey(KeyValues);
	
	DataArea = Undefined;
	Separator = AuxiliaryDataSeparator();
	
	If KeyValues.Property(Separator, DataArea) Then
		
		If Var_Key[Separator] <> DataArea Then
			
			Object = XDTOSerializer.WriteXDTO(Var_Key);
			Object[Separator] = DataArea;
			Var_Key = XDTOSerializer.ReadXDTO(Object);
			
		EndIf;
		
	EndIf;
	
	Return Var_Key;
	
EndFunction

// Sets whether the user is active in the Cur area.
// The attribute is the value of the jointly divided constant of the date of the last startaclient session.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure SetUserActivityFlagInArea() Export
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated. The platform method should be used to set the Monopoly mode (True).
//
// Parameters:
//  CheckNoOtherSessions - Boolean - check whether there are no other sessions.
//  SharedLocking - Boolean - this is a shared lock.
//
Procedure LockCurDataArea(Val CheckNoOtherSessions = False, Val SharedLocking = False) Export
	
	If Not SeparatedDataUsageAvailable() Then
		Raise(NStr("vi = 'Có thể thiết lập phong tỏa chỉ khi bật sử dụng đường chia tách.';
					|ru = 'Блокировка области может быть установлена только при включенном использовании разделителей';
					|en = 'Area can be locked only when separator usage is enabled'; fa = 'Area can be locked only when separator usage is enabled';
					|it = 'Il blocco dell''area dati può essere impostato solo quando i separatori sono abilitati';
					|pl = 'Blokadę obszaru można ustawić tylko wtedy, gdy włączone są separatory';
					|tr = 'Alan sadece ayırıcı kullanımı etkinleştirildiğinde kilitlenebilir'"));
	EndIf;
	
	Var_Key = CreateAuxiliaryDataInformationRegisterEntryKey(
		InformationRegisters.DataAreas,
		New Structure(AuxiliaryDataSeparator(), SessionSeparatorValue()));
	
	AttemptsNumber = 5;
	CurrentAttempt = 0;
	While True Do
		Try
			LockDataForEdit(Var_Key);
			Break;
		Except
			CurrentAttempt = CurrentAttempt + 1;
			
			If CurrentAttempt = AttemptsNumber Then
				CommentTemplate = NStr("vi = 'Không thể đặt phong tỏa vùng dữ liệu do nguyên nhân:
					|%1';
					|ru = 'Не удалось установить блокировку области данных по причине:
					|%1';
					|en = 'Cannot lock the data area due to:
					|%1'; fa = 'Cannot lock the data area due to:
					|%1';
					|it = 'Non è stato possibile impostare il blocco dell''area dati per: 
					|%1';
					|pl = 'Nie udało się ustawić blokady obszaru danych z powodu:
					|%1';
					|tr = 'Aşağıdaki nedenle veri alanı kilitlenemedi: 
					|%1'");
				CommentText1 = StringFunctionsClientServer.SubstituteParametersToString(
					CommentTemplate, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				WriteLogEvent(LogEventDataAreaLock(),
					EventLogLevel.Error,
					,
					,
					CommentText1);
					
				TextTemplate1 = NStr("vi = 'Không thể đặt phong tỏa vùng dữ liệu do nguyên nhân:
					|%1';
					|ru = 'Не удалось установить блокировку области данных по причине:
					|%1';
					|en = 'Cannot lock the data area due to:
					|%1'; fa = 'Cannot lock the data area due to:
					|%1';
					|it = 'Non è stato possibile impostare il blocco dell''area dati per: 
					|%1';
					|pl = 'Nie udało się ustawić blokady obszaru danych z powodu:
					|%1';
					|tr = 'Aşağıdaki nedenle veri alanı kilitlenemedi: 
					|%1'");
				Text = StringFunctionsClientServer.SubstituteParametersToString(
					TextTemplate1, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
					
				Raise(Text);
			EndIf;
		EndTry;
	EndDo;
	
	If CheckNoOtherSessions Then
		
		ConflictingSessions = New Array; // Array of InfoBaseSession
		
		For Each Session In GetInfoBaseSessions() Do
			If Session.SessionNumber = InfoBaseSessionNumber() Then
				Continue;
			EndIf;
			
			ClientApplications = New Array;
			ClientApplications.Add(Upper("1CV8"));
			ClientApplications.Add(Upper("1CV8C"));
			ClientApplications.Add(Upper("WebClient"));
			ClientApplications.Add(Upper("COMConnection"));
			ClientApplications.Add(Upper("WSConnection"));
			ClientApplications.Add(Upper("BackgroundJob"));
			If ClientApplications.Find(Upper(Session.ApplicationName)) = Undefined Then
				Continue;
			EndIf;
			
			ConflictingSessions.Add(Session);
			
		EndDo;
		
		If ConflictingSessions.Count() > 0 Then
			
			UnlockDataForEdit(Var_Key);
			
			TextSessions = "";
			For Each ConflictingSession In ConflictingSessions Do
				
				If Not IsBlankString(TextSessions) Then
					TextSessions = TextSessions + ", ";
				EndIf;
				
				TextSessions = TextSessions + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 (phiên làm việc - %2)';
						|ru = '%1 (сеанс - %2)';
						|en = '%1 (session %2)'; fa = '%1 (session %2)';
						|it = '%1 (sessione -%2)';
						|pl = '%1 (seans - %2)';
						|tr = '%1 (oturum %2)'", Common.DefaultLanguageCode()),
					ConflictingSession.User.Name,
					Format(ConflictingSession.SessionNumber, "NG=0"));
				
			EndDo;
			
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa thực hiện thao tác, bởi vì trong ứng dụng có người sử dụng khác đang làm việc: %1';
					|ru = 'Операция не может быть выполнена, т.к. в приложении работают другие пользователи: %1';
					|en = 'Operation cannot be performed as other users are using the application: %1'; fa = 'Operation cannot be performed as other users are using the application: %1';
					|it = 'L''operazione non può essere completata poiché altri utenti stanno utilizzando lo stesso programma: %1';
					|pl = 'Operacja nie może zostać wykonana, ponieważ inni użytkownicy pracują w aplikacji: %1';
					|tr = 'Diğer kullanıcılar uygulama kullanıyor olduğundan işlem yapılamaz: %1'",
					Common.DefaultLanguageCode()),
				TextSessions);
				
			Raise ExceptionText;
			
		EndIf;
		
	EndIf;
	
	If Not SharedLocking Then
		SetExclusiveMode(True);
		Return;
	EndIf;
	
	DataModel = SaaSOperationsCached.GetAreaDataModel();
	
	Block = New DataLock;
	
	For Each ModelItem In DataModel Do
		
		FullMetadataObjectName = ModelItem.Key;
		MetadataObjectDetails = ModelItem.Value; // MetadataObject
		
		LockSpace = FullMetadataObjectName;
		
		If ThisIsFullRegisterName(FullMetadataObjectName) Then
			
			BlockSets = True;
			If ThisIsFullNameOfInformationRegister(FullMetadataObjectName) Then
				AreaMetadataObject = Metadata.InformationRegisters.Find(MetadataObjectDetails.Name);
				If AreaMetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
					BlockSets = False;
				EndIf;
			EndIf;
			
			If BlockSets Then
				LockSpace = LockSpace + ".RecordSet";
			EndIf;
			
		ElsIf ThisIsFullNameOfSequence(FullMetadataObjectName) Then
			
			LockSpace = LockSpace + ".Records";
			
		ElsIf ThisIsFullNameOfDocumentLog(FullMetadataObjectName)
				Or ThisIsFullNameOfEnumeration(FullMetadataObjectName)
				Or ThisIsFullNameOfSequence(FullMetadataObjectName)
				Or ThisIsFullNameOfRoutineAssignment(FullMetadataObjectName) Then
			
			Continue;
			
		EndIf;
		
		LockItem = Block.Add(LockSpace);
		
		If SharedLocking Then
			
			LockItem.Mode = DataLockMode.Shared;
			
		EndIf;
		
	EndDo;
	
	Block.Lock();
	
EndProcedure

// Deprecated. The platform method should be used to set the Monopoly mode (False).
Procedure UnlockCurDataArea() Export
	
	Var_Key = CreateAuxiliaryDataInformationRegisterEntryKey(
		InformationRegisters.DataAreas,
		New Structure(AuxiliaryDataSeparator(), SessionSeparatorValue()));
		
	UnlockDataForEdit(Var_Key);
	
	SetExclusiveMode(False);
	
EndProcedure

// Deprecated. Writes a reference-type value separated by the delimiter of
// the help data Separator, and switches the session split to the recording time.
//
// Parameters:
//  AuxiliaryDataObject - CatalogObject
//  							- ChartOfCharacteristicTypesObject
//  							- DocumentObject - an object of a reference type or the deletion of an object.
//
Procedure WriteAuxiliaryData(AuxiliaryDataObject) Export
	
	AuxiliaryDataObject.Write();
	
EndProcedure

// Deprecated. Deletes reference-type values separated by the help data Delimiter and
// switches the session split to write time.
//
// Parameters:
//  AuxiliaryDataObject - CatalogObject
//  							- ChartOfCharacteristicTypesObject
//  							- DocumentObject - an object of the reference type.
//
Procedure DeleteAuxiliaryData(AuxiliaryDataObject) Export
	
	AuxiliaryDataObject.Delete();
	
EndProcedure

// Deprecated. You should use the work of the Service model.Get the Service Manager's filesrelease
// Retrieves the file description by its ID in the Files register.
// If the storage on disk and the path of the data place = True, 
// in the output structure Data = Undefined, full name = Full file name,
// otherwise Data - binary file data, full name - Undefined.
// The value of the Name key always contains the name in the storage.
//
// Parameters:
//   FileID - UUID - unique identifier of the file,
//   ConnectionParameters - Structure - Fields:
//							* URL - String - The service URL must be present and filled in,
//							* UserName - String - service user name,
//							* Password - String - service user password,
//   PathInsteadOfData - Boolean - what to return,
//   CheckForExistence - Boolean - check whether the file exists in case of an error when it is received.
//		
// Returns:
//   Structure - File description:
//	   * Name - String - name of the file in the storage.
//	   * Data - BinaryData - File data.
//	   * FullName - String - full name of the file (the file will be deleted automatically after the temporary file storage period expires).
//
Function GetFileFromStorage(Val FileID, Val ConnectionParameters, 
	Val PathInsteadOfData = False, Val CheckForExistence = False) Export
	
	ExecutionStarted = CurrentUniversalDate();
	
	ProxyDescription = DescriptionOfFileTransferProxyService(ConnectionParameters);
	
	ExchangeViaFS = CanBeTransmittedViaFSSServer(ProxyDescription.Proxy, ProxyDescription.ThereIsSupportFor2ndVersion);
	
	If ExchangeViaFS Then
			
		Try
			Try
				FileName = ProxyDescription.Proxy.WriteFileToFS(FileID);
			Except
				ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				If CheckForExistence And Not ProxyDescription.Proxy.FileExists(FileID) Then
					Return Undefined;
				EndIf;
				Raise ErrorDescription;
			EndTry;
			
			FileProperties = New File(FilesCTL.SharedDirectoryOfTemporaryFiles() + FileName);
			If FileProperties.Exists() Then
				FileDetails = CreateFileDescription();
				FileDetails.Name = FileProperties.Name;
				
				SizeOfReceivedFile = FileProperties.Size();
				
				If PathInsteadOfData Then
					FileDetails.Data = Undefined;
					FileDetails.FullName = FileProperties.FullName;
				Else
					FileDetails.Data = New BinaryData(FileProperties.FullName);
					FileDetails.FullName = Undefined;
					Try
						DeleteFiles(FileProperties.FullName);
					Except
						WriteLogEvent(LogEventRetrievingFileFromStorage(),
							EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					EndTry;
				EndIf;
				
				LogFileStorageEvent(
					NStr("vi = 'Lấy ra';
						|ru = 'Извлечение';
						|en = 'Extract'; fa = 'Extract';
						|it = 'Estrazione';
						|pl = 'Extract';
						|tr = 'Çıkarma'", Common.DefaultLanguageCode()),
					FileID,
					SizeOfReceivedFile,
					CurrentUniversalDate() - ExecutionStarted,
					ExchangeViaFS);
				
				Return FileDetails;
			Else
				ExchangeViaFS = False;
			EndIf;
		Except
			WriteLogEvent(LogEventRetrievingFileFromStorage(),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			ExchangeViaFS = False;
		EndTry;
			
	EndIf; // ExchangeViaFS
	
	PartCount = Undefined;
	FileTransferBlockSize = GetFileTransferBlockSize();
	Try
		If ProxyDescription.ThereIsSupportFor2ndVersion Then
			TransferID = ProxyDescription.Proxy.PrepareGetFile(FileID, FileTransferBlockSize * 1024, PartCount);
		Else
			TransferID = Undefined;
			ProxyDescription.Proxy.PrepareGetFile(FileID, FileTransferBlockSize * 1024, TransferID, PartCount);
		EndIf;
	Except
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		If CheckForExistence And Not ProxyDescription.Proxy.FileExists(FileID) Then
			Return Undefined;
		EndIf;
		Raise ErrorDescription;
	EndTry;
	
	FilesNames = New Array;
	
	BuildDirectory = CreateAssemblyDirectory();
	
	If ProxyDescription.ThereIsSupportFor2ndVersion Then
		For PartNumber = 1 To PartCount Do
			PartData = ProxyDescription.Proxy.GetFilePart(TransferID, PartNumber, PartCount);
			PartFileName = BuildDirectory + "part" + Format(PartNumber, "ND=4; NLZ=; NG=");
			If TypeOf(PartData) = Type("BinaryData") Then
				PartData.Write(PartFileName);
			EndIf;
			FilesNames.Add(PartFileName);
		EndDo;
	Else // 1st version.
		For PartNumber = 1 To PartCount Do
			PartData = Undefined;
			ProxyDescription.Proxy.GetFilePart(TransferID, PartNumber, PartData);
			PartFileName = BuildDirectory + "part" + Format(PartNumber, "ND=4; NLZ=; NG=");
			If TypeOf(PartData) = Type("BinaryData") Then
				PartData.Write(PartFileName);
			EndIf;
			FilesNames.Add(PartFileName);
		EndDo;
	EndIf;
	PartData = Undefined;
	
	ProxyDescription.Proxy.ReleaseFile(TransferID);
	
	ArchiveName = GetTempFileName("zip");
	
	Try
	
		MergeFiles(FilesNames, ArchiveName);
		FileMerged = True;
		
	Except
		
		FileMerged = False;
		WriteLogEvent(NStr("vi = 'Thực hiện thao tác hợp nhất tệp';
							|ru = 'Выполнение операции объединения файлов';
							|en = 'Merging files'; fa = 'Merging files';
							|it = 'Compimento dell''operazione di unione dei file';
							|pl = 'Przeprowadzanie operacji scalania plików';
							|tr = 'Dosya birleştirme işlemi yürütülüyor'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
	EndTry;
	
	If FileMerged Then
		
		Try
		
			ZipFileReader = New ZipFileReader(ArchiveName);
			ZipFileRead = True;
			
		Except
			
			ZipFileRead = False;
			WriteLogEvent(NStr("vi = 'Thực hiện thao tác đọc tệp zip';
								|ru = 'Выполнение операции чтения zip файла';
								|en = 'Reading zip file'; fa = 'Reading zip file';
								|it = 'Compimento dell''operazione di lettura del file zip';
								|pl = 'Przeprowadzanie operacji odczytu pliku zip';
								|tr = 'Zip dosya okuma işlemi yürütülüyor'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
		EndTry;
		
		If ZipFileRead Then
			
			ResultingArchiveContainsMoreThanOneFile = ZipFileReader.Items.Count() > 1;
			
			If Not ResultingArchiveContainsMoreThanOneFile Then
				
				FileName = BuildDirectory + ZipFileReader.Items.Get(0).Name;
				ZipFileReader.Extract(ZipFileReader.Items.Get(0), BuildDirectory);
				ZipFileReader.Close();
				
				ResultFile = New File(GetTempFileName());
				MoveFile(FileName, ResultFile.FullName);
				SizeOfReceivedFile = ResultFile.Size();
				
				FileDetails = CreateFileDescription();
				FileDetails.Name = ResultFile.Name;
				
				If PathInsteadOfData Then
					
					FileDetails.Data = Undefined;
					FileDetails.FullName = ResultFile.FullName;
					
				Else
					
					FileDetails.Data = New BinaryData(ResultFile.FullName);
					FileDetails.FullName = Undefined;
					
					Try
						
						DeleteFiles(ResultFile.FullName);
						
					Except
						
						WriteLogEvent(LogEventRetrievingFileFromStorage(),
							EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
							
					EndTry;
						
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	FileIsTemporary = New File(ArchiveName);
	
	If FileIsTemporary.Exists() Then
		
		Try
			
			FileIsTemporary.SetReadOnly(False);
			DeleteFiles(ArchiveName);
			
		Except
			
			WriteLogEvent(NStr("vi = 'Thực hiện thao tác xóa tệp tạm thời';
								|ru = 'Выполнение операции удаления временного файла';
								|en = 'Deleting temporary file'; fa = 'Deleting temporary file';
								|it = 'Compimento dell''operazione di eliminazione del file temporaneo';
								|pl = 'Przeprowadzanie operacji usuwanie pliku tymczasowego';
								|tr = 'Geçici dosya siliniyor'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
		EndTry;
		
	EndIf;
	
	Try
		
		DeleteFiles(BuildDirectory);
		
	Except
		
		WriteLogEvent(LogEventRetrievingFileFromStorage(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
	EndTry;
		
	If Not ZipFileRead Then
		
		Raise(NStr("vi = 'Khi đọc tệp zip, đã xảy ra lỗi.';
					|ru = 'При чтении zip файла произошла ошибка.';
					|en = 'An error occurred when reading zip file.'; fa = 'An error occurred when reading zip file.';
					|it = 'Errore durante la lettura del file zip.';
					|pl = 'Wystąpił błąd podczas odczytu pliku zip.';
					|tr = 'Zip dosya okunurken bir hata oluştu.'"));
		
	EndIf;
	
	If ResultingArchiveContainsMoreThanOneFile Then
		
		Raise(NStr("vi = 'Trong tệp nén có chứa hơn một tệp.';
					|ru = 'В полученном архиве содержится более одного файла.';
					|en = 'The archive contains more than one file.'; fa = 'The archive contains more than one file.';
					|it = 'Nell''archivio ricevuto è presente più di un file.';
					|pl = 'Wynikowe archiwum zawiera więcej niż jeden plik.';
					|tr = 'Elde edilen arşivde birden fazla dosya bulunmaktadır.'"));
		
	EndIf;
	
	LogFileStorageEvent(
		NStr("vi = 'Lấy ra';
			|ru = 'Извлечение';
			|en = 'Extract'; fa = 'Extract';
			|it = 'Estrazione';
			|pl = 'Extract';
			|tr = 'Çıkarma'", Common.DefaultLanguageCode()),
		FileID,
		SizeOfReceivedFile,
		CurrentUniversalDate() - ExecutionStarted,
		ExchangeViaFS);
	
	Return FileDetails;
	
EndFunction

// Deprecated. You should use the work of the Service model.Place the file in the storage of the Service manager
// Adds a file to the storage of the service manager.
//
// Parameters:
//  AddressDataFile - String, BinaryData, File - Line/Binary data/file-temporary storage Address/File data/File.
//  ConnectionParameters - Structure - With Fields:
//   * URL - String - URL of the service. It must be present and filled in.
//	 * UserName - String - Name of the service user.
//	 * Password - String - Password of the service user.
//  FileName - String - the stored file name.
//
// Returns:
// UUID - id of the file in the repository.
//
Function PutFileInStorage(Val AddressDataFile, Val ConnectionParameters, Val FileName = "") Export
	
	DeleteTemporaryFile = False;
	ExecutionStarted = CurrentUniversalDate();
	
	ProxyDescription = DescriptionOfFileTransferProxyService(ConnectionParameters);
	
	LongDesc = GetNameOfDataFile(AddressDataFile, FileName);
	
	If IsBlankString(LongDesc.Name) Then
		
		LongDesc.Name = GetTempFileName();
		DeleteTemporaryFile = True;
		
	EndIf;
	
	FileProperties = New File(LongDesc.Name);
	
	ExchangeViaFS = CanBeTransmittedViaFSToServer(ProxyDescription.Proxy, ProxyDescription.ThereIsSupportFor2ndVersion);
	
	If ExchangeViaFS Then
		
		// Save the data to a file.
		CommonDirectory = FilesCTL.SharedDirectoryOfTemporaryFiles();
		TargetFile = New File(CommonDirectory + FileProperties.Name);
		If TargetFile.Exists() Then
			// It's the same file. You can immediately read it on the server without transmitting it.
			If FileProperties.FullName = TargetFile.FullName Then
				Result = ProxyDescription.Proxy.ReadFileFromFS(TargetFile.Name, FileProperties.Name);
				SourceFileSize = TargetFile.Size();
				LogFileStorageEvent(
					NStr("vi = 'Nhà kho';
						|ru = 'Помещение';
						|en = 'Put'; fa = 'Put';
						|it = 'Locale';
						|pl = 'Put';
						|tr = 'Tesis'", Common.DefaultLanguageCode()),
					Result,
					SourceFileSize,
					CurrentUniversalDate() - ExecutionStarted,
					ExchangeViaFS);
				Return Result;
				// It cannot be deleted, since it is also the source.
			EndIf;
			// The source and receiver are different files. In order not to erase someone else's file, we make the receiver a unique name.
			NewID = New UUID;
			TargetFile = New File(CommonDirectory + NewID + FileProperties.Extension);
		EndIf;
		
		Try
			If LongDesc.Data = Undefined Then
				CopyFile(FileProperties.FullName, TargetFile.FullName);
			Else
				LongDesc.Data.Write(TargetFile.FullName);
			EndIf;
			Result = ProxyDescription.Proxy.ReadFileFromFS(TargetFile.Name, FileProperties.Name);
			SourceFileSize = TargetFile.Size();
			LogFileStorageEvent(
				NStr("vi = 'Nhà kho';
					|ru = 'Помещение';
					|en = 'Put'; fa = 'Put';
					|it = 'Locale';
					|pl = 'Put';
					|tr = 'Tesis'", Common.DefaultLanguageCode()),
				Result,
				SourceFileSize,
				CurrentUniversalDate() - ExecutionStarted,
				ExchangeViaFS);
		Except
			WriteLogEvent(LogEventAddFileExchangeViaFS(),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			ExchangeViaFS = False;
		EndTry;
		
		DeleteTempFiles(TargetFile.FullName);
		If DeleteTemporaryFile Then
			DeleteTempFiles(LongDesc.Name)
		EndIf;
		
	EndIf; // ExchangeViaFS
		
	If Not ExchangeViaFS Then
		
		If LongDesc.Data = Undefined Then
			
			If FileProperties.Exists() Then
				
				BuildDirectory = Undefined;
				FullFileName = FileProperties.FullName;
				
			Else
				
				Raise(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Thêm tệp vào kho chứa. Không tìm thấy tệp %1.';
						|ru = 'Добавление файла в хранилище. Не найден файл %1.';
						|en = 'Add file to the storage. File %1 not found.'; fa = 'Add file to the storage. File %1 not found.';
						|it = 'Aggiunta del file all''archivio. File non trovato %1.';
						|pl = 'Dodawanie pliku do repozytorium. Nie znaleziono pliku %1.';
						|tr = 'Dosyayı depolama alanına ekle. %1 dosya bulunamadı.'"),
					FileProperties.FullName));
					
			EndIf;
				
		Else
			
			Try
				
				BuildDirectory = CreateAssemblyDirectory();
				FullFileName = BuildDirectory + FileProperties.Name;
				LongDesc.Data.Write(FullFileName);
				
			Except
				
				DeleteTempFiles(BuildDirectory);
				Raise;
				
			EndTry;
			
		EndIf;
		
		// Archive the file.
		Try
			
			ArchiveFileName = GetTempFileName("zip");
			Archiver = New ZipFileWriter(ArchiveFileName,,,, ZIPCompressionLevel.Minimum);
			Archiver.Add(FullFileName);
			Archiver.Write();
			
		Except
			
			If DeleteTemporaryFile Then
				
				DeleteTempFiles(LongDesc.Name);
				
			EndIf;
			
			DeleteTempFiles(ArchiveFileName);

			If ValueIsFilled(BuildDirectory) Then
				
				DeleteTempFiles(BuildDirectory);
				
			EndIf;
			
			Raise;
				
		EndTry;
		
		If DeleteTemporaryFile Then
			
			DeleteTempFiles(LongDesc.Name);
			
		EndIf;
		
		If ValueIsFilled(BuildDirectory) Then
			
			DeleteTempFiles(BuildDirectory);
			
		EndIf;
		
		FileTransferBlockSize = GetFileTransferBlockSize() * 1024 * 1024;
		TransferID = New UUID;
		
		ArchiveFile1 = New File(ArchiveFileName);
		ArchiveFileSize = ArchiveFile1.Size();
		
		PartCount = Round((ArchiveFileSize / FileTransferBlockSize) + 0.5, 0, RoundMode.Round15as10);
		
		ReaderStream = Undefined;
		
		Try
			
			ReaderStream = FileStreams.OpenForRead(ArchiveFileName);
			ReaderStream.Seek(0, PositionInStream.Begin);
			
			PartNumber = 0;
			
			While ReaderStream.CurrentPosition() < ArchiveFileSize - 1 Do
				
				PartNumber = PartNumber + 1;
				Buffer = New BinaryDataBuffer(Min(FileTransferBlockSize, ArchiveFileSize - ReaderStream.CurrentPosition()));
				ReaderStream.Read(Buffer, 0, Buffer.Size);
				
				AttemptsNumber = 10;
				
				For AttemptNumber = 1 To AttemptsNumber Do
				
					Try
						
						If ProxyDescription.ThereIsSupportFor2ndVersion Then
							
							ProxyDescription.Proxy.PutFilePart(TransferID, PartNumber, GetBinaryDataFromBinaryDataBuffer(Buffer), PartCount);
							
						Else // 1st version.
							
							ProxyDescription.Proxy.PutFilePart(TransferID, PartNumber, GetBinaryDataFromBinaryDataBuffer(Buffer));
							
						EndIf;
						
						Break;
						
					Except
						
						If AttemptNumber = AttemptsNumber Then
							
							Raise;
							
						EndIf;
						
					EndTry;
					
				EndDo;
				
			EndDo;
			
		Except
			
			If ReaderStream <> Undefined Then
				
				ReaderStream.Close();
				
			EndIf;
			
			ExceptionDetails = ErrorDescription();
			
			DeleteTempFiles(ArchiveFileName);
			
			Try
				
				ProxyDescription.Proxy.ReleaseFile(TransferID);
				
			Except
				
				ExceptionDetails = ExceptionDetails + Chars.LF + ErrorDescription();
				
			EndTry;
			
			Raise ExceptionDetails;
			
		EndTry;
		
		ReaderStream.Close();
		DeleteTempFiles(ArchiveFileName);
		
		If ProxyDescription.ThereIsSupportFor2ndVersion Then
			
			Result = ProxyDescription.Proxy.SaveFileFromParts(TransferID, PartCount);
			
		Else // 1st version.
			
			Result = Undefined;
			ProxyDescription.Proxy.SaveFileFromParts(TransferID, PartCount, Result);
			
		EndIf;
		
		LogFileStorageEvent(
			NStr("vi = 'Nhà kho';
				|ru = 'Помещение';
				|en = 'Put'; fa = 'Put';
				|it = 'Locale';
				|pl = 'Put';
				|tr = 'Tesis'", Common.DefaultLanguageCode()),
			Result,
			SourceFileSize,
			CurrentUniversalDate() - ExecutionStarted,
			ExchangeViaFS);
		
	EndIf; // Not exchangereferences
	
	Return Result;
	
EndFunction

#EndRegion

// Checking the blocking of the data area at startup.
// Only for calling from a standard undersystem Server.Add the parameters of the work when you start().
// 
// Parameters:
//  ErrorDescription - String - Error description text
Procedure OnCheckDataAreaLockOnStart(ErrorDescription) Export
	
	If DataSeparationEnabled()
			And SeparatedDataUsageAvailable()
			And DataAreaLocked(SessionSeparatorValue()) Then
		
		ErrorDescription =
			NStr("vi = 'Tính năng khởi chạy ứng dụng tạm thời không khả dụng. 
			           | Đang tiến hành bảo trì ứng dụng.
			           |
			           |Hãy thử khởi chạy ứng dụng sau vài phút.';
			           |ru = 'Запуск приложения временно недоступен.
			           |Выполняются регламентные операции по обслуживанию приложения.
			           |
			           |Попробуйте запустить приложение через несколько минут.';
			           |en = 'Cannot start the application.
			           |Scheduled jobs are running.
			           |
			           |Please wait a few minutes and restart the application.'; fa = 'Cannot start the application.
			           |Scheduled jobs are running.
			           |
			           |Please wait a few minutes and restart the application.';
			           |it = 'Al momento non è possibile avviare l''applicazione.
			           | Le operazioni relative al servizio dell''applicazione sono completate. 
			           |
			           | Riprovare ad avviare l''applicazione fra qualche minuto.';
			           |pl = 'Uruchamianie aplikacji jest tymczasowo niedostępne.
			           |Wykonywane są planowe prace konserwacyjne z obsługi aplikacji.
			           |
			           |Spróbuj uruchomić aplikację za kilka minut.';
			           |tr = 'Uygulamayı geçici olarak çalıştırılamıyor. 
			           | Rutin uygulama bakım işlemleri gerçekleştirilir. 
			           |
			           |Birkaç dakika içinde uygulamayı çalıştırmayı deneyin.'");
		
	EndIf;
	
EndProcedure

// Returns a collection of data areas used by users.
//	The areas used by users are determined by the installed application type for the area
//
// Returns:
//   QueryResult - the result of a query containing a list of data areas.
//
Function UsersUsedDataAreas() Export
	Query = New Query();
	Query.Text = 
	"SELECT
	|	DataAreas.DataAreaAuxiliaryData AS DataArea
	|FROM
	|	InformationRegister.DataAreas AS DataAreas
	|		INNER JOIN InformationRegister.DataAreasAppTypes AS DataAreasAppTypes
	|		ON DataAreas.DataAreaAuxiliaryData = DataAreasAppTypes.DataAreaAuxiliaryData
	|WHERE
	|	DataAreas.Status = VALUE(Enum.DataAreaStatuses.Used)
	|ORDER BY
	|	DataArea";
	
	Result = Query.Execute();
	
	Return Result;
EndFunction

// Returns an indication that the data area is being used by users.
// The areas used by users are determined by the installed application type for the area
//
// Parameters:
//  DataArea -  Number - the value of the separator for the data area 
//   that users want to use to get.
//
// Returns:
//  Boolean
//
Function DataAreaIsUsedByUsers(DataArea) Export
			
	Query = New Query;
	Query.Text =
		"SELECT TOP 1
		|	DataAreas.Status AS Status
		|FROM
		|	InformationRegister.DataAreas AS DataAreas
		|		INNER JOIN InformationRegister.DataAreasAppTypes AS DataAreasAppTypes
		|		ON DataAreas.DataAreaAuxiliaryData = DataAreasAppTypes.DataAreaAuxiliaryData
		|WHERE
		|	DataAreas.DataAreaAuxiliaryData = &DataArea
		|	AND DataAreas.Status = VALUE(Enum.DataAreaStatuses.Used)";
	Query.SetParameter("DataArea", DataArea);
	QueryResult = Query.Execute();
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

#EndRegion

#Region Internal

// Deletes all data in the data area, sets the Status deleted for the data area,
// and sends a message to the service manager with information about the change in the Status of the area.
// After that, the data area will be unusable.
//
// If you need to delete all the data of an area without changing its Status and while maintaining the possibility
//  of further use of the area, you must use the procedure to clear these areas().
//
// Parameters: 
//  DataArea - Number - the delimiter value of the data area to be erased.
//   When the procedure is called, data separation should already be switched to this area.
//
Procedure ClearDataArea(DataArea) Export
	
	If Not Users.IsFullUser(, True) Then
		Raise(NStr("vi = 'Không đủ quyền để thực hiện thao tác';
					|ru = 'Недостаточно прав для выполнения операции';
					|en = 'Insufficient rights to perform the operation.'; fa = 'Insufficient rights to perform the operation.';
					|it = 'Diritti insufficienti per eseguire l''operazione';
					|pl = 'Niewystarczające uprawnienia do wykonania operacji';
					|tr = 'İşlem için gerekli yetkiler yok'"));
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	AreaKey = CreateAuxiliaryDataInformationRegisterEntryKey(
		InformationRegisters.DataAreas,
		New Structure(AuxiliaryDataSeparator(), DataArea));
	LockDataForEdit(AreaKey);
	
	Try
		
		RecordManager = GetDataAreaRecordManager(
			DataArea,
			Enums.DataAreaStatuses.ForDeletion);
		
		SaaSOperationsOverridable.OnDeleteDataArea(DataArea);
		
		ClearAreaData();
		
		ChangeAreaStatusAndNotifyManager(RecordManager, "AreaRemoved", "");
		
	Except
		UnlockDataForEdit(AreaKey);
		Raise;
	EndTry;
	
	UnlockDataForEdit(AreaKey);
	
EndProcedure

Procedure ClearAreaData(ExtensionsDeleting = True, DeleteCurrentUser = True) Export
	
	If DataSeparationEnabled() Then
		
		DeleteApplicationData();
		
	Else
		
		ClearInformationDatabaseData(ExtensionsDeleting, DeleteCurrentUser);
		
	EndIf;
	
EndProcedure

Procedure CreateTaskToClearDataArea(DataArea) Export
	
	MethodParameters = New Array;
	MethodParameters.Add(DataArea);
	
	JobParameters = New Structure();
	JobParameters.Insert("MethodName", ClearDataAreaMethodName());
	JobParameters.Insert("Parameters", MethodParameters);
	JobParameters.Insert("Key", "1");
	JobParameters.Insert("DataArea", DataArea);
	JobParameters.Insert("ExclusiveExecution", True);
	
	JobsQueue.AddJob(JobParameters);
	
EndProcedure

// Returns a list of the full names of all metadata objects that are used in the common delimiter attribute,
//  the name of which is passed as the value of the Delimiter parameter, and the values of the metadata object properties
//  that may be required for further processing in universal algorithms.
// For document sequences and logs, defines the separation by incoming documents: any of them.
//
// Parameters:
//  Separator - String - name of the shared property.
//
// Returns:
// FixedMap of KeyAndValue:
//  * Key - String - full name of the metadata object,
//  * Value - FixedStructure:
//    ** Name - String - name of the metadata object,
//    ** Separator - String - name of the separator that separates the metadata object,
//    ** ConditionalSeparation - String - the full name of the metadata object that serves as a condition for using
//      this separator to separate the metadata object.
//
Function SeparatedMetadataObjects(Val Separator) Export
	
	Return SaaSOperationsCached.SeparatedMetadataObjects(Separator);
	
EndFunction

// Parameters:
//  MetadataJob - MetadataObject - metadata of a predefined routine task.
//  Use     - Boolean - True if the task needs to be enabled, otherwise False.
//
Procedure SetPredefinedScheduledJobUsage(MetadataJob, Use) Export
	
	Template = JobsQueue.TemplateByName_(MetadataJob.Name);
	
	FilterJobs = New Structure;
	FilterJobs.Insert("Template", Template);
	Jobs = JobsQueue.GetJobs(FilterJobs);
	
	If Jobs.Count() = 0 Then
		ExclusiveModeSet = ExclusiveMode();
		If Not ExclusiveModeSet Then
			Try
				SetExclusiveMode(True);
				ExclusiveModeSet = True;
			Except
				ExclusiveModeSet = False;
			EndTry;
		EndIf;
		If ExclusiveMode() Then
			Try
				JobsQueueInternalDataSeparation.CreateQueueJobsUsingTemplatesInCurScope();
				UpdateComplete = True;
			Except
				UpdateComplete = False;
			EndTry;
			If UpdateComplete Then
				Jobs = JobsQueue.GetJobs(FilterJobs);
			EndIf;
		EndIf;
		If ExclusiveModeSet Then
			SetExclusiveMode(False);
		EndIf;
	EndIf;
	If Jobs.Count() = 0 Then
		MessageTemplate = NStr("vi = 'Không tìm thấy nhiệm vụ ở hàng đợi đối với nhiệm vụ định trước có tên %1';
								|ru = 'Не найдено задание в очереди для предопределенного задания с именем %1';
								|en = 'Job in the queue for predefined job with the %1 name is not found.'; fa = 'Job in the queue for predefined job with the %1 name is not found.';
								|it = 'Il processo in coda per il processo predefinito con nome %1 non è stato trovato';
								|pl = 'Nie znaleziono pracy w kolejce dla predefiniowanego zadania o nazwie %1';
								|tr = '%1 adına sahip önceden tanımlanmış görev için sırada görev bulunamadı'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, MetadataJob.Name);
		Raise(MessageText);
	EndIf;
	
	JobParameters = New Structure("Use", Use);
	JobsQueue.ChangeJob(Jobs.Get(0).Id, JobParameters);
	
EndProcedure

// Checks whether the configuration can be used in the service model.
//  If it can't be used, an exception is thrown indicating the reason
//  why the configuration cannot be used in the service model.
//
Procedure CheckIfConfigurationCanBeUsedInServiceModel() Export
	
	SubsystemsDetails = Common.SubsystemsDetails(); // Array of Structure
	
	DetailsCTL = Undefined;
	
	For Each SubsystemDetails In SubsystemsDetails Do
		
		If SubsystemDetails.Name = "CloudTechnologyLibrary" Then
			
			DetailsCTL = SubsystemDetails;
			Break;
			
		EndIf;
		
	EndDo;
	
	If DetailsCTL = Undefined Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Cấu hình không có trong thư viện ""1C: Thư viện Công nghệ Dịch vụ""
                  | Nếu không triển khai thư viện này, cấu hình không thể được sử dụng trong mô hình dịch vụ.
                  |
                  |Để sử dụng cấu hình này trong mô hình dịch vụ, nó bắt buộc phải triển khai thư viện 
                  |""1C: Thư viện Công nghệ Dịch vụ"" phiên bản không ít hơn %1.';
                  |ru = 'В конфигурацию не внедрена библиотека ""1С:Библиотека технологии сервиса"".
                  |Без внедрения этой библиотеки конфигурация не может использоваться в модели сервиса.
                  |
                  |Для использования этой конфигурации в модели сервиса требуется внедрить библиотеку
                  |""1С:Библиотека технологии сервиса"" версии не младше %1.';
                  |en = '1C:Cloud Technology Library was not integrated into the configuration.
                  |
                  |To use the configuration in SaaS, integrate 1C:Cloud Technology Library version %1 or later.'; fa = '1C:Cloud Technology Library was not integrated into the configuration.
                  |
                  |To use the configuration in SaaS, integrate 1C:Cloud Technology Library version %1 or later.';
                  |it = 'Nella configurazione non è implementata la biblioteca: ""1C:Libreria della tecnologia del servizio"".
                  |Senza l''implementazione di questa libreria, la configurazione non può essere utilizzata nel modello di servizio.
                  |
                  |Per utilizzare questa configurazione nel modello di servizio, è necessario implementare la libreria
                  |""1C:Libreria della tecnologia del servizio"", versione non precedente a %1.';
                  |pl = 'W konfigurację nie została wdrożona biblioteka ""1C:Biblioteka technologii usługi"".
                  |Bez wdrożenia tej biblioteki konfiguracja nie może być stosowana w modelu usługi.
                  |
                  |Aby skorzystać z tej konfiguracji w modelu usług wymaga się wprowadzenia biblioteki
                  |""1C:Biblioteka technologii usługi"" w wersji nie niżej %1.';
                  |tr = 'Yapılandırma, entegre 1C:Service Technology Library içermez. 
                  |Bu kütüphane entegre değilse, yapılandırma hizmet modelinde kullanılamaz.
                  |
                  | Bu yapılandırmayı hizmet modelinde kullanmak için, 
                  | sürüm veya daha eski sürüm 1C:Service Technology Library %1 entegre edilmelidir!'", Metadata.DefaultLanguage.LanguageCode),
			RequiredCTLVersion());
		
	Else
		
		CTLVersion = DetailsCTL.Version;
		
		If CommonClientServer.CompareVersions(CTLVersion, RequiredCTLVersion()) < 0 Then
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Để sử dụng cấu hình trong mô hình dịch vụ với phiên bản Thư viện phân hệ chuẩn hiện tại,
                      |cập nhật phiên bản đã sử dụng của thư viện ""1C:Thư viện Công nghệ Dịch vụ"". 
                      |
                      |Phiên bản đã sử dụng: %1, cần có phiên bản ít nhất %2.';
                      |ru = 'Для использования конфигурации в модели сервиса с текущей версией БСП требуется
                      |обновить используемую версию библиотеки ""1С:Библиотека технологии сервиса"".
                      |
                      |Используемая версия: %1, требуется версия не младше %2.';
                      |en = 'To use the configuration in SaaS with the current SSL version,
                      |update the current version of library 1C:Cloud Technology Library.
                      |
                      |Current version: %1, version not earlier than %2 is required.'; fa = 'To use the configuration in SaaS with the current SSL version,
                      |update the current version of library 1C:Cloud Technology Library.
                      |
                      |Current version: %1, version not earlier than %2 is required.';
                      |it = 'Per utilizzare la configurazione nel modello di servizio con la versione corrente della Libreria dei Sottosistemi Standard
                      |, è necessario aggiornare la versione utilizzata della libreria ""1C:Libreria dei sottosistemi standard""! 
                      |
                      |Versione utilizzata: %1, è richiesta una versione non precedente a %2.';
                      |pl = 'Do użytku konfiguracji w modelu usługi z bieżącą wersją BSP wymaga się
                      |zaktualizować stosowaną wersję biblioteki ""1C:Biblioteka technologii usługi"".
                      |
                      |Stosowana wersja: %1, wymaga wersji nie niżej %2.';
                      |tr = 'CTL''nin 
                      |geçerli sürümüne sahip bir hizmet modelinde yapılandırmayı kullanmak için kullanılan 1C:Service Technology Library sürümünü güncellenmelidir. 
                      |
                      |Kullanılan sürüm: %1, gerekli sürüm %2 daha küçük değildir .'", Metadata.DefaultLanguage.LanguageCode),
				CTLVersion, RequiredCTLVersion());
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Throws an exception if the required subsystem is missing from the service technology library.
//
// Parameters:
//  SubsystemName - String - name of the subsystem. 
//
Procedure CauseExceptionMissingSubsystemCTL(Val SubsystemName) Export
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể thực hiện thao tác do hệ thống con ""%1"" không được triển khai trong cấu hình.
              |Hệ thống con này được cung cấp như một phần của thư viện công nghệ dịch vụ, phải được tích hợp riêng vào cấu hình.
              |Kiểm tra sự hiện diện và tính đúng đắn của việc triển khai hệ thống con ""%1"".';
              |ru = 'Невозможно выполнить операцию по причине - в конфигурации не внедрена подсистема ""%1"".
              |Данная подсистема поставляется в состав библиотеки технологии сервиса, которая должна отдельно внедряться в состав конфигурации.
              |Проверьте наличие и корректность внедрения подсистемы ""%1"".';
              |en = 'Cannot execute operation: subsystem ""%1"" is not implemented in the configuration.
              |This subsystem is included in service technology library which should be implemented separately in the configuration set.
              |Check the existence of subsystem ""%1"" and verify its proper implementation.'; fa = 'Cannot execute operation: subsystem ""%1"" is not implemented in the configuration.
              |This subsystem is included in service technology library which should be implemented separately in the configuration set.
              |Check the existence of subsystem ""%1"" and verify its proper implementation.';
              |it = 'Non è possibile completare l''operazione per il seguente motivo: nella configurazione non è implementata il sottosistema ""%1"". 
              | Tale sottosistema è fornito all''interno della libreria della tecnologia di servizio, la quale deve essere introdotta separatamente all''interno della configurazione. 
              |Verificare la presenza e la correttezza dell''inserimento del sottosistema ""%1"".';
              |pl = 'Nie można wykonać operacji z powodu - w konfiguracji nie został wdrożony podsystem ""%1"".
              |Ten podsystem jest dostarczany w skład biblioteki technologii serwisu, który powinien oddzielnie wdrażać się w skład konfiguracji.
              |Sprawdź dostępność i poprawność wdrożenia podsystemu ""%1"".';
              |tr = 'Bir nedenle işlem gerçekleştirilemiyor - yapılandırmada ""%1"" alt sistemi uygulanmadı. 
              |Bu alt sistem, yapılandırmanın bir parçası olarak ayrı ayrı uygulanması gereken hizmet teknolojisi kütüphanesinin bir parçası olarak gelir. 
              | ""%1"" Alt sistemin uygulanmasının kullanılabilirliğini ve doğruluğunu kontrol edin.'"),
		SubsystemName);
	
EndProcedure

// Raises an exception if there is no suitable extension of the service technology library
//
Procedure CauseExceptionMissingExtensionCTL() Export

	ExtensionVersion = CloudTechnology.LibraryExtensionVersion();
	If ValueIsFilled(ExtensionVersion) Then
		ErrorText = StrTemplate(NStr(
		"vi = 'Không thể thực hiện thao tác: phiên bản hiện tại %1 của tiện ích mở rộng để hoạt động ở chế độ dịch vụ
		|không thích hợp để làm việc với phiên bản %2 của thư viện công nghệ dịch vụ';
		|ru = 'Невозможно выполнить операцию: текущая версия %1 расширения для работы в режиме сервиса
		|не подходит для работы с версией %2 библиотеки технологии сервиса';
		|en = 'Cannot perform the operation: the current version %1 of the SaaS mode extension
		|is not suitable for Cloud Technology Library version %2'; fa = 'Cannot perform the operation: the current version %1 of the SaaS mode extension
		|is not suitable for Cloud Technology Library version %2';
		|it = 'Impossibile eseguire l''operazione: la versione corrente %1 dell''estensione per il lavoro in modalità del servizio
		|non è adatta al lavoro con la versione %2 e biblioteca delle tecnologie del servizio';
		|pl = 'Nie można wykonać operacji: bieżąca wersja %1 rozszerzenia dla pracy w trybie serwisu
		|nie pasuje do pracy z wersją %2 biblioteki technologii serwisu';
		|tr = 'İşlem gerçekleştirilemiyor: hizmet modu uzantısının geçerli %1 sürümü
		|Bulut Teknolojisi Kütüphanesi %2 sürümüyle çalışmıyor'"), ExtensionVersion,
			CloudTechnology.LibraryVersion());
	Else
		ErrorText = NStr(
		"vi = 'Không thể thực hiện thao tác: tiện ích mở rộng thư viện công nghệ dịch vụ chưa được cài đặt 
		|để hoạt động ở chế độ dịch vụ';
		|ru = 'Невозможно выполнить операцию: не установлено расширение библиотеки технологии сервиса
		|для работы в режиме сервиса';
		|en = 'Cannot perform the operation: Cloud Technology Library extension
		|for SaaS mode is not installed'; fa = 'Cannot perform the operation: Cloud Technology Library extension
		|for SaaS mode is not installed';
		|it = 'Impossibile eseguire l''operazione: estensione BTS 
		| di lavoro in modalità servizio non installata';
		|pl = 'Nie można wykonać operacji: nie zainstalowano rozszerzenia biblioteki technologii serwisu
		|do pracy w trybie serwisu';
		|tr = 'İşlem gerçekleştirilemiyor: Bulut Teknolojisi Kütüphanesi uzantısı
		|hizmet modunda çalışacak şekilde yüklenmedi'");
	EndIf;

	Raise ErrorText;

EndProcedure

// Attempts to complete the request in several attempts.
// Used for reading frequently changed data outside of a transaction.
// When called in a transaction, it returns an error.
//
// Parameters:
//  Query - Query - the request to be executed.
//
// Returns:
//  QueryResult - the result of executing the request.
//
Function ExecuteQueryOutsideTransaction(Val Query) Export
	
	If TransactionActive() Then
		Raise(NStr("vi = 'Giao tác đang hoạt động. Không thể thực hiện truy vấn ngoài giao tác.';
					|ru = 'Транзакция активна. Выполнение запроса вне транзакции невозможно.';
					|en = 'The transaction is active. Cannot execute a query outside the transaction.'; fa = 'The transaction is active. Cannot execute a query outside the transaction.';
					|it = 'La transazione è attiva. Il completamento della richiesta al di fuori della transazione non è possibile.';
					|pl = 'Transakcja jest aktywna. Wykonywanie zapytania poza transakcją nie jest możliwe.';
					|tr = 'İşlem aktif. İşlemin dışında bir sorgu yürütülemiyor.'"));
	EndIf;
	
	AttemptsNumber = 0;
	
	Result = Undefined;
	While True Do
		Try
			Result = Query.Execute(); // Reading outside the transaction, an error may occur.
			                                // Could not continue scan with NOLOCK due to data movement
			                                // in this case, you need to retry reading.
			Break;
		Except
			AttemptsNumber = AttemptsNumber + 1;
			If AttemptsNumber = 5 Then
				Raise;
			EndIf;
		EndTry;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns an XML representation of the XDTO type.
//
// Parameters:
//  XDTOType - XDTOObjectType, XDTOValueType - the type of XDTO to get.
//   XML representation.
//
// Returns:
//  String - XML representation of type XDTO.
//
Function XDTOTypePresentation(XDTOType) Export
	
	Return XDTOSerializer.XMLString(New XMLExpandedName(XDTOType.NamespaceURI, XDTOType.Name))
	
EndFunction

// for internal use.
// Returns:
//	CommonAttributeContent - structure.
Function DataAreaMainDataContent() Export
	Return Metadata.CommonAttributes.DataAreaMainData.Content;
EndFunction

// for internal use.
// Returns:
//	Number - data area.
Function GetDataAreasQueryResult() Export
	Query = New Query();
	Query.Text = 
	"SELECT
	|	DataAreas.DataAreaAuxiliaryData AS DataArea
	|FROM
	|	InformationRegister.DataAreas AS DataAreas
	|WHERE
	|	DataAreas.Status = VALUE(Enum.DataAreaStatuses.Used)
	|ORDER BY
	|	DataArea";
	
	Result = Query.Execute();
	
	Return Result;
EndFunction

// The handler routine tasks
Procedure DeletingIrrelevantData() Export
	
	CauseExceptionMissingExtensionCTL();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Event handlers of configuration subsystems.

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert(MethodNamePrepareDataAreaForUse());
	NamesAndAliasesMap.Insert(ClearDataAreaMethodName());
	NamesAndAliasesMap.Insert("SaaSOperations.DeleteFile");
	
EndProcedure

// See JobsQueueOverridable.OnDefineScheduledJobsUsage.
// Parameters:
// 	UsageTable  - ValueTable - LongDesc:
//	 * ScheduledJob - String - the name of the routine task.
//	 * Use - Boolean - signs of use.
Procedure OnDefineScheduledJobsUsage(UsageTable) Export
	
	NewRow = UsageTable.Add();
	NewRow.ScheduledJob = "DataAreaMaintenance";
	NewRow.Use       = True;
	
	NewRow = UsageTable.Add();
	NewRow.ScheduledJob = "DeletingIrrelevantData";
	NewRow.Use       = True;
	
	NewRow = UsageTable.Add();
	NewRow.ScheduledJob = "HandlingUserAlerts";
	NewRow.Use       = True;
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.JobsQueue.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.Constants.DataAreaKey);
	Types.Add(Metadata.InformationRegisters.DataAreas);
	Types.Add(Metadata.Constants.InformationAboutImportProcedure);
	Types.Add(Metadata.Constants.ParametersForLaunchingInteractiveImportProcedure);
	Types.Add(Metadata.Constants.DataAreaPresentation);
	Types.Add(Metadata.InformationRegisters.TemporaryStorageFiles);
	Types.Add(Metadata.InformationRegisters.ServiceUserDetails);
	Types.Add(Metadata.InformationRegisters.ExportImportDataAreasStates);
	Types.Add(Metadata.InformationRegisters.ExportImportMetadataObjects);
	Types.Add(Metadata.Constants.ExclusiveLockSet);
	Types.Add(Metadata.InformationRegisters.ExportImportDataAreasParts);
	Types.Add(Metadata.InformationRegisters.TemporaryQueriesIDs);
	
EndProcedure

// See SaaSOperationsOverridable.OnEnableSeparationByDataAreas.
Procedure OnEnableSeparationByDataAreas() Export
	
	CheckIfConfigurationCanBeUsedInServiceModel();
	
	SaaSOperationsOverridable.OnEnableSeparationByDataAreas();
	
EndProcedure

// See SuppliedDataOverridable.GetHandlersForSuppliedData.
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
	
	RegisterSuppliedDataHandlers(Handlers);
	
EndProcedure

// Checking the safe mode of data separation.
// Only for calling from the session module.
//
Procedure OnCheckDataSeparationSafeModeEnabled() Export
	
	If SafeMode() = False
		And DataSeparationEnabled()
		And SeparatedDataUsageAvailable()
		And Not SessionWithoutSeparators() Then
		
		If Not DataSeparationSafeMode(AuxiliaryDataSeparator()) Then
			
			SetDataSeparationSafeMode(AuxiliaryDataSeparator(), True);
			
		EndIf;
		
		If Not DataSeparationSafeMode(MainDataSeparator()) Then
			
			SetDataSeparationSafeMode(MainDataSeparator(), True);
			
		EndIf;
	
	EndIf;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "SaaSOperations.ControllingDelimitersWhenUpdating";
	Handler.SharedData = True;
	Handler.ExecuteInMandatoryGroup = True;
	Handler.Priority = 99;
	Handler.ExclusiveMode = False;
	
	If DataSeparationEnabled() Then
		
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.Procedure = "SaaSOperations.CheckIfConfigurationCanBeUsedInServiceModel";
		Handler.SharedData = True;
		Handler.ExecuteInMandatoryGroup = True;
		Handler.Priority = 99;
		Handler.ExclusiveMode = False;
		
		Handler = Handlers.Add();
		Handler.Version = "2.0.6.6";
		Handler.Procedure = "SaaSOperations.DeleteArea0";
		Handler.SharedData = True;
		Handler.ExecuteInMandatoryGroup = True;
		Handler.Priority = 99;
		Handler.ExclusiveMode = False;
		
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	OnAddClientParameters(Parameters);
	
EndProcedure

// See CommonOverridable.OnAddClientParameters.
Procedure OnAddClientParameters(Parameters) Export
	
	If Not DataSeparationEnabled()
		Or Not SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DataAreaPresentation.Value AS Presentation
	|FROM
	|	Constant.DataAreaPresentation AS DataAreaPresentation
	|WHERE
	|	DataAreaPresentation.DataAreaAuxiliaryData = &DataAreaAuxiliaryData";
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Query.SetParameter("DataAreaAuxiliaryData", SessionSeparatorValue());
	// We consider the data conditionally immutable.
	Result = Query.Execute();
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	If Not Result.IsEmpty() Then
		Selection = Result.Select();
		Selection.Next();
		
		AddlInfo = New Array;
		
		SubscriberCode = SubscriberCode();
		If ValueIsFilled(SubscriberCode) Then
			AddlInfo.Add(StrTemplate(NStr("vi = 'thuê bao %1';
											|ru = 'абонент %1';
											|en = 'Subscriber %1'; fa = 'Subscriber %1';
											|it = 'Subscriber %1';
											|pl = 'Subscriber %1';
											|tr = '%1 abonesi'"), Format(SubscriberCode, "NZ=0; NG=0")));
		EndIf;
		
		ApplicationCode = SessionSeparatorValue();
		If ValueIsFilled(ApplicationCode) Then
			AddlInfo.Add(StrTemplate(NStr("vi = 'ứng dụng %1';
											|ru = 'приложение %1';
											|en = 'Application %1'; fa = 'Application %1';
											|it = 'Application %1';
											|pl = 'Application %1';
											|tr = '%1 uygulaması'"), Format(ApplicationCode, "NZ=0; NG=0")));
		EndIf;
		
		If AddlInfo.Count() > 0 Then
			DataAreaPresentation = StrTemplate("%1 [%2]", Selection.Presentation, StrConcat(AddlInfo, ", "));
		Else
			DataAreaPresentation = Selection.Presentation;
		EndIf;
		
		Parameters.Insert("DataAreaPresentation", DataAreaPresentation);
		
	EndIf;
	
EndProcedure

// See CTLSubsystemsIntegration.OnDefineSharedDataExceptions
// 
// Parameters:
//	Exceptions - Array of MetadataObject - Exceptions.
//
Procedure OnDefineSharedDataExceptions(Exceptions) Export
	
	Exceptions.Add(Metadata.InformationRegisters.DataOfClearedArea);
	Exceptions.Add(Metadata.InformationRegisters.ExportImportDataThreads);
	Exceptions.Add(Metadata.InformationRegisters.ScheduledQueueJobs);
	
EndProcedure

// See ExportImportDataOverridable.AfterImportData.
Procedure AfterImportData(Container) Export
	
	UsersInternal.AfterImportData(Container);
	
	If Common.SubsystemExists("StandardSubsystems.TotalsAndAggregatesManagement") Then
		
		ModuleName = "TotalsAndAggregatesManagementInternal";
		ModuleTotalsAndAggregatesInternal = Common.CommonModule(ModuleName);
		ModuleTotalsAndAggregatesInternal.CalculateTotals();
		
	EndIf;
	
EndProcedure

// Get the file size from the storage of the service manager.
// 
// Parameters:
//  FileID - UUID
// 
// Returns:
//  Undefined, Number - file size.
Function GetFileSizeFromServiceManagerStorage(FileID) Export
	
	ServiceManagerURL = InternalServiceManagerURL();
	
	If Not ValueIsFilled(ServiceManagerURL) Then
		
		Raise(NStr("vi = 'Chưa đặt tham số liên hệ với người quản lý dịch vụ.';
					|ru = 'Не установлены параметры связи с менеджером сервиса.';
					|en = 'Service manager connection parameters are not specified.'; fa = 'Service manager connection parameters are not specified.';
					|it = 'Le impostazioni di comunicazione con il gestore del servizio non sono state impostate.';
					|pl = 'Nie są ustanowione parametry połączenia z menedżerem serwisu.';
					|tr = 'Servis yöneticisiyle bağlantı parametreleri ayarlanmamış.'"));
		
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	StorageAccessSettings = New Structure;
	StorageAccessSettings.Insert("URL", ServiceManagerURL);
	StorageAccessSettings.Insert("UserName", ServiceManagerInternalUserName());
	StorageAccessSettings.Insert("Password", ServiceManagerInternalUserPassword());
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	If Common.SubsystemExists("CloudTechnology.DataTransfer") Then
		
		SupportedVersions = Common.GetInterfaceVersions(StorageAccessSettings, "DataTransfer");
		
		If SupportedVersions.Count() > 0 Then
			
			ModuleDataTransferServer = Common.CommonModule("DataTransferServer");
			Return ModuleDataTransferServer.GetFileSizeFromLogicalStorage(StorageAccessSettings, "files", FileID);
			
		EndIf;
		
	EndIf;
	
	// not supported
	Return Undefined;
	
EndFunction

Procedure ClearMetadataObjectData(FullMetadataObjectName, MetadataObjectDetails) Export

	If ThisIsFullNameOfConstant(FullMetadataObjectName) Then

		AreaMetadataObject = Metadata.Constants.Find(MetadataObjectDetails.Name);
		ValueManager = Constants[MetadataObjectDetails.Name].CreateValueManager();
		ValueManager.DataExchange.Load = True;
		ValueManager.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		ValueManager.AdditionalProperties.Insert("DontControlObjectsToDelete");
		ValueManager.Value = AreaMetadataObject.Type.AdjustValue();
		ValueManager.Write();

		DisableAndClearDataHistory(AreaMetadataObject);
		
	ElsIf ThisIsFullNameOfObjectOfReferenceType(FullMetadataObjectName) Then
		
		ObjectParameters = NewParametersOfObjectBeingDeleted();
		ObjectParameters.PredefinedSupported = IsFullNameOfObjectWithPredefinedData(
			FullMetadataObjectName);
		
		Manager = Common.ObjectManagerByFullName(FullMetadataObjectName);
		Selection = Manager.Select();
		
		While Selection.Next() Do

			RemovableObject = Selection.GetObject(); // CatalogObject
			If ExcludeObjectFromCleanup(RemovableObject, ObjectParameters) Then
				Continue;
			EndIf;
			
			DeleteDataObject(RemovableObject);

		EndDo;
		
		AreaMetadataObject = Metadata.FindByFullName(FullMetadataObjectName);
		DisableAndClearDataHistory(AreaMetadataObject);
		
	ElsIf ThisIsFullRegisterName(FullMetadataObjectName) Or ThisIsFullNameOfRecalculation(FullMetadataObjectName)
		Or ThisIsFullNameOfSequence(FullMetadataObjectName) Then

		IsAccumulationRegister = ThisIsFullNameOfAccumulationRegister(FullMetadataObjectName);
		IsAccountingRegister = ThisIsFullNameOfAccountingRegister(FullMetadataObjectName);
		IsInformationRegister = ThisIsFullNameOfInformationRegister(FullMetadataObjectName);

		Manager = Common.ObjectManagerByFullName(FullMetadataObjectName); // AccumulationRegisterManagerAccumulationRegisterName

		IsIndependentInformationRegister = False;
		RecalcTotals = False;

		If IsAccumulationRegister Then

			MetadataRegister = Metadata.AccumulationRegisters.Find(MetadataObjectDetails.Name);

			If MetadataRegister.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Balance Then

				If Manager.GetMinTotalsPeriod() <> '00010101'
					Or Manager.GetMaxTotalsPeriod() <> EndOfMonth('00010101') Then

					Manager.SetMinAndMaxTotalsPeriods('00010101', '00010101');

				EndIf;

				If Manager.GetPresentTotalsUsing() Then

					Manager.SetPresentTotalsUsing(False);

				EndIf;

				If Manager.GetTotalsUsing() Then

					Manager.SetTotalsUsing(False);

				EndIf;
			
			ElsIf MetadataRegister.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers Then 

				AggregateMode = Manager.GetAggregatesMode();

				If AggregateMode And Manager.GetAggregatesUsing() Then
					
					Manager.SetAggregatesUsing(False);
					
				EndIf;
			
				If Not AggregateMode And Manager.GetTotalsUsing() Then

					Manager.SetTotalsUsing(False);
					RecalcTotals = True;

				EndIf;
			
			EndIf;

		ElsIf IsAccountingRegister Then

			If Manager.GetMinTotalsPeriod() <> '00010101'
				Or Manager.GetMaxTotalsPeriod() <> '00010101' Then

				Manager.SetMinAndMaxTotalsPeriods('00010101', '00010101');

			EndIf;

			If Manager.GetPresentTotalsUsing() Then

				Manager.SetPresentTotalsUsing(False);

			EndIf;

			If Manager.GetTotalsUsing() Then

				Manager.SetTotalsUsing(False);

			EndIf;

		ElsIf IsInformationRegister Then

			MetadataRegister = Metadata.InformationRegisters.Find(MetadataObjectDetails.Name);

			If MetadataRegister.EnableTotalsSliceFirst Or MetadataRegister.EnableTotalsSliceLast Then

				If Manager.GetTotalsUsing() Then

					Manager.SetTotalsUsing(False);
					RecalcTotals = True;

				EndIf;

			EndIf;

			IsIndependentInformationRegister = (MetadataRegister.WriteMode
				= Metadata.ObjectProperties.RegisterWriteMode.Independent);

		EndIf;

		If IsIndependentInformationRegister Then

			RecordSet = Manager.CreateRecordSet();
			RecordSet.DataExchange.Load = True;
			RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
			RecordSet.AdditionalProperties.Insert("DontControlObjectsToDelete");
			RecordSet.Write();

		Else

			SelectionParameters = SelectionParameters(FullMetadataObjectName);
			FieldNameLogger = SelectionParameters.FieldNameLogger;

			Query = New Query;
			Query.Text = StrReplace(
				"SELECT DISTINCT
				|	T.Recorder AS Recorder
				|FROM
				|	&Table AS T", "&Table", SelectionParameters.Table);

			If FieldNameLogger <> "Recorder" Then

				Query.Text = StrReplace(Query.Text, "Recorder", FieldNameLogger);

			EndIf;

			QueryResult = Query.Execute();
			Selection = QueryResult.Select();

			While Selection.Next() Do

				RecordSet = Manager.CreateRecordSet();
				FilterRecorder = RecordSet.Filter[FieldNameLogger]; // FilterItem
				FilterRecorder.Set(Selection[FieldNameLogger]);
				RecordSet.DataExchange.Load = True;
				RecordSet.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
				RecordSet.AdditionalProperties.Insert("DontControlObjectsToDelete");
				RecordSet.Write();

			EndDo;

		EndIf;
		
		If RecalcTotals Then
			
			If IsAccumulationRegister
				And MetadataRegister.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers
				And Manager.GetAggregatesMode() Then
				
				Manager.SetAggregatesUsing(True);
				Manager.SetAggregatesUsing(False);
				
			Else
			
				Manager.SetTotalsUsing(True);
				Manager.SetTotalsUsing(False);
				
			EndIf;
			
		EndIf;
		
		If IsInformationRegister Then
			DisableAndClearDataHistory(MetadataRegister);
		EndIf;

	ElsIf ThisIsFullNameOfRoutineAssignment(FullMetadataObjectName) Then

		AreaMetadataObject = Metadata.ScheduledJobs.Find(MetadataObjectDetails.Name);
		For Each ScheduledJob In ScheduledJobs.GetScheduledJobs(
			New Structure("Metadata", AreaMetadataObject)) Do
			If ScheduledJob.Predefined Then
				ScheduledJob.Use = False;
				ScheduledJob.Write();
			Else
				ScheduledJob.Delete();
			EndIf;
		EndDo;

	EndIf;
EndProcedure

Procedure RemoveAreaExtensions() Export
	
	ScopeExtensions = ConfigurationExtensions.Get();
	For Each AreaExpansion In ScopeExtensions Do
		
		If AreaExpansion.Scope <> ConfigurationExtensionScope.DataSeparation Then
			Continue;
		EndIf;
				
		AreaExpansion.Delete();
		
	EndDo;
	
	CleaningKit = InformationRegisters.UseSuppliedExtensionsInDataAreas.CreateRecordSet();
	CleaningKit.Write();
	
EndProcedure

// For deferred file deletion via the task queue 
// Parameters:
//   FileName - String - file to delete
//
Procedure DeleteFile(FileName) Export
	
	File = New File(FileName);
	If File.Exists() Then
		DeleteFiles(FileName);
	EndIf;
	
EndProcedure

// Update handler for deleting an area with a separator value of 0.
//
Procedure DeleteArea0() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Record = InformationRegisters.DataAreas.CreateRecordManager();
	Record.DataAreaAuxiliaryData = 0;
	Record.Read();
	If Record.Selected() Then
		Record.Delete();
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	JobsQueue.Ref
	|FROM
	|	Catalog.JobsQueue AS JobsQueue
	|WHERE
	|	JobsQueue.JobState <> VALUE(Enum.JobsStates.Deleted)
	|	AND JobsQueue.Template <> VALUE(Catalog.QueueJobTemplates.EmptyRef)
	|	AND JobsQueue.DataAreaAuxiliaryData = 0
	|
	|UNION ALL
	|
	|SELECT
	|	JobsQueue.Ref
	|FROM
	|	Catalog.JobsQueue AS JobsQueue
	|WHERE
	|	JobsQueue.JobState <> VALUE(Enum.JobsStates.Deleted)
	|	AND JobsQueue.Template = VALUE(Catalog.QueueJobTemplates.EmptyRef)
	|	AND JobsQueue.DataAreaAuxiliaryData = 0
	|	AND JobsQueue.MethodName IN
	|		(SELECT DISTINCT
	|			QueueAreas.MethodName
	|		FROM
	|			Catalog.JobsQueue AS QueueAreas
	|		WHERE
	|			QueueAreas.DataAreaAuxiliaryData > 0
	|			AND QueueAreas.Template = VALUE(Catalog.QueueJobTemplates.EmptyRef))";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		CatObject = Selection.Ref.GetObject(); // CatalogObject.JobsQueue
		CatObject.Use = False;
		CatObject.JobState = Enums.JobsStates.Deleted;
		CatObject.DataExchange.Load = True;
		CatObject.Write();
	EndDo;
	
EndProcedure

Function ClearDataAreaMethodName() Export
	
	Return "SaaSOperations.ClearDataArea";
	
EndFunction

Function MethodNamePrepareDataAreaForUse() Export
	
	Return "SaaSOperations.PrepareDataAreaForUse";
	
EndFunction

Procedure SetExclusiveLock(UseMultithreading = False) Export
	
	If UseMultithreading And GetFunctionalOption("ExclusiveLockSet")
		Or Not UseMultithreading And ExclusiveMode() Then
		Return;
	EndIf;
	
	If Not ExclusiveMode() Then
		SetExclusiveMode(True);
	EndIf;
	
	If UseMultithreading Then
		Constants.ExclusiveLockSet.Set(True);
		SetExclusiveMode(False);
	EndIf;
	
EndProcedure

Procedure RemoveExclusiveLock(UseMultithreading = False) Export
	
	If UseMultithreading And Not GetFunctionalOption("ExclusiveLockSet")
		Or Not UseMultithreading And Not ExclusiveMode() Then
		Return;
	EndIf;
	
	If UseMultithreading Then
		
		Constants.ExclusiveLockSet.Set(False);
		
	Else
		
		Try
			SetExclusiveMode(False);
		Except
			
			ErrorText = StrTemplate(
				NStr("vi = 'Không thể bỏ phong tỏa độc quyền cơ sở thông tin.
					 |
					 |%1';
					 |ru = 'Не удалось снять монопольную блокировку информационной базы.
					 |
					 |%1';
					 |en = 'Cannot remove the exclusive infobase lock.
					 |
					 |%1'; fa = 'Cannot remove the exclusive infobase lock.
					 |
					 |%1';
					 |it = 'Cannot remove the exclusive infobase lock.
					 |
					 |%1';
					 |pl = 'Cannot remove the exclusive infobase lock.
					 |
					 |%1';
					 |tr = 'Infobase''in tekli engellenmesi alınamıyor.
					 |
					 |%1'"),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				NStr("vi = 'Phong tỏa độc quyền';
					|ru = 'Монопольная блокировка';
					|en = 'Exclusive lock'; fa = 'Exclusive lock';
					|it = 'Exclusive lock';
					|pl = 'Exclusive lock';
					|tr = 'Tekli engelleme'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,
				,
				,
				ErrorText);
			
		EndTry;
		
	EndIf;
	
EndProcedure

// The monopoly mode is set.
// 
// Returns:
//  Boolean - The Monopoly Mode Is Set
Function MonopolyModeIsSet() Export
	
	Return ExclusiveMode()
		Or GetFunctionalOption("ExclusiveLockSet");
	
EndFunction

Function MethodsAllowedToRunNames() Export
	
	MethodNames = New Array();
	MethodNames.Add(ExportImportDataInternal.ExportImportDataInThreadMethodName());
	
	Return MethodNames;
	
EndFunction

Procedure DeleteAreaUsers(DeleteCurrentUser = True) Export
	
	FirstAdministrator = Undefined;
	CurrentIBUserName = Undefined;
	
	If Not DeleteCurrentUser Then
		
		CurrentIBUserName = UserName();
		
		If IsBlankString(CurrentIBUserName) Then
			CurrentIBUserName = Undefined;
		EndIf;
		
	EndIf;
	
	For Each IBUser In InfoBaseUsers.GetUsers() Do
		
		If IBUser.Name = CurrentIBUserName Then
			Continue;
		EndIf;
		
		If FirstAdministrator = Undefined
			And Users.IsFullUser(IBUser, True, False)
			And IBUser.StandardAuthentication Then
			
			// We will postpone the removal of the administrator so that at the time of its removal all other
			// users of the information database have already been deleted.
			FirstAdministrator = IBUser;
			
		Else
			
			IBUser.Delete();
			
		EndIf;
		
	EndDo;
	
	If FirstAdministrator <> Undefined Then
		
		FirstAdministrator.Delete();
		
	EndIf;
	
EndProcedure

Function UserRightsSettingsInSaaSSupportedSSL() Export
	Return False;
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated. Should be used See FilesCTL.NewTemporaryStorageFile
// Schedules a queue job for delayed file deletion.
// Parameters:
//   FileName - String - file to delete
//   Timeout - Number - the number of seconds after which you plan to delete the file.
//   
// Returns:
//   CatalogRef.JobsQueue - scheduled task
//
Function ScheduleFileDeletion(FileName, Timeout) Export

	MethodParameters = New Array();
	MethodParameters.Add(FileName);
		
	JobParameters = New Structure;
	JobParameters.Insert("Use", True);
	JobParameters.Insert("ScheduledStartTime", CurrentSessionDate() + Timeout);
	JobParameters.Insert("MethodName", "SaaSOperations.DeleteFile");
	JobParameters.Insert("Parameters", MethodParameters);
	JobParameters.Insert("RestartCountOnFailure", 3);
	
	Return JobsQueue.AddJob(JobParameters);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Preparing data areas

// Updates the status of the area in the area Data register and sends a message to the service Manager.
//
// Parameters:
//  RecordManager - InformationRegisterRecordManager.DataAreas - Manager of recording
//  ResultOfPreparation - String - one of the "Success", "Required conversion", "Fatal error",
//    "Error removal", "Area Removed".
//  ErrorMessage - String - text of the error message. 
//
Procedure ChangeAreaStatusAndNotifyManager(Val RecordManager, Val ResultOfPreparation, Val ErrorMessage)
	
	ManagerSCopy = InformationRegisters.DataAreas.CreateRecordManager();
	FillPropertyValues(ManagerSCopy, RecordManager);
	RecordManager = ManagerSCopy;

	IncludeErrorMessage = False;
	
	CalledModule = Common.CommonModule("RemoteAdministrationControlMessagesInterface");
	If ResultOfPreparation = "Success" Then
		RecordManager.Status = Enums.DataAreaStatuses.Used;
		MessageType = CalledModule.MessageDataAreaPrepared();
	ElsIf ResultOfPreparation = "ConversionIsRequired" Then
		RecordManager.Status = Enums.DataAreaStatuses.ImportFromFile;
		MessageType = CalledModule.ErrorMessagePreparingDataAreaConversionRequired();
	ElsIf ResultOfPreparation = "AreaRemoved" Then
		RecordManager.Status = Enums.DataAreaStatuses.isDeleted;
		MessageType = CalledModule.MessageDataAreaDeleted();
	ElsIf ResultOfPreparation = "FatalError" Then
		WriteLogEvent(LogEventPreparingDataArea(), 
			EventLogLevel.Error, , , ErrorMessage);
		RecordManager.ProcessingError = True;
		MessageType = CalledModule.DataAreaPreparationErrorMessage();
		IncludeErrorMessage = True;
	ElsIf ResultOfPreparation = "DeletionError" Then
		RecordManager.ProcessingError = True;
		MessageType = CalledModule.MessageErrorDeletingDataArea();
		IncludeErrorMessage = True;
	Else
		Raise NStr("vi = 'Mã trả lại bất thường';
					|ru = 'Неожиданный код возврата';
					|en = 'Unexpected return code'; fa = 'Unexpected return code';
					|it = 'Codice riportato sconosciuto';
					|pl = 'Nieoczekiwany kod powrotu';
					|tr = 'Beklenmeyen geri dönüş kodu'");
	EndIf;
	
	// Send a message about the readiness of the area to the service manager.
	Message = MessagesSaaS.NewMessage(MessageType);
	Message.Body.Zone = RecordManager.DataAreaAuxiliaryData;
	If IncludeErrorMessage Then
		Message.Body.ErrorDescription = ErrorMessage;
	EndIf;

	BeginTransaction();
	Try
		MessagesSaaS.SendMessage(
			Message,
			ServiceManagerEndpoint());
		
		RecordManager.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Loads data to the area from a custom upload.
//
// Parameters:
//   DataArea - Number - number of the area to fill in.
//   UploadFileID - String - ID of the initial data file.
//   ErrorMessage - String - returned, error description.
//
// Returns:
//  String - one of the options is "Conversion is required", "Success", "Fatal error".
//
Function PrepareDataAreaForUseFromUpload(Val DataArea, Val UploadFileID, ErrorMessage)
	
	UploadFileName = GetFileFromServiceManagerStorage(UploadFileID);
	
	If UploadFileName = Undefined Then
		
		ErrorMessage = NStr("vi = 'Không có tệp dữ liệu ban đầu cho vùng';
							|ru = 'Нет файла начальных данных для области';
							|en = 'No initial data file for the data area'; fa = 'No initial data file for the data area';
							|it = 'Il file dei dati iniziali dell''area non è presente';
							|pl = 'Nie ma pliku początkowych danych dla obszaru';
							|tr = 'Alan için hiçbir başlangıç veri dosyası yok'");
		
		Return "FatalError";
	EndIf;
	
	If Not Common.SubsystemExists("CloudTechnology.ExportImportDataAreas") Then
		
		CauseExceptionMissingSubsystemCTL("CloudTechnology.ExportImportDataAreas");
		
	EndIf;
	
	If Not ExportImportDataAreas.UploadingToArchiveIsCompatibleWithCurConfiguration(UploadFileName) Then
		Result = "ConversionIsRequired";
	Else
		
		ExportImportDataAreas.LoadAreaFromArchive(UploadFileName);
		Result = "Success";
		
	EndIf;
	
	Try
		DeleteFiles(UploadFileName);
	Except
		WriteLogEvent(LogEventPreparingDataArea(), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions for determining the types of metadata objects by the full name
// of the metadata object.

Function CheckingTypeOfMetadataObjectByItsFullName(Val FullName, Val RussianLocalization, Val EnglishLocalization, Val SubstringPosition = 0)
	
	Substrings = StrSplit(FullName, ".");
	If Substrings.Count() > SubstringPosition Then
		TypeName = Substrings.Get(SubstringPosition);
		Return TypeName = RussianLocalization Or TypeName = EnglishLocalization;
	Else
		Return False;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Work with files

// Returns a structure with the file name and data at the address in temporary storage/information in the File object/binary
// data.
//
// Parameters:
//	AddressDataFile - String, BinaryData, File - Line/Binary data/File-Address of the file data storage/file Data/File.
//	FileName - String - file name. 
//
// Returns:
// Structure - Returned Data:
//   * Data - BinaryData - File data.
//   * Name - String - file name.
//
Function GetNameOfDataFile(Val AddressDataFile, Val FileName = "")
	
	If TypeOf(AddressDataFile) = Type("String") Then // The address of the file data in the temporary storage.
		If IsBlankString(AddressDataFile) Then
			Raise(NStr("vi = 'Sai địa chỉ kho chứa.';
						|ru = 'Неверный адрес хранилища.';
						|en = 'Invalid storage address.'; fa = 'Invalid storage address.';
						|it = 'Indirizzo dell''archivio errato.';
						|pl = 'Nieprawidłowy adres repozytorium.';
						|tr = 'Geçersiz depolama alanı adresi.'"));
		EndIf;
		FileData = GetFromTempStorage(AddressDataFile);
	ElsIf TypeOf(AddressDataFile) = Type("File") Then // an object of the File type.
		If Not AddressDataFile.Exists() Then
			Raise(NStr("vi = 'Không tìm thấy tệp.';
						|ru = 'Файл не найден.';
						|en = 'File not found.'; fa = 'File not found.';
						|it = 'File non trovato.';
						|pl = 'Plik nie został znaleziony.';
						|tr = 'Dosya bulunamadı.'"));
		EndIf;
		FileData = Undefined;
		FileName = AddressDataFile.FullName;
	ElsIf TypeOf(AddressDataFile) = Type("BinaryData") Then // File data.
		FileData = AddressDataFile;
	Else
		Raise(NStr("vi = 'Sai kiểu dữ liệu';
					|ru = 'Неверный тип данных';
					|en = 'Invalid data type'; fa = 'Invalid data type';
					|it = 'Tipo di dato errato';
					|pl = 'Nieprawidłowy typ danych';
					|tr = 'Geçersiz veri türü'"));
	EndIf;
	
	Return New Structure("Data, Name", FileData, FileName);
	
EndFunction

// Checks whether the file can be transferred via the file system from the server to the client.
//
// Parameters:
//  Proxy - WSProxy - Filestransfer proxy service*
//  ThereIsSupportFor2ndVersion - Boolean -
//
// Returns:
//  Boolean - a sign.
//
Function CanBeTransmittedViaFSSServer(Val Proxy, Val ThereIsSupportFor2ndVersion)
	
	If Not ThereIsSupportFor2ndVersion Then
		Return False;
	EndIf;
	
	FileName = Proxy.WriteTestFile();
	If FileName = "" Then 
		Return False;
	EndIf;
	
	Result = ReadTrialFile(FileName);
	
	Proxy.DeleteTestFile(FileName);
	
	Return Result;
	
EndFunction

// Checks whether the file can be transferred via the file system from the client to the server.
//
// Parameters:
//  Proxy - WSProxy - Filestransfer proxy service*
//  ThereIsSupportFor2ndVersion - Boolean - 
//
// Returns:
//  Boolean - a sign.
//
Function CanBeTransmittedViaFSToServer(Val Proxy, Val ThereIsSupportFor2ndVersion)
	
	If Not ThereIsSupportFor2ndVersion Then
		Return False;
	EndIf;
	
	FileName = RecordTrialFile();
	If FileName = "" Then 
		Return False;
	EndIf;
	
	Result = Proxy.ReadTestFile(FileName);
	
	FullFileName = FilesCTL.SharedDirectoryOfTemporaryFiles() + FileName;
	DeleteTempFiles(FullFileName);
	
	Return Result;
	
EndFunction

// Create a folder with a unique name to place parts of the shared file.
//
// Returns:
// String - directory name.
//
Function CreateAssemblyDirectory()
	
	BuildDirectory = GetTempFileName();
	CreateDirectory(BuildDirectory);
	Return BuildDirectory + GetPathSeparator();
	
EndFunction

// Reads a test file from disk, comparing the contents and name: they should be the same.
// The file must be deleted by the caller.
//
// Parameters:
// FileName - String - Without path.
//
// Returns:
// Boolean - True if the file has been read successfully and the contents match its name.
//
Function ReadTrialFile(Val FileName)
	
	FileProperties = New File(FilesCTL.SharedDirectoryOfTemporaryFiles() + FileName);
	If FileProperties.Exists() Then
		Text = New TextReader(FileProperties.FullName, TextEncoding.ANSI);
		TestID = Text.Read();
		Text.Close();
		Return TestID = FileProperties.BaseName;
	Else
		Return False;
	EndIf;
	
EndFunction

// Creates an empty structure of the desired format.
//
// Returns:
// Structure - with fields:
//   Name - String - The name of the file in the repository.
//   Data - Binary data - File data.
// 	 Fullname - String - The name of the file with the path.
//
Function CreateFileDescription()
	
	FileDetails = New Structure;
	FileDetails.Insert("Name");
	FileDetails.Insert("Data");
	FileDetails.Insert("FullName");
	FileDetails.Insert("RequiredParameters2", "Name"); // Required parameters.
	Return FileDetails;
	
EndFunction

// Gets the Wsproxy object of the Web service specified by its base name.
//
// Parameters:
// ConnectionParameters - Structure - With Fields:
//	* URL - String - URL of the service. It must be present and filled in.
//	* UserName - String - Name of the service user.
//	* Password - String - Password of the service user.
// Returns:
//  Structure - With Fields:
//   * Proxy - WSProxy - proxy,
//   * ThereIsSupportFor2ndVersion - Boolean - a sign.
//
Function DescriptionOfFileTransferProxyService(Val ConnectionParameters)
	
	BaseNameOfService = "FilesTransfer";
	
	ArrayOfSupportedVersions = Common.GetInterfaceVersions(ConnectionParameters, "FileTransferService");
	If ArrayOfSupportedVersions.Find("1.0.2.1") = Undefined Then
		ThereIsSupportFor2ndVersion = False;
		InterfaceVersion = "1.0.1.1"
	Else
		ThereIsSupportFor2ndVersion = True;
		InterfaceVersion = "1.0.2.1";
	EndIf;
	
	If ConnectionParameters.Property("UserName")
		And ValueIsFilled(ConnectionParameters.UserName) Then
		
		UserName = ConnectionParameters.UserName;
		UserPassword = ConnectionParameters.Password;
	Else
		UserName = Undefined;
		UserPassword = Undefined;
	EndIf;
	
	If InterfaceVersion = Undefined Or InterfaceVersion = "1.0.1.1" Then // 1st version.
		ServiceName = BaseNameOfService;
	Else // Versions 2 and higher.
		ServiceName = BaseNameOfService + "_" + StrReplace(InterfaceVersion, ".", "_");
	EndIf;
	
	ServiceAddress = ConnectionParameters.URL + StringFunctionsClientServer.SubstituteParametersToString("/ws/%1?wsdl", ServiceName);
	
	ConnectionParameters = Common.WSProxyConnectionParameters();
	ConnectionParameters.WSDLAddress = ServiceAddress;
	ConnectionParameters.NamespaceURI = "http://www.1c.ru/SaaS/1.0/WS";
	ConnectionParameters.ServiceName = ServiceName;
	ConnectionParameters.UserName = UserName;
	ConnectionParameters.Password = UserPassword;
	ConnectionParameters.Timeout = 600;
	Proxy = Common.CreateWSProxy(ConnectionParameters);
	
	Return New Structure("Proxy, ThereIsSupportFor2ndVersion", Proxy, ThereIsSupportFor2ndVersion);
		
EndFunction

Procedure LogFileStorageEvent(Val Event,
	Val FileID_, Val Size, Val Duration, Val TransferViaFileSystem)
	
	EventData = New Structure;
	EventData.Insert("FileID_", FileID_);
	EventData.Insert("Size", Size);
	EventData.Insert("Duration", Duration);
	
	If TransferViaFileSystem Then
		EventData.Insert("Transport", "file");
	Else
		EventData.Insert("Transport", "ws");
	EndIf;
	
	WriteLogEvent(
		NStr("vi = 'Kho chứa tệp';
			|ru = 'Хранилище файлов';
			|en = 'File storage'; fa = 'محل ذخیره فایل';
			|it = 'Archivio dei file';
			|pl = 'Repozytorium plików';
			|tr = 'Dosya depolama'", Common.DefaultLanguageCode()) + "." + Event,
		EventLogLevel.Information,
		,
		,
		Common.ValueToXMLString(EventData));
	
EndProcedure

/////////////////////////////////////////////////////////////////////////////////
// Temporary file

// Delete the file (s) on disk.
// If the file name is set to a mask with a path, split it into a path and a mask.
//
Procedure DeleteTempFiles(Val FileName)
	
	Try
		If StrEndsWith(FileName, "*") Then // Mask.
			IndexOf = StrFind(FileName, GetPathSeparator(), SearchDirection.FromEnd);
			If IndexOf > 0 Then
				PathToFile = Left(FileName, IndexOf - 1);
				FileMask = Mid(FileName, IndexOf + 1);
				If FindFiles(PathToFile, FileMask, False).Count() > 0 Then
					DeleteFiles(PathToFile, FileMask);
				EndIf;
			EndIf;
		Else
			FileProperties = New File(FileName);
			If FileProperties.Exists() Then
				FileProperties.SetReadOnly(False); // Remove the attribute.
				DeleteFiles(FileProperties.FullName);
			EndIf;
		EndIf;
	Except
		WriteLogEvent(TempFileDeletionEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
EndProcedure

/////////////////////////////////////////////////////////////////////////////////
// Serialization

Function WriteValueToString(Val Value)
	
	Record = New XMLWriter;
	Record.SetString();
	
	If TypeOf(Value) = Type("XDTODataObject") Then
		XDTOFactory.WriteXML(Record, Value, , , , XMLTypeAssignment.Explicit);
	Else
		XDTOSerializer.WriteXML(Record, Value, XMLTypeAssignment.Explicit);
	EndIf;
	
	Return Record.Close();
		
EndFunction

// Indicates whether this type is serializable.
//
// Parameters:
//  StructuralType - Type - 
//
// Returns:
//  Boolean - a sign.
//
Function SerializableStructuralType(StructuralType);
	
	ArrayOfSerializableTypes = SaaSOperationsCached.SerializableStructuralTypes();
	
	For Each SerializableType In ArrayOfSerializableTypes Do 
		If StructuralType = SerializableType Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
		
EndFunction

// Gets the XDTO representation of a structural type object.
//
// Parameters:
//   MeaningOfStructuralType - Array of Structure 
//   						  - Array of Map - or their fixed counterparts.
//
// Returns:
//   XDTODataObject - XDTO is a representation of a structural type object.
//
Function StructuralObjectToXDTOObject(Val MeaningOfStructuralType)
	
	StructuralType = TypeOf(MeaningOfStructuralType);
	
	If Not SerializableStructuralType(StructuralType) Then
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Kiểu %1 không phải là kiểu cấu trúc hoặc không hỗ trợ tuần tự hóa kiểu đó.';
				|ru = 'Тип %1 не является структурным или его сериализация в настоящее время не поддерживается.';
				|en = 'Type ""%1"" is not structural or currently its serialization is not supported.'; fa = 'Type ""%1"" is not structural or currently its serialization is not supported.';
				|it = 'La tipologia %1 non è strutturale o la sua serializzazione al momento non è supportata.';
				|pl = 'Rodzaj %1 nie jest strukturalnym lub jego serializacja nie jest obecnie obsługiwana.';
				|tr = '%1 türü yapısal değil veya şu andaki serileştirme desteklenmiyor.'"),
			StructuralType);
		Raise(ErrorMessage);
	EndIf;
	
	XMLValueType = XDTOSerializer.XMLTypeOf(MeaningOfStructuralType);
	StructureType = XDTOFactory.Type(XMLValueType);
	XDTOStructure = XDTOFactory.Create(StructureType);
	
	// Iteration of acceptable structural types.
	
	If StructuralType = Type("Structure") Or StructuralType = Type("FixedStructure") Then
		
		TypeProperty = StructureType.Properties.Get("Property").Type;
		
		For Each KeyAndValue In MeaningOfStructuralType Do
			Property = XDTOFactory.Create(TypeProperty);
			Property.name = KeyAndValue.Key;
			Property.Value = TypeValueToXDTOValue(KeyAndValue.Value);
			PropertiesList = XDTOStructure.Property; // XDTOList
			PropertiesList.Add(Property);
		EndDo;
		
	ElsIf StructuralType = Type("Array") Or StructuralType = Type("FixedArray") Then 
		
		For Each ElementValue In MeaningOfStructuralType Do
			ValuesList = XDTOStructure.Value; // XDTOList
			ValuesList.Add(TypeValueToXDTOValue(ElementValue));
		EndDo;
		
	ElsIf StructuralType = Type("Map") Or StructuralType = Type("FixedMap") Then
		
		For Each KeyAndValue In MeaningOfStructuralType Do
			KeyValueList = XDTOStructure.pair; // XDTOList
			KeyValueList.Add(StructuralObjectToXDTOObject(KeyAndValue));
		EndDo;
	
	ElsIf StructuralType = Type("KeyAndValue")	Then	
		
		XDTOStructure.key = TypeValueToXDTOValue(MeaningOfStructuralType.Key);
		XDTOStructure.value = TypeValueToXDTOValue(MeaningOfStructuralType.Value);
		
	ElsIf StructuralType = Type("ValueTable") Then
		
		XDTOTypeColumnVt = StructureType.Properties.Get("column").Type;
		
		For Each Column In MeaningOfStructuralType.Columns Do
			
			XDTOColumn = XDTOFactory.Create(XDTOTypeColumnVt);
			
			XDTOColumn.Name = TypeValueToXDTOValue(Column.Name);
			XDTOColumn.ValueType = XDTOSerializer.WriteXDTO(Column.ValueType);
			XDTOColumn.Title = TypeValueToXDTOValue(Column.Title);
			XDTOColumn.Width = TypeValueToXDTOValue(Column.Width);
			
			ColumnsList_ = XDTOStructure.column; // XDTOList
			ColumnsList_.Add(XDTOColumn);
			
		EndDo;
		
		XDTOTypeIndexVt = StructureType.Properties.Get("index").Type;
		
		For Each IndexOf In MeaningOfStructuralType.Indexes Do
			
			XDTOIndex = XDTOFactory.Create(XDTOTypeIndexVt);
			
			For Each IndexField In IndexOf Do
				ColumnList = XDTOIndex.column; // XDTOList
				ColumnList.Add(TypeValueToXDTOValue(IndexField));
			EndDo;
			
			IndexList = XDTOStructure.index; // XDTOList
			IndexList.Add(XDTOIndex);
			
		EndDo;
		
		XDTOTypeStringVt = StructureType.Properties.Get("row").Type;
		
		For Each SpecificationRow In MeaningOfStructuralType Do
			
			XDTORow = XDTOFactory.Create(XDTOTypeStringVt);
			
			For Each ColumnValue In SpecificationRow Do
				ListValue_1 = XDTORow.value; // XDTOList
				ListValue_1.Add(TypeValueToXDTOValue(ColumnValue));
			EndDo;
			
			TableRowList = XDTOStructure.row; // XDTOList
			TableRowList.Add(XDTORow);
			
		EndDo;
		
	EndIf;
	
	Return XDTOStructure;
	
EndFunction

// Gets a structural type object from an XDTO object.
//
// Parameters:
//  XDTODataObject - XDTODataObject - Object.
//
// Returns:
//  Array, Structure, Map, FixedArray, FixedStructure, FixedMap - structural object.
//
Function XDTOObjectStructuralObject(XDTODataObject)
	
	XMLDataType = New XMLDataType(XDTODataObject.Type().Name, XDTODataObject.Type().NamespaceURI);
	If AbilityToReadXMLDataType(XMLDataType) Then
		StructuralType = XDTOSerializer.FromXMLType(XMLDataType);
	Else
		Return XDTODataObject;
	EndIf;
	
	If StructuralType = Type("String") Then
		Return "";
	EndIf;
	
	If Not SerializableStructuralType(StructuralType) Then
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Kiểu %1 không phải là kiểu cấu trúc hoặc không hỗ trợ tuần tự hóa kiểu đó.';
				|ru = 'Тип %1 не является структурным или его сериализация в настоящее время не поддерживается.';
				|en = 'Type ""%1"" is not structural or currently its serialization is not supported.'; fa = 'Type ""%1"" is not structural or currently its serialization is not supported.';
				|it = 'La tipologia %1 non è strutturale o la sua serializzazione al momento non è supportata.';
				|pl = 'Rodzaj %1 nie jest strukturalnym lub jego serializacja nie jest obecnie obsługiwana.';
				|tr = '%1 türü yapısal değil veya şu andaki serileştirme desteklenmiyor.'"),
			StructuralType);
		Raise(ErrorMessage);
	EndIf;
	
	If StructuralType = Type("Structure")	Or StructuralType = Type("FixedStructure") Then
		
		StructuralObject = New Structure;
		
		For Each Property In XDTODataObject.Property Do
			StructuralObject.Insert(Property.name, ValueOfXDTOIsValueOfType(Property.Value));          
		EndDo;
		
		If StructuralType = Type("Structure") Then
			Return StructuralObject;
		Else 
			Return New FixedStructure(StructuralObject);
		EndIf;
		
	ElsIf StructuralType = Type("Array") Or StructuralType = Type("FixedArray") Then 
		
		StructuralObject = New Array;
		
		For Each ArrayElement In XDTODataObject.Value Do
			StructuralObject.Add(ValueOfXDTOIsValueOfType(ArrayElement));          
		EndDo;
		
		If StructuralType = Type("Array") Then
			Return StructuralObject;
		Else 
			Return New FixedArray(StructuralObject);
		EndIf;
		
	ElsIf StructuralType = Type("Map") Or StructuralType = Type("FixedMap") Then
		
		StructuralObject = New Map;
		
		For Each XdtoKeyAndValue In XDTODataObject.pair Do
			KeyAndValue = XDTOObjectStructuralObject(XdtoKeyAndValue);
			StructuralObject.Insert(KeyAndValue.Ключ, KeyAndValue.Значение);
		EndDo;
		
		If StructuralType = Type("Map") Then
			Return StructuralObject;
		Else 
			Return New FixedMap(StructuralObject);
		EndIf;
	
	ElsIf StructuralType = Type("KeyAndValue")	Then	
		
		StructuralObject = New Structure("Key, Value");
		StructuralObject.Key = ValueOfXDTOIsValueOfType(XDTODataObject.key);
		StructuralObject.Value = ValueOfXDTOIsValueOfType(XDTODataObject.value);
		
		Return StructuralObject;
		
	ElsIf StructuralType = Type("ValueTable") Then
		
		StructuralObject = New ValueTable;
		
		For Each Column In XDTODataObject.column Do
			
			StructuralObject.Columns.Add(
				ValueOfXDTOIsValueOfType(Column.Name), 
				XDTOSerializer.ReadXDTO(Column.ValueType), 
				ValueOfXDTOIsValueOfType(Column.Title), 
				ValueOfXDTOIsValueOfType(Column.Width));
				
		EndDo;
		For Each IndexOf In XDTODataObject.index Do
			
			IndexAsString = "";
			For Each IndexField In IndexOf.column Do
				IndexAsString = IndexAsString + IndexField + ", ";
			EndDo;
			IndexAsString = TrimAll(IndexAsString);
			If StrLen(IndexAsString) > 0 Then
				IndexAsString = Left(IndexAsString, StrLen(IndexAsString) - 1);
			EndIf;
			
			StructuralObject.Indexes.Add(IndexAsString);
		EndDo;
		For Each XDTORow In XDTODataObject.row Do
			
			SpecificationRow = StructuralObject.Add();
			
			NumberOfColumns_ = StructuralObject.Columns.Count();
			For IndexOf = 0 To NumberOfColumns_ - 1 Do 
				TableColumn2 = StructuralObject.Columns[IndexOf]; // ValueTableColumn
				SpecificationRow[TableColumn2.Name] = ValueOfXDTOIsValueOfType(XDTORow.value[IndexOf]);
			EndDo;
			
		EndDo;
		
		Return StructuralObject;
		
	EndIf;
	
EndFunction

Function AbilityToReadXMLDataType(Val XMLDataType)
	
	Record = New XMLWriter;
	Record.SetString();
	Record.WriteStartElement("Dummy");
	Record.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
	Record.WriteNamespaceMapping("ns1", XMLDataType.NamespaceURI);
	Record.WriteAttribute("xsi:type", "ns1:" + XMLDataType.TypeName);
	Record.WriteEndElement();
	
	String = Record.Close();
	
	Read = New XMLReader;
	Read.SetString(String);
	Read.MoveToContent();
	
	Return XDTOSerializer.CanReadXML(Read);
	
EndFunction

// Gets the value of a simple type in the context of XDTO.
//
// Parameters:
// 	TypeValue - Arbitrary - a value of any type.
//
// Returns:
// 	XDTODataObject, XDTODataValue - the type of value.
Function TypeValueToXDTOValue(Val TypeValue)
	
	If TypeValue = Undefined
		Or TypeOf(TypeValue) = Type("XDTODataObject")
		Or TypeOf(TypeValue) = Type("XDTODataValue") Then
		
		Return TypeValue;
		
	Else
		
		If TypeOf(TypeValue) = Type("String") Then
			XDTOType = XDTOFactory.Type("http://www.w3.org/2001/XMLSchema", "string")
		Else
			XMLType = XDTOSerializer.XMLTypeOf(TypeValue);
			XDTOType = XDTOFactory.Type(XMLType);
		EndIf;
		
		If TypeOf(XDTOType) = Type("XDTOObjectType") Then // The value of the structural type.
			Return StructuralObjectToXDTOObject(TypeValue);
		Else
			Return XDTOFactory.Create(XDTOType, TypeValue); // For example, UUID.
		EndIf;
		
	EndIf;
	
EndFunction

// Gets the platform analog of the XDTO type value.
//
// Parameters:
// XDTODataValue - XDTODataValue -A value of an arbitrary XDTO type.
//
// Returns:
//	Arbitrary - meaning.
//
Function ValueOfXDTOIsValueOfType(XDTODataValue)
	
	If TypeOf(XDTODataValue) = Type("XDTODataValue") Then
		Return XDTODataValue.Value;
	ElsIf TypeOf(XDTODataValue) = Type("XDTODataObject") Then
		Return XDTOObjectStructuralObject(XDTODataValue);
	Else
		Return XDTODataValue;
	EndIf;
	
EndFunction

// Fills the area with the supplied data when preparing for use.
//
// Parameters:
//   DataArea - Number - number of the area to fill in.
//   UploadFileID - UUID - ID of the initial data file.
//   Variant - String - a variant of the initial data.
//   FatalErrorMessage - String - the returned parameter.
//
// Returns:
//  String - one of the options is "Success", "Fatal error".
//
// @unavailable-in-safemode
Function ImportAreaFormSuppliedData(Val DataArea, Val UploadFileID, Val Variant, FatalErrorMessage)
	
	If Not Users.IsFullUser(, True) Then
		Raise(NStr("vi = 'Không đủ quyền để thực hiện thao tác';
					|ru = 'Недостаточно прав для выполнения операции';
					|en = 'Insufficient rights to perform the operation.'; fa = 'Insufficient rights to perform the operation.';
					|it = 'Diritti insufficienti per eseguire l''operazione';
					|pl = 'Niewystarczające uprawnienia do wykonania operacji';
					|tr = 'İşlem için gerekli yetkiler yok'"));
	EndIf;
	
	Filter = New Array();
	Filter.Add(New Structure("Code, Value", "ConfigurationName", Metadata.Name));
	Filter.Add(New Structure("Code, Value", "ConfigurationVersion", Metadata.Version));
	Filter.Add(New Structure("Code, Value", "Variant", Variant));
	Filter.Add(New Structure("Code, Value", "Mode", 
		?(Constants.InfobaseUsageMode.Get() 
			= Enums.InfobaseUsageModes.Demo, 
			"Demo", "Work")));

	Descriptors = SuppliedData.DescriptorsOfSuppliedDataFromManager("DataAreaPrototype", Filter);
	
	If Descriptors.Descriptor.Count() = 0 Then
		FatalErrorMessage = 
		NStr("vi = 'Trong bộ quản lý dịch vụ, không có tệp dữ liệu ban đầu đối với phiên bản hiện tại của cấu hình.';
			|ru = 'В менеджере сервиса нет файла начальных данных для текущей версии конфигурации.';
			|en = 'The service manager has no initial data file for the current applied solution version.'; fa = 'The service manager has no initial data file for the current applied solution version.';
			|it = 'Nel gestore del servizio non è presente il file contenente i dati iniziali dell''attuale versione della configurazione.';
			|pl = 'W menedżerze usługi brak pliku początkowych danych dla bieżącej wersji konfiguracji.';
			|tr = 'Servis yöneticisi mevcut yapılandırma sürümü için ilk veri dosyasını içermez.'");
		Return "FatalError";
	EndIf;
	
	Id = Descriptors.Descriptor[0].FileGUID;
	
	BinaryDataOfSuppliedData = SuppliedData.SuppliedDataFromCache(Id);
	If ValueIsFilled(BinaryDataOfSuppliedData) Then	
		UploadFileName = GetTempFileName();
		BinaryDataOfSuppliedData.Write(UploadFileName);	
	Else	
		UploadFileName = GetFileFromServiceManagerStorage(Id);			
		If UploadFileName = Undefined Then
			FatalErrorMessage = 
			NStr("vi = 'Trong bộ quản lý dịch vụ không còn tệp dữ liệu ban đầu được yêu cầu, có lẽ tệp đã bị thay thế. Vùng không thể được chuẩn bị.';
				|ru = 'В менеджере сервиса больше нет требуемого файла начальных данных, вероятно он был заменен. Область не может быть подготовлена.';
				|en = 'Service manager no longer contains the required file with initial data, it might have been replaced. Area cannot be prepared.'; fa = 'Service manager no longer contains the required file with initial data, it might have been replaced. Area cannot be prepared.';
				|it = 'Il file necessario, contenente i dati iniziali non si trova più nel gestore del servizio, probabilmente è stato sostituito. L''area non può essere preparata.';
				|pl = 'W menedżerze usługi już nie ma żądanego pliku danych początkowych, prawdopodobnie został on wymieniony. Obszar nie może być przygotowany.';
				|tr = 'Hizmet yöneticisi artık başlangıç verileri içeren gereken dosyayı içermiyor, değiştirilmiş olabilir. Alan hazırlanamıyor.'");
			Return "FatalError";
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Not Common.SubsystemExists("CloudTechnology.ExportImportDataAreas") Then
		
		CauseExceptionMissingSubsystemCTL("CloudTechnology.ExportImportDataAreas");
		
	EndIf;
	
	Try
		
		ImportParameters = ExportImportDataAreas.ImportParameters();
		ImportParameters.CollapseElementsInUsersCatalog = 
			(Not Constants.InfobaseUsageMode.Get() = Enums.InfobaseUsageModes.Demo);
		
		ExportImportDataAreas.LoadAreaFromArchive(UploadFileName, ImportParameters);
		
	Except
		
		WriteLogEvent(LogEventCopyingDataArea(), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Try
			DeleteFiles(UploadFileName);
		Except
			WriteLogEvent(LogEventCopyingDataArea(), 
				EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
		Raise;
	EndTry;
	
	Try
		DeleteFiles(UploadFileName);
	Except
		WriteLogEvent(LogEventCopyingDataArea(), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return "Success";

EndFunction

////////////////////////////////////////////////////////////////////////////////
// Control of undivided data.

// Called when checking whether undivided data is available for writing.
//
Procedure ControlOfUnsharedDataWhenWriting(Val Source)
	
	If DataSeparationEnabled() And SeparatedDataUsageAvailable() Then
		
		ExceptionPresentation = NStr("vi = 'Vi phạm quyền truy cập.';
									|ru = 'Нарушение прав доступа.';
									|en = 'Access violation.'; fa = 'Access violation.';
									|it = 'Violazione dei diritti di accesso.';
									|pl = 'Naruszenie praw dostępu.';
									|tr = 'Erişim hakkı ihlali.'", Common.DefaultLanguageCode());
		
		WriteLogEvent(
			ExceptionPresentation,
			EventLogLevel.Error,
			Source.Metadata());
		
		Raise ExceptionPresentation;
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Processing of auxiliary data of the region.

////////////////////////////////////////////////////////////////////////////////
// HANDLERS FOR RECEIVING THE SUPPLIED DATA

Procedure ProcessSuppliedConfigurationReference(Val Descriptor, Val PathToFile)
	
	If ValueIsFilled(PathToFile) Then
		
		SuppliedData.SaveSuppliedDataToCache(Descriptor, PathToFile);
		
		DeleteIrrelevantDataAreaBenchmarks(Metadata.Version);
		
	Else
		
		Filter = New Array;
		For Each Characteristic In Descriptor.Properties.Property Do
			If Characteristic.IsKey Then
				Filter.Add(New Structure("Code, Value", Characteristic.Code, Characteristic.Value));
			EndIf;
		EndDo;

		For Each Ref In SuppliedData.ReferencesSuppliedDataFromCache(Descriptor.DataType, Filter) Do
		
			SuppliedData.DeleteSuppliedDataFromCache(Ref);
		
		EndDo;
	EndIf;
	
EndProcedure

// Deletes out-of-date data area standards: those standards whose version is less than the specified (current) one.
//
// Parameters:
//  CurrentConfigurationVersion_ - String - current version of the configuration.
//
Procedure DeleteIrrelevantDataAreaBenchmarks(CurrentConfigurationVersion_)
	
	Query = New Query(
		"SELECT DISTINCT
		|	SuppliedDataDataCharacteristics.Ref.Ref AS SuppliedData,
		|	CAST(SuppliedDataDataCharacteristics.Value AS STRING(150)) AS ConfigurationVersion
		|FROM
		|	Catalog.SuppliedData.DataCharacteristics AS SuppliedDataDataCharacteristics
		|WHERE
		|	SuppliedDataDataCharacteristics.Characteristic = ""ConfigurationVersion""
		|	AND SuppliedDataDataCharacteristics.Ref.DataKind = ""DataAreaPrototype""");
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If CommonClientServer.CompareVersions(CurrentConfigurationVersion_, Selection.ConfigurationVersion) > 0 Then
			SuppliedData.DeleteSuppliedDataFromCache(Selection.SuppliedData);
		EndIf;
	EndDo;
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// INFORMATION BASE UPDATE HANDLERS

// Controls the metadata structure based on whether undivided data is not available
// for recording from sessions with partitioning enabled.
// 
// Parameters:
//  RaiseException1 - Boolean - raise an exception in case of a control error.
// 
// Returns:
//	Structure:
//		* ThereIsNoUndividedDataInControllingSubscription - Array of MetadataObject
//		* TextForExcludingUnsharedData - String
//		* ObjectsWithMultipleSeparators - Array of MetadataObject
//		* ExceptionTextWithMultipleDelimiters - String
//		* MetadataObjects - Array of MetadataObject - deprecated property.
//		* ExceptionText - String - deprecated property.
//
Function ControlOfUnsharedDataWhenUpdating(RaiseException1 = True) Export
	
	MetadataControlRules = New Map;
	
	MetadataControlRules.Insert(Metadata.Constants, "ConstantValueManager.%1");
	MetadataControlRules.Insert(Metadata.Catalogs, "CatalogObject.%1");
	MetadataControlRules.Insert(Metadata.Documents, "DocumentObject.%1");
	MetadataControlRules.Insert(Metadata.BusinessProcesses, "BusinessProcessObject.%1");
	MetadataControlRules.Insert(Metadata.Tasks, "TaskObject.%1");
	MetadataControlRules.Insert(Metadata.ChartsOfCalculationTypes, "ChartOfCalculationTypesObject.%1");
	MetadataControlRules.Insert(Metadata.ChartsOfCharacteristicTypes, "ChartOfCharacteristicTypesObject.%1");
	MetadataControlRules.Insert(Metadata.ExchangePlans, "ExchangePlanObject.%1");
	MetadataControlRules.Insert(Metadata.ChartsOfAccounts, "ChartOfAccountsObject.%1");
	MetadataControlRules.Insert(Metadata.AccountingRegisters, "AccountingRegisterRecordSet.%1");
	MetadataControlRules.Insert(Metadata.AccumulationRegisters, "AccumulationRegisterRecordSet.%1");
	MetadataControlRules.Insert(Metadata.CalculationRegisters, "CalculationRegisterRecordSet.%1");
	MetadataControlRules.Insert(Metadata.InformationRegisters, "InformationRegisterRecordSet.%1");
	
	Exceptions = New Array();
	
	Exceptions.Add(Metadata.InformationRegisters.ProgramInterfaceCache);
	Exceptions.Add(Metadata.Constants.InstantMessageSendingLocked);
	Exceptions.Add(Metadata.InformationRegisters.SafeDataStorage);
	
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		Exceptions.Add(Metadata.InformationRegisters.Find("DeleteExchangeTransportSettings"));
		Exceptions.Add(Metadata.InformationRegisters.Find("DataExchangesStates"));
		Exceptions.Add(Metadata.InformationRegisters.Find("SuccessfulDataExchangesStates"));
		
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PerformanceMonitor") Then
		
		Exceptions.Add(Metadata.Catalogs.Find("KeyOperations"));
		Exceptions.Add(Metadata.Catalogs.Find("KeyOperationProfiles"));
		Exceptions.Add(Metadata.InformationRegisters.Find("TimeMeasurements"));
		Exceptions.Add(Metadata.InformationRegisters.Find("TimeMeasurementsTechnological"));
		
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		
		Exceptions.Add(Metadata.InformationRegisters.Find("PlatformDumps"));
		Exceptions.Add(Metadata.InformationRegisters.Find("StatisticsOperations"));
		Exceptions.Add(Metadata.InformationRegisters.Find("StatisticsComments"));
		Exceptions.Add(Metadata.InformationRegisters.Find("StatisticsAreas"));
		Exceptions.Add(Metadata.InformationRegisters.Find("StatisticsOperationComments"));
		Exceptions.Add(Metadata.InformationRegisters.Find("StatisticsOperationsClipboard"));
		Exceptions.Add(Metadata.InformationRegisters.Find("MeasurementsStatisticsOperations"));
		Exceptions.Add(Metadata.InformationRegisters.Find("MeasurementsStatisticsComments"));
		Exceptions.Add(Metadata.InformationRegisters.Find("MeasurementsStatisticsAreas"));
		Exceptions.Add(Metadata.InformationRegisters.Find("ConfigurationStatistics"));
		Exceptions.Add(Metadata.InformationRegisters.Find("PackagesToSend"));
        Exceptions.Add(Metadata.InformationRegisters.Find("StatisticsMeasurements"));
		
	EndIf;
	
	CTLSubsystemsIntegration.OnDefineSharedDataExceptions(Exceptions);
	
	StandardSeparators = New Array; // Array of MetadataObjectCommonAttribute
	StandardSeparators.Add(Metadata.CommonAttributes.DataAreaMainData);
	StandardSeparators.Add(Metadata.CommonAttributes.DataAreaAuxiliaryData);
	
	ControlProcedures = New Array;
	ControlProcedures.Add(Metadata.EventSubscriptions.CheckSharedRecordsSetsOnWrite.Handler);
	ControlProcedures.Add(Metadata.EventSubscriptions.CheckSharedObjectsOnWrite.Handler);
	ControlProcedures.Add(Metadata.EventSubscriptions.CheckSharedRecordSetsOnWriteSaaSTechnology.Handler);
	ControlProcedures.Add(Metadata.EventSubscriptions.CheckSharedObjectsOnWriteSaaSTechnology.Handler);
	
	ControllingSubscriptions = New Array; // Array of MetadataObjectEventSubscription
	
	For Each EventSubscription In Metadata.EventSubscriptions Do
		
		If ControlProcedures.Find(EventSubscription.Handler) <> Undefined Then
			
			ControllingSubscriptions.Add(EventSubscription);
			
		EndIf;
		
	EndDo;
	
	ThereIsNoUndividedDataInControllingSubscription = New Array;
	ObjectsWithMultipleSeparators = New Array;
	MetadataObjectsWithViolations = New Array;
	
	For Each MetadataControlRule In MetadataControlRules Do
		
		ControlledMetadataObjects = MetadataControlRule.Key; // Array of MetadataObject
		ConstructorForMetadataObjectType = MetadataControlRule.Value;
		
		For Each ControlledMetadataObject In ControlledMetadataObjects Do
			
			// 1. Checking the metadata object for separation by multiple separators.
			
			NumberOfSeparators = 0;
			
			For Each StandardSeparator In StandardSeparators Do
				
				If IsSeparatedMetadataObject(ControlledMetadataObject, StandardSeparator.Name) Then
					
					NumberOfSeparators = NumberOfSeparators + 1;
					
				EndIf;
				
			EndDo;
			
			If NumberOfSeparators > 1 Then
				
				ObjectsWithMultipleSeparators.Add(ControlledMetadataObject);
				MetadataObjectsWithViolations.Add(ControlledMetadataObject);
				
			EndIf;
			
			// 2. Checking of undivided metadata objects for inclusion in controlling
			// event subscriptions.
			
			If ValueIsFilled(ConstructorForMetadataObjectType) Then
				
				If Exceptions.Find(ControlledMetadataObject) <> Undefined Then
					
					Continue;
					
				EndIf;
				
				MetadataObjectType = Type(StringFunctionsClientServer.SubstituteParametersToString(ConstructorForMetadataObjectType, ControlledMetadataObject.Name));
				
				VerificationRequired = True;
				
				For Each StandardSeparator In StandardSeparators Do
					
					If IsSeparatedMetadataObject(ControlledMetadataObject, StandardSeparator.Name) Then
						
						VerificationRequired = False;
						
					EndIf;
					
				EndDo;
				
				ControlIsProvided = False;
				
				If VerificationRequired Then
					
					For Each ControllingSubscription In ControllingSubscriptions Do
						
						If ControllingSubscription.Source.ContainsType(MetadataObjectType) Then
							
							ControlIsProvided = True;
							
						EndIf;
						
					EndDo;
					
				EndIf;
				
				If VerificationRequired And Not ControlIsProvided Then
					
					ThereIsNoUndividedDataInControllingSubscription.Add(ControlledMetadataObject);
					MetadataObjectsWithViolations.Add(ControlledMetadataObject);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ExceptionsRaised = New Array;
	
	DelimiterText = "";
	
	For Each StandardSeparator In StandardSeparators Do
		
		If Not IsBlankString(DelimiterText) Then
			
			DelimiterText = DelimiterText + ", ";
			
		EndIf;
		
		DelimiterText = DelimiterText + StandardSeparator.Name;
		
	EndDo;
	
	TextForExcludingUnsharedData = "";
	
	If ThereIsNoUndividedDataInControllingSubscription.Count() > 0 Then
		
		TextProblematicObjects = "";
		
		If RaiseException1 Then
			
			For Each ObjectWithIssue In ThereIsNoUndividedDataInControllingSubscription Do
				
				If Not IsBlankString(TextProblematicObjects) Then
					
					TextProblematicObjects = TextProblematicObjects + ", ";
					
				EndIf;
				
				TextProblematicObjects = TextProblematicObjects + ObjectWithIssue.FullName();
				
			EndDo;
			
		EndIf;
		
		SubscriptionText = "";
		
		For Each ControllingSubscription In ControllingSubscriptions Do
			
			If Not IsBlankString(SubscriptionText) Then
				
				SubscriptionText = SubscriptionText + ", ";
				
			EndIf;
			
			SubscriptionText = SubscriptionText + ControllingSubscription.Name;
			
		EndDo;
		
		TextForExcludingUnsharedData = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đối tượng metadata không nằm trong thành phần chia tách %1,
						|phải đưa vào thành phần của một trong các sự kiện đăng ký kiểm soát 
						|không có khả năng ghi lại dữ liệu không chia tách trong phiên làm việc chia tách: 
						|%2.';
						|ru = 'Объекты метаданных, не входящие в состав разделителей %1,
						|должны быть включены в состав одной из подписок на события, контролирующих
						|невозможность записи неразделенных данных в разделенных сеансах: 
						|%2.';
						|en = 'Metadata objects that are not included in the %1 separators
						|must be included in one of the event subscriptions
						|that control the inability to save shared data in separated sessions: 
						|%2.'; fa = 'Metadata objects that are not included in the %1 separators
						|must be included in one of the event subscriptions
						|that control the inability to save shared data in separated sessions: 
						|%2.';
						|it = 'Gli oggetti metadati non inclusi in separatori %1,
						| devono essere inclusi in una delle sottoscrizioni agli eventi che controllano
						|l''impossibilità di salvataggio di dati non separati nelle sezioni separate: 
						|%2.';
						|pl = 'Obiekty metadanych, nie wchodzące do zestawu separatorów %1,
						|powinny być włączone do zestawu jednej z subskrypcji na wydarzenia, które kontrolują 
						|niemożliwość zapisu niepodzielonych danych w rozdzielonych sesjach: 
						|%2.';
						|tr = '%1 ayırıcı parçası olmayan meta veri nesneleri
						|bölünmüş oturumlarda bölümlenmemiş verilerin yazılamamasını
						|denetleyen olay aboneliklerinden birine dahil edilmelidir: 
						|%2.'"),
					DelimiterText, SubscriptionText);
					
		If RaiseException1 Then
						
			ExceptionText = TextForExcludingUnsharedData + Chars.LF + Chars.LF 
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Các đối tượng metadata sau không thỏa mãn tiêu chí này: 
						|%1.';
						|ru = 'Следующие объекты метаданных не удовлетворяют этому критерию: 
						|%1.';
						|en = 'The following metadata objects do not meet this criterion: 
						|%1.'; fa = 'The following metadata objects do not meet this criterion: 
						|%1.';
						|it = 'I seguenti oggetti metadati non sono conformi a questo criterio: 
						|%1.';
						|pl = 'Następujące obiekty metadanych nie spełniają tego kryterium: 
						|%1.';
						|tr = 'Aşağıdaki meta veri nesneleri bu kriteri karşılamıyor: 
						|%1.'"),
				TextProblematicObjects);
			ExceptionsRaised.Add(ExceptionText);
			
		EndIf;
		
	EndIf;
	
	ExceptionTextWithMultipleDelimiters = "";
	
	If ObjectsWithMultipleSeparators.Count() > 0 Then
		
		TextProblematicObjects = "";
		
		For Each ObjectWithIssue In ObjectsWithMultipleSeparators Do
			
			If Not IsBlankString(TextProblematicObjects) Then
				
				TextProblematicObjects = TextProblematicObjects + ", ";
				
			EndIf;
			
			TextProblematicObjects = TextProblematicObjects + ObjectWithIssue.FullName();
			
		EndDo;
		
		ExceptionTextWithMultipleDelimiters = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối tượng metadata cấu hình phải được phân chia bởi không quá một đường chia tách: %1.';
				|ru = 'Объекты метаданных конфигурации должны быть разделены не более чем одним разделителем: %1.';
				|en = 'Configuration metadata objects must be separated only with one separator: %1.'; fa = 'Configuration metadata objects must be separated only with one separator: %1.';
				|it = 'Gli oggetti metadati della configurazione devono essere separati da non più di un separatore: %1.';
				|pl = 'Obiekty metadanych konfiguracji powinny być podzielone nie więcej niż jednym separatorem: %1.';
				|tr = 'Konfigürasyon meta verisi nesneleri en fazla bir ayırıcı ile ayrılmalıdır: %1.'"),
			DelimiterText);
			
		If RaiseException1 Then
			
			ExceptionText = ExceptionTextWithMultipleDelimiters + Chars.LF + Chars.LF 
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Các đối tượng sau không thỏa mãn tiêu chí này:
						|%1';
						|ru = 'Следующие объекты не удовлетворяют этому критерию:
						|%1';
						|en = 'The following objects do not meet this criterion:
						|%1'; fa = 'The following objects do not meet this criterion:
						|%1';
						|it = 'Следующие объекты не удовлетворяют этому критерию:
						|%1';
						|pl = 'The following objects do not meet this criterion:
						|%1';
						|tr = 'Aşağıdaki nesneler bu kriteri karşılamıyor: 
						|%1'"),
					TextProblematicObjects);
			ExceptionsRaised.Add(ExceptionText);
			
		EndIf;
		
	EndIf;
	
	ExceptionText = "";
	Result = New Structure;
	Result.Insert("MetadataObjects", MetadataObjectsWithViolations); // for backward compatibility
	Result.Insert("ExceptionText", ExceptionText); // for backward compatibility
	Result.Insert("ThereIsNoUndividedDataInControllingSubscription", ThereIsNoUndividedDataInControllingSubscription);
	Result.Insert("TextForExcludingUnsharedData", TextForExcludingUnsharedData);
	Result.Insert("ObjectsWithMultipleSeparators", ObjectsWithMultipleSeparators);
	Result.Insert("ExceptionTextWithMultipleDelimiters", ExceptionTextWithMultipleDelimiters);
	
	Iterator_SSLy = 1;
	
	For Each RaisedException In ExceptionsRaised Do
		
		If Not IsBlankString(Result.ExceptionText) Then
			
			Result.ExceptionText = Result.ExceptionText + Chars.LF + Chars.CR;
			
		EndIf;
		
		Result.ExceptionText = Result.ExceptionText + Format(Iterator_SSLy, "NFD=0; NG=0") + ". " + RaisedException;
		Iterator_SSLy = Iterator_SSLy + 1;
		
	EndDo;
	
	If RaiseException1 Then
		
		If Not IsBlankString(Result.ExceptionText) Then
			
			Raise NStr("vi = 'Đã tìm thấy lỗi trong cấu trúc metadata của cấu hình:';
						|ru = 'Обнаружены ошибки в структуре метаданных конфигурации:';
						|en = 'Errors are found in the configuration metadata structure:'; fa = 'Errors are found in the configuration metadata structure:';
						|it = 'Sono stati rilevati degli errori nella struttura della configurazione dei metadati:';
						|pl = 'Wykryto błędy w strukturze metadanych konfiguracji:';
						|tr = 'Meta veri yapılandırmasının yapısında bulunan hatalar:'") 
				+ Chars.LF + Chars.CR + Result.ExceptionText;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Controls the metadata structure based on the order of shared details
// in the configuration metadata tree.
//
Procedure ControllingDelimitersWhenUpdating() Export
	
	OrderOfApplicationData = 99;
	InternalDataOrder = 99;
	
	ApplicationSeparator = Metadata.CommonAttributes.DataAreaMainData;
	InternalSeparator = Metadata.CommonAttributes.DataAreaAuxiliaryData;
	
	Iterator_SSLy = 0;
	For Each CommonConfigurationProps In Metadata.CommonAttributes Do
		
		If CommonConfigurationProps = ApplicationSeparator Then
			OrderOfApplicationData = Iterator_SSLy;
		ElsIf CommonConfigurationProps = InternalSeparator Then
			InternalDataOrder = Iterator_SSLy;
		EndIf;
		
		Iterator_SSLy = Iterator_SSLy + 1;
		
	EndDo;
	
	If OrderOfApplicationData <= InternalDataOrder Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã phát hiện vi phạm cấu trúc metadata cấu hình: mục tin chung %1 phải 
                  |nằm trong cây metadata cấu hình trước mục tin chung 
                  |%2 theo thứ tự.';
                  |ru = 'Обнаружено нарушение структуры метаданных конфигурации: общий реквизит %1 должен
                  |быть расположен в дереве метаданных конфигурации до общего реквизита
                  |%2 по порядку.';
                  |en = 'Configuration metadata structure violation detected: common attribute %1
                  |must be placed before common attribute
                  |%2 in the configuration metadata tree.'; fa = 'Configuration metadata structure violation detected: common attribute %1
                  |must be placed before common attribute
                  |%2 in the configuration metadata tree.';
                  |it = 'È stata individuata una violazione della struttura della configurazione dei metadati: il requisito generale %1 deve 
                  | essere disposto sull''albero della configurazione dei metadati fino al requisito generale 
                  |%2 relativo all''ordine.';
                  |pl = 'Wykryto naruszenie struktury metadanych konfiguracji: ogólny rekwizyt %1 powinien
                  |być położony w drzewie metadanych konfiguracji do wspólnego rekwizytu
                  |%2 po kolei.';
                  |tr = 'Yapılandırma meta veri yapısında kırılma tespit edildi: ortak özellik
                  |, sırayla sıraya göre yapılandırma %1 metaveri 
                  |ağacında %2 yer almalıdır.'"),
			InternalSeparator.Name,
			ApplicationSeparator.Name);
		
	EndIf;
	
EndProcedure

// Returns the minimum version of the "1C" library:Service technology library", which
// can be used together with the current version of the BSP.
//
// Returns:
//   String - the minimum supported version of the BTS in the format PP.{P|PP}.ZZ.SS.
//
Function RequiredCTLVersion()
	
	Return "1.0.2.1";
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Working with information security parameters

// Returns an empty table of information security parameters.
//
Function InformationSecurityParameterTemplate()
	
	Result = New ValueTable;
	Result.Columns.Add("Name", New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	Result.Columns.Add("LongDesc", New TypeDescription("String", , New StringQualifiers(0, AllowedLength.Variable)));
	Result.Columns.Add("ForbiddenReading", New TypeDescription("Boolean"));
	Result.Columns.Add("RecordBan", New TypeDescription("Boolean"));
	Result.Columns.Add("Type", New TypeDescription("TypeDescription"));
	Return Result;
	
EndFunction

#Region DataClearing

Procedure ClearInformationDatabaseData(ExtensionsDeleting, DeleteCurrentUser = True)
	
	If Common.DataSeparationEnabled() Then
		Raise NStr(
			"vi = 'Trong cơ sở thông tin đã bật sử dụng chia tách, được phép sử dụng phương thức РаботаВМоделиСервиса.ОчиститьДанныеОбласти';
			|ru = 'В информационной базе включено разделение, допустимо использование метода РаботаВМоделиСервиса.ОчиститьДанныеОбласти';
			|en = 'Separation is enabled in the infobase. You can use the SaaSOperations.ClearAreaData method'; fa = 'Separation is enabled in the infobase. You can use the SaaSOperations.ClearAreaData method';
			|it = 'В информационной базе включено разделение, допустимо использование метода РаботаВМоделиСервиса.ОчиститьДанныеОбласти';
			|pl = 'Separation is enabled in the infobase. You can use the SaaSOperations.ClearAreaData method';
			|tr = 'Infobase''te ayırma etkinleştirildi, РаботаВМоделиСервиса.ОчиститьДанныеОбласти yöntemini kullanmasına izin verildi'");	
	EndIf;
	
	// Data
	ClearDataByAreaDataModel();
		
	// Users
	DeleteAreaUsers(DeleteCurrentUser);
		
	// Clearing the history.
	ClearUserWorkHistory();
		
	// Settings
	ClearSettingsStorages();
		
	If ExtensionsDeleting Then
		// Extensions
		RemoveAreaExtensions();
	EndIf;	
	
EndProcedure

Procedure DeleteApplicationData(DataArea = Undefined)
	
	If Not SeparatedDataUsageAvailable() Then
		Raise NStr(
			"vi = 'Việc xóa dữ liệu ứng dụng chỉ có thể thực hiện chỉ khi bật sử dụng đường chia tách';
			|ru = 'Удаление данных приложения может быть выполнено только при включенном использовании разделителей';
			|en = 'You can delete the application data only when the separators are enabled'; fa = 'You can delete the application data only when the separators are enabled';
			|it = 'Удаление данных приложения может быть выполнено только при включенном использовании разделителей';
			|pl = 'You can delete the application data only when the separators are enabled';
			|tr = 'Uygulama verilerinin silinmesi, yalnızca ayırıcılar etkinleştirildiğinde yapılabilir'");
	EndIf;
	
	If DataArea = Undefined Then
		DataArea = SessionSeparatorValue();
	EndIf;
	
	StoredData = New Structure();
	ExternalMonopolyModeIsSet = ExclusiveMode();
	ExclusiveModeSet = False;
	
	Try
	
		If Not ExternalMonopolyModeIsSet Then
			SetExclusiveMode(True);
			ExclusiveModeSet = True;
		EndIf;
		
		BeforeDeletingApplicationData(DataArea, StoredData);
		
		DisableUsageQueueJobs();
		EraseInfoBaseData();
		DeleteAreaUsers();
		RemoveAreaExtensions();
		
		AfterDeletingApplicationData(DataArea, StoredData);
		
		If ExclusiveModeSet Then
			SetExclusiveMode(False);
			ExclusiveModeSet = False;
		EndIf;
		
	Except
		
		If ExclusiveModeSet Then
			SetExclusiveMode(False);
		EndIf;
		
		Raise;
		
	EndTry;
	
EndProcedure

Procedure BeforeDeletingApplicationData(DataArea, StoredData)
	
	If Not InformationRegisters.DataOfClearedArea.AreaDataIsSaved(DataArea) Then
		InformationRegisters.DataOfClearedArea.SaveAreaData(DataArea);
	EndIf;
	
	StoredData.Insert("DataAreaKey", Constants.DataAreaKey.Get());
	
EndProcedure

Procedure DisableUsageQueueJobs()
	
	Query = New Query(
	"SELECT
	|	JobsQueue.Ref AS Job
	|FROM
	|	Catalog.JobsQueue AS JobsQueue
	|WHERE
	|	JobsQueue.Use");
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		Return;
		
	EndIf;
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		JobsQueue.ChangeJob(Selection.Job, New Structure("Use", False));
		
	EndDo;

EndProcedure

Procedure AfterDeletingApplicationData(DataArea, StoredData)
	
	Constants.DataAreaKey.Set(StoredData.DataAreaKey);
	
	DataModel = SaaSOperationsCached.GetAreaDataModel();
	
	For Each ModelItem In DataModel Do
		
		If IsFullNameOfObjectWithPredefinedData(ModelItem.Key) Then
			DisablePredefinedDataInitialization(ModelItem.Key);
		EndIf;
		
	EndDo;
	
	InformationRegisters.DataOfClearedArea.RestoreAreaData(DataArea);
	
EndProcedure

Procedure DisablePredefinedDataInitialization(FullMetadataObjectName)
	
	Manager = Common.ObjectManagerByFullName(FullMetadataObjectName);
	Manager.SetPredefinedDataInitialization(False);
	
EndProcedure

Procedure DeleteDataObject(RemovableObject)
	
	RemovableObject.DataExchange.Load = True;
	RemovableObject.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	RemovableObject.AdditionalProperties.Insert("DontControlObjectsToDelete");
	RemovableObject.Delete();

EndProcedure

Function ExcludeObjectFromCleanup(Object, ObjectParameters)
	
	ExcludeObject = False;
	
	If ObjectParameters.PredefinedSupported Then
		ExcludeObject = Object.Predefined;
	EndIf;
	
	Return ExcludeObject;
	
EndFunction

Function NewParametersOfObjectBeingDeleted()
	
	ObjectParameters = New Structure();
	ObjectParameters.Insert("PredefinedSupported", False);
	
	Return ObjectParameters;
	
EndFunction

Procedure DisableAndClearDataHistory(MetadataObject)
	
	If MetadataObject = Undefined Then
		Return;
	EndIf;
	
	DataHistory.DeleteVersions(MetadataObject);
	
	HistorySettings = DataHistory.GetSettings(MetadataObject);
	If HistorySettings <> Undefined Then
		DataHistory.SetSettings(MetadataObject, Undefined);
	EndIf;
	
EndProcedure

Procedure ClearDataByAreaDataModel()
	
	DataModel = SaaSOperationsCached.GetAreaDataModel();
	
	CleanupExceptions = New Array();
	CleanupExceptions.Add(Metadata.InformationRegisters.DataAreas.FullName());
	CleanupExceptions.Add(Metadata.InformationRegisters.TemporaryStorageFiles.FullName());
	CleanupExceptions.Add(Metadata.Constants.InformationAboutImportProcedure.FullName());
	CleanupExceptions.Add(Metadata.Constants.ParametersForLaunchingInteractiveImportProcedure.FullName());
	CleanupExceptions.Add(Metadata.Constants.DataAreaKey.FullName());
	CleanupExceptions.Add(Metadata.Constants.ExclusiveLockSet.FullName());
	CleanupExceptions.Add(
		Metadata.InformationRegisters.UseSuppliedExtensionsInDataAreas.FullName());
	
	CTLSubsystemsIntegration.OnFillClearingDBDataExceptions(CleanupExceptions);
	SaaSOperationsOverridable.OnFillClearingDBDataExceptions(CleanupExceptions);
		
	For Each ModelItem In DataModel Do
		
		FullMetadataObjectName = ModelItem.Key;
		MetadataObjectDetails = ModelItem.Value; // MetadataObject
		
		If CleanupExceptions.Find(FullMetadataObjectName) <> Undefined Then
			Continue;
		EndIf;
		
		ClearMetadataObjectData(FullMetadataObjectName, MetadataObjectDetails);
		
	EndDo;
	
EndProcedure

Procedure ClearUserWorkHistory()
	
	UserWorkHistory.ClearAll();
	
EndProcedure

Procedure ClearSettingsStorages()
	
	Repositories = New Array;
	Repositories.Add(ReportsVariantsStorage);
	Repositories.Add(FormDataSettingsStorage);
	Repositories.Add(CommonSettingsStorage);
	Repositories.Add(ReportsUserSettingsStorage);
	Repositories.Add(SystemSettingsStorage);
	Repositories.Add(DynamicListsUserSettingsStorage);
	
	For Each Storage In Repositories Do
		
		If TypeOf(Storage) <> Type("StandardSettingsStorageManager") Then
			
			// The settings will be deleted when the data is cleared.
			Continue;
			
		EndIf;
		
		Storage.Delete(Undefined, Undefined, Undefined);
		
	EndDo;
	
EndProcedure

#EndRegion

Procedure AuthenticateCurrentUser()
	
	If ExtensionsSaaS.ThereAreInstalledExtensionsModifyingDataStructure() Then
		
		Job = CloudTechnology.CompleteTaskWithExtensions(
			"UsersInternal.AuthenticateCurrentUser",
			Undefined,
			New UUID,
			NStr("vi = 'Đăng nhập người sử dụng hiện tại';
				|ru = 'Авторизация текущего пользователя';
				|en = 'Current user authorization'; fa = 'Current user authorization';
				|it = 'Autorizzazione utente corrente';
				|pl = 'Uwierzytelnianie bieżącego użytkownika';
				|tr = 'Mevcut kulllanıcının kimlik doğrulaması'"))
			.WaitForExecutionCompletion();
		
		If Job.State = BackgroundJobState.Canceled Then
			Raise NStr("vi = 'Nhiệm vụ đã bị hủy';
						|ru = 'Задание отменено';
						|en = 'Job is canceled'; fa = 'Job is canceled';
						|it = 'Task annullato';
						|pl = 'Zadanie anulowano';
						|tr = 'Görev iptal edildi'");
		ElsIf Job.State = BackgroundJobState.Failed Then
			Raise ErrorProcessing.DetailErrorDescription(Job.ErrorInfo);
		EndIf;
		
		UsersInternal.AuthenticateCurrentUser();
	Else
		UsersInternal.AuthenticateCurrentUser();
	EndIf;
	
EndProcedure

#EndRegion
