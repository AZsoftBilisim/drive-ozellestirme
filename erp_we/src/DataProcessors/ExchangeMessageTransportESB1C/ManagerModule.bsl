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

// Transport parameters. Returns the transport parameters
// 
// Returns:
//  Structure - See ExchangeMessagesTransport.StructureOfTransportParameters 
Function TransportParameters() Export
	
	LongDesc = NStr("vi = 'Để kết nối, cần chỉ ra dữ liệu để kết nối đến ESB.';
					|ru = 'Для подключения необходимо указать данные для подключения к шине.';
					|en = 'Connection required bus connection details.'; fa = 'Connection required bus connection details.';
					|it = 'Для подключения необходимо указать данные для подключения к шине.';
					|pl = 'Connection required bus connection details.';
					|tr = 'Bağlanmak için veri yoluna bağlanma verilerini belirtmeniz gerekir.'");
	
	Parameters = ExchangeMessagesTransport.StructureOfTransportParameters();
	
	Parameters.Alias = NStr("vi = '1C:ESB';
							|ru = '1С:Шина';
							|en = '1C:Bus'; fa = '1C:Bus';
							|it = '1С:Шина';
							|pl = '1C:Bus';
							|tr = '1C:Bus'");
	Parameters.TransportID = "ESB1C";
	Parameters.LongDesc = LongDesc;

	Parameters.Picture = PictureLib.TransportESB1C;
		
	Return Parameters;
	
EndFunction

// Saves the exchange message to the "DataExchangeMessages" information register to later import during synchronization
// 
// Parameters:
//  Message - IntegrationServiceMessage
//  Cancel - Boolean
//
Procedure PutMessageInVault(Message, Cancel) Export
	
	Try
	
		TempFileName = GetTempFileName("xml");
		
		Stream = FileStreams.Open(TempFileName, FileOpenMode.OpenOrCreate, FileAccess.Write);
		
		Body = Message.GetBodyAsStream();
		Body.CopyTo(Stream);
		Stream.Flush();
		
		Body.Close();
		Stream.Close();
		
		// Save to the storage
		StorageFolder = DataExchangeServer.TempFilesStorageDirectory();
		FileNameInRepository = FileName(Message.SenderCode);
		FullNameOfFileInRepository = CommonClientServer.GetFullFileName(StorageFolder, FileNameInRepository);
	
		MoveFile(TempFileName, FullNameOfFileInRepository);
		
		DataExchangeServer.PutFileInStorage(FullNameOfFileInRepository, FileNameInRepository);
	
	Except
		
		Cancel = True;
		
		EventLogMessageKey = NStr("vi = 'Truyền thông điệp trao đổi';
									|ru = 'Транспорт сообщений обмена';
									|en = 'Exchange message transport'; fa = 'انتقال پیام تبادل';
									|it = 'Trasporto dei messaggi di scambio';
									|pl = 'Exchange message transport';
									|tr = 'Değişim ileti aktarımı'", Common.DefaultLanguageCode());
		DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(EventLogMessageKey, 
			EventLogLevel.Error,,,DetailErrorDescription);
	
	EndTry;
	
EndProcedure

// Returns the name (ID) that will be used to save the file to the temp storage (information register "DataExchangeMessages")
// 
// Parameters:
//  SenderCode - String - Sender code
// 
// Returns:
//  String - Filename
Function FileName(SenderCode) Export
	
	Template = "esb_1c_%1.xml";
	Return StrTemplate(Template, SenderCode);
	
EndFunction

#EndRegion

#Region Private

Function ConnectionSettingsInXML(ConnectionSettings) Export
	
	Return "";
	
EndFunction

Function ConnectionSettingsFromXML(XMLText) Export
	
	Return "";
	
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