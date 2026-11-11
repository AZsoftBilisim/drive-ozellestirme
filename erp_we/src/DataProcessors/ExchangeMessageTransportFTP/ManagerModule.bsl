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
	
	LongDesc = NStr("vi = 'Để kết nối, cần chỉ ra một thư mục nằm trên server FTP mà được phép truy cập từ các ứng dụng trao đổi.';
					|ru = 'Для подключения необходимо указать каталог, расположенный на FTP-сервере, доступном из обменивающихся приложений.';
					|en = 'Connection requires an FTP directory available for exchanging applications.'; fa = 'Connection requires an FTP directory available for exchanging applications.';
					|it = 'Для подключения необходимо указать каталог, расположенный на FTP-сервере, доступном из обменивающихся приложений.';
					|pl = 'Connection requires an FTP directory available for exchanging applications.';
					|tr = 'Bağlanmak için, FTP sunucusunda bulunan ve alışveriş yapılan uygulamalardan erişilebilen bir dizin belirtmeniz gerekir.'");
	
	Parameters = ExchangeMessagesTransport.StructureOfTransportParameters();
	
	Parameters.Alias = NStr("vi = 'server FTP';
							|ru = 'FTP-сервер';
							|en = 'FTP server'; fa = 'FTP server';
							|it = 'FTP-сервер';
							|pl = 'FTP server';
							|tr = 'FTP-sunucu'");
	Parameters.TransportID = "FTP";
	Parameters.LongDesc = LongDesc;
	Parameters.Picture = PictureLib.TransportFTP;
	
	Attributes = New Array;
	Attributes.Add("ArchivePasswordExchangeMessages");
	Attributes.Add("Password");
	
	Parameters.AttributesForSecureStorage = Attributes;
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionSettingsInXML(ConnectionSettings) Export
	
	Return ExchangeMessagesTransport.ConnectionSettingsInXML_1_2(ConnectionSettings);
	
EndFunction

Function ConnectionSettingsFromXML(XMLText) Export
	
	Return ExchangeMessagesTransport.ConnectionSettingsFromXML_1_2(XMLText, "FTP");
	
EndFunction

Function TransportSettingsINJSON(TransportSettings) Export
		
	JSONTransportSettings = New Structure;
			
	ArchivePasswordExchangeMessages = Common.ReadDataFromSecureStorage(TransportSettings.ArchivePasswordExchangeMessages);
	Password = Common.ReadDataFromSecureStorage(TransportSettings.Password);
	
	JSONTransportSettings.Insert("CompressOutgoingMessageFile", TransportSettings.CompressOutgoingMessageFile);
	JSONTransportSettings.Insert("MaxMessageSize", TransportSettings.MaxMessageSize);
	JSONTransportSettings.Insert("Password", Password);
	JSONTransportSettings.Insert("PassiveConnection", TransportSettings.PassiveConnection);
	JSONTransportSettings.Insert("User", TransportSettings.User);
	JSONTransportSettings.Insert("Port", TransportSettings.Port);
	JSONTransportSettings.Insert("Path", TransportSettings.Path);
	JSONTransportSettings.Insert("ArchivePasswordExchangeMessages", ArchivePasswordExchangeMessages);
	JSONTransportSettings.Insert("TransliterateExchangeMessageFileNames", TransportSettings.Transliteration);
		
	Return JSONTransportSettings;
	
EndFunction

Function TransportSettingsFromJSON(JSONTransportSettings) Export
	
	TransportSettings = New Structure;
	
	TransportSettings.Insert("CompressOutgoingMessageFile", JSONTransportSettings.CompressOutgoingMessageFile);
	TransportSettings.Insert("MaxMessageSize", JSONTransportSettings.MaxMessageSize);
	TransportSettings.Insert("Password", JSONTransportSettings.Password);
	TransportSettings.Insert("PassiveConnection", JSONTransportSettings.PassiveConnection);
	TransportSettings.Insert("User", JSONTransportSettings.User);
	TransportSettings.Insert("Port", JSONTransportSettings.Port);
	TransportSettings.Insert("Path", JSONTransportSettings.Path);
	TransportSettings.Insert("ArchivePasswordExchangeMessages", JSONTransportSettings.ArchivePasswordExchangeMessages);
	TransportSettings.Insert("Transliteration", JSONTransportSettings.TransliterateExchangeMessageFileNames);

	Return TransportSettings;
	
EndFunction

Function NameOfFolderWhereSettingsAreSaved(ConnectionSettings) Export
	
	Return "";
	
EndFunction

#EndRegion
	
#EndIf