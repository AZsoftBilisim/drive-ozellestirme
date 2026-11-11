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
	If TypeOf(Parameters.Variants) <> Type("Array") Then
		ErrorText = NStr("vi = 'Chưa chỉ ra phương án báo cáo.';
						|ru = 'Не указаны варианты отчетов.';
						|en = 'No report options provided.'; fa = 'No report options provided.';
						|it = 'Varianti dei report non specificate.';
						|pl = 'Nie określono wariantów raportów.';
						|tr = 'Rapor seçenekleri belirtilmedi.'");
		Return;
	EndIf;

	If Not HasUserSettings(Parameters.Variants) Then
		ErrorText = NStr("vi = 'Chưa đặt hoặc đã thiết lập lại tùy chỉnh tự tạo của các phương án báo cáo đã chọn (%1).';
						|ru = 'Пользовательские настройки выбранных вариантов отчетов (%1 шт) не заданы или уже сброшены.';
						|en = 'Custom settings for the %1selected report options have not been defined or have been reset.'; fa = 'Custom settings for the %1selected report options have not been defined or have been reset.';
						|it = 'Impostazioni personalizzate per le varianti dei report (%1 elementi) non sono impostate o sono già state ripristinate.';
						|pl = 'Nie określono lub zresetowano ustawienia niestandardowe wybranych wariantów raportów (%1 szt.).';
						|tr = 'Seçilen rapor seçeneklerinin (%1 adet) kullanıcı ayarları belirtilmemiş veya zaten sıfırlanmış.'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, 
			Format(Parameters.Variants.Count(), "NZ=0; NG=0"));
		Return;
	EndIf;

	DefineBehaviorInMobileClient();
	OptionsToAssign.LoadValues(Parameters.Variants);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If Not IsBlankString(ErrorText) Then
		Cancel = True;
		ShowMessageBox(, ErrorText);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ResetCommand(Command)
	OptionsCount = OptionsToAssign.Count();
	If OptionsCount = 0 Then
		ShowMessageBox(, NStr("vi = 'Chưa chỉ ra phương án báo cáo.';
								|ru = 'Не указаны варианты отчетов.';
								|en = 'No report options provided.'; fa = 'No report options provided.';
								|it = 'Varianti dei report non specificate.';
								|pl = 'Nie określono wariantów raportów.';
								|tr = 'Rapor seçenekleri belirtilmedi.'"));
		Return;
	EndIf;

	ResetUserSettingsServer(OptionsToAssign);
	If OptionsCount = 1 Then
		OptionRef1 = OptionsToAssign[0].Value;
		NotificationTitle1 = NStr("vi = 'Đã thiết lập lại tùy chỉnh tự tạo đối với phương án báo cáo';
									|ru = 'Сброшены пользовательские настройки варианта отчета';
									|en = 'Custom settings for the report option have been reset.'; fa = 'Custom settings for the report option have been reset.';
									|it = 'Le impostazioni personalizzate della variante del report sono state ripristinate';
									|pl = 'Zresetowano ustawienia niestandardowe wariantu raportu';
									|tr = 'Rapor seçeneğinin kullanıcı ayarları sıfırlandı'");
		NotificationRef    = GetURL(OptionRef1);
		NotificationText     = String(OptionRef1);
		ShowUserNotification(NotificationTitle1, NotificationRef, NotificationText);
	Else
		NotificationText = NStr("vi = 'Đã thiết lập lại tùy chỉnh tự tạo đối với
							   |các phương án báo cáo (%1).';
							   |ru = 'Сброшены пользовательские настройки
							   |вариантов отчетов (%1 шт.).';
							   |en = 'Custom settings for %1 report options
							   |have been reset.'; fa = 'Custom settings for %1 report options
							   |have been reset.';
							   |it = 'Impostazioni personalizzate delle varianti dei report sono state ripristinate
							   |(%1 elementi).';
							   |pl = 'Zresetowano niestandardowe ustawienia
							   |wariantów raportów (%1 szt.).';
							   |tr = 'Rapor seçeneklerinin
							   |kullanıcı ayarları sıfırlandı (%1 adet).'");
		NotificationText = StringFunctionsClientServer.SubstituteParametersToString(NotificationText, 
			Format(OptionsCount, "NZ=0; NG=0"));
		ShowUserNotification(,, NotificationText);
	EndIf;
	Close();
EndProcedure

#EndRegion

#Region Private

#Region ServerCall

&AtServerNoContext
Procedure ResetUserSettingsServer(Val OptionsToAssign)
	BeginTransaction();
	Try
		Block = New DataLock;
		For Each ListItem In OptionsToAssign Do
			LockItem = Block.Add(Metadata.Catalogs.ReportsOptions.FullName());
			LockItem.SetValue("Ref", ListItem.Value);
		EndDo;
		Block.Lock();

		InformationRegisters.ReportOptionsSettings.ResetSettings(OptionsToAssign.UnloadValues());

		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
EndProcedure

#EndRegion

#Region Server

&AtServer
Procedure DefineBehaviorInMobileClient()
	If Not Common.IsMobileClient() Then
		Return;
	EndIf;

	CommandBarLocation = FormCommandBarLabelLocation.Auto;
EndProcedure

&AtServer
Function HasUserSettings(OptionsArray)
	Query = New Query;
	Query.SetParameter("OptionsArray", OptionsArray);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS HasUserSettings
	|FROM
	|	InformationRegister.ReportOptionsSettings AS Settings
	|WHERE
	|	Settings.Variant IN(&OptionsArray)";

	HasUserSettings = Not Query.Execute().IsEmpty();
	Return HasUserSettings;
EndFunction

#EndRegion

#EndRegion