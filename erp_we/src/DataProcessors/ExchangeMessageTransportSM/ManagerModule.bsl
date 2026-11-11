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
	
	LongDesc = NStr("vi = 'Trao đổi qua chương trình quản lý trong dịch vụ (Bộ quản lý dịch vụ).';
					|ru = 'Обмен через управляющую программу в сервисе (Менеджер сервиса).';
					|en = 'Exchange via managing application (service manager).'; fa = 'Exchange via managing application (service manager).';
					|it = 'Обмен через управляющую программу в сервисе (Менеджер сервиса).';
					|pl = 'Exchange via managing application (service manager).';
					|tr = 'Yönetici program üzerinden değişim (servis yöneticisi).'");
	
	Parameters = ExchangeMessagesTransport.StructureOfTransportParameters();
	
	Parameters.Alias = NStr("vi = 'Trao đổi với ứng dụng trong dịch vụ';
							|ru = 'Обмен с приложением в сервисе';
							|en = 'Exchange with service application'; fa = 'Exchange with service application';
							|it = 'Обмен с приложением в сервисе';
							|pl = 'Exchange with service application';
							|tr = 'Hizmetteki bir uygulamayla alışveriş'");
	Parameters.TransportID = "SM";
	Parameters.LongDesc = LongDesc;
	Parameters.NameOfFirstSetupForm = "FirstSettingForm";
	Parameters.StartDataExchangeFromCorrespondent = True;
	Parameters.UseProgress = False;
	Parameters.ApplicationOperationMode = 1;
	Parameters.DirectConnection = True;
	Parameters.SaveConnectionParametersToFile = False;
	Parameters.Picture = PictureLib.TransportFresh;
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionSettingsInXML(ConnectionSettings) Export
	
	NodeAttributes = Common.ObjectAttributesValues(
		ConnectionSettings.InfobaseNode, "Code,ReceivedNo,SentNo");
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();
	
	XMLWriter.WriteStartElement("ПараметрыНастройки"); // @Non-NLS
	XMLWriter.WriteAttribute("ВерсияФормата", ExchangeMessagesTransport.VersionOfXMLDataExchangeSettingsFormat()); // @Non-NLS 
	
	XMLWriter.WriteNamespaceMapping("xsd", "http://www.w3.org/2001/XMLSchema");
	XMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
	XMLWriter.WriteNamespaceMapping("v8",  "http://v8.1c.ru/data");
	
	// Connection parameters
	XMLWriter.WriteStartElement("ОсновныеПараметрыОбмена"); // @Non-NLS

	ExchangePlanName = DataExchangeFormatTranslationCached.BroadcastName(ConnectionSettings.ExchangePlanName, "ru");
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, ExchangePlanName, "ИмяПланаОбмена"); // @Non-NLS
	
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, ConnectionSettings.ThisInfobaseDescription,   "НаименованиеВторойБазы"); // @Non-NLS
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, ConnectionSettings.SecondInfobaseDescription, "НаименованиеЭтойБазы"); // @Non-NLS
	
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, ConnectionSettings.NodeCode, "КодНовогоУзлаВторойБазы"); // @Non-NLS
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, ConnectionSettings.DestinationInfobasePrefix, "ПрефиксИнформационнойБазыИсточника"); // @Non-NLS
	
	// Exchange message transport settings
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, Undefined, "ВидТранспортаСообщенийОбмена"); // @Non-NLS
	
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, "", "ArchivePasswordExchangeMessages"); // @Non-NLS
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, False, "ТранслитерацияИмениФайловСообщенийОбмена"); // @Non-NLS
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, "", "FILEDataExchangeDirectory"); // @Non-NLS
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, False, "FILEСжиматьФайлИсходящегоСообщения"); // @Non-NLS
	
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, False, "ИспользоватьПараметрыТранспортаEMAIL"); // @Non-NLS
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, True, "ИспользоватьПараметрыТранспортаFILE"); // @Non-NLS
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, False, "ИспользоватьПараметрыТранспортаFTP"); // @Non-NLS
	
	// Supporting the exchange settings file of the 1.0 version format.
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, ConnectionSettings.ThisInfobaseDescription, "НаименованиеНастройкиВыполненияОбмена"); // @Non-NLS
	
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, ConnectionSettings.NodeCode, "КодНовогоУзла"); // @Non-NLS
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, NodeAttributes.Code, "КодПредопределенногоУзла"); // @Non-NLS
	
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, NodeAttributes.SentNo, "НомерОтправленного"); // @Non-NLS
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, NodeAttributes.ReceivedNo, "НомерПринятого"); // @Non-NLS
	
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, ConnectionSettings.WSCorrespondentEndpoint, "WSКонечнаяТочкаКорреспондента"); // @Non-NLS
	ExchangeMessagesTransport.AddXMLRecord(XMLWriter, ConnectionSettings.WSPeerDataArea, "WSОбластьДанныхКорреспондента"); // @Non-NLS

	XMLWriter.WriteEndElement(); // MainExchangeParameters
	
	If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
		ExchangeMessagesTransport.WriteXDTOExchangeParameters(XMLWriter, ConnectionSettings.ExchangePlanName);
	EndIf;
	
	XMLWriter.WriteEndElement(); // SetupParameters

	Return XMLWriter.Close();
	
EndFunction

Function ConnectionSettingsFromXML(XMLText) Export
			
	Settings = New Structure;

	XMLReader = New XMLReader;
	XMLReader.SetString(XMLText);

	Factory = XDTOFactory.ReadXML(XMLReader);
		
	If Factory.Properties().Get("MainExchangeParameters") <> Undefined Then
		
		MainParameters = New Structure;
		MainParametersOfXDTO = Factory["ОсновныеПараметрыОбмена"]; // @Non-NLS
		For Each Property In MainParametersOfXDTO.Properties() Do
			MainParameters.Insert(Property.Name, MainParametersOfXDTO[Property.Name]); 
		EndDo;
		
		Settings.Insert("ExchangePlanName", MainParameters["ИмяПланаОбмена"]); // @Non-NLS-2
		Settings.Insert("SecondInfobaseDescription", MainParameters["НаименованиеВторойБазы"]); // @Non-NLS-2
		Settings.Insert("ThisInfobaseDescription", MainParameters["НаименованиеЭтойБазы"]); // @Non-NLS-2
		Settings.Insert("SecondInfobaseNewNodeCode", MainParameters["КодНовогоУзлаВторойБазы"]); // @Non-NLS-2
		Settings.Insert("SourceInfobasePrefix", MainParameters["ПрефиксИнформационнойБазыИсточника"]); // @Non-NLS-2
		
		Settings.Insert("DataExchangeExecutionSettingsDescription", MainParameters["НаименованиеНастройкиВыполненияОбмена"]); // @Non-NLS-2
		Settings.Insert("NewNodeCode", MainParameters["КодНовогоУзла"]); // @Non-NLS-2
		Settings.Insert("PredefinedNodeCode", MainParameters["КодПредопределенногоУзла"]); // @Non-NLS-2
		Settings.Insert("TransportID", "SM");
		
		ExchangeMessagesTransport.CopyStructureValue(MainParameters, "НомерОтправленного", Settings, "SentNo"); // @Non-NLS-1
		ExchangeMessagesTransport.CopyStructureValue(MainParameters, "НомерПринятого", Settings, "ReceivedNo"); // @Non-NLS-1
		
	EndIf;
	
	If Factory.Properties().Get("XDTOExchangeParameters") <> Undefined Then
		
		ExchangeParameters = New Structure;
		XDTOExchangeParameters = Factory["XDTOExchangeParameters"];
		For Each Property In XDTOExchangeParameters.Properties() Do
			ExchangeParameters.Insert(Property.Name, XDTOExchangeParameters[Property.Name]); 
		EndDo;
		
		Settings.Insert("ExchangeFormat", XDTOExchangeParameters["ФорматОбмена"]); // @Non-NLS-2
		
	EndIf;
		
	Return Settings;
	
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