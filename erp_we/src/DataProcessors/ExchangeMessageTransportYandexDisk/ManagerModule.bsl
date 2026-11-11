///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// See DataProcessorManager.ExchangeMessageTransportFILE.TransportParameters
Function TransportParameters() Export
	
	LongDesc = NStr("vi = 'Để kết nối, cần tham số đăng nhập trên dịch vụ đám mây.';
					|ru = 'Для подключения необходимо параметры авторизации на облачном сервисе.';
					|en = 'Connection requires authentication parameters for the cloud service.'; fa = 'Connection requires authentication parameters for the cloud service.';
					|it = 'Для подключения необходимо параметры авторизации на облачном сервисе.';
					|pl = 'Connection requires authentication parameters for the cloud service.';
					|tr = 'Bağlanmak için bulut hizmetinde yetkilendirme parametrelerine ihtiyacınız vardır.'");
	
	Parameters = ExchangeMessagesTransport.StructureOfTransportParameters();
	
	Parameters.Alias = NStr("vi = 'Yandex.Disk';
							|ru = 'Яндекс.Диск';
							|en = 'Yandex.Disk'; fa = 'Yandex.Disk';
							|it = 'Яндекс.Диск';
							|pl = 'Yandex.Disk';
							|tr = 'Yandex.Disk'");
	Parameters.TransportID = "YandexDisk";
	Parameters.LongDesc = LongDesc;
	Parameters.Picture = PictureLib.YandexDisk;
	
	Attributes = New Array;
	Attributes.Add("ArchivePasswordExchangeMessages");
	
	Parameters.AttributesForSecureStorage = Attributes;
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionSettingsInXML(ConnectionSettings) Export
	
	Return "";
	
EndFunction

Function ConnectionSettingsFromXML(XMLText) Export
	
	Settings = New Structure;
	Return Settings;
	
EndFunction

Function TransportSettingsINJSON(TransportSettings) Export
		
	JSONTransportSettings = New Structure;
		
	ArchivePasswordExchangeMessages = Common.ReadDataFromSecureStorage(TransportSettings.ArchivePasswordExchangeMessages);
	
	JSONTransportSettings.Insert("CompressOutgoingMessageFile", TransportSettings.CompressOutgoingMessageFile);
	JSONTransportSettings.Insert("ArchivePasswordExchangeMessages", ArchivePasswordExchangeMessages);
	JSONTransportSettings.Insert("TransliterateExchangeMessageFileNames", TransportSettings.Transliteration);
	
	// Yandex.Disk
	JSONTransportSettings.Insert("AccessToken", TransportSettings.AccessToken);
	JSONTransportSettings.Insert("ClientID", TransportSettings.ClientID);
	JSONTransportSettings.Insert("ClientSecret", TransportSettings.ClientSecret);
	JSONTransportSettings.Insert("ExpiresIn", TransportSettings.ExpiresIn);
	JSONTransportSettings.Insert("RefreshToken", TransportSettings.RefreshToken);
	JSONTransportSettings.Insert("CloudDirectory", TransportSettings.CloudDirectory);
	
	Return JSONTransportSettings;
	
EndFunction

Function TransportSettingsFromJSON(JSONTransportSettings) Export
	
	TransportSettings = New Structure;
	
	TransportSettings.Insert("CompressOutgoingMessageFile", JSONTransportSettings.CompressOutgoingMessageFile);
	TransportSettings.Insert("ArchivePasswordExchangeMessages", JSONTransportSettings.ArchivePasswordExchangeMessages);
	TransportSettings.Insert("Transliteration", JSONTransportSettings.TransliterateExchangeMessageFileNames);
	
	// Yandex
	TransportSettings.Insert("AccessToken", JSONTransportSettings.AccessToken);
	TransportSettings.Insert("ClientID", JSONTransportSettings.ClientID);
	TransportSettings.Insert("ClientSecret", JSONTransportSettings.ClientSecret);
	TransportSettings.Insert("ExpiresIn", JSONTransportSettings.ExpiresIn);
	TransportSettings.Insert("RefreshToken", JSONTransportSettings.RefreshToken);
	TransportSettings.Insert("CloudDirectory", JSONTransportSettings.CloudDirectory);
		
	Return TransportSettings;
	
EndFunction

Function NameOfFolderWhereSettingsAreSaved(ConnectionSettings) Export
	
	Return "";
	
EndFunction

#EndRegion
	
#EndIf