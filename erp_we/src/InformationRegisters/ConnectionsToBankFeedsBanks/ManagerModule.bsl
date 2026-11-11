#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// The function determines the Status of the connection and consent
//
// Parameters:
//	QueryOptions - Structure - request parameters
//	FillParameters - Structure - The fill parameters
//
// Returns:
//	Structure - Processing result:
//	* ConnectionInfo - String
//	* ConsentIsActive - Boolean
//	* ConnectionIsActive - Boolean
//
Function StatusOfConsentForCurrentConnection(QueryOptions, FillParameters) Export
	
	StructureReturn = New Structure("ConnectionInfo,ConsentIsActive,ConnectionIsActive", "", False, False);
	
	If QueryOptions.CompanyID = ""
		Or QueryOptions.ProviderID = ""
		Or QueryOptions.ConnectionID = "" Then
		Return StructureReturn;
	EndIf;	

	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	
	If ValueIsFilled(QueryOptions.ConnectionID)
		And ValueIsFilled(QueryOptions.ConsentID) Then
		
		ResponseParametersFromService = CheckConnectionAndConsentStatus(FillParameters);
		
		If ResponseParametersFromService.ResponseStatus = StatusesOfResponse.IsAnswered Then
			 
			 FillPropertyValues(StructureReturn, ResponseParametersFromService);
			 
		 EndIf;
		 
	EndIf;	

	Return StructureReturn;	 		 

EndFunction

// The function receives data in the service for further authorization
//
// Parameters:
//	FillParameters - Structure - The fill parameters
//
// Returns:
//	Structure - Processing result:
//	* ResponseStatus - String
//	* FillParameters - String
//	* ErrorsArray - Array of String
//
Function GettingAuthorizationData(FillParameters) Export
	
	QueryOptions = ExchangeWithBankFeedsServer.ConvertToRequestParameters(FillParameters);
	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	ProcessingResult = New Structure;
	ProcessingResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived);
	ProcessingResult.Insert("FillParameters", FillParameters);
	ProcessingResult.Insert("ErrorsArray", New Array());
	
	StatusOfConsent = StatusOfConsentForCurrentConnection(QueryOptions, FillParameters);
	
	// If you need to create a new connection, then we will reset the parameters of the existing connection 
	If FillParameters.NewConnectionOnly Then
		QueryOptions.ProviderID = "";	
		QueryOptions.ConnectionID = "";
		StatusOfConsent.ConsentIsActive = False;
	EndIf;	
	
	// If you have already received the ID, you don't need to get it again
	If QueryOptions.CompanyID = ""
		Or QueryOptions.ProviderID = ""
		Or QueryOptions.ConnectionID = ""
		Or Not StatusOfConsent.ConsentIsActive 
		Or Not StatusOfConsent.ConnectionIsActive  Then
		
		ResponseParametersFromService = ExchangeWithBankFeedsServer.RegisterConnection(QueryOptions);
		
		FillPropertyValues(ProcessingResult, ResponseParametersFromService);  
		
		If ResponseParametersFromService.ResponseStatus = StatusesOfResponse.IsAnswered  Then
			
			BeginTransaction();
			Try
		
				Block = New DataLock;
				LockItem = Block.Add("InformationRegister.ConnectionsToBankFeedsBanks");
				LockItem.Mode = DataLockMode.Exclusive;
				LockItem.SetValue("Organization", FillParameters.Organization);
				LockItem.SetValue("Bank",        FillParameters.Bank);
				Block.Lock();
				
				InformationRegisterEntry = InformationRegisters.ConnectionsToBankFeedsBanks.CreateRecordManager();
				
				InformationRegisterEntry.Organization = FillParameters.Organization;
				InformationRegisterEntry.Bank = FillParameters.Bank;
				InformationRegisterEntry.ServiceSettings= FillParameters.ServiceSettings;
				FillPropertyValues(InformationRegisterEntry, ResponseParametersFromService.FillParameters);
				
				StorageOfRegistrationDetails = New ValueStorage(FillParameters.RegistrationAttributes);
				
				InformationRegisterEntry.RegistrationAttributes = StorageOfRegistrationDetails;
				
				InformationRegisterEntry.Write();
				
				ProcessingResult.Insert("LinkToAuthorization", ResponseParametersFromService.LinkToAuthorization);
				
				CommitTransaction();
		
			Except
				
			RollbackTransaction();
			Raise;
				
			EndTry;
		EndIf;
		
	Else

		ProcessingResult.ResponseStatus = StatusesOfResponse.RequestIsNotNeededDataIsReady;
		
	EndIf;	
	
	Return ProcessingResult;
	
EndFunction	

// The function checks the Status of the connection and consent in the service
//
// Parameters:
//	FillParameters - Structure - The fill parameters
//
// Returns:
//	Structure - Processing result:
//	* ResponseStatus - String
//	* FillParameters - String
//	* ErrorsArray - Array of String
//	* ConnectionIsActive - Boolean
//	* ConsentIsActive - Boolean
//
Function CheckConnectionAndConsentStatus(FillParameters) Export
	
	QueryOptions = ExchangeWithBankFeedsServer.ConvertToRequestParameters(FillParameters);
	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	ProcessingResult = New Structure;
	ProcessingResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived);
	ProcessingResult.Insert("FillParameters", FillParameters);
	ProcessingResult.Insert("ErrorsArray", New Array());
	ProcessingResult.Insert("ConnectionIsActive", False);
	ProcessingResult.Insert("ConsentIsActive", False);  

	ConnectionInfo = NStr("vi = 'Chưa kích hoạt kết nối';
							|ru = 'Соединение не активно';
							|en = 'Connection is inactive'; fa = 'Connection is inactive';
							|it = 'Соединение не активно';
							|pl = 'Connection is inactive';
							|tr = 'Bağlantı etkin değil'");

	ProcessingResult.Insert("ConnectionInfo", ConnectionInfo);
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"InformationRegister.ConnectionsToBankFeedsBanks.Form.RecordForm.StartCheckingStatusOfConnectionAndConsent");
		
	// If you have already received the ID, you don't need to get it again
	If QueryOptions.CompanyID <> ""
		And QueryOptions.ConnectionID <> "" Then
		
		ResponseParametersFromService = ExchangeWithBankFeedsServer.CheckStatusOfConnectionAndConsent(QueryOptions);
		
		FillPropertyValues(ProcessingResult, ResponseParametersFromService);  
		
		If ResponseParametersFromService.ResponseStatus = StatusesOfResponse.IsAnswered  Then
			
			StatusOfConsent = ResponseParametersFromService.StatusOfConsent;	
			ValidityPeriodOfConsent = ResponseParametersFromService.ValidityPeriodOfConsent;	
			EndDateOfConsent = ResponseParametersFromService.EndDateOfConsent;	
			StatusOfConnection = ResponseParametersFromService.StatusOfConnection;	
			
			ProcessingResult.ConnectionIsActive = StatusOfConnection = "active";
			ProcessingResult.ConsentIsActive = StatusOfConsent = "active";
			
			If ProcessingResult.ConnectionIsActive 
				And ProcessingResult.ConsentIsActive Then
				
				If ValidityPeriodOfConsent = Undefined Then

					ConnectionInfo = NStr("vi = 'Đã kích hoạt kết nối';
											|ru = 'Соединение активно';
											|en = 'Connection is active'; fa = 'Connection is active';
											|it = 'Соединение активно';
											|pl = 'Connection is active';
											|tr = 'Bağlantı etkin'");
					
				Else	
					ConnectionInfo = 
						StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Thống nhất có hiệu lực: %1 ngày (%2)';
																						|ru = 'Согласие действует: %1 дней (%2)';
																						|en = 'Consent is valid: %1 days (%2)'; fa = 'Consent is valid: %1 days (%2)';
																						|it = 'Согласие действует: %1 дней (%2)';
																						|pl = 'Consent is valid: %1 days (%2)';
																						|tr = 'Onay geçerlidir: %1 gün (%2)'"), ValidityPeriodOfConsent, EndDateOfConsent);
				EndIf;
			
			ElsIf Not ProcessingResult.ConsentIsActive	Then
							
				ConnectionInfo = 
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1';
																					|ru = '%1';
																					|en = '%1'; fa = '%1';
																					|it = '%1';
																					|pl = '%1';
																					|tr = '%1'"), 
																			?(StatusOfConsent = "expired", NStr("vi = 'Đã quá hạn thống nhất';
																												|ru = 'Истек срок согласия';
																												|en = 'Consent expired'; fa = 'Consent expired';
																												|it = 'Истек срок согласия';
																												|pl = 'Consent expired';
																												|tr = 'Onay süresi sona ermiştir'"),
																			NStr("vi = 'Đã thu hồi thống nhất';
																				|ru = 'Отозвано согласие';
																				|en = 'Consent is revoked'; fa = 'Consent is revoked';
																				|it = 'Отозвано согласие';
																				|pl = 'Consent is revoked';
																				|tr = 'Onay geri çekildi'")));
			ElsIf Not ProcessingResult.ConnectionIsActive Then
							
				ConnectionInfo = NStr("vi = 'Chưa kích hoạt kết nối';
										|ru = 'Соединение не активно';
										|en = 'Connection is inactive'; fa = 'Connection is inactive';
										|it = 'Соединение не активно';
										|pl = 'Connection is inactive';
										|tr = 'Bağlantı etkin değil'");
				
			EndIf;	

			ProcessingResult.ConnectionInfo = ConnectionInfo;
		EndIf;
		
	EndIf;	
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
		
	Return ProcessingResult;
	
EndFunction	

// The function updates the connection in the service
//
// Parameters:
//	FillParameters - Structure - The fill parameters
//
// Returns:
//	Structure - Processing result:
//	* ResponseStatus - String
//	* FillParameters - String
//	* ErrorsArray - Array of String
//
Function ConnectionUpdate(FillParameters) Export
	
	QueryOptions = ExchangeWithBankFeedsServer.ConvertToRequestParameters(FillParameters);
	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	ProcessingResult = New Structure;
	ProcessingResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived);
	ProcessingResult.Insert("FillParameters", FillParameters);
	ProcessingResult.Insert("ErrorsArray", New Array());
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"InformationRegister.ConnectionsToBankFeedsBanks.Form.RecordForm.UpdateConnection");
			
	// If you have already received the ID, you don't need to get it again
	If QueryOptions.CompanyID <> ""
		Or QueryOptions.ConnectionID <> "" Then
		
		ResponseParametersFromService = ExchangeWithBankFeedsServer.UpdateConnection(QueryOptions);
		
		FillPropertyValues(ProcessingResult, ResponseParametersFromService);  
		
		If ResponseParametersFromService.ResponseStatus = StatusesOfResponse.IsAnswered  Then
			
			ProcessingResult.Insert("LinkToConnectionUpdate", ResponseParametersFromService.LinkToConnectionUpdate);
			
		EndIf;
		
	Else

		ProcessingResult.ResponseStatus = StatusesOfResponse.RequestIsNotNeededDataIsReady;
		
	EndIf;	
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
		
	Return ProcessingResult;
	
EndFunction	

// This function reads bank accounts by organization
//
// Parameters:
//	FillParameters - Structure - The fill parameters
//
// Returns:
//	Structure - Processing result:
//	See ExchangeWithBankFeedsServer.ReadingCompanySBankAccounts
//
Function ReadingBankAccountsByCompany(FillParameters) Export
	
	QueryOptions = ExchangeWithBankFeedsServer.ConvertToRequestParameters(FillParameters);
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"InformationRegister.ConnectionsToBankFeedsBanks.Form.ConnectionForm.ReadingBankAccountsByCompany");
		
	ResponseParametersFromService = ExchangeWithBankFeedsServer.ReadingCompanySBankAccounts(QueryOptions);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);	
	
	Return ResponseParametersFromService;
	
EndFunction

// This function connects the organization to the service
//
// Parameters:
//	FillParameters - Structure - The fill parameters
//
// Returns:
//	Structure - Processing result:
//	* ResponseStatus - String
//	* InvoiceId - String
//	* ErrorsArray - Array of String
//
Function ConnectingToService(FillParameters) Export

	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"InformationRegister.ConnectionsToBankFeedsBanks.Form.ConnectionForm.Performs connection k toservice");
	
	QueryOptions = ExchangeWithBankFeedsServer.ConvertToRequestParameters(FillParameters);
	ResponseParametersFromService = ExchangeWithBankFeedsServer.GetConnectionDataAfterUserAuthorization(
		QueryOptions);
	
	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	
	ProcessingResult = New Structure;
	ProcessingResult.Insert("ResponseStatus", ResponseParametersFromService.ResponseStatus);
	ProcessingResult.Insert("InvoiceId", ResponseParametersFromService.FillParameters.InvoiceId);
	ProcessingResult.Insert("ErrorsArray", ResponseParametersFromService.ErrorsArray);
	
	If ResponseParametersFromService.ResponseStatus = StatusesOfResponse.IsAnswered Then
		
		BeginTransaction();
		Try
		
			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.ConnectionsToBankFeedsBanks");
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem.SetValue("Organization", FillParameters.Organization);
			LockItem.SetValue("Bank",        FillParameters.Bank);
			Block.Lock();
			
			InformationRegisterEntry = InformationRegisters.ConnectionsToBankFeedsBanks.CreateRecordManager();
			
			InformationRegisterEntry.Organization = FillParameters.Organization;
			InformationRegisterEntry.Bank = FillParameters.Bank;
			InformationRegisterEntry.ServiceSettings= FillParameters.ServiceSettings;
			InformationRegisterEntry.ConnectionDate = CurrentSessionDate();
			FillPropertyValues(InformationRegisterEntry, ResponseParametersFromService.FillParameters);
			
			RegistrationAttributes = New ValueStorage(FillParameters.RegistrationAttributes);
			
			InformationRegisterEntry.RegistrationAttributes = RegistrationAttributes;
			
			InformationRegisterEntry.Write();
			
			CommitTransaction();
		
		Except
				
			RollbackTransaction();
			Raise;
				
		EndTry;
		
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
			
	Return ProcessingResult;

EndFunction	

// The function checks the connection to the service
//
// Parameters:
//	FillParameters - Structure - The fill parameters
//
// Returns:
//	Structure - Processing result:
//	* ResponseStatus - String
//	* InvoiceId - String
//	* ErrorsArray - Array of String
//
Function CheckingServiceConnectionUpdate(FillParameters) Export

	QueryOptions = ExchangeWithBankFeedsServer.ConvertToRequestParameters(FillParameters);
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"InformationRegister.ConnectionsToBankFeedsBanks.ManagerModule.CheckingServiceConnectionUpdate");	
	
	ResponseParametersFromService = ExchangeWithBankFeedsServer.GetConnectionDataAfterUserAuthorization(
		QueryOptions);
	
	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	
	If ResponseParametersFromService.ResponseStatus = StatusesOfResponse.IsAnswered Then
		
		BeginTransaction();
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.ConnectionsToBankFeedsBanks");
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem.SetValue("Organization", FillParameters.Organization);
			LockItem.SetValue("Bank",        FillParameters.Bank);
			Block.Lock();
			
			InformationRegisterEntry = InformationRegisters.ConnectionsToBankFeedsBanks.CreateRecordManager();
			InformationRegisterEntry.Organization = FillParameters.Organization;
			InformationRegisterEntry.Bank = FillParameters.Bank;
			InformationRegisterEntry.Read();
			
			InformationRegisterEntry.ConsentID = QueryOptions.ConsentID;
			
			InformationRegisterEntry.Write(True);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			Raise;
			
		EndTry;
		
	EndIf;
	
	ProcessingResult = New Structure;
	ProcessingResult.Insert("ResponseStatus", ResponseParametersFromService.ResponseStatus);
	ProcessingResult.Insert("InvoiceId", ResponseParametersFromService.FillParameters.InvoiceId);
	ProcessingResult.Insert("ErrorsArray", ResponseParametersFromService.ErrorsArray);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
		
	Return ProcessingResult;

EndFunction	

// The function revokes consent in the service over a connection
//
// Parameters:
//	FillParameters - Structure - The fill parameters
//
// Returns:
//	Structure - Processing result:
//	* ResponseStatus - String
//	* FillParameters - String
//	* StatusOfConsent - String
//	* ErrorsArray - Array of String
//
Function RevocationOfConsent(FillParameters) Export
	
	QueryOptions = ExchangeWithBankFeedsServer.ConvertToRequestParameters(FillParameters);
	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	ProcessingResult = New Structure;
	ProcessingResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived);
	ProcessingResult.Insert("FillParameters", FillParameters);
	ProcessingResult.Insert("ErrorsArray", New Array()); 
	ProcessingResult.Insert("StatusOfConsent", ""); 
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"InformationRegister.ConnectionsToBankFeedsBanks.Form.RecordForm.Revoke_Consent");
			
	If QueryOptions.CompanyID <> ""
		Or QueryOptions.ConnectionID <> "" Then
		
		ResponseParametersFromService = ExchangeWithBankFeedsServer.RevocationOfConsent(QueryOptions);
		
		FillPropertyValues(ProcessingResult, ResponseParametersFromService);  
		
		If ResponseParametersFromService.ResponseStatus = StatusesOfResponse.IsAnswered  Then
			
			ProcessingResult.StatusOfConsent = ResponseParametersFromService.StatusOfConsent;
			
		EndIf;
		
	EndIf;	
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
		
	Return ProcessingResult;
	
EndFunction	

#EndRegion

#EndIf