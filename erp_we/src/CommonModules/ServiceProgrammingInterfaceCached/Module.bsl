
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// the EXT Api version of the service manager.
// 
// Returns:
//  Number - the EXT Api version of the service manager.
Function ServiceManagerExtAPIVersion() Export
	
	Return ServiceProgrammingInterfaceInternal.ServiceManagerExtAPIVersion();

EndFunction

// Indicates whether the method is supported in the address.
// 
// Returns:
//  Boolean - the service manager supports the method in the address.
Function ServiceManagerSupportsMethodInAddress() Export

	Return ServiceProgrammingInterfaceInternal.ServiceManagerSupportsMethodInAddress();

EndFunction

// Properties of the interface version.
// 
// Returns:
//  Structure:
//   * Version - Number
//   * ServiceManagerVersion - String - in the Editorial format.Sub-edit.Version.Assembling
//   * TimeZoneOfServiceManager - String - time zone.
//   * ServiceManagerExternalURL - String
Function InterfaceVersionProperties() Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Address = VersionAddressOfExternalSoftwareInterface();
	
	QueryData = New Structure;
	QueryData.Insert("host", GetInfoBaseURL());
	If SaaSOperations.DataSeparationEnabled() Then
		Response = SaaSOperationsCTL.SendRequestToServiceManager("POST", Address, QueryData);
	Else
		Response = IsInternal.SendRequestToServiceFromLocalDatabase("POST", Address, QueryData);
	EndIf;
	
	If Response.StatusCode <> 200 Then
		ExceptionText = NStr("vi = 'Không thể nhận thuộc tính phiên bản của giao diện chương trình, tạm thời không truy cập được dịch vụ:
			|Nguồn: %1
			|Mã phản hồi: %2
			|Phản hồi: %3';
			|ru = 'Не удалось получить свойства версии программного интерфейса, сервис временно недоступен:
			|Ресурс: %1
			|Код ответа: %2
			|Ответ: %3';
			|en = 'Failed to obtain API version properties. The service is temporarily unavailable.
			|Resource: %1
			|Response code: %2
			|Response: %3'; fa = 'Failed to obtain API version properties. The service is temporarily unavailable.
			|Resource: %1
			|Response code: %2
			|Response: %3';
			|it = 'Не удалось получить свойства версии программного интерфейса, сервис временно недоступен:
			|Ресурс: %1
			|Код ответа: %2
			|Ответ: %3';
			|pl = 'Failed to obtain API version properties. The service is temporarily unavailable.
			|Resource: %1
			|Response code: %2
			|Response: %3';
			|tr = 'Program arayüzünün sürüm özellikleri alınamadı, hizmet geçici olarak kullanılamıyor:
			|Kaynak: %1
			|Cevap kodu: %2
			|Cevap: %3'");
		Raise StrTemplate(ExceptionText, Address, Response.StatusCode, Response.GetBodyAsString());			
	EndIf;
	
 	DataStream = Response.GetBodyAsStream();
	ResponseData = SaaSOperationsCTL.StructureFromJSONStream(DataStream);
	Renamings = New Map;
	Renamings.Insert("version", "Version");
	Renamings.Insert("sm_version", "ServiceManagerVersion");
	Renamings.Insert("sm_timezone", "TimeZoneOfServiceManager");
	Renamings.Insert("sm_ext_url", "ServiceManagerExternalURL");
	
	Return IsInternal.RenameProperties(ResponseData, Renamings);
	
EndFunction

// Connection with the service manager from the local database.
// 
// Parameters:
//  ServerData - See CommonClientServer.URIStructure
//  Timeout - Number - Timeout
// 
// Returns:
//  HTTPConnection - connection with the Service Manager.
Function ConnectingToServiceManagerFromLocalDatabase(ServerData, Timeout = 60) Export
	
	Return ServiceProgrammingInterfaceInternal.ConnectingToServiceManagerFromLocalDatabase(ServerData, Timeout);
	
EndFunction

Function ConnectionToServiceManagerWithoutAuthorization(ServerData, Timeout = 60) Export
	
	Return ServiceProgrammingInterfaceInternal.ConnectionToServiceManagerWithoutAuthorization(ServerData, Timeout);
	
EndFunction

// The subscriber of this application.
// 
// Parameters:
//  User - CatalogRef.Users - User
//  Token - String
// 
// Returns:
//  Structure - subscriber data:
//  * Description - String
//  * Code - Number
//  * UserRole - EnumRef.SubscriberUsersRoles
Function SubscriberOfThisApplication(Val User = Undefined, Val Token = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/account";

	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SaaSOperations.SessionSeparatorValue());
	QueryData.Insert("auth", IsInternal.AuthorizationProperties(Undefined, User, Token));
	Address = IsInternal.ExecutionAddressOfExternalSoftwareInterface(Method);
	If SaaSOperations.AccessTokenAuthenticationOfInternalAPIRequests()
		And Token = Undefined Then
		AccessToken = ServiceProgrammingInterface.ValidAccessToken(User);
		Result = ServiceProgrammingInterfaceInternal.SendRequestToServiceManagerByAccessToken(
			"POST", Address, AccessToken, QueryData);
	Else
		Result = SaaSOperationsCTL.SendRequestToServiceManager("POST", Address, QueryData);
	EndIf;

	ResponseData = IsInternal.ExecutionResult(Result);
	Subscriber = ResponseData.account;
	RoleField = "role";
	Subscriber[RoleField] = Enums.SubscriberUsersRoles.ValueByName(Subscriber[RoleField]);

	Renamings = IsInternal.RenamingSubscriber();
	Renamings.Insert(RoleField, "UserRole");

	Return IsInternal.RenameProperties(Subscriber, Renamings);

EndFunction

Function SubscriberCode() Export
	Return SaaSOperations.SubscriberCode();
EndFunction

// The subscriber's service organizations.
// 
// Returns:
//  ValueTable:
//   * Description - String
//   * Code - Number
//   * Website1 - String
//   * Phone - String
//   * Mail - String
//   * City - String
//   * Id - String
//   * AutomaticInvoiceIssuanceAllowed - Boolean
//   * TariffOverrideAllowed - Boolean
//   * FareSelectionPageOnly - Boolean
Function SubscriberSServiceOrganizations() Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/servants/list";
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", ServiceProgrammingInterface.SubscriberCode());
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result);

	Renamings = IsInternal.RenamingSubscriber(True);
	Renamings.Insert("servant_id", IsInternal.ColumnDetails(
		"Id", Common.StringTypeDetails(50)));
	Renamings.Insert("tariff_subscribe_allowed", IsInternal.ColumnDetails(
		"YouCanSubscribeToPricingPlans", New TypeDescription("Boolean")));
	Renamings.Insert("automatic_billing_allowed", IsInternal.ColumnDetails(
		"AutomaticInvoiceIssuanceAllowed", New TypeDescription("Boolean")));
	Renamings.Insert("tariff_override_allowed", IsInternal.ColumnDetails(
		"TariffOverrideAllowed", New TypeDescription("Boolean")));
	Renamings.Insert("tariff_selection_page_only", IsInternal.ColumnDetails(
		"FareSelectionPageOnly", New TypeDescription("Boolean")));
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.servants, Renamings);

EndFunction

// The service rate.
//
// Parameters:
//  ServicePlanCode - String - fare code.
//
// Returns:
//  Structure - tariff information:
//   * Code - String - fare code
//   * Description - String - name of the tariff
//   * DescriptionForServiceOrganizations - String - description of the tariff for the service organization.
//   * DescriptionForSubscribers - FormattedDocument - description of the tariff for subscribers.
//   * ValidityStartDate - Date - start date of the tariff.
//   * ValidityEndDate - Date - expiration date of the tariff.
//   * ProlongationSubscriptionPeriod - Number - the period (in days) during which the renewing subscription is valid (if renewal is allowed).
//   * ExtensionSubscriptionPeriod - Number - the period (in days) during which the extension subscription is valid.
//   * PeriodForAddingRenewingSubscription - Number - the period (in days) after the subscription expires during which you can create a renewal subscription.
//   * TariffExpansion - Boolean - indicates that the tariff is an extension
//   * TariffType - EnumRef.TariffTypes - Fare Type
//   * Paid - Boolean - indicates that the tariff is paid (contains paid validity periods)
//   * Test_ - Boolean - indicates that the tariff is a test one
//   * ThereIsCondition - Boolean - indicates that the use of the tariff requires compliance with the terms of use.
//   * PeriodicPayment - Boolean - indicates that the tariff uses periodic payment
//   * FrequencyOfPayment - String - code of the payment frequency period
//   * Services - ValueTable - tariff services:
//     ** Code - String - service code
//     ** Description - String - name of the service
//     ** ServiceType - EnumRef.ServicesTypes - type of service
//     ** LongDesc - String - Service description
//     ** LicensesCount - Number - number of service licenses included in the tariff
//     ** NumberOfAdditionalLicensesForExpandingSubscription - Number - the number of service licenses that can be provided by an extension subscription
//     ** VendorID - String - ID of the service provider
//     ** SupplierName - String - name of the service provider
//   * Extensions - ValueTable - tariff extensions:
//     ** Code - String - extension rate code
//     ** Description - String - name of the extension rate
//   * Configurations - ValueTable - tariff configurations:
//     ** Code - String - configuration code
//     ** Description - String - configuration name
//     ** LongDesc - String - the description of the configuration
//   * ActionPeriods - ValueTable - tariff validity periods:
//     ** Code - String - validity period code
//     ** Description - String - name of the validity period
//     ** Sum - Number - Cost
//     ** Comment - String - comment on the validity period
//   * SubscriptionTerminationNotificationPeriods - ValueTable - periods of notifications about the end of subscription to the tariff:
//     ** DaysCount - Number - the number of days to notify the user.
Function ServiceRate(ServicePlanCode) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tariff/info";
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", ServicePlanCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result);
	Tariff = ResponseData.tariff;

	Renamings = IsInternal.RenamingRates();
	
	Renamings.Insert("condition", "TermsOfUse_");
	Renamings.Insert("services", IsInternal.ColumnDetails("Services", New TypeDescription("ValueTable")));
	Renamings.Insert("extensions", IsInternal.ColumnDetails("Extensions", New TypeDescription("ValueTable")));
	Renamings.Insert("applications", IsInternal.ColumnDetails(
		"Configurations", New TypeDescription("ValueTable")));
	Renamings.Insert("validity_periods", IsInternal.ColumnDetails(
		"ActionPeriods", New TypeDescription("ValueTable")));
	Renamings.Insert("notification_periods", IsInternal.ColumnDetails(
		"SubscriptionTerminationNotificationPeriods", New TypeDescription("ValueTable")));

	RenamingService = New Map;
	RenamingService.Insert("id", "Code");
	RenamingService.Insert("name", "Description");
	RenamingService.Insert("type", IsInternal.ColumnDetails(
		"ServiceType", New TypeDescription("EnumRef.ServicesTypes")));
	RenamingService.Insert("description", "LongDesc");
	RenamingService.Insert("amount", "LicensesCount");
	RenamingService.Insert("extend_amount", "NumberOfAdditionalLicensesForExpandingSubscription");
	RenamingService.Insert("provider_id", "VendorID");
	RenamingService.Insert("provider_name", "SupplierName");

	TariffExtensionsRenamings = IsInternal.TariffExtensionsRenamings();

	RenamingConfiguration = New Map;
	RenamingConfiguration.Insert("id", "Code");
	RenamingConfiguration.Insert("name", "Description");
	RenamingConfiguration.Insert("description", "LongDesc");

	RenamingValidityPeriods = IsInternal.RenamesAndValidityPeriods();
	
	RenamingAlertPeriods = New Map;
	RenamingAlertPeriods.Insert("days_quantity", IsInternal.ColumnDetails(
		"DaysCount", Common.TypeDescriptionNumber(2, 0, AllowedSign.Nonnegative)));

	IsInternal.RenameProperties(Tariff, Renamings);

	// We will process the description for subscribers
	AttachmentsStructure = New Structure;
	For Each Attachment In Tariff.DescriptionForSubscribers.images Do
		PictureData = GetBinaryDataFromBase64String(Attachment.data);
		AttachmentsStructure.Insert(Attachment.name, New Picture(PictureData, True));
	EndDo;
	DescriptionForSubscribers = New FormattedDocument;
	DescriptionForSubscribers.SetHTML(Tariff.DescriptionForSubscribers.html, AttachmentsStructure);
	Tariff.DescriptionForSubscribers = DescriptionForSubscribers;

	Tariff.Services = IsInternal.StructuresArrayIntoValueTable(Tariff.Services, RenamingService);
	Tariff.Extensions = IsInternal.StructuresArrayIntoValueTable(Tariff.Extensions, TariffExtensionsRenamings);
	Tariff.Configurations = IsInternal.StructuresArrayIntoValueTable(Tariff.Configurations, RenamingConfiguration);
	Tariff.ActionPeriods = IsInternal.StructuresArrayIntoValueTable(Tariff.ActionPeriods, RenamingValidityPeriods);
	Tariff.SubscriptionTerminationNotificationPeriods = IsInternal.StructuresArrayIntoValueTable(
		Tariff.SubscriptionTerminationNotificationPeriods, RenamingAlertPeriods);

	Return Tariff;

EndFunction

// The tariff of the service organization.
// 
// Parameters:
//  SCCode - Number - code of the service organization
//  ServicePlanCode -String - tariff code of the service organization
// 
// Returns:
//  Structure - tariff information:
//   * Code - String - fare code
//   * Description - String - name of the tariff
//   * ProviderServicePlanCode - String - provider's tariff code
//   * ShortDescription - String - brief description of the tariff
//   * DescriptionForSubscribers - FormattedDocument - description of the tariff for subscribers.
//   * ActionPeriods - ValueTable - tariff validity periods:
//     ** Code - String - validity period code
//     ** Description - String - name of the validity period
//     ** Sum - Number - Cost
//     ** Recommended_ - Boolean - indicates that the period is recommended for purchase
//     ** Comment - String - comment on the validity period
Function ServiceOrganizationTariff(SCCode, ServicePlanCode) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/servant_tariffs/info";
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("servant", SCCode);
	QueryData.Insert("id", ServicePlanCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result);
	Tariff = ResponseData.servant_tariff;

	Renamings = IsInternal.RenamingServiceOrganizationRates(Method);
	RenamingPeriods = IsInternal.RenamingServiceOrganizationTariffValidityPeriods();
	IsInternal.RenameProperties(Tariff, Renamings);

	AttachmentsStructure = New Structure;
	For Each Attachment In Tariff.DescriptionForSubscribers.images Do
		PictureData = GetBinaryDataFromBase64String(Attachment.data);
		AttachmentsStructure.Insert(Attachment.name, New Picture(PictureData, True));
	EndDo;
	DescriptionForSubscribers = New FormattedDocument;
	DescriptionForSubscribers.SetHTML(Tariff.DescriptionForSubscribers.html, AttachmentsStructure);
	Tariff.DescriptionForSubscribers = DescriptionForSubscribers;

	Tariff.ActionPeriods = IsInternal.StructuresArrayIntoValueTable(Tariff.ActionPeriods, RenamingPeriods);

	Return Tariff;

EndFunction

Function TimeZones() Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "timezones/list";
	
	QueryData = IsInternal.QueryTemplate(Method);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result);
	
	Renamings = New Map;
	Renamings.Insert("id", IsInternal.ColumnDetails("Id", Common.StringTypeDetails(0)));
	Renamings.Insert("description", IsInternal.ColumnDetails("Presentation", Common.StringTypeDetails(0)));
	Renamings.Insert("offset", IsInternal.ColumnDetails("Offset", Common.TypeDescriptionNumber(6)));
	Renamings.Insert("primary", IsInternal.ColumnDetails("Main", New TypeDescription("Boolean")));
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.timezones, Renamings);
	
EndFunction

#EndRegion

#Region Private

Function VersionAddressOfExternalSoftwareInterface()

	Return "hs/ext_api/version";

EndFunction

#EndRegion

#EndIf