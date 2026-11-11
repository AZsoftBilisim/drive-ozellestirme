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
	
	LongDesc = NStr("vi = 'Với phương án kết nối như vậy, chương trình này sẽ gửi và nhận dữ liệu chỉ theo yêu cầu của chương trình-nơi trao đổi tin.';
					|ru = 'При таком варианте подключения эта программа отправляет и принимает данные только по запросу от программы-корреспондента.';
					|en = 'With the current connection settings, this application sends and receives data only upon request from the peer application.'; fa = 'With the current connection settings, this application sends and receives data only upon request from the peer application.';
					|it = 'При таком варианте подключения эта программа отправляет и принимает данные только по запросу от программы-корреспондента.';
					|pl = 'With the current connection settings, this application sends and receives data only upon request from the peer application.';
					|tr = 'Bu bağlantı seçeneği ile, bu uygulama sadece muhabir programdan talep üzerine İnternet üzerinden veri gönderir ve alır.'");
	
	Parameters = ExchangeMessagesTransport.StructureOfTransportParameters();
	
	Parameters.Alias = NStr("vi = 'Chế độ thụ động';
							|ru = 'Пассивный режим';
							|en = 'Passive mode'; fa = 'حالت غیرفعال';
							|it = 'Modalità passiva';
							|pl = 'Tryb pasywny';
							|tr = 'Pasif mod'");
	Parameters.TransportID = "PassiveMode";
	Parameters.LongDesc = LongDesc;
	Parameters.StartDataExchangeFromCorrespondent = False;
	Parameters.UseProgress = False;
	Parameters.ApplicationOperationMode = 1;
	Parameters.DirectConnection = False;
	Parameters.PassiveMode = True;
	Parameters.Picture = PictureLib.TransportPassiveMode;
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionSettingsInXML(ConnectionSettings) Export
	
	Return DataExchangeXDTOServer.ConnectionSettingsInExchangeMessage(ConnectionSettings);
	
EndFunction

Function ConnectionSettingsFromXML(XMLText) Export
	
	Return DataExchangeXDTOServer.ExchangeMessageInConnectionSettings(XMLText);
	
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