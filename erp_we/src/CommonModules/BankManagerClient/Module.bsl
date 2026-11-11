///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Opens the choice form of the Bank codes catalog with filter by the passed bank code.
// If the choice list contains a single record, it is automatically selected in the form.
//
// Parameters:
//  BIC - String - Bank ID.
//  Form - ClientApplicationForm - a form that opens the choice form.
//  HandlerNotifications - CallbackDescription - the procedure to which the management is passed after the selection.
//                                              If the parameter is not specified, the standard choice handler will be called.
//    Procedure parameters:
//     * BIC - CatalogRef.BankClassifier - a selected item.
//     * AdditionalParameters - Arbitrary - the parameter passed in the notification details constructor.
// 
Procedure SelectFromTheBICDirectory(BIC, Form, HandlerNotifications = Undefined) Export
	
	Parameters = New Structure;
	Parameters.Insert("BIC", BIC);
	OpenForm("Catalog.BankClassifier.ChoiceForm", Parameters, Form, , , , HandlerNotifications);
	
EndProcedure

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Configuration subsystems event handlers.

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientParameters.Property("Banks") And ClientParameters.Banks.OutputMessageOnInvalidity Then
		AttachIdleHandler("BankManagerOutputObsoleteDataNotification", 180, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Update bank classifier.

// Displays the update notification.
//
Procedure NotifyClassifierObsolete() Export
	
	If BankManagerServerCall.ClassifierUpToDate() Then
		Return;
	EndIf;
	
	ShowUserNotification(
		NStr("vi = 'Bảng mã hiệu ngân hàng đã cũ';
			|ru = 'Классификатор банков устарел';
			|en = 'The bank classifier is outdated'; fa = 'The bank classifier is outdated';
			|it = 'Il classificatore delle banche è obsoleto';
			|pl = 'Klasyfikator banków jest nieaktualny';
			|tr = 'Banka sınıflandırıcı zaman aşımına uğramış'"),
		NotificationURLImportForm(),
		NStr("vi = 'Cập nhật bảng mã hiệu ngân hàng';
			|ru = 'Обновить классификатор банков';
			|en = 'Update the bank classifier'; fa = 'Update the bank classifier';
			|it = 'Aggiornare il classificatore delle banche';
			|pl = 'Zaktualizować klasyfikator banków';
			|tr = 'Banka sınıflandırıcısını yenile'"),
		PictureLib.DialogExclamation,
		UserNotificationStatus.Important,
		"BankClassifierIsOutdated");
	
EndProcedure

// Returns a notification URL.
//
Function NotificationURLImportForm()
	Return "e1cib/command/DataProcessor.ImportBankClassifier.Command.ImportBankClassifier";
EndFunction

Procedure OpenClassifierImportForm() Export
	AttachIdleHandler("BankManagerOpenClassifierImportForm", 0.1, True);
EndProcedure

Procedure GoToClassifierImport() Export
	FileSystemClient.OpenURL(NotificationURLImportForm());
EndProcedure

Procedure SuggestToImportClassifier() Export
	
	CallbackDescription = New CallbackDescription("OnGetAnswerToQuestionAboutClassifierImport", ThisObject);
	QuestionTitle = NStr("vi = 'Kết nhập bảng mã hiệu ngân hàng';
						|ru = 'Загрузка классификатора банков';
						|en = 'Import bank classifier'; fa = 'Import bank classifier';
						|it = 'Download dei classificatori delle banche';
						|pl = 'Pobieranie klasyfikatora banków';
						|tr = 'Banka sınıflandırmayı içe aktarma'");
	QueryText = NStr("vi = 'Vẫn chưa kết nhập bảng mã hiệu ngân hàng. Kết nhập bây giờ?';
					|ru = 'Классификатор банков еще не загружен. Загрузить сейчас?';
					|en = 'Bank classifier has not been imported yet. Import now?'; fa = 'Bank classifier has not been imported yet. Import now?';
					|it = 'Il classificatore delle banche non è ancora scaricato. Scaricare ora?';
					|pl = 'Nie pobrano jeszcze klasyfikatora banków. Pobrać teraz?';
					|tr = 'Banka sınıflandırıcısı henüz yüklenmedi. Şimdi yüklensin mi?'");
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Kết nhập';
											|ru = 'Загрузить';
											|en = 'Import'; fa = 'ورود اطلاعات';
											|it = 'Scaricare';
											|pl = 'Import';
											|tr = 'İçe aktar'"));
	Buttons.Add(DialogReturnCode.Cancel);
	ShowQueryBox(CallbackDescription, QueryText, Buttons, , Buttons[0].Value, QuestionTitle);

EndProcedure

Procedure OnGetAnswerToQuestionAboutClassifierImport(Response, AdditionalParameters) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	OpenClassifierImportForm();
	
EndProcedure

#EndRegion
