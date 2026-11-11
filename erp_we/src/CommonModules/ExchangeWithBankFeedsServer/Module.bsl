
////////////////////////////////////////////////////////////////////////////////
// The Bankfeedsserver service exchange: The server part of the service and 1C exchange mechanism
//
////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns True if the current user has the System Administrator role enabled.
// Users with the System Administrator role can edit unshared objects,
//  but cannot edit split objects.
//
// Returns:
//   Boolean - True if the current user has the System Administrator role enabled.
//
Function HasRoleSystemAdministrator() Export

	ForPrivilegedMode = False;
	CheckSystemAdministrationRights = True;
	Result = Users.IsFullUser(
		, // Check the current user.
		CheckSystemAdministrationRights,
		ForPrivilegedMode);

	Return Result;

EndFunction

// Checks the connection to the service
// 
// Parameters:
// 	BankAccount - CatalogRef.CompaniesBankAccounts - Bank account
// 
// Returns:
// Boolean - True if the bank account is connected to the service
//
Function TestServiceConnection(BankAccount) Export

	BankAccountParameters = Common.ObjectAttributesValues(
							BankAccount, "ManualBankDetailsChange,Bank,Owner,BankFeedsAccountID,UseBankFeedsBankExchange"); 
							
	If Not BankAccountParameters.UseBankFeedsBankExchange
		Or BankAccountParameters.BankFeedsAccountID	= "" Then

		Return False;
		
	EndIf;	
							
	If BankAccountParameters.ManualBankDetailsChange Then
			
		CurBank = BankAccount;
	Else
		
		CurBank = BankAccountParameters.Bank;
		
	EndIf;	
	
	CurrentSetting = ConfigureExchange(BankAccountParameters.Owner, CurBank);
	
	Return ValueIsFilled(CurrentSetting)
	
EndFunction	

// Defines the current session date
//
// Returns:
//  Date - session date
//
Function LocalCurDate() Export
	
	Return CurrentSessionDate();
	
EndFunction

#Region StateOfPaymentDocument

// Fills in the State of the payment document on the form
//
// Parameters:
//   Form - ClientApplicationForm - the form of the document
//    
Procedure WhenCreatingPaymentDocument(Form) Export
	
	Object = Form.Object;
	
	Form.StateOfBankFeeds = StateOfPaymentDocument(Object.Ref);
	
EndProcedure	

// If the Use by Exchanges functionality is not enabled
// , the bank direct State element is deleted.
//
// Parameters:
//   Form - ClientApplicationForm - the form of the document.
//    
Procedure WhenCreatingDocumentFormOnServer(Form) Export

	Items = Form.Items;
	
	
EndProcedure

// After recording the Cash debiting, the procedure generates an entry that has not been sent to the Bank Feeds transaction statusreferences
//
// Parameters:
//   Object - DocumentObject - It is called in the documents that need to record the initial Status of the transaction    
//    
Procedure AfterRecordingPaymentDocument(Object) Export
	
	If Not GetFunctionalOption("UseBankFeedsExchange") Then
		Return ;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("Ref", Object.Ref);
	Query.Text = 
	"SELECT
	|	BankAccountIssue.Ref AS PaymentDocument
	|FROM
	|	Document.BankAccountIssue AS BankAccountIssue
	|		LEFT JOIN Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|		ON BankAccountIssue.BankAccount = CompaniesBankAccounts.Ref
	|		LEFT JOIN InformationRegister.BankFeedsTransactionStatuses AS BankFeedsTransactionStatuses
	|		ON BankAccountIssue.Ref = BankFeedsTransactionStatuses.Object
	|WHERE
	|	BankAccountIssue.Ref = &Ref
	|	AND CompaniesBankAccounts.BankFeedsAccountID <> """"
	|	AND BankFeedsTransactionStatuses.Status IS NULL";   
	
	Result = Query.Execute().Select();
	
	While Result.Next() Do

		PaymentDocument = Result.PaymentDocument;
		
		BeginTransaction();
		Try
		
			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.BankFeedsTransactionStatuses");
			LockItem.Mode = DataLockMode.Exclusive;
			LockItem.SetValue("Object", PaymentDocument);
			Block.Lock();
			
			Set = InformationRegisters.BankFeedsTransactionStatuses.CreateRecordSet();
			Set.Filter.IDType.Set(Enums.BankFeedsIDTypes.ByPaymentOrder);
			Set.Filter.Object.Set(PaymentDocument);
			
			Record = Set.Add();
			
			Record.Object = PaymentDocument;
			Record.IDType = Enums.BankFeedsIDTypes.ByPaymentOrder;
			
			Record.Status = Enums.BankFeedsPaymentDocumentStatuses.NotShipped_5;
			Record.TransactionID = "";
			
			Set.Write(True);
			
			CommitTransaction();
		
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
	EndDo;	
	
EndProcedure	

#EndRegion

#Region FormParameters

// Returns mail from the company
//
// Parameters:
//   Organization - CatalogRef.Companies - Organization
//    
// 
// Returns:
//  String - Mail
//
Function CompanySMail(Organization) Export
	
	Return ContactsManager.ObjectContactInformation(
			Organization,Catalogs.ContactInformationKinds.EmailCompanies, CurrentSessionDate());
	
EndFunction	

#EndRegion

#Region QueryParameters

// Returns the structure of the parameters for the request. Data is collected based on the input parameters
// Used to check the connection. when the company is unknown.
//
// Parameters:
//   FillParameters - Structure - data structure
// 
// Returns:
//  See ServiceRequestParameters
//
Function ConvertToRequestParametersForConnectionVerification(FillParameters) Export
	
	QueryOptions = ServiceRequestParameters();
	
	SetPrivilegedMode(True);
	AuthorizationSettings = Catalogs.IntegrateWithBankFeeds.AuthorizationSettings(
		FillParameters.ServiceSettings);
	SetPrivilegedMode(False);

	FillPropertyValues(QueryOptions, AuthorizationSettings); 
	FillPropertyValues(QueryOptions, FillParameters); 
	
	QueryOptions.Service = 
		Common.ObjectAttributeValue(FillParameters.ServiceSettings, "Service");
		
	QueryOptions.ServiceAddress = ServiceAddress(QueryOptions.Service);

	AddressDiagram = CommonClientServer.URIStructure(QueryOptions.ServiceAddress);
	QueryOptions.HostName = AddressDiagram.Host;  
	
    Return QueryOptions;
	
EndFunction	

// Returns the structure of the parameters for the request. Data is collected based on the input parameters
//
// Parameters:
//   FillParameters - Structure - data structure
// 
// Returns:
//  See ServiceRequestParameters
//
Function ConvertToRequestParameters(FillParameters) Export
	
	QueryOptions = ServiceRequestParameters();
	
	SetPrivilegedMode(True);
	AuthorizationSettings = Catalogs.IntegrateWithBankFeeds.AuthorizationSettings(
		FillParameters.ServiceSettings);
	SetPrivilegedMode(False);

	FillPropertyValues(QueryOptions, AuthorizationSettings); 
	FillPropertyValues(QueryOptions, FillParameters); 
	
	QueryOptions.Service = 
		Common.ObjectAttributeValue(FillParameters.ServiceSettings, "Service");
		
	QueryOptions.ServiceAddress = ServiceAddress(QueryOptions.Service);

	AddressDiagram = CommonClientServer.URIStructure(QueryOptions.ServiceAddress);
	QueryOptions.HostName = AddressDiagram.Host;  
	
	If ValueIsFilled(QueryOptions.BankAccount) Then
		
		BankAccountParameters = Common.ObjectAttributesValues(
			QueryOptions.BankAccount, "AccountNumber,BankFeedsAccountID,CashCurrency");
			
		QueryOptions.BankAccountNumber = BankAccountParameters.AccountNumber;
		QueryOptions.InvoiceId = BankAccountParameters.BankFeedsAccountID;	
		QueryOptions.AccountCurrency = BankAccountParameters.CashCurrency;
		
	EndIf;	

	ConnectionSetup = CompanyAndBankSettings(FillParameters);
	
	If Not ConnectionSetup = Undefined Then
		FillPropertyValues(QueryOptions, ConnectionSetup);
	EndIf;	

	ComplianceOfRegistrationDetails = 
		BankFeedsDictionaryInternal.ComplianceOfRegistrationDetailsOnFormWithRequestDetails();
		
		If TypeOf(FillParameters) = Type("Structure") 
			And FillParameters.Property("RegistrationAttributes")
			And ValueIsFilled(FillParameters.RegistrationAttributes) Then	
		
		 RegistrationAttributes = FillParameters.RegistrationAttributes;
		
	ElsIf Not ConnectionSetup = Undefined Then
		
		RegistrationAttributes = ConnectionSetup.RegistrationAttributes.Get();
		
	EndIf;
	
	If ValueIsFilled(RegistrationAttributes) Then
		For Each CurrentField In RegistrationAttributes Do
			     CurTimeMatchingOfCurTimeField = ComplianceOfRegistrationDetails[CurrentField.Key];
				 
				ValueOfRegistrationDetails = CurrentField.Value;				 
				 
			If CurTimeMatchingOfCurTimeField <> Undefined Then 
				
				If TypeOf(CurrentField.Value) = Type("CatalogRef.WorldCountries") Then
					
					ValueOfRegistrationDetails = Common.ObjectAttributeValue(CurrentField.Value, "CodeAlpha2");
					
				ElsIf TypeOf(CurrentField.Value) = Type("EnumRef.GenderPersons") Then	
					
					If CurrentField.Value = Enums.GenderPersons.Feminine Then
						ValueOfRegistrationDetails = "female";
					Else 
						ValueOfRegistrationDetails= "male";
					EndIf;	

				ElsIf TypeOf(CurrentField.Value) = Type("Date") Then	
					
					 ValueOfRegistrationDetails = Format(CurrentField.Value, "DF=yyyy-MM-dd");
					
				EndIf;	
				
				QueryOptions.RegistrationDetailsForRequest.Insert(
													CurTimeMatchingOfCurTimeField, ValueOfRegistrationDetails);
			EndIf;	

		EndDo;	
	EndIf;	
	
	CompanyParameters = Catalogs.Companies.GetBusinessDetails(QueryOptions.Organization);
	
	QueryOptions.CompanyRegistrationCountryCode = 
					Common.ObjectAttributeValue(CompanyParameters.RegistrationCountry, "CodeAlpha2");
	
	QueryOptions.IPAddress = DigitalFootprint().IPAddress;
	
    Return QueryOptions;
	
EndFunction	

// Returns the request body using the Command
//
// Parameters:
//   Service - EnumRef.BankFeedsServices - the service to use to find the Command body
//   Command - String - Command
// 
// Returns:
//  String - Command body 
//
Function RequestBodyForCommand(Service, Command) Export
	
	 ListOfCommandBodies = BankFeedsDictionaryInternal.ListOfCommandBodies(Service);
	 
	 Return ListOfCommandBodies[Command];
	
EndFunction	

// Returns data from the register of connection informationbankfeeds 
//
// Parameters:
//   Organization - CatalogRef.Companies - Organization
//   Bank - CatalogRef.BankClassifier - Bank 
// 
// Returns:
//   Structure  - parameter structure: 
//		* ConnectionDate - Date - date of activation.
//		* ServiceSettings - CatalogRef.IntegrateWithBankFeeds - setting up the service.
//
Function ConfigureExchange(Organization, Bank) Export

	 BankFeedsServiceIsUsed = Constants.UseBankFeedsService.Get(); 

	 ConfigureExchange = New Structure("ConnectionDate,ServiceSettings", 
	 							Date(1,1,1,0,0,0), Catalogs.IntegrateWithBankFeeds.EmptyRef());
	 
	 If Not BankFeedsServiceIsUsed Then
		 Return ConfigureExchange;
	 EndIf;	 
	
	 Query = New Query; 
	 Query.SetParameter("Organization",Organization);
	 Query.SetParameter("Bank",Bank);  
	 Query.Text = 
	 "SELECT
	 |	ConnectionsToBankFeedsBanks.Organization AS Organization,
	 |	ConnectionsToBankFeedsBanks.Bank AS Bank,
	 |	ConnectionsToBankFeedsBanks.ConnectionDate AS ConnectionDate,
	 |	ConnectionsToBankFeedsBanks.ServiceSettings AS ServiceSettings
	 |FROM
	 |	InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	 |WHERE
	 |	ConnectionsToBankFeedsBanks.Organization = &Organization
	 |	AND ConnectionsToBankFeedsBanks.Bank = &Bank"; 
	 
	 Result = Query.Execute().Select();
	 
	 If Result.Next() Then
		 
		 // By date, we determine that the connection has passed all the stages
		 If Result.ConnectionDate <> Date(1,1,1,0,0,0) Then 
			 
			FillPropertyValues(ConfigureExchange , Result); 
			
			Return ConfigureExchange;
		EndIf;	
		 
	 EndIf;
	 
	 Return ConfigureExchange;
	
EndFunction	

#EndRegion

#Region ServiceRequests

// The function executes a request to verify the connection to the service
//
// Parameters:
//   QueryOptions - Structure - the data set for the request
// 
// Returns:
//  Structure - The result of the query:
//  * ResponseStatus - String
//  * FillParameters - String - Structure
//  * ErrorsArray - Array of String
//
Function TestConnection(QueryOptions) Export

	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	
	QueryExecutionResult = New Structure();
	QueryExecutionResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived); 
	QueryExecutionResult.Insert("FillParameters", QueryOptions);
	QueryExecutionResult.Insert("ErrorsArray", New Array());

	CommandsOfServices = BankFeedsDictionaryInternal.CommandsOfServices(QueryOptions.Service);   
	QueryOptions.HTTPMethod = "GET";
	
	// Check connection
	ResponseUserHasBeenCreated = MakeRequestToService(CommandsOfServices.GetListOfCompanies, QueryOptions);
	
	If ResponseUserHasBeenCreated["data"] <> Undefined Then               
		
		QueryExecutionResult.ResponseStatus = StatusesOfResponse.IsAnswered;
		
	EndIf;	
	
	Return QueryExecutionResult;
	
EndFunction

// The function executes a set of connection update requests
//
// Parameters:
//   QueryOptions - Structure - the data set for the request
// 
// Returns:
//  Structure - The result of the query:
//  	*LinkToConnectionUpdate - String 
//  	*ResponseStatus - String
//  	*FillParameters - Structure:
//  		**Organization - CatalogRef.Companies - Organization
//  		**Bank - CatalogRef.BankClassifier - Bank
//  		**email - String - String
//  	*ErrorsArray - Array of String 
//
Function UpdateConnection(QueryOptions) Export
	
	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	
	QueryExecutionResult = New Structure();
	QueryExecutionResult.Insert("LinkToConnectionUpdate", ""); 
	QueryExecutionResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived); 
	QueryExecutionResult.Insert("FillParameters", QueryOptions);
	QueryExecutionResult.Insert("ErrorsArray", New Array());
	
	CommandsOfServices = BankFeedsDictionaryInternal.CommandsOfServices(QueryOptions.Service);   
	
	// Making a request to update the connection
	BodyStructure = RequestBodyForCommand(QueryOptions.Service, CommandsOfServices.UpdateConnection);
	BodyStructure.Data.customer_id = QueryOptions.CompanyID; 	
	BodyStructure.Data.connection_id = QueryOptions.ConnectionID; 
	BodyStructure.Data.consent.from_date = Format(LocalCurDate(), "DF=yyyy-MM-dd");  
	BodyStructure.Data.attempt.custom_fields.numberAccount = QueryOptions.BankAccountNumber;
	BodyStructure.Data.attempt.custom_fields.nameBank = 
				Common.ObjectAttributeValue(QueryOptions.Bank, "Description");
	BodyStructure.Data.attempt.custom_fields.RecordID = QueryOptions.RecordID;
	
	QueryOptions.RequestBody = BodyStructure;
	QueryOptions.HTTPMethod = "POST";
	ResponseLinkToAuthorization = MakeRequestToService(CommandsOfServices.UpdateConnection, QueryOptions);
	Data = ResponseLinkToAuthorization["data"];
	LinkToConnectionUpdate = Data["redirect_url"];
	
	If LinkToConnectionUpdate = "" Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Dịch vụ: %1 gửi liên kết trống để cập nhật kết nối';
					|ru = 'Сервис: %1 отправляет пустую ссылку на обновление соединения';
					|en = 'Service: %1 sends an empty link to update the connection'; fa = 'Service: %1 sends an empty link to update the connection';
					|it = 'Сервис: %1 отправляет пустую ссылку на обновление соединения';
					|pl = 'Service: %1 sends an empty link to update the connection';
					|tr = 'Hizmet: %1 bağlantıyı güncellemek için boş bir bağlantı gönderir'"),
				QueryOptions.Service);
		QueryExecutionResult.ErrorsArray.Add(MessageText);
	
		Return QueryExecutionResult;

	EndIf;	
		
	QueryExecutionResult.LinkToConnectionUpdate = LinkToConnectionUpdate;
	QueryExecutionResult.ResponseStatus = StatusesOfResponse.IsAnswered;
	QueryExecutionResult.FillParameters = QueryOptions;
	
	Return QueryExecutionResult;
EndFunction	

// The function executes a set of requests for revocation of consent
//
// Parameters:
//   QueryOptions - Structure - the data set for the request
// 
// Returns:
//  Structure - The result of the query:
//  	*LinkToConnectionUpdate - String 
//  	*ResponseStatus - String
//  	*FillParameters - Structure:
//  		**Organization - CatalogRef.Companies - Organization
//  		**Bank - CatalogRef.BankClassifier - Bank
//  		**email - String - String
//  	*ErrorsArray - Array of String 
//
Function RevocationOfConsent(QueryOptions) Export
	
	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	
	QueryExecutionResult = New Structure();
	QueryExecutionResult.Insert("StatusOfConsent", ""); 
	QueryExecutionResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived); 
	QueryExecutionResult.Insert("FillParameters", QueryOptions);
	QueryExecutionResult.Insert("ErrorsArray", New Array());
	
	CommandsOfServices = BankFeedsDictionaryInternal.CommandsOfServices(QueryOptions.Service);   
	
	// We make a request to search for consents
	CommandParameters = BankFeedsDictionaryInternal.CommandParameters(CommandsOfServices.GetListOfConsents);
	Connection_idParameter = CommandParameters.Connection_id;
	CommandParameter1 = StrReplace(Connection_idParameter, "%CONNECTION_ID%", QueryOptions.ConnectionID);
	ParametersString1 = "?" + CommandParameter1;
	
	QueryOptions.HTTPMethod = "GET";    
	
	ContinueReadingPages = True;
	PageParameterString = "";
	
	While ContinueReadingPages Do 
		
		ResponseLinkToAuthorization = MakeRequestToService(CommandsOfServices.GetListOfConsents, 
										QueryOptions, ParametersString1 + PageParameterString);
		Data = ResponseLinkToAuthorization["data"];
		Meta = ResponseLinkToAuthorization["meta"];
		
		ArrayOfConsentIds = New Array();
		
		For Each CurRow In Data Do
			
			If CurRow["status"] = "active" Then
				ArrayOfConsentIds.Add(CurRow["id"]);
			EndIf;	
			
		EndDo;	
		
		If Meta["next_id"] = Undefined Then
			ContinueReadingPages = False;  
		Else	
			PageParameterString = "&from_id=" + Meta["next_id"];
		EndIf;	
		
	EndDo;	
	
	If ArrayOfConsentIds.Count() = 0 Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Dịch vụ: %1 , lỗi, không tìm thấy thống nhất';
			|ru = 'Сервис: %1 , ошибка, не найдено согласие';
			|en = 'Service: %1, error, no consent found'; fa = 'Service: %1, error, no consent found';
			|it = 'Сервис: %1 , ошибка, не найдено согласие';
			|pl = 'Service: %1, error, no consent found';
			|tr = 'Hizmet: %1 , hata, anlaşma bulunamadı'"),
		QueryOptions.Service);
		QueryExecutionResult.ErrorsArray.Add(MessageText);
		
		Return QueryExecutionResult;
		
	EndIf;	
	
	For Each CurStringArrayOfConsentIdentifiers In ArrayOfConsentIds Do
		
		CommandParameters = BankFeedsDictionaryInternal.CommandParameters(CommandsOfServices.RevokeConsent);
		Connection_idParameter = CommandParameters.Connection_id;
		CommandParameter1 = StrReplace(Connection_idParameter, "%CONNECTION_ID%", 
																			QueryOptions.ConnectionID);
		ParametersString1 =  "/" + CurStringArrayOfConsentIdentifiers + "/revoke?" + CommandParameter1;
	
		QueryOptions.HTTPMethod = "PUT";
		ServiceResponse = MakeRequestToService(CommandsOfServices.RevokeConsent, 
																	QueryOptions, ParametersString1);
		Data = ServiceResponse["data"];
		
		If QueryOptions.ConsentID = "" Then 
			QueryOptions.ConsentID = Data["id"];
		EndIf;	
		
	EndDo;
	
	QueryExecutionResult.StatusOfConsent = Data["status"];
	QueryExecutionResult.ResponseStatus = StatusesOfResponse.IsAnswered;
	QueryExecutionResult.FillParameters = QueryOptions;
	
	Return QueryExecutionResult;
EndFunction	

// The function checks the Status of consent
//
// Parameters:
//   QueryOptions - Structure - the data set for the request
// 
// Returns:
//  Structure - The result of the query:
//  	*LinkToConnectionUpdate - String 
//  	*ResponseStatus - String
//  	*FillParameters - Structure:
//  		**Organization - CatalogRef.Companies - Organization
//  		**Bank - CatalogRef.BankClassifier - Bank
//  		**email - String - String
//  	*ErrorsArray - Array of String 
//
Function CheckStatusOfConnectionAndConsent(QueryOptions) Export
	
	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	
	QueryExecutionResult = New Structure();
	QueryExecutionResult.Insert("StatusOfConnection", ""); 
	QueryExecutionResult.Insert("StatusOfConsent", ""); 
	QueryExecutionResult.Insert("ValidityPeriodOfConsent", ""); 
	QueryExecutionResult.Insert("EndDateOfConsent", ""); 
	QueryExecutionResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived); 
	QueryExecutionResult.Insert("FillParameters", QueryOptions);
	QueryExecutionResult.Insert("ErrorsArray", New Array());
	
	CommandsOfServices = BankFeedsDictionaryInternal.CommandsOfServices(QueryOptions.Service);   
	
	//We make a request by consent
	CommandParameters = BankFeedsDictionaryInternal.CommandParameters(CommandsOfServices.GetListOfConsents);
	Connection_idParameter = CommandParameters.Connection_id;
	CommandParameter1 = StrReplace(Connection_idParameter, "%CONNECTION_ID%", QueryOptions.ConnectionID);
	ParametersString1 = "/" +  QueryOptions.ConsentID +"?" + CommandParameter1;
	
	QueryOptions.HTTPMethod = "GET";    
	
	ResponseFromService = MakeRequestToService(CommandsOfServices.GetListOfConsents, 
													QueryOptions, ParametersString1);
	Data = ResponseFromService["data"];
	
	QueryExecutionResult.StatusOfConsent = Data["status"];	
	QueryExecutionResult.ValidityPeriodOfConsent = Data["period_days"];
	QueryExecutionResult.EndDateOfConsent = GetValue(Data, "expires_at", Date("00010101"));
	QueryExecutionResult.ResponseStatus = StatusesOfResponse.IsAnswered;
	QueryExecutionResult.FillParameters = QueryOptions;
	
	If QueryExecutionResult.StatusOfConsent = "active" Then
		//Making a connection request
		QueryOptions.HTTPMethod = "GET"; 
		CommandParameters = BankFeedsDictionaryInternal.CommandParameters(CommandsOfServices.GetListOfConnectionsFromService);
		CommandParameter = "/" + QueryOptions.ConnectionID;
		
		Try
			ResponseListOfProviders = MakeRequestToService(
			CommandsOfServices.GetListOfConnectionsFromService, QueryOptions, CommandParameter);
		
			Data = ResponseListOfProviders["data"];
		
			StatusOfConnection = Data["status"];
			
		Except   

			StatusOfConnection = "unknown";
			
		EndTry;	
	Else
		
		StatusOfConnection = "unknown";
		
	EndIf;
	
	QueryExecutionResult.StatusOfConnection = StatusOfConnection;
	
	Return QueryExecutionResult; 
	
EndFunction	

// The function executes a set of requests for bank account authorization
//
// Parameters:
//   QueryOptions - Structure - the data set for the request
// 
// Returns:
//  Structure - The result of the query:
//  	*LinkToConnectionUpdate - String 
//  	*ResponseStatus - String
//  	*FillParameters - Structure:
//  		**Organization - CatalogRef.Companies - Organization
//  		**Bank - CatalogRef.BankClassifier - Bank
//  		**email - String - String
//  	*ErrorsArray - Array of String 
//
Function RegisterConnection(QueryOptions) Export
	
	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	
	QueryExecutionResult = New Structure();
	QueryExecutionResult.Insert("LinkToAuthorization", ""); 
	QueryExecutionResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived); 
	QueryExecutionResult.Insert("FillParameters", QueryOptions);
	QueryExecutionResult.Insert("ErrorsArray", New Array());
	
	CommandsOfServices = BankFeedsDictionaryInternal.CommandsOfServices(QueryOptions.Service);   
	
	// Looking for the company ID, if the ID is not filled in
	If Not ValueIsFilled(QueryOptions.CompanyID) Then
		
		BodyStructure = RequestBodyForCommand(QueryOptions.Service, CommandsOfServices.CreateUser);
		FillPropertyValues(BodyStructure.Data, QueryOptions);
		BodyStructure.Data.identifier = 
							Common.ObjectAttributeValue(QueryOptions.Organization, "Description");
        FillPropertyValues(BodyStructure.Data.kyc, QueryOptions.RegistrationDetailsForRequest);
		QueryOptions.RequestBody = BodyStructure; 
		QueryOptions.HTTPMethod = "POST";
	
		// Create a user
		ResponseUserHasBeenCreated = MakeRequestToService(CommandsOfServices.CreateUser, QueryOptions);
	
		Data = ResponseUserHasBeenCreated["data"];
		customer_id = Data["customer_id"];
    	QueryOptions.CompanyID = customer_id;

		If customer_id = "" Then
		
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Lỗi khi gán ID của doanh nghiệp %1 vào dịch vụ: %2';
						|ru = 'Ошибка в присвоении идентификатора организации %1 в сервисе: %2';
						|en = 'Error assigning company ID %1 in the service: %2'; fa = 'Error assigning company ID %1 in the service: %2';
						|it = 'Ошибка в присвоении идентификатора организации %1 в сервисе: %2';
						|pl = 'Error assigning company ID %1 in the service: %2';
						|tr = 'Hizmette %1 kuruluş tanımlayıcısı atanırken hata oluştu: %2'"),
					QueryOptions.Organization, QueryOptions.Service);
			QueryExecutionResult.ErrorsArray.Add(MessageText);
		
			Return QueryExecutionResult;
		
		EndIf;	
	EndIf;	
	
	// Making a request to create a lead
	BodyStructure = RequestBodyForCommand(QueryOptions.Service, CommandsOfServices.CreateLeadSession);
	BodyStructure.Data.customer_id = QueryOptions.CompanyID; 	
	BodyStructure.Data.provider_code = QueryOptions.ProviderID; 
	BodyStructure.Data.attempt.custom_fields.numberAccount = QueryOptions.BankAccountNumber;
	BodyStructure.Data.attempt.custom_fields.nameBank = 
							Common.ObjectAttributeValue(QueryOptions.Bank, "Description");

	QueryOptions.RecordID = String(New UUID()); 
	
	BodyStructure.Data.attempt.custom_fields.RecordID = QueryOptions.RecordID;
	QueryOptions.RequestBody = BodyStructure;
	QueryOptions.HTTPMethod = "POST";
	ResponseLinkToAuthorization = MakeRequestToService(CommandsOfServices.CreateLeadSession, QueryOptions);
	Data = ResponseLinkToAuthorization["data"];
	LinkToAuthorization = Data["redirect_url"];
	
	If LinkToAuthorization = "" Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Dịch vụ: %1 gửi liên kết trống để đăng nhập';
					|ru = 'Сервис: %1 отправляет пустюю ссылку на авторизацию';
					|en = 'Service: %1 sends an empty authorization link'; fa = 'Service: %1 sends an empty authorization link';
					|it = 'Сервис: %1 отправляет пустюю ссылку на авторизацию';
					|pl = 'Service: %1 sends an empty authorization link';
					|tr = 'Hizmet: %1 boş bir yetkilendirme bağlantısı gönderiyor'"),
				QueryOptions.Service);
		QueryExecutionResult.ErrorsArray.Add(MessageText);
	
		Return QueryExecutionResult;

	EndIf;	
	
	QueryExecutionResult.LinkToAuthorization = LinkToAuthorization;
	QueryExecutionResult.ResponseStatus = StatusesOfResponse.IsAnswered;
	QueryExecutionResult.FillParameters = QueryOptions;
	
	Return QueryExecutionResult;
EndFunction	

// The function executes a set of requests after authorization from the provider
//
// Parameters:
//   QueryOptions - Structure - the data set for the request
// 
// Returns:
//  Structure - The result of the query:
//  	*LinkToConnectionUpdate - String 
//  	*ResponseStatus - String
//  	*FillParameters - Structure:
//  		**Organization - CatalogRef.Companies - Organization
//  		**Bank - CatalogRef.BankClassifier - Bank
//  		**email - String - String
//  	*ErrorsArray - Array of String 
//
Function GetConnectionDataAfterUserAuthorization(QueryOptions) Export

	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();

	QueryExecutionResult = New Structure();
	QueryExecutionResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived); 
	QueryExecutionResult.Insert("FillParameters", QueryOptions);
	QueryExecutionResult.Insert("ErrorsArray", New Array());
	
	CommandsOfServices = BankFeedsDictionaryInternal.CommandsOfServices(QueryOptions.Service);   

	QueryOptions.HTTPMethod = "GET"; 
	CommandParameters = BankFeedsDictionaryInternal.CommandParameters(CommandsOfServices.GetListOfConnectionsFromService);
	Customer_idParameter = CommandParameters.Customer_id;
	CommandParameter = "?" + StrReplace(Customer_idParameter, "%CUSTOMER_ID%", QueryOptions.CompanyID);
	
	ContinueReadingPages = True;
	PageParameterString = "";
	
	While ContinueReadingPages Do 
		
		ResponseListOfProviders = MakeRequestToService(
		CommandsOfServices.GetListOfConnectionsFromService, QueryOptions, CommandParameter + PageParameterString);
		
		Data = ResponseListOfProviders["data"];
		Meta = ResponseListOfProviders["meta"];
		
		ConnectionIdFound = False;
		// Selecting a connection by record ID 
		For Each CurRow In Data Do
			
				custom_fields = CurRow["last_attempt"]["custom_fields"];
				
				If custom_fields.Count() > 0 Then
					
					IdOfRecordFromAttempt = custom_fields.Get("RecordID"); 
					
					If IdOfRecordFromAttempt <> Undefined                         
						And ValueIsFilled(QueryOptions.RecordID) 
						And QueryOptions.RecordID = IdOfRecordFromAttempt Then  
						
						QueryOptions.ConnectionID = CurRow["id"];  
						QueryOptions.ProviderID = CurRow["provider_code"];
						QueryOptions.NameOfProvider =  CurRow["provider_name"];
						
						ConnectionIdFound = True;
						Break;
						
					EndIf; 
				EndIf;		  
			
		EndDo;	                 
		
		If ConnectionIdFound Then
			Break;
		ElsIf Meta["next_id"] = Undefined Then
			ContinueReadingPages = False;  
		Else	
			PageParameterString = "&from_id=" + Meta["next_id"];
		EndIf;	
		
	EndDo;	
	
	If QueryOptions.ConnectionID = ""
		Or Not ConnectionIdFound Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không tìm thấy ID kết nối theo ngân hàng %1 trong dịch vụ: %2';
					|ru = 'Не найден идентификатор соединения по банку %1 в сервисе: %2';
					|en = 'No connection ID is found for the %1 bank in the service: %2'; fa = 'No connection ID is found for the %1 bank in the service: %2';
					|it = 'Не найден идентификатор соединения по банку %1 в сервисе: %2';
					|pl = 'No connection ID is found for the %1 bank in the service: %2';
					|tr = 'Hizmetteki %1 bankası için bağlantı kimliği bulunamadı: %2'"),
				QueryOptions.Bank, QueryOptions.Service);
		QueryExecutionResult.ErrorsArray.Add(MessageText);
		
		Return QueryExecutionResult;
		
	EndIf;	

	//We make a request to search for consents
	CommandParameters = BankFeedsDictionaryInternal.CommandParameters(CommandsOfServices.GetListOfConsents);
	Connection_idParameter = CommandParameters.Connection_id;
	CommandParameter1 = StrReplace(Connection_idParameter, "%CONNECTION_ID%", QueryOptions.ConnectionID);
	ParametersString1 = "?" + CommandParameter1;
	
	QueryOptions.HTTPMethod = "GET";    
	
	ContinueReadingPages = True;
	PageParameterString = "";
	
	While ContinueReadingPages Do 
		
		ResponseFromService = MakeRequestToService(CommandsOfServices.GetListOfConsents, 
										QueryOptions, ParametersString1 + PageParameterString);
		Data = ResponseFromService["data"];
		Meta = ResponseFromService["meta"];
		
		For Each CurRow In Data Do
			
			If CurRow["status"] = "active" Then
				QueryOptions.ConsentID = CurRow["id"];
				Break;
			EndIf;	
			
		EndDo;	
		
		If Meta["next_id"] = Undefined Then
			ContinueReadingPages = False;  
		Else	
			PageParameterString = "&from_id=" + Meta["next_id"];
		EndIf;	
		
	EndDo;	
	
	If QueryOptions.ConsentID = "" Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không tìm thấy thống nhất theo ngân hàng %1 trong dịch vụ: %2';
					|ru = 'Не найдено согласие по банку %1 в сервисе: %2';
					|en = 'No consent is found for the %1 bank in the service: %2'; fa = 'No consent is found for the %1 bank in the service: %2';
					|it = 'Не найдено согласие по банку %1 в сервисе: %2';
					|pl = 'No consent is found for the %1 bank in the service: %2';
					|tr = 'Hizmette %1 bankası için onay bulunamadı: %2'"),
				QueryOptions.Bank, QueryOptions.Service);
		QueryExecutionResult.ErrorsArray.Add(MessageText);
		
		Return QueryExecutionResult;
		
	EndIf;	

	MainFormat = BankFeedsDictionaryInternal.MainTemplateForPaymentOrderFormat();
	
	// Request to receive bank formats
	If ValueIsFilled(QueryOptions.ProviderID) Then
		// Find a bank
		QueryOptions.RequestBody.Clear();
		QueryOptions.HTTPMethod = "GET"; 
		
		ResponseListOfProviders = MakeRequestToService(
		CommandsOfServices.GetListOfProvidersFromService + "/" + QueryOptions.ProviderID, 
		QueryOptions, PageParameterString);
		
		Data = ResponseListOfProviders["data"];
		
		For Each CurRow In Data Do
			
			If CurRow.Key = "payment_templates" Then
				
				SupportedFormats = CurRow.Value;
				
				For Each CurRow In SupportedFormats Do
					
					If CurRow = String(MainFormat) Then
						
						QueryOptions.PaymentMethodByIBAN = MainFormat; 
						QueryOptions.PaymentMethodByBBAN = Enums.BankFeedsPaymentMethods.EmptyRef();
						
					EndIf;	 
				EndDo;		 
				
			EndIf;	
			
		EndDo;	
		
	EndIf;	
		
	If ValueIsFilled(QueryOptions.BankAccountNumber) Then
		
		QueryOptions.HTTPMethod = "GET"; 
		CommandParameters = BankFeedsDictionaryInternal.CommandParameters(CommandsOfServices.GetListOfAccountsFromService);
		Connection_idParameter = CommandParameters.Connection_id;
		CommandParameter = "?" + StrReplace(Connection_idParameter, "%CONNECTION_ID%", 
		QueryOptions.ConnectionID);       
		
		ContinueReadingPages = True;
		PageParameterString = "";
		AccountFound = False;
		CurrencyName  = Common.ObjectAttributeValue(QueryOptions.AccountCurrency, "Description");
		
		While ContinueReadingPages Do 
			
			ResponseIsListOfAccounts = MakeRequestToService(
			CommandsOfServices.GetListOfAccountsFromService, QueryOptions, CommandParameter + PageParameterString);
			
			Data = ResponseIsListOfAccounts["data"];
			Meta = ResponseIsListOfAccounts["meta"];
			
			For Each CurRow In Data Do
				extra = CurRow["extra"];
				
				If StrFind(extra["iban"], QueryOptions.BankAccountNumber) > 0
					And CurRow["currency_code"] = CurrencyName Then
					QueryOptions.InvoiceId = CurRow["id"]; 
					AccountFound = True;
					Break;
				EndIf;	
				
			EndDo;	
			
			If AccountFound Then
				Break;	
			ElsIf Meta["next_id"] = Undefined Then
				ContinueReadingPages = False;  
			Else	
				PageParameterString = "&from_id=" + Meta["next_id"];
			EndIf;	
			
		EndDo;	
		
		If QueryOptions.InvoiceId = "" Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kết nối tài khoản ngân hàng. Không tìm thấy tài khoản ngân hàng số %1 tại ngân hàng %2 thông qua nhà cung cấp dịch vụ: %3';
				|ru = 'Невозможно подключить банковский счет. Банковский счет с номером счета %1 не найден в банке %2 с помощью поставщика услуг: %3';
				|en = 'Unable to connect bank account. Bank account with account number %1 is not found in bank %2 using service provider %3'; fa = 'Unable to connect bank account. Bank account with account number %1 is not found in bank %2 using service provider %3';
				|it = 'Невозможно подключить банковский счет. Банковский счет с номером счета %1 не найден в банке %2 с помощью поставщика услуг: %3';
				|pl = 'Unable to connect bank account. Bank account with account number %1 is not found in bank %2 using service provider %3';
				|tr = 'Bir banka hesabına bağlanılamıyor. Hesap numarası %1 olan banka hesabı, servis sağlayıcı: %3 kullanılarak %2 bankasında bulunamadı'"),
			QueryOptions.BankAccountNumber, QueryOptions.Bank, QueryOptions.Service);
			QueryExecutionResult.ErrorsArray.Add(MessageText);
			
			Return QueryExecutionResult;
			
		EndIf;	
	
	EndIf;

	QueryExecutionResult.ResponseStatus = StatusesOfResponse.IsAnswered;
	QueryExecutionResult.FillParameters = QueryOptions;
	
	Return QueryExecutionResult;
	
EndFunction	

// The function loads transactions from the service
//
// Parameters:
//   QueryOptions - Structure - the data set for the request
//   StartDate - Date - start date of the transaction upload
//   EndDate - Date - the end date of the transaction upload
// 
// Returns:
//  Structure - The result of the query:
//  	*LinkToConnectionUpdate - String 
//  	*ResponseStatus - String
//  	*FillParameters - Structure:
//  		**Organization - CatalogRef.Companies - Organization
//  		**Bank - CatalogRef.BankClassifier - Bank
//  		**email - String - String
//  	*ErrorsArray - Array of String 
//
Function GetTransactions(QueryOptions, StartDate, EndDate) Export

	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();

	QueryExecutionResult = New Structure();
	QueryExecutionResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived); 
	QueryExecutionResult.Insert("FillParameters", QueryOptions);
	QueryExecutionResult.Insert("TransactionsTable", New ValueTable());
	QueryExecutionResult.Insert("ErrorsArray", New Array());

	CommandsOfServices = BankFeedsDictionaryInternal.CommandsOfServices(QueryOptions.Service);   

	QueryOptions.HTTPMethod = "GET"; 
	CommandParameters = BankFeedsDictionaryInternal.CommandParameters(CommandsOfServices.GetListOfTransactionsFromService);
	Connection_idParameter = CommandParameters.Connection_id;
	Account_idParameter = CommandParameters.Account_id;
	CommandParameter1 = StrReplace(Connection_idParameter, "%CONNECTION_ID%", QueryOptions.ConnectionID);
	CommandParameter2 = StrReplace(Account_idParameter, "%ACCOUNT_ID%", QueryOptions.InvoiceId);         
	ParametersString1 = "?" + CommandParameter1 + "&" + CommandParameter2;
	
	ContinueReadingPages = True;
	PageParameterString = "";

	TransactionsTable = CreateTransactionTable();
	
	While ContinueReadingPages Do 
		
		ResponseIsListOfTransactions = MakeRequestToService(
			CommandsOfServices.GetListOfTransactionsFromService, QueryOptions, 
																ParametersString1 + PageParameterString);

		Data = ResponseIsListOfTransactions["data"];
		Meta = ResponseIsListOfTransactions["meta"];
		
		// Think about how to make the search faster
		For Each CurRow In Data Do
		
			CreationDate = GetValue(CurRow, "made_on", "JSONDate", Date("00010101"));
		
			If StartDate <= CreationDate 
				And CreationDate <= EndDate Then
					Add_Transaction(TransactionsTable, CurRow);
			EndIf;	
		
		EndDo;	
		
		If Meta["next_id"] = Undefined Then
			ContinueReadingPages = False;  
		Else	
			PageParameterString = "&from_id=" + Meta["next_id"];
		EndIf;	
		
	EndDo;	
		
	// Forming a request for merchants
	If TransactionsTable.Count() > 0 Then
		Filter = New Structure("ThereIsMerchant", True);
		ArrayOfMerchantIds = New Array();
		
		FoundRows = TransactionsTable.FindRows(Filter);
		
		For Each CurCurrentRowFoundRows In FoundRows Do
			ArrayOfMerchantIds.Add(CurCurrentRowFoundRows.IDMerchant);
		EndDo;
		
		ArrayOfMerchantIds = TMCommonUse.DeleteDuplicateElementsFromArray(ArrayOfMerchantIds);
		
		ResponseToListOfMerchants = ExecuteRequestForListOfMerchants(ArrayOfMerchantIds, QueryOptions);
		
		Data = ResponseToListOfMerchants["data"];
		Filter = New Structure("IDMerchant", "");

	//*********************
		For Each CurRow In Data Do
			
			CurIDOfMerchant = CurRow["id"];
			AttributesList = CurRow["names"];
			MerchantSName = "";
			
			For Each CurLineIsListOfAttributes In AttributesList Do
				
				If CurLineIsListOfAttributes["mode"] = "name" Then
					
					MerchantSName = CurLineIsListOfAttributes["value"];		
					Break;
				EndIf;	
			
			EndDo;
			
			Filter.IDMerchant = CurIDOfMerchant;
			FoundRows = TransactionsTable.FindRows(Filter);
			
			For Each CurCurrentRowFoundRows In FoundRows Do

				CurCurrentRowFoundRows.NameMerchant = MerchantSName;	
				
			EndDo;	
			
		EndDo;	
		
	EndIf;
	//*********************
	
	QueryExecutionResult.TransactionsTable = TransactionsTable;	
	QueryExecutionResult.ResponseStatus = StatusesOfResponse.IsAnswered;
	
	If TransactionsTable.Count() = 0 Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa kết nhập giao dịch theo ngân hàng %1 vào dịch vụ: %2';
					|ru = 'Транзакции не загружены по банку %1 в сервисе: %2';
					|en = 'Transactions of the %1 bank are not imported in the service: %2'; fa = 'Transactions of the %1 bank are not imported in the service: %2';
					|it = 'Транзакции не загружены по банку %1 в сервисе: %2';
					|pl = 'Transactions of the %1 bank are not imported in the service: %2';
					|tr = 'Hizmetteki %1 bankası için işlemler yüklenmedi: %2'"),
				QueryOptions.Bank, QueryOptions.Service);
		QueryExecutionResult.ErrorsArray.Add(MessageText);
		
	EndIf;	
	
	Return QueryExecutionResult;
	
EndFunction	

// The function executes a set of requests to check the Status of payment documents
//
// Parameters:
//   QueryOptions - Structure - the data set for the request
// 
// Returns:
//  Structure - The result of the query:
//  	*LinkToConnectionUpdate - String 
//  	*ResponseStatus - String
//  	*FillParameters - Structure:
//  		**Organization - CatalogRef.Companies - Organization
//  		**Bank - CatalogRef.BankClassifier - Bank
//  		**email - String - String
//  	*ErrorsArray - Array of String 
//
Function GetStatusesOfPaymentDocuments(QueryOptions) Export
	
	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	
	QueryExecutionResult = New Structure();
	QueryExecutionResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived); 
	QueryExecutionResult.Insert("FillParameters", QueryOptions);
	QueryExecutionResult.Insert("PaymentTableInService", "");
	QueryExecutionResult.Insert("ErrorsArray", New Array());
	
	CommandsOfServices = BankFeedsDictionaryInternal.CommandsOfServices(QueryOptions.Service);   
	
	QueryOptions.HTTPMethod = "GET"; 
	CommandParameters = BankFeedsDictionaryInternal.CommandParameters(
													CommandsOfServices.GetListOfPaymentDocumentsFromService);
	Customer_idParameter = CommandParameters.Customer_id;
	CommandParameter = "?" + StrReplace(Customer_idParameter, "%CUSTOMER_ID%", QueryOptions.CompanyID);
	
	PaymentTableInService = New ValueTable();
	PaymentTableInService.Columns.Add("id", Common.StringTypeDetails(100));
	PaymentTableInService.Columns.Add("UIDDOcument", Common.StringTypeDetails(100));
	PaymentTableInService.Columns.Add("Ref", Documents.AllRefsType());
	PaymentTableInService.Columns.Add("provider_code", Common.StringTypeDetails(30));
	PaymentTableInService.Columns.Add("provider_name", Common.StringTypeDetails(100));
	PaymentTableInService.Columns.Add("customer_id", Common.StringTypeDetails(30));
	PaymentTableInService.Columns.Add("created_at", Common.StringTypeDetails(100));
	PaymentTableInService.Columns.Add("updated_at", Common.StringTypeDetails(100));
	PaymentTableInService.Columns.Add("status", Common.StringTypeDetails(19));
	PaymentTableInService.Columns.Add("template_identifier", Common.StringTypeDetails(50));
	PaymentTableInService.Columns.Add("end_to_end_id", Common.StringTypeDetails(30));
	PaymentTableInService.Columns.Add("reference", Common.StringTypeDetails(100));
	PaymentTableInService.Columns.Add("customer_last_logged_at", Common.StringTypeDetails(100));
	PaymentTableInService.Columns.Add("customer_ip_address", Common.StringTypeDetails(100));
	PaymentTableInService.Columns.Add("customer_device_os", Common.StringTypeDetails(100));
	PaymentTableInService.Columns.Add("creditor_name", Common.StringTypeDetails(100));
	PaymentTableInService.Columns.Add("creditor_street_name", Common.StringTypeDetails(50));
	PaymentTableInService.Columns.Add("creditor_building_number", Common.StringTypeDetails(5));
	PaymentTableInService.Columns.Add("creditor_country_code", Common.StringTypeDetails(5));
	PaymentTableInService.Columns.Add("currency_code", Common.StringTypeDetails(100));
	PaymentTableInService.Columns.Add("amount", 			New TypeDescription("Number"));
	PaymentTableInService.Columns.Add("description", Common.StringTypeDetails(700));
	PaymentTableInService.Columns.Add("creditor_iban", Common.StringTypeDetails(30));
	
	ContinueReadingPages = True;
	PageParameterString = "";
	
	While ContinueReadingPages Do 
		
		ResponseListOfPaymentDocuments = MakeRequestToService(
		CommandsOfServices.GetListOfPaymentDocumentsFromService, 
												QueryOptions, CommandParameter + PageParameterString);
		
		Data = ResponseListOfPaymentDocuments["data"];
		Meta = ResponseListOfPaymentDocuments["meta"];
		
		// 
		For Each CurStringIsData In Data Do
			
			NewRow = PaymentTableInService.Add();	
			
			For Each CurDataStringPaymentString In CurStringIsData Do
				
				If CurDataStringPaymentString.Key = "payment_attributes" Then
					
					For Each CurDataStringPaymentStringPaymentFields In CurDataStringPaymentString.Value Do
						
						If PaymentTableInService.Columns.Find(CurDataStringPaymentStringPaymentFields.Key) <> Undefined Then  
							If TypeOf(NewRow[CurDataStringPaymentStringPaymentFields.Key]) = Type("Number") Then
								NewRow[CurDataStringPaymentStringPaymentFields.Key] = 
																Number(CurDataStringPaymentStringPaymentFields.Value);
							Else	
								NewRow[CurDataStringPaymentStringPaymentFields.Key] = 
																	CurDataStringPaymentStringPaymentFields.Value;
								
							EndIf;	
						ElsIf CurDataStringPaymentStringPaymentFields.Key = "end_to_end_id"
							And ValueIsFilled(CurDataStringPaymentStringPaymentFields.Value)
							And StrLen(CurDataStringPaymentStringPaymentFields.Value) = 32 Then
							
							UIDIsAbbreviated = CurDataStringPaymentStringPaymentFields.Value;
							
							If ValueIsFilled(UIDIsAbbreviated) Then 
								Id = AssembleUIDFor1C(UIDIsAbbreviated); 
								NewRow.Ref = 
									Documents.BankAccountIssue.GetRef(Id);
								
							EndIf;	
							
						ElsIf CurDataStringPaymentStringPaymentFields.Key = "custom_fields" Then
							
							NewRow.UIDDOcument = CurDataStringPaymentStringPaymentFields.Value["uid_document"];
							
							If ValueIsFilled(NewRow.UIDDOcument) Then
								Id = New UUID(NewRow.UIDDOcument); 
								NewRow.Ref = 
									Documents.BankAccountIssue.GetRef(Id);
								
							EndIf;	
							
						EndIf;	
						
					EndDo;	
					
				Else
					
					If PaymentTableInService.Columns.Find(CurDataStringPaymentString.Key) <> Undefined Then 
						NewRow[CurDataStringPaymentString.Key] = CurDataStringPaymentString.Value;
					EndIf;	
				EndIf;	
				
			EndDo	
			
		EndDo;	
		
		If Meta["next_id"] = Undefined Then
			ContinueReadingPages = False;  
		Else	
			PageParameterString = "&from_id=" + Meta["next_id"];
		EndIf;	
		
	EndDo;	
	

	QueryExecutionResult.PaymentTableInService = PaymentTableInService;

	Return QueryExecutionResult;
	
EndFunction	

// The function executes a set of requests for sending a payment order to the service
//
// Parameters:
//   PaymentDocumentData - Structure - payment document data to be sent to the service
//   QueryOptions - Structure - the data set for the request
// 
// Returns:
//  Structure - The result of the query:
//  	*LinkToConnectionUpdate - String 
//  	*ResponseStatus - String
//  	*FillParameters - Structure:
//  		**Organization - CatalogRef.Companies - Organization
//  		**Bank - CatalogRef.BankClassifier - Bank
//  		**email - String - String
//  	*ErrorsArray - Array of String 
//
Function SendPaymentDocument(PaymentDocumentData, QueryOptions) Export 
	
	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();

	QueryExecutionResult = New Structure();
	QueryExecutionResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived); 
	QueryExecutionResult.Insert("FillParameters", QueryOptions);
	QueryExecutionResult.Insert("LinkToPaymentConfirmation", "");
	QueryExecutionResult.Insert("PaymentDocumentData", PaymentDocumentData);
	QueryExecutionResult.Insert("ErrorsArray", New Array());

	CommandsOfServices = BankFeedsDictionaryInternal.CommandsOfServices(QueryOptions.Service);   

	BodyStructure = RequestBodyForCommand(QueryOptions.Service, CommandsOfServices.OpenPaymentSessionInService);  
	FillPropertyValues(BodyStructure.Data, QueryOptions); 
	BodyStructure.data.customer_id = QueryOptions.CompanyID;
	BodyStructure.data.payee_description = PaymentDocumentData.CounterpartyName; // who are we paying
	BodyStructure.data.provider_code = QueryOptions.ProviderID;

	// The template is being filled in   
	If PaymentDocumentData.DocumentKind = Enums.TypesOfPaymentDocuments.PaymentDemand Then
		PaymentDocumentTemplate = BankFeedsDictionaryInternal.PaymentRequestTemplates();
	Else	
		PaymentDocumentTemplate = BankFeedsDictionaryInternal.PaymentOrderTemplates();
	EndIf;

	TemplateOfSpecifiedFormat = PaymentDocumentTemplate[Enums.BankFeedsPaymentMethods.SEPA];
	
	PaymentOrderFields = BodyStructure.Data.payment_attributes;
	For Each CurCurrentRowTemplates In TemplateOfSpecifiedFormat Do
		
		If PaymentDocumentData.Property(CurCurrentRowTemplates.Key)
			And PaymentOrderFields.Property(CurCurrentRowTemplates.Value) Then 
			
		 	PaymentOrderFields[CurCurrentRowTemplates.Value] = 
				String(PaymentDocumentData[CurCurrentRowTemplates.Key]);
			
		EndIf;	
		
	EndDo;
	
	SystemInfo = New SystemInfo;
	StringIsUniqueIdentifierOfDocument = String(PaymentDocumentData.Ref.UUID());

	PaymentOrderFields.end_to_end_id = StrReplace(StringIsUniqueIdentifierOfDocument, "-", "");
	 
	PaymentOrderFields.customer_ip_address = QueryOptions.IPAddress;
	PaymentOrderFields.customer_device_os = SystemInfo.OSVersion + "UIDDOCUMENT:" 
		+ StringIsUniqueIdentifierOfDocument;    
	
	PaymentOrderFields.currency_code = Common.ObjectAttributeValue(
		PaymentDocumentData.Currency, "Description");
	PaymentOrderFields.mode = "normal";

	PaymentOrderFields.creditor_country_code = QueryOptions.CompanyRegistrationCountryCode;
	
	PaymentOrderFields.debtor_country_code = Left(PaymentOrderFields.debtor_iban, 2);
	PaymentOrderFields.amount = Format(PaymentDocumentData.Sum, "NFD=2; NDS=.");
	
	PaymentOrderFields.custom_fields.uid_document = StringIsUniqueIdentifierOfDocument;
	
	QueryOptions.RequestBody = BodyStructure;
	QueryOptions.HTTPMethod = "POST";
	
	//CreateBillingSession
	ResponseCreateBillingSession = MakeRequestToService(CommandsOfServices.OpenPaymentSessionInService, 
													QueryOptions);
	
	Data = ResponseCreateBillingSession["data"];

	For Each CurRow In Data Do
		
		If CurRow.Key = "connect_url" Then
			LinkToConfirmation = CurRow.Value;
			Break;                                         
		EndIf;
		
	EndDo;	  
	
	QueryExecutionResult.LinkToPaymentConfirmation = LinkToConfirmation;
	
	If LinkToConfirmation = "" Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xảy ra lỗi %1 trong dịch vụ: %2';
					|ru = 'Что то пошло не так %1 в сервисе: %2';
					|en = 'Something went wrong %1 in the service: %2'; fa = 'Something went wrong %1 in the service: %2';
					|it = 'Что то пошло не так %1 в сервисе: %2';
					|pl = 'Something went wrong %1 in the service: %2';
					|tr = 'Hizmette bir şeyler ters gitti'"),
				QueryOptions.Organization, QueryOptions.Service);
		QueryExecutionResult.ErrorsArray.Add(MessageText);
		
	EndIf;	

	Return QueryExecutionResult;

EndFunction	

// The function executes a request to read bank accounts in the service for a specific bank
//
// Parameters:
//   QueryOptions - Structure - the data set for the request
// 
// Returns:
//  Structure - The result of the query:
//  	*LinkToConnectionUpdate - String 
//  	*ResponseStatus - String
//  	*FillParameters - Structure:
//  		**Organization - CatalogRef.Companies - Organization
//  		**Bank - CatalogRef.BankClassifier - Bank
//  		**email - String - String
//  	*ErrorsArray - Array of String 
//
Function ReadingCompanySBankAccounts(QueryOptions) Export
	
	StatusesOfResponse = BankFeedsDictionaryInternal.StatusesOfResponse();
	
	QueryExecutionResult = New Structure();
	QueryExecutionResult.Insert("TableOfAccounts", ""); 
	QueryExecutionResult.Insert("ResponseStatus", StatusesOfResponse.NoResponseReceived); 
	QueryExecutionResult.Insert("FillParameters", QueryOptions);
	QueryExecutionResult.Insert("ErrorsArray", New Array());
	
	CommandsOfServices = BankFeedsDictionaryInternal.CommandsOfServices(QueryOptions.Service);   
	
	QueryOptions.HTTPMethod = "GET"; 
	CommandParameters = BankFeedsDictionaryInternal.CommandParameters(CommandsOfServices.GetListOfAccountsFromService);
	Connection_idParameter = CommandParameters.Connection_id;
	CommandParameter1 = StrReplace(Connection_idParameter, "%CONNECTION_ID%", QueryOptions.ConnectionID);
	ParametersString1 = "?" + CommandParameter1;
	
	ContinueReadingPages = True;
	PageParameterString = "";
	
	While ContinueReadingPages Do 
	
	ResponseIsListOfTransactions = MakeRequestToService(
		CommandsOfServices.GetListOfAccountsFromService, QueryOptions, ParametersString1 + PageParameterString);

	Data = ResponseIsListOfTransactions["data"];
	Meta = ResponseIsListOfTransactions["meta"];
	
	TableOfAccounts = CreateInvoiceTable();
	
	// Think about how to make the search faster
	For Each CurRow In Data Do
		
		AddBankAccountFromService(TableOfAccounts, CurRow);
		
	EndDo;	
	
		If Meta["next_id"] = Undefined Then
			ContinueReadingPages = False;  
		Else	
			PageParameterString = "&from_id=" + Meta["next_id"];
		EndIf;	
		
	EndDo;	
	
	QueryExecutionResult.TableOfAccounts = TableOfAccounts;	
	QueryExecutionResult.ResponseStatus = StatusesOfResponse.IsAnswered;
	
	If TableOfAccounts.Count() = 0 Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa kết nhập giao dịch theo ngân hàng %1 vào dịch vụ: %2';
					|ru = 'Транзакции не загружены по банку %1 в сервисе: %2';
					|en = 'Transactions of the %1 bank are not imported in the service: %2'; fa = 'Transactions of the %1 bank are not imported in the service: %2';
					|it = 'Транзакции не загружены по банку %1 в сервисе: %2';
					|pl = 'Transactions of the %1 bank are not imported in the service: %2';
					|tr = '%2Hizmetteki bankası için işlemler yüklenmedi %1'"),
				QueryOptions.Bank, QueryOptions.Service);
		QueryExecutionResult.ErrorsArray.Add(MessageText);
		
	EndIf;	
	
	Return QueryExecutionResult;
	
EndFunction	

#EndRegion

#Region RunningBackgroundJobs   

// Runs a background task for reading bank accounts in the service 
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	FillParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskReadInvoicesForOrganization(UUID, FillParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Đọc tài khoản ngân hàng theo doanh nghiệp';
														|ru = 'Чтение банковских счетов по организации';
														|en = 'Read bank accounts by company'; fa = 'Read bank accounts by company';
														|it = 'Чтение банковских счетов по организации';
														|pl = 'Read bank accounts by company';
														|tr = 'Banka hesaplarını kuruluşa göre okuma'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"InformationRegisters.ConnectionsToBankFeedsBanks.ReadingBankAccountsByCompany",
							FillParameters);
	
	Return ExecutionResult;
	
EndFunction

// Runs a background task to check the connection to the service 
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	FillParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForCheckingConnection(UUID, FillParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Kiểm tra kết nối đến';
														|ru = 'Проверка подключения к';
														|en = 'Check connection to'; fa = 'Check connection to';
														|it = 'Проверка подключения к';
														|pl = 'Check connection to';
														|tr = 'Bağlantı kontrol ediliyor'") + " BankFeeds";
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"Catalogs.IntegrateWithBankFeeds.ConnectionCheckUp",
							FillParameters);
	
	Return ExecutionResult;
	
EndFunction

// Runs a background task for user authorization on the service 
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	FillParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForUserAuthorization(UUID, FillParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Kết nối dịch vụ';
														|ru = 'Подключение сервиса';
														|en = 'Connecting the service'; fa = 'Connecting the service';
														|it = 'Подключение сервиса';
														|pl = 'Connecting the service';
														|tr = 'Servis bağlantısı'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"InformationRegisters.ConnectionsToBankFeedsBanks.GettingAuthorizationData",
							FillParameters);
	
	Return ExecutionResult;
	
EndFunction 

// Runs a background job to update the connection on the service 
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	FillParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundConnectionUpdateTask(UUID, FillParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Cập nhật kết nối dịch vụ';
														|ru = 'Обновление соединения сервиса';
														|en = 'Service connection update'; fa = 'Service connection update';
														|it = 'Обновление соединения сервиса';
														|pl = 'Service connection update';
														|tr = 'Servis bağlantısının güncellenmesi'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"InformationRegisters.ConnectionsToBankFeedsBanks.ConnectionUpdate",
							FillParameters);
	
	Return ExecutionResult;
	
EndFunction 

// Runs a background task to check the Status of connection and consent on the service 
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	FillParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskToCheckStatusOfConnectionAndConsent(UUID, FillParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Cập nhật kết nối dịch vụ';
														|ru = 'Обновление соединения сервиса';
														|en = 'Service connection update'; fa = 'Service connection update';
														|it = 'Обновление соединения сервиса';
														|pl = 'Service connection update';
														|tr = 'Servis bağlantısının güncellenmesi'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"InformationRegisters.ConnectionsToBankFeedsBanks.CheckConnectionAndConsentStatus",
							FillParameters);
	
	Return ExecutionResult;
	
EndFunction  

// Runs a background task to revoke consent on the service 
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	FillParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForRevocationOfConsent(UUID, FillParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Thu hồi thống nhất dịch vụ';
														|ru = 'Отзыв согласия сервиса';
														|en = 'Service consent revocation'; fa = 'Service consent revocation';
														|it = 'Отзыв согласия сервиса';
														|pl = 'Service consent revocation';
														|tr = 'Servis onayının geri çekilmesi'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"InformationRegisters.ConnectionsToBankFeedsBanks.RevocationOfConsent",
							FillParameters);
	
	Return ExecutionResult;
	
EndFunction 

// Runs a background job to load transactions from the service 
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	ImportParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForDownloadingTransactions(UUID, ImportParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Kết nhập giao dịch';
														|ru = 'Загрузка транзакций';
														|en = 'Import transactions'; fa = 'ورود تراکنش‌ها';
														|it = 'Загрузка транзакций';
														|pl = 'Import transactions';
														|tr = 'İşlemlerin yüklenmesi'");
	
	If ImportParameters.DownloadIsPerformedWhenSyncing Then
		BankAccounts = ListOfBankAccountsAndDownloadPeriodsWhenSyncing(ImportParameters.BankAccount);
	Else	
		BankAccounts = GetFromTempStorage(ImportParameters.BankAccountAddress);	
	EndIf;	
		
	TransactionLoadingParameters = Common.CopyRecursive(ImportParameters);
	TransactionLoadingParameters.Insert("BankAccounts", BankAccounts);
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"DataProcessors.EDIWithBanksBankFeeds.ImportTransactions",
							TransactionLoadingParameters);
	
	Return ExecutionResult;
	
EndFunction  

// Runs a background task for uploading payment orders to the service 
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	ExportingParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForUploadingPaymentDocuments(UUID, ExportingParameters) Export
	
	If ExportingParameters.UploadIsPerformedWhenSyncing Then
		BankAccounts = FillInBankAccountsWhenUploading(ExportingParameters.BankAccount);   
		DocumentsToExport = FillOutDocumentsForUploadingWhenSyncing(BankAccounts);
	Else	
		BankAccounts = GetFromTempStorage(ExportingParameters.AddressBankAccounts);
		DocumentsToExport = GetFromTempStorage(ExportingParameters.AddressDocumentsToBeUploaded);
	EndIf;	
	
	UploadParametersForTask = New Structure();
	
	UploadParametersForTask.Insert("BankAccounts", BankAccounts);
	UploadParametersForTask.Insert("DocumentsToExport", DocumentsToExport);
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Kết xuất chứng từ thanh toán';
														|ru = 'Выгрузка платежных документов';
														|en = 'Export payment documents'; fa = 'خروج اطلاعات اسناد پرداخت';
														|it = 'Выгрузка платежных документов';
														|pl = 'Export payment documents';
														|tr = 'Ödeme belgelerinin dışa aktarılması'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"DataProcessors.EDIWithBanksBankFeeds.ExportPaymentDocuments",
							UploadParametersForTask);
	
	Return ExecutionResult;
	
EndFunction  

// Runs a background task to check the Status of the payment document in the service 
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForCheckingStatusOfPaymentDocuments(UUID) Export
	
	BankAccounts = FillInBankAccountsWhenCheckingStatus();
	DocumentsToExport = FillInDocumentsForUploadingWhenCheckingStatus(BankAccounts);	
	
	UploadParametersForTask = New Structure();
	
	UploadParametersForTask.Insert("BankAccounts", BankAccounts);
	UploadParametersForTask.Insert("DocumentsToExport", DocumentsToExport);
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Kiểm tra trạng thái chứng từ thanh toán';
														|ru = 'Проверка статусов платежных документов';
														|en = 'Check payment document statuses'; fa = 'Check payment document statuses';
														|it = 'Проверка статусов платежных документов';
														|pl = 'Check payment document statuses';
														|tr = 'Ödeme belgelerinin durumunun kontrol edilmesi'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"DataProcessors.EDIWithBanksBankFeeds.CheckingStatusOfPaymentDocuments",
							UploadParametersForTask);
	
	Return ExecutionResult;
	
EndFunction	

// Runs a background task to connect a bank account to the service
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	FillParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForConnectingToService(UUID, FillParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Kết nối dịch vụ';
														|ru = 'Подключение сервиса';
														|en = 'Connecting the service'; fa = 'Connecting the service';
														|it = 'Подключение сервиса';
														|pl = 'Connecting the service';
														|tr = 'Servis bağlantısı'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"InformationRegisters.ConnectionsToBankFeedsBanks.ConnectingToService",
							FillParameters);
	
	Return ExecutionResult;
	
EndFunction

// Runs a background job to check for updates to a connection in the service
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	FillParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForCheckingConnectionUpdateToService(UUID, FillParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Kết nối dịch vụ';
														|ru = 'Подключение сервиса';
														|en = 'Connecting the service'; fa = 'Connecting the service';
														|it = 'Подключение сервиса';
														|pl = 'Connecting the service';
														|tr = 'Servis bağlantısı'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"InformationRegisters.ConnectionsToBankFeedsBanks.CheckingServiceConnectionUpdate",
							FillParameters);
	
	Return ExecutionResult;
	
EndFunction

#EndRegion

#Region MethodsForWorkingWithDataConnectionAndProcessing

// The function from the string makes a uid 
//
// Parameters:
//   UIDIsAbbreviated - String - uid in the form of a string without a dash
// 
// Returns:
//  UUID - collected uid
//
Function AssembleUIDFor1C(UIDIsAbbreviated) Export 
	
	//XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
	
	FirstBlock = Left(UIDIsAbbreviated, 8);
	SecondBlock = Mid(UIDIsAbbreviated, 9,4);
	ThirdBlock = Mid(UIDIsAbbreviated, 13,4);
	FourthBlock = Mid(UIDIsAbbreviated, 17,4);
	FifthBlock = Right(UIDIsAbbreviated, 12);
	
	FullUID = "" + FirstBlock + "-" + SecondBlock + "-" + ThirdBlock + "-" + FourthBlock + "-" + FifthBlock; 
	
	Return New UUID(FullUID); 
	
EndFunction	

#EndRegion  

#Region DetailsOfRegistrar

// The function reads the registration Attributes 
//
// Parameters:
//   FillParameters - Structure - set of Attributes 
// 
// Returns:
//  Structure - The result of the query:
//  	*LinkToConnectionUpdate - String 
//  	*ResponseStatus - String
//  	*FillParameters - Structure:
//  		**Organization - CatalogRef.Companies - Organization
//  		**Bank - CatalogRef.BankClassifier - Bank
//  		**email - String - String
//  	*ErrorsArray - Array of String 
//
Function ReadRegistrationDetailsOnServer(FillParameters) Export
	
	Query = New Query;
	Query.SetParameter("Organization", FillParameters.Organization);
	Query.Text = 
	"SELECT
	|	ConnectionsToBankFeedsBanks.RegistrationAttributes AS RegistrationAttributes
	|FROM
	|	InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	|WHERE
	|	ConnectionsToBankFeedsBanks.Organization = &Organization";
	

	Result = Query.Execute().Select();
	RegistrationAttributes = Undefined;
	
	If Result.Next() Then
		
		StorageOfValuesDetailsDuringRegistration = Result.RegistrationAttributes;	
		
		RegistrationAttributes =  StorageOfValuesDetailsDuringRegistration.Get();
		
	EndIf;	
	
	If ValueIsFilled(RegistrationAttributes) Then
		Return RegistrationAttributes;
	EndIf;	
	
	RegistrationAttributes = BankFeedsDictionaryInternal.RegistrationDetailsOnForm();

	FillInRegistrationDetailsByDefault(RegistrationAttributes, FillParameters);	
	
	Return RegistrationAttributes;
	
EndFunction	

#EndRegion  

#EndRegion  

#Region Private

// Returns the structure of parameters to insert into the query
//
// 
// Returns:
//  Structure - the list of names that will be further filled in
//
Function ServiceRequestParameters()

	QueryOptions = New Structure();
	QueryOptions.Insert("HostName", "");
	QueryOptions.Insert("IPAddress", "");
	QueryOptions.Insert("ServiceAddress", "");
	QueryOptions.Insert("CompanyID", "");
	QueryOptions.Insert("ProviderID", "");
	QueryOptions.Insert("NameOfProvider", "");
	QueryOptions.Insert("ConsentID", "");
	QueryOptions.Insert("PaymentMethodByIBAN", "");
	QueryOptions.Insert("PaymentMethodByBBAN", "");
	QueryOptions.Insert("ConnectionID", "");  
	QueryOptions.Insert("RecordID", "");  
	QueryOptions.Insert("AppID", "");
	QueryOptions.Insert("Secret", "");
	QueryOptions.Insert("TestMode", False);
	QueryOptions.Insert("PrivateKey", "");
	QueryOptions.Insert("Service", Enums.BankFeedsServices.EmptyRef());
	QueryOptions.Insert("ServiceSettings", Catalogs.IntegrateWithBankFeeds.EmptyRef());
	QueryOptions.Insert("Bank", Catalogs.BankClassifier.EmptyRef());
	QueryOptions.Insert("BankAccount", Catalogs.CompaniesBankAccounts.EmptyRef());
	QueryOptions.Insert("BankAccountNumber", "");  
	QueryOptions.Insert("AccountCurrency", "");  
	QueryOptions.Insert("InvoiceId", "");  
	QueryOptions.Insert("Organization", Catalogs.Companies.EmptyRef()); 
	QueryOptions.Insert("RequestBody", New Structure());
	QueryOptions.Insert("email", "");
	QueryOptions.Insert("HTTPMethod", "");
	QueryOptions.Insert("RegistrationDetailsForRequest", New Structure());
	QueryOptions.Insert("CompanyRegistrationCountryCode", "");
	
	Return QueryOptions; 
	
EndFunction	

// Returns data from the register of connection informationbankfeeds
//
// Parameters:
//   FillParameters - Structure - data structure
// 
// Returns:
//  Structure - The result of the query:
//  	*LinkToConnectionUpdate - String 
//  	*ResponseStatus - String
//  	*FillParameters - Structure:
//  		**Organization - CatalogRef.Companies - Organization
//  		**Bank - CatalogRef.BankClassifier - Bank
//  		**email - String - String
//  	*ErrorsArray - Array of String 
//
Function CompanyAndBankSettings(FillParameters)
	
	Query = New Query(); 
	Query.SetParameter("Organization", FillParameters.Organization);
	Query.SetParameter("Bank", FillParameters.Bank);
	
	Query.Text = 
	"SELECT
	|	ConnectionsToBankFeedsBanks.CompanyID AS CompanyID,
	|	ConnectionsToBankFeedsBanks.ProviderID AS ProviderID,
	|	ConnectionsToBankFeedsBanks.PaymentMethodByIBAN AS PaymentMethodByIBAN,
	|	ConnectionsToBankFeedsBanks.ConnectionID AS ConnectionID,
	|	ConnectionsToBankFeedsBanks.ServiceSettings AS ServiceSettings,
	|	ConnectionsToBankFeedsBanks.NameOfProvider AS NameOfProvider,
	|	ConnectionsToBankFeedsBanks.RegistrationAttributes AS RegistrationAttributes,
	|	ConnectionsToBankFeedsBanks.RecordID AS RecordID,
	|	ConnectionsToBankFeedsBanks.ConsentID AS ConsentID
	|FROM
	|	InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	|WHERE
	|	ConnectionsToBankFeedsBanks.Organization = &Organization
	|	AND ConnectionsToBankFeedsBanks.Bank = &Bank";
	
	Result = Query.Execute().Select();
	
	If Result.Next() Then
		
		Return Result;
	EndIf;
	
	Return Undefined;
	
EndFunction	

// Returns a response from the server 
//
// Parameters:
//   CommandToService - String - The line selected by the Command: The dictionary is bankfeedservicebankfeedservicebankfeedservicebankfeedservicebankfeedservicebank.Service CommandServices
//   QueryOptions - Structure - a set of parameters for the request 
//   CommandParameters - String - Commands Parameters
// 
// Returns:
//  Structure - Response From The Service
//
Function MakeRequestToService(CommandToService, QueryOptions, CommandParameters = "")

	RequestMethod = CommandToService + CommandParameters;

	// Creating json
	HTTPRequest = New HTTPRequest(RequestMethod);
	FillInHeadings(HTTPRequest.Headers, QueryOptions);
	HTTPMethod = QueryOptions.HTTPMethod;
	
	RequestBody = Undefined;
	If QueryOptions.RequestBody.Count() > 0 Then
		RequestBody = ValueToJSON(QueryOptions.RequestBody);
		RequestBody = StrReplace(RequestBody, Chars.CR, "");
		RequestBody = StrReplace(RequestBody, Chars.LF, "");
		RequestBody = StrReplace(RequestBody, " ", "");
		
		HTTPRequest.SetBodyFromString(RequestBody);
	EndIf;  
	
	FillHeadersWithEncryption(HTTPRequest.Headers, QueryOptions, RequestMethod, RequestBody);
	
	QueryResult = ExecuteQuery(HTTPRequest, HTTPMethod, QueryOptions.HostName);
	
	If Not QueryResult.QueryCompleted Then 
		
		ServerResponse1 = JSONValue(QueryResult.ServerResponse1);
		ErrorDescription_ForUser = "";
		
		If ServerResponse1["error"] <> Undefined Then
			For Each ErrorString In ServerResponse1["error"] Do
				
				If ErrorString.Key = "message" Then
					ErrorDescription_ForUser = ErrorString.Value;
					Break;
				EndIf;
		    EndDo;
		EndIf;
		
		If Not ValueIsFilled(ErrorDescription_ForUser) Then
			ErrorDescription_ForUser = ServerResponse1;
		EndIf;	
			
		TextOfConnectionError  = StringFunctionsClientServer.SubstituteParametersToString(
		        NStr("vi = 'Không thể thực hiện truy vấn theo lệnh:%1 nội dung lỗi:%2';
					|ru = 'Не удалось выполнить запрос по команде:%1 текст ошибки:%2';
					|en = 'Cannot run the command query:%1 error text:%2'; fa = 'Cannot run the command query:%1 error text:%2';
					|it = 'Не удалось выполнить запрос по команде:%1 текст ошибки:%2';
					|pl = 'Cannot run the command query:%1 error text:%2';
					|tr = 'Komut:%1 hata metni:%2 üzerinde sorgu yürütülemedi'"),
				CommandToService, ErrorDescription_ForUser);
		
		Raise ErrorText(TextOfConnectionError);
	EndIf;
	
	ServerResponse1 = JSONValue(QueryResult.ServerResponse1);

	Return ServerResponse1;
	
EndFunction	

// The function executes a request to the server at the specified address 
//
// Parameters:
//   HTTPRequest - String - The line selected by the Command: The dictionary is bankfeedservicebankfeedservicebankfeedservicebankfeedservicebankfeedservicebank.Service CommandServices
//   HTTPMethod - HTTPRequest - request to the service
//   HostName - String - server address
// 
// Returns:
//  Structure - Response From The Service
//
Function ExecuteQuery(Val HTTPRequest, Val HTTPMethod, Val HostName)
	
	Proxy = GetFilesFromInternet.GetProxy("https");
	SecureConnection = CommonClientServer.NewSecureConnection();
	
	Try
		Join = New HTTPConnection(HostName, , , , Proxy, 60, SecureConnection);
		HTTPResponse = Join.CallHTTPMethod(HTTPMethod, HTTPRequest);
	Except
		WriteErrorToEventLog(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kết nối với máy chủ %1 do nguyên nhân:
			|%2';
			|ru = 'Не удалось установить соединение с сервером %1 по причине:
			|%2';
			|en = 'Cannot establish a connection with server %1 due to:
			|%2'; fa = 'Cannot establish a connection with server %1 due to:
			|%2';
			|it = 'Не удалось установить соединение с сервером %1 по причине:
			|%2';
			|pl = 'Nie udało się połączyć się z serwerem %1 z powodu:
			|%2';
			|tr = '%1 sunucusu ile bağlantı şu sebeple kurulamadı:
			|%2'"), HostName, ErrorProcessing.DetailErrorDescription(ErrorInfo())));
		Raise;
	EndTry;
	
	Result = New Structure;
	Result.Insert("QueryCompleted", False);
	Result.Insert("ServerResponse1", "");
	
	If HTTPResponse.StatusCode <> 200 Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa thực hiện yêu cầu ""%1"". Mã trạng thái: %2.';
				|ru = 'Запрос ""%1"" не выполнен. Код состояния: %2.';
				|en = 'Request ""%1"" failed. State code: %2.'; fa = 'Request ""%1"" failed. State code: %2.';
				|it = 'Запрос ""%1"" не выполнен. Код состояния: %2.';
				|pl = 'Zapytanie ""%1"" nie jest wykonane. Kod statusu: %2.';
				|tr = '""%1"" talebi yerine getirilmedi. Durum kodu: %2.'"),
			HTTPRequest.ResourceAddress,
			HTTPResponse.StatusCode) + Chars.LF + HTTPResponse.GetBodyAsString();
		WriteErrorToEventLog(ErrorText);
	EndIf;
		
	If HTTPResponse.StatusCode = 401 
		Or HTTPResponse.StatusCode = 403 Then
		ErrorInfo = Common.JSONValue(HTTPResponse.GetBodyAsString());
		Raise ErrorInfo["message"];  
	ElsIf HTTPResponse.StatusCode = 406 Then
		
		ErrorInfo = Common.JSONValue(HTTPResponse.GetBodyAsString()); 
		Error = ErrorInfo["error"];
		Raise Error["message"];  
		
	EndIf;
	
	Result.QueryCompleted = HTTPResponse.StatusCode = 200;  
	Result.ServerResponse1 = HTTPResponse.GetBodyAsString();
	
	Return Result;
	
EndFunction

// The function executes a request to search for information about the supplier in the transaction
//
// Parameters:
//   QueryOptions - Structure - the data set for the request
//   The mass of Individual merchants is an array of String - an array of identifiers.
// 
// Returns:
//  Structure - The result of the query
//
Function ExecuteRequestForListOfMerchants(ArrayOfMerchantIds, QueryOptions)
	
	CommandsOfServices = BankFeedsDictionaryInternal.CommandsOfServices(QueryOptions.Service);   

	QueryOptions.HTTPMethod = "POST"; 
	BodyStructure = RequestBodyForCommand(QueryOptions.Service, CommandsOfServices.GetTranscriptOfMerchants);  
	BodyStructure.Data = ArrayOfMerchantIds;
	
	QueryOptions.RequestBody = BodyStructure;

	ResponseMerchantDecryptionList = MakeRequestToService(
		CommandsOfServices.GetTranscriptOfMerchants, QueryOptions);
		
	Return ResponseMerchantDecryptionList;
	
EndFunction	

#Region SyncingWithBankFeeds  

Function ListOfBankAccountsAndDownloadPeriodsWhenSyncing(BankAccount)
	
	Query = New Query();
	Query.SetParameter("BankAccount", BankAccount);
	Query.Text = 
	"SELECT
	|	ConnectionsToBankFeedsBanks.Organization AS Organization,
	|	ConnectionsToBankFeedsBanks.Bank AS Bank,
	|	ConnectionsToBankFeedsBanks.ServiceSettings AS ServiceSettings,
	|	CompaniesBankAccounts.Ref AS Ref,
	|	CompaniesBankAccounts.AccountNumber AS AccountNumber,
	|	CompaniesBankAccounts.Ref AS BankAccount
	|INTO ListOfBankAccounts
	|FROM
	|	InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	|		LEFT JOIN Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|		ON ConnectionsToBankFeedsBanks.Bank = CompaniesBankAccounts.Bank
	|			AND ConnectionsToBankFeedsBanks.Organization = CompaniesBankAccounts.Owner
	|WHERE
	|	CompaniesBankAccounts.BankFeedsAccountID <> """"
	|	AND NOT CompaniesBankAccounts.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	ConnectionsToBankFeedsBanks.Organization,
	|	ConnectionsToBankFeedsBanks.Bank,
	|	ConnectionsToBankFeedsBanks.ServiceSettings,
	|	CompaniesBankAccounts.Ref,
	|	CompaniesBankAccounts.AccountNumber,
	|	CompaniesBankAccounts.Ref
	|FROM
	|	InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	|		LEFT JOIN Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|		ON ConnectionsToBankFeedsBanks.Bank = CompaniesBankAccounts.Ref
	|			AND ConnectionsToBankFeedsBanks.Organization = CompaniesBankAccounts.Owner
	|WHERE
	|	CompaniesBankAccounts.BankFeedsAccountID <> """"
	|	AND NOT CompaniesBankAccounts.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(BankAccountReceiptNote.Date) AS DocumentDate,
	|	BankAccountReceiptNote.BankAccount AS BankAccount
	|INTO DetailedTableOfUploadDates
	|FROM
	|	Document.BankAccountReceiptNote AS BankAccountReceiptNote
	|WHERE
	|	BankAccountReceiptNote.Posted
	|
	|GROUP BY
	|	BankAccountReceiptNote.BankAccount
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(BankAccountIssue.Date),
	|	BankAccountIssue.BankAccount
	|FROM
	|	Document.BankAccountIssue AS BankAccountIssue
	|WHERE
	|	BankAccountIssue.Posted = TRUE
	|
	|GROUP BY
	|	BankAccountIssue.BankAccount
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DetailedTableOfUploadDates.BankAccount AS BankAccount,
	|	MAX(DetailedTableOfUploadDates.DocumentDate) AS DocumentDate
	|INTO DateLoadingTable
	|FROM
	|	DetailedTableOfUploadDates AS DetailedTableOfUploadDates
	|
	|GROUP BY
	|	DetailedTableOfUploadDates.BankAccount
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ListOfBankAccounts.Organization AS Organization,
	|	ListOfBankAccounts.Bank AS Bank,
	|	ListOfBankAccounts.ServiceSettings AS ServiceSettings,
	|	ListOfBankAccounts.Ref AS Ref,
	|	ListOfBankAccounts.AccountNumber AS AccountNumber,
	|	ListOfBankAccounts.BankAccount AS BankAccount,
	|	CASE
	|		WHEN ISNULL(DateLoadingTable.DocumentDate, 0) = 0
	|			THEN DATETIME(1, 1, 1)
	|		ELSE DateLoadingTable.DocumentDate
	|	END AS ImportStartDate
	|FROM
	|	ListOfBankAccounts AS ListOfBankAccounts
	|		LEFT JOIN DateLoadingTable AS DateLoadingTable
	|		ON ListOfBankAccounts.BankAccount = DateLoadingTable.BankAccount
	|WHERE
	|	&FilterCriterion";
	
	If ValueIsFilled(BankAccount) Then
		Query.Text = StrReplace(Query.Text, "&FilterCriterion", "ListOfBankAccounts.BankAccount = &BankAccount");
	Else
		Query.Text = StrReplace(Query.Text, "&FilterCriterion", "TRUE");
	EndIf;	
		
	ConnectedBankAccounts = Query.Execute().Unload();
	
	Return  ConnectedBankAccounts;
	
EndFunction

Function FillOutDocumentsForUploadingWhenSyncing(BankAccounts)
	
	If BankAccounts.Count() = 0 Then
		Return New ValueTable();
	EndIf;	
	
	EndDate = CurrentSessionDate();
	StartDate = Date(1,1,1);
	AccountList = New ValueList();
	
	For Each CurLineIsBankAccounts In BankAccounts Do
		
		DateOfPaymentOrderThatWasNotSent = 
			CurLineIsBankAccounts.DateOfPaymentOrderThatWasNotSent;
		
		If DateOfPaymentOrderThatWasNotSent < StartDate Then
			StartDate = DateOfPaymentOrderThatWasNotSent; 
		EndIf;
		
		AccountList.Add(CurLineIsBankAccounts.Ref);
		
	EndDo;	
	
	DocumentsTable = DataProcessors.EDIWithBanksBankFeeds.TableOfDocumentsToUpload(AccountList,
																	StartDate,
																	EndDate,
																	True);
	
	Return DocumentsTable;
EndFunction 

Function FillInBankAccountsWhenUploading(BankAccount)

	Query = New Query();
	Query.SetParameter("BankAccount", BankAccount);
	Query.Text = 
	"SELECT
	|	ConnectionsToBankFeedsBanks.Organization AS Organization,
	|	ConnectionsToBankFeedsBanks.Bank AS Bank,
	|	ConnectionsToBankFeedsBanks.ServiceSettings AS ServiceSettings,
	|	CompaniesBankAccounts.Ref AS Ref,
	|	CompaniesBankAccounts.AccountNumber AS AccountNumber,
	|	CompaniesBankAccounts.Ref AS BankAccount
	|INTO BankAccountsTable
	|FROM
	|	InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	|		LEFT JOIN Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|		ON ConnectionsToBankFeedsBanks.Bank = CompaniesBankAccounts.Bank
	|			AND ConnectionsToBankFeedsBanks.Organization = CompaniesBankAccounts.Owner
	|WHERE
	|	CompaniesBankAccounts.BankFeedsAccountID <> """"
	|	AND NOT CompaniesBankAccounts.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	ConnectionsToBankFeedsBanks.Organization,
	|	ConnectionsToBankFeedsBanks.Bank,
	|	ConnectionsToBankFeedsBanks.ServiceSettings,
	|	CompaniesBankAccounts.Ref,
	|	CompaniesBankAccounts.AccountNumber,
	|	CompaniesBankAccounts.Ref
	|FROM
	|	InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	|		LEFT JOIN Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|		ON ConnectionsToBankFeedsBanks.Bank = CompaniesBankAccounts.Ref
	|			AND ConnectionsToBankFeedsBanks.Organization = CompaniesBankAccounts.Owner
	|WHERE
	|	CompaniesBankAccounts.BankFeedsAccountID <> """"
	|	AND NOT CompaniesBankAccounts.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(BankAccountIssue.Date) AS DateOfPaymentOrderThatWasNotSent,
	|	BankFeedsTransactionStatuses.IDType AS IDType,
	|	BankFeedsTransactionStatuses.TransactionID AS TransactionID,
	|	BankFeedsTransactionStatuses.Status AS Status,
	|	BankFeedsTransactionStatuses.DateOfSendingToService AS DateOfSendingToService,
	|	BankAccountIssue.Organization AS Organization,
	|	BankAccountIssue.BankAccount AS BankAccount
	|INTO Payment_Documents
	|FROM
	|	InformationRegister.BankFeedsTransactionStatuses AS BankFeedsTransactionStatuses
	|		LEFT JOIN Document.BankAccountIssue AS BankAccountIssue
	|		ON BankFeedsTransactionStatuses.Object = BankAccountIssue.Ref
	|WHERE
	|	BankFeedsTransactionStatuses.Status = VALUE(Enum.BankFeedsPaymentDocumentStatuses.NotShipped_5)
	|
	|GROUP BY
	|	BankFeedsTransactionStatuses.IDType,
	|	BankFeedsTransactionStatuses.TransactionID,
	|	BankFeedsTransactionStatuses.Status,
	|	BankFeedsTransactionStatuses.DateOfSendingToService,
	|	BankAccountIssue.Organization,
	|	BankAccountIssue.BankAccount
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Payment_Documents.DateOfPaymentOrderThatWasNotSent AS DateOfPaymentOrderThatWasNotSent,
	|	Payment_Documents.IDType AS IDType,
	|	Payment_Documents.TransactionID AS TransactionID,
	|	Payment_Documents.Status AS Status,
	|	Payment_Documents.DateOfSendingToService AS DateOfSendingToService,
	|	Payment_Documents.Organization AS Organization,
	|	Payment_Documents.BankAccount AS BankAccount,
	|	BankAccountsTable.Bank AS Bank,
	|	BankAccountsTable.ServiceSettings AS ServiceSettings,
	|	BankAccountsTable.Ref AS Ref,
	|	BankAccountsTable.AccountNumber AS AccountNumber
	|FROM
	|	Payment_Documents AS Payment_Documents
	|		LEFT JOIN BankAccountsTable AS BankAccountsTable
	|		ON Payment_Documents.Organization = BankAccountsTable.Organization
	|			AND Payment_Documents.BankAccount = BankAccountsTable.BankAccount
	|WHERE
	|	&FilterCriterion";
	
	If ValueIsFilled(BankAccount) Then
		Query.Text = StrReplace(Query.Text, "&FilterCriterion", "BankAccountsTable.BankAccount = &BankAccount");
	Else
		Query.Text = StrReplace(Query.Text, "&FilterCriterion", "TRUE");
	EndIf;	
	
	ConnectedBankAccounts = Query.Execute().Unload();
	
	Return ConnectedBankAccounts;
	
EndFunction

Function FillInDocumentsForUploadingWhenCheckingStatus(BankAccounts)
	
	If BankAccounts.Count() = 0 Then
		Return New ValueTable();
	EndIf;	

	Query = New Query();  
	Query.SetParameter("BankAccounts", BankAccounts);
	Query.Text = 
	"SELECT
	|	BankAccounts.Ref AS Ref
	|INTO BankAccounts
	|FROM
	|	&BankAccounts AS BankAccounts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	BankFeedsTransactionStatuses.Object AS Ref,
	|	BankFeedsTransactionStatuses.Status AS Status,
	|	BankAccountIssue.BankAccount AS BankAccount,
	|	BankAccountIssue.Organization AS Organization
	|INTO DocumentsTable
	|FROM
	|	InformationRegister.BankFeedsTransactionStatuses AS BankFeedsTransactionStatuses
	|		LEFT JOIN Document.BankAccountIssue AS BankAccountIssue
	|		ON BankFeedsTransactionStatuses.Object = BankAccountIssue.Ref
	|WHERE
	|	BankFeedsTransactionStatuses.Status <> VALUE(Enum.BankFeedsPaymentDocumentStatuses.accepted)
	|	AND BankAccountIssue.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsTable.BankAccount AS BankAccount,
	|	DocumentsTable.Organization AS Organization,
	|	DocumentsTable.Ref AS Ref
	|FROM
	|	BankAccounts AS BankAccounts
	|		INNER JOIN DocumentsTable AS DocumentsTable
	|		ON BankAccounts.Ref = DocumentsTable.BankAccount";
	
	DocumentsTable = Query.Execute().Unload();
	
	Return DocumentsTable;
	
EndFunction	

Function FillInBankAccountsWhenCheckingStatus()

	Query = New Query();
	Query.Text = 
	"SELECT
	|	ConnectionsToBankFeedsBanks.Organization AS Organization,
	|	ConnectionsToBankFeedsBanks.Bank AS Bank,
	|	ConnectionsToBankFeedsBanks.ServiceSettings AS ServiceSettings,
	|	CompaniesBankAccounts.Ref AS Ref,
	|	CompaniesBankAccounts.AccountNumber AS AccountNumber,
	|	CompaniesBankAccounts.Ref AS BankAccount
	|FROM
	|	InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	|		LEFT JOIN Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|		ON ConnectionsToBankFeedsBanks.Bank = CompaniesBankAccounts.Bank
	|			AND ConnectionsToBankFeedsBanks.Organization = CompaniesBankAccounts.Owner
	|WHERE
	|	CompaniesBankAccounts.BankFeedsAccountID <> """"
	|	AND NOT CompaniesBankAccounts.DeletionMark";
	
	ConnectedBankAccounts = Query.Execute().Unload();
	
	Return ConnectedBankAccounts;
	
EndFunction

#EndRegion

Procedure FillInRegistrationDetailsByDefault(AttributesSet, FillParameters)
	
	CurrentUser = Users.CurrentUser();	
	Individual = Common.ObjectAttributeValue(CurrentUser, "Individual");
	
	If ValueIsFilled(Individual) Then
		
		PhysicalPersonSParameters = ParametersOfIndividual(Individual);
		
		FillPropertyValues(AttributesSet, PhysicalPersonSParameters);
		
	EndIf;	   
	
	CompanyParameters = Catalogs.Companies.GetBusinessDetails(FillParameters.Organization);
	
	AttributesSet.CompanyOfficeAddress = PrintFormGeneration.GetAddressFromContactInformation(
													FillParameters.Organization, "Legal", LocalCurDate()); 
	
	AttributesSet.CompanyRegistrationNumber = CompanyParameters.TIN;   
	AttributesSet.CompanyIsRegisteredInCountry = CompanyParameters.RegistrationCountry;
		
	AttributesSet.LegalNameOfCompany = CompanyParameters.DescriptionFull;
	
EndProcedure	

Function ParametersOfIndividual(Individual) 
	
	Query = New Query();
	Query.SetParameter("Individual", Individual);
	Query.Text = 
	"SELECT
	|	Persons.BirthDate AS RegistrarSDateOfBirth,
	|	Persons.Gender AS GenderOfRegistrar,
	|	Persons.Birthplace AS RegistrarSPlaceOfBirth,
	|	Persons.LastFirstName AS LastNameFirstNamePatronymicOfRegistrar,
	|	PersonsContactInformation.Presentation AS RegistrarSResidentialAddress
	|FROM
	|	Catalog.Persons AS Persons
	|
	|		LEFT JOIN Catalog.Persons.ContactInformation AS PersonsContactInformation
	|		ON Persons.Ref = PersonsContactInformation.Ref
	|			AND (PersonsContactInformation.Type = VALUE(Enum.ContactInformationTypes.Address))
	|			AND (PersonsContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.ResidentialAddressPersons))
	|WHERE
	|	Persons.Ref = &Individual";
	
	Result = Query.Execute().Select();
	
	Result.Next();
	
	Return Result;
	
EndFunction	

Function StateOfPaymentDocument(Document)
	
	If Not ValueIsFilled(Document) Then
		Return "";
	EndIf;	
	
	DocumentParameters = Common.ObjectAttributesValues(Document, "Organization,BankAccount,ProcessedByBank");	
	BankAccountBank = Common.ObjectAttributeValue(DocumentParameters.BankAccount, "Bank");
	DocumentParameters.Insert("Bank", BankAccountBank);
	
	ConnectionParameters = CompanyAndBankSettings(DocumentParameters);
	
	If ValueIsFilled(ConnectionParameters) Then
		
		 IDOfBankFeeds = Common.ObjectAttributeValue(
		  				DocumentParameters.BankAccount, "BankFeedsAccountID");
						
			If IDOfBankFeeds <> "" Then
				
				DocumentStatus = CheckStatusOfDocument(Document);
				
				If DocumentStatus <> Enums.BankFeedsPaymentDocumentStatuses.EmptyRef() Then
					
					If DocumentStatus = Enums.BankFeedsPaymentDocumentStatuses.accepted Then
						DocumentState = NStr("vi = 'Ngân hàng đã tiếp nhận';
											|ru = 'Принято банком';
											|en = 'Accepted by the bank'; fa = 'Accepted by the bank';
											|it = 'Принято банком';
											|pl = 'Accepted by the bank';
											|tr = 'Banka tarafından kabul edildi'", Common.DefaultLanguageCode());
					ElsIf DocumentStatus = Enums.BankFeedsPaymentDocumentStatuses.processing Then
						DocumentState = NStr("vi = 'Đang chờ kiểm tra tại ngân hàng';
											|ru = 'Ожидается проверка в банке';
											|en = 'Bank check is expected'; fa = 'Bank check is expected';
											|it = 'Ожидается проверка в банке';
											|pl = 'Bank check is expected';
											|tr = 'Bir banka çeki beklemede'", Common.DefaultLanguageCode());
					ElsIf DocumentStatus = Enums.BankFeedsPaymentDocumentStatuses.rejected  Then
						DocumentState = NStr("vi = 'Đã từ chối';
											|ru = 'Отказано';
											|en = 'Declined'; fa = 'ردشده';
											|it = 'Отказано';
											|pl = 'Declined';
											|tr = 'Reddedildi'", Common.DefaultLanguageCode());
					ElsIf DocumentStatus = Enums.BankFeedsPaymentDocumentStatuses.failed Then
						DocumentState = NStr("vi = 'Đã từ chối';
											|ru = 'Отказано';
											|en = 'Declined'; fa = 'ردشده';
											|it = 'Отказано';
											|pl = 'Declined';
											|tr = 'Reddedildi'", Common.DefaultLanguageCode());
					ElsIf DocumentStatus = Enums.BankFeedsPaymentDocumentStatuses.deleted Then
						DocumentState = NStr("vi = 'Đã xóa';
											|ru = 'Удален';
											|en = 'Deleted'; fa = 'حذف‌شده';
											|it = 'Удален';
											|pl = 'Deleted';
											|tr = 'Silindi'", Common.DefaultLanguageCode());
					Else 
						DocumentState = String(DocumentStatus);
					EndIf;	
						
					Return	DocumentState;
				EndIf;	
				
				If DocumentParameters.ProcessedByBank Then
					Return "";
				Else	
					Return NStr("vi = 'Cần gửi';
								|ru = 'Требуется отправка';
								|en = 'Sending is required'; fa = 'ارسال لازم است';
								|it = 'Требуется отправка';
								|pl = 'Wymagana jest wysyłka';
								|tr = 'Gönderme gerekli'", Common.DefaultLanguageCode());	
				EndIf;	
				
			EndIf;	
			
	EndIf;	
		
	Return "";	

EndFunction

Function CheckStatusOfDocument(Document)

	Query = New Query();                                   
	Query.SetParameter("Document", Document);
	Query.SetParameter("IDType", Enums.BankFeedsIDTypes.ByPaymentOrder);
	
	Query.Text = 
	"SELECT
	|	BankFeedsTransactionStatuses.Status AS Status
	|FROM
	|	InformationRegister.BankFeedsTransactionStatuses AS BankFeedsTransactionStatuses
	|WHERE
	|	BankFeedsTransactionStatuses.Object = &Document
	|	AND BankFeedsTransactionStatuses.IDType = &IDType";
	
	Result = Query.Execute().Select();
	
	If Result.Next() Then
		Return Result.Status;
	EndIf;	
	
	Return Enums.BankFeedsPaymentDocumentStatuses.EmptyRef();
	
EndFunction	

Function CreateInvoiceTable()

	TableOfAccounts = New ValueTable();
	TableOfAccounts.Columns.Add("Account",               New TypeDescription("String"));
	TableOfAccounts.Columns.Add("InvoiceId", New TypeDescription("String"));
	TableOfAccounts.Columns.Add("CreationDate",       New TypeDescription("Date"));
	TableOfAccounts.Columns.Add("Currency",	         New TypeDescription("String"));
	TableOfAccounts.Columns.Add("NameOfAnAccount",	         New TypeDescription("String"));
	TableOfAccounts.Columns.Add("Balance",	         New TypeDescription("String"));

	Return TableOfAccounts; 

EndFunction	

Function CreateTransactionTable()
	
	TransactionsTable = New ValueTable();
	TransactionsTable.Columns.Add("TransactionID", 
		New TypeDescription("String",,New StringQualifiers(100)));
	TransactionsTable.Columns.Add("BankNumber", 
		New TypeDescription("String",,New StringQualifiers(100))); 
	TransactionsTable.Columns.Add("end_to_end_id", 
		New TypeDescription("String",,New StringQualifiers(32))); 
	TransactionsTable.Columns.Add("mode", New TypeDescription("String",,New StringQualifiers(50)));
	TransactionsTable.Columns.Add("status", New TypeDescription("String",,New StringQualifiers(50)));
	TransactionsTable.Columns.Add("CreationDate", New TypeDescription("Date"));
	TransactionsTable.Columns.Add("Sum", New TypeDescription("Number", New NumberQualifiers(15, 3)));
	TransactionsTable.Columns.Add("Currency", New TypeDescription("String",,New StringQualifiers(50)));
	TransactionsTable.Columns.Add("PaymentPurposes", New TypeDescription("String",,New StringQualifiers(500)));
	TransactionsTable.Columns.Add("category", New TypeDescription("String",,New StringQualifiers(50)));
	TransactionsTable.Columns.Add("PartnerSAccountNumber", New TypeDescription("String",,New StringQualifiers(50)));
	TransactionsTable.Columns.Add("extra", New TypeDescription("Structure"));
	TransactionsTable.Columns.Add("PaymentDirection", New TypeDescription("String",,New StringQualifiers(1)));
	TransactionsTable.Columns.Add("ThereIsMerchant", New TypeDescription("Boolean"));
	TransactionsTable.Columns.Add("IDMerchant", New TypeDescription("String",,New StringQualifiers(150)));
	TransactionsTable.Columns.Add("NameMerchant", New TypeDescription("String",,New StringQualifiers(500)));
	
	Return TransactionsTable; 
EndFunction	

Function ValueToJSON(Value)
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, Value);
	Return JSONWriter.Close();
EndFunction

Function JSONValue(String, PropertiesWithDateValuesNames = Undefined)
	JSONReader = New JSONReader;
	JSONReader.SetString(String);
	Return ReadJSON(JSONReader, True, PropertiesWithDateValuesNames);
EndFunction

Function ServiceAddress(Service)
	
	ServiceAddresses = BankFeedsDictionaryInternal.ServiceRequestAddresses();
	
	Return ServiceAddresses[Service];	

EndFunction	

Procedure FillInHeadings(Headers, QueryOptions)

	Headers.Insert("Accept",       "application/json");  
	Headers.Insert("Content-Type", "application/json");
	Headers.Insert("App-id",       QueryOptions.AppID);
	Headers.Insert("Secret",       QueryOptions.Secret);

EndProcedure

Function GetUnixTimeFromDate(DateParameter) 
	
	CurrentTimeZone = SessionTimeZone();
	
	Return ToUniversalTime(DateParameter, CurrentTimeZone) - '19700101';
	
EndFunction

Procedure FillHeadersWithEncryption(Headers, QueryOptions, RequestMethod, RequestBody)
	
	If QueryOptions.TestMode Then
		Return;
	EndIf;	
	
	TimeLimit = GetUnixTimeFromDate(CurrentSessionDate()) + 60;
	TimeLimit = Format(TimeLimit, "NG=0");		
	
	TextToEncrypt = StringFunctionsClientServer.SubstituteParametersToString(
				"%1|%2|%3|%4", TimeLimit, QueryOptions.HTTPMethod, 
						"https://" + QueryOptions.HostName + RequestMethod, 
					?(RequestBody = Undefined, "", RequestBody));	
					
	NameOfTemporaryFileWithTextForSignature = GetTempFileName();	
	
	TXTFile = New TextDocument;
	TXTFile.SetText(TextToEncrypt);
	TXTFile.Write(NameOfTemporaryFileWithTextForSignature, "CESU-8");
	
	NamePathOfClosedSignatureFile = QueryOptions.PrivateKey;

	NameOfTemporaryFileWithTextSignedWithSignature256 = GetTempFileName();	

	// running the Command	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	ApplicationStartupParameters.GetOutputStream = False;
	CommandText = StringFunctionsClientServer.SubstituteParametersToString(
		"openssl dgst -sha256 -sign %1 -out %2 %3", 
		NamePathOfClosedSignatureFile, NameOfTemporaryFileWithTextSignedWithSignature256, NameOfTemporaryFileWithTextForSignature);
	RunResult = FileSystem.StartApplication(CommandText, ApplicationStartupParameters);
	
	ReturnCode = RunResult.ReturnCode;
	If ReturnCode <> 0 Then
		
		TextOfConnectionError  = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể thực hiện lệnh %1 :%2 nội dung lỗi:%3';
					|ru = 'Не удалось выполнить команду %1 :%2 текст ошибки:%3';
					|en = 'Cannot run the %1 command:%2 error text:%3'; fa = 'Cannot run the %1 command:%2 error text:%3';
					|it = 'Не удалось выполнить команду %1 :%2 текст ошибки:%3';
					|pl = 'Cannot run the %1 command:%2 error text:%3';
					|tr = '%1 :%2 komutu çalıştırılamadı hata metni:%3'"),
				"OpenSSL", CommandText, RunResult.ErrorStream);
		
		Raise ErrorText(TextOfConnectionError);
	EndIf;	
	
	// reading the created file
	SignatureIsBinary = New BinaryData(NameOfTemporaryFileWithTextSignedWithSignature256);
	
	Signature64 = Base64String(SignatureIsBinary); 
    Signature64 = StrReplace(Signature64, Chars.CR, "");
    Signature64 = StrReplace(Signature64, Chars.LF, "");

	FileSystem.DeleteTempFile(NameOfTemporaryFileWithTextForSignature);
	FileSystem.DeleteTempFile(NameOfTemporaryFileWithTextSignedWithSignature256);
	
	Headers.Insert("Expires-at", TimeLimit);  
	Headers.Insert("Signature",  Signature64);
					
EndProcedure	

Function ErrorText(ErrorText)
	
	If Users.IsFullUser() Then
		Return ErrorText + Chars.LF + NStr("vi = 'Chi tiết xem trong nhật ký sự kiện.';
											|ru = 'Подробности см. в журнале регистрации.';
											|en = 'See the event log for details.'; fa = 'See the event log for details.';
											|it = 'Подробности см. в журнале регистрации.';
											|pl = 'Szczegóły zob. w dzienniku rejestracji.';
											|tr = 'Ayrıntılar için olay günlüğüne bakın.'");
	EndIf;
	
	Return ErrorText + Chars.LF + NStr("vi = 'Hãy liên hệ với người quản trị.';
										|ru = 'Обратитесь к администратору.';
										|en = 'Please contact the administrator.'; fa = 'Please contact the administrator.';
										|it = 'Обратитесь к администратору.';
										|pl = 'Skontaktuj się z administratorem.';
										|tr = 'Yöneticiye başvurun.'");
	
EndFunction

// Returns the IP and MAC address of the application server.
//
// Returns:
//   Structure:
//     * IPAddress - String
//     * MACAddress - String
//
Function DigitalFootprint()
	
	DigitalFootprint = New Structure("IPAddress, MACAddress", "", "");
	
	//@skip-check undefined-function
	AllAdapters = GetNetworkAdaptersInformation();
	
	If AllAdapters.Count() > 0 Then
		CurCurrentAdapter = AllAdapters[0];
		For Each NetworkAdapter In AllAdapters Do
			If NetworkAdapter.IsCurrentAdapter = True Then
				CurCurrentAdapter = NetworkAdapter;
				Break;
			EndIf;
		EndDo;
		
		DigitalFootprint.IPAddress = CurCurrentAdapter.IPAddress;
		DigitalFootprint.MACAddress = CurCurrentAdapter.MACAddress;
		
	EndIf;
	
	Return DigitalFootprint;
	
EndFunction

Procedure WriteErrorToEventLog(Comment)
	
	WriteLogEvent(NStr("vi = 'Dịch văn bản';
						|ru = 'Перевод текста';
						|en = 'Translator'; fa = 'مترجم';
						|it = 'Перевод текста';
						|pl = 'Tłumaczenie tekstu';
						|tr = 'Metin çevirisi'", Common.DefaultLanguageCode()),
		EventLogLevel.Error, , Enums.TextTranslationServices.YandexTranslate, Comment);
	
EndProcedure

Procedure Add_Transaction(TransactionsTable, LineFromService)
	
	NewRow = TransactionsTable.Add();
	NewRow.TransactionID = GetValue(LineFromService, "id", "String", "");
	NewRow.mode =                    GetValue(LineFromService, "mode", "String", "");
	NewRow.CreationDate =            GetValue(LineFromService, "made_on", "JSONDate", Date("00010101"));
	NewRow.Sum =                   GetValue(LineFromService, "amount", "Number", 0);
	NewRow.Currency =                  GetValue(LineFromService, "currency_code", "String", 0);
	NewRow.PaymentPurposes =       GetValue(LineFromService, "description", "String", 0);
	NewRow.category =                GetValue(LineFromService, "category", "String", 0);

	NewRow.status = GetValue(LineFromService,"status", 
		"EnumRef.BankFeedsPaymentDocumentStatuses",
		Enums.BankFeedsPaymentDocumentStatuses.EmptyRef());
	
	NewRow.PaymentDirection = ?(NewRow.Sum>0, "2", "1");
	NewRow.extra = GetValue(LineFromService, "extra", "Map", New Structure());
	
	If NewRow.extra.Property("merchant_id") Then
		
		MerchantID = NewRow.extra.merchant_id;
		
		If ValueIsFilled(MerchantID) Then
			
			NewRow.ThereIsMerchant = True;
			NewRow.IDMerchant = MerchantID;
			
		EndIf;	
		
	EndIf;	

	If NewRow.extra.Property("end_to_end_id") Then
		
		NewRow.end_to_end_id = NewRow.extra.end_to_end_id;	
		
	EndIf;
	
	If NewRow.extra.Property("record_number") Then
		
		NewRow.BankNumber = NewRow.extra.record_number;	
		
	ElsIf NewRow.extra.Property("id") Then	
		
		NewRow.BankNumber = NewRow.extra.id;	
		
		If StrLen(NewRow.BankNumber) > 20 Then
		    ReceivedString = Left(NewRow.BankNumber, Find(NewRow.extra.id, "-")-1);  
			If StrLen(ReceivedString) > 0 Then
				NewRow.BankNumber = ReceivedString;	
			EndIf;
		EndIf;	
		
	EndIf;
	
	If NewRow.extra.Property("posting_date") Then
		
		NewRow.extra.posting_date = GetValue(NewRow.extra, "posting_date", "JSONDate", Date("00010101"))
		
	EndIf;
	
EndProcedure	

Procedure AddBankAccountFromService(TableOfAccounts, LineFromService)
	
	AdditionalFields = GetValue(LineFromService, "extra", "Structure", "");
	
	If Not AdditionalFields.Property("iban") Then
		Return;
	EndIf;	
	
	NewRow = TableOfAccounts.Add();
	NewRow.InvoiceId = GetValue(LineFromService, "id", "String", "");
	NewRow.CreationDate = GetValue(LineFromService, "created_at", "JSONDate", "");
	NewRow.Currency = GetValue(LineFromService, "currency_code", "String", "");
	NewRow.Account = AdditionalFields.iban;
	NewRow.NameOfAnAccount = GetValue(LineFromService, "name", "String", "");
	NewRow.Balance = GetValue(LineFromService, "balance", "String", "");
	
EndProcedure	

// Get the value.
// 
// Parameters:
//  Source - Arbitrary - source.
//  AttributeName - String - name of the prop.
//  ValueType - String - the type of value.
//  DefaultValue - Arbitrary - default.
// 
// Returns:
//  Arbitrary - a value of any type
//
Function GetValue(Val Source, AttributeName, ValueType = "", DefaultValue = Undefined)
	
	Value = DefaultValue;
	
		SourceValue = Source[AttributeName];
		
		If SourceValue = Undefined Then
			Value = DefaultValue;
		ElsIf TypeOf(SourceValue) = Type("Structure") Then
			Value = SourceValue;
		ElsIf TypeOf(SourceValue) = Type("Map") Then
			
			Value = New Structure();
			
			For Each CurrentRow In SourceValue Do
				Value.Insert(CurrentRow.Key, CurrentRow.Value);
			EndDo;	
			
		ElsIf TypeOf(SourceValue) = Type("Array") Then
			Value = SourceValue;
		ElsIf TypeOf(SourceValue) = Type("Date") Then
			Value = SourceValue;
		ElsIf TypeOf(SourceValue) = Type("String") And Upper(SourceValue) = "NONE" Then
			Value = DefaultValue;
		ElsIf ValueType = "" Then
			Value = SourceValue;
		ElsIf ValueType = "JSONDate" Then
			Value = ReadJSONDate(Source[AttributeName], JSONDateFormat.ISO);
		ElsIf ValueType = "Date" Then
			Value = StringToDate(SourceValue);
		ElsIf ValueType = "Number" Then
			Value = StringToNumber(SourceValue, DefaultValue);
		ElsIf ValueType = "EnumRef.BankFeedsPaymentDocumentStatuses" Then
			Value = Enums.BankFeedsPaymentDocumentStatuses[SourceValue];
		Else
			RequiredType	= New TypeDescription(ValueType);
			Value		= RequiredType.AdjustValue(SourceValue);
		EndIf;
		
		If Value = Undefined Then
			Value = DefaultValue;
		EndIf;
	
	Return Value;
	
EndFunction

Function StringToDate(Value)
	
	Value = StrReplace(Value, " ", "");
	Value = TrimAll(StrReplace(Value, ":", ""));
	Value = TrimAll(StrReplace(Value, "-", ""));
	Value = TrimAll(StrReplace(Value, "T", ""));
	Value = TrimAll(StrReplace(Value, ".", ""));
	
	TypeDetails = New TypeDescription("Date");
	Result = TypeDetails.AdjustValue(Value);
	
	Return Result;
	
EndFunction

Function StringToNumber(Value, DefaultValue = Undefined)
	
	If TypeOf(Value) = Type("Number") Then
		Result = Value;
	ElsIf TypeOf(Value) = Type("String") Then
		Result = StringFunctionsClientServer.StringToNumber(Value);
	Else
		Result = Undefined;
	EndIf;
	
	If Result = Undefined Then
		Result = DefaultValue;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion  

