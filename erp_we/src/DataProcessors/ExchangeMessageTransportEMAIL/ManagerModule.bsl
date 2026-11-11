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
	
	LongDesc = NStr("vi = 'Để kết nối, cần chỉ ra tài khoản email.';
					|ru = 'Для подключения необходимо указать учетную запись электронной почты.';
					|en = 'Connection requires email address.'; fa = 'Connection requires email address.';
					|it = 'Для подключения необходимо указать учетную запись электронной почты.';
					|pl = 'Connection requires email address.';
					|tr = 'Bağlanmak için bir e-posta hesabı belirtmeniz gerekir.'");
	
	Parameters = ExchangeMessagesTransport.StructureOfTransportParameters();
	
	Parameters.Alias = NStr("vi = 'Email';
							|ru = 'Электронная почта';
							|en = 'Email'; fa = 'ایمیل';
							|it = 'Posta elettronica';
							|pl = 'Poczta elektroniczna';
							|tr = 'E-posta'");
	Parameters.TransportID = "EMAIL";
	Parameters.LongDesc = LongDesc;
	Parameters.AttributesForSecureStorage.Add("ArchivePasswordExchangeMessages");
	Parameters.SettingUpSubAssetInCorrespondent = True;
	Parameters.Picture = PictureLib.TransportEmail;
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionSettingsInXML(ConnectionSettings) Export
	
	Return ExchangeMessagesTransport.ConnectionSettingsInXML_1_2(ConnectionSettings);
	
EndFunction

Function ConnectionSettingsFromXML(XMLText) Export
	
	Return ExchangeMessagesTransport.ConnectionSettingsFromXML_1_2(XMLText, "EMAIL");
	
EndFunction

Function TransportSettingsINJSON(TransportSettings) Export
	
	JSONTransportSettings = New Structure;
	
	ArchivePasswordExchangeMessages = Common.ReadDataFromSecureStorage(TransportSettings.ArchivePasswordExchangeMessages);
	
	JSONTransportSettings.Insert("MaxMessageSize", TransportSettings.MaxMessageSize);
	JSONTransportSettings.Insert("CompressOutgoingMessageFile", TransportSettings.CompressOutgoingMessageFile);
	JSONTransportSettings.Insert("ArchivePasswordExchangeMessages", ArchivePasswordExchangeMessages);
	JSONTransportSettings.Insert("TransliterateExchangeMessageFileNames", TransportSettings.Transliteration);
	
	If ValueIsFilled(TransportSettings.Account) Then
		
		CatAccount = TransportSettings.Account;
		
		Account = New Structure;
		
		Account.Insert("Ref", String(CatAccount.UUID()));
		Account.Insert("Description", CatAccount.Description);
		Account.Insert("DeletionMark", CatAccount.DeletionMark);
		Account.Insert("PredefinedDataName", CatAccount.PredefinedDataName);
		
		Dictionary = DictionaryForAccount();
		Type = TypeOf(CatAccount);
		CatalogMetadata = Metadata.FindByType(Type);
		
		For Each Attribute In CatalogMetadata.Attributes Do
			
			Var_Key = Attribute.Name;
			If Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.Russian Then
				If Dictionary.Get(Var_Key) <> Undefined Then
					Var_Key = Dictionary.Get(Var_Key);
				EndIf;
			EndIf;
			
			Value = CatAccount[Attribute.Name];
			If TypeOf(Value) <> Type("Number")
				Or TypeOf(Value) <> Type("String")
				Or TypeOf(Value) <> Type("Date")
				Or TypeOf(Value) <> Type("Boolean") Then
				
				Value = String(Value);
				
			EndIf;
			
			Account.Insert(Var_Key, Value);
			
		EndDo;
		
		JSONTransportSettings.Insert("Account", Account);
		
		SMTPPassword = Common.ReadDataFromSecureStorage(TransportSettings.Account, "SMTPPassword");
		If ValueIsFilled(SMTPPassword) Then
			JSONTransportSettings.Insert("PasswordSMTP", SMTPPassword);
		EndIf;
		
	EndIf;
			
	Return JSONTransportSettings;
	
EndFunction

Function TransportSettingsFromJSON(JSONTransportSettings) Export
		
	TransportSettings = New Structure;
	TransportSettings.Insert("MaxMessageSize", JSONTransportSettings.MaxMessageSize);
	TransportSettings.Insert("CompressOutgoingMessageFile", JSONTransportSettings.CompressOutgoingMessageFile);
	TransportSettings.Insert("ArchivePasswordExchangeMessages", JSONTransportSettings.ArchivePasswordExchangeMessages);
	TransportSettings.Insert("Transliteration", JSONTransportSettings.TransliterateExchangeMessageFileNames);
	
	StructureOfAccount = New Structure;
	StructureOfAccount.Insert("Description", JSONTransportSettings.Account.Description);
	StructureOfAccount.Insert("PredefinedDataName", JSONTransportSettings.Account.PredefinedDataName);
	
	Dictionary = DictionaryForAccount("ru");
	
	For Each KeyAndValue In JSONTransportSettings.Account Do
		
		Var_Key = KeyAndValue.Key;
		Value = KeyAndValue.Value;
		
		If Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.Russian Then
			If Dictionary.Get(Var_Key) <> Undefined Then
				Var_Key = Dictionary.Get(Var_Key);
			Else
				Continue;
			EndIf;
		EndIf;
		
		StructureOfAccount.Insert(Var_Key, Value);
		
	EndDo;
		
	CatalogName = "EmailAccounts";
	Manager = Common.ObjectManagerByFullName("Catalog." + CatalogName);
	EmailAccount = Manager.CreateItem();
	EmailAccount.Description = StructureOfAccount.Description;
	If StructureOfAccount.Property("PredefinedDataName") Then
		EmailAccount.PredefinedDataName = StructureOfAccount.PredefinedDataName;
	EndIf;
		
	For Each Attribute In Metadata.Catalogs[CatalogName].Attributes Do
		
		If Not StructureOfAccount.Property(Attribute.Name) Then
			Continue;
		EndIf;
		
		EmailAccount[Attribute.Name] = StructureOfAccount[Attribute.Name];
		
	EndDo;

	If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		
		ModuleEmailOperationsInternal = Common.CommonModule("EmailOperationsInternal");
		
		ThisInfobaseAccount = ModuleEmailOperationsInternal.ThisInfobaseAccountByCorrespondentAccountData(
			EmailAccount);
			
		TransportSettings.Insert("Account", ThisInfobaseAccount.Ref);
		
		SMTPPassword = "";
		If JSONTransportSettings.Property("PasswordSMTP", SMTPPassword) Then
			Common.WriteDataToSecureStorage(ThisInfobaseAccount.Ref, SMTPPassword);
			Common.WriteDataToSecureStorage(ThisInfobaseAccount.Ref, SMTPPassword, "SMTPPassword");
		EndIf;
		
	EndIf;
		
	Return TransportSettings;
	
EndFunction

Function DictionaryForAccount(DirectionOfTranslation = "en")
	
	Dictionary = New Map;
	
	Dictionary.Insert("Email", "Email");
	Dictionary.Insert("Timeout", "Timeout");
	Dictionary.Insert("UserName", "UserName");
	Dictionary.Insert("UseForSending", "UseForSending");
	Dictionary.Insert("UseForReceiving", "UseForReceiving");
	Dictionary.Insert("UseSecureConnectionForIncomingMail", "UseSecureConnectionForIncomingMail");
	Dictionary.Insert("UseSecureConnectionForOutgoingMail", "UseSecureConnectionForOutgoingMail");
	Dictionary.Insert("KeepMessageCopiesAtServer", "KeepMessageCopiesAtServer");
	Dictionary.Insert("KeepMailAtServerPeriod", "KeepMailAtServerPeriod");
	Dictionary.Insert("User", "User");
	Dictionary.Insert("SMTPUser", "SMTPUser");
	Dictionary.Insert("IncomingMailServerPort", "IncomingMailServerPort");
	Dictionary.Insert("OutgoingMailServerPort", "OutgoingMailServerPort");
	Dictionary.Insert("ProtocolForIncomingMail", "ProtocolForIncomingMail");
	Dictionary.Insert("IncomingMailServer", "IncomingMailServer");
	Dictionary.Insert("OutgoingMailServer", "OutgoingMailServer");
	Dictionary.Insert("SignInBeforeSendingRequired", "SignInBeforeSendingRequired");
	Dictionary.Insert("SendBCCToThisAddress", "SendBCCToThisAddress");
	Dictionary.Insert("AccountOwner", "AccountOwner");
	Dictionary.Insert("AuthorizationRequiredOnSendEmails", "AuthorizationRequiredOnSendEmails");
	Dictionary.Insert("EmailServiceAuthorization", "EmailServiceAuthorization");
	Dictionary.Insert("EmailServiceName", "EmailServiceName");
	
	If DirectionOfTranslation = "en" Then
		
		Return Dictionary;
		
	ElsIf DirectionOfTranslation = "ru" Then
		
		NewDictionary = New Map;
		For Each KeyAndValue In Dictionary Do
			NewDictionary.Insert(KeyAndValue.Value, KeyAndValue.Key);
		EndDo;
		
		Return NewDictionary;
		
	EndIf;
	
EndFunction

Function NameOfFolderWhereSettingsAreSaved(ConnectionSettings) Export
	
	Return "";
	
EndFunction

#EndRegion
	
#EndIf