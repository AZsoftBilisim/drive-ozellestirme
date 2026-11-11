#Region EventHandlers

// Handler of the GET/version method
//
Function VersionGet(Query)
	
	Response = New HTTPServiceResponse(200);
	Data = New Structure;
	Data.Insert("version", ServicePayment.InterfaceVersion());
	ServicePayment.AddDataHeaders(Response);
	Response.SetBodyFromString(ServicePayment.JSONString(Data));
	
	ServicePayment.LogHTTPRequest(Query, Response);
	
	Return Response;
	
EndFunction

// Handler for the POST/setup method
//
Function SetSettingsAdd(Query)
	
	Try
		
		Data = ServicePayment.JSONData(Query.GetBodyAsString());
		JobState = TaskStateTemplate();
		
		RequiredProperties_ = StrSplit("version,url,login,password,subscriber",",");
		ErrorText = "";
		If Not CheckFilling(Data, RequiredProperties_, ErrorText) Then
			Response = ErrorResponse(10400, ErrorText);
			Return Response;
		EndIf;
					
		Constants.UseServicePayment.Set(True);
		Constants.Fresh1CServiceAddress.Set(Data.url);
		Constants.AccountSystemUserName.Set(Data.login);
		Common.WriteDataToSecureStorage(ServicePayment.OwnerOfAuthorizationPasswordInAccountSystem(), Data.password);
		CurrentUser = Users.CurrentUser();
		InformationRegisters.AuthorizationIn1cFresh.AddRecord(
			CurrentUser, Data.login, Data.password, Data.subscriber);
			
		Parameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID());
		Parameters.BackgroundJobDescription = NStr("vi = 'Thiết lập tùy chỉnh thanh toán của dịch vụ';
													|ru = 'Установка настроек оплаты сервиса';
													|en = 'Configure service payment settings'; fa = 'Configure service payment settings';
													|it = 'Установка настроек оплаты сервиса';
													|pl = 'Configure service payment settings';
													|tr = 'Servis Ödemeleri ayar kurulumu'");
		Parameters.WaitCompletion = 1;
		ExecutionParameters = TimeConsumingOperations.ExecuteProcedure(
			Parameters, "ServicePayment.SetServicePaymentSettings", Data.subscriber);
		JobState = TaskToRespondState(ExecutionParameters);
		
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StrTemplate(NStr("vi = 'Không thể thiết lập tùy chỉnh theo nguyên nhân: %1';
									|ru = 'Не удалось установить настройки по причине: %1';
									|en = 'Cannot set the settings due to: %1'; fa = 'Cannot set the settings due to: %1';
									|it = 'Не удалось установить настройки по причине: %1';
									|pl = 'Cannot set the settings due to: %1';
									|tr = 'Bu sebepten ayarlar kurulamadı: %1'"), 
			CloudTechnology.ShortErrorText(ErrorInfo));
		Response = ErrorResponse(10400,  ErrorText);
		ServicePayment.LogHTTPRequest(Query, Response);
		
		WriteLogEvent(ServicePayment.EventLogEvent(NStr("vi = 'Lỗi dữ liệu';
														|ru = 'Ошибка данных';
														|en = 'Data error'; fa = 'Data error';
														|it = 'Errore dati';
														|pl = 'Błąd danych';
														|tr = 'Veri hatası'")), 
			EventLogLevel.Error, Metadata.HTTPServices.Billing, , 
			CloudTechnology.DetailedErrorText(ErrorInfo)); 
		
		Return Response;
		
	EndTry;
		
	Response = New HTTPServiceResponse(200);
	ResponseData = ServicePayment.ResponseDataTemplate();
	ResponseData.Insert("tariff_loading_supported", ServicePayment.TariffLoadingIsSupported());
	ResponseData.Insert("tariff_loading_job", JobState); // Backward compatibility.
	ResponseData.Insert("setup_job", JobState); 
	ServicePayment.AddDataHeaders(Response);
	Response.SetBodyFromString(ServicePayment.JSONString(ResponseData));
	ServicePayment.LogHTTPRequest(Query, Response);
	
	Return Response;
	
EndFunction

// Handler for the POST/uninstall method
//
Function DeleteSettingsAdd(Query)
	
	Try
		
		Data = ServicePayment.JSONData(Query.GetBodyAsString());
		JobState = TaskStateTemplate();
		
		RequiredProperties_ = StrSplit("version,subscriber",",");
		ErrorText = "";
		If Not CheckFilling(Data, RequiredProperties_, ErrorText) Then
			Response = ErrorResponse(10400, ErrorText);
			Return Response;
		EndIf;

		Constants.UseServicePayment.Set(False);
		Constants.Fresh1CServiceAddress.Set("");
		Constants.AccountSystemUserName.Set("");
		Common.DeleteDataFromSecureStorage(ServicePayment.OwnerOfAuthorizationPasswordInAccountSystem());
		CurrentUser = Users.CurrentUser();
		InformationRegisters.AuthorizationIn1cFresh.DeleteRecord(CurrentUser);
		
		Parameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID());
		Parameters.BackgroundJobDescription = NStr("vi = 'Xóa tùy chỉnh thanh toán của dịch vụ';
													|ru = 'Удаление настроек оплаты сервиса';
													|en = 'Delete service payment settings'; fa = 'Delete service payment settings';
													|it = 'Удаление настроек оплаты сервиса';
													|pl = 'Delete service payment settings';
													|tr = 'Servis Ödemeleri ayar silinmesi'");
		Parameters.WaitCompletion = 1;
		ExecutionParameters = TimeConsumingOperations.ExecuteProcedure(
			Parameters, "ServicePayment.DeleteServicePaymentSettings", Data.subscriber);
		
		JobState = TaskToRespondState(ExecutionParameters);
		
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StrTemplate(NStr("vi = 'Không thể xóa tùy chỉnh theo nguyên nhân: %1';
									|ru = 'Не удалось удалить настройки по причине: %1';
									|en = 'Cannot delete the settings due to: %1'; fa = 'Cannot delete the settings due to: %1';
									|it = 'Не удалось удалить настройки по причине: %1';
									|pl = 'Cannot delete the settings due to: %1';
									|tr = 'Bu sebepten ayarlar silinemedi: %1'"), 
			CloudTechnology.ShortErrorText(ErrorInfo));
		Response = ErrorResponse(10400,  ErrorText);
		ServicePayment.LogHTTPRequest(Query, Response);
		
		WriteLogEvent(ServicePayment.EventLogEvent(NStr("vi = 'Lỗi dữ liệu';
														|ru = 'Ошибка данных';
														|en = 'Data error'; fa = 'Data error';
														|it = 'Errore dati';
														|pl = 'Błąd danych';
														|tr = 'Veri hatası'")), 
			EventLogLevel.Error, Metadata.HTTPServices.Billing, , 
			CloudTechnology.DetailedErrorText(ErrorInfo)); 
		
		Return Response;
		
	EndTry;
		
	Response = New HTTPServiceResponse(200);
	ResponseData = ServicePayment.ResponseDataTemplate();
	ResponseData.Insert("setup_job", JobState);
	ServicePayment.AddDataHeaders(Response);
	Response.SetBodyFromString(ServicePayment.JSONString(ResponseData));
	ServicePayment.LogHTTPRequest(Query, Response);
	
	Return Response;

EndFunction

// Handler for the GET /setup_result/ method{Task ID}
//
// URL parameters:
//  Task ID - String - ID of the setup task
//
Function SetDeleteSettingsStateGet(Query)
	
	JobID = New UUID(Query.URLParameters["JobID"]);
	ExecutionParameters = TimeConsumingOperations.ActionCompleted(JobID);
	ExecutionParameters.Insert("JobID", JobID);
	Response = New HTTPServiceResponse(200);
	ServicePayment.AddDataHeaders(Response);
	ResponseData = TaskToRespondState(ExecutionParameters);
	Response.SetBodyFromString(ServicePayment.JSONString(ResponseData));
	
	Return Response;
	
EndFunction

// Handler of the POST /bill/ method{Version}/*
//
// URL Parameters:
//  Version - String - numeric version of the interface
//
Function ProformaInvoiceAdd(Query)
	
	Return ResponseToInvoiceRequest(Query);
	
EndFunction

// Handler of the PUT/bill/ method{Version}/*
//
// URL Parameters:
//  Version - the version of the interface.
//
Function ProformaInvoiceChange(Query)
	
	Return ResponseToInvoiceRequest(Query);
	
EndFunction
	
#EndRegion

#Region Private

Function CheckFilling(Data, RequiredProperties_, ErrorText = "")
	
	MissingProperties = New Array;
	For Each Property In RequiredProperties_ Do
		If Not Data.Property(Property) Then
			MissingProperties.Add(Property);
		EndIf;
	EndDo;
	
	If MissingProperties.Count() > 0 Then
		ErrorText = StrTemplate(
			NStr("vi = 'Không có thuộc tính bắt buộc: %1';
				|ru = 'Отсутствуют обязательные свойства: %1';
				|en = 'Required properties are missing: %1'; fa = 'Required properties are missing: %1';
				|it = 'Mancano proprietà obbligatorie: %1';
				|pl = 'Brak obowiązkowych właściwości: %1';
				|tr = 'Zorunlu özellikler eksik: %1'"), 
			StrConcat(MissingProperties, ", "));
		Return False;
	EndIf;
	
	InterfaceVersion = Data.version;
	
	If InterfaceVersion > ServicePayment.InterfaceVersion() Then
		ErrorText = StrTemplate(
			NStr("vi = 'Ứng dụng không hỗ trợ phiên bản giao diện thanh toán %1 của bộ quản lý dịch vụ.';
				|ru = 'Версия интерфейса оплат %1 менеджера сервиса не поддерживается приложением.';
				|en = 'The application does not support the %1 payment interface version of Service Manager.'; fa = 'The application does not support the %1 payment interface version of Service Manager.';
				|it = 'Versione dell''interfaccia di pagamento %1 del manager di servizio non supportata dall''applicazione.';
				|pl = 'Wersja interfejsu opłat %1 menedżera usługi nie jest obsługiwana przez aplikację.';
				|tr = 'Servis yöneticisinin ödeme arabirimi sürümü %1, uygulama tarafından desteklenmiyor.'"),
			InterfaceVersion);
		Return False;
	EndIf; 
	
	Return True;
	
EndFunction

Function TaskStateTemplate()
	
	TaskDataTemplate = New Structure;
	TaskDataTemplate.Insert("id", "");
	TaskDataTemplate.Insert("status", "");
	TaskDataTemplate.Insert("error", False);
	TaskDataTemplate.Insert("brief_message", "");
	TaskDataTemplate.Insert("detail_message", "");
	
	Return TaskDataTemplate;
	
EndFunction

Function TaskToRespondState(ExecutionParameters)
	
	JobState = TaskStateTemplate();
	JobState.id = String(ExecutionParameters.JobID);
	If ExecutionParameters.Status = "Running" Then
		JobState.status = "Running";
	ElsIf ExecutionParameters.Status = "Completed2" Then
		JobState.status = "Completed";
	ElsIf ExecutionParameters.Status = "Error" Then
		JobState.status = "Error";
		JobState.error = True;
		JobState.brief_message = ExecutionParameters.BriefErrorDescription;
		JobState.detail_message = ExecutionParameters.DetailErrorDescription;
	ElsIf ExecutionParameters.Status = "Canceled" Then
		JobState.status = "Canceled";
	EndIf;
	
	Return JobState;
	
EndFunction

Function ResponseToInvoiceRequest(Query)
	
	Try
		QueryData = ServicePayment.InvoiceRequestData(Query);
		
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StrTemplate(NStr("vi = 'Không thể đọc dữ liệu do nguyên nhân: %1';
									|ru = 'Не удалось прочитать данные по причине: %1';
									|en = 'Cannot read the data. Reason: %1'; fa = 'Cannot read the data. Reason: %1';
									|it = 'Non è stato possibile leggere i dati a causa di: %1';
									|pl = 'Nie udało się odczytać danych z powodu: %1';
									|tr = 'Bu sebepten veriler okunamadı: %1'"), 
			CloudTechnology.ShortErrorText(ErrorInfo));
		Response = ErrorResponse(ServicePayment.ReturnCodeDataError(),  ErrorText);
		ServicePayment.LogHTTPRequest(Query, Response);
		
		WriteLogEvent(ServicePayment.EventLogEvent(NStr("vi = 'Lỗi dữ liệu';
														|ru = 'Ошибка данных';
														|en = 'Data error'; fa = 'Data error';
														|it = 'Errore dati';
														|pl = 'Błąd danych';
														|tr = 'Veri hatası'")), 
			EventLogLevel.Error, Metadata.HTTPServices.Billing, , 
			CloudTechnology.DetailedErrorText(ErrorInfo)); 
		
		Return Response;
		
	EndTry;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(QueryData.InvoiceId);
	ExecutionParameters.BackgroundJobDescription = StrTemplate(
		NStr("vi = 'Chuẩn bị hóa đơn thanh toán theo truy vấn %1.';
			|ru = 'Подготовка счета на оплату по запросу %1.';
			|en = 'Prepare a proforma invoice for request %1.'; fa = 'Prepare a proforma invoice for request %1.';
			|it = 'Preparazione fattura di pagamento della richiesta %1.';
			|pl = 'Przygotowanie rachunko do opłaty według zapytania %1.';
			|tr = '%1 sorguya göre ticari fatura hazırlama.'"), QueryData.InvoiceId);
	ExecutionParameters.WaitCompletion = 0;
	TimeConsumingOperations.ExecuteProcedure(ExecutionParameters, "ServicePayment.PrepareInvoiceForPayment", QueryData);
	
	Response = New HTTPServiceResponse(200);
	ResponseData = ServicePayment.ResponseDataTemplate();
	ServicePayment.AddDataHeaders(Response);
	Response.SetBodyFromString(ServicePayment.JSONString(ResponseData));
	ServicePayment.LogHTTPRequest(Query, Response);
	
	Return Response;

EndFunction

Function ErrorResponse(ErrorCode, ErrorText)
	
	Response = New HTTPServiceResponse(400);
	Data = ServicePayment.ResponseDataTemplate(ErrorCode, ErrorText);
	ServicePayment.AddDataHeaders(Response);
	Response.SetBodyFromString(ServicePayment.JSONString(Data));
	Return Response;
	
EndFunction
  
#EndRegion 

