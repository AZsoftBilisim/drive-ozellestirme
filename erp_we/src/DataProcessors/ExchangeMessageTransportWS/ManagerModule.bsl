///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// See DataProcessorManager.ExchangeMessageTransportFILE.TransportParameters
Function TransportParameters() Export
	
	LongDesc = NStr("vi = 'Để kết nối, cần chỉ ra tham số kết nối đến cơ sở trao đổi tin.';
					|ru = 'Для подключения необходимо указать параметры подключения к базе корреспонденту.';
					|en = 'Connection required peer connection details.'; fa = 'Connection required peer connection details.';
					|it = 'Для подключения необходимо указать параметры подключения к базе корреспонденту.';
					|pl = 'Connection required peer connection details.';
					|tr = 'Bağlanmak için, veri tabanına muhabirle bağlanmak için parametreleri belirtmeniz gerekir.'");
	
	Parameters = ExchangeMessagesTransport.StructureOfTransportParameters();
	
	Parameters.Alias = NStr("vi = 'Internet (dịch vụ web)';
							|ru = 'Интернет (веб-сервис)';
							|en = 'Internet (web service)'; fa = 'Internet (web service)';
							|it = 'Интернет (веб-сервис)';
							|pl = 'Internet (web service)';
							|tr = 'İnternet (web-servis)'");
	Parameters.TransportID = "WS";
	Parameters.LongDesc = LongDesc;
	Parameters.NameOfAuthenticationForm = "AuthenticationForm";
	Parameters.AttributesForSecureStorage.Add("Password");
	Parameters.DirectConnection = True;
	Parameters.ApplicationOperationMode = 1;
	Parameters.UseProgress = False;
	Parameters.SaveConnectionParametersToFile = False;
	Parameters.Picture = PictureLib.TransportWS;
		
	Return Parameters;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionSettingsInXML(ConnectionSettings) Export
	
	Return ExchangeMessagesTransport.ConnectionSettingsInXML_1_2(ConnectionSettings);
	
EndFunction

Function ConnectionSettingsFromXML(XMLText) Export
	
	Return ExchangeMessagesTransport.ConnectionSettingsFromXML_1_2(XMLText, "WS");
	
EndFunction

Function TransportSettingsINJSON(TransportSettings) Export
	
	Return New Structure;
	
EndFunction

Function TransportSettingsFromJSON(JSONTransportSettings) Export
	
	Return New Structure;
	
EndFunction

Function NameOfFolderWhereSettingsAreSaved(ConnectionSettings) Export
	
	Return "";
	
EndFunction

#EndRegion
	
#EndIf