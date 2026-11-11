#Region Internal

// Defines logical storage managers.
//
// Parameters:
//   AllLogicalStorageManagers - Map of String - Logical Storage Managers:
//    * Key - String - ID of the logical storage;
//    * Value - CommonModule - logical storage Manager.
//
//@skip-check module-empty-method
Procedure LogicalStorageManagers(AllLogicalStorageManagers) Export
		
	If Common.SubsystemExists("CloudTechnology.ApplicationsMigration") Then
		ApplicationMigrationModule = Common.CommonModule("ApplicationsMigration");
		AllLogicalStorageManagers.Insert("migration", ApplicationMigrationModule);
	EndIf;
	
EndProcedure

// Defines physical storage managers.
//
// Parameters:
//   AllPhysicalStorageManagers - Map of String - Physical Storage Managers:
//    * Key - String - ID of the physical storage;
//    * Value - CommonModule - physical storage Manager.
//
//@skip-check module-empty-method
Procedure PhysicalStorageManagers(AllPhysicalStorageManagers) Export
	
EndProcedure

// Defines the validity period of the temporary ID.
//
// Parameters:
//   ValidityPeriodOfTemporaryID - Number - period of validity of the temporary ID.
//
//@skip-check module-empty-method
Procedure ValidityPeriodOfTemporaryID(ValidityPeriodOfTemporaryID) Export
	
EndProcedure

// Determines the size of the data receiving block.
//
// Parameters:
//   DataBlockSize - Number - the size of the data acquisition block, in bytes.
//
//@skip-check module-empty-method
Procedure DataBlockSize(DataBlockSize) Export
	
EndProcedure

// Determines the size of the data sending block.
//
// Parameters:
//   BlockSizeForSendingData - Number - the size of the data sending block, in bytes.
//
//@skip-check module-empty-method
Procedure BlockSizeForSendingData(BlockSizeForSendingData) Export
	
EndProcedure

// Called if there is an error receiving data.
//
// Parameters:
//   Response - HTTPServiceResponse - response of the service when receiving data.
//
//@skip-check module-empty-method
Procedure ErrorReceivingData(Response) Export
	
	CommonCTL.TechnologyLogEntry("GetData.Error", New Structure("StatusCode, LongDesc", Response.StatusCode, Response.GetBodyAsString()));
	
	WriteLogEvent(
		NStr("vi = 'Truyền dữ liệu.Nhận';
			|ru = 'Передача данных.Получение';
			|en = 'Data transfer.Receiving'; fa = 'Data transfer.Receiving';
			|it = 'Trasferimento dati. Ricezione';
			|pl = 'Przekazanie danych.Otrzymanie';
			|tr = 'Veri transferi. Alım.'", Common.DefaultLanguageCode()),
		EventLogLevel.Error,
		,
		,
		StrTemplate(
			NStr("vi = 'Mã trạng thái: %1 %2';
				|ru = 'Код состояния: %1 %2';
				|en = 'Status code: %1 %2'; fa = 'Status code: %1 %2';
				|it = 'Codice dello stato: %1 %2';
				|pl = 'Kod statusu: %1 %2';
				|tr = 'Durum kodu: %1 %2'", Common.DefaultLanguageCode()),
			Response.StatusCode,
			Chars.LF + Response.GetBodyAsString()));
	
EndProcedure

// Called if there is an error sending data.
//
// Parameters:
//   Response - HTTPServiceResponse - service response when sending data.
//
//@skip-check module-empty-method
Procedure AnErrorOccurredWhileSendingData(Response) Export
	
	CommonCTL.TechnologyLogEntry("DataSending.Error", New Structure("StatusCode, LongDesc", Response.StatusCode, Response.GetBodyAsString()));
	
	WriteLogEvent(
		NStr("vi = 'Chuyển dữ liệu.Gửi';
			|ru = 'Передача данных.Отправка';
			|en = 'Data transfer.Sending'; fa = 'Data transfer.Sending';
			|it = 'Trasmissione dati. Invio';
			|pl = 'Przekazanie danych. Wysyłanie';
			|tr = 'Veri transfer.Gönderim'", Common.DefaultLanguageCode()),
		EventLogLevel.Error,
		,
		,
		StrTemplate(
			NStr("vi = 'Mã trạng thái: %1 %2';
				|ru = 'Код состояния: %1 %2';
				|en = 'Status code: %1 %2'; fa = 'Status code: %1 %2';
				|it = 'Codice dello stato: %1 %2';
				|pl = 'Kod statusu: %1 %2';
				|tr = 'Durum kodu: %1 %2'", Common.DefaultLanguageCode()),
			Response.StatusCode,
			Chars.LF + Response.GetBodyAsString()));
	
EndProcedure

// Called when the name of a temporary file is received.
//
// Parameters:
//   TempFileName - String - name of the temporary file.
//   Extension - String - the desired extension of the temporary file name.
//   Additional parameters - Structure - additional parameters of the temporary file.
//
//@skip-check module-empty-method
Procedure OnGetTemporaryFileName(TempFileName, Extension) Export
	
EndProcedure

// Called when the temporary ID is extended.
//
// Parameters:
//   Id - String - the ID of the request.
//   Date - Date - date when the request was registered.
//   Query - Structure - the original HTTP request:
//    * HTTPMethod - String - HTTP method;
//    * BaseURL - String - the base part of the URL request, including the service name;
//    * Headers - FixedMap of String - HTTP request headers;
//    * RelativeURL - String - the relative part of the URL (relative to the service);
//    * URLParameters - FixedMap of String - parts of the URL that were parameterized in the template;
//    * QueryOptions - FixedMap of String - request parameters (in the URL bar, the parameters follow the request sign);
//    * QueryID - String - unique request ID;
//    * RequestType_ - String - request type;
//    * TempFileName - String - the name of the temporary file used.
//
//@skip-check module-empty-method
Procedure OnExtendTemporaryIDValidity(Id, Date, Query) Export

EndProcedure

// Called when the Proxy used to connect to the server is received.
// 
// Parameters:
//  Proxy - Undefined, InternetProxy - The proxy used to connect to the server.
//  URIStructure - Structure - Fields:
//    * Schema - String - the scheme of the URI
//    * Login - String - login from the URI
//    * Password - String - password from the URI
//    * Host - String - host from URI
//    * Port - Number - port from URI
//    * PathAtServer - String - the <path> part?<parameters>#<anchor> from URI
//
//@skip-check module-empty-method
Procedure OnGetProxy(Proxy, URIStructure) Export

	Proxy = GetFilesFromInternet.GetProxy(URIStructure.Schema);

EndProcedure

#EndRegion