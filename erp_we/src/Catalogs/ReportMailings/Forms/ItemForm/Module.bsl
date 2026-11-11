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
Procedure OnReadAtServer(CurrentObject)
	Rereading = (Cache <> Undefined);
	
	// StandardSubsystems.AttachableCommands
		If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
			ModuleAttachableCommandsClientServer = Common.CommonModule("AttachableCommandsClientServer");
			ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
		EndIf;
	// End StandardSubsystems.AttachableCommands

	// Read value storage.
	If CurrentObject.HTMLFormatEmail Then
		EmailAttachmentsStructureInHTMLFormat = CurrentObject.EmailPicturesInHTMLFormat.Get();
		If EmailAttachmentsStructureInHTMLFormat = Undefined Then
			EmailAttachmentsStructureInHTMLFormat = New Structure;
		EndIf;
		EmailTextFormattedDocument.SetHTML(CurrentObject.EmailTextInHTMLFormat, EmailAttachmentsStructureInHTMLFormat);
	EndIf;
	
	// Refill form data to be clear on rereading object from DB.
	If Rereading Then
		FillReportTableInfo();
		ReadJobSchedule();
		AddCommandsAddTextAdditionalParameters();
	EndIf;
	
	DoDisplayImportance();
	
	For Each String In Object.Reports Do
		String.DoNotSendIfEmpty = Not String.SendIfEmpty;
	EndDo;
	
	CreateAttributeItemEncryptionCertificate();
	SetCertificatePasswordsVisibilityAndAvailability(ThisObject);
	
	If GetFunctionalOption("RetainReportDistributionHistory") And Not Object.Personal And Object.UseEmail Then
		MailoutStatus = ReportMailing.GetReportDistributionState(Object.Ref);
		If MailoutStatus.WithErrors Then
			Items.RedistributionHeader.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã gửi báo cáo hàng loạt (%1) không phải cho tất cả người nhận.';
					|ru = 'Рассылка отчетов (%1) была отправлена не всем получателям.';
					|en = 'The report distribution (%1) was not delivered to some recipients.'; fa = 'The report distribution (%1) was not delivered to some recipients.';
					|it = 'Рассылка отчетов (%1) была отправлена не всем получателям.';
					|pl = 'The report distribution (%1) was not delivered to some recipients.';
					|tr = 'Rapor bülteni (%1) tüm alıcılara gönderilmedi.'"),
				MailoutStatus.LastRunStart);
			Items.GroupRedistribution.Visible = True;
		Else
			Items.GroupRedistribution.Visible = False;
		EndIf;
	EndIf;
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	UpdateListOfFilesAndEmailTextParameters();
	ConvertTextParameters(Object, "ParametersInPresentation");
	ConvertReportsSettingsParameters(Object, "ParametersInPresentation");
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IsNew = Object.Ref.IsEmpty();
	
	If IsNew Then
		UpdateListOfFilesAndEmailTextParameters();
	EndIf;
	
	SetConditionalAppearance();
	
	ErrorTextOnOpen = ReportMailing.CheckAddRightErrorText();
	If ValueIsFilled(ErrorTextOnOpen) Then
		Return;
	EndIf;
		
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
		ModuleObjectsVersioning.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.ObjectsVersioning
	
	If Object.DeletionMark Then
		ReadOnly = True;
	EndIf;
	
	// Deleting the "To folder" option if the FilesOperations subsystem is not available.
	If TypeOf(Object.Folder) = Type("Undefined") Or TypeOf(Object.Folder) = Type("String") Then
		Items.OtherDeliveryMethod.ChoiceList.Delete(0);
	EndIf;
	
	// Delete the To network directory option if the operation mode in SaaS mode.
	If Common.DataSeparationEnabled() Then
		TransportMethodNetworkDirectory = Items.OtherDeliveryMethod.ChoiceList.FindByValue("UseNetworkDirectory");
		Items.OtherDeliveryMethod.ChoiceList.Delete(TransportMethodNetworkDirectory);
	EndIf;
	
	If Not AccessRight("EventLog", Metadata) Then
		Items.MailingEventsCommand.Visible = False;
		Items.MailingEvents.Visible = False;
	EndIf;
		
	MailingBasis = Parameters.CopyingValue;
	
	// Used on import and write selected report settings.
	CurrentRowIDOfReportsTable = -1;
	
	CreatedByCopying = Not MailingBasis.IsEmpty();
	
	If IsNew Then
		CreateAttributeItemEncryptionCertificate();
		DoDisplayImportance();
	EndIf;
	
	// Add reports to tabular section.
	If TypeOf(Parameters.ReportsToAttach) = Type("Array") Then
		Modified = True;
		AddReportsSettings(Parameters.ReportsToAttach);
	EndIf;
	
	Cache = GetCache();
	
	Schedule = New JobSchedule;
	
	MailingWasPersonalized = Object.Personalized;
	
	// Read
	FillReportTableInfo();
	FillEmptyTemplatesWithStandard(Object);
	
	If IsNew And Not CreatedByCopying Then
		DefineDistributionKind();
		FillScheduleByOption(Undefined);
	Else
		ReadJobSchedule();
	EndIf;
	
	// Populate report distribution author.
	If IsNew Then
		// Report distribution author.
		CurrentUser = Users.CurrentUser();
		Object.Author = CurrentUser;
		Object.EmailImportance = EmailOperationsInternalClientServer.InternetMailMessageImportanceStandard();
		Object.ShouldAttachReports = True;
		If Not ValueIsFilled(Object.Author) Then
			Cancel = True;
			
			LogParameters = New Structure;
			LogParameters.Insert("EventName", NStr("vi = 'Gửi báo cáo. Mở biểu mẫu phần tử';
													|ru = 'Рассылка отчетов. Открытие формы элемента';
													|en = 'Report distribution. Opening item form'; fa = 'Report distribution. Opening item form';
													|it = 'Spedizione di report. Apertura del modello di elemento';
													|pl = 'Subskrypcja raportów. Otwarcie formularza elementu';
													|tr = 'Rapor Bülteni. Öğe formunu aç'", Common.DefaultLanguageCode()));
			LogParameters.Insert("Data", Undefined);
			LogParameters.Insert("Metadata", Metadata.Catalogs.ReportMailings);
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 không thể được chỉ định bởi tác giả gửi hàng loạt.';
					|ru = '%1 не может быть указан автором рассылки.';
					|en = '%1 cannot be a report distribution author.'; fa = '%1 cannot be a report distribution author.';
					|it = '%1 не может быть указан автором рассылки.';
					|pl = '%1 cannot be a report distribution author.';
					|tr = '%1, dağıtımı oluşturan kişiyi belirtemiyor.'"),
				Common.SubjectString(CurrentUser));

			ReportMailing.LogRecord(LogParameters, EventLogLevel.Error, Text);
			
			Return;
		EndIf;
		
		// Asterisks for passwords to be copied from a basis.
		If CreatedByCopying Then
			BasisAuthor = Common.ObjectAttributeValue(MailingBasis, "Author");
			If BasisAuthor = CurrentUser Then
				SetPrivilegedMode(True);
				Passwords = Common.ReadDataFromSecureStorage(MailingBasis,
					"ArchivePassword, FTPPassword");
				SetPrivilegedMode(False);
				If ValueIsFilled(Passwords.ArchivePassword) Then
					ArchivePasswordChanged = True; // See this parameter processing in the OnWriteAtServer.
				EndIf;
				If ValueIsFilled(Passwords.FTPPassword) Then
					FTPPassword = PasswordHidden();
					FTPPasswordChanged = True; // See this parameter processing in the OnWriteAtServer.
				EndIf;
				If Object.Personal And CanEncryptAttachments Then
					RecipientsCertificates = ReportMailing.GetEncryptionCertificatesForDistributionRecipients(Object.Author);
					If RecipientsCertificates.Count() > 0 Then
						ThisObject["CertificateToEncrypt"] = RecipientsCertificates[0].CertificateToEncrypt;
						EncryptionCertificateChanged = True; // See this parameter processing in the OnWriteAtServer.
					EndIf;
				EndIf;
			EndIf;
		EndIf;
		
		// Reset parameters that cannot be copied to defaults.
		If Not ArchivePasswordChanged Then
			Object.ArchiveName = Cache.Templates.ArchiveName;
		EndIf;
		If Not FTPPasswordChanged Then
			Object.FTPUsername = "";
			Object.FTPServer = "";
			Object.FTPPort = 21;
			Object.FTPDirectory = "";
		EndIf;
	Else
		SetPrivilegedMode(True);
		Passwords = Common.ReadDataFromSecureStorage(Object.Ref, "ArchivePassword, FTPPassword");
		SetPrivilegedMode(False);
		ArchivePassword = ?(ValueIsFilled(Passwords.ArchivePassword), Passwords.ArchivePassword, "");
		FTPPassword = ?(ValueIsFilled(Passwords.FTPPassword), PasswordHidden(), "");
		If Object.Personal And CanEncryptAttachments Then
			RecipientsCertificates = ReportMailing.GetEncryptionCertificatesForDistributionRecipients(Object.Author);
			If RecipientsCertificates.Count() > 0 Then
				ThisObject["CertificateToEncrypt"] = RecipientsCertificates[0].CertificateToEncrypt;
			EndIf;
		EndIf;
	EndIf;
	Passwords = Undefined;
	
	// Allows you to see and control some protected mailing parameters.
	MailingBeingEditedByAuthor = (Object.Author = Users.CurrentUser());
	
	// Add additional report button availability.
	Items.ReportsAddAdditionalReport.Enabled = ?(Cache.EmptyReportValue = Undefined, True, False);
	// "Cache.EmptyReportValue" is set to "Undefined" is the "Report" attribute type is flexible. 
	//   Therefore, the "Additional reports and data processors" subsystem is integrated.
	
	// Report distribution author availability.
	Items.Author.Enabled = Users.IsFullUser();
	
	// List of formats with marks for default formats.
	DefaultFormatsList = ReportMailing.FormatsList();
	
	// Default formats list presentation.
	DefaultFormatsListPresentation = "";
	For Each ListItem In DefaultFormatsList Do
		If ListItem.Check Then
			DefaultFormatsListPresentation = DefaultFormatsListPresentation + ?(DefaultFormatsListPresentation = "", "", ", ") + String(ListItem.Presentation);
		EndIf;
	EndDo;
	
	// Editable format list.
	FormatsList = DefaultFormatsList.Copy();
	
	// Default formats list presentation within the mailing.
	DefaultFormats = "";
	FoundItems = Object.ReportFormats.FindRows(New Structure("Report", Cache.EmptyReportValue));
	If FoundItems.Count() = 0 Then
		DefaultFormats = DefaultFormatsListPresentation;
	Else
		For Each StringFormat In FoundItems Do
			DefaultFormats = DefaultFormats + ?(DefaultFormats = "", "", ", ") + ReportMailing.FormatPresentation(StringFormat.Format);
		EndDo;
	EndIf;
	
	// Attachments.
	If EmailAttachmentsStructureInHTMLFormat = Undefined Then
		EmailAttachmentsStructureInHTMLFormat = New Structure;
	EndIf;
	
	// For the recipients and exclusion lists one tabular section is used.
	Items.EmptySettings.RowFilter = New FixedStructure("PictureIndex", 200);
	
	// Selection list of author postal addresses.
	RecipientMailAddresses(Object.Author, Items.AuthorMailAddressKind.ChoiceList);
	
	// Selection list of author postal addresses.
	ConnectEmailSettingsCache();
	
	// Read report settings from the object being copied.
	If CreatedByCopying Then
		ReadObjectSettingsOfObjectToCopy();
		ConvertTextParameters(Object, "ParametersInPresentation");
		ConvertReportsSettingsParameters(Object, "ParametersInPresentation");
	EndIf;
	
	// Activate the first row.
	If Object.Reports.Count() > 0 And CurrentRowIDOfReportsTable = -1 Then
		ReportsRow = Object.Reports[0];
		RowID = ReportsRow.GetID();
		ErrorText = ReportsOnActivateRowAtServer(RowID);
		If ErrorText <> "" Then
			Common.MessageToUser(ErrorText, , "Object.Reports[0].Presentation");
		EndIf;
	EndIf;
	
	SetVisibilityAvailabilityAndCorrectness(ThisObject);
	AddCommandsAddTextAdditionalParameters();
	
	FixAttributesValuesBeforeChange();
	
	For Each String In Object.Reports Do
		String.DoNotSendIfEmpty = Not String.SendIfEmpty;
	EndDo;
	
	If AccessRight("Update", Metadata.Catalogs.ReportMailings) Then
		Items.ArchivePassword.ChoiceButton = True;
	Else
		Items.ArchivePassword.ChoiceButton = False;
	EndIf;
	
	CheckPeriodsInReports();
	
	If Common.IsMobileClient() Then
		Items.CommandSaveAndClose.Representation = ButtonRepresentation.Picture;
		Items.OtherDeliveryMethods.Group = ChildFormItemsGroup.HorizontalIfPossible;
		Items.UseNetworkDirectory.Group = ChildFormItemsGroup.HorizontalIfPossible;
		Items.UseFolder.Group = ChildFormItemsGroup.HorizontalIfPossible;
		Items.ReplyToAddressBCC.Group = ChildFormItemsGroup.HorizontalIfPossible;
		Items.Move(Items.DeliverRight, Items.AdditionalPage);
		Items.Move(Items.GroupPasswordsEncryption, Items.AdditionalPage);
		Items.DefaultFormats.TitleLocation = FormItemTitleLocation.Top;
		Items.BulkEmailRecipients.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
		
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If FormWasModifiedAtServer Then
		Modified = True;
	EndIf;
	If ValueIsFilled(ErrorTextOnOpen) Then
		Cancel = True;
		ShowMessageBox(, ErrorTextOnOpen);
		Return;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	If ValueIsFilled(PopupAlertTextOnOpen) Then
		ShowUserNotification(PopupAlertTextOnOpen, , , PictureLib.ExecuteTask)
	EndIf;
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	// Check data that is output through the attributes of the form itself.
	If Not ValueIsFilled(Object.Description) Then
		Cancel = True;
		MessageText = NStr("vi = 'Chưa nhập tên gọi.';
							|ru = 'Не введено наименование.';
							|en = 'Description is not entered.'; fa = 'Description is not entered.';
							|it = 'Не введено наименование.';
							|pl = 'Description is not entered.';
							|tr = 'Tanım girilmedi.'");
		Common.MessageToUser(MessageText, , "Object.Description");
	EndIf;
	If Object.UseEmail And Not Object.Personal Then
		If Not ValueIsFilled(MailingRecipientType) Then
			Cancel = True;
			MessageText = NStr("vi = 'Chưa chọn kiểu người nhận.';
								|ru = 'Не выбран тип получателей.';
								|en = 'Recipient type is not selected.'; fa = 'Recipient type is not selected.';
								|it = 'Не выбран тип получателей.';
								|pl = 'Recipient type is not selected.';
								|tr = 'Alıcı türü seçilmedi.'");
			Common.MessageToUser(MessageText, , "MailingRecipientType");
		EndIf;
	EndIf;
	
	If Object.IsPrepared Then
		If Object.Reports.Count() = 0 Then
			Cancel = True;
			MessageText = NStr("vi = 'Chưa chọn báo cáo nào.';
								|ru = 'Не выбрано ни одного отчета.';
								|en = 'No report is selected.'; fa = 'No report is selected.';
								|it = 'Не выбрано ни одного отчета.';
								|pl = 'No report is selected.';
								|tr = 'Herhangi bir rapor seçilmedi.'");
			Common.MessageToUser(MessageText, , "Object.Reports");
		EndIf;
		
		If Not ValueIsFilled(Object.SchedulePeriodicity) Then
			Cancel = True;
			MessageText = NStr("vi = 'Chưa chọn định kỳ khởi động.';
								|ru = 'Не выбрана периодичность запуска.';
								|en = 'Distribution frequency is not specified.'; fa = 'Distribution frequency is not specified.';
								|it = 'Не выбрана периодичность запуска.';
								|pl = 'Distribution frequency is not specified.';
								|tr = 'Başlatma sıklığı seçilmedi.'");
			Common.MessageToUser(MessageText, , "Object.SchedulePeriodicity");
		EndIf;
		
		If Object.UseFTPResource Then
			If Not ValueIsFilled(Object.FTPServer)
				Or Not ValueIsFilled(Object.FTPPort)
				Or Not ValueIsFilled(Object.FTPDirectory) Then
				Cancel = True;
				MessageText = NStr("vi = 'Chưa nhập địa chỉ FTP.';
									|ru = 'Не введен FTP адрес.';
									|en = 'FTP address is not entered.'; fa = 'FTP address is not entered.';
									|it = 'Не введен FTP адрес.';
									|pl = 'FTP address is not entered.';
									|tr = 'FTP adresi girilmedi.'");
				Common.MessageToUser(MessageText, , "FTPServerAndDirectory");
			EndIf;
		EndIf;
		
		If Object.UseNetworkDirectory Then
			If Not ValueIsFilled(Object.NetworkDirectoryWindows) Then
				Cancel = True;
				MessageText = NStr("vi = 'Chưa nhập thư mục mạng Windows.';
									|ru = 'Не введен сетевой каталог Windows.';
									|en = 'Windows network directory is not entered.'; fa = 'Windows network directory is not entered.';
									|it = 'Не введен сетевой каталог Windows.';
									|pl = 'Windows network directory is not entered.';
									|tr = 'Windows ağ dizini girilmedi.'");
				Common.MessageToUser(MessageText, , "Object.NetworkDirectoryWindows");
			EndIf;
			If Not ValueIsFilled(Object.NetworkDirectoryLinux) Then
				Cancel = True;
				MessageText = NStr("vi = 'Chưa nhập thư mục mạng Linux.';
									|ru = 'Не введен сетевой каталог Linux.';
									|en = 'Linux network directory is not entered.'; fa = 'Linux network directory is not entered.';
									|it = 'Не введен сетевой каталог Linux.';
									|pl = 'Linux network directory is not entered.';
									|tr = 'Linux ağ dizini girilmedi.'");
				Common.MessageToUser(MessageText, , "Object.NetworkDirectoryLinux");
			EndIf;
		EndIf;
		
		If Object.UseFolder Then
			If Not ValueIsFilled(Object.Folder) Then
				Cancel = True;
				MessageText = NStr("vi = 'Chưa chọn thư mục.';
									|ru = 'Не выбрана папка.';
									|en = 'Folder is not selected.'; fa = 'Folder is not selected.';
									|it = 'Не выбрана папка.';
									|pl = 'Folder is not selected.';
									|tr = 'Klasör seçilmedi.'");
				Common.MessageToUser(MessageText, , "Object.Folder");
			EndIf;
		EndIf;
		
		If Object.UseEmail Then
			If Object.Personal Then
				If Not ValueIsFilled(Object.RecipientsEmailAddressKind) Then
					Cancel = True;
					MessageText = NStr("vi = 'Chưa chọn địa chỉ email.';
										|ru = 'Не выбран почтовый адрес.';
										|en = 'Email address is not selected.'; fa = 'Email address is not selected.';
										|it = 'Не выбран почтовый адрес.';
										|pl = 'Email address is not selected.';
										|tr = 'Posta adresi seçilmedi.'");
					Common.MessageToUser(MessageText, , "Object.RecipientsEmailAddressKind");
				EndIf;
			Else
				If Not RecipientsSpecified(Object.Recipients) Then
					Cancel = True;
				EndIf;
				If Not ValueIsFilled(Object.RecipientsEmailAddressKind) Then
					Cancel = True;
					MessageText = NStr("vi = 'Chưa chọn kiểu địa chỉ email của người nhận.';
										|ru = 'Не выбран тип почтового адреса получателей.';
										|en = 'Recipient email address type is not selected.'; fa = 'Recipient email address type is not selected.';
										|it = 'Не выбран тип почтового адреса получателей.';
										|pl = 'Recipient email address type is not selected.';
										|tr = 'Alıcı e-posta türü seçilmedi.'");
					Common.MessageToUser(MessageText, , "BulkEmailRecipients");
				EndIf;
			EndIf;
			If Not ValueIsFilled(Object.Account) Then
				Cancel = True;
				MessageText = NStr("vi = 'Chưa chọn tài khoản gửi.';
									|ru = 'Не выбрана учетная запись для отправки.';
									|en = 'Account for sending is not selected.'; fa = 'Account for sending is not selected.';
									|it = 'Не выбрана учетная запись для отправки.';
									|pl = 'Account for sending is not selected.';
									|tr = 'Gönderilecek hesap seçilmedi.'");
				Common.MessageToUser(MessageText, , "Object.Account");
			EndIf;
		EndIf;
	EndIf;
	
	If Object.ExecuteOnSchedule Then
		If Object.SchedulePeriodicity <> Enums.ReportMailingSchedulePeriodicities.CustomValue
		   And ValueIsFilled(Schedule.EndTime)Then
			DatesDiffInHours = SecondsToHours(Schedule.EndTime - Schedule.BeginTime);
			If DatesDiffInHours < 4 Then
				Cancel = True;
				MessageText = NStr("vi = 'Thời gian kết thúc gửi báo cáo phải muộn hơn 4 giờ so với thời gian bắt đầu.';
									|ru = 'Время окончания рассылки отчетов должно быть на 4 часа позже времени начала.';
									|en = 'The end time must be 4 hours later than the start time.'; fa = 'The end time must be 4 hours later than the start time.';
									|it = 'Время окончания рассылки отчетов должно быть на 4 часа позже времени начала.';
									|pl = 'The end time must be 4 hours later than the start time.';
									|tr = 'Rapor dağıtımı için bitiş zamanı başlangıç zamanından 4 saat sonra olmalıdır.'");
				Common.MessageToUser(MessageText, , "EndTime");
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	If WriteParameters = Undefined Then
		WriteParameters = New Structure;
	EndIf;
	If Not WriteParameters.Property("Step") Then
		Cancel = True;
		WriteAtClient(Undefined, WriteParameters);
	EndIf;
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	AttachIdleHandler("UpdatePersonalizedDistributionRecipientParameterValue", 0.1, True);
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	// Write current row settings.
	If CurrentRowIDOfReportsTable <> -1 Then
		WriteReportsRowSettings(CurrentRowIDOfReportsTable);
	EndIf;
	
	// The follow-up actions:
	// [1] Save the custom settings. Put the modified settings rows
	//     to the settings of the object being written (to the value storage).
	//     Analyze all reports if the user changes the settings.
	// [2] Search for unfilled mandatory settings.
	//     Analyze DCS reports if the distribution is prepared.
	CheckRequired1 = Object.IsPrepared;
	// [3] Search for personalized fields if the distribution is not personalized.
	//     Analyze all reports if the user switched the type from personalized to any other type.
	//     
	MailingIsNotPersonalized = (Not Object.Personalized And MailingWasPersonalized);
	For Each ReportsRow In Object.Reports Do
		
		ReportsRowObject = CurrentObject.Reports.Get(ReportsRow.LineNumber-1);
		
		If ReportsRow.ChangesMade Then
			// [1], [2] and [3] Read uninitialized settings.
			UserSettings = GetFromTempStorage(ReportsRow.SettingsAddress);
			
			// [1] Write settings.
			ReportsRowObject.Settings = New ValueStorage(UserSettings, New Deflation(9));
			
			If Not CheckRequired1 And Not MailingIsNotPersonalized Then
				Continue;
			EndIf;
			
		Else
			
			If Not CheckRequired1 And Not MailingIsNotPersonalized Then
				Continue;
			EndIf;
			
			// [2] and [3] Read uninitialized settings.
			If IsTempStorageURL(ReportsRow.SettingsAddress) Then
				UserSettings = GetFromTempStorage(ReportsRow.SettingsAddress);
			Else
				UserSettings = ReportsRowObject.Settings.Get();
			EndIf;
			
		EndIf;
		
		// [2] and [3] Initialize settings.
		ReportParameters = InitializeReport(ReportsRow, True, UserSettings, False);
		ReportSettings = ?(ReportsRow.DCS, ReportParameters.DCSettingsComposer, UserSettings);
		ReportPersonalized = False;
		
		// [2] and [3] DCS reports analysis.
		If ReportsRow.DCS Then
			DCSettings = ReportSettings.Settings;
			DCUserSettings = ReportSettings.UserSettings; // DataCompositionUserSettings
			// [3] Verify settings.
			Filter = New Structure("Use, Value", True, MailingRecipientValueTemplate(FilesAndEmailTextParameters));
			FoundItems = ReportsClientServer.SettingsItemsFiltered(DCUserSettings, Filter);
			If FoundItems.Count() > 0 Then
				ReportPersonalized = True;
			EndIf;
			// [2] Search and check the available setting.
			AllRequiredSettingsFilled = True;
			For Each UserSetting In DCUserSettings.Items Do
				If TypeOf(UserSetting) = Type("DataCompositionSettingsParameterValue") Then
					Id = UserSetting.UserSettingID;
					CommonSetting = ReportsClientServer.GetObjectByUserID(DCSettings, Id);
					If CommonSetting = Undefined Then 
						Continue;
					EndIf;
					AvailableSetting = ReportsClientServer.FindAvailableSetting(DCSettings, CommonSetting);
					If AvailableSetting = Undefined Then
						Continue;
					EndIf;
					If Not AvailableSetting.Use = DataCompositionParameterUse.Always
						And Not UserSetting.Use Then
						Continue;
					EndIf;
					If AvailableSetting.DenyIncompleteValues And Not ValueIsFilled(UserSetting.Value) Then
						AllRequiredSettingsFilled = False;
					EndIf;
				EndIf;
			EndDo;
			
			// [2] Error output.
			If Not AllRequiredSettingsFilled Then
				Cancel = True;
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đối với báo cáo ''%1'' đã điền không phải tất cả tùy chỉnh bắt buộc điền. Cần điền tất cả tùy chỉnh bắt buộc hoặc bỏ dấu hộp kiểm ''Đã soạn''.';
						|ru = 'Для отчета ''%1'' заполнены не все настройки, обязательные для заполнения. Заполните все обязательные настройки или снимите флажок ''Подготовлена''.';
						|en = 'Not all required settings are filled in for the ''%1'' report. Fill in all the required settings or clear the ''Prepared'' check box.'; fa = 'Not all required settings are filled in for the ''%1'' report. Fill in all the required settings or clear the ''Prepared'' check box.';
						|it = 'Per il report ""%1"" sono compilate tutte le impostazioni obbligatorie per la compilazione. Compilare tutte le impostazioni obbligatorie oppure rimuovere il contrassegno ""Preparato"".';
						|pl = 'Dla raportu ''%1'' są wypełnione nie wszystkie ustawienia, konieczne do wypełnienia. Wypełnij wszystkie konieczne ustawienia lub odznacz pole wyboru ''Przygotowane''.';
						|tr = '''%1'' raporu için gerekli tüm ayarlar doldurulmamıştır. Gerekli tüm ayarları tamamlayın veya ''Tedarik Edildi'' onay kutusunun işaretini kaldırın.'"),
					String(ReportsRow.Report));
				Field = "Reports["+ Format(CurrentObject.Reports.IndexOf(ReportsRowObject), "NZ=0; NG=0") +"].Presentation";
				Common.MessageToUser(MessageText, CurrentObject, Field);
			EndIf;
		EndIf;
		
		// [3] Ordinary report analysis.
		If TypeOf(ReportSettings) = Type("ValueTable") Then
			FoundItems = ReportSettings.FindRows(New Structure("Value, Use", MailingRecipientValueTemplate(FilesAndEmailTextParameters), True));
			If FoundItems.Count() > 0 Then
				ReportPersonalized = True;
			EndIf;
		EndIf;
		If MailingIsNotPersonalized And ReportPersonalized Then
			Cancel = True;
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong tùy chỉnh báo cáo ''%1'' đã đặt bộ lọc theo người nhận hàng loạt. Hãy bỏ bộ lọc này hoặc thay đổi dạng gửi hàng loạt sang ''Báo cáo riêng cho mỗi người nhận''.';
					|ru = 'В настройках отчета ''%1'' задан отбор по получателю рассылки. Отключите этот отбор или измените вид рассылки на ''Свой отчет для каждого получателя''.';
					|en = 'Filter by recipients is applied to the ""%1"" report. Remove the filter or change the distribution mode to ""individual report for each recipient"".'; fa = 'Filter by recipients is applied to the ""%1"" report. Remove the filter or change the distribution mode to ""individual report for each recipient"".';
					|it = 'Nelle impostazioni del report ''%1'' è dato un filtro per destinatario della newsletter. Disattivare questo filtro o modificare il tipo di newsletter in ''Report proprio per ciascun destinatario''.';
					|pl = 'W ustawieniach raportu ''%1'' jest zadany filtr wg adresata subskrypcji. Odłącz ten filtr lub zmień rodzaj subskrypcji na ''Własny raport dla każdego odbiorcy''.';
					|tr = 'Rapor ayarlarında ''%1'' posta alıcısına göre filtreleme ayarlanmıştır. Bu seçimi devre dışı bırakın veya posta türünü ''Her alıcı için özel rapor'' olarak değiştirin.'"),
				String(ReportsRow.Report));
			Field = "Reports["+ Format(CurrentObject.Reports.IndexOf(ReportsRowObject), "NZ=0; NG=0") +"].Presentation";
			Common.MessageToUser(MessageText, CurrentObject, Field);
		EndIf;
		
		If Object.Personalized And	Not ReportPersonalized Then
			Cancel = True;
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong tùy chỉnh báo cáo ""%1"" chưa chỉ ra phễu lọc gửi thư theo người nhận.';
					|ru = 'В настройках отчета ""%1"" не указан отбор по получателю рассылки.';
					|en = 'Filter by recipient is not specified in the ""%1"" report settings.'; fa = 'Filter by recipient is not specified in the ""%1"" report settings.';
					|it = 'Nelle impostazioni del report ""%1"" non è specificata la selezione per destinatario di newsletter.';
					|pl = 'W ustawieniach raportu ""%1"" nie określono wyboru wg odbiorcy subskrypcji.';
					|tr = 'Bülten alıcısına göre filtreleme ""%1"" rapor ayarlarında belirtilmedi.'"),
				String(ReportsRow.Report));
			Field = "Reports["+ Format(CurrentObject.Reports.IndexOf(ReportsRowObject), "NZ=0; NG=0") +"].Presentation";
			Common.MessageToUser(MessageText, CurrentObject, Field);
		EndIf;
		
	EndDo;
	
	CurrentObject.EmailPicturesInHTMLFormat = Undefined;
	If CurrentObject.HTMLFormatEmail Then
		CurrentObject.EmailText = TrimAll(EmailTextFormattedDocument.GetText());
		If CurrentObject.EmailText = "" Then
			CurrentObject.EmailTextInHTMLFormat = "";
		Else
			EmailTextFormattedDocument.GetHTML(CurrentObject.EmailTextInHTMLFormat, EmailAttachmentsStructureInHTMLFormat);
			If TypeOf(EmailAttachmentsStructureInHTMLFormat) = Type("Structure")
				And EmailAttachmentsStructureInHTMLFormat.Count() > 0 Then
				CurrentObject.EmailPicturesInHTMLFormat = New ValueStorage(EmailAttachmentsStructureInHTMLFormat, New Deflation(9));
			EndIf;
			CurrentObject.EmailText = EmailTextFormattedDocument.GetText();
		EndIf;
	EndIf;
	
	// Write the values.
	If ValueIsFilled(MailingRecipientType) Then
		FoundItems = RecipientsTypesTable.FindRows(New Structure("RecipientsType", MailingRecipientType));
		If FoundItems.Count() = 1 Then
			CurrentObject.MailingRecipientType = FoundItems[0].MetadataObjectID;
		Else
			CurrentObject.MailingRecipientType = Catalogs.MetadataObjectIDs.EmptyRef();
		EndIf;
	Else
		CurrentObject.MailingRecipientType = Catalogs.MetadataObjectIDs.EmptyRef();
	EndIf;
	
	// All operations with scheduled jobs are placed in the object module.
	If Object.SchedulePeriodicity <> Enums.ReportMailingSchedulePeriodicities.CustomValue 
		And Not ValueIsFilled(Schedule.RepeatPeriodInDay)Then
		Schedule.EndTime = '00010101';
	EndIf;
	CurrentObject.AdditionalProperties.Insert("Schedule", Schedule);
	
	If Not Cancel Then
		ConvertTextParameters(CurrentObject, "PresentationInParameters");
		ConvertReportsSettingsParameters(CurrentObject, "PresentationInParameters");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	ArchivePasswordChangedButHidden = ArchivePasswordChanged And ArchivePassword = PasswordHidden();
	FTPPasswordChangedButHidden = FTPPasswordChanged And FTPPassword = PasswordHidden();
	
	If (ArchivePasswordChangedButHidden Or FTPPasswordChangedButHidden) And ValueIsFilled(MailingBasis) Then
		CurrentUser = Users.CurrentUser();
		BasisAuthor = Common.ObjectAttributeValue(MailingBasis, "Author");
		If BasisAuthor = CurrentUser Then
			SetPrivilegedMode(True);
			If ArchivePasswordChangedButHidden Then
				TemporaryVariable = Common.ReadDataFromSecureStorage(MailingBasis, "ArchivePassword");
				Common.WriteDataToSecureStorage(CurrentObject.Ref, TemporaryVariable, "ArchivePassword");
				ArchivePasswordChanged = False;
			EndIf;
			If FTPPasswordChangedButHidden Then
				TemporaryVariable = Common.ReadDataFromSecureStorage(MailingBasis, "FTPPassword");
				Common.WriteDataToSecureStorage(CurrentObject.Ref, TemporaryVariable, "FTPPassword");
				FTPPasswordChanged = False;
			EndIf;
			SetPrivilegedMode(False);
		EndIf;
		MailingBasis = Undefined;
	EndIf;
	
	If ArchivePasswordChanged Then
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(CurrentObject.Ref, ArchivePassword, "ArchivePassword");
		SetPrivilegedMode(False);
	EndIf;
	
	If FTPPasswordChanged Then
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(CurrentObject.Ref, FTPPassword, "FTPPassword");
		SetPrivilegedMode(False);
	EndIf;
	
	If CanEncryptAttachments And EncryptionCertificateChanged Then
		InformationRegisters.CertificatesOfReportDistributionRecipients.SaveCertificateForDistributionRecipient(
			Object.Author, ThisObject["CertificateToEncrypt"]);
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ConvertTextParameters(Object, "ParametersInPresentation");
	ConvertReportsSettingsParameters(Object, "ParametersInPresentation");
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

	// Refill form tables associated with objects tables (since object tables have already been filled).
	FillReportTableInfo();
	ReportsOnActivateRowAtServer(CurrentRowIDOfReportsTable);
	
	// Update the attributes initial values in the cache.
	FixAttributesValuesBeforeChange();
	For Each String In Object.Reports Do
		String.DoNotSendIfEmpty = Not String.SendIfEmpty;
	EndDo;
	
	CheckPeriodsInReports();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure IsPreparedOnChange(Item)
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "IsPrepared");
EndProcedure

#Region SchedulePage

&AtClient
Procedure ExecuteOnScheduleOnChange(Item)
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "ExecuteOnSchedule");
EndProcedure

&AtClient
Procedure MonthsOnChange(Item)
	If Item <> Undefined Then
		Schedule.Months = ChangeArrayContent(ThisObject[Item.Name], Cache.Maps1.Months[Item.Name], Schedule.Months);
	EndIf;
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "Months");
EndProcedure

&AtClient
Procedure WeekDaysOnChange(Item)
	If Item <> Undefined Then
		Schedule.WeekDays = ChangeArrayContent(ThisObject[Item.Name], Cache.Maps1.WeekDays[Item.Name], Schedule.WeekDays);
	EndIf;
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "WeekDays");
EndProcedure

&AtClient
Procedure ModifySchedule(Command)

	If CommonClient.DataSeparationEnabled() Then
		ClearMessages();
		CommonClient.MessageToUser(NStr("vi = 'Lịch biểu tùy ý không khả dụng khi làm việc qua Internet.';
										|ru = 'Произвольное расписание недоступно при работе через Интернет.';
										|en = 'A custom schedule cannot be set over the Internet.'; fa = 'A custom schedule cannot be set over the Internet.';
										|it = 'Произвольное расписание недоступно при работе через Интернет.';
										|pl = 'A custom schedule cannot be set over the Internet.';
										|tr = 'İnternet üzerinden çalışmada rastgele planlama mevcut değil.'"));
		Return;
	EndIf;
		
	ChangeScheduleInDialog();
EndProcedure

&AtClient
Procedure SchedulePeriodicityOnChange(Item)
	
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "SchedulePeriodicity");
	If Object.SchedulePeriodicity = PredefinedValue("Enum.ReportMailingSchedulePeriodicities.CustomValue") 
	   And Not CommonClient.DataSeparationEnabled() Then
		ChangeScheduleInDialog();
	EndIf;
EndProcedure

&AtClient
Procedure BegEndOfMonthHyperlinkClick(Item)
	If Schedule.DayInMonth = 0 Then
		DayInMonth = 1;
		Schedule.DayInMonth = -1;
	Else
		Schedule.DayInMonth = -Schedule.DayInMonth;
	EndIf;
	Modified = True;
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "MonthBeginEnd");
EndProcedure

&AtClient
Procedure BeginTimeOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	Schedule.BeginTime = BeginTime;
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "BeginTime");
EndProcedure

&AtClient
Procedure UseHourlyRepeatPeriodOnChange(Item)
	RepeatPeriodInDay = ?(UseHourlyRepeatPeriod, 1, 0);
	EndTime = ?(UseHourlyRepeatPeriod, BeginTime + HoursToSeconds(4), '00010101');
	Schedule.EndTime = EndTime;
	Schedule.RepeatPeriodInDay = HoursToSeconds(RepeatPeriodInDay);
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "RepeatPeriodInDay");
EndProcedure

&AtClient
Procedure RepeatPeriodInDayOnChange(Item)
	Schedule.RepeatPeriodInDay = HoursToSeconds(RepeatPeriodInDay);
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "RepeatPeriodInDay");
EndProcedure

&AtClient
Procedure EndTimeOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	Schedule.EndTime = EndTime;
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "EndTime");
EndProcedure

&AtClient
Procedure DaysRepeatPeriodOnChange(Item)
	Schedule.DaysRepeatPeriod = DaysRepeatPeriod;
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "DaysRepeatPeriod");
EndProcedure

&AtClient
Procedure MonthDayOnChange(Item)
	Schedule.DayInMonth = ?(Schedule.DayInMonth >= 0, DayInMonth, -DayInMonth);
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "DayInMonth");
EndProcedure

#EndRegion

#Region DeliveryPage

&AtClient
Procedure MailingRecipientTypeChoiceProcessing(Item, ValueSelected, StandardProcessing)
	If ValueSelected = MailingRecipientType Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	FoundItems = RecipientsTypesTable.FindRows(New Structure("RecipientsType", ValueSelected));
	If FoundItems.Count() <> 1 Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	// Clear recipients (if necessary).
	If Object.Recipients.Count() > 0 Then
		StandardProcessing = False;
		
		QuestionRow = NStr("vi = 'Để tiếp tục cần xóa bỏ danh sách người nhận.';
							|ru = 'Для продолжения необходимо очистить список получателей.';
							|en = 'To continue, clear the recipient list.'; fa = 'To continue, clear the recipient list.';
							|it = 'Per continuare, è necessario cancellare l''elenco dei destinatari.';
							|pl = 'Aby kontynuować, należy oczyścić listę odbiorców.';
							|tr = 'Devam etmek için alıcı listesini temizleyin.'");
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Xóa';
												|ru = 'Очистить';
												|en = 'Clear'; fa = 'پاک کردن';
												|it = 'Cancellare';
												|pl = 'Clear';
												|tr = 'Temizle'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ValueSelected", ValueSelected);
		Handler = New CallbackDescription("MailingRecipientTypeChoiceProcessingCompletion", ThisObject, AdditionalParameters);
		
		ShowQueryBox(Handler, QuestionRow, Buttons, 60, DialogReturnCode.Yes);
	EndIf;
	
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "BulkEmailRecipients");

EndProcedure

&AtClient
Procedure MailingRecipientTypeOnChange(Item)
	FoundItems = RecipientsTypesTable.FindRows(New Structure("RecipientsType", MailingRecipientType));
	If FoundItems.Count() = 1 Then
		RecipientRow = FoundItems[0];
		Object.MailingRecipientType = RecipientRow.MetadataObjectID;
		Object.RecipientsEmailAddressKind = RecipientRow.MainCIKind;
		AddCommandsAddTextAdditionalParameters();
	EndIf;
EndProcedure

&AtClient
Procedure MailingRecipientTypeClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure AuthorMailAddressKindOpening(Item, StandardProcessing)
	StandardProcessing = False;
	ShowValue(, Object.Author);
EndProcedure

&AtClient
Procedure FTPServerAndDirectoryOnChange(Item)
	ValueSelected = ReportMailingClient.ParseFTPAddress(FTPServerAndDirectory);
	FTPServerAndDirectoryChoiceProcessing(Item, ValueSelected, True);
EndProcedure

&AtClient
Procedure FTPServerAndDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	CustomFormParameters = New Structure("Server, Directory, Port, Login, PassiveConnection");
	For Each KeyAndValue In CustomFormParameters Do
		CustomFormParameters[KeyAndValue.Key] = Object["FTP" + KeyAndValue.Key];
	EndDo;
	CustomFormParameters.Insert("Password", FTPPassword);
	CustomFormParameters.Insert("Title", NStr("vi = '<Hãy chỉ ra người nhận>';
												|ru = '<Укажите получателя>';
												|en = '<Specify recipient>'; fa = '<Specify recipient>';
												|it = '<Specificare destinatario>';
												|pl = '<Wskaż odbiorcę>';
												|tr = '<Alıcı belirt>'"));
	
	OpenForm("Catalog.ReportMailings.Form.FTPParameters", CustomFormParameters, Item);
EndProcedure

&AtClient
Procedure FTPServerAndDirectoryChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	If ValueSelected = Undefined Or TypeOf(ValueSelected) <> Type("Structure") Then
		Return;
	EndIf;
	For Each KeyAndValue In ValueSelected Do
		If KeyAndValue.Key = "Password" Then
			If KeyAndValue.Value <> FTPPassword And KeyAndValue.Value <> PasswordHidden() Then
				FTPPassword = KeyAndValue.Value;
				FTPPasswordChanged = True;
			EndIf;
		Else
			Object["FTP" + KeyAndValue.Key] = KeyAndValue.Value;
		EndIf;
	EndDo;
	
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "FTPServerAndDirectory");
	Modified = True;
EndProcedure

&AtClient
Procedure FTPServerAndDirectoryClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure FTPServerAndDirectoryOpening(Item, StandardProcessing)

	StandardProcessing = False;
	
	FullAddress = "ftp://"+ Object.FTPServer +":"+ Format(Object.FTPPort, "NZ=21; NG=0") + Object.FTPDirectory;
	FileSystemClient.OpenURL(FullAddress);

EndProcedure

&AtClient
Procedure BulkEmailTypeOnChange(Item)
	Object.Personal            = (BulkEmailType = "Personal");
	Object.Personalized = (BulkEmailType = "Personalized");
	
	If Not Object.ShouldInsertReportsIntoEmailBody And Not Object.NotifyOnly Then
		Object.ShouldAttachReports = True;
	EndIf;
	
	If Object.Personal Then
		Object.Recipients.Clear();
	ElsIf Not ValueIsFilled(MailingRecipientType) Then
		If Items.MailingRecipientType.ChoiceList.Count() > 0 Then
			MailingRecipientType = Items.MailingRecipientType.ChoiceList[0].Value;
			MailingRecipientTypeOnChange(Items.MailingRecipientType);
		EndIf;
	EndIf;
	
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "BulkEmailType");
	AddCommandsAddTextAdditionalParameters();
	
EndProcedure

&AtClient
Procedure UseEmailOnChange(Item)
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "UseEmail");
	
	If Not Publish And Not Object.UseEmail Then
		Publish = True;
		EvaluateAdditionalDeliveryMethodsCheckBoxes();
		SetVisibilityAvailabilityAndCorrectness(ThisObject, "Publish");
	ElsIf Object.UseEmail And Not Object.ShouldInsertReportsIntoEmailBody And Not Object.NotifyOnly Then
		Object.ShouldAttachReports = True;
	EndIf;
EndProcedure

&AtClient
Procedure NotifyOnlyOnChange(Item)
	
	If Object.NotifyOnly Then
		Object.ShouldInsertReportsIntoEmailBody = False;
		Object.ShouldAttachReports = False;
	Else
		Object.ShouldInsertReportsIntoEmailBody = False;
		Object.ShouldAttachReports = True;
	EndIf;
	
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "NotifyOnly");
EndProcedure

&AtClient
Procedure OtherDeliveryMethodOnChange(Item)
	EvaluateAdditionalDeliveryMethodsCheckBoxes();
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "OtherDeliveryMethod");
EndProcedure

&AtClient
Procedure OtherDeliveryMethodTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	If IsBlankString(Text) Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure PublishOnChange(Item)
	EvaluateAdditionalDeliveryMethodsCheckBoxes();
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "Publish");
	
	If Not Publish And Not Object.UseEmail Then
		Object.UseEmail = True;
		Object.ShouldAttachReports  = True;
		SetVisibilityAvailabilityAndCorrectness(ThisObject, "UseEmail");
	ElsIf Object.UseEmail And Not Object.ShouldInsertReportsIntoEmailBody And Not Object.NotifyOnly Then
		Object.ShouldAttachReports = True;
	EndIf;
EndProcedure

&AtClient
Procedure FolderOpening(Item, StandardProcessing)
	If CommonClient.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsInternalClient = CommonClient.CommonModule("FilesOperationsInternalClient");
		ModuleFilesOperationsInternalClient.ReportsMailingViewFolder(StandardProcessing, Object.Folder);
	EndIf;
EndProcedure

&AtClient
Procedure FolderChoiceProcessing(Item, ValueSelected, StandardProcessing)
	If Not ChangeFolderAndFilesRight(ValueSelected) Then
		StandardProcessing = False;
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không đủ quyền để thay đổi tệp thư mục ""%1"".';
				|ru = 'Недостаточно прав для изменения файлов папки ""%1"".';
				|en = 'Insufficient rights to change files of folder ""%1"".'; fa = 'Insufficient rights to change files of folder ""%1"".';
				|it = 'Permessi insufficienti per la modifica di file della cartella ""%1"".';
				|pl = 'Niewystarczające uprawnienia do zmiany plików folderu ""%1"".';
				|tr = '""%1"" Dosyasının klasörlerini değiştirmek için haklar yetersiz.'"), 
			String(ValueSelected));
		Raise(WarningText, ErrorCategory.AccessViolation);
	EndIf;
EndProcedure

&AtClient
Procedure NetworkDirectoryWindowsOnChange(Item)
	Object.NetworkDirectoryWindows = CommonClientServer.AddLastPathSeparator(Object.NetworkDirectoryWindows);
	If IsBlankString(Object.NetworkDirectoryLinux) Then
		Object.NetworkDirectoryLinux = StrReplace(Object.NetworkDirectoryWindows, "\", "/");
	EndIf; 
EndProcedure

&AtClient
Procedure NetworkDirectoryLinuxOnChange(Item)
	Object.NetworkDirectoryLinux = CommonClientServer.AddLastPathSeparator(Object.NetworkDirectoryLinux);
	If IsBlankString(Object.NetworkDirectoryWindows) Then
		Object.NetworkDirectoryWindows = StrReplace(Object.NetworkDirectoryLinux, "/", "\");
	EndIf; 
EndProcedure

#EndRegion

#Region AdditionalPage

&AtClient
Procedure DefaultFormatsClick(Item, StandardProcessing)
	StandardProcessing = False;
	Handler = New CallbackDescription("DefaultFormatsSelectionCompletion", ThisObject);
	ChooseFormat(Cache.EmptyReportValue, Handler);
EndProcedure

&AtClient
Procedure ArchiveOnChange(Item)
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "Archive");
	CheckOnSetArchivePasswordInsertReportsToEmailText();
EndProcedure

&AtClient
Procedure AuthorOnChange(Item)
	CurrentList = Items.AuthorMailAddressKind.ChoiceList;
	CurrentList.Clear();
	NewList = New ValueList;
	RecipientMailAddresses(Object.Author, NewList);
	For Each ListItem In NewList Do
		FillPropertyValues(CurrentList.Add(), ListItem);
	EndDo;
	If NewList.FindByValue(Object.RecipientsEmailAddressKind) = Undefined Then
		Object.RecipientsEmailAddressKind = Undefined;
	EndIf;
EndProcedure

&AtClient
Procedure ArchiveNameChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected = "DescriptionDistributionDate" Then
		AddLayout();
		StandardProcessing = False;
		CurrentItem.SelectedText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 ngày %2';
				|ru = '%1 от %2';
				|en = '%1 dated %2'; fa = '%1 dated %2';
				|it = '%1 del %2';
				|pl = '%1 z dn. %2';
				|tr = '%2 tarihli %1'"), "[" + FilesAndEmailTextParameters.MailingDescription + "]",
			"[" + FilesAndEmailTextParameters.ExecutionDate + "()]");
		
		Variables1 = ReportDescriptionTemplateChoiceVariables("DescriptionDistributionDate", False);
		Variables1.Item = CurrentItem;
		Variables1.Prefix = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 ngày %2';
				|ru = '%1 от %2';
				|en = '%1 dated %2'; fa = '%1 dated %2';
				|it = '%1 del %2';
				|pl = '%1 z dn. %2';
				|tr = '%2 tarihli %1'"), "[" + FilesAndEmailTextParameters.MailingDescription + "]",
			"[" + FilesAndEmailTextParameters.ExecutionDate + "(");
		Variables1.Postfix = ")]";
		Variables1.ShouldChangeReportDescriptionTemplate = False;
		
		Handler = New CallbackDescription("AddChangeMailingDateTemplateCompletion", ThisObject, Variables1);

		Dialog = New FormatStringWizard;
		Dialog.AvailableTypes = New TypeDescription("Date");
		Dialog.Text         = Variables1.FormatText;
		Dialog.Show(Handler);		
	EndIf;
	
EndProcedure

&AtClient
Procedure ArchivePasswordOnChange(Item)
	ArchivePasswordChanged = True;
	
	CheckOnSetArchivePasswordInsertReportsToEmailText();
	
EndProcedure

&AtClient
Procedure ArchivePasswordStartChoice(Item, ChoiceData, StandardProcessing)
	
	EmailOperationsClient.PasswordFieldStartChoice(Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_EncryptionCertificateOnChange(Item)
	EncryptionCertificateChanged = True;

	If ValueIsFilled(ThisObject["CertificateToEncrypt"]) And Object.ShouldInsertReportsIntoEmailBody 
		And Object.ShouldAttachReports Then

		QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionParameters.PromptDontAskAgain = False;
		
		QuestionButtons = New ValueList;
		QuestionButtons.Add("InstallEncryptionCertificate", NStr("vi = 'Cài đặt chứng thư để mã hóa';
																|ru = 'Установить сертификат для шифрования';
																|en = 'Install encryption certificate'; fa = 'Install encryption certificate';
																|it = 'Установить сертификат для шифрования';
																|pl = 'Install encryption certificate';
																|tr = 'Şifreleme için sertifika yükle'"));
		QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
															|ru = 'Отмена';
															|en = 'Cancel'; fa = 'انصراف';
															|it = 'Отмена';
															|pl = 'Cancel';
															|tr = 'İptal'"));
		QueryText = NStr(
			"vi = 'Để cài đặt chứng thư mã hóa, cần xóa báo cáo khỏi nội dung thư.';
			|ru = 'Для того чтобы установить сертификат для шифрования, необходимо убрать отчеты из текста письма.';
			|en = 'To install the encryption certificate, remove the reports from the email text.'; fa = 'To install the encryption certificate, remove the reports from the email text.';
			|it = 'Для того чтобы установить сертификат для шифрования, необходимо убрать отчеты из текста письма.';
			|pl = 'To install the encryption certificate, remove the reports from the email text.';
			|tr = 'Şifreleme sertifikası yüklemek için ileti metninden raporları kaldırmanız gerekmektedir.'");
		QuestionParameters.DefaultButton = "InstallEncryptionCertificate";

		StandardSubsystemsClient.ShowQuestionToUser(
			New CallbackDescription("AfterAnswerQuestionPasswordEncryptionReportsInEmailText", ThisObject), QueryText,
			QuestionButtons, QuestionParameters);
	EndIf;

EndProcedure

&AtClient
Procedure ShouldSetPasswordsAndEncryptOnChange(Item)

	SetCertificatePasswordsVisibilityAndAvailability(ThisObject);
	
	If Not Object.ShouldInsertReportsIntoEmailBody And Object.ShouldSetPasswordsAndEncrypt Then
		OpenFormPasswordsEncryption();
	ElsIf Object.ShouldInsertReportsIntoEmailBody And Object.ShouldSetPasswordsAndEncrypt Then
		QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.PromptDontAskAgain = False;

		If CanEncryptAttachments Then
			If Object.Archive Then
				QuestionButtons = New ValueList;
				QuestionButtons.Add("ShouldSetPasswordsAndEncrypt", NStr("vi = 'Đặt mật khẩu và mã hóa';
																		|ru = 'Установить пароли и зашифровать';
																		|en = 'Set passwords and encrypt data'; fa = 'تعیین رمز عبور و رمزگذاری داده‌ها';
																		|it = 'Установить пароли и зашифровать';
																		|pl = 'Set passwords and encrypt data';
																		|tr = 'Parolaları yapılandır ve şifrele'"));
				QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																	|ru = 'Отмена';
																	|en = 'Cancel'; fa = 'انصراف';
																	|it = 'Отмена';
																	|pl = 'Cancel';
																	|tr = 'İptal'"));
				QueryText = NStr("vi = 'Để đặt mật khẩu và mã hóa, cần xóa báo cáo khỏi nội dung thư.';
								|ru = 'Для того чтобы установить пароли и зашифровать, необходимо убрать отчеты из текста письма.';
								|en = 'To set the passwords and encrypt data, remove the reports from the email text.'; fa = 'To set the passwords and encrypt data, remove the reports from the email text.';
								|it = 'Для того чтобы установить пароли и зашифровать, необходимо убрать отчеты из текста письма.';
								|pl = 'To set the passwords and encrypt data, remove the reports from the email text.';
								|tr = 'Parolaları ayarlamak ve şifrelemek için ileti metninden raporları kaldırmanız gerekmektedir.'");
				QuestionParameters.DefaultButton = "ShouldSetPasswordsAndEncrypt";
			Else
				QuestionButtons = New ValueList;
				QuestionButtons.Add("ShouldSetPasswordsAndEncrypt", NStr("vi = 'Mã hóa';
																		|ru = 'Зашифровать';
																		|en = 'Encrypt data'; fa = 'Encrypt data';
																		|it = 'Зашифровать';
																		|pl = 'Encrypt data';
																		|tr = 'Şifrele'"));
				QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																	|ru = 'Отмена';
																	|en = 'Cancel'; fa = 'انصراف';
																	|it = 'Отмена';
																	|pl = 'Cancel';
																	|tr = 'İptal'"));
				QueryText = NStr("vi = 'Để mã hóa báo cáo, cần xóa báo cáo khỏi nội dung thư.';
								|ru = 'Для того чтобы зашифровать отчеты, необходимо убрать отчеты из текста письма.';
								|en = 'To encrypt the reports, remove them from the email text.'; fa = 'To encrypt the reports, remove them from the email text.';
								|it = 'Для того чтобы зашифровать отчеты, необходимо убрать отчеты из текста письма.';
								|pl = 'To encrypt the reports, remove them from the email text.';
								|tr = 'Raporları şifrelemek için ileti metninden raporları kaldırmanız gerekmektedir.'");
				QuestionParameters.DefaultButton = "Encrypt";
			EndIf;
		ElsIf Object.Archive Then
			QuestionButtons = New ValueList;
			QuestionButtons.Add("ShouldSetPasswordsAndEncrypt", NStr("vi = 'Đặt mật khẩu';
																	|ru = 'Установить пароли';
																	|en = 'Set passwords'; fa = 'تعیین رمزهای عبور';
																	|it = 'Установить пароли';
																	|pl = 'Set passwords';
																	|tr = 'Şifreyi kur'"));
			QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																|ru = 'Отмена';
																|en = 'Cancel'; fa = 'انصراف';
																|it = 'Отмена';
																|pl = 'Cancel';
																|tr = 'İptal'"));
			QueryText = NStr("vi = 'Để đặt mật khẩu, cần xóa báo cáo khỏi nội dung thư.';
							|ru = 'Для того чтобы установить пароли, необходимо убрать отчеты из текста письма.';
							|en = 'To set the passwords, remove the reports from the email text.'; fa = 'To set the passwords, remove the reports from the email text.';
							|it = 'Для того чтобы установить пароли, необходимо убрать отчеты из текста письма.';
							|pl = 'To set the passwords, remove the reports from the email text.';
							|tr = 'Parolaları ayarlamak için ileti metninden raporları kaldırmanız gerekmektedir.'");
			QuestionParameters.DefaultButton = "SetPasswords";
		EndIf;
		StandardSubsystemsClient.ShowQuestionToUser(
			New CallbackDescription("SetPasswordsReportsInEmailBodyAfterQuestionAnswered", ThisObject), QueryText,
			QuestionButtons, QuestionParameters);
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersReports

&AtClient
Procedure ReportsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	
	FillingStructure = New Structure;
	FillingStructure.Insert("Formats", "");
	FillingStructure.Insert("SendIfEmpty", False);
	FillingStructure.Insert("DoNotSendIfEmpty", True);
	FillingStructure.Insert("Enabled", True);  
	FillingStructure.Insert("DescriptionTemplate", "[" + FilesAndEmailTextParameters.ReportDescription1
		+ "] [" + FilesAndEmailTextParameters.ReportFormat + "]");
	
	NewRowArray = ChoicePickupDragToTabularSection(
		ValueSelected,
		Object.Reports,
		"Report",
		FillingStructure,
		True);
	
	Template = New FixedStructure("Count, RowsArray, ReportsPresentations, Text", 0, Undefined, "");
	ChoiceStructure = New Structure;
	ChoiceStructure.Insert("SelectedItemsCount",   New Structure(Template));
	ChoiceStructure.Insert("Success",   New Structure(Template));
	ChoiceStructure.Insert("WithErrors", New Structure(Template));
	ChoiceStructure.SelectedItemsCount.RowsArray   = NewRowArray;
	ChoiceStructure.Success.RowsArray   = New Array;
	ChoiceStructure.WithErrors.RowsArray = New Array;
	
	// Initialize the added report rows and fill the selection structure.
	CheckAddedReportRows(ChoiceStructure);
	
	If ChoiceStructure.WithErrors.Count > 0 Then
		
		If ChoiceStructure.SelectedItemsCount.Count = 1 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không đưa được báo cáo vào danh sách gửi thư vì lý do:
					|%1';
					|ru = 'Не удалось включить отчет в рассылку по причине:
					|%1';
					|en = 'Cannot include the report in the distribution. Reason:
					|%1'; fa = 'Cannot include the report in the distribution. Reason:
					|%1';
					|it = 'Impossibile includere il report in mailing list a causa di:
					|%1';
					|pl = 'Nie udało się dołączyć raport do rozsyłania z powodu: 
					|%1';
					|tr = '
					|%1 sebebiyle rapor Bültene eklenemiyor.'"), ChoiceStructure.WithErrors.Text);
		ElsIf ChoiceStructure.Success.Count = 0 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không đưa được báo cáo vào danh sách gửi thư vì lý do:
					|%1';
					|ru = 'Не удалось включить отчеты в рассылку по причине:
					|%1';
					|en = 'Cannot include the reports in the distribution. Reason:
					|%1'; fa = 'Cannot include the reports in the distribution. Reason:
					|%1';
					|it = 'Impossibile includere i report in mailing list a causa di:
					|%1';
					|pl = 'Nie udało się dołączyć raporty do rozsyłania z powodu: 
					|%1';
					|tr = '
					|%1 sebebiyle raporlar Bültene eklenemiyor.'"), ChoiceStructure.WithErrors.Text);
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Các báo cáo có trong danh sách gửi thư: %1 từ %2
					|Chi tiết:
					|%3';
					|ru = 'В рассылку включено отчетов: %1 из %2
					|Подробности:
					|%3';
					|en = 'Reports included in distribution: %1 out of %2.
					|Details:
					|%3'; fa = 'Reports included in distribution: %1 out of %2.
					|Details:
					|%3';
					|it = 'Report inclusi in mailing list: %1di %2
					|Dettagli:
					|%3';
					|pl = 'Do rozsyłanie dołączono raportów: %1 z %2
					|Więcej:
					|%3';
					|tr = 'Bültene eklenen raporlar: %2
					|''dan %1Detaylar:
					|%3'"),
				Format(ChoiceStructure.Success.Count, "NZ=0; NG="),
				Format(ChoiceStructure.SelectedItemsCount.Count, "NZ=0; NG="), 
				ChoiceStructure.WithErrors.Text);
		EndIf;
		ShowMessageBox(Undefined, MessageText);
		
	Else
		
		If ChoiceStructure.Success.Count = 0 Then
			NotificationTitle = Undefined;
			NotificationText1 = NStr("vi = 'Đã thêm tất cả báo cáo được chọn vào danh sách gửi.';
									|ru = 'Все выбранные отчеты уже включены в рассылку.';
									|en = 'All the selected reports are already included in the distribution.'; fa = 'All the selected reports are already included in the distribution.';
									|it = 'Все выбранные отчеты уже включены в рассылку.';
									|pl = 'All the selected reports are already included in the distribution.';
									|tr = 'Tüm seçilen raporlar zaten bültene eklenmiştir.'");
		Else
			If ChoiceStructure.SelectedItemsCount.Count = 1 Then
				NotificationTitle = NStr("vi = 'Báo cáo đã được đưa vào danh sách gửi';
										|ru = 'Отчет включен в рассылку';
										|en = 'The report is included in the distribution.'; fa = 'The report is included in the distribution.';
										|it = 'Il report è presente in mailing list';
										|pl = 'Raport zostały włączony do subskrypcji';
										|tr = 'Rapor, bültene eklendi'");
			Else
				NotificationTitle = NStr("vi = 'Đã đưa báo cáo vào danh sách gửi';
										|ru = 'Отчеты включены в рассылку';
										|en = 'The reports are included in the distribution.'; fa = 'The reports are included in the distribution.';
										|it = 'I report sono presenti in mailing list';
										|pl = 'Raport został włączony do subskrypcji';
										|tr = 'Raporlar, bültene eklendi'");
			EndIf;
			NotificationText1 = ChoiceStructure.Success.ReportsPresentations;
		EndIf;
		
		ShowUserNotification(
			NotificationTitle,
			,
			NotificationText1,
			PictureLib.Success32);
		
	EndIf;
	CheckPeriodsInReports(ChoiceStructure.Success.RowsArray);
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "Reports");
EndProcedure

&AtClient
Procedure ReportsOnActivateRow(Item)
	AttachIdleHandler("ReportsTableRowActivationHandler", 0.1, True);
EndProcedure

&AtClient
Procedure ReportsTableRowActivationHandler()
	ReportsRow = Items.Reports.CurrentData;
	If ReportsRow = Undefined Then
		Items.ReportSettingsPages.CurrentPage = Items.PageEmpty;
		Return;
	EndIf;
	
	RowID = ReportsRow.GetID();
	If RowID = CurrentRowIDOfReportsTable Then
		Return;
	EndIf;
	WarningText = ReportsOnActivateRowAtServer(RowID);
	If WarningText <> "" Then
		ShowMessageBox(, WarningText);
	EndIf;
	
	UpdatePersonalizedDistributionRecipientParameterValue();
	
EndProcedure

&AtClient
Procedure ReportsBeforeRowChange(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure ReportsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	Cancel = True;
EndProcedure

&AtClient
Procedure ReportsAfterDeleteRow(Item)
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "Reports");
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUserSettings

&AtClient
Procedure UserSettingsOnChange(Item)
	ReportsRow = Items.Reports.CurrentData;
	If ReportsRow = Undefined Then
		Return;
	EndIf;
	
	ReportsRow.ChangesMade = True;
EndProcedure

&AtClient
Procedure UserSettingsOnActivateRow(Item)
	If Items.ReportSettingsPages.CurrentPage <> Items.ComposerPage Then
		Return;
	EndIf;
	Report = Items.Reports.CurrentData;
	If Report = Undefined Or TypeOf(Report.Report) <> Type("CatalogRef.ReportsOptions") Then
		Return;
	EndIf;
	DCID = Items.UserSettings.CurrentRow;
	ValueViewOnly = False;
	ReportMailingClientOverridable.OnActivateRowSettings(Report, DCSettingsComposer, DCID, ValueViewOnly);
	If Items.UserSettingsValue.ReadOnly <> ValueViewOnly Then
		Items.UserSettingsValue.ReadOnly = ValueViewOnly;
	EndIf;
EndProcedure

&AtClient
Procedure UserSettingsValueStartChoice(Item, ChoiceData, StandardProcessing)
	UserSettingStartChoice(StandardProcessing);
EndProcedure

&AtClient
Procedure UserSettingsValueClearing(Item, StandardProcessing)
	If Items.ReportSettingsPages.CurrentPage <> Items.ComposerPage Then
		Return;
	EndIf;
	Report = Items.Reports.CurrentData;
	If Report = Undefined Or TypeOf(Report.Report) <> Type("CatalogRef.ReportsOptions") Then
		Return;
	EndIf;
	DCID = Items.UserSettings.CurrentRow;
	ReportMailingClientOverridable.OnSettingsClear(Report, DCSettingsComposer, DCID, StandardProcessing);
EndProcedure

&AtClient
Procedure UserSettingsSelection(Item, RowSelected, Field, StandardProcessing)
	UserSettingStartChoice(StandardProcessing);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCurrentReportSettings

&AtClient
Procedure CurrentReportSettingsValueOnChange(Item)
	SettingsString = Items.CurrentReportSettings.CurrentData;
	If SettingsString = Undefined Then
		Return;
	EndIf;
	
	SettingsString.Use = True;
EndProcedure

&AtClient
Procedure CurrentReportSettingsOnChange(Item)
	ReportsRow = Items.Reports.CurrentData;
	If ReportsRow = Undefined Then
		Return;
	EndIf;
	
	ReportsRow.ChangesMade = True;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReportFormats

&AtClient
Procedure ReportFormatsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure ReportFormatsBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure ReportFormatsFormatsStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	ReportsRow = Items.ReportFormats.CurrentData;
	If ReportsRow = Undefined Then
		Return;
	EndIf;
	
	Variables1 = New Structure;
	Variables1.Insert("ReportsRow", ReportsRow);
	
	Handler = New CallbackDescription("ReportFormatsEndChoiceFormat", ThisObject, Variables1);
	
	ChooseFormat(ReportsRow.Report, Handler);
EndProcedure

&AtClient
Procedure ReportFormatsFormatsClearing(Item, StandardProcessing)
	StandardProcessing = False;
	ReportsRow = Items.ReportFormats.CurrentData;
	If ReportsRow = Undefined Then
		Return;
	EndIf;
	
	ClearFormat(ReportsRow.Report);
	ReportsRow.Formats = "";
EndProcedure

&AtClient
Procedure ReportFormatsSendIfEmptyOnChange(Item)
	CurrentData = Items.ReportFormats.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	CurrentData.DoNotSendIfEmpty = Not CurrentData.SendIfEmpty;
EndProcedure

&AtClient
Procedure ReportFormatsDoNotSendIfEmptyOnChange(Item)
	CurrentData = Items.ReportFormats.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	CurrentData.SendIfEmpty = Not CurrentData.DoNotSendIfEmpty;
EndProcedure

&AtClient
Procedure ReportFormatsOnActivateRow(Item)
	
	ReportsFormatsRow = Item.CurrentData;
	If ReportsFormatsRow = Undefined Then
		Return;
	EndIf;
	
	Items.ReportsFormatsDescriptionTemplate.ChoiceList.Clear();
	Items.ReportsFormatsDescriptionTemplate.ChoiceList.Add("ReportDescription1", NStr("vi = 'Tên báo cáo';
																						|ru = 'Наименование отчета';
																						|en = 'Report name'; fa = 'نام گزارش';
																						|it = 'Наименование отчета';
																						|pl = 'Report name';
																						|tr = 'Rapor tanımı'"));
	Items.ReportsFormatsDescriptionTemplate.ChoiceList.Add("ReportDescriptionFormat", NStr("vi = 'Tên báo cáo, định dạng';
																							|ru = 'Наименование отчета, формат';
																							|en = 'Report name, format'; fa = 'نام گزارش، قالب';
																							|it = 'Наименование отчета, формат';
																							|pl = 'Report name, format';
																							|tr = 'Rapor tanımı, format'"));
	If ReportsFormatsRow.ThereIsPeriod Then
		Items.ReportsFormatsDescriptionTemplate.ChoiceList.Add("DescriptionPeriod", NStr("vi = 'Tên báo cáo, kỳ';
																						|ru = 'Наименование отчета, период';
																						|en = 'Report name, period'; fa = 'نام گزارش، دوره';
																						|it = 'Наименование отчета, период';
																						|pl = 'Report name, period';
																						|tr = 'Rapor tanımı, dönem'"));
		Items.ReportsFormatsDescriptionTemplate.ChoiceList.Add("DescriptionPeriodFormat", NStr("vi = 'Tên báo cáo, kỳ, định dạng';
																								|ru = 'Наименование отчета, период, формат';
																								|en = 'Report name, period, format'; fa = 'نام گزارش، دوره، قالب';
																								|it = 'Наименование отчета, период, формат';
																								|pl = 'Report name, period, format';
																								|tr = 'Rapor tanımı, dönem, format'"));
	EndIf;
	Items.ReportsFormatsDescriptionTemplate.ChoiceList.Add("DescriptionDistributionDate", NStr("vi = 'Tên báo cáo, ngày gửi hàng loạt';
																								|ru = 'Наименование отчета, дата рассылки';
																								|en = 'Report name, report distribution date'; fa = 'نام گزارش، تاریخ توزیع گزارش';
																								|it = 'Наименование отчета, дата рассылки';
																								|pl = 'Report name, report distribution date';
																								|tr = 'Rapor tanımı, bülten tarihi'"));
	Items.ReportsFormatsDescriptionTemplate.ChoiceList.Add("DescriptionDistributionDateFormat", NStr("vi = 'Tên báo cáo, ngày gửi hàng loạt, định dạng';
																									|ru = 'Наименование отчета, дата рассылки, формат';
																									|en = 'Report name, report distribution date, format'; fa = 'نام گزارش، تاریخ توزیع گزارش، قالب';
																									|it = 'Наименование отчета, дата рассылки, формат';
																									|pl = 'Report name, report distribution date, format';
																									|tr = 'Rapor tanımı, bülten tarihi, format'"));

EndProcedure

&AtClient
Procedure ReportsFormatsDescriptionTemplateChoiceProcessing(Item, ValueSelected, StandardProcessing)

	StandardProcessing = False;
	SetDescriptionTemplates(ValueSelected);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region CommandBar

&AtClient
Procedure CommandSaveAndClose(Command)
	WriteParameters = New Structure;
	WriteParameters.Insert("CommandName", "CommandSaveAndClose");
	WriteAtClient(Undefined, WriteParameters);
EndProcedure

&AtClient
Procedure BulkEmailRecipientsClick(Item, StandardProcessing)
	StandardProcessing = False;
	
	If Not ValueIsFilled(Object.MailingRecipientType) Then
		ErrorText = NStr("vi = 'Để nhập người nhận, hãy chọn kiểu người nhận.';
						|ru = 'Для ввода получателей выберите их тип.';
						|en = 'To enter recipients, select their type.'; fa = 'To enter recipients, select their type.';
						|it = 'Для ввода получателей выберите их тип.';
						|pl = 'To enter recipients, select their type.';
						|tr = 'Alıcıları girmek için türlerini seçin.'");
		CommonClient.MessageToUser(ErrorText, , "MailingRecipientType");
		Return;
	EndIf;
	
	Handler = New CallbackDescription("BulkEmailRecipientsClickCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Recipients", Object.Recipients);
	FormParameters.Insert("MailingRecipientType", MailingRecipientType);
	FormParameters.Insert("RecipientsEmailAddressKind", Object.RecipientsEmailAddressKind);
	FormParameters.Insert("MailingDescription", Object.Description);
	
	OpenForm("Catalog.ReportMailings.Form.BulkEmailRecipients", FormParameters, , , , , Handler);
EndProcedure

&AtClient
Procedure CommandWrite(Command)
	WriteParameters = New Structure;
	WriteParameters.Insert("CommandName", "CommandWrite");
	WriteAtClient(Undefined, WriteParameters);
EndProcedure

&AtClient
Procedure ExecuteNowCommand(Command)
	If Not Object.IsPrepared Then
		ShowMessageBox(, NStr("vi = 'Chưa chuẩn bị danh sách gửi.';
								|ru = 'Рассылка не подготовлена.';
								|en = 'The report distribution is not prepared.'; fa = 'The report distribution is not prepared.';
								|it = 'Рассылка не подготовлена.';
								|pl = 'The report distribution is not prepared.';
								|tr = 'Bülten hazırlanmadı.'"));
		Return;
	EndIf;
	WriteParameters = New Structure;
	WriteParameters.Insert("CommandName", "ExecuteNowCommand");
	WriteAtClient(Undefined, WriteParameters);
EndProcedure

&AtClient
Procedure MailingEventsCommand(Command)
	WriteParameters = New Structure;
	WriteParameters.Insert("CommandName", "MailingEventsCommand");
	WriteAtClient(Undefined, WriteParameters);
EndProcedure

&AtClient
Procedure Redistribution(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Ref", Object.Ref);
	CallbackDescription = New CallbackDescription("AfterCloseRedistribution", ThisObject);
	OpenForm("Catalog.ReportMailings.Form.ResendReports", FormParameters, ThisObject, , , , CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

#EndRegion

#Region ReportsPage

&AtClient
Procedure AddReport(Command)
	SelectedValues = New ValueList;
	For Each ReportsRow In Object.Reports Do
		If TypeOf(ReportsRow.Report) = Type("CatalogRef.ReportsOptions") Then
			SelectedValues.Add(ReportsRow.Report);
		EndIf;
	EndDo;
	
	ChoiceFilter = New Structure;
	ChoiceFilter.Insert("ReportType", 1);
	ChoiceFilter.Insert("Report", New Structure("Kind, Value", "NotInList", Cache.ReportsToExclude));
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("WindowOpeningMode",  FormWindowOpeningMode.LockOwnerWindow);
	ChoiceFormParameters.Insert("ChoiceMode",        True);
	ChoiceFormParameters.Insert("MultipleChoice", True);
	ChoiceFormParameters.Insert("CloseOnChoice", False);
	ChoiceFormParameters.Insert("Filter",              ChoiceFilter);
	ChoiceFormParameters.Insert("SelectedValues",  SelectedValues);
	
	OpenForm("Catalog.ReportsOptions.ChoiceForm", ChoiceFormParameters, Items.Reports);
EndProcedure

&AtClient
Procedure AddAdditionalReport(Command)
	// Additional reports pickup form.
	If CommonClient.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		ModuleAdditionalReportsAndDataProcessorsClient = CommonClient.CommonModule("AdditionalReportsAndDataProcessorsClient");
		ModuleAdditionalReportsAndDataProcessorsClient.ReportDistributionPickAddlReport(Items.Reports);
	EndIf;
EndProcedure

&AtClient
Procedure ReportPreview(Command)
	
	ClearMessages();
	
	ReportsRow = Items.Reports.CurrentData;
	If ReportsRow = Undefined Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn báo cáo';
								|ru = 'Выберите отчет';
								|en = 'Select report'; fa = 'Select report';
								|it = 'Selezionare rapporto';
								|pl = 'Wybierz raport';
								|tr = 'Rapor seç'"));
		Return;
	EndIf;
	If Not ReportsRow.Enabled Then
		ShowMessageBox(, ReportsRow.Presentation);
		Return;
	EndIf;
	
	ReportParameters = New Structure;
	ReportParameters.Insert("Report",                ReportsRow.Report);
	ReportParameters.Insert("Settings",            Undefined);
	ReportParameters.Insert("SendIfEmpty", ReportsRow.SendIfEmpty);
	ReportParameters.Insert("Formats",              New Array);
	ReportParameters.Insert("Presentation",        ReportsRow.Presentation);
	ReportParameters.Insert("FullName",            ReportsRow.FullName);
	ReportParameters.Insert("VariantKey",         ReportsRow.VariantKey);
	
	If ReportsRow.DCS Then
		ReportParameters.Settings = DCSettingsComposer.UserSettings;
	Else
		Settings = New Array;
		FoundItems = CurrentReportSettings.FindRows(New Structure("Use", True));
		For Each SettingRow In FoundItems Do
			SettingToAdd = New Structure("Attribute, Value", SettingRow.Attribute, SettingRow.Value);
			Settings.Add(SettingToAdd);
		EndDo;
		ReportParameters.Settings = Settings;
	EndIf;
	
	If Object.Personalized Then
		If Not RecipientsSpecified(Object.Recipients) Then
			Return;
		EndIf;
		Handler = New CallbackDescription("ReportPreviewContinued", ThisObject, ReportParameters);
		ReportMailingClient.SelectRecipient(Handler, Object, False, False);
	Else
		ReportPreviewContinued(Undefined, ReportParameters);
	EndIf;
EndProcedure

&AtClient
Procedure ReportPreviewContinued(SelectionResult, ReportParameters) Export
	DCUserSettings = ReportParameters.Settings;
	Filter = New Structure("Use, Value", True, MailingRecipientValueTemplate(FilesAndEmailTextParameters));
	PersonalizedSettings = ReportsClientServer.SettingsItemsFiltered(DCUserSettings, Filter);
	If Object.Personalized Then
		If SelectionResult = Undefined Then
			Return;
		Else
			Recipient = SelectionResult.Recipient;
		EndIf;
		For Each DCUserSetting In PersonalizedSettings Do
			If TypeOf(DCUserSetting) = Type("DataCompositionFilterItem") Then
				DCUserSetting.RightValue = Recipient;
			ElsIf TypeOf(DCUserSetting) = Type("DataCompositionSettingsParameterValue") Then
				DCUserSetting.Value = Recipient;
			EndIf;
		EndDo;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("UserSettings", DCUserSettings);
	FormParameters.Insert("GenerateOnOpen", True);
	
	ReportsOptionsClient.OpenReportForm(ThisObject, ReportParameters.Report, FormParameters);
	
	For Each DCUserSetting In PersonalizedSettings Do
		If TypeOf(DCUserSetting) = Type("DataCompositionFilterItem") Then
			DCUserSetting.RightValue = MailingRecipientValueTemplate(FilesAndEmailTextParameters);
		ElsIf TypeOf(DCUserSetting) = Type("DataCompositionSettingsParameterValue") Then
			DCUserSetting.Value = MailingRecipientValueTemplate(FilesAndEmailTextParameters);
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure SpecifyMailingRecipient(Command)
	ClearMessages();
	
	// Check - whether the possibility to personalize the mailing enabled.
	If Not Object.Personalized Then
		KindPresentaion = Items.BulkEmailType.ChoiceList.FindByValue("Personalized").Presentation;
		TheMessageText = NStr("vi = 'Chỉ có thể sử dụng người nhận trong các tham số đối với dạng gửi hàng loạt ""%1"".';
								|ru = 'Использовать получателя в параметрах возможно только для вида рассылки ""%1"".';
								|en = 'You can specify recipients in parameters only if the distribution type is ""%1"".'; fa = 'You can specify recipients in parameters only if the distribution type is ""%1"".';
								|it = 'Использовать получателя в параметрах возможно только для вида рассылки ""%1"".';
								|pl = 'You can specify recipients in parameters only if the distribution type is ""%1"".';
								|tr = 'Alıcı sadece ""%1"" bülten türü için parametrelerde kullanılabilir.'");
		TheMessageText = StringFunctionsClientServer.SubstituteParametersToString(TheMessageText, KindPresentaion);
		CommonClient.MessageToUser(TheMessageText, , "BulkEmailType");
		Return;
	EndIf;
	
	// Get the main type of recipients.
	TypesCount = MailingRecipientType.Types().Count();
	If TypesCount < 1 Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Người nhận"".';
										|ru = 'Поле ""Получатели"" не заполнено.';
										|en = 'The ""Recipients"" field is required.'; fa = 'The ""Recipients"" field is required.';
										|it = 'Поле ""Получатели"" не заполнено.';
										|pl = 'The ""Recipients"" field is required.';
										|tr = '""Alıcılar"" alanı doldurulmadı.'"), , "MailingRecipientType");
		Return;
	EndIf;
	
	FoundMetadataObjectIDs = RecipientsTypesTable.FindRows(New Structure("RecipientsType", MailingRecipientType));
	If FoundMetadataObjectIDs.Count() <> 1 Then
		ShowMessageBox(, NStr("vi = 'Loại người nhận không hợp lệ.';
								|ru = 'Некорректный тип получателей.';
								|en = 'Incorrect recipient type.'; fa = 'Incorrect recipient type.';
								|it = 'Tipo errato di riceventi.';
								|pl = 'Niepoprawny typ odbiorców.';
								|tr = 'Geçersiz alıcı türü.'"));
		Return;
	EndIf;
	
	TypesArray = FoundMetadataObjectIDs[0].MainType.Types();
	If TypesArray.Count() <> 1 Then
		ShowMessageBox(, NStr("vi = 'Loại người nhận không hợp lệ.';
								|ru = 'Некорректный тип получателей.';
								|en = 'Incorrect recipient type.'; fa = 'Incorrect recipient type.';
								|it = 'Tipo errato di riceventi.';
								|pl = 'Niepoprawny typ odbiorców.';
								|tr = 'Geçersiz alıcı türü.'"));
		Return;
	EndIf;
	
	MainRecipientsType = TypesArray[0];
	
	Setting = IdentifySetting();
	If Setting = Undefined Then
		Return;
	EndIf;
	
	// Recipients type content check.
	If Not Setting.DetailsOfAvailableTypes.ContainsType(MainRecipientsType) Then
		WarningText = NStr("vi = 'Kiểu ""%1"" không phù hợp về kiểu đối với tùy chỉnh đã chọn.
			|Hãy chọn kiểu người nhận hàng loạt khác hoặc tùy chỉnh khác.';
			|ru = 'Тип ""%1"" не подходит по типу к выбранной настройке.
			|Выберите другой тип получателей рассылки или другую настройку.';
			|en = 'Type ""%1"" is not suitable for the selected setting.
			|Select another recipient type or setting.'; fa = 'Type ""%1"" is not suitable for the selected setting.
			|Select another recipient type or setting.';
			|it = 'Il tipo ""%1"" non corrisponde per tipo all''impostazione selezionata.
			|Selezionare un altro tipo di destinatari della newsletter o un''altra impostazione.';
			|pl = 'Typ ""%1"" nie jest zgodny z wybranym ustawieniem.
			|Wybierz inny typ odbiorców subskrypcji lub inne ustawienie.';
			|tr = '""%1"" türü, seçilen ayarın tipiyle eşleşmiyor.
			|Farklı bir posta alıcısı türü veya farklı bir ayar seçin.'");
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(WarningText, String(MainRecipientsType));
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	Setting.Initiator.EndEditRow(False);
	Setting.SettingsString.Use = True;
	If Setting.DCS Then
		If Setting.IsFilterItem Then
			If Setting.SettingsString.ComparisonType = DataCompositionComparisonType.InList
				Or Setting.SettingsString.ComparisonType = DataCompositionComparisonType.InHierarchy
				Or Setting.SettingsString.ComparisonType = DataCompositionComparisonType.InListByHierarchy
				Or Setting.SettingsString.ComparisonType = DataCompositionComparisonType.NotInList
				Or Setting.SettingsString.ComparisonType = DataCompositionComparisonType.NotInHierarchy
				Or Setting.SettingsString.ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
				Setting.SettingsString.ComparisonType = DataCompositionComparisonType.Equal;
			EndIf;
			Setting.SettingsString.RightValue = MailingRecipientValueTemplate(FilesAndEmailTextParameters);
		Else
			AvailableParameter = DCSettingsComposer.Settings.DataParameters.AvailableParameters.FindParameter(Setting.SettingsString.Parameter);
			If AvailableParameter <> Undefined And AvailableParameter.ValueListAllowed Then
				ValueAsList = New ValueList;
				ValueAsList.Add(MailingRecipientValueTemplate(FilesAndEmailTextParameters),
					MailingRecipientValueTemplate(FilesAndEmailTextParameters));
				Setting.SettingsString.Value = ValueAsList;
			Else	
				Setting.SettingsString.Value = MailingRecipientValueTemplate(FilesAndEmailTextParameters);
			EndIf;
		EndIf;
	Else
		Setting.SettingsString.Value = MailingRecipientValueTemplate(FilesAndEmailTextParameters);
	EndIf;
	
	FindPersonalizationSettings();
	
	MailingWasPersonalized = True;
	Items.Reports.CurrentData.ChangesMade = True;
	Modified = True;
	
EndProcedure

&AtClient
Procedure DeleteMailingRecipient(Command)
	ClearMessages();
	
	Setting = IdentifySetting();
	If Setting = Undefined Then
		Return;
	EndIf;
	
	Setting.Initiator.EndEditRow(False);
	ChangesMade = False;
	If Setting.DCS Then
		If Setting.IsFilterItem Then
			If Setting.SettingsString.RightValue = MailingRecipientValueTemplate(FilesAndEmailTextParameters) Then
				Setting.SettingsString.RightValue = Undefined;
				ChangesMade = True;
			EndIf;
		Else
			If Setting.SettingsString.Value = MailingRecipientValueTemplate(FilesAndEmailTextParameters) Then 
				Setting.SettingsString.Value = Undefined;
				ChangesMade = True;
			EndIf;
		EndIf;
	Else
		If Setting.SettingsString.Value = MailingRecipientValueTemplate(FilesAndEmailTextParameters) Then 
			Setting.SettingsString.Value = Undefined;
			ChangesMade = True;
		EndIf;
	EndIf;
	
	If ChangesMade Then
		Items.Reports.CurrentData.ChangesMade = True;
		Modified = True;
	EndIf;
EndProcedure

&AtClient
Function IdentifySetting()
	
	DCS = (Items.ReportSettingsPages.CurrentPage = Items.ComposerPage);
	If DCS Then
		Initiator = Items.UserSettings;
	Else
		Initiator = Items.CurrentReportSettings;
	EndIf;
	
	// Get details of the types available for selection.
	If DCS Then
		
		// User setting ID.
		SettingID = Initiator.CurrentRow;
		If SettingID = Undefined Then
			ShowMessageBox(, NStr("vi = 'Chưa chọn tùy chỉnh báo cáo.';
									|ru = 'Не выбрана настройка отчета.';
									|en = 'Report setting is not selected.'; fa = 'Report setting is not selected.';
									|it = 'Nessuna impostazione del report è selezionata.';
									|pl = 'Nie wybrano ustawienia raportu.';
									|tr = 'Rapor ayarı seçilmedi.'"));
			Return Undefined;
		EndIf;
		
		UserSettings = DCSettingsComposer.UserSettings;
		
		// Get a row from data composition settings.
		SettingsString = UserSettings.GetObjectByID(SettingID);
		If SettingsString = Undefined Then
			ShowMessageBox(, NStr("vi = 'Chưa chọn tùy chỉnh báo cáo.';
									|ru = 'Не выбрана настройка отчета.';
									|en = 'Report setting is not selected.'; fa = 'Report setting is not selected.';
									|it = 'Nessuna impostazione del report è selezionata.';
									|pl = 'Nie wybrano ustawienia raportu.';
									|tr = 'Rapor ayarı seçilmedi.'"));
			Return Undefined;
		EndIf;
		
		// Setting type check.
		If TypeOf(SettingsString) = Type("DataCompositionFilterItem") Then
			IsFilterItem = True;
		ElsIf TypeOf(SettingsString) = Type("DataCompositionSettingsParameterValue") Then
			IsFilterItem = False;
		Else
			ShowMessageBox(, NStr("vi = 'Chỉ có thể chỉ định người nhận đối với tham số và bộ lọc báo cáo.';
									|ru = 'Указывать получателя можно только для параметров и отборов отчетов.';
									|en = 'You can specify the recipient only for report parameters and filters.'; fa = 'You can specify the recipient only for report parameters and filters.';
									|it = 'È possibile specificare un destinatario solo per parametri e selezioni del report.';
									|pl = 'Wskazywanie odbiorcy jest możliwe tylko dla parametrów i filtrów raportów.';
									|tr = 'Sadece rapor parametreleri ve filtreleri için alıcı belirtebilirsiniz.'"));
			Return Undefined;
		EndIf;
		
		// Data composition field.
		If IsFilterItem Then
			FoundItems1 = UserSettings.GetMainSettingsByUserSettingID(
				SettingsString.UserSettingID);
			
			If FoundItems1.Count() > 0 Then 
				DCField = FoundItems1[0].LeftValue;
			Else
				
				DCField = DetermineFieldFromComposer(SettingID, DCSettingsComposer.Settings.Filter.Items);
				If DCField = Undefined Then
					DCField = DetermineFieldFromComposer(SettingID, UserSettings.Items);
				EndIf;
				If DCField = Undefined Then
					ShowMessageBox(, NStr("vi = 'Để tùy chỉnh báo cáo không có mô tả trường khả dụng.';
											|ru = 'Для настройки отчета не существует описания доступного поля.';
											|en = 'There is no details of an available field for the report setting.'; fa = 'There is no details of an available field for the report setting.';
											|it = 'Per l''impostazione del report non esiste la descrizione del campo disponibile.';
											|pl = 'Dla ustawienia raportu nie istnieje opisu dostępnego pola.';
											|tr = 'Raporu özelleştirmek için kullanılabilir alan açıklaması yok.'"));
					Return Undefined;
				EndIf;
				
			EndIf;
			AvailableDCField = DCSettingsComposer.Settings.Filter.FilterAvailableFields.FindField(DCField);
			
		Else
			AvailableDCField = DCSettingsComposer.Settings.DataParameters.AvailableParameters.FindParameter(SettingsString.Parameter);
		EndIf;
		
		If AvailableDCField = Undefined Then
			Return Undefined;
		EndIf;
		DetailsOfAvailableTypes = AvailableDCField.ValueType;
		
	Else
		
		// Types array for arbitrary reports.
		SettingsString = Initiator.CurrentData;
		If SettingsString = Undefined Then
			ShowMessageBox(, NStr("vi = 'Chưa chọn tùy chỉnh báo cáo.';
									|ru = 'Не выбрана настройка отчета.';
									|en = 'Report setting is not selected.'; fa = 'Report setting is not selected.';
									|it = 'Nessuna impostazione del report è selezionata.';
									|pl = 'Nie wybrano ustawienia raportu.';
									|tr = 'Rapor ayarı seçilmedi.'"));
			Return Undefined;
		EndIf;
		
		DetailsOfAvailableTypes = SettingsString.Type;
	EndIf;
	
	Result = New Structure;
	Result.Insert("DCS", DCS);
	Result.Insert("Initiator", Initiator);
	Result.Insert("DetailsOfAvailableTypes", DetailsOfAvailableTypes);
	Result.Insert("SettingsString", SettingsString);
	Result.Insert("IsFilterItem", IsFilterItem);
	Return Result;
	
EndFunction

&AtClient
Function DetermineFieldFromComposer(SettingID, Collection)
	For Each Item In Collection Do
		If String(Item.UserSettingID) = String(SettingID)
			And ValueIsFilled(String(Item.LeftValue)) Then
			Return Item.LeftValue;
		EndIf;
		
		If TypeOf(Item) = Type("DataCompositionFilterItemGroup")
			Or TypeOf(Item) = Type("DataCompositionFilter") Then
			Field = DetermineFieldFromComposer(SettingID, Item.Items);
			If Field <> Undefined Then
				Return Field;
			EndIf;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

#EndRegion

#Region SchedulePage

&AtClient
Procedure SelectCheckBoxes(Command)
	AllMonths = New Array;
	For Each KeyAndValue In Cache.Maps1.Months Do
		ThisObject[KeyAndValue.Key] = True;
		AllMonths.Add(KeyAndValue.Value);
	EndDo;
	Schedule.Months = AllMonths;
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "Months");
EndProcedure

&AtClient
Procedure ClearCheckBoxes(Command)
	AllMonths = New Array;
	For Each KeyAndValue In Cache.Maps1.Months Do
		ThisObject[KeyAndValue.Key] = False;
	EndDo;
	Schedule.Months = AllMonths;
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "Months");
EndProcedure

&AtClient
Procedure FillScheduleByTemplate(Command)
	Handler = New CallbackDescription("FillScheduleByTemplateCompletion", ThisObject);
	
	VariantList = ReportMailingClient.ScheduleFillingOptionsList();
	VariantList.ShowChooseItem(Handler, NStr("vi = 'Hãy chọn mẫu lịch biểu.';
											|ru = 'Выберите шаблон расписания.';
											|en = 'Select schedule template.'; fa = 'Select schedule template.';
											|it = 'Выберите шаблон расписания.';
											|pl = 'Select schedule template.';
											|tr = 'Program şablonu seçin.'"));
EndProcedure

#EndRegion

#Region DeliveryPage

&AtClient
Procedure AddChangeMailingDateTemplate(Command)
	AddLayout();
	
	Variables1 = ReportDescriptionTemplateChoiceVariables("", False);
	Variables1.Item = CurrentItem;
	Variables1.PreviousText1 = Variables1.Item.SelectedText;
	Variables1.Prefix = "[" + FilesAndEmailTextParameters.ExecutionDate + "(";
	Variables1.Postfix = ")]";
	Variables1.ShouldChangeReportDescriptionTemplate = False;
	
	PrefixLength  = StrLen(Variables1.Prefix);
	PrefixPosition  = StrFind(Variables1.PreviousText1, Variables1.Prefix);
	PostfixPosition = StrFind(Variables1.PreviousText1, Variables1.Postfix);
	Variables1.PreviousFragmentFound = (PrefixPosition > 0 And PostfixPosition > PrefixPosition);
	
	If Variables1.PreviousFragmentFound Then
		Variables1.FormatText = Mid(Variables1.PreviousText1, PrefixPosition + PrefixLength, PostfixPosition - PrefixPosition - PrefixLength);
	EndIf;
	
	Handler = New CallbackDescription("AddChangeMailingDateTemplateCompletion", ThisObject, Variables1);
	
	Dialog = New FormatStringWizard;
	Dialog.AvailableTypes = New TypeDescription("Date");
	Dialog.Text         = Variables1.FormatText;
	Dialog.Show(Handler);
	
EndProcedure

&AtClient
Procedure AddRecipientTemplate(Command)
	// Clean up message window.
	ClearMessages();
	
	//
	If Not Object.Personalized Then
		TheMessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chỉ có thể sử dụng người nhận trong nội dung khuôn mẫu đối với dạng gửi hàng loạt ""%1"".';
				|ru = 'Использование получателя в тексте шаблона возможно только для вида рассылки ""%1"".';
				|en = 'You can specify recipients in template body only if the distribution type is ""%1"".'; fa = 'You can specify recipients in template body only if the distribution type is ""%1"".';
				|it = 'Использование получателя в тексте шаблона возможно только для вида рассылки ""%1"".';
				|pl = 'You can specify recipients in template body only if the distribution type is ""%1"".';
				|tr = 'Alıcı sadece ""%1"" bülten türü için şablon metninde kullanılabilir.'"),
			Items.BulkEmailType.ChoiceList.FindByValue("Personalized").Presentation);
		CommonClient.MessageToUser(TheMessageText, , "BulkEmailType");
		Return;
	EndIf;
	
	AddLayout(MailingRecipientValueTemplate(FilesAndEmailTextParameters));
	MailingWasPersonalized = True;
EndProcedure

&AtClient
Procedure AddGeneratedReportsTemplate(Command)
	AddLayout("[" + FilesAndEmailTextParameters.GeneratedReports + "]", True);
EndProcedure

&AtClient
Procedure AddAuthorTemplate(Command)
	AddLayout("[" + FilesAndEmailTextParameters.Author + "]");
EndProcedure

&AtClient
Procedure AddMailingDescriptionTemplate(Command)
	AddLayout("[" + FilesAndEmailTextParameters.MailingDescription + "]");
EndProcedure

&AtClient
Procedure AddSystemTemplate(Command)
	AddLayout("[" + FilesAndEmailTextParameters.SystemTitle +  "]");
EndProcedure

&AtClient
Procedure AddDeliveryMethodTemplate(Command)
	AddLayout("[" + FilesAndEmailTextParameters.DeliveryMethod + "]");
EndProcedure

&AtClient
Procedure AddDefaultTemplate(Command)
	OverwriteSubject = (CurrentItem = Items.EmailSubject);
	
	If OverwriteSubject Then
		SubjectValue = Object.EmailSubject;
		DefaultTemplate = Cache.Templates.Subject;
	Else
		If Object.HTMLFormatEmail Then
			SubjectValue = EmailTextFormattedDocument.GetText();
		Else
			SubjectValue = Object.EmailText;
		EndIf;
		SubjectValue = TrimAll(SubjectValue);
		DefaultTemplate = Cache.Templates.Text;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("OverwriteSubject", OverwriteSubject);
	AdditionalParameters.Insert("DefaultTemplate", DefaultTemplate);
	
	If SubjectValue = "" Then
		// If the subject is empty, fill it in.
		AddDefaultTemplateCompletion(1, AdditionalParameters);
		
	ElsIf SubjectValue = DefaultTemplate Then
		// Subject matches the template — no fill required.
		
		If OverwriteSubject Then
			WarningText = NStr("vi = 'Chủ đề email tương ứng với khuôn mẫu theo mặc định.';
								|ru = 'Тема письма уже соответствует шаблону по умолчанию.';
								|en = 'Email subject already matches the default template.'; fa = 'Email subject already matches the default template.';
								|it = 'L''oggetto dell''email corrisponde già al modello predefinito.';
								|pl = 'Temat wiadomości odpowiada już domyślnemu szablonowi.';
								|tr = 'E-posta konusu zaten varsayılan şablona uyuyor.'");
		Else
			WarningText = NStr("vi = 'Nội dung email tương ứng với khuôn mẫu theo mặc định.';
								|ru = 'Текст письма уже соответствует шаблону по умолчанию.';
								|en = 'Email text already matches the default template.'; fa = 'Email text already matches the default template.';
								|it = 'Il testo dell''email corrisponde già al modello predefinito.';
								|pl = 'Tekst wiadomości odpowiada już domyślnemu szablonowi.';
								|tr = 'E-posta metni zaten varsayılan şablona uyuyor.'");
		EndIf;
		ShowMessageBox(, WarningText);
		
	Else
		// Subject is not empty - you need to ask a replacement for a standard template.
		
		If OverwriteSubject Then
			QuestionTitle = NStr("vi = 'Thêm khuôn mẫu mặc định vào chủ đề email';
								|ru = 'Добавить в тему письма шаблон по умолчанию';
								|en = 'Add default template to the email subject'; fa = 'Add default template to the email subject';
								|it = 'Aggiungere un modello predefinito all''oggetto dell''email';
								|pl = 'Dodaj do tematu wiadomości szablon domyślny';
								|tr = 'E-posta konusuna varsayılan şablon ekle'");
			QueryText = NStr("vi = 'Thay thế chủ đề email bằng khuôn mẫu mặc định?';
							|ru = 'Заменить тему письма на шаблон по умолчанию?';
							|en = 'Replace the email subject with the default template?'; fa = 'Replace the email subject with the default template?';
							|it = 'Sostituire l''oggetto dell''email con il modello predefinito?';
							|pl = 'Zamienić tekst wiadomoąci na szablon domyślny?';
							|tr = 'E-posta konusu varsayılan şablonla değiştirilsin mi?'");
		Else
			QuestionTitle = NStr("vi = 'Thêm khuôn mẫu mặc định vào nội dung email';
								|ru = 'Добавить в текст письма шаблон по умолчанию';
								|en = 'Add default template to the email body'; fa = 'Add default template to the email body';
								|it = 'Aggiungere un modello predefinito nel testo dell''email';
								|pl = 'Dodaj do tekstu wiadomości szablon domyślny';
								|tr = 'E-posta gövdesine varsayılan şablon ekle'");
			QueryText = NStr("vi = 'Thay thế nội dung email bằng khuôn mẫu mặc định?';
							|ru = 'Заменить текст письма на шаблон по умолчанию?';
							|en = 'Replace the email text with the default template?'; fa = 'Replace the email text with the default template?';
							|it = 'Sostituire il testo dell''email con il modello predefinito?';
							|pl = 'Zamienić tekst wiadomości na szablon domyślny?';
							|tr = 'E-posta metni varsayılan şablonla değiştirilsin mi?'");
		EndIf;
		
		Buttons = New ValueList;
		Buttons.Add(1, NStr("vi = 'Thay thế';
							|ru = 'Заменить';
							|en = 'Replace'; fa = 'جایگزینی';
							|it = 'Sostituire';
							|pl = 'Replace';
							|tr = 'Değiştir'"));
		Buttons.Add(2, NStr("vi = 'Thêm';
							|ru = 'Добавить';
							|en = 'Add'; fa = 'افزودن';
							|it = 'Aggiungere';
							|pl = 'Add';
							|tr = 'Ekle'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		Handler = New CallbackDescription("AddDefaultTemplateCompletion", ThisObject, AdditionalParameters);
		
		ShowQueryBox(Handler, QueryText, Buttons, 60, 1, QuestionTitle);
	EndIf;
	
EndProcedure

&AtClient
Procedure TemplatePreview(Command)
	AttachIdleHandler("OnOpenTemplatePreview", 0.1, True);
EndProcedure

&AtClient
Procedure CheckIfBulkEmailIsPossible(Command)
	
	DeliveryParameters = ReportMailingClientServer.DeliveryParameters();
	DeliveryParameters.ExecutionDate = CommonClient.SessionDate();
	DeliveryParameters.Author = Object.Author;
	DeliveryParameters.UseFolder = Object.UseFolder;
	DeliveryParameters.UseNetworkDirectory = Object.UseNetworkDirectory;
	DeliveryParameters.UseFTPResource = Object.UseFTPResource;
	DeliveryParameters.UseEmail = Object.UseEmail;
	
	CheckMailing(DeliveryParameters);
	
EndProcedure

&AtClient
Procedure ChangeTextTypeToHTML(Command)
	Modified = True;
	Object.HTMLFormatEmail = True;
	EmailTextFromHTML = TrimAll(EmailTextFormattedDocument.GetText());
	If EmailTextFromHTML <> Object.EmailText Then
		EmailTextFormattedDocument.Delete();
		EmailTextFormattedDocument.Add(Object.EmailText, FormattedDocumentItemType.Text);
	EndIf;
	CurrentItem = Items.EmailTextFormattedDocument;
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "HTMLFormatEmail");
EndProcedure

&AtClient
Procedure ChangeTextTypeToPlain(Command)
	Modified = True;
	Object.HTMLFormatEmail = False;
	EmailTextFromHTML = TrimAll(EmailTextFormattedDocument.GetText());
	If Object.EmailText <> EmailTextFromHTML Then
		Object.EmailText = EmailTextFromHTML;
	EndIf;
	CurrentItem = Items.EmailText;
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "HTMLFormatEmail");
EndProcedure

&AtClient
Procedure ImportanceHigh(Command)
	Object.EmailImportance = EmailOperationsInternalClientServer.InternetMailMessageImportanceHigh();
	Items.SeverityGroup.Picture = PictureLib.ImportanceHigh;
	Items.SeverityGroup.ToolTip = NStr("vi = 'Mức độ quan trọng cao';
										|ru = 'Высокая важность';
										|en = 'High importance'; fa = 'اهمیت بالا';
										|it = 'Alta importanza';
										|pl = 'Wysoka ważność';
										|tr = 'Yüksek önemlilik'");
	Modified = True;
EndProcedure

&AtClient
Procedure ImportanceNormal(Command)
	Object.EmailImportance = EmailOperationsInternalClientServer.InternetMailMessageImportanceStandard();
	Items.SeverityGroup.Picture = PictureLib.ImportanceNotSpecified;
	Items.SeverityGroup.ToolTip = NStr("vi = 'Mức độ quan trọng thường';
										|ru = 'Обычная важность';
										|en = 'Normal importance'; fa = 'اهمیت عادی';
										|it = 'Media importanza';
										|pl = 'Zwykła ważność';
										|tr = 'Normal önemlilik'");
	Modified = True;
EndProcedure

&AtClient
Procedure ImportanceLow(Command)
	Object.EmailImportance = EmailOperationsInternalClientServer.InternetMailMessageImportanceLow();
	Items.SeverityGroup.Picture = PictureLib.ImportanceLow;
	Items.SeverityGroup.ToolTip = NStr("vi = 'Mức độ quan trọng thấp';
										|ru = 'Низкая важность';
										|en = 'Low importance'; fa = 'اهمیت پایین';
										|it = 'Bassa importanza';
										|pl = 'Niska ważność';
										|tr = 'Az önemlilik'");
	Modified = True;
EndProcedure

&AtClient
Procedure Attachable_AddEmailTextAdditionalParameter(Command)

	If EmailTextAdditionalParameters = Undefined Then
		Return;
	EndIf;

	If Not EmailTextAdditionalParameters.Property(Command.Name) Then
		Return;
	EndIf;

	ParameterName = "[" + EmailTextAdditionalParameters[Command.Name].Name + "]";
	AddLayout(ParameterName);

EndProcedure

&AtClient
Procedure ShouldInsertReportsIntoEmailBodyOnChange(Item)

	If Object.ShouldInsertReportsIntoEmailBody Then
		Object.NotifyOnly = False;
		If Object.ShouldAttachReports Then
			CheckEncryptionBeforeIncludeReportsToEmailBody();
		EndIf;
	Else
		Object.ShouldAttachReports = True;
		SetVisibilityAvailabilityAndCorrectness(ThisObject, "ShouldAttachReports");
	EndIf;

EndProcedure

&AtClient
Procedure ShouldAttachReportsOnChange(Item)

	If Object.ShouldAttachReports Then
		Object.NotifyOnly = False;
		If Object.ShouldAttachReports Then
			CheckEncryptionBeforeIncludeReportsToEmailBody();
		EndIf;
	Else
		Object.ShouldInsertReportsIntoEmailBody = True;
	EndIf;

	SetVisibilityAvailabilityAndCorrectness(ThisObject, "ShouldAttachReports");
	

EndProcedure

#EndRegion

#Region AdditionalPage

&AtClient
Procedure ResetDefaultFormat(Command)
	ClearFormat(Cache.EmptyReportValue);
	DefaultFormats = DefaultFormatsListPresentation;
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "DefaultFormats");
EndProcedure

&AtClient
Procedure ClearAllSendIfBlank(Command)
	If Object.Reports.Count() > 0 Then
		Modified = True;
		For Each StrReport In Object.Reports Do
			StrReport.SendIfEmpty = False;
			StrReport.DoNotSendIfEmpty = True;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure SelectAllSendIfBlank(Command)
	If Object.Reports.Count() > 0 Then
		Modified = True;
		For Each StrReport In Object.Reports Do
			StrReport.SendIfEmpty = True;
			StrReport.DoNotSendIfEmpty = False;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure CreateArchivePassword(Command)
	
	If ValueIsFilled(ArchivePassword) Then	
		ShowQueryBox(
			New CallbackDescription("OnCreateArchivePassword", ThisObject),
			NStr("vi = 'Đã đặt mật khẩu để nén. Đặt mật khẩu mới?';
				|ru = 'Пароль для архива уже установлен. Установить новый пароль?';
				|en = 'A password for the archive is already set. Do you want to set a new password?'; fa = 'A password for the archive is already set. Do you want to set a new password?';
				|it = 'Пароль для архива уже установлен. Установить новый пароль?';
				|pl = 'A password for the archive is already set. Do you want to set a new password?';
				|tr = 'Arşiv şifresi zaten ayarlandı. Yeni bir şifre ayarlansın mı?'"),
			QuestionDialogMode.YesNo, , DialogReturnCode.No);	
		Return;
	EndIf;
	
	If Object.ShouldInsertReportsIntoEmailBody And Object.ShouldAttachReports Then
		QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionParameters.PromptDontAskAgain = False;

		QuestionButtons = New ValueList;
		QuestionButtons.Add("AutoSetPassword", NStr("vi = 'Đặt mật khẩu';
													|ru = 'Установить пароль';
													|en = 'Set password'; fa = 'تعیین رمز عبور';
													|it = 'Impostare password';
													|pl = 'Ustaw hasło';
													|tr = 'Şifre belirle'"));
		QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
															|ru = 'Отмена';
															|en = 'Cancel'; fa = 'انصراف';
															|it = 'Отмена';
															|pl = 'Cancel';
															|tr = 'İptal'"));
		QueryText = NStr(
			"vi = 'Để đặt mật khẩu, cần xóa báo cáo khỏi nội dung thư.';
			|ru = 'Для того чтобы установить пароль, необходимо убрать отчеты из текста письма.';
			|en = 'To set a password, remove the reports from the email text.'; fa = 'To set a password, remove the reports from the email text.';
			|it = 'Для того чтобы установить пароль, необходимо убрать отчеты из текста письма.';
			|pl = 'To set a password, remove the reports from the email text.';
			|tr = 'Parolayı ayarlamak için ileti metninden raporları kaldırmanız gerekmektedir.'");
		QuestionParameters.DefaultButton = "SetPassword";

		StandardSubsystemsClient.ShowQuestionToUser(
			New CallbackDescription("AfterAnswerQuestionPasswordEncryptionReportsInEmailText", ThisObject), QueryText,
			QuestionButtons, QuestionParameters);
	Else
		ArchivePassword = CreatePassword();
		ArchivePasswordChanged = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure PasswordsEncryption(Command)

	OpenFormPasswordsEncryption();

EndProcedure

&AtClient
Procedure SetTemplateDescription(Command)
	SetDescriptionTemplates("ReportDescription1", True);
EndProcedure

&AtClient
Procedure SetTemplateDescriptionFormat(Command)
	SetDescriptionTemplates("ReportDescriptionFormat", True);
EndProcedure

&AtClient
Procedure SetTemplateDescriptionPeriod(Command)
	SetDescriptionTemplates("DescriptionPeriod", True);
EndProcedure

&AtClient
Procedure SetTemplateDescriptionPeriodFormat(Command)
	SetDescriptionTemplates("DescriptionPeriodFormat", True);
EndProcedure

&AtClient
Procedure SetTemplateDescriptionDistributionDate(Command)
	SetDescriptionTemplates("DescriptionDistributionDate", True);
EndProcedure

&AtClient
Procedure SetTemplateDescriptionDistributionDateFormat(Command)
	SetDescriptionTemplates("DescriptionDistributionDateFormat", True);
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Client

&AtClient
Procedure UserSettingStartChoice(StandardProcessing)
	If Items.ReportSettingsPages.CurrentPage <> Items.ComposerPage Then
		Return;
	EndIf;
	Report = Items.Reports.CurrentData;
	If Report = Undefined Or TypeOf(Report.Report) <> Type("CatalogRef.ReportsOptions") Then
		Return;
	EndIf;
	DCID = Items.UserSettings.CurrentRow;
	Handler = New CallbackDescription("SelectUserSettingsCompletion", ThisObject);
	ReportMailingClientOverridable.OnSettingChoiceStart(Report, DCSettingsComposer, DCID, StandardProcessing, Handler);
EndProcedure

&AtClient
Procedure SelectUserSettingsCompletion(Result, ExecutionParameters) Export
	If TypeOf(Result) = Type("DataCompositionUserSettings") Then
		DCSettingsComposer.LoadUserSettings(Result);
	Else
		Return;
	EndIf;
	Report = Items.Reports.CurrentData;
	If Report = Undefined Or TypeOf(Report.Report) <> Type("CatalogRef.ReportsOptions") Then
		Return;
	EndIf;
	Report.ChangesMade = True;
EndProcedure

// A handler of closing the BulkEmailRecipients form.
//
// Parameters:
//   Result - Structure:
//     * Recipients - ValueTable:
//         * Recipient - DefinedType.BulkEmailRecipient
//         * Excluded - Boolean
//         * Address - String
//         * PictureIndex - Number
//     * RecipientsEmailAddressKind - CatalogRef.ContactInformationKinds
//   Parameter - Structure
//            - Undefined
//
&AtClient
Procedure BulkEmailRecipientsClickCompletion(Result, Parameter) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	Object.RecipientsEmailAddressKind = Result.RecipientsEmailAddressKind;
	Object.Recipients.Clear();
	For Each Item In Result.Recipients Do 
		NewRow = Object.Recipients.Add();
		NewRow.Recipient = Item.Recipient;
		NewRow.Excluded = Item.Excluded;
	EndDo;
	
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "BulkEmailRecipients");
	Modified = True;
EndProcedure

&AtClient
Procedure MailingRecipientTypeChoiceProcessingCompletion(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		Object.Recipients.Clear();
		MailingRecipientType = AdditionalParameters.ValueSelected;
		Modified = True;
		MailingRecipientTypeOnChange(Undefined);
		SetVisibilityAvailabilityAndCorrectness(ThisObject, "BulkEmailRecipients");
	EndIf;
EndProcedure

&AtClient
Procedure AddDefaultTemplateCompletion(Response, AdditionalParameters) Export
	DefaultTemplate = AdditionalParameters.DefaultTemplate;
	If Response = 1 Then
		If AdditionalParameters.OverwriteSubject Then
			Object.EmailSubject = DefaultTemplate;
		Else
			If Object.HTMLFormatEmail Then
				EmailTextFormattedDocument.Delete();
				EmailTextFormattedDocument.Add(DefaultTemplate, FormattedDocumentItemType.Text);
			Else
				Object.EmailText = DefaultTemplate;
			EndIf;
		EndIf;
	ElsIf Response = 2 Then
		AddLayout(DefaultTemplate);
	EndIf;
EndProcedure

&AtClient
Procedure CheckMailingAfterResponseToQuestion(Response, DeliveryParameters) Export
	If Response = 1 Or Modified Then
		If Response = 1 Then
			Object.IsPrepared = True;
		EndIf;
		WriteParameters = New Structure;
		WriteParameters.Insert("CommandName", "CommandCheckMailing");
		WriteParameters.Insert("DeliveryParameters", DeliveryParameters);
		WriteAtClient(Undefined, WriteParameters);
		Return;
	ElsIf Response <> -1 Then
		Return;
	EndIf;
	
	ClearMessages();
	
	DeliveryParameters.BulkEmail = Object.Description;
	
	If DeliveryParameters.UseFolder Then
		DeliveryParameters.Folder = Object.Folder;
	EndIf;
	
	If DeliveryParameters.UseNetworkDirectory Then
		DeliveryParameters.NetworkDirectoryWindows = Object.NetworkDirectoryWindows;
		DeliveryParameters.NetworkDirectoryLinux = Object.NetworkDirectoryLinux;
	EndIf;
	
	If DeliveryParameters.UseFTPResource Then
		DeliveryParameters.Owner = Object.Ref;
		DeliveryParameters.Server = Object.FTPServer;
		DeliveryParameters.Port = Object.FTPPort;
		DeliveryParameters.Login = Object.FTPUsername;
		If FTPPasswordChanged Then
			DeliveryParameters.Password = FTPPassword;
		EndIf;
		DeliveryParameters.Directory = Object.FTPDirectory;
		DeliveryParameters.PassiveConnection = Object.FTPPassiveConnection;
	EndIf;
	
	Handler = New CallbackDescription("CheckMailingAfterRecipientsChoice", ThisObject, DeliveryParameters);
	
	If DeliveryParameters.UseEmail Then
		ReportMailingClient.SelectRecipient(Handler, Object, False, True);
		Return;
	EndIf;
	
	RunCallback(Handler, Undefined);
	
EndProcedure

&AtClient
Procedure CheckMailingAfterRecipientsChoice(SelectionResult, DeliveryParameters) Export
	// CheckMailingAfterResponseToQuestion procedure execution result handler.
	If DeliveryParameters.UseEmail Then
		If SelectionResult = Undefined Then
			Return;
		EndIf;
		
		DeliveryParameters.Account = Object.Account;
		DeliveryParameters.BCCs  = Object.BCCs;
		DeliveryParameters.SubjectTemplate    = NStr("vi = 'Thông báo văn bản 1C:Enterprise';
													|ru = 'Тестовое сообщение 1С:Предприятие';
													|en = 'Test message from 1C:Enterprise'; fa = 'Test message from 1C:Enterprise';
													|it = 'Messaggio di testo 1C:Enterprise';
													|pl = 'Wiadomość tekstowa 1C:Enterprise';
													|tr = '1C:Enterprise test mesajı'");
		DeliveryParameters.TextTemplate1  = NStr("vi = 'Đây là thông báo đã gửi bằng hệ thống gửi hàng loạt của 1C:Enterprise.';
												|ru = 'Это сообщение отправлено системой рассылок 1С:Предприятие.';
												|en = 'This message is sent by 1C: Enterprise mailing system.'; fa = 'This message is sent by 1C: Enterprise mailing system.';
												|it = 'Questo messaggio è stato inviato da 1C:Enterprise mailing system.';
												|pl = 'Ta wiadomość została wysłana przez system subskrypcji 1C:Enterpise.';
												|tr = 'Bu mesaj 1C:Enterprise gönderim sistemi tarafından gönderildi.'")
			+ Chars.LF + Cache.SystemTitle;
		DeliveryParameters.Recipients    = SelectionResult;
	EndIf;
	
	ExecutionResult = CheckTransportMethod(Object.Ref, DeliveryParameters);
	
	WarningParameters = New Structure("Title, Text, More, Ref, UseEmail");
	FillPropertyValues(WarningParameters, DeliveryParameters);
	FillPropertyValues(WarningParameters, ExecutionResult);
	WarningParameters.Title = NStr("vi = 'Kết quả kiểm tra';
									|ru = 'Результат проверки';
									|en = 'Check result'; fa = 'نتیجه بررسی';
									|it = 'Risultato della verifica';
									|pl = 'Rezultat weryfikacji';
									|tr = 'Kontrol sonucu'");
	WarningParameters.Ref = Object.Account;
	
	OpenForm("Catalog.ReportMailings.Form.Warning", WarningParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure FillScheduleByTemplateCompletion(SelectedElement, AdditionalParameters) Export
	If SelectedElement <> Undefined Then
		FillScheduleByOption(SelectedElement.Value, True);
	EndIf;
EndProcedure

// A handler of closing the format string dialog box.
//
// Parameters:
//   ResultRow - String
//   Variables1 - Structure
//
&AtClient
Procedure AddChangeMailingDateTemplateCompletion(ResultRow, Variables1) Export
	If ResultRow = Undefined Then
		Return;
	EndIf;
	
	NewFragment   = Variables1.Prefix + ResultRow + Variables1.Postfix;
	PreviousFragment  = Variables1.Prefix + Variables1.FormatText + Variables1.Postfix;
	
	If Variables1.ChangeReportDescriptionTemplateMultiply Then
		If Variables1.PreviousFragmentFound Then
			DescriptionTemplate = StrReplace(Variables1.PreviousText1, PreviousFragment, NewFragment);
		Else
			DescriptionTemplate = Variables1.PreviousText1 + NewFragment;
		EndIf;
		SetDescriptionTemplatesForAllReports(Variables1.TemplateName, DescriptionTemplate);
	ElsIf Variables1.ShouldChangeReportDescriptionTemplate Then
		If Variables1.PreviousFragmentFound Then
			If ResultRow = Variables1.FormatText Then
				Return;
			EndIf;
			Items.ReportFormats.CurrentData.DescriptionTemplate = StrReplace(Variables1.PreviousText1, PreviousFragment, NewFragment);
		Else
			Items.ReportFormats.CurrentData.DescriptionTemplate = Variables1.PreviousText1 + NewFragment;
		EndIf;
	ElsIf Variables1.Item = Items.EmailTextFormattedDocument Then
		ReplacementExecuted = False;
		If Variables1.PreviousFragmentFound Then
			SearchResult = EmailTextFormattedDocument.FindText(PreviousFragment);
			If SearchResult <> Undefined Then
				FoundItems = EmailTextFormattedDocument.GetItems(SearchResult.BeginBookmark, SearchResult.EndBookmark);
				For Each FDText In FoundItems Do
					If StrFind(FDText.Text, PreviousFragment) > 0 Then
						FDText.Text = StrReplace(FDText.Text, PreviousFragment, NewFragment);
						ReplacementExecuted = True;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf; // Variable.PreviousFragmentFound
		If Not ReplacementExecuted Then
			If TrimAll(Variables1.PreviousText1) = PreviousFragment Then
				// The "SelectedText" property is rarely used in formatted documents (in case it's safe).
				//  
				Variables1.Item.SelectedText = NewFragment;
			Else
				EmailTextFormattedDocument.Add(NewFragment, FormattedDocumentItemType.Text);
			EndIf;
		EndIf;
	Else
		If Variables1.PreviousFragmentFound Then
			If ResultRow = Variables1.FormatText Then
				Return;
			EndIf;
			Variables1.Item.SelectedText = StrReplace(Variables1.PreviousText1, PreviousFragment, NewFragment);
		Else
			Variables1.Item.SelectedText = Variables1.PreviousText1 + NewFragment;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChooseFormatCompletion(FormatsList, Variables1) Export
	If FormatsList = Undefined Then
		Return;
	EndIf;
	
	// Check for changes.
	FormatsMatch = True;
	For IndexOf = 1 To FormatsList.Count() Do
		If FormatsList[IndexOf - 1].Check <> Variables1.FormatsListCopy[IndexOf - 1].Check Then
			FormatsMatch = False;
			Break;
		EndIf;
	EndDo;
	If FormatsMatch Then
		Return;
	EndIf;
	
	FormatPresentation = "";
	
	// Clean up existing records.
	ClearFormat(Variables1.ReportRef1);
	
	// Add marked formats.
	For Each ListItem In FormatsList Do
		If ListItem.Check Then
			StringFormat = Object.ReportFormats.Add();
			StringFormat.Report  = Variables1.ReportRef1;
			StringFormat.Format = ListItem.Value;
			FormatPresentation = FormatPresentation + ?(FormatPresentation = "", "", ", ") + String(ListItem.Presentation);
		EndIf;
	EndDo;
	
	If Variables1.IsDefaultFormat And FormatPresentation = "" Then
		FormatPresentation = DefaultFormatsListPresentation;
	EndIf;
	
	RunCallback(Variables1.HandlerResults_1, FormatPresentation);
EndProcedure

&AtClient
Procedure ReportFormatsEndChoiceFormat(FormatPresentation, Variables1) Export
	If FormatPresentation <> Undefined Then
		Variables1.ReportsRow.Formats = FormatPresentation;
	EndIf;
EndProcedure

&AtClient
Procedure DefaultFormatsSelectionCompletion(FormatPresentation, Variables1) Export
	If FormatPresentation <> Undefined Then
		DefaultFormats = FormatPresentation;
	EndIf;
	SetVisibilityAvailabilityAndCorrectness(ThisObject, "DefaultFormats");
EndProcedure

&AtClient
Procedure AfterChangeSchedule(ScheduleResult, AdditionalParameters) Export
	If ScheduleResult <> Undefined Then
		Modified = True;
		Schedule = ScheduleResult;
		SetVisibilityAvailabilityAndCorrectness(ThisObject, "Schedule");
	EndIf;
EndProcedure

&AtClient
Function ChoicePickupDragItemToTabularSection(PickingItem, TabularSection, Var_AttributeName, FillingStructure, Uniqueness = True)
	
	// (CatalogRef.*) drag from the pickup or selection form.
	AttributeValue = PickingItem;
	
	// The attribute must be unique within the table.
	FoundItems = TabularSection.FindRows(New Structure(Var_AttributeName, AttributeValue));
	
	If Uniqueness And FoundItems.Count() > 0 Then
		Return Undefined;
	EndIf;
	
	TableRow = TabularSection.Add();
	TableRow[Var_AttributeName] = AttributeValue;
	FillPropertyValues(TableRow, FillingStructure);
	
	Return TableRow;
EndFunction

&AtClient
Function ChoicePickupDragToTabularSection(ValueSelected, TabularSection, Var_AttributeName, FillingStructure, IDs = False)
	Modified = True;
	NewRowArray = New Array;
	
	If TypeOf(ValueSelected) = Type("Array") Then
		For Each PickingItem In ValueSelected Do
			Result = ChoicePickupDragItemToTabularSection(PickingItem, TabularSection, Var_AttributeName, FillingStructure);
			If Result <> Undefined Then
				NewRowArray.Add(?(IDs, Result.GetID(), Result));
			EndIf;
		EndDo;
	Else
		Result = ChoicePickupDragItemToTabularSection(ValueSelected, TabularSection, Var_AttributeName, FillingStructure);
		If Result <> Undefined Then
			NewRowArray.Add(?(IDs, Result.GetID(), Result));
		EndIf;
	EndIf;
	Return NewRowArray;
EndFunction

&AtClient
Procedure ChooseFormat(ReportRef1, HandlerResults_1)
	// The "ReportFormats" table is used to store all user-selected formats.
	// To store the default formats, an empty value of the "Report" attribute is used.
	// Depending on the implementation, the "Report" attribute can be "Undefined" or "EmptyRef".
	IsDefaultFormat = Not ValueIsFilled(ReportRef1);
	
	FoundItems = Object.ReportFormats.FindRows(New Structure("Report", ReportRef1));
	If FoundItems.Count() > 0 Then
		FormatsList.FillChecks(False);
		For Each StringFormat In FoundItems Do
			FormatsList.FindByValue(StringFormat.Format).Check = True;
		EndDo;
	Else
		FormatsList = DefaultFormatsList.Copy();
		If Not IsDefaultFormat Then
			FoundItems = Object.ReportFormats.FindRows(New Structure("Report", Cache.EmptyReportValue));
			If FoundItems.Count() > 0 Then
				FormatsList.FillChecks(False);
				For Each StringFormat In FoundItems Do
					FormatsList.FindByValue(StringFormat.Format).Check = True;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
	If IsDefaultFormat Then
		DialogTitle = NStr("vi = 'Hãy chọn định dạng mặc định';
							|ru = 'Выберите форматы по умолчанию';
							|en = 'Select default formats'; fa = 'Select default formats';
							|it = 'Selezionare i formati predefiniti';
							|pl = 'Wybierz formaty domyślne';
							|tr = 'Varsayılan formatları seç'");
	Else
		DialogTitle = NStr("vi = 'Hãy chọn định dạng đối với báo cáo ""%1""';
							|ru = 'Выберите форматы для отчета ""%1""';
							|en = 'Select formats for report ""%1""'; fa = 'Select formats for report ""%1""';
							|it = 'Selezionare i formati per il report ""%1""';
							|pl = 'Wybierz formaty dla raportu ""%1""';
							|tr = '""%1"" raporu için biçim seç'");
		DialogTitle = StringFunctionsClientServer.SubstituteParametersToString(DialogTitle, String(ReportRef1));
	EndIf;
	
	Variables1 = New Structure;
	Variables1.Insert("ReportRef1",        ReportRef1);
	Variables1.Insert("FormatsListCopy",  FormatsList.Copy());
	Variables1.Insert("IsDefaultFormat", IsDefaultFormat);
	Variables1.Insert("HandlerResults_1", HandlerResults_1);
	Handler = New CallbackDescription("ChooseFormatCompletion", ThisObject, Variables1);
	
	FormatsList.ShowCheckItems(Handler, DialogTitle);
	
EndProcedure

&AtClient
Procedure ClearFormat(ReportRef1)
	Modified = True;
	FoundItems = Object.ReportFormats.FindRows(New Structure("Report", ReportRef1));
	For Each StringFormat In FoundItems Do
		Object.ReportFormats.Delete(StringFormat);
	EndDo;
EndProcedure

&AtClient
Procedure AddLayout(TextTemplate = Undefined, SkipEmailSubject = False)
	// Checking and setting focus on the item.
	If SkipEmailSubject Or Not (CurrentItem = Items.EmailSubject Or CurrentItem = Items.ArchiveName) Then
		If Object.HTMLFormatEmail Then
			If CurrentItem <> Items.EmailTextFormattedDocument Then
				CurrentItem = Items.EmailTextFormattedDocument;
			EndIf;
		Else
			If CurrentItem <> Items.EmailText Then
				CurrentItem = Items.EmailText;
			EndIf;
		EndIf;
	EndIf;
	
	If TextTemplate = Undefined Then
		// Just preparing to add a template (switching current item).
		Return;
	EndIf;
	
	If CurrentItem.SelectedText = "" Then
		// Formatted documents mishandle changes of the "SelectedText" property if no text is selected.
		//  Therefore, use the alternative method for adding text.
		//  
		If CurrentItem = Items.EmailTextFormattedDocument Then
			EmailTextFormattedDocument.Add(TextTemplate, FormattedDocumentItemType.Text);
		Else
			CurrentItem.SelectedText = TextTemplate;
		EndIf;
	Else
		CurrentItem.SelectedText = CurrentItem.SelectedText + TextTemplate;
	EndIf;
EndProcedure

&AtClient
Function ChangeArrayContent(Add, Item, Val Array)
	IndexOf = Array.Find(Item);
	If Add And IndexOf = Undefined Then
		UBoundPlus1 = ?(Array.Count() >= Item, Item, Array.Count());
		For IndexOf = 1 To UBoundPlus1 Do
			If Array[UBoundPlus1 - IndexOf] < Item Then
				Array.Insert(UBoundPlus1 - IndexOf + 1, Item);
				Return Array;
			EndIf;
		EndDo;
		Array.Insert(0, Item);
	ElsIf Not Add And IndexOf <> Undefined Then
		Array.Delete(IndexOf);
	EndIf;
	Return Array;
EndFunction

&AtClient
Procedure ChangeScheduleInDialog()
	Handler = New CallbackDescription("AfterChangeSchedule", ThisObject);
	ScheduleDialog1 = New ScheduledJobDialog(Schedule);
	ScheduleDialog1.Show(Handler);
EndProcedure

&AtClient
Procedure EvaluateAdditionalDeliveryMethodsCheckBoxes()
	Object.UseFolder        = Publish And (OtherDeliveryMethod = "UseFolder");
	Object.UseNetworkDirectory = Publish And (OtherDeliveryMethod = "UseNetworkDirectory");
	Object.UseFTPResource    = Publish And (OtherDeliveryMethod = "UseFTPResource");
EndProcedure

&AtClient
Procedure CheckMailing(DeliveryParameters)
	// Clear message window.
	ClearMessages();
	
	// Check the data readiness and the need for writing.
	If Not Object.IsPrepared Or Object.Ref.IsEmpty() Then
		QuestionTitle = NStr("vi = 'Kiểm tra phương thức gửi';
							|ru = 'Проверка способа доставки';
							|en = 'Check delivery method'; fa = 'Check delivery method';
							|it = 'Verifica della modalità di consegna';
							|pl = 'Weryfikacja sposobu dostawy';
							|tr = 'Teslimat yönteminin kontrolü'");
		If Not Object.IsPrepared Then
			QueryText = NStr("vi = 'Trước khi kiểm tra, cần chuẩn bị gửi hàng loạt.
			|Nhấp vào ""Tiếp tục"" để bật hộp kiểm ""Đã chuẩn bị"" và ghi lại việc gửi hàng loạt.';
			|ru = 'Перед проверкой рассылка должна быть подготовлена.
			|Нажмите ""Продолжить"", чтобы включить флажок ""Подготовлена"" и записать рассылку.';
			|en = 'Prepare the distribution before check.
			|Click ""Continue"" to select the ""Prepared"" check box and save the distribution.'; fa = 'Prepare the distribution before check.
			|Click ""Continue"" to select the ""Prepared"" check box and save the distribution.';
			|it = 'Prima del controllo la newsletter deve essere preparata.
			|Fai clic su ""Continua"" per attivare la casella ""Preparata"" e registrare la newsletter.';
			|pl = 'Przed weryfikacją subskrypcja musi zostać przygotowana.
			|Naciśnij ""Kontynuuj"", żeby włączyć zaznaczenie ""Przygotowana"" i zapisać subskrypcję.';
			|tr = 'Lütfen kontrolden önce bülteni hazırlayın. 
			| ''''Hazır'''' işaret kutucuğunu seçmek ve bülteni kaydetmek için ''''Devam et'''' düğmesine basın.'");
		Else
			QueryText = NStr("vi = 'Trước khi kiểm tra, cần ghi lại việc gửi hàng loạt.
			|Hãy nhấn ""Tiếp tục"" để ghi lại việc gửi hàng loạt.';
			|ru = 'Перед проверкой рассылка должна быть записана.
			|Нажмите ""Продолжить"", чтобы записать рассылку.';
			|en = 'Save the distribution before check.
			|Click ""Continue"" to save the distribution.'; fa = 'Save the distribution before check.
			|Click ""Continue"" to save the distribution.';
			|it = 'Prima del controllo la newsletter deve essere registrata.
			|Fai clic su ""Continua"" per registrare la newsletter.';
			|pl = 'Przed weryfikacją subskrypcja musi zostać zapisana.
			|Naciśnij ""Kontynuuj"", żeby zapisać subskrypcję.';
			|tr = 'Lütfen kontrolden önce e-postayı yazın.
			|Bülteni kaydetmek için ''''Devam et'''' düğmesine basın.'");
		EndIf;
		
		Buttons = New ValueList;
		Buttons.Add(1, NStr("vi = 'Tiếp tục';
							|ru = 'Продолжить';
							|en = 'Continue'; fa = 'ادامه';
							|it = 'Continuare';
							|pl = 'Continue';
							|tr = 'Devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		Handler = New CallbackDescription("CheckMailingAfterResponseToQuestion", ThisObject, DeliveryParameters);
		ShowQueryBox(Handler, QueryText, Buttons, 60, 1, QuestionTitle);
	Else
		CheckMailingAfterResponseToQuestion(-1, DeliveryParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCreateArchivePassword(Response, Context) Export
	
	If Response = DialogReturnCode.Yes Then
		ArchivePassword = CreatePassword();
		ArchivePasswordChanged = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetDescriptionTemplates(TemplateName, Plural_Update = False)

	If Plural_Update Then
		SetDescriptionTemplatesForAllReports(TemplateName);
	Else
		Templates = DescriptionsTemplates();
		Items.ReportFormats.CurrentData.DescriptionTemplate = Templates.Get(TemplateName);
	EndIf;
	
	Modified = True;

	If TemplateName = "ReportDescription1" Or TemplateName = "ReportDescriptionFormat" Then
		Return;
	EndIf;

	Variables1 = ReportDescriptionTemplateChoiceVariables(TemplateName, Plural_Update);
	Handler = New CallbackDescription("AddChangeMailingDateTemplateCompletion", ThisObject, Variables1);

	Dialog = New FormatStringWizard;
	Dialog.AvailableTypes = New TypeDescription("Date");
	Dialog.Text         = Variables1.FormatText;
	Dialog.Show(Handler);

EndProcedure

&AtClient
Function ReportDescriptionTemplateChoiceVariables(TemplateName, Plural_Update)

	Variables1 = New Structure;
	Variables1.Insert("Item", Undefined);
	Variables1.Insert("PreviousText1", "");
	Variables1.Insert("Prefix", "[(");
	Variables1.Insert("Postfix", ")]");
	Variables1.Insert("FormatText", "");
	Variables1.Insert("PreviousFragmentFound", False);
	Variables1.Insert("ShouldChangeReportDescriptionTemplate", True);
	Variables1.Insert("ChangeReportDescriptionTemplateMultiply", Plural_Update);
	Variables1.Insert("TemplateName", TemplateName);

	If TemplateName = "DescriptionDistributionDate" Then

		Variables1.Insert("Prefix", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 ngày %2';
				|ru = '%1 от %2';
				|en = '%1 dated %2'; fa = '%1 dated %2';
				|it = '%1 del %2';
				|pl = '%1 z dn. %2';
				|tr = '%2 tarihli %1'"), "[" + FilesAndEmailTextParameters.ReportDescription1 + "]",
			"[" + FilesAndEmailTextParameters.MailingDate + "("));

	ElsIf TemplateName = "DescriptionDistributionDateFormat" Then

		Variables1.Insert("Prefix", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 ngày %2';
				|ru = '%1 от %2';
				|en = '%1 dated %2'; fa = '%1 dated %2';
				|it = '%1 del %2';
				|pl = '%1 z dn. %2';
				|tr = '%2 tarihli %1'"), "[" + FilesAndEmailTextParameters.ReportDescription1 + "]",
			"[" + FilesAndEmailTextParameters.MailingDate + "("));

		Variables1.Insert("Postfix", ")] [" + FilesAndEmailTextParameters.ReportFormat + "]");

	ElsIf TemplateName = "DescriptionPeriod" Then

		Variables1.Insert("Prefix", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 trong %2';
				|ru = '%1 за %2';
				|en = '%1 for %2'; fa = '%1 for %2';
				|it = '%1 за %2';
				|pl = '%1 for %2';
				|tr = '%1 %2 için'"), "[" + FilesAndEmailTextParameters.ReportDescription1 + "]",
			"[" + FilesAndEmailTextParameters.Period + "("));

	ElsIf TemplateName = "DescriptionPeriodFormat" Then

		Variables1.Insert("Prefix", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 trong %2';
				|ru = '%1 за %2';
				|en = '%1 for %2'; fa = '%1 for %2';
				|it = '%1 за %2';
				|pl = '%1 for %2';
				|tr = '%1 %2 için'"), "[" + FilesAndEmailTextParameters.ReportDescription1 + "]",
			"[" + FilesAndEmailTextParameters.Period + "("));
			
		Variables1.Insert("Postfix", ")] [" + FilesAndEmailTextParameters.ReportFormat + "]");
	EndIf;

	Return Variables1;

EndFunction

&AtClient
Procedure CheckEncryptionBeforeIncludeReportsToEmailBody()

	QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
	QuestionParameters.PromptDontAskAgain = False;

	If Object.Personalized And Object.ShouldSetPasswordsAndEncrypt Then

		If CanEncryptAttachments Then
			If Object.Archive Then
				QuestionButtons = New ValueList;
				QuestionButtons.Add("DisableEncryptionPasswords", NStr("vi = 'Đặt báo cáo vào nội dung thư';
																		|ru = 'Вставлять отчеты в текст письма';
																		|en = 'Insert reports into email body'; fa = 'درج گزارش‌ها در متن ایمیل';
																		|it = 'Вставлять отчеты в текст письма';
																		|pl = 'Insert reports into email body';
																		|tr = 'Raporları ileti metnine ekle'"));
				QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																	|ru = 'Отмена';
																	|en = 'Cancel'; fa = 'انصراف';
																	|it = 'Отмена';
																	|pl = 'Cancel';
																	|tr = 'İptal'"));
				QueryText = NStr("vi = 'Để đặt báo cáo vào nội dung thư, cần tắt mật khẩu và mã hóa.';
								|ru = 'Для того чтобы вставлять отчеты в текст письма, нужно отключить пароли и шифрование.';
								|en = 'To insert reports into the email body, disable passwords and encryption.'; fa = 'To insert reports into the email body, disable passwords and encryption.';
								|it = 'Для того чтобы вставлять отчеты в текст письма, нужно отключить пароли и шифрование.';
								|pl = 'To insert reports into the email body, disable passwords and encryption.';
								|tr = 'Raporları ileti metnine yerleştirmek için parolaları ve şifrelemeyi devre dışı bırakmanız gerekmektedir.'");
				QuestionParameters.DefaultButton = "DisableEncryptionPasswords";
			Else
				QuestionButtons = New ValueList;
				QuestionButtons.Add("DisableEncryptionPasswords", NStr("vi = 'Đặt báo cáo vào nội dung thư';
																		|ru = 'Вставлять отчеты в текст письма';
																		|en = 'Insert reports into email body'; fa = 'درج گزارش‌ها در متن ایمیل';
																		|it = 'Вставлять отчеты в текст письма';
																		|pl = 'Insert reports into email body';
																		|tr = 'Raporları ileti metnine ekle'"));
				QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																	|ru = 'Отмена';
																	|en = 'Cancel'; fa = 'انصراف';
																	|it = 'Отмена';
																	|pl = 'Cancel';
																	|tr = 'İptal'"));
				QueryText = NStr("vi = 'Để đặt báo cáo vào nội dung thư, cần tắt mã hóa.';
								|ru = 'Для того чтобы вставлять отчеты в текст письма, нужно отключить шифрование.';
								|en = 'To insert reports into the email body, disable encryption.'; fa = 'To insert reports into the email body, disable encryption.';
								|it = 'Для того чтобы вставлять отчеты в текст письма, нужно отключить шифрование.';
								|pl = 'To insert reports into the email body, disable encryption.';
								|tr = 'Raporları ileti metnine yerleştirmek için şifrelemeyi devre dışı bırakmanız gerekmektedir.'");
				QuestionParameters.DefaultButton = "DisableEncryption";
			EndIf;
		ElsIf Object.Archive Then
			QuestionButtons = New ValueList;
			QuestionButtons.Add("DisableEncryptionPasswords", NStr("vi = 'Đặt báo cáo vào nội dung thư';
																	|ru = 'Вставлять отчеты в текст письма';
																	|en = 'Insert reports into email body'; fa = 'درج گزارش‌ها در متن ایمیل';
																	|it = 'Вставлять отчеты в текст письма';
																	|pl = 'Insert reports into email body';
																	|tr = 'Raporları ileti metnine ekle'"));
			QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																|ru = 'Отмена';
																|en = 'Cancel'; fa = 'انصراف';
																|it = 'Отмена';
																|pl = 'Cancel';
																|tr = 'İptal'"));
			QueryText = NStr("vi = 'Để đặt báo cáo vào nội dung thư, cần tắt mật khẩu.';
							|ru = 'Для того чтобы вставлять отчеты в текст письма, нужно отключить пароли.';
							|en = 'To insert reports into the email body, disable passwords.'; fa = 'To insert reports into the email body, disable passwords.';
							|it = 'Для того чтобы вставлять отчеты в текст письма, нужно отключить пароли.';
							|pl = 'To insert reports into the email body, disable passwords.';
							|tr = 'Raporları ileti metnine yerleştirmek için parolaları devre dışı bırakmanız gerekmektedir.'");
			QuestionParameters.DefaultButton = "DisablePasswords";
		EndIf;
		If CanEncryptAttachments Or Object.Archive Then
			StandardSubsystemsClient.ShowQuestionToUser(
				New CallbackDescription("AfterQuestionAnsweredReportsInEmailTextEncryption", ThisObject), QueryText,
				QuestionButtons, QuestionParameters);
		EndIf;

	ElsIf Object.Personal Then

		If CanEncryptAttachments Then

			If Object.Archive And ValueIsFilled(ArchivePassword) And ValueIsFilled(ThisObject["CertificateToEncrypt"]) Then
				QuestionButtons = New ValueList;
				QuestionButtons.Add("DisablePasswordEncryption", NStr("vi = 'Đặt báo cáo vào nội dung thư';
																		|ru = 'Вставлять отчеты в текст письма';
																		|en = 'Insert reports into email body'; fa = 'درج گزارش‌ها در متن ایمیل';
																		|it = 'Вставлять отчеты в текст письма';
																		|pl = 'Insert reports into email body';
																		|tr = 'Raporları ileti metnine ekle'"));
				QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																	|ru = 'Отмена';
																	|en = 'Cancel'; fa = 'انصراف';
																	|it = 'Отмена';
																	|pl = 'Cancel';
																	|tr = 'İptal'"));
				QueryText = NStr("vi = 'Để đặt báo cáo vào nội dung thư, cần tắt mật khẩu và mã hóa.';
								|ru = 'Для того чтобы вставлять отчеты в текст письма, нужно отключить пароль и шифрование.';
								|en = 'To insert reports into the email body, disable the password and encryption.'; fa = 'To insert reports into the email body, disable the password and encryption.';
								|it = 'Для того чтобы вставлять отчеты в текст письма, нужно отключить пароль и шифрование.';
								|pl = 'To insert reports into the email body, disable the password and encryption.';
								|tr = 'Raporları ileti metnine yerleştirmek için parolayı ve şifrelemeyi devre dışı bırakmanız gerekmektedir.'");
				QuestionParameters.DefaultButton = "DisablePasswordEncryption";

				StandardSubsystemsClient.ShowQuestionToUser(
					New CallbackDescription("AfterQuestionAnsweredReportsInEmailTextEncryption", ThisObject),
					QueryText, QuestionButtons, QuestionParameters);

			ElsIf Object.Archive And ValueIsFilled(ArchivePassword) Then
				QuestionButtons = New ValueList;
				QuestionButtons.Add("ClearUpPassword", NStr("vi = 'Đặt báo cáo vào nội dung thư';
															|ru = 'Вставлять отчеты в текст письма';
															|en = 'Insert reports into email body'; fa = 'درج گزارش‌ها در متن ایمیل';
															|it = 'Вставлять отчеты в текст письма';
															|pl = 'Insert reports into email body';
															|tr = 'Raporları ileti metnine ekle'"));
				QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																	|ru = 'Отмена';
																	|en = 'Cancel'; fa = 'انصراف';
																	|it = 'Отмена';
																	|pl = 'Cancel';
																	|tr = 'İptal'"));
				QueryText = NStr(
					"vi = 'Để đặt báo cáo vào nội dung thư, cần xóa mật khẩu nén.';
					|ru = 'Для того чтобы вставлять отчеты в текст письма, нужно очистить пароль архива.';
					|en = 'To insert reports into the email body, clear the archive password.'; fa = 'To insert reports into the email body, clear the archive password.';
					|it = 'Для того чтобы вставлять отчеты в текст письма, нужно очистить пароль архива.';
					|pl = 'To insert reports into the email body, clear the archive password.';
					|tr = 'Raporları ileti metnine yerleştirmek için arşiv parolasını temizlemeniz gerekmektedir.'");
				QuestionParameters.DefaultButton = "ClearUpPassword";

				StandardSubsystemsClient.ShowQuestionToUser(
					New CallbackDescription("AfterQuestionAnsweredReportsInEmailTextEncryption", ThisObject),
					QueryText, QuestionButtons, QuestionParameters);

			ElsIf ValueIsFilled(ThisObject["CertificateToEncrypt"]) Then
				QuestionButtons = New ValueList;
				QuestionButtons.Add("ClearCertificate", NStr("vi = 'Đặt báo cáo vào nội dung thư';
															|ru = 'Вставлять отчеты в текст письма';
															|en = 'Insert reports into email body'; fa = 'درج گزارش‌ها در متن ایمیل';
															|it = 'Вставлять отчеты в текст письма';
															|pl = 'Insert reports into email body';
															|tr = 'Raporları ileti metnine ekle'"));
				QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																	|ru = 'Отмена';
																	|en = 'Cancel'; fa = 'انصراف';
																	|it = 'Отмена';
																	|pl = 'Cancel';
																	|tr = 'İptal'"));
				QueryText = NStr("vi = 'Để đặt báo cáo vào nội dung thư, cần xóa trường chứng thư để mã hóa.';
								|ru = 'Для того чтобы вставлять отчеты в текст письма, нужно очистить поле сертификата для шифрования.';
								|en = 'To insert reports into the email body, clear the encryption certificate field.'; fa = 'To insert reports into the email body, clear the encryption certificate field.';
								|it = 'Для того чтобы вставлять отчеты в текст письма, нужно очистить поле сертификата для шифрования.';
								|pl = 'To insert reports into the email body, clear the encryption certificate field.';
								|tr = 'Raporları ileti metnine yerleştirmek için şifreleme sertifikası alanını temizlemeniz gerekmektedir.'");
				QuestionParameters.DefaultButton = "ClearCertificate";

				StandardSubsystemsClient.ShowQuestionToUser(
					New CallbackDescription("AfterQuestionAnsweredReportsInEmailTextEncryption", ThisObject),
					QueryText, QuestionButtons, QuestionParameters);
			EndIf;
		ElsIf Object.Archive And ValueIsFilled(ArchivePassword) Then
			QuestionButtons = New ValueList;
			QuestionButtons.Add("ClearUpPassword", NStr("vi = 'Đặt báo cáo vào nội dung thư';
														|ru = 'Вставлять отчеты в текст письма';
														|en = 'Insert reports into email body'; fa = 'درج گزارش‌ها در متن ایمیل';
														|it = 'Вставлять отчеты в текст письма';
														|pl = 'Insert reports into email body';
														|tr = 'Raporları ileti metnine ekle'"));
			QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																|ru = 'Отмена';
																|en = 'Cancel'; fa = 'انصراف';
																|it = 'Отмена';
																|pl = 'Cancel';
																|tr = 'İptal'"));
			QueryText = NStr(
				"vi = 'Để đặt báo cáo vào nội dung thư, cần xóa mật khẩu nén.';
				|ru = 'Для того чтобы вставлять отчеты в текст письма, нужно очистить пароль архива.';
				|en = 'To insert reports into the email body, clear the archive password.'; fa = 'To insert reports into the email body, clear the archive password.';
				|it = 'Для того чтобы вставлять отчеты в текст письма, нужно очистить пароль архива.';
				|pl = 'To insert reports into the email body, clear the archive password.';
				|tr = 'Raporları ileti metnine yerleştirmek için arşiv parolasını temizlemeniz gerekmektedir.'");
			QuestionParameters.DefaultButton = "ClearUpPassword";

			StandardSubsystemsClient.ShowQuestionToUser(
				New CallbackDescription("AfterQuestionAnsweredReportsInEmailTextEncryption", ThisObject), QueryText,
				QuestionButtons, QuestionParameters);
		EndIf;

	ElsIf Not Object.Personalized And Not Object.Personal And Object.Archive And ValueIsFilled(ArchivePassword) Then
		QuestionButtons = New ValueList;
		QuestionButtons.Add("ClearUpPassword", NStr("vi = 'Đặt báo cáo vào nội dung thư';
													|ru = 'Вставлять отчеты в текст письма';
													|en = 'Insert reports into email body'; fa = 'درج گزارش‌ها در متن ایمیل';
													|it = 'Вставлять отчеты в текст письма';
													|pl = 'Insert reports into email body';
													|tr = 'Raporları ileti metnine ekle'"));
		QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
															|ru = 'Отмена';
															|en = 'Cancel'; fa = 'انصراف';
															|it = 'Отмена';
															|pl = 'Cancel';
															|tr = 'İptal'"));
		QueryText = NStr(
			"vi = 'Để đặt báo cáo vào nội dung thư, cần xóa mật khẩu nén.';
			|ru = 'Для того чтобы вставлять отчеты в текст письма, нужно очистить пароль архива.';
			|en = 'To insert reports into the email body, clear the archive password.'; fa = 'To insert reports into the email body, clear the archive password.';
			|it = 'Для того чтобы вставлять отчеты в текст письма, нужно очистить пароль архива.';
			|pl = 'To insert reports into the email body, clear the archive password.';
			|tr = 'Raporları ileti metnine yerleştirmek için arşiv parolasını temizlemeniz gerekmektedir.'");
		QuestionParameters.DefaultButton = "ClearUpPassword";

		StandardSubsystemsClient.ShowQuestionToUser(
			New CallbackDescription("AfterQuestionAnsweredReportsInEmailTextEncryption", ThisObject), QueryText,
			QuestionButtons, QuestionParameters);
	EndIf;

EndProcedure

&AtClient
Procedure AfterQuestionAnsweredReportsInEmailTextEncryption(Result, Var_Parameters) Export

	If Result = Undefined Then
		Return;
	EndIf;

	If Result.Value = "DisableEncryptionPasswords" Then
		Object.ShouldSetPasswordsAndEncrypt = False;
		Items.PasswordsEncryption.Enabled = False;
	ElsIf Result.Value = "DisablePasswordEncryption" Then
		ArchivePassword = "";
		ThisObject["CertificateToEncrypt"] = "";
		ArchivePasswordChanged = True;
		EncryptionCertificateChanged = True;
	ElsIf Result.Value = "ClearUpPassword" Then
		ArchivePassword = "";
		ArchivePasswordChanged = True;
	ElsIf Result.Value = "ClearCertificate" Then
		ThisObject["CertificateToEncrypt"] = "";
		EncryptionCertificateChanged = True;
	ElsIf Result.Value = DialogReturnCode.Cancel Then
		Object.ShouldInsertReportsIntoEmailBody = False;
	EndIf;

EndProcedure

&AtClient
Procedure CheckOnSetArchivePasswordInsertReportsToEmailText()

	If ValueIsFilled(ArchivePassword) And Object.Archive And Object.ShouldInsertReportsIntoEmailBody 
		And Object.ShouldAttachReports Then
		QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionParameters.PromptDontAskAgain = False;
		
		QuestionButtons = New ValueList;
		QuestionButtons.Add("SetPassword", NStr("vi = 'Đặt mật khẩu';
												|ru = 'Установить пароль';
												|en = 'Set password'; fa = 'تعیین رمز عبور';
												|it = 'Impostare password';
												|pl = 'Ustaw hasło';
												|tr = 'Şifre belirle'"));
		QuestionButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
															|ru = 'Отмена';
															|en = 'Cancel'; fa = 'انصراف';
															|it = 'Отмена';
															|pl = 'Cancel';
															|tr = 'İptal'"));
		QueryText = NStr(
			"vi = 'Để đặt mật khẩu, cần xóa báo cáo khỏi nội dung thư.';
			|ru = 'Для того чтобы установить пароль, необходимо убрать отчеты из текста письма.';
			|en = 'To set a password, remove the reports from the email text.'; fa = 'To set a password, remove the reports from the email text.';
			|it = 'Для того чтобы установить пароль, необходимо убрать отчеты из текста письма.';
			|pl = 'To set a password, remove the reports from the email text.';
			|tr = 'Parolayı ayarlamak için ileti metninden raporları kaldırmanız gerekmektedir.'");
		QuestionParameters.DefaultButton = "SetPassword";

		StandardSubsystemsClient.ShowQuestionToUser(
			New CallbackDescription("AfterAnswerQuestionPasswordEncryptionReportsInEmailText", ThisObject), QueryText,
			QuestionButtons, QuestionParameters);
	EndIf;

EndProcedure

&AtClient
Procedure AfterAnswerQuestionPasswordEncryptionReportsInEmailText(Result, Var_Parameters) Export

	If Result = Undefined Then
		Return;
	EndIf;

	If Result.Value = "SetPassword" Then
		Object.ShouldInsertReportsIntoEmailBody = False;
	ElsIf Result.Value = "AutoSetPassword" Then
		Object.ShouldInsertReportsIntoEmailBody = False;
		ArchivePassword = CreatePassword();
		ArchivePasswordChanged = True;
	ElsIf Result.Value = "InstallEncryptionCertificate" Then
		Object.ShouldInsertReportsIntoEmailBody = False;
	ElsIf Result.Value = DialogReturnCode.Cancel Then
		ArchivePassword = "";
		ArchivePasswordChanged = True;
		ThisObject["CertificateToEncrypt"] = "";
		EncryptionCertificateChanged = True;
	EndIf;

EndProcedure

&AtClient
Procedure SetPasswordsReportsInEmailBodyAfterQuestionAnswered(Result, Var_Parameters) Export

	If Result = Undefined Then
		Return;
	EndIf;

	If Result.Value = "ShouldSetPasswordsAndEncrypt" Then
		Object.ShouldInsertReportsIntoEmailBody = False;
		OpenFormPasswordsEncryption();
	ElsIf Result.Value = DialogReturnCode.Cancel Then
		Object.ShouldSetPasswordsAndEncrypt = False;
	EndIf;

EndProcedure

&AtClient
Procedure OpenFormPasswordsEncryption()

	FormParameters = New Structure;
	FormParameters.Insert("RecipientsAddress", PutRecipientsInStorage());
	FormParameters.Insert("Archive", Object.Archive);
	FormParameters.Insert("MailingRecipientType", MailingRecipientType);
	FormParameters.Insert("RecipientsEmailAddressKind", Object.RecipientsEmailAddressKind);
	FormParameters.Insert("Ref", Object.Ref);
	FormParameters.Insert("MailingDescription", Object.Description);
	OpenForm("Catalog.ReportMailings.Form.PasswordsEncryption", FormParameters, ThisObject, , , , ,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure


&AtClient
Procedure SetDescriptionTemplatesForAllReports(TemplateName, DescriptionTemplate = "")
	
	Templates = DescriptionsTemplates();
	
	IsPeriodUsed = TemplateName = "DescriptionPeriod" Or TemplateName = "DescriptionPeriodFormat";
	For Each RowReport In Object.Reports Do
		If IsPeriodUsed Then
			RowID = RowReport.GetID();
			If Not RowReport.ThereIsPeriod Then
				RowReport.DescriptionTemplate = Templates.Get("ReportDescriptionFormat");
				Continue;
			EndIf;
		EndIf;
		If ValueIsFilled(DescriptionTemplate) Then
			RowReport.DescriptionTemplate = DescriptionTemplate;
		Else
			RowReport.DescriptionTemplate = Templates.Get(TemplateName);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Function DescriptionsTemplates()

	Templates = New Map;
	Templates.Insert("ReportDescription1", "[" + FilesAndEmailTextParameters.ReportDescription1 + "]");
	Templates.Insert("ReportDescriptionFormat", "[" + FilesAndEmailTextParameters.ReportDescription1 + "] [" + FilesAndEmailTextParameters.ReportFormat + "]");
	Templates.Insert("DescriptionPeriod", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 trong %2';
				|ru = '%1 за %2';
				|en = '%1 for %2'; fa = '%1 for %2';
				|it = '%1 за %2';
				|pl = '%1 for %2';
				|tr = '%1 %2 için'"), "[" + FilesAndEmailTextParameters.ReportDescription1 + "]",
			"[" + FilesAndEmailTextParameters.Period + "()]"));
	Templates.Insert("DescriptionPeriodFormat", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 trong %2 %3';
				|ru = '%1 за %2 %3';
				|en = '%1 for %2 %3'; fa = '%1 for %2 %3';
				|it = '%1 per %2 %3';
				|pl = '%1 za %2 %3';
				|tr = '%1 %2 %3 için'"), "[" + FilesAndEmailTextParameters.ReportDescription1 + "]",
			"[" + FilesAndEmailTextParameters.Period + "()]", "[" + FilesAndEmailTextParameters.ReportFormat + "]"));
	Templates.Insert("DescriptionDistributionDate", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 ngày %2';
				|ru = '%1 от %2';
				|en = '%1 dated %2'; fa = '%1 dated %2';
				|it = '%1 del %2';
				|pl = '%1 z dn. %2';
				|tr = '%2 tarihli %1'"), "[" + FilesAndEmailTextParameters.ReportDescription1 + "]",
			"[" + FilesAndEmailTextParameters.MailingDate + "()]"));
	Templates.Insert("DescriptionDistributionDateFormat", StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 ngày %2 %3';
				|ru = '%1 от %2 %3';
				|en = '%1 dated %2 %3'; fa = '%1 dated %2 %3';
				|it = '%1 del %2 %3';
				|pl = '%1 z dn. %2 %3';
				|tr = '%2 tarihli %1 %3'"), "[" + FilesAndEmailTextParameters.ReportDescription1 + "]",
			"[" + FilesAndEmailTextParameters.MailingDate + "()]", "[" + FilesAndEmailTextParameters.ReportFormat + "]"));

	Return Templates;

EndFunction

&AtClient
Procedure AfterCloseRedistribution(Result, Var_Parameters) Export
	
	Read();
	
EndProcedure

&AtClient
Procedure OnOpenTemplatePreview()
	AddLayout();
	FormParameters = TemplatePreviewFormParameters();
	OpenForm("Catalog.ReportMailings.Form.EmailPreview", FormParameters, ThisObject, , , , ,
		FormWindowOpeningMode.Independent);

EndProcedure

#EndRegion

#Region ClientServer

&AtClientAtServerNoContext
Function PasswordHidden()
	Return "********";
EndFunction

// Parameters:
//  Form - ClientApplicationForm:
//    * Schedule - JobSchedule
//  Changes - String 
//
&AtClientAtServerNoContext
Procedure SetVisibilityAvailabilityAndCorrectness(Form, Changes = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	If Changes = "" Or Changes = "FTPServerAndDirectory" Then
		If ValueIsFilled(Object.FTPServer) Then
			AddressPresentation = "ftp://";
			If ValueIsFilled(Object.FTPUsername) Then
				AddressPresentation = AddressPresentation + Object.FTPUsername + ?(ValueIsFilled(Form.FTPPassword), ":" + PasswordHidden(), "") + "@";
			EndIf;
			Form.FTPServerAndDirectory = AddressPresentation + Object.FTPServer + ":" + Format(Object.FTPPort, "NZ=0; NG=0") + Object.FTPDirectory;
		Else
			Form.FTPServerAndDirectory = "";
		EndIf;
	EndIf;
	
	If Changes = ""
		Or Changes = "IsPrepared"
		Or Changes = "ExecuteOnSchedule"
		Or Changes = "BulkEmailType"
		Or Changes = "Publish"
		Or Changes = "UseEmail" Then
		
		Items.Reports.AutoMarkIncomplete         = Object.IsPrepared;
		Items.ReportFormats.AutoMarkIncomplete = Object.IsPrepared;
		
		Items.SchedulePeriodicity.AutoMarkIncomplete = Object.IsPrepared And Object.ExecuteOnSchedule;
		
		Items.NetworkDirectoryWindows.AutoMarkIncomplete = Object.IsPrepared And Form.Publish;
		Items.NetworkDirectoryLinux.AutoMarkIncomplete   = Object.IsPrepared And Form.Publish;
		Items.FTPServerAndDirectory.AutoMarkIncomplete     = Object.IsPrepared And Form.Publish;
		Items.Folder.AutoMarkIncomplete                 = Object.IsPrepared And Form.Publish;
		
		Items.AuthorMailAddressKind.AutoMarkIncomplete = Object.IsPrepared And Object.Personal;
		Items.Account.AutoMarkIncomplete = Object.IsPrepared And Object.UseEmail;
		
	EndIf;
	
	If Changes = "" Or Changes = "BulkEmailType" Then
		// Validity
		If Object.Personal And Object.Personalized Then
			Object.Personal = False;
		EndIf;
		
		GroupIncludedIntoPersonalDistributionHierarchy = IsMemberOfPersonalReportGroup(Object.Parent);
		If Object.Personal <> GroupIncludedIntoPersonalDistributionHierarchy Then
			SetFormModified(Form, "Parent", , 
				NStr("vi = 'Nhóm đã đặt theo dạng gửi hàng loạt';
					|ru = 'Группа установлена в соответствии с видом рассылки.';
					|en = 'The group applied complies with the distribution type.'; fa = 'The group applied complies with the distribution type.';
					|it = 'Группа установлена в соответствии с видом рассылки.';
					|pl = 'The group applied complies with the distribution type.';
					|tr = 'Grup, bülten türüne göre ayarlandı.'"));
			Object.Parent = ?(Object.Personal, Form.Cache.PersonalMailingsGroup, Undefined);
		EndIf;
		
		If Object.Personal Then
			CommonMailing = False;
			Form.BulkEmailType = "Personal";
		ElsIf Object.Personalized Then
			CommonMailing = False;
			Form.BulkEmailType = "Personalized";
		Else
			CommonMailing = True;
			Form.BulkEmailType = "Shared3";
		EndIf;
		
		If Not CommonMailing Then
			Object.UseFolder            = False;
			Object.UseNetworkDirectory   = False;
			Object.UseFTPResource        = False;
			Object.UseEmail = True;
		EndIf;
		
		// Visibility & Availability
		Items.BulkEmailTypes.CurrentPage = ?(Object.Personal, Items.BulkEmailTypesPersonal, 
			Items.BulkEmailTypesForRecipients);
		Items.OtherDeliveryMethods.Visible = CommonMailing;
		Items.UseEmail.Visible = CommonMailing;
		
		If Object.Personal Then
			Items.BulkEmailRecipients.Visible = False;
		Else
			Items.BulkEmailRecipients.Visible = ValueIsFilled(Form.MailingRecipientType);
			If Not CommonMailing Then
				Items.BulkEmailRecipients.TitleLocation = FormItemTitleLocation.Auto;
			Else
				Items.BulkEmailRecipients.TitleLocation = FormItemTitleLocation.None;
			EndIf;
		EndIf;
		
		// Restore parameters
		If Object.UseFolder Then
			Form.OtherDeliveryMethod = "UseFolder";
			Form.Publish = True;
		ElsIf Object.UseNetworkDirectory Then
			Form.OtherDeliveryMethod = "UseNetworkDirectory";
			Form.Publish = True;
		ElsIf Object.UseFTPResource Then
			Form.OtherDeliveryMethod = "UseFTPResource";
			Form.Publish = True;
		Else
			Form.OtherDeliveryMethod = Items.OtherDeliveryMethod.ChoiceList[0].Value;
			Form.Publish = False;
		EndIf;
		
		Items.UseMailingRecipientInReport1Setting.Visible = Object.Personalized;
		Items.UseMailingRecipientInReport2Setting.Visible = Object.Personalized;
		Items.UseMailingRecipientInReport3Setting.Visible = Object.Personalized;
		Items.UseMailingRecipientInReport4Setting.Visible = Object.Personalized;
		
		SetCertificatePasswordsVisibilityAndAvailability(Form);
	EndIf;
	
	If Changes = "" Or Changes = "Reports" Then
		ReportCount = Form.Object.Reports.Count();
		If ReportCount > 0 Then
			Items.ReportsPage.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Báo cáo (%1)';
					|ru = 'Отчеты (%1)';
					|en = 'Reports (%1)'; fa = 'Reports (%1)';
					|it = 'I report (%1)';
					|pl = 'Raporty (%1)';
					|tr = 'Raporlar (%1)'"), 
				Format(ReportCount, "NZ=0; NG="));
		Else
			Items.ReportsPage.Title = NStr("vi = 'Báo cáo';
											|ru = 'Отчеты';
											|en = 'Reports'; fa = 'گزارش‌ها';
											|it = 'Отчеты';
											|pl = 'Reports';
											|tr = 'Raporlar'") ;
		EndIf;
	EndIf;
	
	If Changes = "" Or Changes = "OtherDeliveryMethod" Or Changes = "Publish" Or Changes = "BulkEmailType" Then
		Items.OtherDeliveryMethod.Enabled  = Form.Publish;
		Items.DeliveryParameters.Enabled     = Form.Publish;
		Items.DeliveryParameters.CurrentPage = Items[Form.OtherDeliveryMethod];
		
		Items.Folder.Visible = (Items.DeliveryParameters.CurrentPage = Items.UseFolder);
		Items.NetworkDirectoryWindows.Visible = (Items.DeliveryParameters.CurrentPage = Items.UseNetworkDirectory);
		Items.NetworkDirectoryLinux.Visible = (Items.DeliveryParameters.CurrentPage = Items.UseNetworkDirectory);
		Items.FTPServerAndDirectory.Visible = (Items.DeliveryParameters.CurrentPage = Items.UseFTPResource);
	EndIf;
	
	If Changes = "" Or Changes = "UseEmail" Or Changes = "BulkEmailType" Then
		Items.AccountGroup.Enabled = Object.UseEmail;
		Items.EmailParameters.Enabled = Object.UseEmail;
		Items.AdditionalParametersOfMailing.Enabled = Object.UseEmail;
		Items.BulkEmailRecipients.Enabled = Object.UseEmail;
		Items.ShouldAttachReports.Enabled = Object.UseEmail;
	EndIf;
	
	If Changes = "" Or Changes = "UseEmail" Or Changes = "BulkEmailType"
		Or Changes = "ShouldAttachReports" Or Changes = "Publish" Or Changes = "NotifyOnly" Then
		Items.ReportsFilesSettings.Enabled = Object.ShouldAttachReports Or Form.Publish;
	EndIf;
	
	If Changes = "" Or Changes = "BulkEmailRecipients" Or Changes = "BulkEmailType" Then
		If Form.BulkEmailType <> "Personal" Then
			Items.BulkEmailRecipients.Visible = True;
			RecipientsPresentation1 = RecipientsPresentation1(Form);
			Form.BulkEmailRecipients = RecipientsPresentation1.Short;
		EndIf;
	EndIf;
	
	If Changes = ""
		Or Changes = "NotifyOnly"
		Or Changes = "UseEmail"
		Or Changes = "OtherDeliveryMethod"
		Or Changes = "Publish"
		Or Changes = "BulkEmailType" Then
		
		Items.NotifyOnly.Visible = (Object.UseEmail And Form.Publish);
		If Not Items.NotifyOnly.Visible Then
			Object.NotifyOnly = False;
		EndIf;
		
		TransportMethods = "";
		If Object.UseFolder Then
			TransportMethods = NStr("vi = 'thư mục';
									|ru = 'папка';
									|en = 'folder'; fa = 'folder';
									|it = 'папка';
									|pl = 'folder';
									|tr = 'Klasör'");
		EndIf;
		If Object.UseNetworkDirectory Then
			TransportMethods = NStr("vi = 'thư mục mạng';
									|ru = 'сетевой каталог';
									|en = 'network directory'; fa = 'network directory';
									|it = 'directory di rete';
									|pl = 'katalog sieciowy';
									|tr = 'ağ kataloğu'");
		EndIf;
		If Object.UseFTPResource Then
			TransportMethods = NStr("vi = 'FTP';
									|ru = 'FTP';
									|en = 'FTP'; fa = 'FTP';
									|it = 'FTP';
									|pl = 'FTP';
									|tr = 'FTP'");
		EndIf;
		If Object.UseEmail And Not Object.NotifyOnly Then
			TransportMethods = TransportMethods + ?(TransportMethods = "", NStr("vi = 'Email';
																				|ru = 'эл. почта';
																				|en = 'email'; fa = 'ایمیل';
																				|it = 'posta elettronica';
																				|pl = 'poczta elektroniczna';
																				|tr = 'e-posta'"), " "+ NStr("vi = 'và email';
																											|ru = 'и эл. почта';
																											|en = 'and email'; fa = 'and email';
																											|it = 'e posta elettronica';
																											|pl = 'i poczta elektroniczna';
																											|tr = 've e-posta'"));
		EndIf;
		
		Items.DeliveryPage.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Cách gửi (%1)';
																								|ru = 'Доставка (%1)';
																								|en = 'Delivery (%1)'; fa = 'Delivery (%1)';
																								|it = 'Consegna (%1)';
																								|pl = 'Dostawa (%1)';
																								|tr = 'Teslimat (%1)'"), TransportMethods);
	EndIf;
	
	If IsBlankString(Changes) Or StrCompare(Changes, "HTMLFormatEmail") = 0 Then
		
		Items.EmailTextPages.CurrentPage = ?(Object.HTMLFormatEmail,
			Items.EmailTextPagesHTML, Items.EmailTextPagesNormalText);
		
	EndIf;
	
	If Changes = "" Or Changes = "Archive" Then
		Items.ArchiveName.Enabled           = Object.Archive;
		Items.ArchivePassword.Enabled        = Object.Archive;
		Items.CreateArchivePassword.Enabled = Object.Archive;
		SetCertificatePasswordsVisibilityAndAvailability(Form);
	EndIf;
	
	If Changes = "" Or Changes = "ExecuteOnSchedule" Then
		If Object.ExecuteOnSchedule Then
			Items.SchedulePage.Title = NStr("vi = 'Lịch biểu (đã kích hoạt)';
											|ru = 'Расписание (активно)';
											|en = 'Schedule (active)'; fa = 'Schedule (active)';
											|it = 'Orario (attivo)';
											|pl = 'Harmonogram (aktywny)';
											|tr = 'Program (etkin)'");
		Else
			Items.SchedulePage.Title = NStr("vi = 'Lịch biểu (chưa kích hoạt)';
											|ru = 'Расписание (не активно)';
											|en = 'Schedule (not active)'; fa = 'Schedule (not active)';
											|it = 'Orario (non attivo)';
											|pl = 'Harmonogram (nieaktywny)';
											|tr = 'Program (etkin değil)'");
		EndIf;
		Items.ExecuteOnScheduleParameters.Enabled = Object.ExecuteOnSchedule;
		Items.PeriodicityPages.Enabled           = Object.ExecuteOnSchedule;
		Items.GroupExecutionTime.Enabled           = Object.ExecuteOnSchedule;
	EndIf;
	
	If Changes = "" Or Changes = "SchedulePeriodicity" Then
		
		If Object.SchedulePeriodicity = PredefinedValue("Enum.ReportMailingSchedulePeriodicities.Daily") Then
			EnumerationName    = "Daily";
			VisiblePagesName = Items.DailyPage.Name;
		ElsIf Object.SchedulePeriodicity = PredefinedValue("Enum.ReportMailingSchedulePeriodicities.Weekly") Then
			EnumerationName    = "Weekly";
			VisiblePagesName = Items.WeeklyPage.Name;
		ElsIf Object.SchedulePeriodicity = PredefinedValue("Enum.ReportMailingSchedulePeriodicities.Monthly") Then
			EnumerationName    = "Monthly";
			VisiblePagesName = Items.MonthlyPage.Name;
		Else
			EnumerationName    = "CustomValue";
			VisiblePagesName = "";
		EndIf;
		
		For Each Page In Items.PeriodicityPages.ChildItems Do
			Page.Visible = (Page.Name = VisiblePagesName);
		EndDo;
		If EnumerationName = "CustomValue" Then
			Items.ModifySchedule.Visible = True;
			Items.GroupExecutionTime.Visible = False;
		Else
			Items.ModifySchedule.Visible = False;
			Items.GroupExecutionTime.Visible = True;
		EndIf;
		
		// Reset parameters that do not match simplified editing bookmarks.
		If Changes = "SchedulePeriodicity"
			And (EnumerationName = "Daily" 
			Or EnumerationName = "Weekly"
			Or EnumerationName = "Monthly") Then
			
			// Common parameters
			Form.Schedule.BeginDate = '00010101';
			Form.Schedule.EndDate  = '00010101';
			Form.Schedule.CompletionTime = '00010101';
			Form.Schedule.WeekDayInMonth = 0;
			Form.Schedule.DetailedDailySchedules = New Array;
			Form.Schedule.CompletionInterval = 0;
			Form.Schedule.RepeatPause = 0;
			Form.Schedule.WeeksPeriod = 0;
			
			If EnumerationName <> "Daily" Then
				Form.Schedule.DaysRepeatPeriod = 1;
			EndIf;
			
			If EnumerationName <> "Weekly" Then
				SelectedWeekDays = New Array;
				For IndexOf = 1 To 7 Do
					SelectedWeekDays.Add(IndexOf);
				EndDo;
				Form.Schedule.WeekDays = SelectedWeekDays;
			EndIf;
			
			If EnumerationName <> "Monthly" Then
				AllMonths = New Array;
				For IndexOf = 1 To 12 Do
					AllMonths.Add(IndexOf);
				EndDo;
				Form.Schedule.Months = AllMonths;
				Form.Schedule.DayInMonth = 0;
			EndIf;
		EndIf;
		
		// Restoring parameters on the current bookmark according to schedule parameters.
		If EnumerationName = "Daily" Then
			Form.BeginTime = Form.Schedule.BeginTime;
			Form.DaysRepeatPeriod = Form.Schedule.DaysRepeatPeriod;
		ElsIf EnumerationName = "Weekly" Then
			Form.BeginTime = Form.Schedule.BeginTime;
			For Each KeyAndValue In Form.Cache.Maps1.WeekDays Do
				Form[KeyAndValue.Key] = (Form.Schedule.WeekDays.Find(KeyAndValue.Value) <> Undefined);
			EndDo;
		ElsIf EnumerationName = "Monthly" Then
			Form.BeginTime = Form.Schedule.BeginTime;
			If Form.Schedule.DayInMonth >= 0 Then
				Form.DayInMonth = Form.Schedule.DayInMonth;
				Items.BegEndOfMonthHyperlink.Title = NStr("vi = 'bắt đầu';
															|ru = 'начала';
															|en = 'beginning'; fa = 'ابتدای';
															|it = 'начала';
															|pl = 'beginning';
															|tr = 'başlangıç'");
			Else
				Form.DayInMonth = -Form.Schedule.DayInMonth;
				Items.BegEndOfMonthHyperlink.Title = NStr("vi = 'kết thúc';
															|ru = 'конца';
															|en = 'end'; fa = 'end';
															|it = 'конца';
															|pl = 'end';
															|tr = 'son'");
			EndIf;
			For Each KeyAndValue In Form.Cache.Maps1.Months Do
				Form[KeyAndValue.Key] = (Form.Schedule.Months.Find(KeyAndValue.Value) <> Undefined);
			EndDo;
		EndIf;
		Form.RepeatPeriodInDay = SecondsToHours(Form.Schedule.RepeatPeriodInDay);
		Form.EndTime = Form.Schedule.EndTime;

		Form.UseHourlyRepeatPeriod = ValueIsFilled(Form.RepeatPeriodInDay);
		
	EndIf; // Changes = "" Or Changes = "SchedulePeriodicity"

	If Changes = "" Or Changes = "RepeatPeriodInDay" Or Changes = "SchedulePeriodicity" Then
		Items.RepeatPeriodInDay.Enabled = Form.UseHourlyRepeatPeriod;
		Items.ClockDecoration.Enabled = Form.UseHourlyRepeatPeriod;
		Items.EndTime.Enabled = Form.UseHourlyRepeatPeriod;
		Form.EndTime = ?(Form.UseHourlyRepeatPeriod, Form.EndTime, '00010101');
		Form.Schedule.EndTime = Form.EndTime;
	EndIf;
	
	If Changes = "" Or Changes = "MonthBeginEnd" Then
		Items.BegEndOfMonthHyperlink.Title = ?(Form.Schedule.DayInMonth >= 0, "beginning", "end");
	EndIf;
	
	If Changes = "" Or Changes = "DefaultFormats" Then
		Items.ResetDefaultFormat.Visible = (Form.DefaultFormats <> Form.DefaultFormatsListPresentation);
	EndIf;
	
	If Changes = "" Or Items.Pages.CurrentPage = Items.SchedulePage Then
		Items.SchedulePresentation.Visible = Object.ExecuteOnSchedule;
		If Object.ExecuteOnSchedule Then
			Items.SchedulePresentation.Title = SchedulePresentation(Form.Schedule);
		EndIf;
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Procedure SetCertificatePasswordsVisibilityAndAvailability(Form)
	Object = Form.Object;
	Items = Form.Items;

	If Form.CanEncryptAttachments Then
		If Object.Personalized Then
			Items["GroupEncryptionCertificates"].Visible = False;
			If Object.Archive Then
				Items.PasswordsEncryption.Title = NStr("vi = 'Thiết lập mật khẩu và mã hóa';
														|ru = 'Установить пароли и зашифровать';
														|en = 'Set passwords and encrypt data'; fa = 'تعیین رمز عبور و رمزگذاری داده‌ها';
														|it = 'Установить пароли и зашифровать';
														|pl = 'Set passwords and encrypt data';
														|tr = 'Parolaları yapılandır ve şifrele'");
			Else
				Items.PasswordsEncryption.Title = NStr("vi = 'Mã hóa';
														|ru = 'Зашифровать';
														|en = 'Encrypt data'; fa = 'Encrypt data';
														|it = 'Зашифровать';
														|pl = 'Encrypt data';
														|tr = 'Şifrele'");
			EndIf;
			Items.GroupPasswordsEncryption.Visible = True;
			Items.GroupArchivePassword.Visible = False;
			Items.PasswordsEncryption.Enabled = Object.ShouldSetPasswordsAndEncrypt;
			Items.PasswordsEncryption.ToolTipRepresentation = ToolTipRepresentation.Button;
			Items.PasswordsEncryption.ExtendedTooltip.Title = NStr("vi = 'Cài đặt và tùy chỉnh mật khẩu và mã hóa.
				|Khi gửi báo cáo hàng loạt qua email, cần lưu ý
				|một số máy chủ thư không thể nhận các tệp mã hóa.';
				|ru = 'Установка и настройка паролей и шифрования.
				|При рассылке отчетов по электронной почте необходимо учитывать,
				|что некоторые почтовые сервера могут не принимать зашифрованные файлы.';
				|en = 'Set and configure passwords and encryption.
				|When distributing reports by email, keep in mind that
				|some mail servers might not accept encrypted files.'; fa = 'Set and configure passwords and encryption.
				|When distributing reports by email, keep in mind that
				|some mail servers might not accept encrypted files.';
				|it = 'Установка и настройка паролей и шифрования.
				|При рассылке отчетов по электронной почте необходимо учитывать,
				|что некоторые почтовые сервера могут не принимать зашифрованные файлы.';
				|pl = 'Set and configure passwords and encryption.
				|When distributing reports by email, keep in mind that
				|some mail servers might not accept encrypted files.';
				|tr = 'Şifreleri ve şifrelemeyi ayarlamak ve kurmak.
				| E-posta ile rapor dağıtımı yaparken,
				| bazı e-posta sunucularının şifreli dosyaları kabul etmeyebileceğini göz önünde bulundurmak gerekir.'");
			Items.ShouldSetPasswordsAndEncrypt.Enabled = True;
		Else
			Items["GroupEncryptionCertificates"].Visible = ?(Form.Object.Personal, True, False);
			Items.GroupArchivePassword.Visible = True;
			Items.GroupPasswordsEncryption.Visible = False;
		EndIf;
	Else
		If Object.Personalized Then
			Items.PasswordsEncryption.Title = NStr("vi = 'Thiết lập mật khẩu';
													|ru = 'Установить пароли';
													|en = 'Set passwords'; fa = 'تعیین رمزهای عبور';
													|it = 'Установить пароли';
													|pl = 'Set passwords';
													|tr = 'Şifreyi kur'");
			Items.GroupPasswordsEncryption.Visible   = True;
			Items.GroupArchivePassword.Visible = False;
			Items.PasswordsEncryption.Enabled = Object.Archive And Object.ShouldSetPasswordsAndEncrypt;
			Items.PasswordsEncryption.ToolTipRepresentation = ToolTipRepresentation.Auto;
			Items.PasswordsEncryption.ExtendedTooltip.Title = NStr("vi = 'Cài đặt và tùy chỉnh mật khẩu.';
																	|ru = 'Установка и настройка паролей.';
																	|en = 'Set and configure passwords.'; fa = 'Set and configure passwords.';
																	|it = 'Установка и настройка паролей.';
																	|pl = 'Set and configure passwords.';
																	|tr = 'Şifre kurulumu ve ayarı.'");
			Items.ShouldSetPasswordsAndEncrypt.Enabled = Object.Archive;
		Else
			Items.GroupArchivePassword.Visible = True;
			Items.GroupPasswordsEncryption.Visible = False;
			If Items.Find("GroupEncryptionCertificates") <> Undefined Then
				Items["GroupEncryptionCertificates"].Visible = False;
			EndIf;
		EndIf;
	EndIf;

EndProcedure

// Generates the presentation of scheduled job schedule.
//
// Parameters:
//   Schedule - JobSchedule - a schedule.
//
// Returns:
//   String - a schedule presentation.
//
&AtClientAtServerNoContext
Function SchedulePresentation(Schedule)
	SchedulePresentation = String(Schedule);
	SchedulePresentation = Upper(Left(SchedulePresentation, 1)) + Mid(SchedulePresentation, 2);
	SchedulePresentation = StrReplace(StrReplace(SchedulePresentation, "  ", " "), " ]", "]") + ".";
	If ValueIsFilled(Schedule.BeginTime) Or ValueIsFilled(Schedule.EndTime) Then
		Supplement = AdditionOfSaaSSchedulePresentation();
		SchedulePresentation = ?(ValueIsFilled(Supplement), SchedulePresentation + Chars.LF + Supplement,
			SchedulePresentation);
	EndIf;
	Return SchedulePresentation;
EndFunction

&AtClientAtServerNoContext
Function RecipientsPresentation1(Form)
	Recipients  = Form.Object.Recipients;
	Included  = Recipients.FindRows(New Structure("Excluded", False));
	Disabled1 = Recipients.FindRows(New Structure("Excluded", True));
	
	DisabledPresentation = ReportMailingClientServer.ListPresentation(Disabled1, "Recipient", 0);
	Balance       = 75 - DisabledPresentation.LengthOfShort;
	Presentation = ReportMailingClientServer.ListPresentation(Included, "Recipient", Balance);
	
	RecipientsParameters = ReportMailingClientServer.RecipientsParameters();
	RecipientsParameters.Ref = Form.Object.Ref;
	RecipientsParameters.RecipientsEmailAddressKind = Form.Object.RecipientsEmailAddressKind;
	RecipientsParameters.Personal = Form.Object.Personal;
	RecipientsParameters.MailingRecipientType = Form.Object.MailingRecipientType;
	RecipientsParameters.Recipients = Form.Object.Recipients;
	
	NumberOfRecipients = RecipientsCountIncludingGroups(RecipientsParameters);
	
	If NumberOfRecipients.Total = 0 Then
		Presentation.Short = NStr("vi = '<Hãy chỉ ra người nhận>';
									|ru = '<Укажите получателей>';
									|en = '<Specify recipients>'; fa = '<Specify recipients>';
									|it = '<Specificare destinatari>';
									|pl = '<Wskaż odbiorców>';
									|tr = '<Alıcıları belirt>'");
		Return Presentation;
	EndIf;
	
	If DisabledPresentation.MaximumExceeded Then
		DisabledPresentation.Short = DisabledPresentation.Short + ", ...";
	EndIf;
	If Presentation.MaximumExceeded Then
		Presentation.Short = Presentation.Short + ", ...";
	EndIf;
	
	If NumberOfRecipients.ExcludedCount <> Undefined And NumberOfRecipients.ExcludedCount > 0 Then
		SplitTemplate = NStr("vi = 'Ngoại trừ';
							|ru = 'Кроме';
							|en = 'Except'; fa = 'Except';
							|it = 'Tranne';
							|pl = 'Oprócz';
							|tr = 'Hariç'")+ ": ";
		Presentation.Full = Presentation.Full + ";" + Chars.LF + SplitTemplate + DisabledPresentation.Full;
		If Presentation.LengthOfShort + DisabledPresentation.LengthOfShort <= 75 Then
			Presentation.Short = Presentation.Short + "; " + SplitTemplate + DisabledPresentation.Short;
		EndIf;
	EndIf;
	If Presentation.MaximumExceeded
		Or DisabledPresentation.MaximumExceeded Then
		If NumberOfRecipients.ExcludedCount <> Undefined And NumberOfRecipients.ExcludedCount > 0 Then
			EndTemplate = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '(tổng số %1, ngoại trừ %2)';
					|ru = '(всего %1, исключая %2)';
					|en = '(total %1 not including %2)'; fa = '(total %1 not including %2)';
					|it = '(totale %1, escluso %2)';
					|pl = '(łącznie %1, za wyjątkiem %2)';
					|tr = '(%2 hariç toplam %1)'"),
				NumberOfRecipients.Total,
				NumberOfRecipients.ExcludedCount);
		Else
			EndTemplate = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '(tổng số %1)';
					|ru = '(всего %1)';
					|en = '(total %1)'; fa = '(total %1)';
					|it = '(tutto%1)';
					|pl = '(łącznie %1)';
					|tr = '(toplam %1)'"),
				NumberOfRecipients.Total);
		EndIf;
		Presentation.Short = Presentation.Short + "; " + EndTemplate;
	EndIf;
	
	Return Presentation;
EndFunction

&AtServerNoContext
Function RecipientsCountIncludingGroups(RecipientsParameters)

	Return Catalogs.ReportMailings.RecipientsCountIncludingGroups(RecipientsParameters);

EndFunction

&AtClientAtServerNoContext
Procedure SetFormModified(Form, Field = "", DataPath = "", Text = "")
	If Not Form.Modified Then
		Form.FormWasModifiedAtServer = True;
		If ValueIsFilled(Text) Then
			Message = New UserMessage;
			Message.Text = Text;
			Message.Field = Field;
			Message.DataPath = DataPath;
			Message.Message();
		EndIf;
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Function DefaultFormatsPresentation()
	Return NStr("vi = 'theo mặc định';
				|ru = 'по умолчанию';
				|en = 'default'; fa = 'پیش‌فرض';
				|it = 'per default';
				|pl = 'domyślnie';
				|tr = 'varsayılan'");
EndFunction

&AtClientAtServerNoContext
Function RecipientsSpecified(Recipients)
	
	For Each TableRow In Recipients Do
		If Not TableRow.Excluded Then
			Return True;
		EndIf;
	EndDo;
	
	MessageText = NStr("vi = 'Chưa chọn người nhận nào.';
						|ru = 'Не выбрано ни одного получателя.';
						|en = 'No recipient is selected.'; fa = 'No recipient is selected.';
						|it = 'Не выбрано ни одного получателя.';
						|pl = 'No recipient is selected.';
						|tr = 'Herhangi bir alıcı seçilmedi.'");
	
	Message = New UserMessage;
	Message.Text = MessageText;
	Message.Field = "BulkEmailRecipients";
	Message.Message();
	
	Return False;
	
EndFunction

&AtClientAtServerNoContext
Function MailingRecipientValueTemplate(FilesAndEmailTextParameters)
	
	Return "[" + FilesAndEmailTextParameters.Recipient + "]";
	
EndFunction

&AtClientAtServerNoContext
Function HoursToSeconds(Hours1)
	Return Hours1 * 60 * 60;
EndFunction

&AtClientAtServerNoContext
Function SecondsToHours(Seconds)
	Return Seconds / 60 / 60;
EndFunction

#EndRegion

#Region ServerCallServer

&AtServerNoContext
Function RecipientMailAddresses(Recipient, ValueList)
	
	Recipients = New Array;
	Recipients.Add(Recipient);
	ContactInformationTypes = New Array;
	ContactInformationTypes.Add(Enums.ContactInformationTypes.Email);
	Try
		MailAddresses = ContactsManager.ObjectsContactInformation(Recipients, ContactInformationTypes,, CurrentSessionDate());
	Except
		Return ValueList;
	EndTry;
	
	EmailAddressesByKinds = New Map;
	For Each MailAddress In MailAddresses Do
		If Not ValueIsFilled(MailAddress.Presentation) Then 
			Continue;
		EndIf;
		EmailAddressesOfKind = EmailAddressesByKinds.Get(MailAddress.Kind);
		If EmailAddressesOfKind = Undefined Then
			EmailAddressesByKinds.Insert(MailAddress.Kind, MailAddress.Presentation);
		Else
			EmailAddressesByKinds[MailAddress.Kind]= EmailAddressesOfKind + ", " + MailAddress.Presentation;
		EndIf;
	EndDo;
	
	For Each Kind In EmailAddressesByKinds Do
		ValueList.Add(Kind.Key, Kind.Value + " (" + String(Kind.Key) + ")");
	EndDo;
	
	Return ValueList;
	
EndFunction

&AtServerNoContext
Function ChangeFolderAndFilesRight(Folder)
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
		Result = ModuleFilesOperationsInternal.RightToAddFilesToFolder(Folder);
	Else
		Result = True;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function CreatePassword()
	
	PasswordProperties = Users.PasswordProperties();
	PasswordProperties.MinLength = 8;
	
	Return Users.CreatePassword(PasswordProperties);
	
EndFunction

&AtServerNoContext
Function AdditionOfSaaSSchedulePresentation()
	
	If Common.DataSeparationEnabled() Then
		Return NStr("vi = 'Thời gian khởi động cụ thể có thể khác với thời gian chỉ định.';
					|ru = 'Точное время запуска может отличаться от указанного.';
					|en = 'The exact start time might differ from the specified one.'; fa = 'The exact start time might differ from the specified one.';
					|it = 'Точное время запуска может отличаться от указанного.';
					|pl = 'The exact start time might differ from the specified one.';
					|tr = 'Tam olarak başlatma zamanı belirtilenden farklı olabilir.'");
	Else
		Return "";
	EndIf;
	
EndFunction

&AtClient
Procedure UpdatePersonalizedDistributionRecipientParameterValue()
	
	If Not Object.Personalized Or Items.Reports.CurrentData = Undefined Then
		Return;
	EndIf;
	
	RecipientValueTemplate = MailingRecipientValueTemplate(FilesAndEmailTextParameters);
	ValueAsList = New ValueList;
	ValueAsList.Add(RecipientValueTemplate, RecipientValueTemplate);

	For Each SettingItem In DCSettingsComposer.UserSettings.Items Do
		If Not TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then
			Continue;
		EndIf;
		If SettingItem.Value = RecipientValueTemplate 
			Or TypeOf(SettingItem.Value) = Type("ValueList")
			And SettingItem.Value.FindByValue(RecipientValueTemplate) <> Undefined Then
			AvailableParameter = DCSettingsComposer.Settings.DataParameters.AvailableParameters.FindParameter(SettingItem.Parameter);
			If AvailableParameter <> Undefined And AvailableParameter.ValueListAllowed Then
				SettingItem.Value = ValueAsList;
				Items.Reports.CurrentData.ChangesMade = True;
			EndIf;
		EndIf;
	EndDo;

	FindPersonalizationSettings();
	
EndProcedure

&AtServer
Function ReportsOnActivateRowAtServer(RowID, AddCommonText = True, Val UserSettings = Undefined)
	// Save previous report settings.
	If RowID <> CurrentRowIDOfReportsTable And CurrentRowIDOfReportsTable <> -1 Then
		WriteReportsRowSettings(CurrentRowIDOfReportsTable);
	EndIf;
	CurrentRowIDOfReportsTable = RowID;
	
	// Row search.
	ReportsRow = Object.Reports.FindByID(RowID);
	If ReportsRow = Undefined Then
		CurrentRowIDOfReportsTable = -1;
		Return "";
	EndIf;
	
	If UserSettings = Undefined Then
		// Read current row settings from temporary storage or tabular section by reference.
		If IsTempStorageURL(ReportsRow.SettingsAddress) Then
			UserSettings = GetFromTempStorage(ReportsRow.SettingsAddress);
		Else
			RowIndex = Object.Reports.IndexOf(ReportsRow);
			ReportsRowObject = FormAttributeToValue("Object").Reports.Get(RowIndex);
			UserSettings = ?(ReportsRowObject = Undefined, Undefined, ReportsRowObject.Settings.Get());
		EndIf;
	EndIf;
	
	If Not ReportsRow.Enabled Then
		Items.ReportSettingsPages.CurrentPage = Items.PageEmpty;
		Return "";
	EndIf;
	
	// Initialization.
	ReportParameters = InitializeReport(ReportsRow, AddCommonText, UserSettings);
	
	FindPersonalizationSettings();
	
	Return ReportParameters.Errors;
EndFunction

&AtServer
Procedure FindPersonalizationSettings()
	
	PersonalizationSettings.Clear();
	
	Settings = DCSettingsComposer.UserSettings.Items;
	
	For Each SettingItem In Settings Do 
		
		SettingValue = Undefined;
		
		If TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then 
			
			SettingValue = SettingItem.RightValue;
			
		ElsIf TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
			
			SettingValue = SettingItem.Value;
		Else
			Continue;
		EndIf;
		
		If SettingValue <> MailingRecipientValueTemplate(FilesAndEmailTextParameters) Then 
			Continue;
		EndIf;
		
		TitleSettings = TitlePersonalizationSettings(SettingItem.UserSettingID);
		
		If TitleSettings <> Undefined Then 
			PersonalizationSettings.Add(TitleSettings);
		EndIf;
		
	EndDo;
	SetUpPersonalizationSettings();
	
EndProcedure

&AtServer
Function TitlePersonalizationSettings(SettingID)
	
	TitleSettings = Undefined;
	SettingDetails = Undefined;
	
	Settings = DCSettingsComposer.Settings;
	UserSettings = DCSettingsComposer.UserSettings;
	
	FoundSettings = UserSettings.GetMainSettingsByUserSettingID(
		SettingID);
	
	If FoundSettings.Count() = 0 Then 
		Return TitleSettings;
	EndIf;
	
	SettingItem = FoundSettings[0];
	
	If TypeOf(SettingItem) = Type("DataCompositionFilterItem") Then 
		
		TitleSettings = String(SettingItem.LeftValue);
		
		SettingDetails = Settings.Filter.FilterAvailableFields.FindField(
			SettingItem.LeftValue);
		
	ElsIf TypeOf(SettingItem) = Type("DataCompositionSettingsParameterValue") Then 
		
		TitleSettings = String(SettingItem.Parameter);
		
		SettingDetails = Settings.DataParameters.AvailableParameters.FindParameter(
			SettingItem.Parameter);
		
	EndIf;
	
	If SettingDetails <> Undefined Then 
		TitleSettings = SettingDetails.Title;
	EndIf;
	
	Return TitleSettings;
	
EndFunction

&AtServer
Procedure FillScheduleByOption(Variant, RefreshVisibility = False)
	
	Schedule = New JobSchedule;
	Schedule.BeginTime = '00010101073000'; // at 7:30 am
	Schedule.DaysRepeatPeriod = 1; // Every day.

	// On weekly basis.
	WeekDayMin = 1;
	WeekDayMax = 7;
	
	// On monthly basis.
	AllMonths = New Array;
	For IndexOf = 1 To 12 Do
		AllMonths.Add(IndexOf);
	EndDo;
	Schedule.Months = AllMonths;
	
	Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Daily;
	If Variant = 2 Then // Every other day.
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Daily;
		Schedule.DaysRepeatPeriod = 2;
		
	ElsIf Variant = 3 Then // Every fourth day
		Schedule.DaysRepeatPeriod = 4;
		
	ElsIf Variant = 4 Then // On weekdays.
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Weekly;
		WeekDayMin = 1;
		WeekDayMax = 5;
		
	ElsIf Variant = 5 Then // On weekends.
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Weekly;
		Schedule.BeginTime = '00010101220000'; // at 10:00 pm
		WeekDayMin = 6;
		WeekDayMax = 7;
		
	ElsIf Variant = 6 Then // On Mondays.
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Weekly;
		WeekDayMin = 1;
		WeekDayMax = 1;
		
	ElsIf Variant = 7 Then // On Fridays.
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Weekly;
		WeekDayMin = 5;
		WeekDayMax = 5;
		
	ElsIf Variant = 8 Then // On Sundays.
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Weekly;
		Schedule.BeginTime = '00010101220000'; // at 10:00 pm
		WeekDayMin = 7;
		WeekDayMax = 7;
		
	ElsIf Variant = 9 Then // In the first day of the month
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Monthly;
		Schedule.DayInMonth = 1;
		
	ElsIf Variant = 10 Then // In the last day of the month
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Monthly;
		Schedule.DayInMonth = -1;
		
	ElsIf Variant = 11 Then // WithEvery quarter on the 10th.
		AllMonths = New Array;
		AllMonths.Add(1);
		AllMonths.Add(4);
		AllMonths.Add(7);
		AllMonths.Add(10);
		Schedule.Months = AllMonths;
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.Monthly;
		Schedule.DayInMonth = 10;
		
	ElsIf Variant = 12 Then // Other...
		Object.SchedulePeriodicity = Enums.ReportMailingSchedulePeriodicities.CustomValue;
	EndIf;
	
	// On weekly basis.
	SelectedWeekDays = New Array;
	For IndexOf = WeekDayMin To WeekDayMax Do
		SelectedWeekDays.Add(IndexOf);
	EndDo;
	Schedule.WeekDays = SelectedWeekDays;
	
	If RefreshVisibility Then
		SetVisibilityAvailabilityAndCorrectness(ThisObject);
	EndIf;
EndProcedure

// Checks the selected report.
// 
// Parameters:
//   ChoiceStructure - Structure:
//     * SelectedItemsCount   - Structure - rows selected by the user.
//     * Success   - Structure - rows initialized and added to the list.
//     * WithErrors - Structure - rows not added to the list due to errors:
//         ** RowsArray - Array - Array of row IDs.
//         ** Count - Number - Number of rows.
//         ** ReportsPresentations - String - presentation of all reports of the specified rows.
//         ** Text - String - an error text.
//
&AtServer
Procedure CheckAddedReportRows(ChoiceStructure)
	ErrorsArray = New Array;
	
	ChoiceStructure.SelectedItemsCount.Count = ChoiceStructure.SelectedItemsCount.RowsArray.Count();
	For ReverseIndex = 1 To ChoiceStructure.SelectedItemsCount.Count Do
		IndexOf = ChoiceStructure.SelectedItemsCount.Count - ReverseIndex;
		ReportsRowID = ChoiceStructure.SelectedItemsCount.RowsArray[IndexOf];
		
		ReportsRow = Object.Reports.FindByID(ReportsRowID);
		If ReportsRow.Presentation = "" Then
			ReportsRow.Presentation = String(ReportsRow.Report);
		EndIf;
		
		WarningString = ReportsOnActivateRowAtServer(ReportsRowID, False);
		If WarningString = "" Then
			Var_Key = "Success";
		Else
			Var_Key = "WithErrors";
			ErrorsArray.Add(WarningString);
		EndIf;
		
		Rows = ChoiceStructure[Var_Key].RowsArray; // Array
		Rows.Add(ReportsRowID);
		
		ChoiceStructure[Var_Key].RowsArray = Rows;
		ChoiceStructure[Var_Key].Count = ChoiceStructure[Var_Key].Count + 1;
		ChoiceStructure[Var_Key].ReportsPresentations = ChoiceStructure[Var_Key].ReportsPresentations
			+ ?(ChoiceStructure[Var_Key].ReportsPresentations = "", "", ", ")
			+ ReportsRow.Presentation;
	EndDo;
	
	// Set cursor position on the first of the added items.
	If ChoiceStructure.Success.Count > 0 Then
		Items.Reports.CurrentRow = ChoiceStructure.Success.RowsArray[0];
		CurrentRowIDOfReportsTable = Items.Reports.CurrentRow;
		ReportsOnActivateRowAtServer(ReportsRowID, False);
	EndIf;
	
	// Error text assembly.
	If ChoiceStructure.WithErrors.Count > 0 Then
		ChoiceStructure.WithErrors.Text = ReportMailing.MessagesToUserString(ErrorsArray);
	EndIf;
EndProcedure

&AtServer
Function CheckTransportMethod(BulkEmail, Val DeliveryParameters)
	
	DeliveryParameters.ExecutionDate = CurrentSessionDate();
	DeliveryParameters.TestMode = True;
	
	// Initialize logging parameters.
	SetPrivilegedMode(True);
	
	LogParameters = New Structure;
	LogParameters.Insert("EventName",   NStr("vi = 'Gửi báo cáo. Kiểm tra cách thức gửi';
											|ru = 'Рассылка отчетов. Проверка способа доставки';
											|en = 'Report distribution. Testing delivery method'; fa = 'Report distribution. Testing delivery method';
											|it = 'Spedizione di report. Verifica di modalità di consegna';
											|pl = 'Subskrypcja raportów. Weryfikacja sposobu dostarczania';
											|tr = 'Rapor dağıtımı. Teslimat yöntemi kontrolü'", Common.DefaultLanguageCode()));
	LogParameters.Insert("Data",       BulkEmail);
	LogParameters.Insert("Metadata",   Metadata.Catalogs.ReportMailings);
	LogParameters.Insert("ErrorsArray", New Array);
	
	SetPrivilegedMode(False);
	
	// Write an empty spreadsheet document in html 5.
	FullFileName = GetTempFileName(".html");
	
	TabDoc = New SpreadsheetDocument;
	TabDoc.Write(FullFileName, SpreadsheetDocumentFileType.HTML5);
	
	// Generate attachments.
	File = New File(FullFileName);
	
	Attachments = New Map;
	Attachments.Insert(File.Name, File.FullName);
	
	// Delivery
	BeginTransaction(); // ACC:326 - Transaction opens only for a rollback.
	Try
		ReportMailing.ExecuteDelivery(LogParameters, DeliveryParameters, Attachments);
		RollbackTransaction(); // After the end of the test, all changes in the base are rolled back.
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	// Clean up attachments.
	For Each Attachment In Attachments Do
		DeleteFiles(Attachment.Value);
	EndDo;
	
	DeleteFiles(FullFileName);
	
	ExecutionResult = New Structure("Text, More", "", "");
	
	If LogParameters.ErrorsArray.Count() = 0 Then 
		ExecutionResult.Text = NStr("vi = 'Xác nhận giao hàng thành công.';
									|ru = 'Проверка возможности доставки успешно пройдена.';
									|en = 'Delivery verification completed successfully.'; fa = 'Delivery verification completed successfully.';
									|it = 'Verifica di possibilità di invio effettuata con successo.';
									|pl = 'Weryfikacja możliwości dostawy przeszła pomyślnie.';
									|tr = 'Teslimat yeteneği kontrolü başarıyla tamamlandı.'");
	Else
		ExecutionResult.Text = NStr("vi = 'Xác nhận giao hàng thất bại.';
									|ru = 'Проверка возможности доставки не пройдена.';
									|en = 'Delivery verification failed.'; fa = 'Delivery verification failed.';
									|it = 'Verifica di possibilità di invio fallita.';
									|pl = 'Weryfikacja możliwości dostawy nie przeszło.';
									|tr = 'Teslimat kontrolü başarısız oldu.'");
		ExecutionResult.More = ReportMailing.MessagesToUserString(LogParameters.ErrorsArray, False);
	EndIf;
	
	Return ExecutionResult;
EndFunction

&AtServer
Function PutRecipientsInStorage()
	Return PutToTempStorage(Object.Recipients.Unload(), UUID);
EndFunction

&AtServer
Function HasPeriodInSettings(RowID)

	ReportsRow = Object.Reports.FindByID(RowID);
	If ReportsRow = Undefined Then
		Return False;
	EndIf;
	
	If IsTempStorageURL(ReportsRow.SettingsAddress) Then
		UserSettings = GetFromTempStorage(ReportsRow.SettingsAddress);
	Else
		RowIndex = Object.Reports.IndexOf(ReportsRow);
		ReportsRowObject = FormAttributeToValue("Object").Reports.Get(RowIndex);
		UserSettings = ?(ReportsRowObject = Undefined, Undefined, ReportsRowObject.Settings.Get());
	EndIf;  
	
	If UserSettings = Undefined Then
		ReportParameters = New Structure("Report, Settings", ReportsRow.Report, Undefined);
		LogParameters = New Structure;
		LogParameters.Insert("EventName",   NStr("vi = 'Gửi hàng loạt báo cáo. Khởi tạo báo cáo';
												|ru = 'Рассылка отчетов. Инициализация отчета';
												|en = 'Report distribution. Report initialization'; fa = 'Report distribution. Report initialization';
												|it = 'Spedizione di report. Inizializzazione del report';
												|pl = 'Subskrypcja raportów. Inicjalizacja raportu';
												|tr = 'Rapor gönderimi. Rapor başlatma'", Common.DefaultLanguageCode()));
		LogParameters.Insert("Data",       ?(ValueIsFilled(Object.Ref), Object.Ref, ReportsRow.Report));
		LogParameters.Insert("Metadata",   Metadata.Catalogs.ReportMailings);
		LogParameters.Insert("ErrorsArray", New Array);

		ReportMailing.InitializeReport(
			LogParameters,
			ReportParameters,
			Object.Personalized,
			UUID);
		If ReportParameters.DCSettings <> Undefined Then
			UserSettings = ReportParameters.DCSettings.DataParameters;
		EndIf;
	EndIf;
	
	Period = ReportMailing.GetPeriodFromUserSettings(UserSettings);
	If Period <> Undefined Then
		Return True;
	EndIf;

	Return False;

EndFunction

&AtServer
Procedure AddTemplateAdditionalParameters(TemplateParameters, Recipient)

	If EmailTextAdditionalParameters = Undefined Then
		Return;
	EndIf;

	TemplateAdditionalParameters = New Structure;
	For Each Parameter In EmailTextAdditionalParameters Do
		TemplateAdditionalParameters.Insert(Parameter.Value.Name, "");
	EndDo;
	
	ReportMailingOverridable.OnReceiveEmailTextParameters(BulkEmailType, MailingRecipientType, Recipient, TemplateAdditionalParameters);
	
	For Each Parameter In TemplateAdditionalParameters Do
		TemplateParameters.Insert(Parameter.Key, Parameter.Value);
	EndDo;

EndProcedure

&AtServer
Function GetFirstRecipient()
	
	RecipientsParameters = ReportMailingClientServer.RecipientsParameters();
	RecipientsParameters.Recipients = Object.Recipients;
	RecipientsParameters.Author = Object.Author;
	RecipientsParameters.Personal = Object.Personal;
	RecipientsParameters.MailingRecipientType = Object.MailingRecipientType;
	RecipientsParameters.RecipientsEmailAddressKind = Object.RecipientsEmailAddressKind;
	
	DistributionRecipientsList = ReportMailing.GenerateMailingRecipientsList(RecipientsParameters, Undefined);
	
	RecipientsMetadata = Common.MetadataObjectByID(Object.MailingRecipientType, False);
	MetadataObjectKey = ?(ValueIsFilled(Object.MailingRecipientType),
			Common.ObjectAttributeValue(Object.MailingRecipientType, "MetadataObjectKey"), Undefined);
	RecipientsType = ?(MetadataObjectKey <> Undefined, MetadataObjectKey.Get(), Undefined);

	FirstRecipient = New Structure ("Description, Ref", "", New (RecipientsType));
	
	For Each Recipient In DistributionRecipientsList Do
		FirstRecipient.Ref = Recipient.Key;
		Break;
	EndDo;
	
	If ValueIsFilled(FirstRecipient.Ref) Then
		FirstRecipient.Description = Common.ObjectAttributeValue(FirstRecipient.Ref, "Description");
	EndIf;
	
	Return FirstRecipient;
	
EndFunction

&AtServer
Function ReportsPlannedListInAttachments()

	ListFileNames = New Array;
	DeliveryParameters = New Structure("TransliterateFileNames", Object.TransliterateFileNames);

	// Formats parameters.
	FormatsParameters = New Map;
	For Each MetadataFormat In Metadata.Enums.ReportSaveFormats.EnumValues Do
		Format = Enums.ReportSaveFormats[MetadataFormat.Name];
		FormatParameters = ReportMailing.WriteSpreadsheetDocumentToFormatParameters(Format);
		FormatParameters.Insert("Name", MetadataFormat.Name);
		FormatsParameters.Insert(Format, FormatParameters);
	EndDo;

	For Each RowReport In Object.Reports Do
		FormatsOfReport = New Array;
		FoundItems = Object.ReportFormats.FindRows(New Structure("Report", RowReport.Report));

		If FoundItems.Count() = 0 Then
			For Each StringFormat In DefaultFormatsList Do
				If Not StringFormat.Check Then
					Continue;
				EndIf;
				FormatsOfReport.Add(StringFormat.Value);
			EndDo;
		Else
			For Each StringFormat In FoundItems Do
				FormatsOfReport.Add(StringFormat.Format);
			EndDo;
		EndIf;
		If IsTempStorageURL(RowReport.SettingsAddress) Then
			UserSettings = GetFromTempStorage(RowReport.SettingsAddress);
		Else
			RowIndex = Object.Reports.IndexOf(RowReport);
			ReportsRowObject = FormAttributeToValue("Object").Reports.Get(RowIndex);
			UserSettings = ?(ReportsRowObject = Undefined, Undefined, ReportsRowObject.Settings.Get());
		EndIf;
		Period = ReportMailing.GetPeriodFromUserSettings(UserSettings);

		For Each Format In FormatsOfReport Do
			FormatParameters = FormatsParameters.Get(Format);
			FullFileName = ReportMailing.FullFileNameFromTemplate(
			"", RowReport.Presentation, FormatParameters, DeliveryParameters, RowReport.DescriptionTemplate, Period);

			// Extension mechanism.
			ReportMailingOverridable.BeforeSaveSpreadsheetDocumentToFormat(
			True,
			New SpreadsheetDocument,
			Format,
			FullFileName);

			ListFileNames.Add(FullFileName);
		EndDo;

	EndDo;

	Return ListFileNames;

EndFunction

&AtServerNoContext
Function PutPicturesToTempStorage(PicturesForHTML)
	
	StringType = New TypeDescription("String");
	
	Attachments = New ValueTable;
	Attachments.Columns.Add("AddressInTempStorage", StringType);
	Attachments.Columns.Add("Id", StringType);
	Attachments.Columns.Add("Extension", StringType);
	
	For Each PictureForHTML In PicturesForHTML Do
		StringAttachment = Attachments.Add();
		FileAttachment = PictureForHTML.Value.GetBinaryData();
		StringAttachment.AddressInTempStorage = PutToTempStorage(FileAttachment);
		StringAttachment.Id = PictureForHTML.Key;
		StringAttachment.Extension = String(PictureForHTML.Value.Format());
	EndDo;
	
	Return PutToTempStorage(Attachments);
	
EndFunction

&AtServerNoContext
Function IsMemberOfPersonalReportGroup(Group)
	
	Return ReportMailing.IsMemberOfPersonalReportGroup(Group);
	
EndFunction

#EndRegion

#Region Server

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	ProhibitedCellTextColor = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CurrentReportSettings.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CurrentReportSettings.Found");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", ProhibitedCellTextColor);
	Item.Appearance.SetParameterValue("Enabled", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Reports.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportFormats.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Reports.Enabled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", ProhibitedCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportsFormatsDescriptionTemplate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Reports.DescriptionTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "";

	Item.Appearance.SetParameterValue("TextColor", ProhibitedCellTextColor);
	Item.Appearance.SetParameterValue("Text", "[" + FilesAndEmailTextParameters.ReportDescription1 + "] [" 
		+ FilesAndEmailTextParameters.ReportFormat + "]");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReportFormatsFormats.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Reports.Formats");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "";

	Item.Appearance.SetParameterValue("TextColor", ProhibitedCellTextColor);
	Item.Appearance.SetParameterValue("Text", DefaultFormatsPresentation());
	
	//
	
	SetUpPersonalizationSettings();
	
EndProcedure

&AtServer
Procedure SetUpPersonalizationSettings()
	
	Item = Undefined;
	DesignParameter = New DataCompositionParameter("Text");
	
	For Each AppearanceItem In ConditionalAppearance.Items Do 
		
		ParameterValue = AppearanceItem.Appearance.FindParameterValue(DesignParameter);
		If ParameterValue.Value = MailingRecipientValueTemplate(FilesAndEmailTextParameters) Then 
			
			Item = AppearanceItem;
			Break;
			
		EndIf;
		
	EndDo;
	
	If Item <> Undefined Then 
		
		ItemFilter = Item.Filter.Items[0];
		ItemFilter.RightValue = PersonalizationSettings;
		Return;
		
	EndIf;
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UserSettingsValue.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DCSettingsComposer.UserSettings.Setting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = PersonalizationSettings;
	
	Item.Appearance.SetParameterValue("Text", MailingRecipientValueTemplate(FilesAndEmailTextParameters));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	FontImportantLabel = Metadata.StyleItems.ImportantLabelFont;
	Item.Appearance.SetParameterValue("Font", FontImportantLabel.Value);
	
	
EndProcedure

&AtServer
Function GetCache()
	
	// Convert descriptions to values.
	WeekDays = New Map;
	WeekDays.Insert(Items.Monday.Name, 1);
	WeekDays.Insert(Items.Tuesday.Name,     2);
	WeekDays.Insert(Items.Wednesday.Name,       3);
	WeekDays.Insert(Items.Thursday.Name,     4);
	WeekDays.Insert(Items.Friday.Name,     5);
	WeekDays.Insert(Items.Saturday.Name,     6);
	WeekDays.Insert(Items.Sunday.Name, 7);
	WeekDays = New FixedMap(WeekDays);
	
	Months = New Map;
	Months.Insert(Items.January.Name,   1);
	Months.Insert(Items.February.Name,  2);
	Months.Insert(Items.March.Name,     3);
	Months.Insert(Items.April.Name,   4);
	Months.Insert(Items.May.Name,      5);
	Months.Insert(Items.June.Name,     6);
	Months.Insert(Items.July.Name,     7);
	Months.Insert(Items.August.Name,   8);
	Months.Insert(Items.September.Name, 9);
	Months.Insert(Items.October.Name,  10);
	Months.Insert(Items.November.Name,   11);
	Months.Insert(Items.December.Name,  12);
	Months = New FixedMap(Months);
	
	// Defaults for fields that support filling templates.
	Templates = New FixedStructure("Subject, Text, ArchiveName",
		ReportMailingClientServer.SubjectTemplate(FilesAndEmailTextParameters),
		ReportMailing.TextTemplate1(FilesAndEmailTextParameters),
		ReportMailingClientServer.ArchivePatternName(FilesAndEmailTextParameters));
	
	// Cache structure.
	Cache = New Structure;
	Cache.Insert("EmptyReportValue", ReportMailing.EmptyReportValue());
	Cache.Insert("PersonalMailingsGroup", Catalogs.ReportMailings.PersonalMailings);
	Cache.Insert("SystemTitle", ReportMailing.ThisInfobaseName());
	Cache.Insert("Maps1", New FixedStructure("WeekDays, Months", WeekDays, Months));
	Cache.Insert("Templates", Templates);
	Cache.Insert("ReportsToExclude", ReportMailingCached.ReportsToExclude());
	
	Return New FixedStructure(Cache);
EndFunction

&AtServer
Procedure FillReportTableInfo()
	ReportsAvailability = ReportsOptions.ReportsAvailability(Object.Reports.Unload(, "Report").UnloadColumn("Report"));
	For Each ReportsRow In Object.Reports Do
		ReportInformation = ReportsAvailability.Find(ReportsRow.Report, "Ref");
		If ReportInformation = Undefined Then
			ReportsRow.Enabled = False;
			ReportsRow.Presentation = NStr("vi = '<Không đủ quyền để làm việc với báo cáo>';
											|ru = '<Недостаточно прав для работы с отчетом>';
											|en = '<Insufficient rights to access the report>'; fa = '<Insufficient rights to access the report>';
											|it = '<Permessi insufficienti per lavorare con il report>';
											|pl = '<Niewystarczające uprawnienia do pracy z raportm>';
											|tr = '<Rapora ulaşmak için çalışma hakları yetersiz>'");
		Else
			ReportsRow.Enabled = ReportInformation.Available;
			ReportsRow.Presentation = ReportInformation.Presentation;
		EndIf;
		ReportsRow.Formats = "";
		FoundItems = Object.ReportFormats.FindRows(New Structure("Report", ReportsRow.Report));
		For Each StringFormat In FoundItems Do
			ReportsRow.Formats = ReportsRow.Formats + ?(ReportsRow.Formats = "", "", ", ") + String(StringFormat.Format);
		EndDo;
	EndDo;
EndProcedure

&AtServer
Procedure ReadJobSchedule()
	SetPrivilegedMode(True);
	JobID = ?(CreatedByCopying, Common.ObjectAttributeValue(MailingBasis,
		"ScheduledJob"), Object.ScheduledJob);
	If TypeOf(JobID) = Type("UUID") Then
		Job = ScheduledJobsServer.Job(JobID);
		If Job <> Undefined Then
			Schedule = Job.Schedule;
			If Object.SchedulePeriodicity <> Enums.ReportMailingSchedulePeriodicities.CustomValue
				And Not ValueIsFilled(Schedule.RepeatPeriodInDay) Then
				Schedule.EndTime = '00010101';
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure ReadObjectSettingsOfObjectToCopy()
	RowsCount = Object.Reports.Count();
	ReportsDistributionsBases = Common.ObjectAttributeValue(MailingBasis, "Reports").Unload();
	For ReverseIndex = 1 To RowsCount Do
		IndexOf = RowsCount - ReverseIndex;
		ReportsRow = Object.Reports.Get(IndexOf);
		ObjectToCopyReportsRow = ReportsDistributionsBases.Get(IndexOf);
		
		DCUserSettings = ObjectToCopyReportsRow.Settings.Get();
		
		ReportsRow.ChangesMade = True;
		
		RowID = ReportsRow.GetID();
		WarningString = ReportsOnActivateRowAtServer(RowID, True, DCUserSettings);
		If IndexOf = 0 Then
			WriteReportsRowSettings(CurrentRowIDOfReportsTable);
		EndIf;
		If WarningString <> "" Then
			Common.MessageToUser(WarningString, , "Object.Reports["+ IndexOf +"].Presentation");
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure ConnectEmailSettingsCache()
	// Connect recipients type cache.
	RecipientsTypesTable.Load(ReportMailingCached.RecipientsTypesTable());
	
	// Fill the recipients type selection list.
	For Each RecipientRow In RecipientsTypesTable Do
		Items.MailingRecipientType.ChoiceList.Add(RecipientRow.RecipientsType, RecipientRow.Presentation);
		If RecipientRow.MetadataObjectID = Object.MailingRecipientType Then
			MailingRecipientType = RecipientRow.RecipientsType;
			If Object.RecipientsEmailAddressKind.IsEmpty() And ValueIsFilled(RecipientRow.MainCIKind) Then
				Object.RecipientsEmailAddressKind = RecipientRow.MainCIKind;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure FillEmptyTemplatesWithStandard(CurrentObject)
	// Object data.
	If IsBlankString(CurrentObject.EmailSubject) Then
		CurrentObject.EmailSubject = Cache.Templates.Subject;
	EndIf;
	If IsBlankString(CurrentObject.EmailText) Then
		CurrentObject.EmailText = Cache.Templates.Text;
	EndIf;
	If IsBlankString(CurrentObject.ArchiveName) Then
		CurrentObject.ArchiveName = Cache.Templates.ArchiveName;
	EndIf;
	// Form data.
	If IsBlankString(EmailTextFormattedDocument.GetText()) Then
		EmailTextFormattedDocument.Add(Cache.Templates.Text, FormattedDocumentItemType.Text);
	EndIf;
EndProcedure

&AtServer
Procedure WriteReportsRowSettings(RowID)
	ReportsRow = Object.Reports.FindByID(RowID);
	If ReportsRow = Undefined Then
		Return;
	EndIf;
	
	If Not ReportsRow.Initialized Then
		ValueToSave = Undefined;
	ElsIf ReportsRow.DCS Then
		ValueToSave = DCSettingsComposer.UserSettings;
	Else
		ColumnsNames = "Attribute, Presentation, Value, Use";
		Filter = New Structure("Found", True);
		ValueToSave = CurrentReportSettings.Unload().Copy(Filter, ColumnsNames);
	EndIf;
	
	Address = ?(IsTempStorageURL(ReportsRow.SettingsAddress), ReportsRow.SettingsAddress, UUID);
	
	ReportsRow.SettingsAddress = PutToTempStorage(ValueToSave, Address);
EndProcedure

&AtServer
Function InitializeReport(ReportsRow, AddCommonText, UserSettings, Interactively = True)
	// Log parameters.
	LogParameters = New Structure;
	LogParameters.Insert("EventName",   NStr("vi = 'Gửi hàng loạt báo cáo. Khởi tạo báo cáo';
											|ru = 'Рассылка отчетов. Инициализация отчета';
											|en = 'Report distribution. Report initialization'; fa = 'Report distribution. Report initialization';
											|it = 'Spedizione di report. Inizializzazione del report';
											|pl = 'Subskrypcja raportów. Inicjalizacja raportu';
											|tr = 'Rapor gönderimi. Rapor başlatma'", Common.DefaultLanguageCode()));
	LogParameters.Insert("Data",       ?(ValueIsFilled(Object.Ref), Object.Ref, ReportsRow.Report));
	LogParameters.Insert("Metadata",   Metadata.Catalogs.ReportMailings);
	LogParameters.Insert("ErrorsArray", New Array);
	
	// Initialize report.
	ReportParameters = New Structure("Report, Settings", ReportsRow.Report, UserSettings);
	ReportMailing.InitializeReport(
		LogParameters,
		ReportParameters,
		Object.Personalized,
		UUID);
	
	ReportParameters.Insert("ErrorsArray", LogParameters.ErrorsArray);
	ReportParameters.Errors = ReportMailing.MessagesToUserString(ReportParameters.ErrorsArray, AddCommonText);
	
	If ReportParameters.Initialized Then
		ReportsRow.DCS             = ReportParameters.DCS;
		ReportsRow.Initialized = ReportParameters.Initialized;
		ReportsRow.FullName       = ReportParameters.FullName;
		ReportsRow.VariantKey    = ReportParameters.VariantKey;
		// Support the ability to directly select additional reports references in reports mailings.
		If ValueIsFilled(ReportParameters.OptionRef1) Then
			ReportsRow.Report         = ReportParameters.OptionRef1;
			ReportsRow.Presentation = String(ReportsRow.Report);
		EndIf;
	EndIf;
	
	If Not Interactively Then
		Return ReportParameters;
	EndIf;
	
	// Check the initialization result.
	If Not ReportsRow.Initialized Then
		// Delete row.
		Object.Reports.Delete(ReportsRow);
		
		// Empty settings page.
		Items.ReportSettingsPages.CurrentPage = Items.PageEmpty;
		
		Return ReportParameters;
	EndIf;
	
	// Restore settings.
	If ReportsRow.DCS Then
		
		DCSettingsComposer = ReportParameters.DCSettingsComposer;
		Items.ReportSettingsPages.CurrentPage = Items.ComposerPage;
		
	Else
		
		// Clear & Restore
		If TypeOf(UserSettings) = Type("ValueTable") Then
			CurrentReportSettings.Load(UserSettings);
		Else
			CurrentReportSettings.Clear();
		EndIf;
		
		For Each KeyAndValue In ReportParameters.AvailableAttributes Do
			// Update attributes to be evaluated.
			FoundItems = CurrentReportSettings.FindRows(New Structure("Attribute", KeyAndValue.Key));
			If FoundItems.Count() = 0 Then
				SettingRow = CurrentReportSettings.Add();
				SettingRow.Attribute = KeyAndValue.Key;
			Else
				SettingRow = FoundItems[0];
			EndIf;
			SettingRow.Presentation = KeyAndValue.Value.Presentation;
			SettingRow.Type           = KeyAndValue.Value.Type;
			SettingRow.Found     = True;
			SettingRow.PictureIndex = 3;
		EndDo;
		
		// Disable undetected rows.
		FoundItems = CurrentReportSettings.FindRows(New Structure("Found", False));
		For Each SettingRow In FoundItems Do
			SettingRow.Use = False;
			SettingRow.PictureIndex = 4;
		EndDo;
		
		Items.ReportSettingsPages.CurrentPage = Items.CurrentReportSettingsPage;
		
	EndIf;
	
	Return ReportParameters;
EndFunction

&AtServer
Procedure AddReportsSettings(ReportsToAttach)
	
	For Each ReportsParametersRow In ReportsToAttach Do
		If TypeOf(ReportsParametersRow.OptionRef) = Type("CatalogRef.ReportsOptions")
			And ReportsParametersRow.OptionRef <> Catalogs.ReportsOptions.EmptyRef() Then
			OptionRef = ReportsParametersRow.OptionRef;
		Else
			ReportInformation = ReportsOptions.ReportInformation(ReportsParametersRow.ReportFullName);
			If Not IsBlankString(ReportInformation.ErrorText) Then
				If Not IsBlankString(PopupAlertTextOnOpen) Then
					PopupAlertTextOnOpen = PopupAlertTextOnOpen + Chars.LF;
				EndIf;
				PopupAlertTextOnOpen = PopupAlertTextOnOpen + ReportInformation.ErrorText;
			EndIf;
			OptionRef = ReportsOptions.ReportVariant(ReportInformation.Report, ReportsParametersRow.VariantKey);
		EndIf;
		
		If OptionRef.DeletionMark Then
			Continue;
		EndIf;
		
		FoundItems = Object.Reports.FindRows(New Structure("Report", OptionRef));
		If FoundItems.Count() > 0 Then
			ReportsRow = FoundItems[0];
		Else
			ReportsRow = Object.Reports.Add();
			ReportsRow.Report                = OptionRef;
			ReportsRow.SendIfEmpty = False;
			ReportsRow.DoNotSendIfEmpty   = True;
			ReportsRow.Enabled          = True;
		EndIf;
		
		ReportsRow.ChangesMade = True;
		
		If Not IsNew Then
			If FoundItems.Count() > 0 Then
				MessageRowTemplate = NStr("vi = 'Đối với báo cáo ""%1"" đã kết nhập tùy chỉnh tự tạo mới.';
											|ru = 'Для отчета ""%1"" загружены новые пользовательские настройки.';
											|en = 'New user settings are imported for report ''%1''.'; fa = 'New user settings are imported for report ''%1''.';
											|it = 'Nuove impostazioni personalizzate caricate per il report ""%1"".';
											|pl = 'Dla raportu ""%1"" pobrano nowe ustawienia niestandardowe.';
											|tr = '''%1'' raporu için yeni kullanıcı ayarları getirildi.'");
			Else
				MessageRowTemplate = NStr("vi = 'Đã thêm báo cáo ""%1"".';
											|ru = 'Добавлен отчет ""%1"".';
											|en = '""%1"" report is added.'; fa = '""%1"" report is added.';
											|it = 'Aggiunto report ""%1"".';
											|pl = 'Dodano raport ""%1"".';
											|tr = '""%1"" raporu eklendi.'");
			EndIf;
			MessageRowTemplate = StringFunctionsClientServer.SubstituteParametersToString(MessageRowTemplate, String(OptionRef));
			If Not IsBlankString(PopupAlertTextOnOpen) Then
				PopupAlertTextOnOpen = PopupAlertTextOnOpen + Chars.LF;
			EndIf;
			PopupAlertTextOnOpen = PopupAlertTextOnOpen + MessageRowTemplate;
			RowIndex = Object.Reports.IndexOf(ReportsRow);
		EndIf;
		
		DCUserSettings = ReportsParametersRow.Settings;
		
		RowID = ReportsRow.GetID();
		Items.Reports.CurrentRow = RowID;
		WarningString = ReportsOnActivateRowAtServer(RowID, True, DCUserSettings);
		If WarningString <> "" Then
			Common.MessageToUser(WarningString, , "Object.Reports["+ RowIndex +"].Presentation");
		Else
			WriteReportsRowSettings(RowID);
		EndIf;
	EndDo;
	
	CurrentRowIDOfReportsTable = -1;
EndProcedure

&AtServer
Procedure CreateAttributeItemEncryptionCertificate()
	
	If Not ReportMailing.CanEncryptAttachments() Then
		CanEncryptAttachments = False;
		Return;
	EndIf;
	
	CanEncryptAttachments = True;
	
	If Items.Find("GroupEncryptionCertificates") <> Undefined Then
		Return;
	EndIf;
	
	AttributesToAddArray = New Array;
	AttributesToAddArray.Add(New FormAttribute("CertificateToEncrypt",
		New TypeDescription("CatalogRef.DigitalSignatureAndEncryptionKeysCertificates"),,
		NStr("vi = 'Chứng thư để mã hóa';
			|ru = 'Сертификат для шифрования';
			|en = 'Encryption certificate'; fa = 'گواهی رمزگذاری';
			|it = 'Сертификат для шифрования';
			|pl = 'Encryption certificate';
			|tr = 'Şifreleme için sertifika'")));
		
	ChangeAttributes(AttributesToAddArray);
	
	Var_Group = Items.Add("GroupEncryptionCertificates", Type("FormGroup"), Items.ReportsFilesSettings);
	Var_Group.Type = FormGroupType.UsualGroup;
	Var_Group.Title = NStr("vi = 'Chứng thư để mã hóa';
							|ru = 'Сертификат для шифрования';
							|en = 'Encryption certificate'; fa = 'گواهی رمزگذاری';
							|it = 'Сертификат для шифрования';
							|pl = 'Encryption certificate';
							|tr = 'Şifreleme için sertifika'");
	Var_Group.ShowTitle = False;
	Var_Group.EnableContentChange = False;
	Var_Group.Representation = UsualGroupRepresentation.None;
	Var_Group.United = True;
	Var_Group.Behavior = UsualGroupBehavior.Usual;
	Var_Group.ThroughAlign = ThroughAlign.DontUse;
	
	Item = Items.Add("CertificateToEncrypt", Type("FormField"), Var_Group);
	Item.Title = NStr("vi = 'Chứng thư để mã hóa';
						|ru = 'Сертификат для шифрования';
						|en = 'Encryption certificate'; fa = 'گواهی رمزگذاری';
						|it = 'Сертификат для шифрования';
						|pl = 'Encryption certificate';
						|tr = 'Şifreleme için sertifika'");
	Item.DataPath = "CertificateToEncrypt";
	Item.Width = 70;
	Item.Type = FormFieldType.InputField;
	Item.SetAction("OnChange", "Attachable_EncryptionCertificateOnChange"); 
	Item.ToolTipRepresentation = ToolTipRepresentation.Button;
	Item.ExtendedTooltip.Title = NStr("vi = 'Khi gửi báo cáo hàng loạt qua email, cần lưu ý
		|một số máy chủ thư không thể nhận tệp mã hóa.';
		|ru = 'При рассылке отчетов по электронной почте необходимо учитывать,
		|что некоторые почтовые сервера могут не принимать зашифрованные файлы.';
		|en = 'When distributing reports by email, keep in mind that
		|some mail servers might not accept encrypted files.'; fa = 'When distributing reports by email, keep in mind that
		|some mail servers might not accept encrypted files.';
		|it = 'При рассылке отчетов по электронной почте необходимо учитывать,
		|что некоторые почтовые сервера могут не принимать зашифрованные файлы.';
		|pl = 'When distributing reports by email, keep in mind that
		|some mail servers might not accept encrypted files.';
		|tr = 'E-posta ile rapor dağıtımı yaparken,
		| bazı e-posta sunucularının şifreli dosyaları kabul etmeyebileceğini göz önünde bulundurmak gerekir.'");

EndProcedure

&AtServer
Procedure DoDisplayImportance()

	If Object.EmailImportance = EmailOperationsInternalClientServer.InternetMailMessageImportanceHigh() Then
		Items.SeverityGroup.Picture = PictureLib.ImportanceHigh;
		Items.SeverityGroup.ToolTip = NStr("vi = 'Mức độ quan trọng cao';
											|ru = 'Высокая важность';
											|en = 'High importance'; fa = 'اهمیت بالا';
											|it = 'Alta importanza';
											|pl = 'Wysoka ważność';
											|tr = 'Yüksek önemlilik'");
	ElsIf Object.EmailImportance = EmailOperationsInternalClientServer.InternetMailMessageImportanceLow() Then
		Items.SeverityGroup.Picture = PictureLib.ImportanceLow;
		Items.SeverityGroup.ToolTip = NStr("vi = 'Mức độ quan trọng thấp';
											|ru = 'Низкая важность';
											|en = 'Low importance'; fa = 'اهمیت پایین';
											|it = 'Bassa importanza';
											|pl = 'Niska ważność';
											|tr = 'Az önemlilik'");
	Else
		Items.SeverityGroup.Picture = PictureLib.ImportanceNotSpecified;
		Items.SeverityGroup.ToolTip = NStr("vi = 'Mức độ quan trọng thường';
											|ru = 'Обычная важность';
											|en = 'Normal importance'; fa = 'اهمیت عادی';
											|it = 'Media importanza';
											|pl = 'Zwykła ważność';
											|tr = 'Normal önemlilik'");
	EndIf;

EndProcedure

&AtServer
Procedure AddCommandsAddTextAdditionalParameters()
	ReportMailing.AddCommandsAddTextAdditionalParameters(ThisObject);
	UpdateListOfFilesAndEmailTextParameters();
EndProcedure

&AtServer
Procedure UpdateListOfFilesAndEmailTextParameters()
	FilesAndEmailTextParameters = ReportMailingCached.FilesAndEmailTextParameters();
	MailingRecipientType = ?(BulkEmailType = "Personal", Undefined, MailingRecipientType);
	ReportMailingOverridable.OnDefineEmailTextParameters(BulkEmailType, MailingRecipientType, FilesAndEmailTextParameters);
EndProcedure

&AtServer
Procedure CheckPeriodsInReports(NewRowArray = Undefined)
	
	If NewRowArray <> Undefined Then 
		For Each RowID In NewRowArray Do
			If HasPeriodInSettings(RowID) Then
				RowReport = Object.Reports.FindByID(RowID);
				RowReport.ThereIsPeriod = True;
			EndIf;
		EndDo;
		Return;
	EndIf;	
		
	For Each RowReport In Object.Reports Do
		RowID = RowReport.GetID();
		If HasPeriodInSettings(RowID) Then
			RowReport.ThereIsPeriod = True;
		EndIf;
	EndDo; 

EndProcedure

&AtServer
Procedure DefineDistributionKind()
	
	If ReportMailing.IsMemberOfPersonalReportGroup(Object.Parent)Then
		 BulkEmailType = "Personal";
		 Object.Personal = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure ConvertTextParameters(CurrentObject, ConversionOption)
	
	If ConversionOption = "ParametersInPresentation" Then
		SearchSubstringName = "Key";
		ReplaceSubstringName = "Value";
	Else
		SearchSubstringName = "Value";
		ReplaceSubstringName = "Key";
	EndIf;
	
	HTMLText = "";
	EmailAttachmentsStructureInHTMLFormat = "";
	EmailTextFormattedDocument.GetHTML(HTMLText, EmailAttachmentsStructureInHTMLFormat);
	For Each ParameterDetails In FilesAndEmailTextParameters Do
		
		SearchSubstring = "[" + ParameterDetails[SearchSubstringName];
		ReplaceSubstring = "[" + ParameterDetails[ReplaceSubstringName];
		
		CurrentObject.EmailSubject = StrReplace(CurrentObject.EmailSubject, SearchSubstring, ReplaceSubstring);
		CurrentObject.EmailText = StrReplace(CurrentObject.EmailText, SearchSubstring, ReplaceSubstring);
		CurrentObject.EmailTextInHTMLFormat = StrReplace(CurrentObject.EmailTextInHTMLFormat, SearchSubstring, ReplaceSubstring);
		HTMLText = StrReplace(HTMLText, SearchSubstring, ReplaceSubstring);
		
		Items.ReportsFormatsDescriptionTemplate.InputHint = StrReplace(Items.ReportsFormatsDescriptionTemplate.InputHint,
			SearchSubstring, ReplaceSubstring);
		
		For Each RowReport In CurrentObject.Reports Do
			RowReport.DescriptionTemplate = StrReplace(RowReport.DescriptionTemplate, SearchSubstring, ReplaceSubstring);
		EndDo;
		
		CurrentObject.ArchiveName = StrReplace(CurrentObject.ArchiveName, SearchSubstring, ReplaceSubstring);
	
	EndDo;

	If CurrentObject.HTMLFormatEmail Then
		EmailTextFormattedDocument.SetHTML(HTMLText, EmailAttachmentsStructureInHTMLFormat);
	EndIf;

EndProcedure

&AtServer
Procedure ConvertReportsSettingsParameters(CurrentObject, ConversionOption)
	
	If Not Object.Personalized Then
		Return;
	EndIf;
	
	If ConversionOption = "ParametersInPresentation" Then
		SearchSubstring = "[Recipient]";
		ReplaceSubstring = MailingRecipientValueTemplate(FilesAndEmailTextParameters);
	Else
		SearchSubstring = MailingRecipientValueTemplate(FilesAndEmailTextParameters);
		ReplaceSubstring = "[Recipient]";
	EndIf;
	
	ChangesMade = False;
	For Each ReportsRow In Object.Reports Do
		If IsTempStorageURL(ReportsRow.SettingsAddress) Then
			UserSettings = GetFromTempStorage(ReportsRow.SettingsAddress);
		Else
			RowIndex = Object.Reports.IndexOf(ReportsRow);
			ReportsRowObject = FormAttributeToValue("Object").Reports.Get(RowIndex);
			UserSettings = ?(ReportsRowObject = Undefined, Undefined, ReportsRowObject.Settings.Get());
		EndIf;
		
		If UserSettings = Undefined Then
			Continue;
		EndIf;
		
		If TypeOf(UserSettings) = Type("ValueTable") Then
			For Each UserSetting In UserSettings Do
				If StrCompare(UserSetting.Value, SearchSubstring) = 0 Then
					UserSetting.Value = StrReplace(UserSetting.Value, SearchSubstring, ReplaceSubstring);
					ChangesMade = True;
				EndIf;
			EndDo;
		Else
			For Each UserSetting In UserSettings.Items Do
				If TypeOf(UserSetting) = Type("DataCompositionFilterItem")
				   And StrCompare(UserSetting.RightValue, SearchSubstring) = 0 Then
					UserSetting.RightValue = StrReplace(UserSetting.RightValue, SearchSubstring, ReplaceSubstring);
					ChangesMade = True;
				ElsIf TypeOf(UserSetting) = Type("DataCompositionSettingsParameterValue") 
				   And StrCompare(UserSetting.Value, SearchSubstring) = 0 Then
					UserSetting.Value = StrReplace(UserSetting.Value, SearchSubstring, ReplaceSubstring);
					ChangesMade = True;
				EndIf;
			EndDo;
		EndIf;
		
		ReportsRowObject = CurrentObject.Reports.Get(ReportsRow.LineNumber-1);
		
		If TypeOf(ReportsRowObject) = Type("CatalogTabularSectionRow.ReportMailings.Reports") And ChangesMade Then
			ReportsRowObject.Settings = New ValueStorage(UserSettings, New Deflation(9));
		ElsIf ChangesMade Then
			Address = ?(IsTempStorageURL(ReportsRow.SettingsAddress), ReportsRow.SettingsAddress, UUID);
			ReportsRow.SettingsAddress = PutToTempStorage(UserSettings, Address);
		EndIf;
		ChangesMade = False;
		
	EndDo;
	
EndProcedure

&AtServer
Function TemplatePreviewFormParameters()

	ConvertTextParameters(Object, "PresentationInParameters");
	
	PicturesForHTML = New Structure;
	
	Template = Object.EmailText;
	If Object.HTMLFormatEmail Then
		TextType = PredefinedValue("Enum.EmailTextTypes.HTML");
		EmailTextFormattedDocument.GetHTML(Template, PicturesForHTML);
		Template = Object.EmailSubject + "<br>" + "<br>" + Template;
	Else
		TextType = PredefinedValue("Enum.EmailTextTypes.PlainText");
		Template = Object.EmailSubject + Chars.LF + Chars.LF + Template;
	EndIf;

	GeneratedReports = "";
	For Each RowReport In Object.Reports Do
		ReportPresentation = StringFunctionsClientServer.SubstituteParametersToString("%1. %2",
			RowReport.LineNumber, RowReport.Presentation);
		GeneratedReports = GeneratedReports + Chars.LF + ReportPresentation;
	EndDo;
	GeneratedReports = TrimAll(GeneratedReports);
	If Object.Archive Then
		GeneratedReports = GeneratedReports + Chars.LF + Chars.LF + NStr(
			"vi = 'Đã nén các tệp báo cáo vào tệp nén';
			|ru = 'Файлы отчетов запакованы в архив';
			|en = 'Report files are archived'; fa = 'Report files are archived';
			|it = 'File dei report archiviati';
			|pl = 'Pliki raportów zostały zapakowane w archiwum';
			|tr = 'Rapor dosyaları arşivlendi'") + " ";

		ArchiveNameStructure = New Structure("MailingDescription, ExecutionDate", Object.Description,
			CurrentSessionDate());
		ArchiveName = ReportMailing.FillTemplate(Object.ArchiveName, ArchiveNameStructure);
		ArchiveName = ArchiveName + ".zip";

		GeneratedReports = TrimAll(
				GeneratedReports + """" + ArchiveName + """");
	EndIf;

	DeliveryParameters = ReportMailingClientServer.DeliveryParameters();
	FillPropertyValues(DeliveryParameters, Object);
	DeliveryParameters.ExecutedToFolder = Object.UseFolder;
	DeliveryParameters.ExecutedToNetworkDirectory = Object.UseNetworkDirectory;
	DeliveryParameters.ExecutedAtFTP = Object.UseFTPResource;
	DeliveryMethod = ReportMailing.DeliveryMethodsPresentation(DeliveryParameters);
	
	TemplateParameters = New Structure;
	TemplateParameters.Insert("MailingDescription", Object.Description);
	TemplateParameters.Insert("Author",                Object.Author);
	TemplateParameters.Insert("SystemTitle",     Cache.SystemTitle);
	TemplateParameters.Insert("ExecutionDate",       CurrentSessionDate());
	TemplateParameters.Insert("GeneratedReports", GeneratedReports);
	TemplateParameters.Insert("DeliveryMethod",       DeliveryMethod);
	
	If BulkEmailType = "Personalized" Then
		FirstRecipient = GetFirstRecipient();
		TemplateParameters.Insert("Recipient", FirstRecipient.Description);
		FirstRecipientRef = FirstRecipient.Ref;
	Else
		FirstRecipientRef = Undefined;
	EndIf;
	AddTemplateAdditionalParameters(TemplateParameters, FirstRecipientRef);
	
	// A simplified report view in the email body.
	If Object.ShouldInsertReportsIntoEmailBody Then
		ReportsInEmailText = "";
		For Each RowReport In Object.Reports Do
			ReportsInEmailText = ReportsInEmailText + Chars.LF
				+ "------------------------------------------" + Chars.LF
				+ RowReport.Presentation;
		EndDo;
		If Object.HTMLFormatEmail Then
			ReportsInEmailText = StrReplace(ReportsInEmailText, Chars.LF, Chars.LF + "<br>");
		EndIf;
		Template = Template + Chars.LF + Chars.LF + ReportsInEmailText;
	EndIf;
	
	// Output a list of attachments.
	If Object.ShouldAttachReports Then
		ReportsPlannedList = ReportsPlannedListInAttachments();
		If ReportsPlannedList.Count() > 0 Then
			ReportsList = StrConcat(ReportsPlannedList, Chars.LF);

			AttachmentText = Chars.LF + Chars.LF + NStr("vi = 'Tệp đính kèm thư:';
														|ru = 'Вложения письма:';
														|en = 'Email attachments:'; fa = 'Email attachments:';
														|it = 'Вложения письма:';
														|pl = 'Email attachments:';
														|tr = 'İleti ekleri:'");
			If Object.Archive Then
				ArchiveNameStructure = New Structure("MailingDescription, ExecutionDate", Object.Description, CurrentSessionDate());
				ArchiveName = ReportMailing.FillTemplate(Object.ArchiveName, ArchiveNameStructure);
				ArchiveName = ArchiveName + ".zip";
				AttachmentText = AttachmentText + Chars.LF + Chars.LF + ArchiveName;
			Else
				AttachmentText = AttachmentText + Chars.LF;
			EndIf;
			FileNumber = 1;
			For Each FullFileName In ReportsPlannedList Do
				NameOfFileWithOrder = StringFunctionsClientServer.SubstituteParametersToString("%1. %2",
					FileNumber, FullFileName);
				If Object.HTMLFormatEmail Then
					AttachmentText = AttachmentText + "<p style=""margin-left: 50px;"">" + NameOfFileWithOrder + "</p>";
				Else
					AttachmentText = AttachmentText + Chars.LF + Chars.Tab + NameOfFileWithOrder;
				EndIf;
				FileNumber = FileNumber + 1;
			EndDo;
			
			If Object.HTMLFormatEmail Then
				AttachmentText = StrReplace(AttachmentText, Chars.LF, Chars.LF + "<br>");
			EndIf;
			Template = Template + Chars.LF + AttachmentText;
		EndIf;
	EndIf;
	
	Text = ReportMailing.FillTemplate(Template, TemplateParameters);
	
	FormParameters = New Structure;
	FormParameters.Insert("MailingDescription", Object.Description);
	FormParameters.Insert("TextType", TextType);
	FormParameters.Insert("Text", Text);
	If PicturesForHTML.Count() > 0 Then
		FormParameters.Insert("PicturesAddressForHTML", PutPicturesToTempStorage(PicturesForHTML));
	EndIf;
		
	ConvertTextParameters(Object, "ParametersInPresentation");
	
	Return FormParameters;
	
EndFunction

#EndRegion

#Region ObjectRecord

&AtClient
Procedure WriteAtClient(Result, WriteParameters) Export
	// Initialize parameters.
	If Not WriteParameters.Property("Step") Then
		ClearMessages(); // Clean up message window.
		WriteParameters.Insert("Step", 1);
	EndIf;
	
	// Resource permissions.
	If WriteParameters.Step = 1 And PermissionsToUseServerResourcesRequired() Then
		WriteParameters.Step = 2;
		// Question.
		Handler = New CallbackDescription("WriteAtClient", ThisObject, WriteParameters);
		If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
			Permissions = PermissionsToUseServerResources();
			ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
			ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Permissions, ThisObject, Handler);
		Else
			RunCallback(Handler, DialogReturnCode.OK);
		EndIf;
	ElsIf WriteParameters.Step = 1 Then
		// Question is not required.
		WriteParameters.Step = 3;
	ElsIf WriteParameters.Step = 2 Then
		// Process the response.
		If Result = DialogReturnCode.OK Then
			WriteParameters.Step = 3; // External resources are allowed. Continue recording.
		Else
			Return; // Cancel writing.
		EndIf;
	EndIf;
	
	// Disable archiving.
	If WriteParameters.Step = 3 And PreferablyDisableArchiving() Then
		WriteParameters.Step = 4;
		// Question.
		QuestionTitle = NStr("vi = 'Tắt tính năng lưu trữ';
							|ru = 'Отключить архивацию';
							|en = 'Disable archiving'; fa = 'Disable archiving';
							|it = 'Disattivare l''archiviazione';
							|pl = 'Wyłącz archiwizację';
							|tr = 'Arşivlemeyi devre dışı bırak'");
		QueryText = NStr("vi = 'Khi đăng tải báo cáo trong thư mục nên tắt tính năng nén vào tệp ZIP.';
						|ru = 'При публикации отчетов в папку рекомендуется отключать архивацию в ZIP.';
						|en = 'Disable archiving to ZIP when publishing reports into a folder.'; fa = 'Disable archiving to ZIP when publishing reports into a folder.';
						|it = 'Quando i report vengono pubblicati in una cartella, si consiglia di disabilitare l''archiviazione in ZIP.';
						|pl = 'Podczas publikacji raportów do folderu zalecane jest wyłączanie archiwizacji ZIP.';
						|tr = 'Raporları klasörde yayımlarken ZIP''e arşivlemeyi devre dışı bırak.'");
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tắt tính năng nén vào tệp ZIP';
												|ru = 'Отключить архивацию в ZIP';
												|en = 'Disable archiving to ZIP'; fa = 'Disable archiving to ZIP';
												|it = 'Disabilitare l''archiviazione in ZIP';
												|pl = 'Wyłącz archiwizację ZIP';
												|tr = 'ZIP''e arşivlemeyi devre dışı bırak'"));
		Buttons.Add(DialogReturnCode.Ignore, NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continuare';
													|pl = 'Continue';
													|tr = 'Devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);
		
		Handler = New CallbackDescription("WriteAtClient", ThisObject, WriteParameters);
		ShowQueryBox(Handler, QueryText, Buttons, 60, DialogReturnCode.Yes, QuestionTitle);
	ElsIf WriteParameters.Step = 3 Then
		// Question is not required.
		WriteParameters.Step = 5;
	ElsIf WriteParameters.Step = 4 Then
		// Process the response.
		If Result = DialogReturnCode.Yes Then
			Object.Archive = False; // Disable archiving.
			WriteParameters.Step = 5; // Continue writing.
		ElsIf Result = DialogReturnCode.Ignore Then
			WriteParameters.Step = 5; // Continue writing without disabling archiving.
		Else
			Return; // Cancel writing.
		EndIf;
	EndIf;
	
	// Write.
	If WriteParameters.Step = 5 Then
		WriteParameters.Step = 6;
		Success = Write(WriteParameters);
		If Not Success Then
			Return; // Cancel writing.
		EndIf;
		CommandName = CommonClientServer.StructureProperty(WriteParameters, "CommandName");
		If CommandName = "ExecuteNowCommand" Then
			ExecuteNow();
		ElsIf CommandName = "CommandSaveAndClose" Then
			Close();
		ElsIf CommandName = "MailingEventsCommand" Then
			MailingEvents();
		ElsIf CommandName = "CommandCheckMailing" Then
			CheckMailing(CommonClientServer.StructureProperty(WriteParameters, "DeliveryParameters"));
		EndIf;
	EndIf;
EndProcedure

&AtClient
Function PermissionsToUseServerResourcesRequired()
	If Object.UseNetworkDirectory
		And (ValueIsFilled(Object.NetworkDirectoryWindows) Or ValueIsFilled(Object.NetworkDirectoryLinux)) Then
		// Publish to the network directory. Requires the permissions.
		If AttributesValuesChanged("UseNetworkDirectory, NetworkDirectoryWindows, NetworkDirectoryLinux") Then
			// User changed the values of the attributes to be checked.
			Return True;
		EndIf;
	EndIf;
	If Object.UseFTPResource And ValueIsFilled(Object.FTPServer) Then
		// Publish to the network directory. Requires the permissions.
		If AttributesValuesChanged("UseFTPResource, FTPServer, FTPDirectory") Then
			// User changed the values of the attributes to be checked.
			Return True;
		EndIf;
	EndIf;
	
	Return False;
EndFunction

&AtClient
Function PreferablyDisableArchiving()
	If Object.UseFolder
		And Object.Archive
		And (Object.NotifyOnly Or Not Object.UseEmail) Then
		// Publish into the notification distribution folder. We recommend that you disable archiving.
		If AttributesValuesChanged("UseFolder, UseEmail, NotifyOnly, Archive") Then
			// User changed the values of the attributes to be checked.
			Return True;
		EndIf;
	EndIf;
	
	Return False;
EndFunction

&AtServer
Function PermissionsToUseServerResources()
	PermissionsSet = ReportMailing.PermissionsToUseServerResources(Object);
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	PermissionsRef = ModuleSafeModeManager.RequestToUseExternalResources(PermissionsSet, Object.Ref);
	PermissionsRefArray = New Array;
	PermissionsRefArray.Add(PermissionsRef);
	Return PermissionsRefArray;
EndFunction

&AtClient
Function AttributesValuesChanged(AttributesNames)
	AttributesNames = StrSplit(AttributesNames, ",", False);
	For Each AttributeName In AttributesNames Do
		AttributeName = TrimAll(AttributeName);
		If Object[AttributeName] <> AttributesValuesBeforeChange[AttributeName] Then
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction

&AtServer
Procedure FixAttributesValuesBeforeChange()
	
	AttributesNames = "UseFolder, UseEmail, NotifyOnly, Archive";
	AttributesNames = AttributesNames + ", UseNetworkDirectory, NetworkDirectoryWindows, NetworkDirectoryLinux";
	AttributesNames = AttributesNames + ", UseFTPResource, FTPServer, FTPDirectory";
	AttributesValuesBeforeChange = New Structure(AttributesNames);
	FillPropertyValues(AttributesValuesBeforeChange, Object);
	AttributesValuesBeforeChange = New FixedStructure(AttributesValuesBeforeChange);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
    ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	EndIf;
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region CopyOfCommandRunNowForAsyncSupport

&AtClient
Procedure ExecuteNow()
	MailingArray = New Array;
	MailingArray.Add(Object.Ref);
	
	StartupParameters = New Structure("MailingArray, Form, IsItemForm");
	StartupParameters.MailingArray = MailingArray;
	StartupParameters.Form = ThisObject;
	StartupParameters.IsItemForm = True;
	
	ReportMailingClient.ExecuteNow(StartupParameters);
EndProcedure

#EndRegion

#Region CopyOfCommandDistributionEventsForAsyncSupport

&AtClient
Procedure MailingEvents()
	EventLogFormParameters = EventLogParameters(Object.Ref);
	If EventLogFormParameters = Undefined Then
		ShowMessageBox(, NStr("vi = 'Vẫn chưa gửi hàng loạt.';
								|ru = 'Рассылка еще не выполнялась.';
								|en = 'Report distribution has not been started yet.'; fa = 'Report distribution has not been started yet.';
								|it = 'Spedizione di newsletter non è ancora stata eseguita.';
								|pl = 'Subskrypcja nie była jeszcze wykonywana.';
								|tr = 'Bülten henüz gerçekleştirilmedi.'"));
		Return;
	EndIf;
	OpenForm("DataProcessor.EventLog.Form", EventLogFormParameters, ThisObject);
EndProcedure

&AtServerNoContext
Function EventLogParameters(BulkEmail)
	Return ReportMailing.EventLogParameters(BulkEmail);
EndFunction

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_BeginTime" Then
		BeginTimeOnChange(Items.BeginTime);
	ElsIf Item.Name = "sh_ShamsiInput_F_EndTime" Then
		EndTimeOnChange(Items.EndTime);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
