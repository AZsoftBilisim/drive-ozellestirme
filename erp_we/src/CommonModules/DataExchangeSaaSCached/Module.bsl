///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns True if synchronization is supported in SaaS mode
// 
// Returns:
//  Boolean
//
Function DataSynchronizationSupported() Export
	
	Return DataSynchronizationExchangePlans().Count() > 0;
	
EndFunction

// Returns a collection of exchange plans used for synchronization.
// SaaS synchronization exchange plan must fulfill the following conditions:
// - It must be included in the SSL data exchange subsystem.
// - It must be separated.
// - It cannot be included in a DIB.
// - It must be used for exchange in SaaS (ExchangePlanUsedInSaaS = True).
// 
// Returns:
//  Array of String - Array of the names of the exchange plans used for syncing
//
Function DataSynchronizationExchangePlans() Export
	
	Result = New Array;
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		If Not ExchangePlan.DistributedInfoBase
			And DataExchangeCached.ExchangePlanUsedInSaaS(ExchangePlan.Name)
			And DataExchangeServer.IsSeparatedSSLExchangePlan(ExchangePlan.Name) Then
			
			Result.Add(ExchangePlan.Name);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

#EndRegion

#Region Private

// Returns a reference to the WSProxy object of exchange service 1.0.6.5.
//
// Returns:
//   WSProxy
//
Function GetExchangeServiceWSProxy() Export
	
	Result = Undefined;
	If Common.SubsystemExists("CloudTechnology.MessagesExchange") Then
		
		ModuleSaaSOperationsCTLCached = Common.CommonModule("SaaSOperationsCTLCached");
		ModuleMessagesExchangeTransportSettings = Common.CommonModule("InformationRegisters.MessageExchangeTransportSettings");
		
		//  @skip-warning Method filled in from the BTS service extension
		TransportSettings = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(
			ModuleSaaSOperationsCTLCached.ServiceManagerEndpoint());
		
		SettingsStructure = New Structure;
		SettingsStructure.Insert("WSWebServiceURL",   TransportSettings.WSWebServiceURL);
		SettingsStructure.Insert("WSUserName", TransportSettings.WSUserName);
		SettingsStructure.Insert("WSPassword",          TransportSettings.WSPassword);
		SettingsStructure.Insert("WSServiceName",      "ManageApplicationExchange_1_0_6_5");
		SettingsStructure.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SaaS/1.0/WS/ManageApplicationExchange_1_0_6_5");
		SettingsStructure.Insert("WSTimeout", 20);
		
		Result = DataExchangeWebService.GetWSProxyByConnectionParameters(SettingsStructure);
	EndIf;
	
	If Result = Undefined Then
		Raise NStr("vi = 'Lỗi nhận Web-service trao đổi dữ liệu của ứng dụng được điều khiển.';
					|ru = 'Ошибка получения web-сервиса обмена данными управляющего приложения.';
					|en = 'An error occurred when getting the data exchange web service from the managing application.'; fa = 'An error occurred when getting the data exchange web service from the managing application.';
					|it = 'Errore di ricezione del servizio di condivisione dati web dell''applicazione di controllo.';
					|pl = 'Błąd pobierania web-serwisu wymiany danych aplikacji zarządzającej.';
					|tr = 'Yönetici uygulamanın veri değişimi web servisi alınırken hata oluştu.'");
	EndIf;
	
	Return Result;
EndFunction

// Returns a reference to the WSProxy object of the correspondent identified by the exchange plan node.
//
// Parameters:
//   InfobaseNode - ExchangePlanRef
//   ErrorMessageString - String - an error message text.
//
// Returns:
//   WSProxy
//
Function GetWSProxyOfCorrespondent(InfobaseNode, ErrorMessageString = "") Export
	
	SettingsStructure = InformationRegisters.DataAreaExchangeTransportSettings.TransportSettingsWS(InfobaseNode);
	SettingsStructure.Insert("WSServiceName", "RemoteAdministrationOfExchange");
	SettingsStructure.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SaaS/1.0/WS/RemoteAdministrationOfExchange");
	SettingsStructure.Insert("WSTimeout", 20);
	
	Return DataExchangeWebService.GetWSProxyByConnectionParameters(SettingsStructure, ErrorMessageString);
	
EndFunction

// Returns a reference to WSProxy object 2.0.1.6 of the correspondent identified by the exchange plan node.
//
// Parameters:
//   InfobaseNode - ExchangePlanRef
//   ErrorMessageString - String - an error message text.
//
// Returns:
//   WSProxy
//
Function GetWSProxyOfCorrespondent_2_0_1_6(InfobaseNode, ErrorMessageString = "") Export
	
	SettingsStructure = InformationRegisters.DataAreaExchangeTransportSettings.TransportSettingsWS(InfobaseNode);
	SettingsStructure.Insert("WSServiceName", "RemoteAdministrationOfExchange_2_0_1_6");
	SettingsStructure.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SaaS/1.0/WS/RemoteAdministrationOfExchange_2_0_1_6");
	SettingsStructure.Insert("WSTimeout", 20);
	
	Return DataExchangeServer.GetWSProxyByConnectionParameters(SettingsStructure, ErrorMessageString);
EndFunction

// Returns a reference to WSProxy object 2.1.6.1 of the correspondent identified by the exchange plan node.
// 
// Parameters:
//  InfobaseNode - ExchangePlanRef
//  ErrorMessageString - String - The default value is "".
// 
// Returns:
//  - Undefined - If failed to create "WSProxy"
//  - WSProxy 
//
Function GetWSProxyOfCorrespondent_2_1_6_1(InfobaseNode, ErrorMessageString = "") Export
	
	SettingsStructure = InformationRegisters.DataAreaExchangeTransportSettings.TransportSettingsWS(InfobaseNode);
	SettingsStructure.Insert("WSServiceName", "RemoteAdministrationOfExchange_2_1_6_1");
	SettingsStructure.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SaaS/1.0/WS/RemoteAdministrationOfExchange_2_1_6_1");
	SettingsStructure.Insert("WSTimeout", 20);
	
	Return DataExchangeServer.GetWSProxyByConnectionParameters(SettingsStructure, ErrorMessageString);
EndFunction

// Returns a reference to WSProxy object 2.4.5.1 of the correspondent identified by the exchange plan node.
// 
// Parameters:
//  InfobaseNode - ExchangePlanRef
//  ErrorMessageString - String - The default value is "".
// 
// Returns:
//  - Undefined - If failed to create "WSProxy"
//  - WSProxy 
//
Function GetWSProxyOfCorrespondent_2_4_5_1(InfobaseNode, ErrorMessageString = "") Export
	
	SettingsStructure = InformationRegisters.DataAreaExchangeTransportSettings.TransportSettingsWS(InfobaseNode);
	SettingsStructure.Insert("WSServiceName", "RemoteAdministrationOfExchange_2_4_5_1");
	SettingsStructure.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SaaS/1.0/WS/RemoteAdministrationOfExchange_2_4_5_1");
	SettingsStructure.Insert("WSTimeout", 20);
	
	Return DataExchangeServer.GetWSProxyByConnectionParameters(SettingsStructure, ErrorMessageString);
EndFunction

// Returns True if this exchange plan is used to synchronize data in SaaS mode.
// 
// Parameters:
//  ExchangePlanName - String -  Exchange plan name (as it is set in Designer)
// 
// Returns:
//  Boolean 
//
Function IsDataSynchronizationExchangePlan(Val ExchangePlanName) Export
	
	Return DataSynchronizationExchangePlans().Find(ExchangePlanName) <> Undefined;
	
EndFunction

#EndRegion
