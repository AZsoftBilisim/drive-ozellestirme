///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If Not DataExchangeServerCall.SUBAssetIsIncludedInDSLExchangePlans(CommandParameter) Then
		
		Text = NStr("vi = 'Lệnh không được dùng cho kiểu nút này';
					|ru = 'Команда не предназначена для данного типа узлов';
					|en = 'The command is not intended for this node type'; fa = 'The command is not intended for this node type';
					|it = 'Команда не предназначена для данного типа узлов';
					|pl = 'The command is not intended for this node type';
					|tr = 'Komut bu tür düğümlere yönelik değildir'",
			CommonClient.DefaultLanguageCode());
		ShowMessageBox(, Text);
		
		Return;
	
	EndIf;
	
	If Not ValueIsFilled(ExchangeMessageTransportServerCall.DefaultTransport(CommandParameter)) Then
		
		Text = NStr("vi = 'Đối với nút, chưa ấn định kiểu truyền mặc định';
					|ru = 'Для узла не назначен тип транспорта по умолчанию';
					|en = 'No default transport type is specified for this node'; fa = 'No default transport type is specified for this node';
					|it = 'Для узла не назначен тип транспорта по умолчанию';
					|pl = 'No default transport type is specified for this node';
					|tr = 'Düğüme atanmış varsayılan bir aktarım türü yok'",
			CommonClient.DefaultLanguageCode());
		ShowMessageBox(, Text);
		
		Return;
		
	EndIf;
	
	If TypeOfTransportUsedIsSM(CommandParameter) Then
		
		Text = NStr("vi = 'Đối với dạng truyền này, không đề xuất lưu cài đặt vào tệp.';
					|ru = 'Для этого вида транспорта не предполагается сохранение настроек в файл.';
					|en = 'Saving settings to a file is not supported for this transport type.'; fa = 'Saving settings to a file is not supported for this transport type.';
					|it = 'Saving settings to a file is not supported for this transport type.';
					|pl = 'Saving settings to a file is not supported for this transport type.';
					|tr = 'Bu taşıma modu için bir dosyaya ayarların kaydedilmesi amaçlanmamaktadır.'",
			CommonClient.DefaultLanguageCode());
		
		ShowMessageBox(, Text);
		
		Return;
		
	EndIf;
		
	Cancel = False;
	
	AddressOfXMLConnectionSettings = "";
	AddressOfJSONConnectionSettings = "";
	
	GetSecondInfobaseDataExchangeSettingsAtServer(Cancel, 
		CommandParameter, AddressOfXMLConnectionSettings, AddressOfJSONConnectionSettings);
	
	If Cancel Then
		
		ShowMessageBox(, NStr("vi = 'Đã xảy ra lỗi khi nhận tùy chỉnh trao đổi dữ liệu.';
								|ru = 'Возникли ошибки при получении настроек обмена данными.';
								|en = 'Cannot get data exchange settings.'; fa = 'Cannot get data exchange settings.';
								|it = 'Si sono verificati degli errori durante il recupero delle impostazioni di scambio dei dati.';
								|pl = 'Podczas pobierania ustawień wymiany danych zaistniały błędy.';
								|tr = 'Veri alışverişi ayarları alınırken hatalar oluştu.'"));
		Return;
		
	EndIf;
	
	FilesToObtain = New Array;
	
	If ValueIsFilled(AddressOfXMLConnectionSettings) Then
		
		FileName = NStr("vi = 'Tùy chỉnh kết nối';
						|ru = 'Настройки подключения';
						|en = 'Connection settings'; fa = 'تنظیمات اتصال';
						|it = 'Impostazioni di connessione';
						|pl = 'Ustawienia podłączenia';
						|tr = 'Bağlantı ayarları'", CommonClient.DefaultLanguageCode()) + ".xml";
		FilesToObtain.Add(New TransferableFileDescription(FileName, AddressOfXMLConnectionSettings));
		
	EndIf;
	
	If ValueIsFilled(AddressOfJSONConnectionSettings) Then
		
		FileName = NStr("vi = 'Tùy chỉnh kết nối';
						|ru = 'Настройки подключения';
						|en = 'Connection settings'; fa = 'تنظیمات اتصال';
						|it = 'Impostazioni di connessione';
						|pl = 'Ustawienia podłączenia';
						|tr = 'Bağlantı ayarları'", CommonClient.DefaultLanguageCode()) + ".json";
		FilesToObtain.Add(New TransferableFileDescription(FileName, AddressOfJSONConnectionSettings));
		
	EndIf;
	
	If FilesToObtain.Count() > 0 Then
		
		Notification = New CallbackDescription("SaveConnectionSettingsFilesCompletion", ThisObject);
		
		SavingParameters = FileSystemClient.FilesSavingParameters();
		SavingParameters.Interactively = True;
			
		FileSystemClient.SaveFiles(Notification, FilesToObtain, SavingParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GetSecondInfobaseDataExchangeSettingsAtServer(Cancel,
	InfobaseNode, AddressOfXMLConnectionSettings, AddressOfJSONConnectionSettings)
	
	DataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard().Create();
	DataExchangeCreationWizard.Initialize(InfobaseNode);
	
	XMLConnectionSettingsString = ExchangeMessagesTransport.ConnectionSettingsInXML(DataExchangeCreationWizard);
	
	If ValueIsFilled(XMLConnectionSettingsString) Then
		
		TempFileName = GetTempFileName();
		
		Record = New TextWriter;
		Record.Open(TempFileName, "UTF-8");
		Record.Write(XMLConnectionSettingsString);
		Record.Close();
		
		AddressOfXMLConnectionSettings = PutToTempStorage(
			New BinaryData(TempFileName));
		
		DeleteFiles(TempFileName);
		
	EndIf;
	
	JSONConnectionSettingsString = ExchangeMessagesTransport.ConnectionSettingsINJSON(DataExchangeCreationWizard);
	
	If ValueIsFilled(JSONConnectionSettingsString) Then
		
		TempFileName = GetTempFileName();
		
		Record = New TextWriter;
		Record.Open(TempFileName, "UTF-8");
		Record.Write(JSONConnectionSettingsString);
		Record.Close();
		
		AddressOfJSONConnectionSettings = PutToTempStorage(
			New BinaryData(TempFileName));
		
		DeleteFiles(TempFileName);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveConnectionSettingsFilesCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf; 
	
	MessageText = NStr("vi = 'Đã lưu tùy chỉnh kết nối';
						|ru = 'Настройки подключения сохранены';
						|en = 'Connection settings saved'; fa = 'Connection settings saved';
						|it = 'Настройки подключения сохранены';
						|pl = 'Connection settings saved';
						|tr = 'Bağlantı ayarları kaydedildi'", CommonClient.DefaultLanguageCode());
	CommonClient.MessageToUser(MessageText);
	
EndProcedure

&AtServer
Function TypeOfTransportUsedIsSM(Val ExchangeNode)
	
	If Common.SubsystemExists("StandardSubsystems.DataExchange.ExchangeMessagesTransport") Then
	
		ModuleMessageExchangeTransport = Common.CommonModule("ExchangeMessagesTransport");
	
		SMManagerModule = ModuleMessageExchangeTransport.TransportManagerSM();
	
		TransportID = ModuleMessageExchangeTransport.DefaultTransport(ExchangeNode);
		TransportParameters = SMManagerModule.TransportParameters();
	
		Return TransportID = TransportParameters.TransportID;
	
	Else
	
		Return False;

	EndIf;
	
EndFunction

#EndRegion
