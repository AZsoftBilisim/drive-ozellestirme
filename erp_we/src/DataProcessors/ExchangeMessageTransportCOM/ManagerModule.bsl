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
	
	LongDesc = NStr("vi = 'Phương án kết nối này được đề xuất trong trường hợp, nếu chương trình khác đặt tại máy tính này
		|và chương trình này hoặc cả hai chương trình cùng đặt trong một mạng lan (trong một văn phòng).';
		|ru = 'Данный вариант подключения рекомендуется в том случае, если другая программа находится на том же компьютере,
		|что и эта программа, или обе программы расположены в одной локальной сети (в одном офисе).';
		|en = 'This option is recommended if both applications are located
		|on the same computer or in the local network (in the same office).'; fa = 'This option is recommended if both applications are located
		|on the same computer or in the local network (in the same office).';
		|it = 'Questa opzione di connessione viene consigliata nel caso se tutti e due programmi si trovano sullo stesso computer
		|oppure nella stessa rete locale (nello stesso ufficio).';
		|pl = 'Dany wariant połączenia jest zalecany w tym przypadku, gdy inny program znajduje się na tym samym komputerze, 
		|co ten program lub oba programy znajdują się w jednej sieci lokalnej (w jednym biurze).';
		|tr = 'Bu bağlantı seçeneği, başka bir programın bu programla aynı bilgisayarda olması veya 
		|her iki programın da aynı yerel ağda (aynı ofiste) bulunması durumunda önerilir.'");
	
	Parameters = ExchangeMessagesTransport.StructureOfTransportParameters();
	
	Parameters.Alias = NStr("vi = 'Kết nối trực tiếp (kết nối com)';
							|ru = 'Прямое подключение (com-соединение)';
							|en = 'Direct COM connection'; fa = 'Direct COM connection';
							|it = 'Прямое подключение (com-соединение)';
							|pl = 'Direct COM connection';
							|tr = 'Doğrudan bağlantı (com-bağlantı)'");
	Parameters.TransportID = "COM";
	Parameters.LongDesc = LongDesc;
	Parameters.NameOfAuthenticationForm = "AuthenticationForm";
	Parameters.AttributesForSecureStorage.Add("UserPassword");
	Parameters.DirectConnection = True;
	Parameters.ApplicationOperationMode = 0;
	Parameters.UseProgress = False;
	Parameters.SaveConnectionParametersToFile = False;
	Parameters.Picture = PictureLib.TransportCOM;
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionSettingsInXML(ConnectionSettings) Export
	
	Return ExchangeMessagesTransport.ConnectionSettingsInXML_1_2(ConnectionSettings);
	
EndFunction

Function ConnectionSettingsFromXML(XMLText) Export
	
	Return ExchangeMessagesTransport.ConnectionSettingsFromXML_1_2(XMLText, "COM");
	
EndFunction

Function TransportSettingsINJSON(TransportSettings) Export
	
	Return "";
	
EndFunction

Function TransportSettingsFromJSON(JSONTransportSettings) Export
	
	Return "";
	
EndFunction

Function NameOfFolderWhereSettingsAreSaved(ConnectionSettings) Export
	
	Return "";
	
EndFunction

#EndRegion
	
#EndIf