///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Verify that the form is opened with the required parameters
	If Not Parameters.Property("ExchangePlanName") Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'", Common.DefaultLanguageCode());
		
	EndIf;
	
	ExchangePlanName     = Parameters.ExchangePlanName;
	
	ExchangePlanSynonym = Metadata.ExchangePlans[ExchangePlanName].Synonym;
	
	ObjectsConversionRules = Enums.DataExchangeRulesTypes.ObjectsConversionRules;
	ObjectsRegistrationRules = Enums.DataExchangeRulesTypes.ObjectsRegistrationRules;
	
	WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Error,,,
		Parameters.DetailErrorDescription);
		
	Items.ErrorMessageText.Title = StringFunctions.FormattedString(
		StringFunctionsClientServer.SubstituteParametersToString(Items.ErrorMessageText.Title,
			ExchangePlanSynonym,
			Parameters.BriefErrorDescription));
	
	RulesFromFile = InformationRegisters.DataExchangeRules.RulesFromFileUsed(ExchangePlanName, True);
	
	If RulesFromFile.ConversionRules And RulesFromFile.RecordRules Then
		RulesType = NStr("vi = 'chuyển đổi và ghi nhận';
						|ru = 'конвертации и регистрации';
						|en = 'conversions and registrations'; fa = 'conversions and registrations';
						|it = 'Conversione e registrazione';
						|pl = 'konwersja i rejestracja';
						|tr = 'dönüştürmeler ve kayıtlar'");
	ElsIf RulesFromFile.ConversionRules Then
		RulesType = NStr("vi = 'chuyển đổi';
						|ru = 'конвертации';
						|en = 'conversions'; fa = 'conversions';
						|it = 'Conversione';
						|pl = 'konwersje';
						|tr = 'dönüştürme'");
	ElsIf RulesFromFile.RecordRules Then
		RulesType = NStr("vi = 'ghi nhận';
						|ru = 'регистрации';
						|en = 'registrations'; fa = 'registrations';
						|it = 'Registrazione';
						|pl = 'rejestracje';
						|tr = 'kayıt'");
	EndIf;
	
	Items.RulesTextFromFile.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.RulesTextFromFile.Title, ExchangePlanSynonym, RulesType);
	
	UpdateStartTime = Parameters.UpdateStartTime;
	If Parameters.UpdateEndTime = Undefined Then
		UpdateEndTime = CurrentSessionDate();
	Else
		UpdateEndTime = Parameters.UpdateEndTime;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExitApplication(Command)
	Close(True);
EndProcedure

&AtClient
Procedure GoToEventLog(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("StartDate", UpdateStartTime);
	FormParameters.Insert("EndDate", UpdateEndTime);
	FormParameters.Insert("ShouldNotRunInBackground", True);
	EventLogClient.OpenEventLog(FormParameters);
	
EndProcedure

&AtClient
Procedure Restart(Command)
	Close(False);
EndProcedure

&AtClient
Procedure ImportRulesSet(Command)
	
	DataExchangeClient.ImportDataSyncRules(ExchangePlanName);
	
EndProcedure

#EndRegion