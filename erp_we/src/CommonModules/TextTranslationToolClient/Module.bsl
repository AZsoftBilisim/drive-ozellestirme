///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Procedure GoToSettings(Owner, CompletionHandler, IsContextCall = False) Export
	
	Parameters = New Structure;
	Parameters.Insert("IsContextCall", IsContextCall);
	
	OpenForm("CommonForm.TextTranslationSetting", Parameters, Owner, , , , CompletionHandler);
	
EndProcedure

Procedure CheckSettings(Form, CompletionHandler) Export
	
	CallbackDescription = New CallbackDescription("OnCompleteSetup", ThisObject, CompletionHandler);

	If TextTranslationToolServerCall.ConfigurationIsRequired() Then
		GoToSettings(Form, CallbackDescription, True);
		Return;
	EndIf;
	
	OnCompleteSetup(True, CompletionHandler);
	
EndProcedure

Procedure TranslateSpreadsheetTexts(SpreadsheetDocument, TranslationLanguage, SourceLanguage, Form, CompletionHandler) Export
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SpreadsheetDocument", SpreadsheetDocument);
	AdditionalParameters.Insert("TranslationLanguage", TranslationLanguage);
	AdditionalParameters.Insert("SourceLanguage", SourceLanguage);
	AdditionalParameters.Insert("CompletionHandler", CompletionHandler);
	
	CallbackDescription = New CallbackDescription("OnCompleteSettingsCheck", ThisObject, AdditionalParameters);
	CheckSettings(Form, CallbackDescription);
	
EndProcedure

#EndRegion

#Region Private

Procedure OnCompleteSetup(Result, CompletionHandler) Export
	
	SetupExecuted = ValueIsFilled(Result);
	RunCallback(CompletionHandler, SetupExecuted);
	
EndProcedure

Procedure OnCompleteSettingsCheck(SetupExecuted, AdditionalParameters) Export
	
	If Not SetupExecuted Then
		Return;
	EndIf;
	
	SpreadsheetDocument = AdditionalParameters.SpreadsheetDocument;
	TranslationLanguage = AdditionalParameters.TranslationLanguage;
	SourceLanguage = AdditionalParameters.SourceLanguage;
	CompletionHandler = AdditionalParameters.CompletionHandler;
	
	TextTranslationToolServerCall.TranslateSpreadsheetTexts(SpreadsheetDocument, TranslationLanguage, SourceLanguage);
	RunCallback(CompletionHandler, SpreadsheetDocument);
	
EndProcedure

#EndRegion
