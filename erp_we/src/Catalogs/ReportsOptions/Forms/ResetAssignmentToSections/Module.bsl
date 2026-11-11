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

	DefineBehaviorInMobileClient();
	OptionsToAssign.LoadValues(Parameters.Variants);
	Filter();
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
	SelectedOptionsCount = OptionsToAssign.Count();
	If SelectedOptionsCount = 0 Then
		ShowMessageBox(, NStr("vi = 'Chưa chỉ ra phương án báo cáo.';
								|ru = 'Не указаны варианты отчетов.';
								|en = 'No report options provided.'; fa = 'No report options provided.';
								|it = 'Varianti dei report non specificate.';
								|pl = 'Nie określono wariantów raportów.';
								|tr = 'Rapor seçenekleri belirtilmedi.'"));
		Return;
	EndIf;

	OptionsCount = ResetAssignmentSettingsServer(OptionsToAssign);
	If OptionsCount = 1 And SelectedOptionsCount = 1 Then
		OptionRef1 = OptionsToAssign[0].Value;
		NotificationTitle1 = NStr("vi = 'Đã thiết lập lại tùy chỉnh sắp xếp phương án báo cáo';
									|ru = 'Сброшены настройки размещения варианта отчета';
									|en = 'Report option assignment settings have been reset.'; fa = 'Report option assignment settings have been reset.';
									|it = 'Impostazioni per il posizionamento della variante del report ripristinate';
									|pl = 'Zresetowano ustawienia rozmieszczania wariantu raportu';
									|tr = 'Rapor seçeneğinin yerleştirme ayarları sıfırlandı'");
		NotificationRef    = GetURL(OptionRef1);
		NotificationText     = String(OptionRef1);
		ShowUserNotification(NotificationTitle1, NotificationRef, NotificationText);
	Else
		NotificationText = NStr("vi = 'Đã thiết lập lại tùy chỉnh sắp xếp
							   |phương án báo cáo (%1).';
							   |ru = 'Сброшены настройки размещения
							   |вариантов отчетов (%1 шт.).';
							   |en = 'Assignment settings for %1 report options
							   |have been reset.'; fa = 'Assignment settings for %1 report options
							   |have been reset.';
							   |it = 'Ripristinate impostazioni per il posizionamento 
							   | delle varianti dei report (%1 elementi).';
							   |pl = 'Zresetowano ustawienia rozmieszczania
							   |wariantów raportów (%1 szt.).';
							   |tr = 'Rapor 
							   |seçenekleri yerleştirme ayarları sıfırlandı (%1 adet).'");
		NotificationText = StringFunctionsClientServer.SubstituteParametersToString(NotificationText, Format(
			OptionsCount, "NZ=0; NG=0"));
		ShowUserNotification(,, NotificationText);
	EndIf;
	ReportsOptionsClient.UpdateOpenForms();
	Close();
EndProcedure

#EndRegion

#Region Private

#Region ServerCall

&AtServerNoContext
Function ResetAssignmentSettingsServer(Val OptionsToAssign)
	OptionsCount = 0;
	BeginTransaction();
	Try
		Block = New DataLock;
		For Each ListItem In OptionsToAssign Do
			LockItem = Block.Add(Metadata.Catalogs.ReportsOptions.FullName());
			LockItem.SetValue("Ref", ListItem.Value);
		EndDo;
		Block.Lock();

		For Each ListItem In OptionsToAssign Do
			OptionObject = ListItem.Value.GetObject(); // CatalogObject.ReportsOptions
			If ReportsOptions.ResetReportOptionSettings(OptionObject) Then
				OptionObject.Write();
				OptionsCount = OptionsCount + 1;
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	Return OptionsCount;
EndFunction

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
Procedure Filter()

	CountBeforeFilter = OptionsToAssign.Count();

	Query = New Query;
	Query.SetParameter("OptionsArray", OptionsToAssign.UnloadValues());
	Query.SetParameter("InternalType", Enums.ReportsTypes.BuiltIn);
	Query.SetParameter("ExtensionType", Enums.ReportsTypes.Extension);
	Query.Text =
	"SELECT DISTINCT
	|	ReportOptionsPlacement.Ref
	|FROM
	|	Catalog.ReportsOptions AS ReportOptionsPlacement
	|WHERE
	|	ReportOptionsPlacement.Ref IN(&OptionsArray)
	|	AND ReportOptionsPlacement.Custom = FALSE
	|	AND ReportOptionsPlacement.ReportType IN (&InternalType, &ExtensionType)
	|	AND ReportOptionsPlacement.DeletionMark = FALSE";

	OptionsArray = Query.Execute().Unload().UnloadColumn("Ref");
	OptionsToAssign.LoadValues(OptionsArray);

	CountAfterFilter = OptionsToAssign.Count();
	If CountBeforeFilter <> CountAfterFilter Then
		If CountAfterFilter = 0 Then
			ErrorText = NStr("vi = 'Không cần thiết lập lại tùy chỉnh vị trí của các phương án báo cáo đã chọn vì một hoặc một số lý do: 
							   |- Đã chọn các phương án báo cáo tự tạo.
							   |- Đã chọn các phương án báo cáo bị đặt dấu xóa.
							   |- Đã chọn các phương án báo cáo ngoài hoặc bổ sung.';
							   |ru = 'Сброс настроек размещения выбранных вариантов отчетов не требуется по одной или нескольким причинам:
							   |- Выбраны пользовательские варианты отчетов.
							   |- Выбраны помеченные на удаление варианты отчетов.
							   |- Выбраны варианты дополнительных или внешних отчетов.';
							   |en = 'You do not have to reset assignment settings for selected report options due to one or more of the following reasons:
							   |- Selected report options are custom options.
							   |- Selected report options are marked for deletion.
							   |- Selected report options are additional or external reports.'; fa = 'You do not have to reset assignment settings for selected report options due to one or more of the following reasons:
							   |- Selected report options are custom options.
							   |- Selected report options are marked for deletion.
							   |- Selected report options are additional or external reports.';
							   |it = 'Il ripristino delle impostazioni di posizionamento delle varianti dei report selezionate non è richiesto per uno o più motivi:
							   |- Sono selezionate varianti dei report personalizzate.
							   |- Sono selezionate delle varianti contrassegnate per la cancellazione.
							   |- Sono selezionate varianti dei report aggiuntivi o esterni.';
							   |pl = 'Resetowanie ustawień rozmieszczania wybranych wariantów raportów nie jest konieczne z jednego lub kilku powodów:
							   |- Wybrano niestandardowe warianty raportów.
							   |- Wybrano zaznaczone do usunięcia warianty raportów.
							   |- Wybrano warianty dodatkowych raportów lub raportów zewnętrznych.';
							   |tr = 'Seçilen rapor seçeneklerinin ayarlarının sıfırlanması bir veya 
							   |birkaç nedenden dolayı gerekmemektedir:- Özel rapor seçenekleri seçildi. 
							   |- Silinmek üzere işaretlenmiş raporlama seçenekleri seçildi.
							   |- Ek veya harici raporlar seçenekleri seçildi.'");
			Return;
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#EndRegion