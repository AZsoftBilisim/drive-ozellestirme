///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// See UsersInternalSaaS.GetUserFormProcessing
Procedure GetUserFormProcessing(Source, FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing) Export
	
	UsersInternalSaaS.GetUserFormProcessing(
		Source,
		FormType,
		Parameters,
		SelectedForm,
		AdditionalInformation,
		StandardProcessing);
	
EndProcedure

Procedure WriteTheErrorToTheLog(ErrorText) Export
	
	WriteLogEvent(
		NStr("vi = 'Lỗi thực hiện';
			|ru = 'Ошибка выполнения';
			|en = 'Runtime error'; fa = 'خطای زمان اجرا';
			|it = 'Errore nell''esecuzione';
			|pl = 'Błąd wykonania';
			|tr = 'Uygulama hatası'", Common.DefaultLanguageCode()),
		EventLogLevel.Error,,, ErrorText);
	
EndProcedure

#EndRegion