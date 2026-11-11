///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns a language postfix followed by its index number. For example, "Language1".
// 
// Parameters:
//  LanguageSeqNumber - Number - Index of the language in the application.
// 
// Returns:
//  String - Language postfix followed by its index in the application.
//
Function LanguageSuffix(LanguageSeqNumber = Undefined) Export
	
	SuffixName = "Language";
	
	If LanguageSeqNumber = Undefined Then
		Return SuffixName;
	EndIf;
	
	Return SuffixName + Format(LanguageSeqNumber,"NG=0");
	
EndFunction

// The function is called when receiving an object presentation or a reference presentation depending on the language
// that is used when the user is working.
//
// Parameters:
//  Data               - Structure - contains the values of the fields from which presentation is being generated.
//  Presentation        - String - a generated presentation must be put in this parameter.
//  StandardProcessing - Boolean - a flag indicating whether the standard presentation is generated is passed to this parameter.
//  AttributeName         - String - indicates which attribute stores the presentation in the main language.
//
Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing, AttributeName = "Description") Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		
		If NationalLanguageSupportServer.IsMainLanguage() Then
			Return;
		EndIf;
		
		LanguageSuffix = NationalLanguageSupportServer.CurrentLanguageSuffix();
		If ValueIsFilled(LanguageSuffix) Then
	
			If Data.Property(AttributeName + LanguageSuffix) Then
				
				Presentation = Data[AttributeName + LanguageSuffix];
				If IsBlankString(Presentation) And Data.Property(AttributeName) Then
					Presentation = Data[AttributeName];
					If IsBlankString(Presentation) Then
						Return;
					EndIf;
				EndIf;
				
				StandardProcessing = False;
				Return;
				
			EndIf;
	
		EndIf;
			
		If Data.Property("Ref") Or Data.Ref <> Undefined Then
			If NationalLanguageSupportServer.ObjectContainsPMRepresentations(Data.Ref, AttributeName) Then
				QueryText = 
				"SELECT TOP 1
				|	&AttributeName AS Description
				|FROM
				|	&Presentations AS Presentations
				|WHERE
				|	Presentations.LanguageCode = &Language
				|	AND Presentations.Ref = &Ref";
				
				QueryText = StrReplace(QueryText, "&AttributeName", "Presentations." + AttributeName);
				QueryText = StrReplace(QueryText, "&Presentations", Data.Ref.Metadata().FullName() + ".Presentations");
				
				Query = New Query(QueryText);
				
				Query.SetParameter("Ref", Data.Ref);
				Query.SetParameter("Language",   CurrentLanguage().LanguageCode);
				
				QueryResult = Query.Execute();
				If Not QueryResult.IsEmpty() 
				   And Not IsBlankString(QueryResult.Unload()[0].Description) Then
					StandardProcessing = False;
					Presentation = QueryResult.Unload()[0].Description;
				EndIf;
			EndIf;
			
		EndIf;
		
#EndIf
	
EndProcedure

// Called to generate the composition of the fields from which the presentation of an object or a link is formed.
// The field composition is generated considering the current user language.
//
// Parameters:
//  Fields                 - Array - an array that contains names of fields that are required to generate a presentation of an object
//                                  or a reference.
//  StandardProcessing - Boolean - this parameter stores the flag of whether the standard(system) event processing is executed. If this parameter is
//                                  set to False in the processing procedure, standard processing
//                                  is skipped.
//  AttributeName         - String - indicates which attribute stores the presentation in the main language.
//
Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing, AttributeName = "Description") Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		
		If NationalLanguageSupportServer.IsMainLanguage() Then
			Return;
		EndIf;
		
		StandardProcessing = False;
		Fields.Add(AttributeName);
		Fields.Add("Ref");
		
		LanguagesInformationRecords = NationalLanguageSupportCached.InfoAboutLanguagesUsed();
		For Each IsAdditionalLanguageUsed In LanguagesInformationRecords Do
			If IsAdditionalLanguageUsed.Value Then
				Fields.Add(AttributeName + IsAdditionalLanguageUsed.Key);
			EndIf;
		EndDo;
	
#EndIf
	
EndProcedure

#EndRegion

