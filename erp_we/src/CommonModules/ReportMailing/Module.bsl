///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Generates reports and, depending to the settings, puts them a either a file folder or folder on the computer, 
// mail them out, or sends to an FTP resource.
//
// Parameters:
//   BulkEmail - CatalogRef.ReportMailings - a report mailing to be executed.
//   LogParameters - See ReportMailing.LogParameters.
//   AdditionalSettings - Structure:
//       * Recipients - Map of KeyAndValue:
//           ** Key - CatalogRef - a recipient.
//           ** Value - String - a set of recipient e-mail addresses in the row with separators.
//
// Returns:
//   Boolean - a flag of successful mailing completion
//
Function ExecuteReportsMailing(BulkEmail, LogParameters = Undefined, AdditionalSettings = Undefined) Export

	DefaultLogParameters = LogParameters(BulkEmail);
	If LogParameters <> Undefined Then
		FillPropertyValues(DefaultLogParameters, LogParameters);
	EndIf;
	LogParameters = DefaultLogParameters;
	
	// Check rights settings.
	If Not OutputRight(LogParameters) Then
		Return False;
	EndIf;
	
	BulkEmailObject = BulkEmail.GetObject();
	
	// Check basic mailing attributes.
	If Not BulkEmailObject.IsPrepared
		Or BulkEmailObject.DeletionMark Then
		
		Cause = "";
		If Not BulkEmailObject.IsPrepared Then
			Cause = Cause + Chars.LF + NStr("vi = 'Chưa chuẩn bị gửi hàng loạt';
											|ru = 'Рассылка не подготовлена';
											|en = 'Distribution not prepared'; fa = 'Distribution not prepared';
											|it = 'Newsletter non preparata';
											|pl = 'Subskrypcja nie została przygotowana';
											|tr = 'Bülten hazırlanmadı'");
		EndIf;
		If BulkEmailObject.DeletionMark Then
			Cause = Cause + Chars.LF + NStr("vi = 'Đã đặt dấu xóa gửi hàng loạt';
											|ru = 'Рассылка помечена на удаление';
											|en = 'The distribution is marked for deletion.'; fa = 'The distribution is marked for deletion.';
											|it = 'Invio massivo contrassegnato per l''eliminazione';
											|pl = 'Wysyłka jest oznaczona do usunięcia';
											|tr = 'Bülten silinmek üzere işaretlendi'");
		EndIf;
		
		LogRecord(LogParameters, EventLogLevel.Warning,
			NStr("vi = 'Kết thúc';
				|ru = 'Завершение';
				|en = 'Completing'; fa = 'Completing';
				|it = 'Completamento';
				|pl = 'Completing';
				|tr = 'Bitiş'"), TrimAll(Cause));
		Return False;
		
	EndIf;
	
	StartCommitted = CommonClientServer.StructureProperty(AdditionalSettings, "StartCommitted");
	If StartCommitted <> True Then
		// Register startup (started but not completed).
		InformationRegisters.ReportMailingStates.FixMailingStart(BulkEmail);
		StartCommitted = True;
	EndIf;
	
	// Default formats.
	DefaultFormats = New Array;
	FoundItems = BulkEmailObject.ReportFormats.FindRows(New Structure("Report", EmptyReportValue()));
	For Each StringFormat In FoundItems Do
		DefaultFormats.Add(StringFormat.Format);
	EndDo;
	If DefaultFormats.Count() = 0 Then
		FormatsList = FormatsList();
		For Each ListValue In FormatsList Do
			If ListValue.Check Then
				DefaultFormats.Add(ListValue.Value);
			EndIf;
		EndDo;
	EndIf;
	If DefaultFormats.Count() = 0 Then
		Raise NStr("vi = 'Chưa đặt định dạng mặc định.';
					|ru = 'Не установлены форматы по умолчанию.';
					|en = 'Default formats are not set.'; fa = 'Default formats are not set.';
					|it = 'Non sono impostati i formati predefiniti.';
					|pl = 'Nie są ustawione domyślne formaty.';
					|tr = 'Varsayılan biçimler ayarlanmadı'");
	EndIf;
	
	// Populate report table.
	ReportsTable = MailingListReports();
	For Each RowReport In BulkEmailObject.Reports Do
		Page1 = ReportsTable.Add();
		Page1.Report = RowReport.Report;
		Page1.SendIfEmpty = RowReport.SendIfEmpty;
		Page1.DescriptionTemplate = RowReport.DescriptionTemplate;
		
		// Settings.
		Settings = RowReport.Settings.Get();
		If TypeOf(Settings) = Type("ValueTable") Then
			Page1.Settings = New Structure;
			FoundItems = Settings.FindRows(New Structure("Use", True));
			For Each SettingRow In FoundItems Do
				Page1.Settings.Insert(SettingRow.Attribute, SettingRow.Value);
			EndDo;
		Else
			Page1.Settings = Settings;
		EndIf;
		
		// Formats.
		FoundItems = BulkEmailObject.ReportFormats.FindRows(New Structure("Report", RowReport.Report));
		If FoundItems.Count() = 0 Then
			Page1.Formats = DefaultFormats;
		Else
			For Each StringFormat In FoundItems Do
				Page1.Formats.Add(StringFormat.Format);
			EndDo;
		EndIf;
	EndDo;
	
	// Prepare delivery parameters.
	DeliveryParameters = DeliveryParameters();
	DeliveryParameters.UseFolder = BulkEmailObject.UseFolder;
	DeliveryParameters.UseNetworkDirectory = BulkEmailObject.UseNetworkDirectory;
	DeliveryParameters.UseFTPResource = BulkEmailObject.UseFTPResource;
	DeliveryParameters.UseEmail = BulkEmailObject.UseEmail;
	DeliveryParameters.TransliterateFileNames = BulkEmailObject.TransliterateFileNames;
	DeliveryParameters.Personal = BulkEmailObject.Personal;
	
	RecipientsTypesTable = ReportMailingCached.RecipientsTypesTable();
	FoundItems = RecipientsTypesTable.FindRows(New Structure("MetadataObjectID", BulkEmailObject.MailingRecipientType));
	If FoundItems.Count() = 1 Then
		DeliveryParameters.MailingRecipientType = FoundItems[0].RecipientsType;
	EndIf;
	
	// Marked delivery method checks.
	If Not DeliveryParameters.UseFolder
		And Not DeliveryParameters.UseNetworkDirectory
		And Not DeliveryParameters.UseFTPResource
		And Not DeliveryParameters.UseEmail Then
		LogRecord(LogParameters, EventLogLevel.Warning, NStr("vi = 'Chưa chọn cách nhận.';
															|ru = 'Не выбран способ доставки.';
															|en = 'Delivery method is not selected.'; fa = 'Delivery method is not selected.';
															|it = 'Non è stato selezionato il metodo di consegna.';
															|pl = 'Nie został wybrany sposób dostawy.';
															|tr = 'Teslimat yöntemi seçilmedi.'"));
		Return False;
	EndIf;
	
	DeliveryParameters.Personalized = BulkEmailObject.Personalized;
	DeliveryParameters.Archive = BulkEmailObject.Archive;
	DeliveryParameters.ArchiveName = BulkEmailObject.ArchiveName;
	
	// Prepare parameters of delivery to the folder.
	If DeliveryParameters.UseFolder Then
		DeliveryParameters.Folder = BulkEmailObject.Folder;
	EndIf;
	
	// Prepare parameters of delivery to the network directory.
	If DeliveryParameters.UseNetworkDirectory Then
		DeliveryParameters.NetworkDirectoryWindows = BulkEmailObject.NetworkDirectoryWindows;
		DeliveryParameters.NetworkDirectoryLinux = BulkEmailObject.NetworkDirectoryLinux;
	EndIf;
	
	// Prepare parameters of delivery to the FTP resource.
	If DeliveryParameters.UseFTPResource Then
		DeliveryParameters.Server = BulkEmailObject.FTPServer;
		DeliveryParameters.Port = BulkEmailObject.FTPPort;
		DeliveryParameters.Login = BulkEmailObject.FTPUsername;
		
		SetPrivilegedMode(True);
		DeliveryParameters.Password = Common.ReadDataFromSecureStorage(BulkEmail, "FTPPassword");
		SetPrivilegedMode(False);
		
		DeliveryParameters.Directory = BulkEmailObject.FTPDirectory;
		DeliveryParameters.PassiveConnection = BulkEmailObject.FTPPassiveConnection;
	EndIf;
	
	DeliveryParameters.ShouldInsertReportsIntoEmailBody = BulkEmailObject.ShouldInsertReportsIntoEmailBody;
	DeliveryParameters.ShouldAttachReports = BulkEmailObject.ShouldAttachReports;
	DeliveryParameters.ShouldSetPasswordsAndEncrypt = BulkEmailObject.ShouldSetPasswordsAndEncrypt;
	
	// Prepare parameters of delivery by email.
	If DeliveryParameters.UseEmail Then
		DeliveryParameters.Account = BulkEmailObject.Account;
		DeliveryParameters.NotifyOnly = BulkEmailObject.NotifyOnly;
		DeliveryParameters.BCCs = BulkEmailObject.BCCs;
		DeliveryParameters.SubjectTemplate = BulkEmailObject.EmailSubject;
		DeliveryParameters.TextTemplate1 = ?(BulkEmailObject.HTMLFormatEmail,
			BulkEmailObject.EmailTextInHTMLFormat, BulkEmailObject.EmailText);
		
		IsDistributionRecipientsSelected = IsDistributionRecipientsSelected(
			BulkEmail, DeliveryParameters, LogParameters, AdditionalSettings);
		
		If Not IsDistributionRecipientsSelected Then 
			Return False;
		EndIf;
		
		DeliveryParameters.EmailParameters.TextType = ?(BulkEmailObject.HTMLFormatEmail, "HTML", "PlainText");
		DeliveryParameters.EmailParameters.ReplyToAddress = BulkEmailObject.ReplyToAddress;
		DeliveryParameters.EmailParameters.Importance = ?(ValueIsFilled(BulkEmailObject.EmailImportance),
			EmailOperationsInternal.InternetMailMessageImportanceFromString(BulkEmailObject.EmailImportance),
			InternetMailMessageImportance.Normal);
		
		If BulkEmailObject.HTMLFormatEmail Then
			EmailPicturesInHTMLFormat = BulkEmailObject.EmailPicturesInHTMLFormat.Get();
			If EmailPicturesInHTMLFormat <> Undefined Then
				DeliveryParameters.Images = EmailPicturesInHTMLFormat;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not StartCommitted Then
		InformationRegisters.ReportMailingStates.FixMailingStart(BulkEmail);
		StartCommitted = True;
	EndIf;
	
	DeliveryParameters.StartCommitted = StartCommitted;
	
	DeliveryParameters.ResultAddress = CommonClientServer.StructureProperty(AdditionalSettings, "ResultAddress");
	
	Result = ExecuteBulkEmail(ReportsTable, DeliveryParameters, BulkEmail, LogParameters);
	InformationRegisters.ReportMailingStates.FixMailingExecutionResult(BulkEmail, DeliveryParameters);
	
	Return Result;
	
EndFunction

// Distributes arbitrary reports specified in the Reports parameter.
//
// Parameters:
//   Var_Reports - See ReportMailing.MailingListReports.
//   DeliveryParameters - See ReportMailing.DeliveryParameters.
//   MailingDescription - String - displayed in the subject and message as well as to display errors.
//                        - CatalogRef.ReportMailings
//   LogParameters - See ReportMailing.LogParameters.
//
// Returns:
//   Boolean - a flag of successful mailing completion
//
Function ExecuteBulkEmail(Var_Reports, DeliveryParameters, MailingDescription = "", LogParameters = Undefined) Export
	
	IsReportsDistributionCatalog = False;
	If TypeOf(MailingDescription) = Type("CatalogRef.ReportMailings")
	   And ValueIsFilled(MailingDescription) Then
		IsReportsDistributionCatalog = True;
	EndIf;
	
	If IsReportsDistributionCatalog Then
		RecordManager = InformationRegisters.ReportMailingStates.CreateRecordManager();
		RecordManager.BulkEmail = LogParameters.Data;
		RecordManager.Read();
		ExecutionDate = RecordManager.LastRunStart;
	Else
		ExecutionDate = CurrentSessionDate();
	EndIf;
	
	DefaultDeliveryOptions = DeliveryParameters();
	FillPropertyValues(DefaultDeliveryOptions, DeliveryParameters);
	DeliveryParameters = DefaultDeliveryOptions;   
	
	IsAutoRedistribution = DeliveryParameters.ReportsTree <> Undefined;
	
	// Add a tree of generated reports  - spreadsheet document and reports saved in formats (of files).
	ReportsTree = CreateReportsTree();
	
	// Fill with default parameters and check whether key delivery parameters are filled.
	If Not CheckAndFillExecutionParameters(Var_Reports, DeliveryParameters, MailingDescription, LogParameters) Then
		Return False;
	EndIf;
	
	DeliveryParameters.ExecutionDate = ExecutionDate;
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã khởi tại gửi hàng loạt ''%1'', tác giả: ''%2''';
			|ru = 'Инициализирована рассылка ''%1'', автор: ''%2''';
			|en = 'Report distribution %1 is started by %2'; fa = 'Report distribution %1 is started by %2';
			|it = 'Invio massivo inizializzato ''%1'', autore: ''%2''';
			|pl = 'Inicjacja wysyłki ''%1'', autor: ''%2''';
			|tr = '''%1'' bülten gönderimi başlatıldı, oluşturan: ''%2'''"),
		MailingDescription, DeliveryParameters.Author);
	
	LogRecord(LogParameters,, MessageText);
	
	If IsAutoRedistribution Then
		ReportsTree = DeliveryParameters.ReportsTree;
		RowsCount = ReportsTree.Rows.Count();
		For Position = -RowsCount + 1 To 0 Do
			If ReportsTree.Rows[-Position] = DeliveryParameters.GeneralReportsRow Then
				Continue; // Ignore the general reports tree row.
			EndIf;
			If DeliveryParameters.Recipients.Get(ReportsTree.Rows[-Position].Key) = Undefined Then
				ReportsTree.Rows.Delete(-Position);
			EndIf;
		EndDo;
	Else
		ReportsTree = RunReportsGeneration(Var_Reports, DeliveryParameters, MailingDescription, LogParameters); 
	EndIf;

	If TypeOf(LogParameters.Metadata) = Type("String") And ValueIsFilled(LogParameters.Metadata) Then
		LogParameters.Metadata = Common.MetadataObjectByFullName(LogParameters.Metadata);
	EndIf;
	
	If ReportsTree.Rows.Count() = 0 Then

		LogRecord(LogParameters,
			EventLogLevel.Warning,
			NStr("vi = 'Chưa thực hiện gửi hàng loạt báo cáo, bởi vì báo cáo trống hoặc chưa lập báo cáo do lỗi.';
				|ru = 'Рассылка отчетов не выполнена, так как отчеты пустые или не сформированы из-за ошибок.';
				|en = 'Report distribution failed. Reports are empty or cannot be generated.'; fa = 'Report distribution failed. Reports are empty or cannot be generated.';
				|it = 'L''invio massivo dei report non eseguito perché i report sono vuoti o non formati a causa degli errori.';
				|pl = 'Wysyłka raportów nie powiodła się, ponieważ raporty są puste lub nie zostały utworzone z powodu błędów.';
				|tr = 'Raporlar boş oldukları için gönderilmedi ya da hatalara bağlı olarak düzenlenmedi.'"));
		Return False;
	EndIf;
	
	// Check the number of the saved reports.
	If ReportsTree.Rows.Find(3, "Level", True) = Undefined
		And DeliveryParameters.ReportsForEmailText.Count() = 0 Then
		LogRecord(LogParameters,
			EventLogLevel.Warning,
			NStr("vi = 'Chưa thực hiện gửi hàng loạt báo cáo, bởi vì báo cáo trống hoặc chưa lập báo cáo do lỗi.';
				|ru = 'Рассылка отчетов не выполнена, так как отчеты пустые или не сформированы из-за ошибок.';
				|en = 'Report distribution failed. Reports are empty or cannot be generated.'; fa = 'Report distribution failed. Reports are empty or cannot be generated.';
				|it = 'L''invio massivo dei report non eseguito perché i report sono vuoti o non formati a causa degli errori.';
				|pl = 'Wysyłka raportów nie powiodła się, ponieważ raporty są puste lub nie zostały utworzone z powodu błędów.';
				|tr = 'Raporlar boş oldukları için gönderilmedi ya da hatalara bağlı olarak düzenlenmedi.'"));
			
		DeleteTempFiles(DeliveryParameters.TempFilesDir, LogParameters);
		Return False;
	EndIf;
	
	MailingExecuted = False;
	
	// Common reports.
	SharedAttachments = DeliveryParameters.GeneralReportsRow.Rows.FindRows(New Structure("Level", 3), True);
	
	If ValueIsFilled(DeliveryParameters.Account) Then 
		SenderSRepresentation = String(DeliveryParameters.Account);
		SendHiddenCopiesToSender = Common.ObjectAttributeValue(
			DeliveryParameters.Account, "SendBCCToThisAddress");
	Else
		SenderSRepresentation = "";
		SendHiddenCopiesToSender = False;
	EndIf;
	
	// Prepare the distribution of personalized reports.
	RecipientsList = New Array();
	For Each RecipientRow In ReportsTree.Rows Do
		If RecipientRow = DeliveryParameters.GeneralReportsRow Then
			Continue; // Ignore the general reports tree row.
		EndIf;	
		RecipientsList.Add(RecipientRow.Key);	
	EndDo;
	
	If RecipientsList.Count() > 0 Then
		SetPrivilegedMode(True);
		RecipientsArchivePasswords = Common.ReadOwnersDataFromSecureStorage(RecipientsList,
			"ArchivePassword");
		SetPrivilegedMode(False);
		If CanEncryptAttachments() Then
			RecipientsEncryptionCertificates = GetEncryptionCertificatesForDistributionRecipients(RecipientsList);
		EndIf;
	EndIf;
	
	LogRecord(LogParameters,
		EventLogLevel.Note,
		NStr("vi = 'Bắt đầu gửi báo cáo cho người nhận.';
			|ru = 'Начало доставки отчетов получателям.';
			|en = 'Start report distribution to recipients.'; fa = 'Start report distribution to recipients.';
			|it = 'Начало доставки отчетов получателям.';
			|pl = 'Start report distribution to recipients.';
			|tr = 'Alıcılara rapor tesliminin başlangıcı.'"));
	
	// Send personal reports (personalized).
	QuantityToSend = ReportsTree.Rows.Count();
	SentCount = 0;
	For Each RecipientRow In ReportsTree.Rows Do
		If RecipientRow = DeliveryParameters.GeneralReportsRow Then
			QuantityToSend = QuantityToSend - 1;
			Continue; // Ignore the general reports tree row.
		EndIf;
		
		// Personal attachments.
		PersonalAttachments = RecipientRow.Rows.FindRows(New Structure("Level", 3), True);
		
		// Check the number of saved personal reports.
		If PersonalAttachments.Count() = 0 And DeliveryParameters.ReportsForEmailText.Count() = 0 Then
			Continue;
		EndIf;
		
		If DeliveryParameters.ShouldAttachReports Then

			// Merge common and personal attachments.
			RecipientsAttachments = CombineArrays(SharedAttachments, PersonalAttachments);

			// Generate reports presentation.
			GenerateReportPresentationsForRecipient(DeliveryParameters, RecipientRow);

			If DeliveryParameters.ShouldSetPasswordsAndEncrypt Then
				// Get a personal archive password and encryption certificate
				If DeliveryParameters.Archive Then
					ArchivePassword = RecipientsArchivePasswords.Get(RecipientRow.Key);
					DeliveryParameters.ArchivePassword = "";
					If ArchivePassword <> Undefined Then
						DeliveryParameters.ArchivePassword = ArchivePassword;
					EndIf;
				EndIf;

				If CanEncryptAttachments() Then
					FilterParameters = New Structure("BulkEmailRecipient", RecipientRow.Key);
					FoundRows = RecipientsEncryptionCertificates.FindRows(FilterParameters);
					DeliveryParameters.CertificateToEncrypt = ?(FoundRows.Count() > 0,
						FoundRows[0].CertificateToEncrypt, Undefined);
				EndIf;

				// Encrypt each file (unless archiving is selected).
				If ValueIsFilled(DeliveryParameters.CertificateToEncrypt) And Not DeliveryParameters.Archive Then
					EncryptedAttachments = New Map;
					For Each Attachment In RecipientsAttachments Do
						ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
						Try
							AttachmentBinaryData = ModuleDigitalSignature.Encrypt(
							New BinaryData(Attachment.Value), DeliveryParameters.CertificateToEncrypt);
						Except
							HandleEncryptionError(DeliveryParameters.ResultAddress, DeliveryParameters.CertificateToEncrypt, ErrorInfo(), LogParameters);
							Raise;
						EndTry;
						AttachmentBinaryData.Write(Attachment.Value);
						CharCountBeforeExtension = StrFind(Attachment.Key, ".", SearchDirection.FromEnd);
						EncryptedFileName = Left(Attachment.Key, CharCountBeforeExtension-1) + " " + NStr(
							"vi = '(Cần giải mã)';
							|ru = '(Необходимо расшифровать)';
							|en = '(Decrypt)'; fa = '(Decrypt)';
							|it = '(Необходимо расшифровать)';
							|pl = '(Decrypt)';
							|tr = '(Şifre çözmek gerekli)'") + Mid(Attachment.Key, CharCountBeforeExtension);
						EncryptedAttachments.Insert(EncryptedFileName, Attachment.Value);
					EndDo;
					RecipientsAttachments = EncryptedAttachments;
				EndIf;
			Else
				DeliveryParameters.ArchivePassword = "";
				DeliveryParameters.CertificateToEncrypt = Undefined;
			EndIf;

			// Archive attachments.
			ArchiveAttachments(RecipientsAttachments, DeliveryParameters, RecipientRow.Value, LogParameters);

		Else
			RecipientsAttachments = New Array;
		EndIf;

		RecipientAddress = DeliveryParameters.Recipients[RecipientRow.Key];
		RecipientPresentation1 = String(RecipientRow.Key) + " (" + RecipientAddress + ")";
		
		// Delivery.
		Try  
			SendReportsToRecipient(RecipientsAttachments, DeliveryParameters, LogParameters, RecipientRow);
			MailingExecuted = True;
		Except
			ErrorInfo = ErrorInfo();
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể gửi báo cáo cho người nhận ''%1'':';
					|ru = 'Не удалось отправить отчеты получателю ''%1'':';
					|en = 'Cannot send reports to %1:'; fa = 'Cannot send reports to %1:';
					|it = 'Non è stato possibile inviare i report al destinatario ''%1'':';
					|pl = 'Nie udało się wysłać raporty do odbiorcy ''%1'':';
					|tr = '''%1'' alıcısına raporlar gönderilemiyor:'"), RecipientPresentation1);
			ExtendedErrorPresentation = EmailOperations.ExtendedErrorPresentation(
				ErrorInfo, Common.DefaultLanguageCode(), False, DeliveryParameters.Account);
			LogRecord(LogParameters,, MessageText, ExtendedErrorPresentation);
			
			If Not EmailClientUsed() And GetFunctionalOption("RetainReportDistributionHistory")
			   And TypeOf(LogParameters.Data) = Type("CatalogRef.ReportMailings") Then
				DeliveryAddressKey = ?(DeliveryParameters.BCCs, "BCCs", "Whom");
				RecipientAddresses = DeliveryParameters.EmailParameters[DeliveryAddressKey];
				Comment = StringFunctionsClientServer.SubstituteParametersToString(
					"%1 %2", MessageText, ExtendedErrorPresentation);
				RecordUnsuccessfulDistributionResult(DeliveryParameters, LogParameters,
					DeliveryParameters.Recipient, RecipientAddresses, Comment);
			EndIf;
		EndTry;
		
		If MailingExecuted Then
			DeliveryParameters.ExecutedByEmail = True;  
			SentCount = SentCount + 1;
			ProgressText = ReportDistributionProgressText(DeliveryParameters, SentCount, QuantityToSend);
			ProgressPercent = Round(SentCount * 100 / QuantityToSend);
			TimeConsumingOperations.ReportProgress(ProgressPercent, ProgressText);

			AdditionalInfo = "";
			If SendHiddenCopiesToSender Then
				AdditionalInfo = NStr("vi = 'Đã gửi bản sao cho người gửi.';
										|ru = 'Копия направлена отправителю.';
										|en = 'A copy was sent to the sender.'; fa = 'A copy was sent to the sender.';
										|it = 'Copia inviata al mittente.';
										|pl = 'Kopia została wysłana nadawcy.';
										|tr = 'Kopya göndericiye gönderildi.'");
			EndIf;
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Báo cáo đã gửi ''%1'' từ %2. %3';
				|ru = 'Отчеты отправлены ''%1'' от %2. %3';
				|en = 'Reports are sent from %2 to ''%1''. %3'; fa = 'Reports are sent from %2 to ''%1''. %3';
				|it = 'Report inviati ""%1"" di %2%3';
				|pl = 'Raporty zostały wysłane ''%1'' od %2. %3';
				|tr = 'Raporlar %2''dan ''%1'' ya gönderildi. %3'"), RecipientPresentation1, SenderSRepresentation,
				AdditionalInfo);

			LogRecord(LogParameters, , MessageText);
				
			DeliveryParameters.Recipients.Delete(RecipientRow.Key);
		EndIf;
	EndDo;
	
	// Send general reports.
	If SharedAttachments.Count() > 0 Or DeliveryParameters.ReportsForEmailText.Count() > 0 Then
		// Reports presentation.
		GenerateReportPresentationsForRecipient(DeliveryParameters, RecipientRow);
		
		If (DeliveryParameters.UseEmail And DeliveryParameters.ShouldAttachReports)
			Or  DeliveryParameters.UseFolder Or DeliveryParameters.UseNetworkDirectory 
			Or DeliveryParameters.UseFTPResource Then

			SetPrivilegedMode(True);
			DeliveryParameters.ArchivePassword = Common.ReadDataFromSecureStorage(
			LogParameters.Data, "ArchivePassword");
			SetPrivilegedMode(False);

			If CanEncryptAttachments() And DeliveryParameters.Personal Then
				RecipientsList = New Array;
				For Each RecipientRow In DeliveryParameters.Recipients Do
					RecipientsList.Add(RecipientRow.Key);
				EndDo;
				RecipientsEncryptionCertificates = GetEncryptionCertificatesForDistributionRecipients(RecipientsList);
				DeliveryParameters.CertificateToEncrypt = ?( RecipientsEncryptionCertificates.Count() > 0,
					RecipientsEncryptionCertificates[0].CertificateToEncrypt, Undefined);
				DeliveryParameters.ShouldSetPasswordsAndEncrypt = ?(ValueIsFilled(DeliveryParameters.CertificateToEncrypt),True, False);

				If Not DeliveryParameters.Archive And DeliveryParameters.ShouldSetPasswordsAndEncrypt Then
				// Encrypt each file (unless archiving is selected).	
					EncryptedAttachments = New Map;
					For Each Attachment In SharedAttachments Do
						ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
						Try
							AttachmentBinaryData = ModuleDigitalSignature.Encrypt(
								New BinaryData(Attachment.Value), DeliveryParameters.CertificateToEncrypt);
						Except
							HandleEncryptionError(DeliveryParameters.ResultAddress, DeliveryParameters.CertificateToEncrypt, ErrorInfo(), LogParameters);
							Raise;
						EndTry;
						AttachmentBinaryData.Write(Attachment.Value);
						CharCountBeforeExtension = StrFind(Attachment.Key, ".", SearchDirection.FromEnd);
						EncryptedFileName = Left(Attachment.Key, CharCountBeforeExtension-1) + " " + NStr(
							"vi = '(Cần giải mã)';
							|ru = '(Необходимо расшифровать)';
							|en = '(Decrypt)'; fa = '(Decrypt)';
							|it = '(Необходимо расшифровать)';
							|pl = '(Decrypt)';
							|tr = '(Şifre çözmek gerekli)'") + Mid(Attachment.Key, CharCountBeforeExtension);
						EncryptedAttachments.Insert(EncryptedFileName, Attachment.Value);
					EndDo;
					SharedAttachments = EncryptedAttachments;
				EndIf;
				
			EndIf;
				
			// Archive attachments.
			ArchiveAttachments(SharedAttachments, DeliveryParameters, DeliveryParameters.TempFilesDir, LogParameters);
				
		Else
			SharedAttachments = New Array;	
		EndIf;
		
		// Delivery.
		If ExecuteDelivery(LogParameters, DeliveryParameters, SharedAttachments) Then
			MailingExecuted = True;
	
			If DeliveryParameters.Recipients <> Undefined Then
				RecipientPresentation1 = New Array;
				For Each BulkEmailRecipient In DeliveryParameters.Recipients Do
					RecipientPresentation1.Add(String(BulkEmailRecipient.Key) + " (" + BulkEmailRecipient.Value + ")");
				EndDo;
				RecipientPresentation1 = StrConcat(RecipientPresentation1, Chars.LF);
				
				AdditionalInfo = "";
				If SendHiddenCopiesToSender Then 
					AdditionalInfo = NStr("vi = 'Đã gửi bản sao cho người gửi.';
											|ru = 'Копия направлена отправителю.';
											|en = 'A copy was sent to the sender.'; fa = 'A copy was sent to the sender.';
											|it = 'Copia inviata al mittente.';
											|pl = 'Kopia została wysłana nadawcy.';
											|tr = 'Kopya göndericiye gönderildi.'");
				EndIf;
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã gửi báo cáo %1 cho người nhận từ %2. %3
					|%4';
					|ru = 'Отчеты отправлены %1 получателям от %2. %3
					|%4';
					|en = 'Reports are sent from %2 to %1 users. %3
					|%4'; fa = 'Reports are sent from %2 to %1 users. %3
					|%4';
					|it = 'Report inviati %1 ai destinatari di %2. %3
					|%4';
					|pl = 'Raporty zostały wysłane %1 odbiorcom od %2. %3
					|%4';
					|tr = 'Raporlar %1 alıcılarına %2''dan gönderildi. %3
					|%4'"),
					DeliveryParameters.Recipients.Count(), SenderSRepresentation, 
					AdditionalInfo, RecipientPresentation1);
				LogRecord(LogParameters,, MessageText);
			EndIf;
		EndIf;
	EndIf;

	If MailingExecuted Then
		LogRecord(LogParameters, , NStr("vi = 'Đã gửi hàng loạt';
										|ru = 'Рассылка выполнена.';
										|en = 'Report distribution completed.'; fa = 'Report distribution completed.';
										|it = 'Рассылка выполнена.';
										|pl = 'Report distribution completed.';
										|tr = 'Bülten tamamlandı.'"));
	Else
		LogRecord(LogParameters, , NStr("vi = 'Chưa gửi hàng loạt';
										|ru = 'Рассылка не выполнена.';
										|en = 'Report distribution failed.'; fa = 'Report distribution failed.';
										|it = 'Рассылка не выполнена.';
										|pl = 'Report distribution failed.';
										|tr = 'Bülten tamamlanmadı.'"));
	EndIf;
	
	If Not IsAutoRedistribution And IsReportsDistributionCatalog Then
		DeliveryParameters.ReportsTree = ReportsTree;
		ResendByEmail(Var_Reports, DeliveryParameters, LogParameters.Data, LogParameters);
	EndIf;
	
	DeleteTempFiles(DeliveryParameters.TempFilesDir, LogParameters);
	
	// Result.
	If LogParameters.Property("HadErrors") Then
		DeliveryParameters.HadErrors = LogParameters.HadErrors;
	EndIf;
	
	If LogParameters.Property("HasWarnings") Then
		DeliveryParameters.HasWarnings = LogParameters.HasWarnings;
	EndIf;
	
	Return MailingExecuted;
EndFunction

// The constructor for the LogParameters parameter value of the ExecuteReportsMailing and ExecuteBulkEmail functions.
//
// Parameters:
//   BulkEmail - CatalogRef.ReportMailings - a report mailing to be executed.
//
// Returns:
//   Structure - Logging parameters.:
//       * EventName - String - an event name (or events group).
//       * Metadata - Array of MetadataObject, Undefined - Metadata for linking the Event log record.
//       * Data     - Arbitrary - Data for linking the Event log record.
//
Function LogParameters(BulkEmail = Undefined) Export
	
	LogParameters = New Structure;
	LogParameters.Insert("EventName", NStr("vi = 'Gửi hàng loạt báo cáo. Khởi động theo yêu cầu';
											|ru = 'Рассылка отчетов. Запуск по требованию';
											|en = 'Report distribution. Manual start'; fa = 'Report distribution. Manual start';
											|it = 'Invio massivo dei report. Avvio su richiesta';
											|pl = 'Wysyłanie raportów. Uruchamianie na żądanie';
											|tr = 'Rapor bülteni. Talep üzerine başlat'", Common.DefaultLanguageCode()));
	LogParameters.Insert("Data", BulkEmail);
	LogParameters.Insert("Metadata", ?(BulkEmail <> Undefined, BulkEmail.Metadata(), Undefined));
	LogParameters.Insert("ErrorsArray", Undefined); // Service property.
	Return LogParameters;
	
EndFunction

// The constructor for the Reports parameter value of the ExecuteBulkEmail function.
//
// Returns:
//   ValueTable - Reports to be exported. Has the following columns:
//       * Report - CatalogRef.ReportsOptions
//               - CatalogRef.AdditionalReportsAndDataProcessors - a report to be generated.
//       * SendIfEmpty - Boolean - Send a report even if it is empty.
//       * Settings - DataCompositionUserSettings - a spreadsheet document will be generated by the DCS mechanisms.
//                   - Structure - Spreadsheet to be generated by the "Generate" method:
//                      ** Key     - String       - a report object attribute name.
//                      ** Value - Arbitrary - a report object attribute value.
//                   - Undefined - default settings.
//                     Note. Settings to generate a report.
//       * Formats - Array of EnumRef.ReportSaveFormats - formats in which the report must be saved and
//                                                                           sent.
//       * DescriptionTemplate - String - Used for generating a report filename.
//
Function MailingListReports() Export
	
	ReportsTable = New ValueTable;
	ReportsTable.Columns.Add("Report", Metadata.Catalogs.ReportMailings.TabularSections.Reports.Attributes.Report.Type);
	ReportsTable.Columns.Add("SendIfEmpty", New TypeDescription("Boolean"));
	
	SettingTypesArray = New Array;
	SettingTypesArray.Add(Type("Undefined"));
	SettingTypesArray.Add(Type("DataCompositionUserSettings"));
	SettingTypesArray.Add(Type("Structure"));
	
	ReportsTable.Columns.Add("Settings", New TypeDescription(SettingTypesArray));
	ReportsTable.Columns.Add("Formats", New TypeDescription("Array"));
	ReportsTable.Columns.Add("DescriptionTemplate", New TypeDescription("String", New StringQualifiers(150)));
	Return ReportsTable;
	
EndFunction

// The constructor for the DeliveryParameters parameter value of the ExecuteBulkEmail function.
//
// Returns:
//   Structure - Report delivery method settings. The list of properties depends on the delivery method.
//     Common properties::
//       * Author - CatalogRef.Users - a mailing author.
//       * UseFolder            - Boolean - deliver reports to the "Stored files" subsystem folder.
//       * UseNetworkDirectory   - Boolean - deliver reports to the file system folder.
//       * UseFTPResource        - Boolean - deliver reports to the FTP.
//       * UseEmail - Boolean - deliver reports via email.
//
//     Properties when UseFolder = True:
//       * Folder - CatalogRef.FilesFolders - a folder of the "File Management" subsystem.
//
//     Properties when UseNetworkDirectory = True:
//       * NetworkDirectoryWindows - String - a file system directory (local at server or network).
//       * NetworkDirectoryLinux   - String - a file system directory (local on the server or network).
//
//     Properties when UseFTPResource = True:
//       * Owner            - CatalogRef.ReportMailings
//       * Server              - String - an FTP server name.
//       * Port                - Number  - an FTP server port.
//       * Login               - String - an FTP server user name.
//       * Password              - String - an FTP server user password.
//       * Directory             - String - a path to the directory at the FTP server.
//       * PassiveConnection - Boolean - use passive connection.
//
//     Properties when UseEmail = True:
//       * Account - CatalogRef.EmailAccounts - to send an email message.
//       * Recipients - Map of KeyAndValue - a set of recipients and their email addresses:
//           ** Key - CatalogRef - a recipient.
//           ** Value - String - email addresses of the recipient separated by commas.
//
//     Additional properties:
//       * Archive - Boolean - archive all generated reports into one archive.
//                                 Archiving can be required, for example, when mailing schedules in html format.
//       * ArchiveName    - String - an archive name.
//       * ArchivePassword - String - an archive password.
//       * TransliterateFileNames - Boolean - Flag indicating whether to convert Cyrillic filenames to Latin.
//       * CertificateToEncrypt - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - If the DigitalSignature subsystem is integrated -
//           Undefined
//
//     Optional properties if UseEmail = True:
//       * Personalized - Boolean - Personalized report distribution.
//           By default, False.
//           If True, each recipient receives an individual report.
//           To do this, in reports, set the [Recipient] filter by the attribute that matches the recipient type.
//           Applies only to email distributions,
//           so setting to True disables other distribution methods.
//       * NotifyOnly - Boolean - False - send notifications only (do not attach generated reports).
//       * BCCs    - Boolean - False - if True, when sending fill BCCs instead of To.
//       * SubjectTemplate      - String -       an email subject.
//       * TextTemplate1    - String -       an email body.
//       * FormatsParameters - Map of KeyAndValue:
//           ** Key - EnumRef.ReportSaveFormats
//           ** Value - Structure:
//                *** Extension - String
//                *** FileType - SpreadsheetDocumentFileType
//                *** Name - String
//       * EmailParameters - Structure - Contains all email details:
//           ** Whom - Array
//                   - String - Recipients' email addresses and presentation.
//                   - Array - Collection of address structures:
//                       *** Address - String - an email address (required).
//                       *** Presentation - String - a recipient's name.
//                   - String - Semicolon-delimited recipient addresses.
//            ** MessageRecipients - Array - Array of structures describing recipients:
//                 *** Address - String - an email recipient address.
//                 *** Presentation - String - Addressee presentation.
//            ** Cc - Array
//                     - String - Email addresses of the CC recipients. See the "To" field.
//            ** BCCs - Array
//                            - String - Email addresses of the BCC recipients. See the "To" field.
//            ** Subject       - String - (mandatory) an email subject.
//            ** Body       - String - (mandatory) an email text (plain text, win1251 encoded).
//            ** Attachments - Array - Files to be attached (as structures):
//                 *** Presentation - String - an attachment file name;
//                 *** AddressInTempStorage - String - a binary data address of an attachment in a temporary storage.
//                 *** Encoding - String - an attachment encoding (used if it differs from the message encoding).
//                 *** Id - String - (optional) used to store images displayed in the message body.
//            ** ReplyToAddress - String - Reply-to email address.
//            ** BasisIDs - String - IDs of the message basis objects.
//            ** ProcessTexts  - Boolean - shows whether message text processing is required on sending.
//            ** RequestDeliveryReceipt  - Boolean - shows whether a delivery notification is required.
//            ** RequestReadReceipt - Boolean - shows whether a read notification is required.
//            ** TextType - String
//                         - EnumRef.EmailTextTypes
//                         - InternetMailTextType - Determines the type of the passed text.:
//                             Valid values:
//                             HTML/EmailTextTypes.HTML - HTML text.
//                                                                       PlainText/EmailTextTypes.PlainText - Plain text.
//                             By default, display "as is".
//                                                                                             MarkedUpText/EmailTextTypes.MarkedUpText - Reach text.
//
Function DeliveryParameters() Export
	
	DeliveryParameters = ReportMailingClientServer.DeliveryParameters();
	DeliveryParameters.ExecutionDate = CurrentSessionDate();
	DeliveryParameters.Author = Users.CurrentUser();
	DeliveryParameters.TempFilesDir = FileSystem.SharedDirectoryOfTemporaryFiles("RP" + InfoBaseSessionNumber()) + GetServerPathSeparator();
	DeliveryParameters.EmailParameters.Importance = InternetMailMessageImportance.Normal;
	
	If GetFunctionalOption("RetainReportDistributionHistory") Then
		DeliveryParameters.EmailParameters.RequestDeliveryReceipt = True;
	EndIf;
	
	Return DeliveryParameters;
	
EndFunction

// To call from the modules ReportMailingOverridable or ReportMailingCached.
// Adds format (if absent) and sets its parameters (if passed).
//
// Parameters:
//   FormatsList - ValueList
//   FormatRef   - String
//                  - EnumRef.ReportSaveFormats - a reference or name of the format.
//   Picture                - Picture - a picture of the format.
//   UseByDefault - Boolean   - flag showing that the format is used by default.
//
Procedure SetFormatsParameters(FormatsList, FormatRef, Picture = Undefined, UseByDefault = Undefined) Export
	If TypeOf(FormatRef) = Type("String") Then
		FormatRef = Enums.ReportSaveFormats[FormatRef];
	EndIf;
	ListItem = FormatsList.FindByValue(FormatRef);
	If ListItem = Undefined Then
		ListItem = FormatsList.Add(FormatRef, FormatPresentation(FormatRef), False, PictureLib.BlankFormat);
	EndIf;
	If Picture <> Undefined Then
		ListItem.Picture = Picture;
	EndIf;
	If UseByDefault <> Undefined Then
		ListItem.Check = UseByDefault;
	EndIf;
EndProcedure

// To call from the modules ReportMailingOverridable or ReportMailingCached.
//   Adds recipients type description to the table.
//
// Parameters:
//   TypesTable  - ValueTable - passed from procedure parameters as is. Contains types information.
//   AvailableTypes - Array          - passed from procedure parameters as is. Unused types array.
//   Settings     - Structure       - predefined settings to register the main type.
//     Mandatory parameters:
//       * MainType - Type - a main type for the described recipients.
//     Optional parameters:
//       * Presentation - String - a presentation of this type of recipients in the interface.
//       * CIKind - CatalogRef.ContactInformationKinds - a main type or group of contact information
//           for email addresses of this type of recipients.
//       * ChoiceFormPath - String - a path to the choice form.
//       * AdditionalType - Type - an additional type that can be selected along with the main one from the choice form.
//
Procedure AddItemToRecipientsTypesTable(TypesTable, AvailableTypes, Settings) Export
	SetPrivilegedMode(True);
	
	MainTypesMetadata = Metadata.FindByType(Settings.MainType);
	
	// Register the main type usage.
	TypeIndex = AvailableTypes.Find(Settings.MainType);
	If TypeIndex <> Undefined Then
		AvailableTypes.Delete(TypeIndex);
	EndIf;
	
	// Metadata object IDs.
	MetadataObjectID = Common.MetadataObjectID(Settings.MainType);
	TableRow = TypesTable.Find(MetadataObjectID, "MetadataObjectID");
	If TableRow = Undefined Then
		TableRow = TypesTable.Add();
		TableRow.MetadataObjectID = MetadataObjectID;
	EndIf;
	
	// Recipients type.
	TypesArray = New Array;
	TypesArray.Add(Settings.MainType);
	
	// Recipients type: Main.
	TableRow.MainType = New TypeDescription(TypesArray);
	
	// Recipients type: Additional.
	If Settings.Property("AdditionalType") Then
		TypesArray.Add(Settings.AdditionalType);
		
		// Register the additional type.
		TypeIndex = AvailableTypes.Find(Settings.AdditionalType);
		If TypeIndex <> Undefined Then
			AvailableTypes.Delete(TypeIndex);
		EndIf;
	EndIf;
	TableRow.RecipientsType = New TypeDescription(TypesArray);
	
	// Presentation.
	If Settings.Property("Presentation") Then
		TableRow.Presentation = Settings.Presentation;
	Else
		TableRow.Presentation = MainTypesMetadata.Synonym;
	EndIf;
	
	// Email as the main contact information kind for the object.
	HasContactInfoKind = Settings.Property("CIKind");
	AttributesOfCIType = ?(HasContactInfoKind, Common.ObjectAttributesValues(Settings.CIKind, "IsFolder, Parent"), Undefined);
	If HasContactInfoKind And Not AttributesOfCIType.IsFolder Then
		TableRow.MainCIKind = Settings.CIKind;
		TableRow.CIGroup = AttributesOfCIType.Parent;
	Else
		If HasContactInfoKind Then
			TableRow.CIGroup = Settings.CIKind;
		Else
			
			If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
				
				ModuleContactsManager = Common.CommonModule("ContactsManager");
				CIGroupName = StrReplace(MainTypesMetadata.FullName(), ".", "");
				TableRow.CIGroup = ModuleContactsManager.ContactInformationKindByName(CIGroupName);
				
			EndIf;
			
		EndIf;
		Query = New Query;
		Query.Text = "SELECT TOP 1 Ref FROM Catalog.ContactInformationKinds WHERE Parent = &Parent AND Type = &Type";
		Query.SetParameter("Parent", TableRow.CIGroup);
		Query.Parameters.Insert("Type", Enums.ContactInformationTypes.Email);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			TableRow.MainCIKind = Selection.Ref;
		EndIf;
	EndIf;
	
	// Full path to the choice form of this object.
	If Settings.Property("ChoiceFormPath") Then
		TableRow.ChoiceFormPath = Settings.ChoiceFormPath;
	Else
		TableRow.ChoiceFormPath = MainTypesMetadata.FullName() +".ChoiceForm";
	EndIf;
EndProcedure

// Distributes several reports and places the result at the ResultAddress address. 
//
// Parameters:
//   ExecutionParameters - Structure - mailings to be executed and their parameters:
//       * MailingArray - Array of CatalogRef.ReportMailings - mailings to be executed.
//       * PreliminarySettings - See ReportMailing.ExecuteReportsMailing.
//   ResultAddress - String - an address in the temporary storage where the result will be placed.
//
Procedure SendBulkEmailsInBackgroundJob(ExecutionParameters, ResultAddress) Export
	MailingArray           = ExecutionParameters.MailingArray;
	PreliminarySettings = ExecutionParameters.PreliminarySettings;
	If PreliminarySettings = Undefined Then
		PreliminarySettings = New Structure;
	EndIf;
	PreliminarySettings.Insert("ResultAddress", ResultAddress);
	
	// Selecting all mailings including nested excluding groups.
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED DISTINCT
	|	ReportMailings.Ref AS BulkEmail,
	|	ReportMailings.Presentation AS Presentation,
	|	CASE
	|		WHEN ReportMailings.IsPrepared = TRUE
	|				AND ReportMailings.DeletionMark = FALSE
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS IsPrepared,
	|	FALSE AS Executed,
	|	FALSE AS WithErrors
	|FROM
	|	Catalog.ReportMailings AS ReportMailings
	|WHERE
	|	ReportMailings.Ref IN HIERARCHY(&MailingArray)
	|	AND ReportMailings.IsFolder = FALSE";
	
	Query.SetParameter("MailingArray", MailingArray);
	MailingsTable = Query.Execute().Unload();
	PreparedReportDistributionDetails = MailingsTable.FindRows(New Structure("IsPrepared", True));
	Completed2 = 0;
	WithErrors = 0;
	
	ArrayOfMessages = New Array;
	For Each TableRow In PreparedReportDistributionDetails Do
		
		LogParameters = LogParameters(TableRow.BulkEmail);
		LogParameters.ErrorsArray = New Array;
		TableRow.Executed = ExecuteReportsMailing(
			TableRow.BulkEmail,
			LogParameters,
			PreliminarySettings);
		TableRow.WithErrors = (LogParameters.ErrorsArray.Count() > 0);
		
		If TableRow.WithErrors Then
			ArrayOfMessages.Add("---" + Chars.LF + Chars.LF + TableRow.Presentation + ":"); // Title.
			For Each Message In LogParameters.ErrorsArray Do
				ArrayOfMessages.Add(Message);
			EndDo;
		EndIf;
		
		If TableRow.Executed Then
			Completed2 = Completed2 + 1;
			If TableRow.WithErrors Then
				WithErrors = WithErrors + 1;
			EndIf;
		EndIf;
	EndDo;
	
	Total        = MailingsTable.Count();
	Prepared2 = PreparedReportDistributionDetails.Count();
	NotCompleted  = Prepared2 - Completed2;
	
	If Total = 0 Then
		MessageText = NStr("vi = 'Các nhóm đã chọn không bao gồm gửi báo cáo hàng loạt.';
							|ru = 'Выбранные группы не содержат рассылок отчетов.';
							|en = 'The selected groups contain  no report distributions.'; fa = 'The selected groups contain  no report distributions.';
							|it = 'I gruppi selezionati non contengono invio massivo dei report.';
							|pl = 'Wybrane grupy nie zawierają wysyłki raportów.';
							|tr = 'Seçilen grupların rapor gönderimi yok.'");
	ElsIf Total <= 5 Then
		MessageText = "";
		For Each TableRow In MailingsTable Do
			If Not TableRow.IsPrepared Then
				MessageTemplate = NStr("vi = 'Chưa sẵn sàng gửi hàng loạt ""%1"".';
										|ru = 'Рассылка ""%1"" не подготовлена.';
										|en = 'Report distribution ""%1"" not prepared.'; fa = 'Report distribution ""%1"" not prepared.';
										|it = 'Invio massivo ""%1"" non preparato.';
										|pl = 'Wysyłka ""%1"" nie została przygotowana.';
										|tr = '""%1"" bülteni hazırlanmadı.'");
			ElsIf Not TableRow.Executed Then
				MessageTemplate = NStr("vi = 'Chưa gửi hàng loạt ""%1"".';
										|ru = 'Рассылка ""%1"" не выполнена.';
										|en = 'Report distribution ""%1"" not completed.'; fa = 'Report distribution ""%1"" not completed.';
										|it = 'Invio massivo ""%1"" non eseguito.';
										|pl = 'Wysyłka ""%1"" nie została wykonana.';
										|tr = '""%1"" bülteni tamamlanmadı.'");
			ElsIf TableRow.WithErrors Then
				MessageTemplate = NStr("vi = 'Đã gửi hàng loạt một phần ""%1""';
										|ru = 'Рассылка ""%1"" выполнена частично';
										|en = 'The ""%1"" report distribution is partially completed'; fa = 'The ""%1"" report distribution is partially completed';
										|it = 'Рассылка ""%1"" выполнена частично';
										|pl = 'The ""%1"" report distribution is partially completed';
										|tr = '""%1"" dağıtımı kısmen tamamlandı'");
			Else
				MessageTemplate = NStr("vi = 'Đã gửi hàng loạt ""%1"".';
										|ru = 'Рассылка ""%1"" выполнена.';
										|en = 'Report distribution ""%1"" completed successfully.'; fa = 'Report distribution ""%1"" completed successfully.';
										|it = 'Invio massivo ""%1"" eseguito.';
										|pl = 'Wysyłka ""%1"" została wykonana.';
										|tr = '""%1"" bülteni tamamlandı.'");
			EndIf;
			MessageTemplate = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, TableRow.Presentation);
			
			If MessageText = "" Then
				MessageText = MessageTemplate;
			Else
				MessageText = MessageText + Chars.LF + Chars.LF + MessageTemplate;
			EndIf;
		EndDo;
	Else
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã chuẩn bị gửi hàng loạt: %1 trong số %2
			|Đã thực hiện: %3
			|Một phần: %4
			|Chưa thực hiện: %5';
			|ru = 'Подготовлено рассылок: %1 из %2
			|Выполнено: %3
			|Частично: %4
			|Не выполнено: %5';
			|en = 'Prepared %1 out of %2 report distributions
			|Completed: %3
			|Partially: %4
			|Not completed: %5'; fa = 'Prepared %1 out of %2 report distributions
			|Completed: %3
			|Partially: %4
			|Not completed: %5';
			|it = 'Подготовлено рассылок: %1 из %2
			|Выполнено: %3
			|Частично: %4
			|Не выполнено: %5';
			|pl = 'Prepared %1 out of %2 report distributions
			|Completed: %3
			|Partially: %4
			|Not completed: %5';
			|tr = 'Hazırlanan dağıtımlar: %2 üzerinden %1
			|Tamamlandı:%3
			|Kısmen:%4
			|Tamamlanmadı: %5'"),
			Format(Prepared2, "NZ=0; NG=0"), Format(Total, "NZ=0; NG=0"),
			Format(Completed2,    "NZ=0; NG=0"),
			Format(WithErrors,    "NZ=0; NG=0"),
			Format(NotCompleted,  "NZ=0; NG=0"));
	EndIf;
	
	Result = New Structure;
	Result.Insert("BulkEmails", MailingsTable.UnloadColumn("BulkEmail"));
	Result.Insert("Text", MessageText);
	Result.Insert("More", MessagesToUserString(ArrayOfMessages));
	PutToTempStorage(Result, ResultAddress);
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated. Obsolete. Use ExecuteReportsMailing.
// Generates reports and sends them according to the transport settings (Folder, FILE, EMAIL, FTP);
//
// Parameters:
//   BulkEmail - CatalogRef.ReportMailings - a report mailing to be executed.
//   LogParameters - Structure - Logging parameters:
//       * EventName - String - an event name (or events group).
//       * Metadata - MetadataObject - Metadata for linking the Event log record.
//       * Data     - Arbitrary - Data for linking the Event log record.
//   AdditionalSettings - Structure - settings that override standard mailing parameters:
//       * Recipients - Map of KeyAndValue - a set of recipients and their email addresses:
//           ** Key - CatalogRef - a recipient.
//           ** Value - String - a set of recipient e-mail addresses in the row with separators.
//
// Returns:
//   Boolean - a flag of successful mailing completion
//
Function PrepareParametersAndExecuteMailing(BulkEmail, LogParameters = Undefined, AdditionalSettings = Undefined) Export
	
	Return ExecuteReportsMailing(BulkEmail, LogParameters, AdditionalSettings);
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Adds commands for creating mailings to the report form.
//
// Parameters:
//   Form - ClientApplicationForm
//         - ReportFormExtension
//   Cancel - Boolean
//   StandardProcessing - Boolean
//
Procedure ReportFormAddCommands(Form, Cancel, StandardProcessing) Export
	
	// Mailings can be added only if there is an option link (it is internal or additional).
	If Form.ReportSettings.External Then
		Return;
	EndIf;
	If Not InsertRight1() Then
		Return;
	EndIf;
	
	NamePrefix = ReportsClientServer.CommandNamePrefixWithReportOptionPreSave();
	
	// Add commands and buttons
	Commands = New Array;
	
	CreateCommand = Form.Commands.Add(NamePrefix + "ReportMailingCreateNew");
	CreateCommand.Action  = "ReportMailingClient.CreateNewBulkEmailFromReport";
	CreateCommand.Picture  = PictureLib.ReportMailing;
	CreateCommand.Title = NStr("vi = 'Tạo giao dịch gửi báo cáo hàng loạt...';
								|ru = 'Создать рассылку отчетов...';
								|en = 'To new report distribution list'; fa = 'To new report distribution list';
								|it = 'Creare l''invio massivo dei report...';
								|pl = 'Utworzyć wysyłkę raportów...';
								|tr = 'Rapor bülteni oluştur...'");
	CreateCommand.ToolTip = NStr("vi = 'Tự động gửi báo cáo theo lịch theo email, đăng tải vào thư mục...';
								|ru = 'Отправлять отчет автоматически по расписанию по почте, публиковать в каталог и т.п.';
								|en = 'Send report on schedule: distribute over email, publish to directory, and so on.'; fa = 'Send report on schedule: distribute over email, publish to directory, and so on.';
								|it = 'Send report on schedule: distribute over email, publish to directory, and so on.';
								|pl = 'Send report on schedule: distribute over email, publish to directory, and so on.';
								|tr = 'Raporu programa göre otomatikman e-posta ile gönder, bir dizinde yayınla, vs.'");
	Commands.Add(CreateCommand);
	
	AttachCommand = Form.Commands.Add("ReportMailingAddToExisting");
	AttachCommand.Action  = "ReportMailingClient.AttachReportToExistingBulkEmail";
	AttachCommand.Title = NStr("vi = 'Đưa vào gửi báo cáo hàng loạt...';
								|ru = 'Включить в рассылку отчетов...';
								|en = 'To existing report distribution list'; fa = 'To existing report distribution list';
								|it = 'To existing report distribution list';
								|pl = 'To existing report distribution list';
								|tr = 'Rapor bağlantılarına dahil et...'");
	AttachCommand.ToolTip = NStr("vi = 'Bật sử dụng phương án báo cáo vào việc gửi hàng loạt hiện có.';
								|ru = 'Включить вариант отчета в существующую рассылку.';
								|en = 'Include this report option to an existing report distribution.'; fa = 'Include this report option to an existing report distribution.';
								|it = 'Include this report option to an existing report distribution.';
								|pl = 'Include this report option to an existing report distribution.';
								|tr = 'Mevcut bir bültene rapor seçeneğini ekle.'");
	Commands.Add(AttachCommand);
	
	MailingsWithReportsNumber = MailingsWithReportsNumber(Form.ReportSettings.OptionRef);
	If MailingsWithReportsNumber > 0 Then
		MailingsCommand = Form.Commands.Add("ReportMailingOpenMailingsWithReport");
		MailingsCommand.Action  = "ReportMailingClient.OpenBulkEmailsWithReport";
		MailingsCommand.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Gửi báo cáo hàng loạt (%1)';
																								|ru = 'Рассылки отчета (%1)';
																								|en = 'Report distribution (%1)'; fa = 'Report distribution (%1)';
																								|it = 'Invio massivo del report (%1)';
																								|pl = 'Wysyłki raportu (%1)';
																								|tr = 'Raporun bültenleri (%1)'"), 
			MailingsWithReportsNumber);
		MailingsCommand.ToolTip = NStr("vi = 'Mở danh sách gửi hàng loạt, trong đó có báo cáo.';
										|ru = 'Открыть список рассылок, в которые включен отчет.';
										|en = 'Show the list of distributions that contain the report.'; fa = 'Show the list of distributions that contain the report.';
										|it = 'Aprire l''elenco di invii massivi in cui è incluso il report.';
										|pl = 'Otworzyć listę wysyłek, w których dołączono raport.';
										|tr = 'Raporun olduğu gönderimlerin listesini aç.'");
		Commands.Add(MailingsCommand);
	EndIf;
	
	ReportsServer.OutputCommand(Form, Commands, "SubmenuSend", False, False, "ReportMailing");
	
EndProcedure

#Region AdministrationPanels

// Returns True if the user has the right to save report mailings.
Function InsertRight1() Export
	Return CheckAddRightErrorText() = "";
EndFunction

#EndRegion

#Region ConfigurationSubsystemsEventHandlers

// See CommonOverridable.OnAddReferenceSearchExceptions.
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	RefSearchExclusions.Add(Metadata.Catalogs.ReportMailings.Attributes.MailingRecipientType);
	
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	ReportMailings.Ref,
	|	ReportMailings.UseFTPResource,
	|	ReportMailings.FTPServer,
	|	ReportMailings.FTPDirectory,
	|	ReportMailings.FTPPort,
	|	ReportMailings.UseNetworkDirectory,
	|	ReportMailings.NetworkDirectoryWindows,
	|	ReportMailings.NetworkDirectoryLinux
	|FROM
	|	Catalog.ReportMailings AS ReportMailings
	|WHERE
	|	ReportMailings.DeletionMark = FALSE
	|	AND (ReportMailings.UseNetworkDirectory = TRUE
	|		OR ReportMailings.UseFTPResource = TRUE)";
	
	Query = New Query;
	Query.Text = QueryText;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	BulkEmail = Query.Execute().Select();
	While BulkEmail.Next() Do
		
		PermissionsRequests.Add(
			ModuleSafeModeManager.RequestToUseExternalResources(
				PermissionsToUseServerResources(BulkEmail), BulkEmail.Ref));
		
	EndDo;
	
EndProcedure

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Not InsertRight1() Then
		Return;
	EndIf;
	
	AddToToDoListSetTempFilesDirectory(ToDoList);
	
	ToDoName = "ReportMailingIssues";
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If ModuleToDoListServer.UserTaskDisabled(ToDoName) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT ALLOWED
		|	COUNT(ReportMailings.Ref) AS Count
		|FROM
		|	InformationRegister.ReportMailingStates AS ReportMailingStates
		|		INNER JOIN Catalog.ReportMailings AS ReportMailings
		|		ON ReportMailingStates.BulkEmail = ReportMailings.Ref
		|WHERE
		|	ReportMailings.IsPrepared = TRUE
		|	AND ReportMailingStates.WithErrors = TRUE
		|	AND ReportMailings.Author = &Author";
	Filters = New Structure;
	Filters.Insert("DeletionMark", False);
	Filters.Insert("IsPrepared", True);
	Filters.Insert("WithErrors", True);
	Filters.Insert("IsFolder", False);
	If Users.IsFullUser() Then
		Query.Text = StrReplace(Query.Text, "AND ReportMailings.Author = &Author", ""); // @query-part
	Else
		Filters.Insert("Author", Users.CurrentUser());
		Query.SetParameter("Author", Filters.Author);
	EndIf;
	IssuesCount = Query.Execute().Unload()[0].Count;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filters);
	FormParameters.Insert("Representation", "List");
	
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.Catalogs.ReportMailings.FullName());
	For Each Section In Sections Do
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = ToDoName + StrReplace(Section.FullName(), ".", "");
		ToDoItem.HasToDoItems       = IssuesCount > 0;
		ToDoItem.Presentation  = NStr("vi = 'Vấn đề gửi báo cáo hàng loạt';
										|ru = 'Проблемы с рассылками отчетов';
										|en = 'Report distribution issues'; fa = 'Report distribution issues';
										|it = 'Problemi con invii massivi dei report';
										|pl = 'Problemy z wysyłkami raportów';
										|tr = 'Rapor bülteni sorunları'");
		ToDoItem.Count     = IssuesCount;
		ToDoItem.Form          = "Catalog.ReportMailings.ListForm";
		ToDoItem.FormParameters = FormParameters;
		ToDoItem.Important         = True;
		ToDoItem.Owner       = Section;
	EndDo;
EndProcedure

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.ReportMailings.FullName(), "AttributesToSkipInBatchProcessing");
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
Procedure OnDefineScheduledJobSettings(Settings) Export
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ReportMailing;
	Setting.UseExternalResources = True;
	Setting.IsParameterized = True;
EndProcedure 

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.ReportMailing.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.ReportDistributionHistoryClearUp.MethodName);
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Catalogs.ReportMailings, True);
	
EndProcedure

// See also InfobaseUpdateOverridable.OnDefineSettings
//
// Parameters:
//  Objects - Array of MetadataObject
//
Procedure OnDefineObjectsWithInitialFilling(Objects) Export
	
	Objects.Add(Metadata.Catalogs.ReportMailings);
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version    = "3.1.8.98";
	Handler.Procedure = "ReportMailing.SetReportDistributionHistoryRetentionPeriodInMonths";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData      = False;
	Handler.InitialFilling = True;
	
	Handler = Handlers.Add();
	Handler.Version          = "3.1.9.21";
	Handler.Id   = New UUID("a3675668-c1c4-4012-a007-8df47dbed76d");
	Handler.Procedure       = "Catalogs.ReportMailings.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.ReportMailings.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToChange  = "Catalog.ReportMailings";
	Handler.ObjectsToLock = "Catalog.ReportMailings";
	Handler.CheckProcedure  = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Đặt mẫu tên gọi báo cáo mặc định khi gửi báo cáo hàng loạt, 
		|đặt dấu hộp kiểm ""Đính kèm báo cáo"". Trước khi kết thúc xử lý, không nên sử dụng các báo cáo này.';
		|ru = 'Установка шаблонов наименований отчетов по умолчанию в рассылках отчетов, 
		|установка флага ""Прикреплять отчеты во вложения"". До завершения обработки, не рекомендуется использовать рассылки отчетов.';
		|en = 'Set default report name templates in report distributions. 
		|Set the Attach reports checkbox. We do not recommend that you run report distributions until processing is completed.'; fa = 'Set default report name templates in report distributions. 
		|Set the Attach reports checkbox. We do not recommend that you run report distributions until processing is completed.';
		|it = 'Установка шаблонов наименований отчетов по умолчанию в рассылках отчетов, 
		|установка флага ""Прикреплять отчеты во вложения"". До завершения обработки, не рекомендуется использовать рассылки отчетов.';
		|pl = 'Set default report name templates in report distributions. 
		|Set the Attach reports checkbox. We do not recommend that you run report distributions until processing is completed.';
		|tr = 'Rapor bültenlerinde varsayılan rapor tanımı şablonlarının yapılandırılması,
		|""Raporları ek olarak ekle"" işaretinin yapılandırılması. İşleme tamamlanıncaya kadar rapor bültenlerinin kullanılması önerilmemektedir.'");
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
		NewRow = Handler.ExecutionPriorities.Add();
		NewRow.Procedure = "NationalLanguageSupportServer.ProcessDataForMigrationToNewVersion";
		NewRow.Order = "Before";
	EndIf;
	
EndProcedure

// See EmailOperationsOverridable.BeforeGetEmailMessagesStatuses
Procedure BeforeGetEmailMessagesStatuses(EmailMessagesIDs) Export
	
	If Not GetFunctionalOption("RetainReportDistributionHistory") Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ReportsDistributionHistory.EmailID AS EmailID,
		|	ReportsDistributionHistory.Account AS Sender,
		|	ReportsDistributionHistory.EMAddress AS RecipientAddress
		|FROM
		|	InformationRegister.ReportsDistributionHistory AS ReportsDistributionHistory
		|WHERE
		|	ReportsDistributionHistory.Status = &EmptyStatus
		|	AND ReportsDistributionHistory.Period >= &VerificationPeriod
		|	AND ReportsDistributionHistory.EmailID <> """"";
	
	Query.SetParameter("VerificationPeriod", CurrentSessionDate() - 259200); // Check the emails sent within the last 3 days.
	Query.SetParameter("EmptyStatus", Enums.EmailMessagesStatuses.EmptyRef());
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do 
		StringMailsIDs = EmailMessagesIDs.Add();
		FillPropertyValues(StringMailsIDs, Selection);		
	EndDo;
			
EndProcedure 

// See EmailOperationsOverridable.AfterGetEmailMessagesStatuses
Procedure AfterGetEmailMessagesStatuses(DeliveryStatuses) Export
	
	If Not GetFunctionalOption("RetainReportDistributionHistory") Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DeliveryStatuses.StatusChangeDate AS StatusChangeDate,
		|	DeliveryStatuses.Status AS Status,
		|	DeliveryStatuses.Cause AS Cause,
		|	DeliveryStatuses.EmailID AS EmailID,
		|	DeliveryStatuses.RecipientAddress AS RecipientAddress,
		|	DeliveryStatuses.Sender AS Sender
		|INTO DeliveryStatuses
		|FROM
		|	&DeliveryStatuses AS DeliveryStatuses
		|
		|INDEX BY
		|	EmailID
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ReportsDistributionHistory.ReportMailing AS ReportMailing,
		|	ReportsDistributionHistory.Recipient AS Recipient,
		|	ReportsDistributionHistory.StartDistribution AS StartDistribution,
		|	ReportsDistributionHistory.Period AS Period,
		|	ReportsDistributionHistory.EmailID AS EmailID,
		|	DeliveryStatuses.StatusChangeDate AS StatusChangeDate,
		|	DeliveryStatuses.Status AS Status,
		|	DeliveryStatuses.Cause AS Comment,
		|	ReportsDistributionHistory.Account AS Account,
		|	ReportsDistributionHistory.EMAddress AS EMAddress,
		|	ReportsDistributionHistory.OutgoingEmail AS OutgoingEmail,
		|	ReportsDistributionHistory.SessionNumber AS SessionNumber,
		|	ReportsDistributionHistory.MethodOfObtaining AS MethodOfObtaining,
		|	ReportsDistributionHistory.Executed AS Executed
		|FROM
		|	InformationRegister.ReportsDistributionHistory AS ReportsDistributionHistory
		|		INNER JOIN DeliveryStatuses AS DeliveryStatuses
		|		ON ReportsDistributionHistory.EmailID = DeliveryStatuses.EmailID
		|		AND ReportsDistributionHistory.EMAddress = DeliveryStatuses.RecipientAddress
		|		AND ReportsDistributionHistory.Account = DeliveryStatuses.Sender";
	
	Query.SetParameter("DeliveryStatuses", DeliveryStatuses);
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do		
		HistoryFields = ReportDistributionHistoryFields(Selection.ReportMailing, Selection.Recipient, Selection.StartDistribution); 
		FillPropertyValues(HistoryFields, Selection);   
		HistoryFields.Executed = ?(Selection.Status = Enums.EmailMessagesStatuses.NotDelivered, False, HistoryFields.Executed);   
		HistoryFields.Status = Selection.Status;
		HistoryFields.Comment = Selection.Comment;
		If Selection.Status = Enums.EmailMessagesStatuses.Delivered Then
			HistoryFields.DeliveryDate = Selection.StatusChangeDate;
		EndIf;
		
		InformationRegisters.ReportsDistributionHistory.CommitResultOfDistributionToRecipient(HistoryFields);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region ScheduledJobsExecution

// Starts mailing and controls result.
//
// Parameters:
//   BulkEmail - CatalogRef.ReportMailings - a report mailing to be executed.
//
Procedure ExecuteScheduledMailing(BulkEmail) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ReportMailing);
	
	InformationRegisters.ReportMailingStates.FixMailingStart(BulkEmail);
	
	If Not AccessRight("Read", Metadata.Catalogs.ReportMailings) Then
		Raise(NStr("vi = 'Không đủ quyền để xem giao dịch gửi báo cáo hàng loạt.';
					|ru = 'Недостаточно прав для просмотра рассылок отчетов.';
					|en = 'Insufficient rights to view the report distributions.'; fa = 'Insufficient rights to view the report distributions.';
					|it = 'Недостаточно прав для просмотра рассылок отчетов.';
					|pl = 'Insufficient rights to view the report distributions.';
					|tr = 'Raporun bültenlerini görüntülemek için yetersiz yetki.'"), ErrorCategory.AccessViolation);
	EndIf;
		
	Query = New Query("SELECT ALLOWED ExecuteOnSchedule FROM Catalog.ReportMailings WHERE Ref = &Ref");
	Query.SetParameter("Ref", BulkEmail);
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Raise(NStr("vi = 'Không đủ quyền để xem giao dịch gửi báo cáo hàng loạt.';
					|ru = 'Недостаточно прав для просмотра рассылки отчетов.';
					|en = 'Insufficient rights to view the report distribution.'; fa = 'Insufficient rights to view the report distribution.';
					|it = 'Diritti insufficienti per visualizzare i report inviati.';
					|pl = 'Nie masz wystarczających praw do przeglądu wysyłki raportów.';
					|tr = 'Raporun bültenlerini görüntülemek için yetersiz yetki.'"), ErrorCategory.AccessViolation);
	EndIf;
	If Not Selection.ExecuteOnSchedule Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong giao dịch gửi báo cáo hàng loạt ""%1"" đã vô hiệu hóa hộp kiểm ""Thực hiện theo lịch biểu""
				|Nên tắt nhiệm vụ thường kỳ tương ứng hoặc khởi động lại giao dịch gửi hàng loạt này.';
				|ru = 'У рассылки отчетов ""%1"" отключен флажок ""Выполнять по расписанию""
				|Рекомендуется отключить соответствующее регламентное задание или перезаписать эту рассылку.';
				|en = 'The ""Schedule"" check box is cleared for report distribution ""%1"". 
				|Disable the associated scheduled task or edit the report distribution.'; fa = 'The ""Schedule"" check box is cleared for report distribution ""%1"". 
				|Disable the associated scheduled task or edit the report distribution.';
				|it = 'L''email massive dei report ""%1"" ha il flag ""Eseguire da pianificazione"" disattivato 
				| Si consiglia di disattivare del il task pianificato corrispondente o riscrivere questa email massive.';
				|pl = 'U wysyłki raportów ""%1"" jest wyłączone pole wyboru ""uruchom zgodnie z harmonogramem"" 
				|Zaleca się wyłączyć odpowiednie planowe zadanie lub nadpisać tę wysyłkę.';
				|tr = '''''Planlanmış başlatma'''' işaret kutucuğu ''''%1'''' rapor bültenleri için temizlendi. 
				| İlgili zamanlanmış görevi devre dışı bırakmanız veya bülteni tekrar yazmanız tavsiye edilir.'"),
			String(BulkEmail));
	EndIf;
	
	ExecuteReportsMailing(BulkEmail, LogParameters(BulkEmail), New Structure("StartCommitted", True));
EndProcedure

#EndRegion

#Region ExportServiceProceduresAndFunctions

// Generate a recipients list from the Recipients tabular section of mailing.
//
// Parameters:
//   BulkEmail - CatalogRef.ReportMailings
//            - Structure - a catalog item for which recipients
//              list generating is required.
//   LogParameters - See LogParameters
//   DeliveryParameters - See DeliveryParameters
//
// Returns: 
//   Map of KeyAndValue:
//       * Key     - CatalogRef
//       * Value - String - Semicolon-delimited email addresses. For example: "email@server.com; email2@server2.com".
//
Function GenerateMailingRecipientsList(BulkEmail, LogParameters = Undefined, DeliveryParameters = Undefined) Export
	
	RecipientsEmailAddressKind = BulkEmail.RecipientsEmailAddressKind;
	
	RecipientsList = New Map;
	
	If BulkEmail.Personal Then
		
		RecipientsType = TypeOf(BulkEmail.Author);
		RecipientsMetadata = Metadata.FindByType(RecipientsType);
		
		TableOfRecipients = New ValueTable;
		For Each Attribute In Metadata.Catalogs.ReportMailings.TabularSections.Recipients.Attributes Do
			TableOfRecipients.Columns.Add(Attribute.Name, Attribute.Type);
		EndDo;
		TableOfRecipients.Add().Recipient = BulkEmail.Author;
		
	Else 
		If BulkEmail.MailingRecipientType = Undefined Then
			 Return RecipientsList;
		EndIf;
		RecipientsMetadata = Common.MetadataObjectByID(BulkEmail.MailingRecipientType, False);
		MetadataObjectKey = ?(ValueIsFilled(BulkEmail.MailingRecipientType),
			Common.ObjectAttributeValue(BulkEmail.MailingRecipientType, "MetadataObjectKey"), Undefined);
		RecipientsType = ?(MetadataObjectKey <> Undefined, MetadataObjectKey.Get(), Undefined);
		If TypeOf(BulkEmail.Recipients) = Type("ValueTable") Then
			TableOfRecipients = BulkEmail.Recipients;
		Else
			TableOfRecipients = BulkEmail.Recipients.Unload();
		EndIf;
	EndIf;
	
	RecipientEmptyValue = ?(TypeOf(RecipientsType) = Type("Type"), New (RecipientsType), Undefined);
	SearchParameters = New Structure("Recipient", RecipientEmptyValue);
	RowsWithoutRecipients = TableOfRecipients.FindRows(SearchParameters);
	For Each RecipientRow In RowsWithoutRecipients Do
		TableOfRecipients.Delete(RecipientRow);
	EndDo;
	
	Query = New Query;
	If RecipientsType = Type("CatalogRef.Users") Then
	
		QueryText =
		"SELECT
		|	TableOfRecipients.Recipient,
		|	TableOfRecipients.Excluded
		|INTO TableOfRecipients
		|FROM
		|	&TableOfRecipients AS TableOfRecipients
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	User.Ref AS Recipient,
		|	MAX(User.Description) AS Description,
		|	MAX(TableOfRecipients.Excluded) AS Excluded
		|INTO Recipients
		|FROM
		|	TableOfRecipients AS TableOfRecipients
		|	LEFT JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
		|		ON UserGroupCompositions.UsersGroup = TableOfRecipients.Recipient
		|	LEFT JOIN Catalog.Users AS Users
		|		ON Users.Ref = UserGroupCompositions.User
		|WHERE
		|	NOT Users.DeletionMark
		|	AND NOT Users.Invalid
		|	AND NOT Users.IsInternal
		|
		|GROUP BY
		|	User.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	Recipients.Recipient,
		|	Recipients.Description,
		|	Contacts.Presentation AS EMail
		|FROM
		|	Recipients AS Recipients
		|	LEFT JOIN Catalog.Users.ContactInformation AS Contacts
		|		ON Contacts.Ref = Recipients.Recipient
		|		AND Contacts.Kind = &RecipientsEmailAddressKind
		|WHERE
		|	NOT Recipients.Excluded";
		
	Else
		
		QueryText =
		"SELECT
		|	TableOfRecipients.Recipient,
		|	TableOfRecipients.Excluded
		|INTO TableOfRecipients
		|FROM
		|	&TableOfRecipients AS TableOfRecipients
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	Recipients.Ref AS Recipient,
		|	Recipients.Description AS Description,
		|	Contacts.Presentation AS EMail
		|FROM
		|	Catalog.Users AS Recipients
		|	LEFT JOIN Catalog.Users.ContactInformation AS Contacts
		|		ON Contacts.Ref = Recipients.Ref
		|		AND Contacts.Kind = &RecipientsEmailAddressKind
		|WHERE
		|	Recipients.Ref IN HIERARCHY
		|		(SELECT
		|			Recipient
		|		FROM
		|			TableOfRecipients
		|		WHERE
		|			NOT Excluded)
		|	AND NOT Recipients.Ref IN HIERARCHY
		|		(SELECT
		|			Recipient
		|		FROM
		|			TableOfRecipients
		|		WHERE
		|			Excluded)
		|	AND NOT Recipients.DeletionMark
		|	AND &ThisIsNotGroup";
		
		If Not RecipientsMetadata.Hierarchical Then
			// Not hierarchical item.
			QueryText = StrReplace(QueryText, "IN HIERARCHY", "In");
			QueryText = StrReplace(QueryText, "AND &ThisIsNotGroup", "");
		ElsIf RecipientsMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyOfItems Then
			// Hierarchy of items.
			QueryText = StrReplace(QueryText, "AND &ThisIsNotGroup", "");
		Else
			// Hierarchy of groups.
			QueryText = StrReplace(QueryText, "AND &ThisIsNotGroup", "AND NOT Recipients.IsFolder");
		EndIf;
		
		QueryText = StrReplace(QueryText, "Catalog.Users", RecipientsMetadata.FullName());
		
	EndIf;
	
	Query.SetParameter("TableOfRecipients", TableOfRecipients);
	If ValueIsFilled(RecipientsEmailAddressKind) Then
		Query.SetParameter("RecipientsEmailAddressKind", RecipientsEmailAddressKind);
	Else
		QueryText = StrReplace(QueryText, ".Kind = &RecipientsEmailAddressKind", ".Type = &MailAddressType");
		Query.SetParameter("MailAddressType", Enums.ContactInformationTypes.Email);
	EndIf;
	Query.Text = QueryText;
	
	ErrorMessageTextForEventLog = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể tạo danh sách người nhận ""%1""do:';
			|ru = 'Не удалось сформировать список получателей ""%1"" по причине:';
			|en = 'Cannot generate recipient list ""%1"" due to:'; fa = 'Cannot generate recipient list ""%1"" due to:';
			|it = 'Non è stato possibile generare l''elenco dei destinatari ""%1"" a causa di:';
			|pl = 'Nie udało się utworzyć listy odbiorców ""%1"" z powodu:';
			|tr = '''''%1'''' alıcı listesi bundan dolayı oluşturulamıyor:'"), String(RecipientsType));
	
	// Extension mechanism.
	Try
		StandardProcessing = True;
		ReportMailingOverridable.BeforeGenerateMailingRecipientsList(BulkEmail, Query, StandardProcessing, RecipientsList);
		If StandardProcessing <> True Then
			Return RecipientsList;
		EndIf;
	Except
		LogRecord(LogParameters,, ErrorMessageTextForEventLog, ErrorInfo());
		Return RecipientsList;
	EndTry;
	
	// Standard data processor.
	Try
		BulkEmailRecipients = Query.Execute().Unload();
	Except
		LogRecord(LogParameters,, ErrorMessageTextForEventLog, ErrorInfo());
		Return RecipientsList;
	EndTry;
	
	RecipientsWithoutAnAddress = New Array;
	RecipientsWithoutAddressDescriptions = New Array;
	HasDescription = ?(BulkEmailRecipients.Columns.Find("Description") <> Undefined, True, False);
	
	For Each BulkEmailRecipient In BulkEmailRecipients Do
		If Not ValueIsFilled(BulkEmailRecipient.EMail) Then
			RecipientsWithoutAnAddress.Add(BulkEmailRecipient.Recipient);
			Description = ?(HasDescription, BulkEmailRecipient.Description, String(BulkEmailRecipient.Recipient));
			RecipientsWithoutAddressDescriptions.Add(Description);
			Continue;
		EndIf;
		
		CurrentAddress = RecipientsList.Get(BulkEmailRecipient.Recipient);
		CurrentAddress = ?(CurrentAddress = Undefined, "", CurrentAddress + "; ");
		RecipientsList[BulkEmailRecipient.Recipient] = CurrentAddress + BulkEmailRecipient.EMail;
	EndDo;
	
	If RecipientsWithoutAnAddress.Count() > 0 And LogParameters <> Undefined Then
		
		PatternOfTheWarningText = NStr("vi = 'Báo cáo chưa được gửi cho những người nhận sau đây, bởi vì chưa điền địa chỉ email:
			|- %1.';
			|ru = 'Отчеты не отправлены следующим получателям, так как не заполнен адрес электронной почты:
			|- %1.';
			|en = 'The reports were not sent to the following recipients as the email address is not filled in:
			|-%1.'; fa = 'The reports were not sent to the following recipients as the email address is not filled in:
			|-%1.';
			|it = 'Report non inviati ai prossimi destinatari, poiché non è compilato l''indirizzo di posta elettronica:
			|- %1.';
			|pl = 'Raporty nie były wysłane następującym odbiorcom, ponieważ nie jest wypełniony adres poczty elektronicznej:
			|- %1.';
			|tr = 'Raporlar e-posta adresi eksik oluğundan aşağıdaki alıcılara gönderilemedi:
			|- %1.'");
		
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(
			PatternOfTheWarningText, StrConcat(RecipientsWithoutAddressDescriptions, ";" + Chars.LF + "- "));
		
		LogRecord(LogParameters, EventLogLevel.Warning, WarningText);
		
		If GetFunctionalOption("RetainReportDistributionHistory") 
		   And TypeOf(LogParameters.Data) = Type("CatalogRef.ReportMailings") 
		   And DeliveryParameters <> Undefined Then
			For Each RecipientsWithoutAddress In RecipientsWithoutAnAddress Do
				HistoryFields = ReportDistributionHistoryFields(LogParameters.Data, RecipientsWithoutAddress, DeliveryParameters.ExecutionDate);
				HistoryFields.Account = DeliveryParameters.Account;
				If DeliveryParameters.NotifyOnly Then
					HistoryFields.Comment = NStr("vi = 'Chưa gửi thông báo theo nguyên nhân: ""Chưa chỉ ra địa chỉ email"".';
												|ru = 'Уведомления не отправлены по причине: ""Адрес электронной почты не указан"".';
												|en = 'Couldn''t send notifications: Email address not specified.'; fa = 'Couldn''t send notifications: Email address not specified.';
												|it = 'Уведомления не отправлены по причине: ""Адрес электронной почты не указан"".';
												|pl = 'Couldn''t send notifications: Email address not specified.';
												|tr = 'Bildirimler şu sebeple gönderilemedi: ""E-posta adresi belirtilmemiş"".'");
				Else
					HistoryFields.Comment = NStr("vi = 'Chưa gửi thông báo theo nguyên nhân: ""Chưa chỉ ra địa chỉ email"".';
												|ru = 'Уведомления не отправлены по причине: ""Адрес электронной почты не указан"".';
												|en = 'Couldn''t send notifications: Email address not specified.'; fa = 'Couldn''t send notifications: Email address not specified.';
												|it = 'Уведомления не отправлены по причине: ""Адрес электронной почты не указан"".';
												|pl = 'Couldn''t send notifications: Email address not specified.';
												|tr = 'Bildirimler şu sebeple gönderilemedi: ""E-posta adresi belirtilmemiş"".'");
				EndIf;
				HistoryFields.Executed = False;
				HistoryFields.MethodOfObtaining = DistributionReceiptMethod(DeliveryParameters, RecipientsWithoutAddress);
				
				InformationRegisters.ReportsDistributionHistory.CommitResultOfDistributionToRecipient(HistoryFields);
			EndDo;
		EndIf;
		
	EndIf;
	
	If RecipientsList.Count() = 0 Then
	ErrorsText = NStr("vi = 'Không thể tạo danh sách người nhận ""%1"" vì do một trong các nguyên nhân sau:
		| - Người nhận chưa điền địa chỉ email ""%2"";
		| - Chưa điền danh sách người nhận hoặc người nhận đã bị đặt dấu xóa;
		| - Đã chọn nhóm người nhận trống;
		| - Đã loại trừ tất cả người nhận (loại trừ có mức độ ưu tiên cao nhất; thành viên của các nhóm bị loại trừ cũng bị loại trừ khỏi danh sách);
		| - Không đủ quyền truy cập vào danh mục ""%1"".';
		|ru = 'Не удалось сформировать список получателей ""%1"" по одной из возможных причин:
		| - У получателей не заполнен адрес электронной почты ""%2"";
		| - Не заполнен список получателей или получатели помечены на удаление;
		| - Выбраны пустые группы получателей;
		| - Исключены все получатели (исключение имеет наивысший приоритет; участники исключенных групп также исключаются из списка);
		| - Недостаточно прав доступа к справочнику ""%1"".';
		|en = 'Cannot generate recipient list ""%1"". Possible reasons:
		| - ""%2"" email is not specified for some of the recipients.
		| - The list of recipients is empty or recipients are marked for deletion.
		| - The groups of recipients are empty.
		| - All recipients are excluded. If you exclude a group, all its members are excluded from the recipient list.
		| - You have insufficient rights to access catalog ""%1"".'; fa = 'Cannot generate recipient list ""%1"". Possible reasons:
		| - ""%2"" email is not specified for some of the recipients.
		| - The list of recipients is empty or recipients are marked for deletion.
		| - The groups of recipients are empty.
		| - All recipients are excluded. If you exclude a group, all its members are excluded from the recipient list.
		| - You have insufficient rights to access catalog ""%1"".';
		|it = 'Non è stato possibile generare l''elenco dei destinatari ""%1"" per una delle seguenti cause:
		| - L''indirizzo di posta elettronica dei destinatari non è compilato ""%2"";
		| - L''elenco dei destinatari non è compilato o i destinatari sono contrassegnati per l''eliminazione;
		| - Sono stati selezionati gruppi vuoti di destinatari;
		| - Tutti i destinatari sono esclusi (l''esclusione ha la priorità; anche i partecipanti dei gruppi esclusi vengono esclusi dagli elenchi);
		| - I diritti di accesso alla directory ""%1"" non sono sufficienti.';
		|pl = 'Nie udało się utworzyć listy odbiorców ""%1"" z jednej z możliwych przyczyn:
		| - U odbiorców nie wypełniono adresu poczty elektronicznej ""%2"";
		| - Nie wypełniono listy odbiorcóe lub odbiorcy są zaznaczeni do usunięcia;
		| - Wybrane puste grupy odbiorców;
		| - Wykluczono wszystkich odbiorców (wyjątkiem jest najwyższy priorytet; uczestnicy grup również są wykluczani z listy);
		| - Brak wystarczających uprawnień dostępu do katalogu ""%1"".';
		|tr = '''''%1'''' alıcı listesi bu olası sebeplerden birinden dolayı oluşturulamıyor: 
		| - Alıcıların e-posta adresi ''''%2'''' belirtilmemiş; 
		| - Alıcı listesi verilmemiş veya alıcılar silinmek üzere işaretlenmiş; 
		| - Seçilen alıcılar grupları boş; 
		| - Tüm alıcılar hariç tutulmuş (hariç tutulma en yüksek önceliğe sahip; hariç tutulan grupların katılımcıları da listeden hariç tutulur); 
		| - ''''%1'''' kataloğuna erişmek için yeterli haklara sahip değilsiniz.'");
		
		LogRecord(LogParameters, EventLogLevel.Error,
			StringFunctionsClientServer.SubstituteParametersToString(ErrorsText, String(RecipientsType),
			String(RecipientsEmailAddressKind)), "");
	EndIf;
	
	Return RecipientsList;
EndFunction

// Generates a list of recipients from the Recipients table.
//
// Parameters:
//   BulkEmail - CatalogRef.ReportMailings
//   LogParameters - See LogParameters
//
// Returns: 
//   Array of CatalogRef.ReportMailings
//
Function GenerateArrayOfDistributionRecipients(BulkEmail, LogParameters)
	
	If BulkEmail.Personal Then
		
		RecipientsType = TypeOf(BulkEmail.Author);
		RecipientsMetadata = Metadata.FindByType(RecipientsType);
		
		TableOfRecipients = New ValueTable;
		For Each Attribute In Metadata.Catalogs.ReportMailings.TabularSections.Recipients.Attributes Do
			TableOfRecipients.Columns.Add(Attribute.Name, Attribute.Type);
		EndDo;
		TableOfRecipients.Add().Recipient = BulkEmail.Author;
		
	Else
		RecipientsMetadata = Common.MetadataObjectByID(BulkEmail.MailingRecipientType, False);
		MetadataObjectKey = ?(ValueIsFilled(BulkEmail.MailingRecipientType),
			Common.ObjectAttributeValue(BulkEmail.MailingRecipientType, "MetadataObjectKey"), Undefined);
		RecipientsType = ?(MetadataObjectKey <> Undefined, MetadataObjectKey.Get(), Undefined);
		TableOfRecipients = BulkEmail.Recipients.Unload();
	EndIf;
	
	RecipientEmptyValue = ?(TypeOf(RecipientsType) = Type("Type"), New (RecipientsType), Undefined);
	SearchParameters = New Structure("Recipient", RecipientEmptyValue);
	RowsWithoutRecipients = TableOfRecipients.FindRows(SearchParameters);
	For Each RecipientRow In RowsWithoutRecipients Do
		TableOfRecipients.Delete(RecipientRow);
	EndDo;
	
	ArrayOfRecipients_ = New Array;
	
	If RecipientsMetadata = Undefined Or RecipientsMetadata = Null Then
		Return ArrayOfRecipients_;
	EndIf;

	Query = New Query;
	If RecipientsType = Type("CatalogRef.Users") Then
	
		QueryText =
		"SELECT
		|	TableOfRecipients.Recipient,
		|	TableOfRecipients.Excluded
		|INTO TableOfRecipients
		|FROM
		|	&TableOfRecipients AS TableOfRecipients
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	User.Ref AS Recipient
		|FROM
		|	TableOfRecipients AS TableOfRecipients
		|		LEFT JOIN InformationRegister.UserGroupCompositions AS UserGroupCompositions
		|		ON UserGroupCompositions.UsersGroup = TableOfRecipients.Recipient
		|		LEFT JOIN Catalog.Users AS Users
		|		ON Users.Ref = UserGroupCompositions.User
		|WHERE
		|	NOT Users.DeletionMark
		|	AND NOT Users.Invalid
		|	AND NOT Users.IsInternal
		|	AND NOT TableOfRecipients.Excluded
		|GROUP BY
		|	User.Ref";
		
	Else
		
		QueryText =
		"SELECT
		|	TableOfRecipients.Recipient,
		|	TableOfRecipients.Excluded
		|INTO TableOfRecipients
		|FROM
		|	&TableOfRecipients AS TableOfRecipients
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	Recipients.Ref AS Recipient
		|FROM
		|	Catalog.Users AS Recipients
		|WHERE
		|	Recipients.Ref IN HIERARCHY
		|		(SELECT
		|			Recipient
		|		FROM
		|			TableOfRecipients
		|		WHERE
		|			NOT Excluded)
		|	AND NOT Recipients.Ref IN HIERARCHY
		|		(SELECT
		|			Recipient
		|		FROM
		|			TableOfRecipients
		|		WHERE
		|			Excluded)
		|	AND NOT Recipients.DeletionMark
		|	AND &ThisIsNotGroup";
		
		If Not RecipientsMetadata.Hierarchical Then
			// Not hierarchical item.
			QueryText = StrReplace(QueryText, "IN HIERARCHY", "In");
			QueryText = StrReplace(QueryText, "AND &ThisIsNotGroup", "");
		ElsIf RecipientsMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyOfItems Then
			// Hierarchy of items.
			QueryText = StrReplace(QueryText, "AND &ThisIsNotGroup", "");
		Else
			// Hierarchy of groups.
			QueryText = StrReplace(QueryText, "AND &ThisIsNotGroup", "AND NOT Recipients.IsFolder");
		EndIf;
		
		QueryText = StrReplace(QueryText, "Catalog.Users", RecipientsMetadata.FullName());
		
	EndIf;
	
	Query.SetParameter("TableOfRecipients", TableOfRecipients);
	Query.Text = QueryText;
	
	ErrorMessageTextForEventLog = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể tạo danh sách người nhận ""%1"" do nguyên nhân:';
			|ru = 'Не удалось сформировать список получателей ""%1"" по причине:';
			|en = 'Cannot generate recipient list ""%1"" due to:'; fa = 'Cannot generate recipient list ""%1"" due to:';
			|it = 'Non è stato possibile generare l''elenco dei destinatari ""%1"" a causa di:';
			|pl = 'Nie udało się utworzyć listy odbiorców ""%1"" z powodu:';
			|tr = '''''%1'''' alıcı listesi bundan dolayı oluşturulamıyor:'"), String(RecipientsType));
	
	// Extension mechanism.
	RecipientsList = New Map;
	Try
		StandardProcessing = True;
		ReportMailingOverridable.BeforeGenerateMailingRecipientsList(BulkEmail, Query, StandardProcessing, RecipientsList);
		If StandardProcessing <> True Then
			For Each Recipient In RecipientsList Do
				ArrayOfRecipients_.Add(Recipient.Key);
			EndDo;
			Return ArrayOfRecipients_;
		EndIf;
	Except
		LogRecord(LogParameters,, ErrorMessageTextForEventLog, ErrorInfo());
		Return ArrayOfRecipients_;
	EndTry;
	
	// Standard data processor.
	Try
		BulkEmailRecipients = Query.Execute().Unload();
	Except
		LogRecord(LogParameters,, ErrorMessageTextForEventLog, ErrorInfo());
		Return ArrayOfRecipients_;
	EndTry;
	
	For Each BulkEmailRecipient In BulkEmailRecipients Do
		ArrayOfRecipients_.Add(BulkEmailRecipient.Recipient);
	EndDo;
	
	Return ArrayOfRecipients_;
	
EndFunction

Function IsDistributionRecipientsSelected(BulkEmail, DeliveryParameters, LogParameters, AdditionalSettings)
	
	Recipients = GenerateMailingRecipientsList(BulkEmail, LogParameters, DeliveryParameters);
	
	If AdditionalSettings <> Undefined
		And AdditionalSettings.Property("Recipients") Then
		
		SelectedRecipients = AdditionalSettings.Recipients;
		ExcludedReceivers = New Array;
		
		For Each Recipient In Recipients Do 
			
			If SelectedRecipients[Recipient.Key] = Undefined Then 
				ExcludedReceivers.Add(Recipient.Key);
			EndIf;
			
		EndDo;
		
		For Each Recipient In ExcludedReceivers Do 
			Recipients.Delete(Recipient);
		EndDo;
		
	EndIf;
	
	If Recipients.Count() = 0 Then
		
		DeliveryParameters.UseEmail = False;
		
		If Not DeliveryParameters.UseFolder
			And Not DeliveryParameters.UseNetworkDirectory
			And Not DeliveryParameters.UseFTPResource Then
			
			Return False;
		EndIf;
		
	EndIf;
	
	DeliveryParameters.Recipients = Recipients;
	
	Return True;
	
EndFunction

// Connects, checks and initializes the report by reference and used before generating or editing
// parameters.
//
// Parameters:
//   LogParameters - See LogParameters.
//   ReportParameters - Structure - a settings report and the result of its initialization:
//       * Report - CatalogRef.ReportsOptions - a report reference.
//       * Settings - Undefined
//                   - DataCompositionUserSettings
//                   - ValueTable -
//           Report settings to apply.
//           See the WriteReportsRowSettings procedure of the Catalog.ReportsMailing.ObjectForm module.
//   PersonalizationAvailable - Boolean - True if a report can be personalized.
//   FormUniqueID - UUID - DCS address.
//
// The parameters modifiable upon the method runtime::
//   ReportParameters - Structure:
//     Initialization result:
//       * Initialized - Boolean - True if was successful.
//       * Errors          - String - an error text.
//     Properties of all reports:
//       * Name        - String - a report name.
//       * IsOption - Boolean - True if a report is from the ReportsOptions catalog.
//       * DCS        - Boolean - True if a report is based on DCS.
//       * Metadata - MetadataObjectReport - report metadata.
//       * Object     - ReportObject, ExternalReport - a report object.
//     Properties of reports based on DCS:
//       * DCSchema               - DataCompositionSchema
//       * DCSettingsComposer - DataCompositionSettingsComposer
//       * DCSettings           - DataCompositionSettings
//       * SchemaURL            - String - an address of data composition schema in the temporary storage.
//     Properties of arbitrary reports:
//       * AvailableAttributes - Structure - a name and parameters of the attribute:
//           ** AttributeName - Structure - attribute parameters:
//               *** Presentation - String - an attribute presentation.
//               *** Type           - TypeDescription - an attribute type.
//
// Returns: 
//   Boolean - True if initialization was successful (matches the ReportParameters.Initialized).
//
Function InitializeReport(LogParameters, ReportParameters, PersonalizationAvailable, FormUniqueID = Undefined) Export
	
	// Re-initialize the check.
	If ReportParameters.Property("Initialized") Then
		Return ReportParameters.Initialized;
	EndIf;
	
	ReportParameters.Insert("Initialized", False);
	ReportParameters.Insert("Errors", "");
	ReportParameters.Insert("IsPersonalized", False);
	ReportParameters.Insert("PersonalFilters", New Map);
	ReportParameters.Insert("IsOption", TypeOf(ReportParameters.Report) = Type("CatalogRef.ReportsOptions"));
	ReportParameters.Insert("DCS", False);
	ReportParameters.Insert("AvailableAttributes", Undefined);
	ReportParameters.Insert("DCSettingsComposer", Undefined);
	
	ConnectionParameters = ReportsOptions.ReportGenerationParameters();
	ConnectionParameters.OptionRef1 = ReportParameters.Report;
	ConnectionParameters.FormIdentifier = FormUniqueID;
	ConnectionParameters.DCUserSettings = ReportParameters.Settings;
	If TypeOf(ConnectionParameters.DCUserSettings) <> Type("DataCompositionUserSettings") Then
		ConnectionParameters.DCUserSettings = New DataCompositionUserSettings;
	EndIf;
	Try
		Connection = ReportsOptions.AttachReportAndImportSettings(ConnectionParameters);
		CommonClientServer.SupplementStructure(ReportParameters, Connection, True);
	Except
		ReportParameters.Errors = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kết nối và kết nhập tùy chỉnh báo cáo ""%1"".';
				|ru = 'Не удалось подключить и загрузить настройки отчета ""%1"".';
				|en = 'Cannot import settings from the ""%1"" report.'; fa = 'Cannot import settings from the ""%1"" report.';
				|it = 'Non è stato possibile connettere e scaricare le impostazioni del report ""%1"".';
				|pl = 'Nie udało się połączyć i pobrać ustawienia raportu ""%1"".';
				|tr = '""%1"" raporu eklenemiyor ve ayarları yüklenemiyor.'"),
			String(ReportParameters.Report));
		LogRecord(
			LogParameters,
			EventLogLevel.Error,
			ReportParameters.Errors,
			ErrorInfo());
		Return ReportParameters.Initialized;
	EndTry;
	
	// In existing mailings, we generate only reports that are ready for mailing.
	If ReportMailingCached.ReportsToExclude().Find(Connection.RefOfReport) <> Undefined Then
		ReportParameters.Errors = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Báo cáo ""%1"" không được dùng để gửi hàng loạt.';
				|ru = 'Отчет ""%1"" не предназначен для рассылки.';
				|en = 'Report ""%1"" is not intended for distribution.'; fa = 'Report ""%1"" is not intended for distribution.';
				|it = 'Report ""%1"" non previsto per la distribuzione.';
				|pl = 'Raport ""%1"" nie jest przeznaczony do rozsyłania.';
				|tr = '""%1"" raporu bülten için tasarlanmamıştır.'"), String(Connection.RefOfReport));
		LogRecord(LogParameters, EventLogLevel.Error, ReportParameters.Errors);
		Return False;
	EndIf;
	If Not Connection.Success Then
		LogRecord(LogParameters, EventLogLevel.Error, Connection.ErrorText);
		Return False;
	EndIf;
	ReportParameters.DCSettingsComposer = Connection.Object.SettingsComposer;
	
	// Define whether the report is based on Data Composition System.
	If TypeOf(ReportParameters.Settings) = Type("DataCompositionUserSettings") Then
		ReportParameters.DCS = True;
	ElsIf TypeOf(ReportParameters.Settings) = Type("ValueTable") 
		Or TypeOf(ReportParameters.Settings) = Type("Structure") Then
		ReportParameters.DCS = False;
	Else
		ReportParameters.DCS = (ReportParameters.Object.DataCompositionSchema <> Undefined);
	EndIf;
	
	// Initialize a report and fill its parameters.
	If ReportParameters.DCS Then
		
		// Set personal filters.
		If PersonalizationAvailable Then
			DCUserSettings = ReportParameters.DCSettingsComposer.UserSettings;
			Filter = New Structure("Use, Value", True, "[Recipient]");
			FoundItems = ReportsClientServer.SettingsItemsFiltered(DCUserSettings, Filter);
			For Each DCUserSetting In FoundItems Do
				DCID = DCUserSettings.GetIDByObject(DCUserSetting);
				If DCID <> Undefined Then
					ReportParameters.PersonalFilters.Insert(DCID);
				EndIf;
			EndDo;
		EndIf;
		
	Else // Not a DCS report.
		
		// Available report attributes.
		ReportParameters.AvailableAttributes = New Structure;
		For Each Attribute In ReportParameters.Metadata.Attributes Do
			ReportParameters.AvailableAttributes.Insert(Attribute.Name, 
				New Structure("Presentation, Type", Attribute.Presentation(), Attribute.Type));
		EndDo;
		
		If ValueIsFilled(ReportParameters.Settings) Then
			
			// Check if the attributes exist.
			// Prepare custom filter maps.
			// Assign values to the static attributes.
			For Each SettingDetails In ReportParameters.Settings Do
				If TypeOf(SettingDetails) = Type("ValueTableRow") Then
					AttributeName = SettingDetails.Attribute;
				Else
					AttributeName = SettingDetails.Key;
				EndIf;
				SettingValue = SettingDetails.Value;
				
				// Attribute availability.
				If Not ReportParameters.AvailableAttributes.Property(AttributeName) Then
					Continue;
				EndIf;
				
				// Belonging to the mechanism of personalization.
				If PersonalizationAvailable And SettingValue = "[Recipient]" Then
					// Register a personal filter field.
					ReportParameters.PersonalFilters.Insert(AttributeName);
				Else
					// Set value of report object attribute.
					ReportParameters.Object[AttributeName] = SettingValue;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	ReportParameters.IsPersonalized = (ReportParameters.PersonalFilters.Count() > 0);
	ReportParameters.Initialized = True;
	
	Return True;
EndFunction

// Generates a report and checks that the result is empty.
//
// Parameters:
//   LogParameters - Structure - Logging parameters. See LogRecord.
//   ReportParameters  - See InitializeReport
//   Recipient       - CatalogRef - a recipient reference.
//
// Returns: 
//   Structure - Report generation result:
//       * TabDoc - SpreadsheetDocument - Spreadsheet document.
//       * IsEmpty - Boolean - True if the report did not contain any parameters values.
//
Function GenerateReport(LogParameters, ReportParameters, Recipient = Undefined)
	Result = New Structure("TabDoc, Generated1, IsEmpty", New SpreadsheetDocument, False, True);
	
	If Not ReportParameters.Property("Initialized") Then
		LogRecord(LogParameters, ,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chưa khởi tạo báo cáo ''%1''';
																			|ru = 'Отчет ''%1'' не инициализирован';
																			|en = 'Report ''%1'' not initialized'; fa = 'Report ''%1'' not initialized';
																			|it = 'Report ""%1"" non inizializzato';
																			|pl = 'Raport ""%1"" nie został zainicjowany';
																			|tr = 'Rapor ''%1'' başlatılmadı'"), String(ReportParameters.Report)));
		Return Result;
	EndIf;
	
	GenerationParameters = ReportGenerationParameters(ReportParameters, Recipient);
	Generation1 = ReportsOptions.GenerateReport(GenerationParameters, True, Not ReportParameters.SendIfEmpty);
	
	If Not Generation1.Success Then
		LogRecord(LogParameters, EventLogLevel.Error,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Báo cáo ""%1"":';
																			|ru = 'Отчет ""%1"":';
																			|en = 'Report ""%1"":'; fa = 'Report ""%1"":';
																			|it = 'Report ""%1"":';
																			|pl = 'Raport ""%1"":';
																			|tr = '""%1"" raporu:'"),
			String(ReportParameters.Report)), Generation1.ErrorText);
		Result.TabDoc = Undefined;
		Return Result;
	EndIf;
	
	Result.Generated1 = True;
	Result.TabDoc = Generation1.SpreadsheetDocument;
	If ReportParameters.SendIfEmpty Then
		Result.IsEmpty = False;
	Else
		Result.IsEmpty = Generation1.IsEmpty;
	EndIf;
	
	Return Result;
EndFunction

Function ReportGenerationParameters(ReportParameters, Recipient)
	
	ReportGenerationParameters = New Structure;
	
	// Fill personalized recipients data.
	If Recipient <> Undefined And ReportParameters.Property("PersonalFilters") Then
		If ReportParameters.DCS Then
			DCUserSettings = ReportParameters.DCSettingsComposer.UserSettings;
			
			For Each KeyAndValue In ReportParameters.PersonalFilters Do
				Setting = DCUserSettings.GetObjectByID(KeyAndValue.Key);
				
				If TypeOf(Setting) = Type("DataCompositionFilterItem") Then
					Setting.RightValue = Recipient;
				ElsIf TypeOf(Setting) = Type("DataCompositionSettingsParameterValue") Then
					Setting.Value = Recipient;
				EndIf;
			EndDo;
			
			ReportGenerationParameters.Insert("DCUserSettings", DCUserSettings);
		Else
			For Each KeyAndValue In ReportParameters.PersonalFilters Do
				ReportParameters.Object[KeyAndValue.Key] = Recipient;
			EndDo;
		EndIf;
	EndIf;
	
	AdditionalParameters = New Structure("Report, Object, DCS, DCSettingsComposer");
	FillPropertyValues(AdditionalParameters, ReportParameters);
	
	ReportMailingOverridable.OnPrepareReportGenerationParameters(ReportGenerationParameters, AdditionalParameters);

	Result = ReportsOptions.ReportGenerationParameters();
	CommonClientServer.SupplementStructure(Result, ReportGenerationParameters, True);

	FillPropertyValues(ReportParameters, AdditionalParameters);
	Result.Connection = ReportParameters;
	
	Return Result;
	
EndFunction

// Transports attachments for all delivery methods.
//
// Parameters:
//   LogParameters  - See LogParameters
//   DeliveryParameters - See ExecuteBulkEmail
//   Attachments          - Map of KeyAndValue:
//     * Key     - String - file name
//     * Value - String - Full filename
//
// Returns:
//   Boolean - "True" if the delivery is executed at least by one of the methods.
//
Function ExecuteDelivery(LogParameters, DeliveryParameters, Attachments) Export
	Result = False;
	
	// To network directory.
	If DeliveryParameters.UseNetworkDirectory Then
		DeliverToNetworkDirectory(LogParameters, DeliveryParameters, Attachments, Result);
	EndIf;
	
	// To FTP resource.
	If DeliveryParameters.UseFTPResource Then
		DeliverToFTPResource(LogParameters, DeliveryParameters, Attachments, Result);
	EndIf;
	
	// To folder.
	If DeliveryParameters.UseFolder Then
		DeliverToFolder(LogParameters, DeliveryParameters, Attachments, Result);
	EndIf;
	
	// By email.
	If DeliveryParameters.UseEmail Then
		DeliverByEmail(LogParameters, DeliveryParameters, Attachments, Result);
	EndIf;
	
	Return Result;
EndFunction

// Gets a username by the Users catalog reference.
//
// Parameters:
//   User - CatalogRef.Users - a user reference.
//
// Returns:
//   String - a username.
//
Function IBUserName(User) Export
	If Not ValueIsFilled(User) Then
		Return "";
	EndIf;
	
	SetPrivilegedMode(True);
	
	IBUser = InfoBaseUsers.FindByUUID(
		Common.ObjectAttributeValue(User, "IBUserID"));
	If IBUser = Undefined Then
		Return "";
	EndIf;
	
	Return IBUser.Name;
EndFunction

// Creates a record in the Event log and outputs user messages.
// A brief error presentation is output to the user, and a detailed error presentation is written to the log.
//
// Parameters:
//   LogParameters - See LogParameters
//   LogLevel - EventLogLevel - Message importance for the administrator.
//       Determined automatically based on the ProblemDetails parameter type.:
//       If type is ErrorInformation, then "Error". If type is String, then "Warning".
//       Otherwise, "Information".
//   Text - String - brief details of the issue.
//   IssueDetails - ErrorInfo
//                    - String - a problem description that is added after the text.
//
Procedure LogRecord(LogParameters, Val LogLevel = Undefined, Val Text = "", Val IssueDetails = Undefined) Export
	
	If LogParameters = Undefined Then
		Return;
	EndIf;
	
	// Determine the Event log level based on the type of the passed error message.
	If TypeOf(LogLevel) <> Type("EventLogLevel") Then
		If TypeOf(IssueDetails) = Type("ErrorInfo") Then
			LogLevel = EventLogLevel.Error;
		ElsIf TypeOf(IssueDetails) = Type("String") Then
			LogLevel = EventLogLevel.Warning;
		Else
			LogLevel = EventLogLevel.Information;
		EndIf;
	EndIf;
	
	If LogLevel = EventLogLevel.Error Then
		LogParameters.Insert("HadErrors", True);
	ElsIf LogLevel = EventLogLevel.Warning Then
		LogParameters.Insert("HasWarnings", True);
	EndIf;
	
	WriteToLog = ValueIsFilled(LogParameters.Data);
	
	TextForLog      = Text;
	TextForUser = Text;
	If TypeOf(IssueDetails) = Type("ErrorInfo") Then
		If WriteToLog Then
			TextForLog = TextForLog + Chars.LF + Chars.LF + ErrorProcessing.DetailErrorDescription(IssueDetails);
		EndIf;	
		TextForUser = TextForUser + Chars.LF + Chars.LF + ErrorProcessing.BriefErrorDescription(IssueDetails);
	ElsIf TypeOf(IssueDetails) = Type("String") Then
		If WriteToLog Then
			TextForLog = TextForLog + Chars.LF + Chars.LF + IssueDetails;
		EndIf;
		TextForUser = TextForUser + Chars.LF + Chars.LF + IssueDetails;
	EndIf;
	
	// The Event log.
	If WriteToLog Then
		WriteLogEvent(LogParameters.EventName, LogLevel, LogParameters.Metadata, 
			LogParameters.Data, TrimAll(TextForLog));
	EndIf;
	
	// User message.
	TextForUser = TrimAll(TextForUser);
	If (LogLevel = EventLogLevel.Error) Or (LogLevel = EventLogLevel.Warning) Then
		If LogParameters.Property("ErrorsArray") And TypeOf(LogParameters.ErrorsArray) = Type("Array") Then
			Message = New UserMessage;
			Message.Text = TextForUser;
			Message.SetData(LogParameters.Data);
			ErrorsArray = LogParameters.ErrorsArray; // Array of UserMessage
			ErrorsArray.Add(Message);
		Else
			Common.MessageToUser(TextForUser,,,LogParameters.Data);
		EndIf;
	EndIf;
	
EndProcedure

// Generates PermissionsArray according to report mailing data.
//
// Parameters:
//  BulkEmail - QueryResultSelection
//
// Returns:
//  Array
//
Function PermissionsToUseServerResources(BulkEmail) Export
	Permissions = New Array;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	If BulkEmail.UseNetworkDirectory Then
		If ValueIsFilled(BulkEmail.NetworkDirectoryWindows) Then
			Item = ModuleSafeModeManager.PermissionToUseFileSystemDirectory(
				BulkEmail.NetworkDirectoryWindows,
				True,
				True,
				NStr("vi = 'Thư mục mạng để đăng tải báo cáo từ máy chủ Windows.';
					|ru = 'Сетевой каталог для публикации отчетов с сервера Windows.';
					|en = 'Network directory to publish reports from a Windows server.'; fa = 'Network directory to publish reports from a Windows server.';
					|it = 'Directory di rete per la pubblicazione dei report dal server Windows.';
					|pl = 'Sieciowy katalog publikacji raportów z serwera Windows.';
					|tr = 'Windows sunucusundan rapor yayımı için ağ dizini.'"));
			Permissions.Add(Item);
		EndIf;
		If ValueIsFilled(BulkEmail.NetworkDirectoryLinux) Then
			Item = ModuleSafeModeManager.PermissionToUseFileSystemDirectory(
				BulkEmail.NetworkDirectoryLinux,
				True,
				True,
				NStr("vi = 'Thư mục mạng để đăng tải báo cáo từ máy chủ Linux.';
					|ru = 'Сетевой каталог для публикации отчетов с сервера Linux.';
					|en = 'Network directory to publish reports from a Linux server.'; fa = 'Network directory to publish reports from a Linux server.';
					|it = 'Directory di rete per la pubblicazione di report dal server Linux';
					|pl = 'Katalog sieciowy dla publikacji raportów z serwera Linux.';
					|tr = 'Linux sunucusundan rapor yayımı için ağ dizini.'"));
			Permissions.Add(Item);
		EndIf;
	EndIf;
	If BulkEmail.UseFTPResource Then
		If ValueIsFilled(BulkEmail.FTPServer) Then
			Item = ModuleSafeModeManager.PermissionToUseInternetResource(
				"FTP",
				BulkEmail.FTPServer + BulkEmail.FTPDirectory,
				BulkEmail.FTPPort,
				NStr("vi = 'Nguồn FTP để đăng tải báo cáo.';
					|ru = 'FTP ресурс для публикации отчетов.';
					|en = 'FTP server to publish reports.'; fa = 'FTP server to publish reports.';
					|it = 'Risorsa FTP per la pubblicazione di report.';
					|pl = 'FTP zasób dla publikacji raportów.';
					|tr = 'Rapor yayımı için FTP kaynağı.'"));
			Permissions.Add(Item);
		EndIf;
	EndIf;
	Return Permissions;
EndFunction

Function EventLogParameters(BulkEmail) Export
	Query = New Query;
	Query.Text =
	"SELECT
	|	States1.LastRunStart,
	|	States1.LastRunCompletion,
	|	States1.SessionNumber
	|FROM
	|	InformationRegister.ReportMailingStates AS States1
	|WHERE
	|	States1.BulkEmail = &BulkEmail";
	Query.SetParameter("BulkEmail", BulkEmail);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	If Not Selection.Next() Then
		Return Undefined;
	EndIf;
	Result = New Structure;
	Result.Insert("StartDate", Selection.LastRunStart);
	Result.Insert("EndDate", Selection.LastRunCompletion);
	// Interval is not more than 30 minutes because sessions numbers can be reused.
	If Not ValueIsFilled(Result.EndDate) Or Result.EndDate < Result.StartDate Then
		Result.EndDate = Result.StartDate + 30 * 60; 
	EndIf;
	If Not ValueIsFilled(Selection.SessionNumber) Then
		Result.Insert("Data", BulkEmail);
	Else
		Sessions = New ValueList;
		Sessions.Add(Selection.SessionNumber);
		Result.Insert("Session", Sessions);
	EndIf;
	Return Result;
EndFunction

Function GetEncryptionCertificatesForDistributionRecipients(RecipientsList) Export
	
	Query = New Query;
	Query.Text =
		"SELECT ALLOWED
		|	CertificatesOfReportDistributionRecipients.BulkEmailRecipient,
		|	CertificatesOfReportDistributionRecipients.CertificateToEncrypt
		|FROM
		|	InformationRegister.CertificatesOfReportDistributionRecipients AS CertificatesOfReportDistributionRecipients
		|WHERE
		|	CertificatesOfReportDistributionRecipients.BulkEmailRecipient IN (&RecipientsList)";
	
	Query.SetParameter("RecipientsList", RecipientsList);
	
	QueryResult = Query.Execute();
	
	Return QueryResult.Unload();

EndFunction

Function ReportRedistributionRecipients(BulkEmail, LastRunStart, SessionNumber) Export
	
	Recipients = New Map;
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	|	ReportsDistributionHistory.Recipient AS Recipient,
	|	ReportsDistributionHistory.EMAddress AS EMAddress,
	|	MAX(ReportsDistributionHistory.Executed) AS Executed
	|INTO TT_Recipients
	|FROM
	|	InformationRegister.ReportsDistributionHistory AS ReportsDistributionHistory
	|WHERE
	|	ReportsDistributionHistory.ReportMailing = &ReportMailing
	|	AND ReportsDistributionHistory.StartDistribution = &StartDistribution
	|	AND ReportsDistributionHistory.SessionNumber = &SessionNumber
	|	AND ReportsDistributionHistory.EMAddress <> """"
	|
	|GROUP BY
	|	ReportsDistributionHistory.Recipient,
	|	ReportsDistributionHistory.EMAddress
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Recipients.Recipient AS Recipient,
	|	TT_Recipients.EMAddress AS Email
	|FROM
	|	TT_Recipients AS TT_Recipients
	|WHERE
	|	NOT TT_Recipients.Executed
	|TOTALS BY
	|	Recipient";

	Query.SetParameter("ReportMailing",BulkEmail);
	Query.SetParameter("StartDistribution", LastRunStart);
	Query.SetParameter("SessionNumber", SessionNumber);
	
	QueryResult = Query.Execute();
	
	SampleRecipients = QueryResult.Select(QueryResultIteration.ByGroups);
		
	While SampleRecipients.Next() Do
		Selection = SampleRecipients.Select();
		Email = "";
		While Selection.Next() Do
			CurrentAddress = ?(IsBlankString(Email), "",
				Email + "; ");
			Email = CurrentAddress + Selection.Email;
		EndDo; 
		Recipients.Insert(SampleRecipients.Recipient, Email);
	EndDo;
	
	Return Recipients;
	
EndFunction

// Generates the delivery methods presentation according to delivery parameters.
//
// Parameters:
//   DeliveryParameters - See ExecuteBulkEmail.DeliveryParameters.
//
// Returns:
//   String
//
Function DeliveryMethodsPresentation(DeliveryParameters) Export
	Prefix = NStr("vi = 'Kết quả';
					|ru = 'Результат';
					|en = 'Result'; fa = 'نتیجه';
					|it = 'Результат';
					|pl = 'Result';
					|tr = 'Sonuç'");
	PresentationText = "";
	Suffix = "";
	
	If Not DeliveryParameters.NotifyOnly Then
		
		PresentationText = PresentationText 
		+ ?(PresentationText = "", Prefix, " " + NStr("vi = 'và';
														|ru = 'и';
														|en = 'and'; fa = 'و';
														|it = 'и';
														|pl = 'and';
														|tr = 've'")) 
		+ " "
		+ NStr("vi = 'gửi qua email (xem tệp đính kèm)';
				|ru = 'отправлен по почте (см. вложения)';
				|en = 'sent by email (see attachments)'; fa = 'sent by email (see attachments)';
				|it = 'inviato per posta (vedi allegati)';
				|pl = 'wysłany pocztą (patrz załączniki)';
				|tr = 'e-posta ile gönderildi (eklere bakınız)'");
		
	EndIf;
	
	If DeliveryParameters.ExecutedToFolder Then
		
		PresentationText = PresentationText 
		+ ?(PresentationText = "", Prefix, " " + NStr("vi = 'và';
														|ru = 'и';
														|en = 'and'; fa = 'و';
														|it = 'и';
														|pl = 'and';
														|tr = 've'")) 
		+ " "
		+ NStr("vi = 'đã thêm vào thư mục';
				|ru = 'доставлен в папку';
				|en = 'delivered to folder'; fa = 'delivered to folder';
				|it = 'consegnato nella cartella';
				|pl = 'dostarczony do folderu';
				|tr = 'klasöre teslim edildi'")
		+ " ";
		
		Ref = GetInfoBaseURL() +"#"+ GetURL(DeliveryParameters.Folder);
		
		If DeliveryParameters.HTMLFormatEmail Then
			PresentationText = PresentationText 
			+ "<a href = '"
			+ Ref
			+ "'>" 
			+ String(DeliveryParameters.Folder)
			+ "</a>";
		Else
			PresentationText = PresentationText 
			+ """"
			+ String(DeliveryParameters.Folder)
			+ """";
			Suffix = Suffix + ":" + Chars.LF + "<" + Ref + ">";
		EndIf;
		
	EndIf;
	
	If DeliveryParameters.ExecutedToNetworkDirectory Then
		
		PresentationText = PresentationText 
		+ ?(PresentationText = "", Prefix, " " + NStr("vi = 'và';
														|ru = 'и';
														|en = 'and'; fa = 'و';
														|it = 'и';
														|pl = 'and';
														|tr = 've'")) 
		+ " "
		+ NStr("vi = 'chuyển vào thư mục mạng';
				|ru = 'доставлен в сетевой каталог';
				|en = 'delivered to network directory'; fa = 'delivered to network directory';
				|it = 'consegnato nella directory di rete';
				|pl = 'dostarczony do katalogu sieciowego';
				|tr = 'ağ dizinine teslim edildi'")
		+ " ";
		
		If DeliveryParameters.HTMLFormatEmail Then
			PresentationText = PresentationText 
			+ "<a href = '"
			+ DeliveryParameters.NetworkDirectoryWindows
			+ "'>" 
			+ DeliveryParameters.NetworkDirectoryWindows
			+ "</a>";
		Else
			PresentationText = PresentationText 
			+ "<"
			+ DeliveryParameters.NetworkDirectoryWindows
			+ ">";
		EndIf;
		
	EndIf;
	
	If DeliveryParameters.ExecutedAtFTP Then
		
		PresentationText = PresentationText 
		+ ?(PresentationText = "", Prefix, " " + NStr("vi = 'và';
														|ru = 'и';
														|en = 'and'; fa = 'و';
														|it = 'и';
														|pl = 'and';
														|tr = 've'")) 
		+ " "
		+ NStr("vi = 'đã chuyển đến tài nguyên FTP';
				|ru = 'доставлен на FTP ресурс';
				|en = 'delivered to FTP resource'; fa = 'delivered to FTP resource';
				|it = 'consegnato nella risorsa FTP';
				|pl = 'dostarczony na FTP zasób';
				|tr = 'FTP kaynağına teslim edildi'")
		+ " ";
		
		Ref = "ftp://"
		+ DeliveryParameters.Server 
		+ ":"
		+ Format(DeliveryParameters.Port, "NZ=0; NG=0") 
		+ DeliveryParameters.Directory;
		
		If DeliveryParameters.HTMLFormatEmail Then
			PresentationText = PresentationText 
			+ "<a href = '"
			+ Ref
			+ "'>" 
			+ Ref
			+ "</a>";
		Else
			PresentationText = PresentationText 
			+ "<"
			+ Ref
			+ ">";
		EndIf;
		
	EndIf;
	
	PresentationText = PresentationText + ?(Suffix = "", ".", Suffix);
	
	Return PresentationText;
EndFunction

// Inserts the passed parameters into the template.
//
// Parameters:
//   Template - String - Initial template. For example, "Welcome, [
//   Parameters - Structure:
//      * Key - String - Parameter name. For example, "FullName".
//      * Value - Arbitrary - Substitution string. For example, "John Smith".
//
// Returns: 
//   String
//
Function FillTemplate(Template, Parameters) Export
	ParameterStart = "[";
	ParameterEnd = "]";
	StartOfFormat = "("; 
	EndOfFormat = ")"; 
	CutBorders = True; // Debug parameter
	
	Result = Template;
	For Each KeyAndValue In Parameters Do
		// Replace "[
		Result = StrReplace(
			Result,
			ParameterStart + KeyAndValue.Key + ParameterEnd, 
			?(CutBorders, "", ParameterStart) + KeyAndValue.Value + ?(CutBorders, "", ParameterEnd));
		LengthLeftFormat = StrLen(ParameterStart + KeyAndValue.Key + StartOfFormat);
		// Replace [key(format)] to value in the format.
		Position1 = StrFind(Result, ParameterStart + KeyAndValue.Key + StartOfFormat);
		While Position1 > 0 Do
			Position2 = StrFind(Result, EndOfFormat + ParameterEnd);
			If Position2 = 0 Then
				Break;
			EndIf;
			FormatString = Mid(Result, Position1 + LengthLeftFormat, Position2 - Position1 - LengthLeftFormat);
			Try
				If TypeOf(KeyAndValue.Value) = Type("StandardPeriod") Then
					ValueWithFormat = NStr("vi = '%StartDate% - %EndDate%';
											|ru = '%StartDate% - %EndDate%';
											|en = '%StartDate% - %EndDate%'; fa = '%StartDate% - %EndDate%';
											|it = '%StartDate% - %EndDate%';
											|pl = '%StartDate% - %EndDate%';
											|tr = '%StartDate% - %EndDate%'");
					ValueWithFormat = StrReplace(ValueWithFormat, "%StartDate%", Format(
						KeyAndValue.Value.StartDate, FormatString));
					ValueWithFormat = StrReplace(ValueWithFormat, "%EndDate%", Format(
						KeyAndValue.Value.EndDate, FormatString));
				Else
					ValueWithFormat = Format(KeyAndValue.Value, FormatString);
				EndIf;
				ReplacedWith = ?(CutBorders, "", ParameterStart) + ValueWithFormat + ?(CutBorders, "", ParameterEnd);
			Except
				ReplacedWith = ?(CutBorders, "", ParameterStart) + KeyAndValue.Value + ?(CutBorders, "", ParameterEnd);
			EndTry;
			Result = StrReplace(
				Result,
				ParameterStart + KeyAndValue.Key + StartOfFormat + FormatString + EndOfFormat + ParameterEnd, 
				ReplacedWith);
			Position1 = StrFind(Result, ParameterStart + KeyAndValue.Key + StartOfFormat);
		EndDo;
	EndDo;
	Return Result;
EndFunction

#EndRegion

#Region LocalUtilityProceduresAndFunctions

// In addition to generating reports, executes personalization on the list of recipients
//   and generates reports broken down by recipients (if necessary).
//
// Parameters:
//   LogParameters - Structure - Logging parameters:
//       * Prefix    - String           - Event log record prefix.
//       * Metadata - MetadataObject - Metadata to write to the Event log.
//       * Data     - Arbitrary     - Data to write to the Event log.
//   ReportParameters   - See ExecuteBulkEmail.Var_Reports
//   ReportsTree     - ValueTree   - reports and result of formation.
//   DeliveryParameters - See DeliveryParameters
//   RecipientRef  - CatalogRef - Recipient reference.
//
// Execution result is written in the ReportsTree.
// Errors are written to the log and user session messages.
//
Procedure GenerateAndSaveReport(LogParameters, ReportParameters, ReportsTree, DeliveryParameters, RecipientRef)
	
	// Determine the root row corresponding to the recipient.
	// 1 - Recipients 
	//   Key - Reference
	//   Value - Recipient's directory.
	//   Settings - Presentation of the generated reports.
	RecipientRow = DefineTreeRowForRecipient(ReportsTree, RecipientRef, DeliveryParameters);
	RecipientsDirectory = RecipientRow.Value;

	// Generate a report for the recipient.
	Result = GenerateReport(LogParameters, ReportParameters, RecipientRef);
	
	// Check the result.
	If Not Result.Generated1 Or (Result.IsEmpty And Not ReportParameters.SendIfEmpty) Then
		
		If GetFunctionalOption("RetainReportDistributionHistory")
		   And TypeOf(LogParameters.Data) = Type("CatalogRef.ReportMailings") Then
			If Result.Generated1 Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"vi = '- ""%1"" chưa gửi vì trống.';
				|ru = '- ""%1"" не был отправлен, так как пустой.';
				|en = '- ""%1"" is not sent as it is empty.'; fa = '- ""%1"" is not sent as it is empty.';
				|it = '- ""%1"" не был отправлен, так как пустой.';
				|pl = '- ""%1"" is not sent as it is empty.';
				|tr = '- ""%1"" boşmuş gibi gönderilmedi.'"), String(ReportParameters.Report));
			Else
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"vi = '- ""%1"" chưa gửi vì chưa tạo do đã chỉ ra sai tham số.';
				|ru = '- ""%1"" не был отправлен, так как не сформирован из-за некорректно указанных параметров.';
				|en = '- ""%1"" is not sent as it is not generated due to incorrect parameters.'; fa = '- ""%1"" is not sent as it is not generated due to incorrect parameters.';
				|it = '- ""%1"" не был отправлен, так как не сформирован из-за некорректно указанных параметров.';
				|pl = '- ""%1"" is not sent as it is not generated due to incorrect parameters.';
				|tr = '- ""%1""  belirtilen yanlış parametrelerin oluşturulmamaları sebebiyle gönderilmedi.'"),
				String(ReportParameters.Report));
			EndIf;
			
			If ValueIsFilled(RecipientRef) Then
				RecipientAddresses = DeliveryParameters.Recipients.Get(RecipientRef);
				If RecipientAddresses <> Undefined Then
					RecipientAddresses = CommonClientServer.ParseStringWithEmailAddresses(RecipientAddresses);
					For Each Whom In RecipientAddresses Do
						HistoryFields = ReportDistributionHistoryFields(LogParameters.Data, RecipientRef, DeliveryParameters.ExecutionDate);
						HistoryFields.Account = DeliveryParameters.Account;
						HistoryFields.EMAddress = Whom.Address;
						HistoryFields.Comment = MessageText;
						HistoryFields.Executed = False;
						HistoryFields.MethodOfObtaining = DistributionReceiptMethod(DeliveryParameters, RecipientRef, Whom.Address);
						
						InformationRegisters.ReportsDistributionHistory.CommitResultOfDistributionToRecipient(HistoryFields);
					EndDo;
				EndIf;
			Else
				For Each Recipient In DeliveryParameters.Recipients Do 
					RecipientAddresses = CommonClientServer.ParseStringWithEmailAddresses(Recipient.Value);
					For Each Whom In RecipientAddresses Do
						HistoryFields = ReportDistributionHistoryFields(LogParameters.Data, Recipient.Key, DeliveryParameters.ExecutionDate);
						HistoryFields.Account = DeliveryParameters.Account;
						HistoryFields.EMAddress = Whom.Address;
						HistoryFields.Comment = MessageText;
						HistoryFields.Executed = False;
						HistoryFields.MethodOfObtaining = DistributionReceiptMethod(DeliveryParameters, Recipient.Key, Whom.Address);
						
						InformationRegisters.ReportsDistributionHistory.CommitResultOfDistributionToRecipient(HistoryFields);
					EndDo;
				EndDo;
			EndIf;
		EndIf;

		Return;
		
	EndIf;
	
	// Register the intermediate result.
	// 2 - Recipients' spreadsheets.
	//   Key -  Report name.
	//   Value - Spreadsheet.
	//   Settings - All report parameters.
	RowReport = RecipientRow.Rows.Add();
	RowReport.Level   = 2;
	RowReport.Key      = String(ReportParameters.Report);
	RowReport.Value  = Result.TabDoc;
	RowReport.Settings = Common.CopyRecursive(ReportParameters);
	
	// Prepare a tree row to properly pass data in a long-running operation. Otherwise, the error occurs:
	// "The passed value cannot be saved to "ValueStorage".
	// The value is non-serializable or contains a non-serializable item.
	RowReport.Settings.Delete("Object");
	RowReport.Settings.Delete("DCSettingsComposer");
	If RowReport.Settings.Property("Metadata") Then
		RowReport.Settings.Metadata = RowReport.Settings.Metadata.FullName();
	EndIf;
	
	ReportPresentation = TrimAll(RowReport.Key);
	
	If DeliveryParameters.UseEmail And DeliveryParameters.ShouldInsertReportsIntoEmailBody
		And Not DeliveryParameters.ShouldAttachReports And Not DeliveryParameters.UseFolder 
		And Not DeliveryParameters.UseNetworkDirectory And Not DeliveryParameters.UseFTPResource Then
	
		ReportParametersForEmailText = ReportParametersForEmailText(RecipientsDirectory, ReportPresentation,
			ReportParameters.DescriptionTemplate, RecipientRef, RowReport.Value);
		PrepareReportForEmailText(DeliveryParameters, ReportParametersForEmailText, LogParameters);
	Else
		Period = GetPeriodFromUserSettings(ReportParameters.DCUserSettings);
		IsReportPreparedForEmailText = False;
		// Save a spreadsheet document in formats.
		FormatsPresentation = "";
		For Each Format In ReportParameters.Formats Do

			FormatParameters = DeliveryParameters.FormatsParameters.Get(Format);

			If FormatParameters = Undefined Then
				Continue;
			EndIf;

			FullFileName = FullFileNameFromTemplate(
			RecipientsDirectory, RowReport.Key, FormatParameters, DeliveryParameters,
				ReportParameters.DescriptionTemplate, Period);

			FindFreeFileName(FullFileName);

			StandardProcessing = True;
			ReportMailingOverridable.BeforeSaveSpreadsheetDocumentToFormat(
				StandardProcessing, RowReport.Value, Format, FullFileName);
		
			// Save a report with the built-in tools.
			If StandardProcessing = True Then
				ErrorTitle = NStr("vi = 'Không thể ghi lại báo cáo ''%1'' theo định dạng ''%2'':';
									|ru = 'Невозможно записать отчет ''%1'' в формате ''%2'':';
									|en = 'Cannot save report %1 as %2:'; fa = 'Cannot save report %1 as %2:';
									|it = 'Cannot save report %1 as %2:';
									|pl = 'Cannot save report %1 as %2:';
									|tr = '""%2"" formatında ""%1"" raporu kaydedilemiyor:'");

				If FormatParameters.FileType = Undefined Then
					LogRecord(LogParameters, EventLogLevel.Error,
						StringFunctionsClientServer.SubstituteParametersToString(ErrorTitle, RowReport.Key,
						FormatParameters.Name), NStr("vi = 'Định dạng không hỗ trợ.';
													|ru = 'Формат не поддерживается.';
													|en = 'Format is not supported.'; fa = 'Format is not supported.';
													|it = 'Формат не поддерживается.';
													|pl = 'Format is not supported.';
													|tr = 'Format desteklenmiyor.'"));
					Continue;
				EndIf;

				ResultDocument = RowReport.Value; // SpreadsheetDocument
				Try
					ResultDocument.Write(FullFileName, FormatParameters.FileType);
				Except
					LogRecord(LogParameters, EventLogLevel.Error,
						StringFunctionsClientServer.SubstituteParametersToString(ErrorTitle, RowReport.Key,
						FormatParameters.Name), ErrorInfo());
					Continue;
				EndTry;
			EndIf;
		
			// Checks and result registration.
			TempFile = New File(FullFileName);
			If Not TempFile.Exists() Then
				LogRecord(LogParameters, EventLogLevel.Error,
					StringFunctionsClientServer.SubstituteParametersToString(ErrorTitle + Chars.LF 
						+ NStr("vi = 'Tệp ''%3'' không tồn tại.';
								|ru = 'Файл ''%3'' не существует.';
								|en = 'File ""%3"" does not exist.'; fa = 'File ""%3"" does not exist.';
								|it = 'Il file ''%3'' non esiste.';
								|pl = 'Plik ''%3'' nie istnieje.';
								|tr = '''%3'' dosyası mevcut değil.'"), RowReport.Key, FormatParameters.Name,
					TempFile.FullName));
				Continue;
			EndIf;
		
			// Register the final result: the report saved to a temp directory.
			// 3 - Recipients' files
			//   Key - Filename
			//   Value - Full file path.
			//   Settings - File settings.
			FileRow = RowReport.Rows.Add();
			FileRow.Level = 3;
			FileRow.Key      = TempFile.Name;
			FileRow.Value  = TempFile.FullName;

			FileRow.Settings = New Structure("FileWithDirectory, FileName, FullFileName, DirectoryName, FullDirectoryName, 
				|Format, Name, Extension, FileType, Ref");

			FileRow.Settings.Format = Format;
			FillPropertyValues(FileRow.Settings, FormatParameters, "Name, Extension, FileType");

			FileRow.Settings.FileName          = TempFile.Name;
			FileRow.Settings.FullFileName    = TempFile.FullName;
			FileRow.Settings.DirectoryName       = TempFile.BaseName + "_files";
			FileRow.Settings.FullDirectoryName = TempFile.Path + FileRow.Settings.DirectoryName + GetServerPathSeparator();

			FileDirectory = New File(FileRow.Settings.FullDirectoryName);

			FileRow.Settings.FileWithDirectory = (FileDirectory.Exists() And FileDirectory.IsDirectory());

			If FileRow.Settings.FileWithDirectory And Not DeliveryParameters.Archive Then
			// Directory and the file are archived and an archive is sent instead of the file.
				ArchiveName       = TempFile.BaseName + ".zip";
				FullArchiveName = RecipientsDirectory + ArchiveName;

				SaveMode = ZIPStorePathMode.StoreRelativePath;
				ProcessingMode  = ZIPSubDirProcessingMode.ProcessRecursively;

				ZipFileWriter = New ZipFileWriter(FullArchiveName);
				ZipFileWriter.Add(FileRow.Settings.FullFileName, SaveMode, ProcessingMode);
				ZipFileWriter.Add(FileRow.Settings.FullDirectoryName, SaveMode, ProcessingMode);
				ZipFileWriter.Write();

				FileRow.Key     = ArchiveName;
				FileRow.Value = FullArchiveName;
			EndIf;

			FileDirectory = Undefined;
			TempFile = Undefined;

			FormatsPresentation = FormatsPresentation + ?(FormatsPresentation = "", "", ", ") + ?(
				DeliveryParameters.AddReferences = "ToFormats", "<a href = '" + FileRow.Value + "'>", "")
				+ FormatParameters.Name + ?(DeliveryParameters.AddReferences = "ToFormats", "</a>", "");
			
		//
			If DeliveryParameters.AddReferences = "AfterReports" Then
				ReportPresentation = ReportPresentation + Chars.LF + "<" + FileRow.Value + ">";
			EndIf;

			If DeliveryParameters.UseEmail And DeliveryParameters.ShouldInsertReportsIntoEmailBody Then
				If (DeliveryParameters.HTMLFormatEmail And Format = Enums.ReportSaveFormats.HTML)
				   Or (Not DeliveryParameters.HTMLFormatEmail And Format = Enums.ReportSaveFormats.TXT) Then
					ReportParametersForEmailText = ReportParametersForEmailText(RecipientsDirectory, ReportPresentation,
						ReportParameters.DescriptionTemplate, RecipientRef, RowReport.Value);
					PrepareReportForEmailText(DeliveryParameters, ReportParametersForEmailText,
						LogParameters, FullFileName);
					IsReportPreparedForEmailText = True;
				EndIf;
			EndIf;

		EndDo;
		
		If DeliveryParameters.UseEmail And DeliveryParameters.ShouldInsertReportsIntoEmailBody And Not IsReportPreparedForEmailText Then
			ReportParametersForEmailText = ReportParametersForEmailText(RecipientsDirectory, ReportPresentation,
				ReportParameters.DescriptionTemplate, RecipientRef, RowReport.Value);
			PrepareReportForEmailText(DeliveryParameters, ReportParametersForEmailText, LogParameters);
		EndIf;

	EndIf;
	
	// Report presentation.
	ReportPresentation = StrReplace(ReportPresentation, "[FormatsPresentation]", FormatsPresentation);
	RowReport.Settings.Insert("PresentationInEmail", ReportPresentation);
	
EndProcedure

Function ReportParametersForEmailText(RecipientsDirectory, ReportPresentation, DescriptionTemplate, Recipient, SpreadsheetDocument)
	
	ReportParameters = New Structure("RecipientsDirectory, ReportPresentation, DescriptionTemplate, Recipient, SpreadsheetDocument");
	ReportParameters.RecipientsDirectory = RecipientsDirectory;
	ReportParameters.ReportPresentation = ReportPresentation;
	ReportParameters.DescriptionTemplate = DescriptionTemplate;
	ReportParameters.Recipient = Recipient;
	ReportParameters.SpreadsheetDocument = SpreadsheetDocument;
	
	Return ReportParameters;
	
EndFunction

Procedure PrepareReportForEmailText(DeliveryParameters, ReportParameters, LogParameters, FullFileName = Undefined)

	If FullFileName = Undefined Then
		FullFileName = PathToTempReportFileForEmailText(DeliveryParameters, ReportParameters, LogParameters);
	EndIf;

	MapKey = ?(ReportParameters.Recipient = Undefined, "Key", ReportParameters.Recipient);
	ReportsForText = DeliveryParameters.ReportsForEmailText.Get(MapKey);
	If ReportsForText = Undefined Then
		FileStructure = New Structure("FullFileName, Presentation", FullFileName, ReportParameters.ReportPresentation);
		ReportsForText = New Array;
		ReportsForText.Add(FileStructure);
		DeliveryParameters.ReportsForEmailText.Insert(MapKey, ReportsForText);
	Else
		FileStructure = New Structure("FullFileName, Presentation", FullFileName, ReportParameters.ReportPresentation);
		ReportsForText.Add(FileStructure);
	EndIf;

EndProcedure

Function PathToTempReportFileForEmailText(DeliveryParameters, ReportParameters, LogParameters)

	Format = ?(DeliveryParameters.HTMLFormatEmail, Enums.ReportSaveFormats.HTML,
		Enums.ReportSaveFormats.TXT);

	FormatParameters = DeliveryParameters.FormatsParameters.Get(Format);
	If FormatParameters = Undefined Then
		Return Undefined;
	EndIf;

	FullFileName = FullFileNameFromTemplate(ReportParameters.RecipientsDirectory, ReportParameters.ReportPresentation,
		FormatParameters, DeliveryParameters, ReportParameters.DescriptionTemplate, Undefined);

	FindFreeFileName(FullFileName);
	ErrorTitle = NStr("vi = 'Không thể ghi lại báo cáo ''%1'' theo định dạng ''%2'':';
						|ru = 'Невозможно записать отчет ''%1'' в формате ''%2'':';
						|en = 'Cannot save report %1 as %2:'; fa = 'Cannot save report %1 as %2:';
						|it = 'Cannot save report %1 as %2:';
						|pl = 'Cannot save report %1 as %2:';
						|tr = '""%2"" formatında ""%1"" raporu kaydedilemiyor:'");
	If FormatParameters.FileType = Undefined Then
		LogRecord(LogParameters, EventLogLevel.Error,
			StringFunctionsClientServer.SubstituteParametersToString(ErrorTitle, ReportParameters.ReportPresentation,
			FormatParameters.Name), NStr("vi = 'Định dạng không được hỗ trợ.';
										|ru = 'Формат не поддерживается.';
										|en = 'Format is not supported.'; fa = 'Format is not supported.';
										|it = 'Формат не поддерживается.';
										|pl = 'Format is not supported.';
										|tr = 'Format desteklenmiyor.'"));
		Return Undefined;
	EndIf;

	Try
		ReportParameters.SpreadsheetDocument.Write(FullFileName, FormatParameters.FileType);
	Except
		LogRecord(LogParameters, EventLogLevel.Error,
			StringFunctionsClientServer.SubstituteParametersToString(ErrorTitle, ReportParameters.ReportPresentation,
			FormatParameters.Name), ErrorInfo());
		Return Undefined;
	EndTry;

	Return FullFileName;

EndFunction

// Auxiliary procedure for the ExecuteMailing function, which populates the parameters with the default values 
// (unless they are passed explicitly).
// Prepares and populates distribution parameters.
//
// Parameters and the return value:
//   See ExecuteBulkEmail.
//
Function CheckAndFillExecutionParameters(ReportsTable, DeliveryParameters, MailingDescription, LogParameters)
	// Parameters of the writing to the Event log.
	If TypeOf(LogParameters) <> Type("Structure") Then
		LogParameters = New Structure;
	EndIf;
	If Not LogParameters.Property("EventName") Then
		LogParameters.Insert("EventName", NStr("vi = 'Gửi báo cáo. Khởi động theo yêu cầu';
												|ru = 'Рассылка отчетов. Запуск по требованию';
												|en = 'Report distribution. Manual start'; fa = 'Report distribution. Manual start';
												|it = 'Invio massivo dei report. Avvio su richiesta';
												|pl = 'Wysyłanie raportów. Uruchamianie na żądanie';
												|tr = 'Rapor bülteni. Talep üzerine başlat'", Common.DefaultLanguageCode()));
	EndIf;
	If Not LogParameters.Property("Data") Then
		LogParameters.Insert("Data", MailingDescription);
	EndIf;
	If Not LogParameters.Property("Metadata") Then
		LogParameters.Insert("Metadata", Undefined);
		DataType = TypeOf(LogParameters.Data);
		If DataType <> Type("Structure") And Common.IsReference(DataType) Then
			LogParameters.Metadata = LogParameters.Data.Metadata();
		EndIf;
	EndIf;
	
	// Check access rights.
	If Not OutputRight(LogParameters) Then
		Return False;
	EndIf;
	
	ReportsAvailability = ReportsOptions.ReportsAvailability(ReportsTable.UnloadColumn("Report"));
	Unavailable2 = ReportsAvailability.Copy(New Structure("Available", False));
	If Unavailable2.Count() > 0 Then
		LogRecord(LogParameters, EventLogLevel.Error,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Trong giao dịch gửi hàng loạt có các báo cáo không hợp lệ (%1):%2';
																			|ru = 'В рассылке есть недоступные отчеты (%1):%2';
																			|en = 'Report distribution contains unavailable reports (%1):%2'; fa = 'Report distribution contains unavailable reports (%1):%2';
																			|it = 'Nella email massive vi sono dei report non accessibili (%1):%2';
																			|pl = 'W wysyłce są niedostępne raporty (%1):%2';
																			|tr = 'Bültende kullanılamaz raporlar mevcut (%1):%2'"),
			Unavailable2.Count(),
			Chars.LF + Chars.Tab + StrConcat(Unavailable2.UnloadColumn("Presentation"), Chars.LF + Chars.Tab)));
		Return False;
	EndIf;
	
	DeliveryParameters.BulkEmail = TrimAll(String(MailingDescription));
	DeliveryParameters.ExecutionDate = CurrentSessionDate();
	DeliveryParameters.HadErrors = False;
	DeliveryParameters.HasWarnings = False;
	DeliveryParameters.ExecutedToFolder = False;
	DeliveryParameters.ExecutedToNetworkDirectory = False;
	DeliveryParameters.ExecutedAtFTP = False;
	DeliveryParameters.ExecutedByEmail = False;
	DeliveryParameters.ExecutedPublicationMethods = "";
	
	If DeliveryParameters.UseFolder Then
		If Not ValueIsFilled(DeliveryParameters.Folder) Then
			DeliveryParameters.UseFolder = False;
			LogRecord(LogParameters, EventLogLevel.Warning,
				NStr("vi = 'Chưa điền thư mục, đã hủy gửi vào thư mục.';
					|ru = 'Папка не заполнена, доставка в папку отключена.';
					|en = 'Directory not specified. Delivery to directory is disabled.'; fa = 'Directory not specified. Delivery to directory is disabled.';
					|it = 'Папка не заполнена, доставка в папку отключена.';
					|pl = 'Directory not specified. Delivery to directory is disabled.';
					|tr = 'Klasör doldurulmadı, klasöre teslim devre dışı bırakıldı.'"));
		Else
			If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
				ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
				AccessRight = ModuleFilesOperationsInternal.RightToAddFilesToFolder(DeliveryParameters.Folder);
			Else
				AccessRight = True;
			EndIf;
			If Not AccessRight Then
				SetPrivilegedMode(True);
				FoldersPresentation = String(DeliveryParameters.Folder);
				SetPrivilegedMode(False);
				LogRecord(LogParameters, EventLogLevel.Error,
					StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không đủ quyền để tạo tệp trong thư mục ""%1"".';
																					|ru = 'Недостаточно прав для создания файлов в папке ""%1"".';
																					|en = 'Insufficient rights to create files in directory ""%1"".'; fa = 'Insufficient rights to create files in directory ""%1"".';
																					|it = 'Diritti insufficienti per creare i file nella cartella ""%1"".';
																					|pl = 'Nie masz wystarczających uprawnień do tworzenia plików w folderze ""%1"".';
																					|tr = '''''%1'''' klasöründe dosya oluşturmak için yetkiniz yok.'"),
					FoldersPresentation));
				Return False;
			EndIf;
		EndIf;
	EndIf;
	
	If DeliveryParameters.UseNetworkDirectory Then
		If Not ValueIsFilled(DeliveryParameters.NetworkDirectoryWindows) 
			Or Not ValueIsFilled(DeliveryParameters.NetworkDirectoryLinux) Then
			
			If ValueIsFilled(DeliveryParameters.NetworkDirectoryWindows) Then
				SubstitutionValue = NStr("vi = 'Linux';
										|ru = 'Linux';
										|en = 'Linux'; fa = 'Linux';
										|it = 'Linux';
										|pl = 'Linux';
										|tr = 'Linux'");
			ElsIf ValueIsFilled(DeliveryParameters.NetworkDirectoryLinux) Then
				SubstitutionValue = NStr("vi = 'Windows';
										|ru = 'Windows';
										|en = 'Windows'; fa = 'Windows';
										|it = 'Windows';
										|pl = 'Windows';
										|tr = 'Windows'");
			Else
				SubstitutionValue = NStr("vi = 'Windows và Linux';
										|ru = 'Windows и Linux';
										|en = 'Windows and Linux'; fa = 'Windows and Linux';
										|it = 'Windows e Linux';
										|pl = 'Windows i Linux';
										|tr = 'Windows ve Linux'");
			EndIf;
			
			DeliveryParameters.UseNetworkDirectory = False;
			LogRecord(LogParameters, EventLogLevel.Error,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chưa chọn thư mục mạng %1, đã hủy gửi vào thư mục mạng.';
																				|ru = 'Сетевой каталог %1 не выбран, доставка в сетевой каталог отключена.';
																				|en = 'Network directory %1 not selected. Delivery to network directory is disabled.'; fa = 'Network directory %1 not selected. Delivery to network directory is disabled.';
																				|it = 'Сетевой каталог %1 не выбран, доставка в сетевой каталог отключена.';
																				|pl = 'Network directory %1 not selected. Delivery to network directory is disabled.';
																				|tr = '%1 dijital kataloğu seçilmedi, dijital kataloğa teslim devre dışı bırakıldı.'"),
				SubstitutionValue));
			
		Else
			
			DeliveryParameters.NetworkDirectoryWindows = CommonClientServer.AddLastPathSeparator(
				DeliveryParameters.NetworkDirectoryWindows);
			DeliveryParameters.NetworkDirectoryLinux = CommonClientServer.AddLastPathSeparator(
				DeliveryParameters.NetworkDirectoryLinux);
			
		EndIf;
	EndIf;
	
	If DeliveryParameters.UseFTPResource And Not ValueIsFilled(DeliveryParameters.Server) Then
		DeliveryParameters.UseFTPResource = False;
		LogRecord(LogParameters, EventLogLevel.Error,
			NStr("vi = 'Chưa điền máy chủ FTP, đã hủy gửi đến thư mục trên nguồn FTP.';
				|ru = 'FTP сервер не заполнен, доставка в папку на FTP ресурс отключена.';
				|en = 'FTP server not specified. Delivery to FTP directory is disabled.'; fa = 'FTP server not specified. Delivery to FTP directory is disabled.';
				|it = 'FTP сервер не заполнен, доставка в папку на FTP ресурс отключена.';
				|pl = 'FTP server not specified. Delivery to FTP directory is disabled.';
				|tr = 'FTP sunucusu doldurulmadı, FTP kaynağındaki klasöre teslim devre dışı bırakıldı.'"));
	EndIf;
	
	If DeliveryParameters.UseEmail And Not ValueIsFilled(DeliveryParameters.Account) Then
		DeliveryParameters.UseEmail = False;
		LogRecord(LogParameters, EventLogLevel.Error,
			NStr("vi = 'Chưa chọn email, đã tắt sử dụng gửi qua email.';
				|ru = 'Почта не выбрана, доставка по электронной почте отключена.';
				|en = 'Email account is not selected. Email delivery is disabled.'; fa = 'Email account is not selected. Email delivery is disabled.';
				|it = 'Почта не выбрана, доставка по электронной почте отключена.';
				|pl = 'Email account is not selected. Email delivery is disabled.';
				|tr = 'Posta seçilmedi, e-posta dağıtımı devre dışı bırakıldı.'"));
	EndIf;
	
	If DeliveryParameters.Personalized Then
		If Not DeliveryParameters.UseEmail Then
			LogRecord(LogParameters, EventLogLevel.Error,
				NStr("vi = 'Chỉ có thể gửi cá nhân hóa hàng loạt qua email.';
					|ru = 'Персонализированная рассылка может быть отправлена только по электронной почте.';
					|en = 'Individual reports can be distributed via email only.'; fa = 'Individual reports can be distributed via email only.';
					|it = 'Персонализированная рассылка может быть отправлена только по электронной почте.';
					|pl = 'Individual reports can be distributed via email only.';
					|tr = 'Kişiselleştirilmiş bülten yalnızca e-posta ile gönderilebilir.'"));
			Return False;
		EndIf;
		
		DeliveryParameters.UseFolder = False;
		DeliveryParameters.UseNetworkDirectory = False;
		DeliveryParameters.UseFTPResource = False;
		DeliveryParameters.NotifyOnly = False;
	EndIf;
	
	If DeliveryParameters.UseEmail Then
		If DeliveryParameters.NotifyOnly
			And Not DeliveryParameters.UseFolder
			And Not DeliveryParameters.UseNetworkDirectory
			And Not DeliveryParameters.UseFTPResource Then
			LogRecord(LogParameters, EventLogLevel.Warning,
				NStr("vi = 'Chỉ có thể sử dụng thông báo qua email chung với các phương thức gửi khác.';
					|ru = 'Использование уведомлений по электронной почте возможно только совместно с другими способами доставки.';
					|en = 'Email notifications are available only with other delivery methods.'; fa = 'Email notifications are available only with other delivery methods.';
					|it = 'Использование уведомлений по электронной почте возможно только совместно с другими способами доставки.';
					|pl = 'Email notifications are available only with other delivery methods.';
					|tr = 'E-posta bildirimlerinin kullanımı sadece diğer teslim yöntemleriyle birlikte mümkündür.'"));
			Return False;
		EndIf;
		
		EmailParameters = DeliveryParameters.EmailParameters;
		
		// Internet mail text type.
		If Not ValueIsFilled(EmailParameters.TextType) Then
			EmailParameters.TextType = InternetMailTextType.PlainText;
		EndIf;
		
		DeliveryParameters.HTMLFormatEmail = EmailParameters.TextType = "HTML"
			Or EmailParameters.TextType = InternetMailTextType.HTML;
		
		// For backward compatibility purposes.
		If EmailParameters.Attachments.Count() > 0 Then
			DeliveryParameters.Images = EmailParameters.Attachments;
		EndIf;
		
		// Message template.
		If Not ValueIsFilled(DeliveryParameters.TextTemplate1) Then
			DeliveryParameters.TextTemplate1 = TextTemplate1();
			If DeliveryParameters.HTMLFormatEmail Then
				Document = New FormattedDocument;
				Document.Add(DeliveryParameters.TextTemplate1, FormattedDocumentItemType.Text);
				Document.GetHTML(DeliveryParameters.TextTemplate1, New Structure);
			EndIf;
		EndIf;
		
		// Delete unnecessary style elements.
		If DeliveryParameters.HTMLFormatEmail Then
			StyleLeft = StrFind(DeliveryParameters.TextTemplate1, "<style");
			StyleRight = StrFind(DeliveryParameters.TextTemplate1, "</style>");
			If StyleLeft > 0 And StyleRight > StyleLeft Then
				DeliveryParameters.TextTemplate1 = Left(DeliveryParameters.TextTemplate1, StyleLeft - 1) + Mid(DeliveryParameters.TextTemplate1, StyleRight + 8);
			EndIf;
		EndIf;
		
		// Value content for the substitution.
		TemplateFillingStructure = New Structure("MailingDescription, Author, SystemTitle, ExecutionDate");
		TemplateFillingStructure.MailingDescription = DeliveryParameters.BulkEmail;
		TemplateFillingStructure.Author                = DeliveryParameters.Author;
		TemplateFillingStructure.SystemTitle     = ThisInfobaseName();
		TemplateFillingStructure.ExecutionDate       = DeliveryParameters.ExecutionDate;
		If Not DeliveryParameters.Personalized Then
			TemplateFillingStructure.Insert("Recipient", "");
		EndIf;
		
		// Subject template.
		DeliveryParameters.SubjectTemplate = FillTemplate(DeliveryParameters.SubjectTemplate, TemplateFillingStructure);
		
		// Message template.
		DeliveryParameters.TextTemplate1 = FillTemplate(DeliveryParameters.TextTemplate1, TemplateFillingStructure);
		
		// Flags that show whether it is necessary to fill in the templates (checks cache).
		DeliveryParameters.FillRecipientInSubjectTemplate =
			StrFind(DeliveryParameters.SubjectTemplate, "[Recipient]") <> 0;
		DeliveryParameters.FillRecipientInMessageTemplate =
			StrFind(DeliveryParameters.TextTemplate1, "[Recipient]") <> 0;
		DeliveryParameters.FillGeneratedReportsInMessageTemplate =
			StrFind(DeliveryParameters.TextTemplate1, "[GeneratedReports]") <> 0;
		DeliveryParameters.FillDeliveryMethodInMessageTemplate =
			StrFind(DeliveryParameters.TextTemplate1, "[DeliveryMethod]") <> 0;
	EndIf;
	
	// Archive name (delete forbidden characters, fill a template) and extension.
	If DeliveryParameters.Archive Then
		Structure = New Structure("MailingDescription, ExecutionDate", DeliveryParameters.BulkEmail, CurrentSessionDate());
		ArchiveName = FillTemplate(DeliveryParameters.ArchiveName, Structure);
		DeliveryParameters.ArchiveName = ConvertFileName(ArchiveName, DeliveryParameters.TransliterateFileNames);
		If Lower(Right(DeliveryParameters.ArchiveName, 4)) <> ".zip" Then
			DeliveryParameters.ArchiveName = DeliveryParameters.ArchiveName +".zip";
		EndIf;
	EndIf;
	
	// Formats parameters.
	For Each MetadataFormat In Metadata.Enums.ReportSaveFormats.EnumValues Do
		Format = Enums.ReportSaveFormats[MetadataFormat.Name];
		FormatParameters = WriteSpreadsheetDocumentToFormatParameters(Format);
		FormatParameters.Insert("Name", MetadataFormat.Name);
		DeliveryParameters.FormatsParameters.Insert(Format, FormatParameters);
	EndDo;
	
	// Parameters for adding links to the final files to the message.
	If DeliveryParameters.UseEmail 
		And (DeliveryParameters.UseFolder
			Or DeliveryParameters.UseNetworkDirectory
			Or DeliveryParameters.UseFTPResource)
		And DeliveryParameters.FillGeneratedReportsInMessageTemplate Then
		
		If DeliveryParameters.Archive Then
			DeliveryParameters.AddReferences = "ToArchive";
		ElsIf DeliveryParameters.HTMLFormatEmail Then
			DeliveryParameters.AddReferences = "ToFormats";
		Else
			DeliveryParameters.AddReferences = "AfterReports";
		EndIf;
	EndIf;
	
	Return True;
EndFunction

// Generates the mailing list from the recipients list, prepares all email parameters, 
//   and passes control to the EmailOperations subsystem.
//   To monitor the fulfillment, use the Try… Except construct.
//
// Parameters:
//   Attachments - Map of KeyAndValue:
//     * Key     - String - file name
//     * Value - String - Full filename
//   DeliveryParameters - See ExecuteBulkEmail.DeliveryParameters
//   LogParameters  - See LogParameters
//   RecipientRow  - Recipient settings:
//       - Undefined - Use the entire recipient list from DeliveryParameters.Recipients.
//       - ValueTreeRow - Use the Recipient row property.
//
Procedure SendReportsToRecipient(Attachments, DeliveryParameters, LogParameters, RecipientRow = Undefined)
	Recipient = ?(RecipientRow = Undefined, Undefined, RecipientRow.Key);
	EmailParameters = DeliveryParameters.EmailParameters;
	
	DeliveryParameters.Recipient = Recipient;
	
	// Attachments are reports.
	EmailParameters.Attachments = ConvertToMap(Attachments, "Key", "Value");
	
	// Subject and body templates
	SubjectTemplate = DeliveryParameters.SubjectTemplate;
	TextTemplate1 = DeliveryParameters.TextTemplate1;
	
	// Insert generated reports into the message template.
	If DeliveryParameters.FillGeneratedReportsInMessageTemplate Then
		If DeliveryParameters.HTMLFormatEmail Then
			DeliveryParameters.RecipientReportsPresentation = StrReplace(
				DeliveryParameters.RecipientReportsPresentation,
				Chars.LF,
				Chars.LF + "<br>");
		EndIf;
		TextTemplate1 = StrReplace(TextTemplate1, "[GeneratedReports]", DeliveryParameters.RecipientReportsPresentation);
	EndIf;
	
	// Delivery method is filled earlier (outside this procedure).
	If DeliveryParameters.FillDeliveryMethodInMessageTemplate Then
		TextTemplate1 = StrReplace(TextTemplate1, "[DeliveryMethod]", DeliveryMethodsPresentation(DeliveryParameters));
	EndIf;
	
	// Subject and body of the message
	EmailParameters.Subject = SubjectTemplate;
	EmailParameters.Body = TextTemplate1;
	
	// Subject and body of the message
	DeliveryAddressKey = ?(DeliveryParameters.BCCs, "BCCs", "Whom");
	
	If DeliveryParameters.Personal Then
		BulkEmailType = "Personal";
	ElsIf DeliveryParameters.Personalized Then
		BulkEmailType = "Personalized";
	Else
		BulkEmailType = "Shared3";
	EndIf;
	AdditionalTextParameters = New Structure;
	ReportMailingOverridable.OnDefineEmailTextParameters(BulkEmailType,
		DeliveryParameters.MailingRecipientType, AdditionalTextParameters);
	ReportMailingOverridable.OnReceiveEmailTextParameters(BulkEmailType,
		DeliveryParameters.MailingRecipientType, Recipient, AdditionalTextParameters);
	For Each KeyAndValue In AdditionalTextParameters Do
		Parameter = "[" + KeyAndValue.Key + "]";
		EmailParameters.Subject = StrReplace(EmailParameters.Subject, Parameter, String(KeyAndValue.Value));
		EmailParameters.Body = StrReplace(EmailParameters.Body, Parameter, String(KeyAndValue.Value));
	EndDo;
	
	// Report embedded in the email body
	If DeliveryParameters.ShouldInsertReportsIntoEmailBody Then
		TextOfAllReports = "";
		MapKey = ?(Recipient = Undefined, "Key", Recipient);
		ReportsForText = DeliveryParameters.ReportsForEmailText.Get(MapKey);
		If ReportsForText <> Undefined And ReportsForText.Count() > 0 Then
			ReportCounter = 0;
			PictureCounter = 0;
			For Each Report In ReportsForText Do
				ReportCounter = ReportCounter + 1;
				Text = New TextDocument;
				Text.Read(Report.FullFileName);
				ReportText = Text.GetText();
				If DeliveryParameters.HTMLFormatEmail Then
					// Possible pictures included in the report.
					If PictureCounter <= 150 Then

						CharCountWithoutExtension = StrFind(Report.FullFileName, ".html",
							SearchDirection.FromEnd);
						CharCountWithoutExtension = ?(CharCountWithoutExtension > 0,
							CharCountWithoutExtension - 1, CharCountWithoutExtension);
						FullNameOfPictureDirectory = Left(Report.FullFileName, CharCountWithoutExtension) + "_files";
						PicturesDirectory = New File(FullNameOfPictureDirectory);
						If PicturesDirectory.Exists() And PicturesDirectory.IsDirectory() Then
							DirectoryName = PicturesDirectory.BaseName;
							PicturesFiles = FindFiles(FullNameOfPictureDirectory, GetAllFilesMask());
							For Each PicturesFile In PicturesFiles Do
								If PictureCounter > 150 Then
									Break;
								EndIf;
								PictureCounter = PictureCounter + 1;
								NewPictureName = PicturesFile.BaseName + "Report" + ReportCounter;
								ReportText = StrReplace(ReportText, DirectoryName + "/" + PicturesFile.Name,
									NewPictureName);
								DeliveryParameters.Images.Insert(NewPictureName,
									New Picture(PicturesFile.FullName));
							EndDo;
						EndIf;
					EndIf;
					TextOfAllReports = TextOfAllReports + Chars.LF + "<br>" + "<br>" + ReportText;
				Else
					TextOfAllReports = TextOfAllReports + Chars.LF + Chars.LF + Chars.LF
						+ "------------------------------------------" + Chars.LF + ReportText;
				EndIf;
			EndDo;
			EmailParameters.Body = EmailParameters.Body + Chars.LF + TextOfAllReports;
		ElsIf DeliveryParameters.EmailParameters.Attachments.Count() = 0 Then
			Return;
		EndIf;
	EndIf;
	
	If Recipient = Undefined Then
		If DeliveryParameters.Recipients.Count() = 0 Then
			Return;
		EndIf;
		
		// Templates are not personalized - glue recipients email addresses and joint delivery.
		Whom = "";
		For Each KeyAndValue In DeliveryParameters.Recipients Do
			Whom = Whom + ?(Whom = "", "", ", ") + KeyAndValue.Value;
		EndDo;

		EmailParameters.Insert(DeliveryAddressKey, Whom);
			
		// Send email.
		SendEmailMessage(DeliveryParameters, EmailParameters, RecipientRow, LogParameters);
	Else
		// Deliver to a specific recipient.
		
		// Subject and body of the message
		If DeliveryParameters.FillRecipientInSubjectTemplate Then
			EmailParameters.Subject = StrReplace(EmailParameters.Subject, "[Recipient]", String(Recipient));
		EndIf;
		If DeliveryParameters.FillRecipientInMessageTemplate Then
			EmailParameters.Body = StrReplace(EmailParameters.Body, "[Recipient]", String(Recipient));
		EndIf;
		
		// Recipient.
		EmailParameters.Insert(DeliveryAddressKey, DeliveryParameters.Recipients[Recipient]);
		
		// Send email.
		SendEmailMessage(DeliveryParameters, EmailParameters, RecipientRow, LogParameters);
	EndIf;  
			
EndProcedure

Procedure SendEmailMessage(DeliveryParameters, EmailParameters, RecipientRow, LogParameters)
	
	If Not TypeOf(EmailParameters.Importance) = Type("InternetMailMessageImportance") Then
		EmailParameters.Importance = InternetMailMessageImportance.Normal	
	EndIf;	
	
	If EmailClientUsed() And GetFunctionalOption("RetainReportDistributionHistory") Then
		SendEmailMessageInteraction(DeliveryParameters, EmailParameters, RecipientRow, LogParameters);
		Return;
	EndIf;	

	MailMessage = PrepareEmail(DeliveryParameters, EmailParameters);
	SendingResult = EmailOperations.SendMail(DeliveryParameters.Account, MailMessage);   
	
	If Not GetFunctionalOption("RetainReportDistributionHistory")
		Or TypeOf(LogParameters.Data) <> Type("CatalogRef.ReportMailings") Then
		Return;
	EndIf;

	AdditionalParameters = AdditionalDistributionResultParameters(DeliveryParameters, RecipientRow, False);
	
	If DeliveryParameters.Recipient <> Undefined Then
		If DeliveryParameters.BCCs Then
			RecipientAddresses = ?(TypeOf(EmailParameters.BCCs) = Type("String"),
			CommonClientServer.ParseStringWithEmailAddresses(EmailParameters.BCCs), 
				EmailParameters.BCCs);
		Else
			RecipientAddresses = ?(TypeOf(EmailParameters.Whom) = Type("String"),
			CommonClientServer.ParseStringWithEmailAddresses(EmailParameters.Whom), EmailParameters.Whom);
		EndIf;
		
		RecordEmailDistributionResult(DeliveryParameters, LogParameters,
			DeliveryParameters.Recipient, RecipientAddresses, SendingResult, AdditionalParameters);
		
	ElsIf DeliveryParameters.Recipients <> Undefined Then
		For Each Recipient In DeliveryParameters.Recipients Do
			RecipientAddresses = CommonClientServer.ParseStringWithEmailAddresses(Recipient.Value);

			RecordEmailDistributionResult(DeliveryParameters, LogParameters,
				Recipient.Key, RecipientAddresses, SendingResult, AdditionalParameters);
		EndDo;
	EndIf;

EndProcedure
	
Procedure SendEmailMessageInteraction(DeliveryParameters, EmailParameters, RecipientRow, LogParameters)

	ModuleInteractions = Common.CommonModule("Interactions");
	Message = MessageParametersForInteractionSystem(DeliveryParameters, EmailParameters);

	SendingResult = ModuleInteractions.CreateEmail(Message, DeliveryParameters.Account, True);
	If TypeOf(LogParameters.Data) <> Type("CatalogRef.ReportMailings")Then
		Return;
	EndIf;
	
	If SendingResult.Sent Then
		
		AdditionalParameters = AdditionalDistributionResultParameters(DeliveryParameters, RecipientRow, True);

		If DeliveryParameters.Recipient <> Undefined Then
			If DeliveryParameters.BCCs Then
				RecipientAddresses = ?(TypeOf(EmailParameters.BCCs) = Type("String"),
					CommonClientServer.ParseStringWithEmailAddresses(EmailParameters.BCCs), 
						EmailParameters.BCCs);
			Else
				RecipientAddresses = ?(TypeOf(EmailParameters.Whom) = Type("String"),
					CommonClientServer.ParseStringWithEmailAddresses(EmailParameters.Whom), EmailParameters.Whom);
			EndIf;
			RecordEmailDistributionResult(DeliveryParameters, LogParameters,
				DeliveryParameters.Recipient, RecipientAddresses, SendingResult, AdditionalParameters);
			
		ElsIf DeliveryParameters.Recipients <> Undefined Then
			For Each Recipient In DeliveryParameters.Recipients Do
				RecipientAddresses = CommonClientServer.ParseStringWithEmailAddresses(Recipient.Value);

				RecordEmailDistributionResult(DeliveryParameters, LogParameters,
					Recipient.Key, RecipientAddresses, SendingResult, AdditionalParameters);
			EndDo;
		EndIf;
		Return;
	EndIf;

	If DeliveryParameters.Recipient <> Undefined Then
		RecipientAddresses = CommonClientServer.ParseStringWithEmailAddresses(EmailParameters.Whom);
		RecordUnsuccessfulDistributionResult(DeliveryParameters, LogParameters, DeliveryParameters.Recipient,
			RecipientAddresses, SendingResult);
	Else
		For Each Recipient In DeliveryParameters.Recipients Do
			RecipientAddresses = CommonClientServer.ParseStringWithEmailAddresses(Recipient.Value);
			RecordUnsuccessfulDistributionResult(DeliveryParameters, LogParameters, Recipient.Key,
				RecipientAddresses, SendingResult);
		EndDo;
	EndIf;

	Raise SendingResult.ErrorDescription;

EndProcedure

Function AdditionalDistributionResultParameters(DeliveryParameters, RecipientRow, EmailClientUsed)
	
	If ValueIsFilled(DeliveryParameters.Account) Then
			SenderSRepresentation = String(DeliveryParameters.Account);
			SendHiddenCopiesToSender = Common.ObjectAttributeValue(
				DeliveryParameters.Account, "SendBCCToThisAddress");
		Else
			SenderSRepresentation = "";
			SendHiddenCopiesToSender = False;
		EndIf;

		AdditionalInformation = "";
		If SendHiddenCopiesToSender Then
			AdditionalInformation = NStr("vi = 'Đã gửi bản sao cho người gửi.';
										|ru = 'Копия направлена отправителю.';
										|en = 'A copy was sent to the sender.'; fa = 'A copy was sent to the sender.';
										|it = 'Copia inviata al mittente.';
										|pl = 'Kopia została wysłana nadawcy.';
										|tr = 'Kopya göndericiye gönderildi.'");
		EndIf;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("SenderSRepresentation", SenderSRepresentation);
		AdditionalParameters.Insert("AdditionalInformation", AdditionalInformation);
		AdditionalParameters.Insert("RecipientRow", RecipientRow);
		AdditionalParameters.Insert("EmailClientUsed", EmailClientUsed);
		
		Return AdditionalParameters;
	
EndFunction

Procedure RecordEmailDistributionResult(DeliveryParameters, LogParameters, Recipient, 
	RecipientAddresses, SendingResult, AdditionalParameters)
	
	For Each Whom In RecipientAddresses Do
		
		RecipientPresentation1 = String(Recipient) + " (" + Whom.Address + ")";
		
		If DeliveryParameters.NotifyOnly Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã gửi thông báo ''%1'' từ %2. %3';
				|ru = 'Уведомления отправлены ''%1'' от %2. %3';
				|en = 'Notifications are sent from %2 to %1. %3'; fa = 'Notifications are sent from %2 to %1. %3';
				|it = 'Уведомления отправлены ''%1'' от %2. %3';
				|pl = 'Notifications are sent from %2 to %1. %3';
				|tr = '%2 üzerinden ''%1'' bildirim gönderildi. %3'"), RecipientPresentation1,
			AdditionalParameters.SenderSRepresentation, AdditionalParameters.AdditionalInformation);
		Else
			MessageText = TestOfSuccessfulReportDistribution(DeliveryParameters, 
				AdditionalParameters.RecipientRow, RecipientPresentation1,
				AdditionalParameters.SenderSRepresentation, AdditionalParameters.AdditionalInformation);
		EndIf;
		
		HistoryFields = ReportDistributionHistoryFields(LogParameters.Data, Recipient, 
		DeliveryParameters.ExecutionDate); 
		HistoryFields.Account = DeliveryParameters.Account;
		HistoryFields.EMAddress = Whom.Address;
		RecipientErrorText = SendingResult.WrongRecipients.Get(Whom.Address);
		If RecipientErrorText <> Undefined Then
			HistoryFields.Comment = RecipientErrorText;
			HistoryFields.Executed = False;
		Else
			HistoryFields.Comment = MessageText;
			HistoryFields.Executed = True;
		EndIf;
		HistoryFields.MethodOfObtaining = DistributionReceiptMethod(DeliveryParameters, Recipient, Whom.Address); 
		If AdditionalParameters.EmailClientUsed Then
			HistoryFields.OutgoingEmail = SendingResult.LinkToTheEmail;
			HistoryFields.EmailID = SendingResult.EmailID;
		Else
			HistoryFields.EmailID = SendingResult.SMTPEmailID;
		EndIf;
		
		InformationRegisters.ReportsDistributionHistory.CommitResultOfDistributionToRecipient(HistoryFields);
	EndDo;
	
EndProcedure

Procedure RecordUnsuccessfulDistributionResult(DeliveryParameters, LogParameters, Recipient, 
	RecipientAddresses, SendingResult)
	
	For Each Whom In RecipientAddresses Do
			
		HistoryFields = ReportDistributionHistoryFields(LogParameters.Data, Recipient, DeliveryParameters.ExecutionDate);
		HistoryFields.Account = DeliveryParameters.Account;
		HistoryFields.EMAddress = Whom.Address;
		HistoryFields.Executed = False;
		HistoryFields.MethodOfObtaining = DistributionReceiptMethod(DeliveryParameters, Recipient, Whom.Address);
		If TypeOf(SendingResult) = Type("String") Then
			HistoryFields.Comment = SendingResult;
		Else
			HistoryFields.Comment = SendingResult.ErrorDescription;
			HistoryFields.OutgoingEmail = SendingResult.LinkToTheEmail;
			HistoryFields.EmailID = SendingResult.EmailID;
		EndIf;				
		InformationRegisters.ReportsDistributionHistory.CommitResultOfDistributionToRecipient(HistoryFields);
	EndDo;
	
EndProcedure

Function MessageParametersForInteractionSystem(DeliveryParameters, EmailParameters)

	ModuleInteractions = Common.CommonModule("Interactions");
	Message = ModuleInteractions.EmailParameters();
	Message.Subject  = EmailParameters.Subject;
	Message.Text = EmailParameters.Body;
	Message.Importance = EmailParameters.Importance;
	Message.AdditionalParameters.RequestDeliveryReceipt = EmailParameters.RequestDeliveryReceipt;  
	Message.AdditionalParameters.RequestReadReceipt = EmailParameters.RequestReadReceipt;

	If EmailParameters.TextType = "PlainText" Or EmailParameters.TextType = InternetMailTextType.PlainText Then
		Message.AdditionalParameters.EmailFormat1 = Enums.EmailEditingMethods.NormalText;
	Else
		Message.AdditionalParameters.EmailFormat1 = Enums.EmailEditingMethods.HTML;
	EndIf;
	
	If ValueIsFilled(DeliveryParameters.Recipient) Then
		RecipientPresentation1 = String(DeliveryParameters.Recipient);
		If DeliveryParameters.BCCs Then
			RecipientAddresses = ?(TypeOf(EmailParameters.BCCs) = Type("String"),
				CommonClientServer.ParseStringWithEmailAddresses(EmailParameters.BCCs), EmailParameters.BCCs);
			RecipientsTableName = "BccRecipients";
		Else
			RecipientAddresses = ?(TypeOf(EmailParameters.Whom) = Type("String"),
				CommonClientServer.ParseStringWithEmailAddresses(EmailParameters.Whom), EmailParameters.Whom);
			RecipientsTableName = "Recipients";
		EndIf;
		
		For Each Whom In RecipientAddresses Do
			NewRow = Message[RecipientsTableName].Add();
			NewRow.Address         = Whom.Address;
			NewRow.Presentation = RecipientPresentation1 + " (" + Whom.Address + ")";
			NewRow.ContactInformationSource = DeliveryParameters.Recipient;
		EndDo;
		
	Else 
		If DeliveryParameters.BCCs Then
			RecipientsTableName = "BccRecipients";
		Else
			RecipientsTableName = "Recipients";
		EndIf;

		For Each Recipient In DeliveryParameters.Recipients Do
			RecipientPresentation1 = String(Recipient.Key);
			RecipientAddresses = CommonClientServer.ParseStringWithEmailAddresses(Recipient.Value);
			For Each Whom In RecipientAddresses Do
				NewRow = Message[RecipientsTableName].Add();
				NewRow.Address         = Whom.Address;
				NewRow.Presentation = RecipientPresentation1 + " (" + Whom.Address + ")";
				NewRow.ContactInformationSource = Recipient.Key;
			EndDo;
		EndDo;
	EndIf;
	
	If ValueIsFilled(EmailParameters.ReplyToAddress) Then
		NewRow = Message.ReplyRecipients.Add();
		NewRow.Address         = EmailParameters.ReplyToAddress;
		NewRow.Presentation = EmailParameters.ReplyToAddress;
	EndIf;
		
	For Each Picture In DeliveryParameters.Images Do
		StringAttachment = Message.Attachments.Add();
		PicFile = Picture.Value.GetBinaryData();
		StringAttachment.AddressInTempStorage = PutToTempStorage(PicFile);
		StringAttachment.Presentation = Picture.Key;
		StringAttachment.Id = Picture.Key;
	EndDo;

	For Each Attachment In EmailParameters.Attachments Do
		StringAttachment = Message.Attachments.Add();
		FileAttachment = New BinaryData(Attachment.Value);
		StringAttachment.AddressInTempStorage = PutToTempStorage(FileAttachment);
		StringAttachment.Presentation = Attachment.Key;
	EndDo;
	
	Return Message;
	
EndFunction
	
Function EmailClientUsed()
	
	If Common.SubsystemExists("StandardSubsystems.Interactions") Then
		ModuleInteractions = Common.CommonModule("Interactions");
		Return ModuleInteractions.EmailClientUsed();
	EndIf;
	
	Return False;
	
EndFunction
	
Function PrepareEmail(DeliveryParameters, EmailParameters)
	
	AttachmentsArray = New Array;
	
	For Each Picture In DeliveryParameters.Images Do
		Id = StringFunctions.LatinString(Picture.Key);
		If StrFind(EmailParameters.Body, "cid:" + Picture.Key) > 0 Then
			EmailParameters.Body = StrReplace(EmailParameters.Body, "cid:" + Picture.Key, "cid:" + Id);
		Else
			EmailParameters.Body = StrReplace(EmailParameters.Body, Picture.Key, "cid:" + Id);
		EndIf;
		
		PicFile = Picture.Value.GetBinaryData();
		AddressInTempStorage = PutToTempStorage(PicFile);
		
		AttachmentData = New Structure;
		AttachmentData.Insert("Presentation", Picture.Key);
		AttachmentData.Insert("AddressInTempStorage", AddressInTempStorage);
		AttachmentData.Insert("Id", Id);
		
		AttachmentsArray.Add(AttachmentData);
	EndDo;
	
	For Each Attachment In EmailParameters.Attachments Do
		FileAttachment = New BinaryData(Attachment.Value);
		AddressInTempStorage = PutToTempStorage(FileAttachment);
		
		AttachmentData = New Structure;
		AttachmentData.Insert("Presentation", Attachment.Key);
		AttachmentData.Insert("AddressInTempStorage", AddressInTempStorage);
		
		AttachmentsArray.Add(AttachmentData);
	EndDo;
	
	EmailParameters.Attachments = AttachmentsArray;
	
	Return EmailOperations.PrepareEmail(DeliveryParameters.Account, EmailParameters);
	
EndFunction

// Converts the collection to mapping.
Function ConvertToMap(Collection, KeyName, EnumValueName)
	If TypeOf(Collection) = Type("Map") Then
		Return New Map(New FixedMap(Collection));
	EndIf;
	Result = New Map;
	For Each Item In Collection Do
		Result.Insert(Item[KeyName], Item[EnumValueName]);
	EndDo;
	Return Result;
EndFunction

// Combines arrays and returns the result of the union.
Function CombineArrays(Array1, Array2)
	Array = New Array;
	For Each ArrayElement In Array1 Do
		Array.Add(ArrayElement);
	EndDo;
	For Each ArrayElement In Array2 Do
		Array.Add(ArrayElement);
	EndDo;
	Return Array;
EndFunction

// Executes archiving of attachments in accordance with the delivery parameters.
//
// Parameters:
//   Attachments - Map
//            - ValueTreeRow - See CreateReportsTree, the return value, level 3.
//   DeliveryParameters - See ExecuteBulkEmail.DeliveryParameters
//   TempFilesDir - String - a directory for archiving.
//
Procedure ArchiveAttachments(Attachments, DeliveryParameters, TempFilesDir, LogParameters)
	If Not DeliveryParameters.Archive Then
		Return;
	EndIf;
	
	If DeliveryParameters.ShouldSetPasswordsAndEncrypt And ValueIsFilled(DeliveryParameters.CertificateToEncrypt) Then
		ArchiveNameTooltip = NStr("vi = '(Cần giải mã)';
									|ru = '(Необходимо расшифровать)';
									|en = '(Decrypt)'; fa = '(Decrypt)';
									|it = '(Необходимо расшифровать)';
									|pl = '(Decrypt)';
									|tr = '(Şifre çözmek gerekli)'");
		If Lower(Right(DeliveryParameters.ArchiveName, 4)) <> ".zip" Then
			DeliveryParameters.ArchiveName = DeliveryParameters.ArchiveName + " " + ArchiveNameTooltip +".zip";
		Else
			CountOfCharacters = StrLen(DeliveryParameters.ArchiveName) - 4;
			DeliveryParameters.ArchiveName = Left(DeliveryParameters.ArchiveName, CountOfCharacters) + " " + ArchiveNameTooltip +".zip";
		EndIf;
	EndIf;
	
	// Directory and file are archived and the file name is changed to the archive name.
	FullFileName = TempFilesDir + DeliveryParameters.ArchiveName;
	
	SaveMode = ZIPStorePathMode.StoreRelativePath;
	ProcessingMode  = ZIPSubDirProcessingMode.ProcessRecursively;
	
	ZipFileWriter = New ZipFileWriter(FullFileName, DeliveryParameters.ArchivePassword);
	
	For Each Attachment In Attachments Do
		ZipFileWriter.Add(Attachment.Value, SaveMode, ProcessingMode);
		If Attachment.Settings.FileWithDirectory = True Then
			ZipFileWriter.Add(Attachment.Settings.FullDirectoryName, SaveMode, ProcessingMode);
		EndIf;
	EndDo;
	
	ZipFileWriter.Write();
	
	If DeliveryParameters.ShouldSetPasswordsAndEncrypt And ValueIsFilled(DeliveryParameters.CertificateToEncrypt) Then
		ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
		Try
			ArchiveBinaryData = ModuleDigitalSignature.Encrypt(New BinaryData(FullFileName),
			DeliveryParameters.CertificateToEncrypt);
		Except
			HandleEncryptionError(DeliveryParameters.ResultAddress, DeliveryParameters.CertificateToEncrypt, ErrorInfo(), LogParameters);
			Raise;
		EndTry;
		ArchiveBinaryData.Write(FullFileName);
	EndIf;
	
	Attachments = New Map;
	Attachments.Insert(DeliveryParameters.ArchiveName, FullFileName);
		
	If DeliveryParameters.UseEmail Then
		If DeliveryParameters.FillGeneratedReportsInMessageTemplate Then
			DeliveryParameters.RecipientReportsPresentation = 
				DeliveryParameters.RecipientReportsPresentation 
				+ Chars.LF 
				+ Chars.LF
				+ NStr("vi = 'Đã nén các tệp báo cáo vào tệp nén';
						|ru = 'Файлы отчетов запакованы в архив';
						|en = 'Report files are archived'; fa = 'Report files are archived';
						|it = 'File dei report archiviati';
						|pl = 'Pliki raportów zostały zapakowane w archiwum';
						|tr = 'Rapor dosyaları arşivlendi'")
				+ " ";
		EndIf;
		
		If DeliveryParameters.AddReferences = "ToArchive" Then
			// Delivery method involves links adding.
			If DeliveryParameters.HTMLFormatEmail Then
				DeliveryParameters.RecipientReportsPresentation = TrimAll(
					DeliveryParameters.RecipientReportsPresentation
					+"<a href = '"+ FullFileName +"'>"+ DeliveryParameters.ArchiveName +"</a>");
			Else
				DeliveryParameters.RecipientReportsPresentation = TrimAll(
					DeliveryParameters.RecipientReportsPresentation
					+""""+ DeliveryParameters.ArchiveName +""":"+ Chars.LF +"<"+ FullFileName +">");
			EndIf;
		ElsIf DeliveryParameters.FillGeneratedReportsInMessageTemplate Then
			// Delivery by mail only
			DeliveryParameters.RecipientReportsPresentation = TrimAll(
				DeliveryParameters.RecipientReportsPresentation
				+""""+ DeliveryParameters.ArchiveName +"""");
		EndIf;
		
	EndIf;
	
EndProcedure

// Parameters for saving a spreadsheet document in format.
//
// Parameters:
//   Format - EnumRef.ReportSaveFormats - a format for which you need to get the parameters.
//
// Returns:
//   Structure - Result - Structure - Writing parameters:
//       * Extension - String - extension with which you can save the file.
//       * FileType - SpreadsheetDocumentFileType - a spreadsheet document save format.
//           This procedure is used to define the <SpreadsheetFileType> parameter of the SpreadsheetDocument.Write method.
//
Function WriteSpreadsheetDocumentToFormatParameters(Format) Export
	Result = New Structure("Extension, FileType");
	If Format = Enums.ReportSaveFormats.XLSX Then
		Result.Extension = ".xlsx";
		Result.FileType = SpreadsheetDocumentFileType.XLSX;
		
	ElsIf Format = Enums.ReportSaveFormats.XLS Then
		Result.Extension = ".xls";
		Result.FileType = SpreadsheetDocumentFileType.XLS;
		
	ElsIf Format = Enums.ReportSaveFormats.ODS Then
		Result.Extension = ".ods";
		Result.FileType = SpreadsheetDocumentFileType.ODS;
		
	ElsIf Format = Enums.ReportSaveFormats.MXL Then
		Result.Extension = ".mxl";
		Result.FileType = SpreadsheetDocumentFileType.MXL;
		
	ElsIf Format = Enums.ReportSaveFormats.PDF Then
		Result.Extension = ".pdf";
		Result.FileType = StandardSubsystemsServer.TableDocumentFileTypePDF();
		
	ElsIf Format = Enums.ReportSaveFormats.HTML Then
		Result.Extension = ".html";
		Result.FileType = SpreadsheetDocumentFileType.HTML5;
		
	ElsIf Format = Enums.ReportSaveFormats.HTML4 Then
		Result.Extension = ".html";
		Result.FileType = SpreadsheetDocumentFileType.HTML4;
		
	ElsIf Format = Enums.ReportSaveFormats.DOCX Then
		Result.Extension = ".docx";
		Result.FileType = SpreadsheetDocumentFileType.DOCX;
		
	ElsIf Format = Enums.ReportSaveFormats.TXT Then
		Result.Extension = ".txt";
		Result.FileType = SpreadsheetDocumentFileType.TXT;
	
	ElsIf Format = Enums.ReportSaveFormats.ANSITXT Then
		Result.Extension = ".txt";
		Result.FileType = SpreadsheetDocumentFileType.ANSITXT;
		
	Else 
		// A blueprint for all formats added during the app implementation and
		// whose saving handler should be located in the overridable module.
		Result.Extension = Undefined;
		Result.FileType = Undefined;
		
	EndIf;
	
	Return Result;
EndFunction

Function FullFileNameFromTemplate(Directory, ReportDescription1, Format, DeliveryParameters, DescriptionTemplate, Period) Export
	
	FileNameParameters = New Structure("ReportDescription1, ReportFormat, MailingDate, FileExtention");
	FileNameParameters.ReportDescription1 = ReportDescription1;
	FileNameParameters.ReportFormat = Format.Name;
	FileNameParameters.FileExtention = ?(Format.Extension = Undefined, "", Format.Extension);
	
	If ValueIsFilled(DescriptionTemplate) Then
		FileNameTemplate = DescriptionTemplate + "[FileExtention]";
		FileNameParameters.MailingDate = CurrentSessionDate();
		If Period <> Undefined Then
			FileNameParameters.Insert("Period", Period);
		EndIf;
		FileName = FillTemplate(FileNameTemplate, FileNameParameters);
	Else
		FileNameTemplate = "[ReportDescription1] ([ReportFormat])[FileExtention]"; // ACC:1297 - This is a template.
		FileName = StringFunctionsClientServer.InsertParametersIntoString(FileNameTemplate, FileNameParameters);
	EndIf;
	
	Return Directory + ConvertFileName(FileName, DeliveryParameters.TransliterateFileNames);
	
EndFunction

// Converts invalid file characters to similar valid characters.
//   Operates only with the file name, the path is not supported.
//
// Parameters:
//   InitialFileName - String - a file name from which you have to remove invalid characters.
//
// Returns:
//   String - Result - String - Conversion result.
//
Function ConvertFileName(InitialFileName, TransliterateFileNames)
	
	Result = Left(TrimAll(InitialFileName), 255);
	
	ReplacementsMap = New Map;
	
	// Standard unsupported characters.
	ReplacementsMap.Insert("""", "'");
	ReplacementsMap.Insert("/", "_");
	ReplacementsMap.Insert("\", "_");
	ReplacementsMap.Insert(":", "_");
	ReplacementsMap.Insert(";", "_");
	ReplacementsMap.Insert("|", "_");
	ReplacementsMap.Insert("=", "_");
	ReplacementsMap.Insert("?", "_");
	ReplacementsMap.Insert("*", "_");
	ReplacementsMap.Insert("<", "_");
	ReplacementsMap.Insert(">", "_");
	
	// Characters not supported by the obsolete OS.
	ReplacementsMap.Insert("[", "");
	ReplacementsMap.Insert("]", "");
	ReplacementsMap.Insert(",", "");
	ReplacementsMap.Insert("{", "");
	ReplacementsMap.Insert("}", "");
	
	For Each KeyAndValue In ReplacementsMap Do
		Result = StrReplace(Result, KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	If TransliterateFileNames Then
		Result = StringFunctions.LatinString(Result);
	EndIf;
	
	Return Result;
EndFunction

// Value tree required for generating and delivering reports.
Function CreateReportsTree()
	// Levels of a tree structure:
	//
	// 1 - Recipients:
	//   Key - Reference.
	//   Value - Recipient's directory.
	//
	// 2 - Recipients' spreadsheets:
	//   Key - Report nname.
	//   Value - Spreadsheet.
	//   Settings - All report parameters.
	//
	// 3 - Recipients' files:
	//   Key - Filename.
	//   Value - File full path.
	//   Settings - "FileWithDirectory", "FileName", "FullFileName", "DirectoryName", "FullDirectoryName", "Format", "Name", "Extension", "FileType".
	
	ReportsTree = New ValueTree;
	ReportsTree.Columns.Add("Level", New TypeDescription("Number"));
	ReportsTree.Columns.Add("Key");
	ReportsTree.Columns.Add("Value");
	ReportsTree.Columns.Add("Settings", New TypeDescription("Structure"));
	
	Return ReportsTree;
EndFunction

// Checks the current user's right to output information. If there are no rights, an event log record is created.
//
// Parameters:
//   LogParameters - Structure
// 
// Returns:
//   Boolean
//
Function OutputRight(LogParameters)
	OutputRight = AccessRight("Output", Metadata);
	If Not OutputRight Then
		LogRecord(LogParameters, EventLogLevel.Error,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Người sử dụng ''%1'' không có đủ quyền để hiển thị thông tin.';
																			|ru = 'У пользователя ''%1'' недостаточно прав на вывод информации.';
																			|en = '%1 has insufficient rights to export data.'; fa = '%1 has insufficient rights to export data.';
																			|it = 'У пользователя ''%1'' недостаточно прав на вывод информации.';
																			|pl = '%1 has insufficient rights to export data.';
																			|tr = '''%1'' kullanıcısı bilgi görüntülemek için yeterli yetkilere sahip değil'"),
			Users.CurrentUser()));
	EndIf;
	Return OutputRight;
EndFunction

// Converts an array of messages to a user in one string.
Function MessagesToUserString(Errors = Undefined, SeeEventLog = True) Export
	If Errors = Undefined Then
		Errors = GetUserMessages(True);
	EndIf;
	
	Indent = Chars.LF + Chars.LF;
	
	AllErrors = "";
	For Each Error In Errors Do
		AllErrors = TrimAll(AllErrors + Indent + ?(TypeOf(Error) = Type("String"), Error, Error.Text));
	EndDo;
	If AllErrors <> "" And SeeEventLog Then
		AllErrors = AllErrors + Indent + "---" + Indent + NStr("vi = 'Chi tiết xem trong nhật ký sự kiện.';
																|ru = 'Подробности см. в журнале регистрации.';
																|en = 'See the event log for details.'; fa = 'See the event log for details.';
																|it = 'Vedere il registro per i dettagli.';
																|pl = 'Szczegóły zob. w dzienniku rejestracji.';
																|tr = 'Ayrıntılar için olay günlüğüne bakın.'");
	EndIf;
	
	Return AllErrors;
EndFunction

// If the file exists - adds a suffix to the file name.
//
// Parameters:
//   FullFileName - String - a file name to start a search.
//
Procedure FindFreeFileName(FullFileName)
	File = New File(FullFileName);
	
	If Not File.Exists() Then
		Return;
	EndIf;
	
	// Set a file names template to substitute various suffixes.
	NameTemplate = "";
	NameLength = StrLen(FullFileName);
	SlashCode = CharCode("/");
	BackSlashCode = CharCode("\");
	PointCode = CharCode(".");
	For ReverseIndex = 1 To NameLength Do
		IndexOf = NameLength - ReverseIndex + 1;
		Code = CharCode(FullFileName, IndexOf);
		If Code = PointCode Then
			NameTemplate = Left(FullFileName, IndexOf - 1) + "<template>" + Mid(FullFileName, IndexOf);
			Break;
		ElsIf Code = SlashCode Or Code = BackSlashCode Then
			Break;
		EndIf;
	EndDo;
	If NameTemplate = "" Then
		NameTemplate = FullFileName + "<template>";
	EndIf;
	
	IndexOf = 0;
	While File.Exists() Do
		IndexOf = IndexOf + 1;
		FullFileName = StrReplace(NameTemplate, "<template>", " ("+ Format(IndexOf, "NG=") +")");
		File = New File(FullFileName);
	EndDo;
EndProcedure

// Creates the tree root row for the recipient (if it is absent) and fills it with default parameters.
//
// Parameters:
//   ReportsTree     - See CreateReportsTree
//   RecipientRef  - CatalogRef
//                     - Undefined - a recipient reference.
//   DeliveryParameters - See ExecuteBulkEmail.DeliveryParameters
//
// Returns: 
//   ValueTreeRow - See CreateReportsTree
//
Function DefineTreeRowForRecipient(ReportsTree, RecipientRef, DeliveryParameters)
	
	RecipientRow = ReportsTree.Rows.Find(RecipientRef, "Key", False);
	If RecipientRow = Undefined Then
		
		RecipientsDirectory = DeliveryParameters.TempFilesDir;
		If RecipientRef <> Undefined Then
			RecipientsDirectory = RecipientsDirectory 
				+ ConvertFileName(String(RecipientRef), DeliveryParameters.TransliterateFileNames)
				+ " (" + String(RecipientRef.UUID()) + ")\";
			CreateDirectory(RecipientsDirectory);
		EndIf;
		
		RecipientRow = ReportsTree.Rows.Add();
		RecipientRow.Level  = 1;
		RecipientRow.Key     = RecipientRef;
		RecipientRow.Value = RecipientsDirectory;
		
	EndIf;
	
	Return RecipientRow;
	
EndFunction

// Generates reports presentation for recipients.
Procedure GenerateReportPresentationsForRecipient(DeliveryParameters, RecipientRow)
	
	GeneratedReports = "";
	
	If DeliveryParameters.UseEmail And DeliveryParameters.FillGeneratedReportsInMessageTemplate Then
		
		Separator = Chars.LF;
		If DeliveryParameters.AddReferences = "AfterReports" Then
			Separator = Separator + Chars.LF;
		EndIf;
		
		IndexOf = 0;
		
		For Each RowReport In DeliveryParameters.GeneralReportsRow.Rows Do
			IndexOf = IndexOf + 1;
			GeneratedReports = GeneratedReports 
			+ Separator 
			+ Format(IndexOf, "NG=") 
			+ ". " 
			+ RowReport.Settings.PresentationInEmail;
		EndDo;
		
		If RecipientRow <> Undefined And RecipientRow <> DeliveryParameters.GeneralReportsRow Then
			For Each RowReport In RecipientRow.Rows Do
				IndexOf = IndexOf + 1;
				GeneratedReports = GeneratedReports 
				+ Separator 
				+ Format(IndexOf, "NG=") 
				+ ". " 
				+ RowReport.Settings.PresentationInEmail;
			EndDo;
		EndIf;
		
	EndIf;
	
	DeliveryParameters.RecipientReportsPresentation = TrimAll(GeneratedReports);
	
EndProcedure

// Generates a text about a successful report distribution and saves it to InformationRegister.ReportsDistributionHistory.
Function TestOfSuccessfulReportDistribution(DeliveryParameters, RecipientRow, RecipientPresentation1, SenderSRepresentation, AdditionalInfo = "")

	GeneratedReports = New Array;

	If DeliveryParameters.UseEmail And DeliveryParameters.FillGeneratedReportsInMessageTemplate Then

		For Each RowReport In DeliveryParameters.GeneralReportsRow.Rows Do
			GeneratedReports.Add(RowReport.Settings.PresentationInEmail);
		EndDo;

		If RecipientRow <> Undefined And RecipientRow <> DeliveryParameters.GeneralReportsRow Then
			For Each RowReport In RecipientRow.Rows Do
				GeneratedReports.Add(RowReport.Settings.PresentationInEmail);
			EndDo;
		EndIf;
		
	EndIf;

	If GeneratedReports.Count() = 1 Then 
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '- ""%1"" đã gửi từ %2. %3';
				|ru = '- ""%1"" отправлен от %2. %3';
				|en = '- ""%1"" is sent from %2. %3'; fa = '- ""%1"" is sent from %2. %3';
				|it = '- ""%1"" отправлен от %2. %3';
				|pl = '- ""%1"" is sent from %2. %3';
				|tr = '- %2 üzerinden ""%1"" gönderildi. %3'"), GeneratedReports[0],
			SenderSRepresentation, AdditionalInfo);	
	Else

		ReportsAsString = "";

		For Each RowReport In GeneratedReports Do
			ReportsAsString = ReportsAsString 
			+ ?(ValueIsFilled(ReportsAsString), Chars.LF, "")
			+ "- """ 
			+ RowReport 
			+ """";
		EndDo;
				
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 đã gửi từ %2. %3';
				|ru = '%1 отправлены от %2. %3';
				|en = '%1 are sent from %2. %3'; fa = '%1 are sent from %2. %3';
				|it = '%1 отправлены от %2. %3';
				|pl = '%1 are sent from %2. %3';
				|tr = '%2 üzerinden %1 gönderildi. %3'"), ReportsAsString, SenderSRepresentation,
				AdditionalInfo);

	EndIf;

	If DeliveryParameters.Archive Then
		PackedToArchive = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã đóng gói vào tệp nén ""%1""';
																						|ru = 'Упаковано в архив ""%1""';
																						|en = 'Packed in the ""%1"" archive'; fa = 'Packed in the ""%1"" archive';
																						|it = 'Упаковано в архив ""%1""';
																						|pl = 'Packed in the ""%1"" archive';
																						|tr = '""%1"" arşivinde paketlendi'"), DeliveryParameters.ArchiveName);
		MessageText = MessageText + Chars.LF + PackedToArchive;	
	EndIf;

	Return MessageText;
	
EndFunction

// Checks if there are external data sets.
//
// Parameters:
//   DataSets - DataCompositionTemplateDataSets - a collection of data sets to be checked.
//
// Returns: 
//   Boolean - True if is has external data sets.
//
Function ThereIsExternalDataSet(DataSets)
	
	For Each DataSet In DataSets Do
		
		If TypeOf(DataSet) = Type("DataCompositionTemplateDataSetObject") Then
			
			Return True;
			
		ElsIf TypeOf(DataSet) = Type("DataCompositionTemplateDataSetUnion") Then
			
			If ThereIsExternalDataSet(DataSet.Items) Then
				
				Return True;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

Function MailingsWithReportsNumber(ReportVariant)
	
	If Not ValueIsFilled(ReportVariant) Or TypeOf(ReportVariant) <> Type("CatalogRef.ReportsOptions") 
		Or ReportVariant.IsEmpty() Then
		Return 0;
	EndIf;
	
	Query = New Query(
		"SELECT ALLOWED
		|	COUNT(DISTINCT ReportsToDistribute.Ref) AS Count
		|FROM
		|	Catalog.ReportMailings.Reports AS ReportsToDistribute
		|WHERE
		|	ReportsToDistribute.Report = &ReportVariant");
		
	Query.SetParameter("ReportVariant", ReportVariant);
	Return Query.Execute().Unload()[0].Count;
	
EndFunction	

// Checks rights and generates error text.
Function CheckAddRightErrorText() Export
	If Not AccessRight("Output", Metadata) Then
		Return NStr("vi = 'Không có quyền để hiển thị thông tin.';
					|ru = 'Нет прав на вывод информации.';
					|en = 'You have insufficient rights to export data.'; fa = 'You have insufficient rights to export data.';
					|it = 'Non si dispone dei diritti per visualizzare le informazioni.';
					|pl = 'Nie ma uprawnień na wyprowadzanie informacji.';
					|tr = 'Bilgi görüntüleme yetkisine sahip değilsiniz.'");
	EndIf;
	If Not AccessRight("Update", Metadata.Catalogs.ReportMailings) Then
		Return NStr("vi = 'Không có quyền gửi báo cáo hàng loạt.';
					|ru = 'Нет прав на рассылки отчетов.';
					|en = 'You have insufficient rights to distribute reports.'; fa = 'You have insufficient rights to distribute reports.';
					|it = 'Non si dispone dei diritti di invio massivo dei report.';
					|pl = 'Nie ma uprawnień na wysyłkę raportów.';
					|tr = 'Rapor gönderme yetkisine sahip değilsiniz.'");
	EndIf;
	If Not EmailOperations.CanSendEmails() Then
		Return NStr("vi = 'Không có quyền gửi email hoặc không có trương mục email khả dụng.';
					|ru = 'Нет прав на отправку писем или нет доступных учетных записей.';
					|en = 'You have insufficient rights to send emails or no email accounts.'; fa = 'You have insufficient rights to send emails or no email accounts.';
					|it = 'Non si dispone dei diritti per l''invio delle lettere oppure non esistono account disponibili.';
					|pl = 'Nie ma uprawnień na wysyłkę listów lub nie ma dostępnych kont.';
					|tr = 'E-posta gönderme yetkisine sahip değilsiniz veya kullanılabilir hesap mevcut değil.'");
	EndIf;
	Return "";
EndFunction

// Returns a value list of the ReportSaveFormats enumeration.
//
// Returns: 
//   ValueList - List of formats with marks on the system default formats:
//     * Value      - EnumRef.ReportSaveFormats - a reference to the described format.
//     * Presentation - String - user presentation of the described format.
//     * Check       - Boolean - a flag of usage as a default format.
//     * Picture      - Picture - a picture of the format.
//
Function FormatsList() Export
	FormatsList = New ValueList;
	
	SetFormatsParameters(FormatsList, "HTML", PictureLib.HTMLFormat, True);
	SetFormatsParameters(FormatsList, "PDF"  , PictureLib.PDFFormat);
	SetFormatsParameters(FormatsList, "XLSX" , PictureLib.ExcelFormat2007);
	SetFormatsParameters(FormatsList, "XLS"  , PictureLib.ExcelFormat);
	SetFormatsParameters(FormatsList, "ODS"  , PictureLib.OpenOfficeCalcFormat);
	SetFormatsParameters(FormatsList, "MXL"  , PictureLib.MXLFormat);
	SetFormatsParameters(FormatsList, "DOCX" , PictureLib.WordFormat2007);
	SetFormatsParameters(FormatsList, "TXT"    , PictureLib.TXTFormat);
	SetFormatsParameters(FormatsList, "ANSITXT", PictureLib.TXTFormat);
	
	ReportMailingOverridable.OverrideFormatsParameters(FormatsList);
	
	// Remaining formats.
	For Each FormatRef In Enums.ReportSaveFormats Do
		If FormatRef = Enums.ReportSaveFormats.HTML4 Then // Skip HTML4
			Continue;
		EndIf;
		SetFormatsParameters(FormatsList, FormatRef);
	EndDo;
	
	Return FormatsList;
EndFunction

// Gets an empty value for the search in the Reports or ReportFormats table of the ReportMailings catalog.
//
// Returns:
//   - CatalogRef.AdditionalReportsAndDataProcessors
//   - CatalogRef.ReportsOptions
//
Function EmptyReportValue() Export
	SetPrivilegedMode(True);
	Return Metadata.Catalogs.ReportMailings.TabularSections.ReportFormats.Attributes.Report.Type.AdjustValue();
EndFunction

// Gets an application title. If it is not specified, gets a configuration metadata synonym.
Function ThisInfobaseName() Export
	
	SetPrivilegedMode(True);
	Result = Constants.SystemTitle.Get();
	Return ?(IsBlankString(Result), Metadata.Synonym, Result);
	
EndFunction

Procedure DisableBulkEmailBeforeDeleteBulkEmailRecipientsType(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ReportMailings.Ref AS Ref
		|FROM
		|	Catalog.ReportMailings AS ReportMailings
		|WHERE
		|	ReportMailings.MailingRecipientType = &MailingRecipientType";
	
	Query.SetParameter("MailingRecipientType", Source.Ref);
	Records = Query.Execute().Select();
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		LockItem = Block.Add(Metadata.Catalogs.ReportMailings.FullName());
		LockItem.SetValue("MailingRecipientType", Source.Ref);
		Block.Lock();
		
		While Records.Next() Do
			BulkEmailObject = Records.Ref.GetObject();
			
			If BulkEmailObject = Undefined Then
				Continue;
			EndIf;
			
			BulkEmailObject.MailingRecipientType = Catalogs.MetadataObjectIDs.EmptyRef();
			BulkEmailObject.IsPrepared = False;
			InfobaseUpdate.WriteData(BulkEmailObject);
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

Function FormatPresentation(Format) Export
	
	If Format = Enums.ReportSaveFormats.PDF Then
		Return StandardSubsystemsServer.FileTypeRepresentationOfATabularPDFDocument();
	EndIf;
	
	Return String(Format);
	
EndFunction

// Sends out text messages containing archive passwords and saves the result to ResultAddress. 
//
// Parameters:
//   ExecutionParameters - Structure - Distributions and their parameters:
//       * PreparedSMSMessages - Array of Structure:
//         ** PhoneNumbers - Array of String
//         ** SMSMessageText - String
//         ** Recipient - DefinedType.BulkEmailRecipient									
//   ResultAddress - String - an address in the temporary storage where the result will be placed.
//
Procedure SendBulkSMSMessagesWithReportDistributionArchivePasswordsInBackgroundJob(Parameters, ResultAddress) Export
	
	ModuleSMS = Common.CommonModule("SendSMSMessage");
	DistributionErrorsMessages = New Array;
	SentCount = 0;
	ResultByRecipients = New Array;
	For Each PrepareSMS In Parameters.PreparedSMSMessages Do
		SendingResult = ModuleSMS.SendSMS(PrepareSMS.PhoneNumbers, PrepareSMS.SMSMessageText);
		RecipientResult = New Structure("Recipient, NotSent, Comment");
		RecipientResult.Recipient = PrepareSMS.Recipient;
		If ValueIsFilled(SendingResult.ErrorDescription) Then
			DistributionErrorsMessages.Add(SendingResult.ErrorDescription);
			RecipientResult.Comment = SendingResult.ErrorDescription;
			RecipientResult.NotSent = True;
		Else	
			SentCount = SentCount + 1;
			RecipientResult.Comment = NStr("vi = 'Đã gửi SMS.';
											|ru = 'SMS отправлено.';
											|en = 'The text message is sent.'; fa = 'The text message is sent.';
											|it = 'SMS отправлено.';
											|pl = 'The text message is sent.';
											|tr = 'SMS gönderildi.'");
		EndIf;
		ResultByRecipients.Add(RecipientResult);
	EndDo;
	
	UnsentCount = Parameters.UnsentCount + DistributionErrorsMessages.Count();
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã gửi SMS có mật khẩu nén. Đã gửi: %1; chưa gửi: %2.';
			|ru = 'Отправлены SMS с паролями архивов. Отправлено: %1; не отправлено: %2.';
			|en = 'Text messages with archive passwords are sent. Sent: %1. Not sent: %2.'; fa = 'Text messages with archive passwords are sent. Sent: %1. Not sent: %2.';
			|it = 'Отправлены SMS с паролями архивов. Отправлено: %1; не отправлено: %2.';
			|pl = 'Text messages with archive passwords are sent. Sent: %1. Not sent: %2.';
			|tr = 'Arşivin şifresiyle bir SMS gönderildi. Gönderilen: %1; gönderilmeyen: %2.'"), SentCount,
		UnsentCount);
	
	Result = New Structure;
	Result.Insert("Text", MessageText);
	Result.Insert("More", MessagesToUserString(DistributionErrorsMessages));
	Result.Insert("ResultByRecipients", ResultByRecipients);
	Result.Insert("SentCount", SentCount);
	Result.Insert("UnsentCount", UnsentCount);
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Function ReportDistributionHistoryFields(ReportMailing, Recipient, StartDistribution)

	HistoryFields = New Structure;
	HistoryFields.Insert("ReportMailing", ReportMailing);  
	HistoryFields.Insert("Recipient", Recipient);
	HistoryFields.Insert("StartDistribution", StartDistribution); 
	HistoryFields.Insert("Period", CurrentSessionDate()); 
	HistoryFields.Insert("Account", ""); 
	HistoryFields.Insert("EMAddress", ""); 
	HistoryFields.Insert("Comment", "");
	HistoryFields.Insert("Executed", False);
	HistoryFields.Insert("OutgoingEmail", "");
	HistoryFields.Insert("MethodOfObtaining", "");
	HistoryFields.Insert("EmailID", "");   
	HistoryFields.Insert("DeliveryDate", '00010101');  
	HistoryFields.Insert("Status", Enums.EmailMessagesStatuses.EmptyRef());   
	HistoryFields.Insert("SessionNumber", InfoBaseSessionNumber());

	Return HistoryFields;

EndFunction

Procedure HandleEncryptionError(ResultAddress, CertificateToEncrypt, ErrorInfo, LogParameters)
	
	Refinement = CommonClientServer.ExceptionClarification(ErrorInfo);
	ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
	ClassifierError = ModuleDigitalSignature.ClassifierError(Refinement.Text, True);
	IsKnownError = ClassifierError <> Undefined;
	If IsKnownError Then
		StringsErrors = New Array;
		StringsErrors.Add(Refinement.Text);
		If ValueIsFilled(ClassifierError.Cause) Then
			Reasons = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Lý do có thể: %1';
																					|ru = 'Возможные причины: %1';
																					|en = 'Possible reasons: %1'; fa = 'Possible reasons: %1';
																					|it = 'Возможные причины: %1';
																					|pl = 'Possible reasons: %1';
																					|tr = 'Olası nedenler: %1'"), ClassifierError.Cause);
			StringsErrors.Add(Reasons);
		EndIf;
		If ValueIsFilled(ClassifierError.Decision) Then
			Decision = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đề xuất: %1';
																					|ru = 'Рекомендации: %1';
																					|en = 'Recommendations: %1'; fa = 'Recommendations: %1';
																					|it = 'Рекомендации: %1';
																					|pl = 'Recommendations: %1';
																					|tr = 'Öneriler: %1'"), ClassifierError.Decision);
			StringsErrors.Add(Decision);
		EndIf;
		ErrorText = StrConcat(StringsErrors, Chars.LF);
		
		LogRecord(LogParameters, EventLogLevel.Error, ErrorText);
	EndIf;
	
	If ResultAddress <> Undefined And IsTempStorageURL(ResultAddress) Then
		Result = New Structure;
		Result.Insert("HasEncryptionErrors", True);
		Result.Insert("CertificateToEncrypt", CertificateToEncrypt);
		PutToTempStorage(Result, ResultAddress);
	EndIf;
	
EndProcedure

// Generates a string containing the delivery method
//
// Parameters:
//   DeliveryParameters - See ReportMailing.DeliveryParameters.
//   Recipient - DefinedType.BulkEmailRecipient
//   MailAddr - String
// 
//
// Returns: 
//   String
// 
Function DistributionReceiptMethod(DeliveryParameters, Recipient, MailAddr = "")

	MethodOfObtaining = "";

	If DeliveryParameters.UseNetworkDirectory Then
		ServerNetworkDdirectory = DeliveryParameters.NetworkDirectoryWindows;

		If Common.IsLinuxServer() Then
			ServerNetworkDdirectory = DeliveryParameters.NetworkDirectoryLinux;
		EndIf;

		MethodOfObtaining = StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"vi = 'Đăng tải trên thư mục mạng: ""%1"".';
			|ru = 'Публиковать в сетевой каталог: ""%1"".';
			|en = 'Publish to the network directory: ""%1"".'; fa = 'Publish to the network directory: ""%1"".';
			|it = 'Публиковать в сетевой каталог: ""%1"".';
			|pl = 'Publish to the network directory: ""%1"".';
			|tr = 'Şu dijital katalogda yayınla: ""%1"".'"), ServerNetworkDdirectory);
	EndIf;

	If DeliveryParameters.UseFTPResource Then
		FTPResource = "ftp://" + DeliveryParameters.Server + ":" + Format(DeliveryParameters.Port, "NZ=0; NG=0")
			+ DeliveryParameters.Directory;
		MethodOfObtaining = StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"vi = 'Đăng tải trên nguồn FTP: ""%1"".';
			|ru = 'Публиковать на FTP ресурс: ""%1"".';
			|en = 'Publish to the FTP resource: ""%1"".'; fa = 'Publish to the FTP resource: ""%1"".';
			|it = 'Публиковать на FTP ресурс: ""%1"".';
			|pl = 'Publish to the FTP resource: ""%1"".';
			|tr = 'Şu FTP kaynağında yayınla: ""%1"".'"), FTPResource);
	EndIf;

	If DeliveryParameters.UseFolder Then
		MethodOfObtaining = StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"vi = 'Đăng tải vào thư mục: ""%1"".';
			|ru = 'Публиковать в папку: ""%1"".';
			|en = 'Publish to the folder: ""%1"".'; fa = 'Publish to the folder: ""%1"".';
			|it = 'Публиковать в папку: ""%1"".';
			|pl = 'Publish to the folder: ""%1"".';
			|tr = 'Şu klasörde yayınla. ""%1"".'"), String(DeliveryParameters.Folder));
	EndIf;

	If DeliveryParameters.UseEmail Then
		If Not ValueIsFilled(MailAddr) Then
			If DeliveryParameters.Recipients <> Undefined Then
				Address = DeliveryParameters.Recipients.Get(Recipient);
				MailAddr = ?(Address <> Undefined, Address, NStr("vi = 'Chưa chỉ ra địa chỉ email.';
																|ru = 'Адрес электронной почты не указан.';
																|en = 'An email address is not specified.'; fa = 'An email address is not specified.';
																|it = 'Адрес электронной почты не указан.';
																|pl = 'An email address is not specified.';
																|tr = 'E-posta adresi belirtilmemiş.'"));
			Else
				MailAddr = NStr("vi = 'Chưa chỉ ra địa chỉ email.';
								|ru = 'Адрес электронной почты не указан.';
								|en = 'An email address is not specified.'; fa = 'An email address is not specified.';
								|it = 'Адрес электронной почты не указан.';
								|pl = 'An email address is not specified.';
								|tr = 'E-posta adresi belirtilmemiş.'");	
			EndIf;
		EndIf;
		If DeliveryParameters.NotifyOnly Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"vi = 'Gửi thông báo qua email: ""%1"".';
				|ru = 'Отправить уведомление по электронной почте: ""%1"".';
				|en = 'Send a notification by email: ""%1"".'; fa = 'Send a notification by email: ""%1"".';
				|it = 'Отправить уведомление по электронной почте: ""%1"".';
				|pl = 'Send a notification by email: ""%1"".';
				|tr = 'Şu e-postaya bildirim gönder: ""%1"".'"), MailAddr);
			MethodOfObtaining = ?(ValueIsFilled(MethodOfObtaining), MethodOfObtaining + " " + Text, Text);
		Else
			Text = StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"vi = 'Gửi qua email: ""%1"".';
				|ru = 'Отправить по электронной почте: ""%1"".';
				|en = 'Send by email: ""%1"".'; fa = 'Send by email: ""%1"".';
				|it = 'Отправить по электронной почте: ""%1"".';
				|pl = 'Send by email: ""%1"".';
				|tr = 'Şu e-postaya gönder: ""%1"".'"), MailAddr);
			MethodOfObtaining = ?(ValueIsFilled(MethodOfObtaining), MethodOfObtaining + " " + Text, Text);
		EndIf;

	EndIf;

	Return MethodOfObtaining;

EndFunction

// For internal use only.
Procedure ClearUpObsoleteRecordsOfReportDistributionHistory() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ReportDistributionHistoryClearUp);
	
	ResultOfClearUpObsoleteRecordsOfReportDistributionHistory();
	
EndProcedure   

Function ResultOfClearUpObsoleteRecordsOfReportDistributionHistory()
	
	DeletionResult = New Structure("DeletedCount", 0);
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	ReportsDistributionHistory.ReportMailing AS ReportMailing,
		|	ReportsDistributionHistory.Recipient AS Recipient,
		|	ReportsDistributionHistory.StartDistribution AS StartDistribution
		|FROM
		|	InformationRegister.ReportsDistributionHistory AS ReportsDistributionHistory
		|WHERE
		|	ReportsDistributionHistory.StartDistribution < &HistoryRetentionStartDate";
	
	NumberOfMonths = Constants.ReportDistributionHistoryRetentionPeriodInMonths.Get();   
	HistoryRetentionStartDate = ?(GetFunctionalOption("RetainReportDistributionHistory"),
		CurrentSessionDate() - NumberOfMonths * 2592000, CurrentSessionDate());

	Query.SetParameter("HistoryRetentionStartDate", HistoryRetentionStartDate);

	BeginTransaction();
	Try

	DataLock = New DataLock;
	DataLockItem = DataLock.Add("InformationRegister.ReportsDistributionHistory");
	DataLockItem.Mode = DataLockMode.Shared;
	DataLock.Lock();

	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		RecordSet = InformationRegisters.ReportsDistributionHistory.CreateRecordSet();
		RecordSet.Filter.ReportMailing.Set(Selection.ReportMailing);
		RecordSet.Filter.Recipient.Set(Selection.Recipient);
		RecordSet.Filter.StartDistribution.Set(Selection.StartDistribution);
		RecordSet.Write();
		DeletionResult.DeletedCount = DeletionResult.DeletedCount + 1;
	EndDo;
	
	CommitTransaction();
	
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	SetPrivilegedMode(False);
	
	Return DeletionResult;
	
EndFunction

Procedure ClearUpReportDistributionHistoryInBackgroundJob(Parameters, ResultAddress) Export
	
	DeletionResult = ResultOfClearUpObsoleteRecordsOfReportDistributionHistory();
	
	MessageText = StringFunctionsClientServer.StringWithNumberForAnyLanguage(NStr(
		"vi = ';Đã xóa %1 bản ghi lịch sử gửi báo cáo hàng loạt;;Đã xóa %1 bản ghi lịch sử gửi báo cáo hàng loạt;
		|Đã xóa %1 bản ghi lịch sử gửi báo cáo hàng loạt;Đã xóa %1 bản ghi lịch sử gửi báo cáo hàng loạt';
		|ru = ';Очищена %1 запись истории рассылки отчетов;;Очищено %1 записи истории рассылки отчетов;
		|Очищено %1 записей истории рассылки отчетов;Очищено %1 записи истории рассылки отчетов';
		|en = ';%1 report distribution history record is cleared;;;;
		|%1 report distribution history records are cleared'; fa = ';%1 report distribution history record is cleared;;;;
		|%1 report distribution history records are cleared';
		|it = ';Очищена %1 запись истории рассылки отчетов;;Очищено %1 записи истории рассылки отчетов;
		|Очищено %1 записей истории рассылки отчетов;Очищено %1 записи истории рассылки отчетов';
		|pl = ';%1 report distribution history record is cleared;;;;
		|%1 report distribution history records are cleared';
		|tr = ';%1 Rapor dağıtımı geçmiş kaydı temizlendi;;%1 Rapor dağıtımı geçmiş kayıtları temizlendi;;
		|%1 Rapor dağıtımı geçmiş kayıtları temizlendi;%1 Rapor dağıtımı geçmiş kayıtları temizlendi'"),
		DeletionResult.DeletedCount);
	
	Result = New Structure;
	Result.Insert("Text", MessageText);
	PutToTempStorage(Result, ResultAddress);
		
EndProcedure   	

// Sets the default duration for retaining the distribution history in months.
//
Procedure SetReportDistributionHistoryRetentionPeriodInMonths() Export
	
	Constants.ReportDistributionHistoryRetentionPeriodInMonths.Set(3);
	
EndProcedure

Function CanEncryptAttachments() Export

	If Not Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		Return False;
	Else
		ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
		Return ModuleDigitalSignature.UseEncryption();
	EndIf;

EndFunction

// Returns the default body template for delivery by email.
Function TextTemplate1(AllParametersOfFilesAndEmailText = Undefined) Export
	
	If AllParametersOfFilesAndEmailText <> Undefined Then
		Return StringFunctionsClientServer.SubstituteParametersToString(NStr(
		"vi = 'Đã lập báo cáo:
		|
		|%1';
		|ru = 'Сформированы отчеты:
		|
		|%1';
		|en = 'Reports are generated:
		|
		|%1'; fa = 'Reports are generated:
		|
		|%1';
		|it = 'Report creati:
		|
		|%1';
		|pl = 'Wygenerowane raporty:
		|
		|%1';
		|tr = 'Raporlar oluşturuldu:
		|
		|%1'"),
		"[" + AllParametersOfFilesAndEmailText.GeneratedReports + "]
		|
		|[" + AllParametersOfFilesAndEmailText.DeliveryMethod + "]
		|
		|[" + AllParametersOfFilesAndEmailText.SystemTitle + "]
		|[" + AllParametersOfFilesAndEmailText.ExecutionDate + "(DLF='DD')]");
	Else
		Return StringFunctionsClientServer.SubstituteParametersToString(NStr(
		"vi = 'Đã lập báo cáo:
		|
		|%1';
		|ru = 'Сформированы отчеты:
		|
		|%1';
		|en = 'Reports are generated:
		|
		|%1'; fa = 'Reports are generated:
		|
		|%1';
		|it = 'Report creati:
		|
		|%1';
		|pl = 'Wygenerowane raporty:
		|
		|%1';
		|tr = 'Raporlar oluşturuldu:
		|
		|%1'"),
		"[GeneratedReports]
		|
		|[DeliveryMethod]
		|
		|[SystemTitle]
		|[ExecutionDate(DLF='DD')]");
	EndIf;

EndFunction

Function GetPeriodFromUserSettings(DCUserSettings) Export
	If TypeOf(DCUserSettings) <> Type("DataCompositionUserSettings") Then
		Return Undefined;
	EndIf;

	SoughtForParameterPeriod = New DataCompositionParameter("Period");
	SoughtForParameterReportPeriod = New DataCompositionParameter("ReportPeriod");
	For Each Item In DCUserSettings.Items Do
		If TypeOf(Item) = Type("DataCompositionSettingsParameterValue") 
			And (Item.Parameter = SoughtForParameterPeriod Or Item.Parameter = SoughtForParameterReportPeriod) Then
			Return Item.Value;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Parameters:
//  Form - ClientApplicationForm
//
Procedure AddCommandsAddTextAdditionalParameters(Form) Export

	If Form.EmailTextAdditionalParameters = Undefined Then
		Form.EmailTextAdditionalParameters = New Structure;
	Else
		For Each Parameter In Form.EmailTextAdditionalParameters Do
			Form.Commands.Delete(Form.Commands[Parameter.Value.CommandName]);
			Form.Items.Delete(Form.Items[Parameter.Value.TextButtonName]);
			Form.Items.Delete(Form.Items[Parameter.Value.HTMLButtonName]);
			Form.Items.Delete(Form.Items[Parameter.Value.SubjectButtonName]);
		EndDo;
		Form.EmailTextAdditionalParameters = New Structure;
	EndIf;

	EmailTextAdditionalParameters = New Structure;

	MailingRecipientType = ?(Form.BulkEmailType = "Personal", Undefined, Form.MailingRecipientType);
	ReportMailingOverridable.OnDefineEmailTextParameters(Form.BulkEmailType,
		MailingRecipientType, EmailTextAdditionalParameters);

	If EmailTextAdditionalParameters.Count() = 0 Then
		Return;
	EndIf;

	For Each TextParameter In EmailTextAdditionalParameters Do

		CommandName        = "AddLayout" + StrReplace(Title(TextParameter.Key), Chars.NBSp, "");
		Command           = Form.Commands.Add(CommandName);
		Command.Title = TextParameter.Value;
		Command.ToolTip = TextParameter.Value;
		Command.Action  = "Attachable_AddEmailTextAdditionalParameter";
		
		GroupParameters = Form.Items.EmailTextAddTemplateParameter;
		ButtonNameText = "AddLayout" + CommandName;
		Button = Form.Items.Add(ButtonNameText, Type("FormButton"), GroupParameters);
		Button.Title  = TextParameter.Value;
		Button.CommandName = CommandName;
		Form.Items.Move(Button, GroupParameters, Form.Items.AddDefaultTemplate);
		
		GroupParameters = Form.Items.EmailTextFormattedDocumentAddTemplateParameters;
		HTMLButtonName = "EmailTextFormattedDocumentAddTemplate" + CommandName;
		Button = Form.Items.Add(HTMLButtonName, Type("FormButton"), GroupParameters);
		Button.Title  = TextParameter.Value;
		Button.CommandName = CommandName;
		
		Form.Items.Move(Button, GroupParameters, Form.Items.EmailTextFormattedDocumentAddDefaultTemplate);

		GroupParameters = Form.Items.EmailSubjectContextMenuSubmenuParameter;
		ButtonNameContextMenuSubject = "EmailSubjectContextMenuAddTemplate" + CommandName;
		Button = Form.Items.Add(ButtonNameContextMenuSubject, Type("FormButton"), GroupParameters);
		Button.Title  = TextParameter.Value;
		Button.CommandName = CommandName;
		Form.Items.Move(Button, GroupParameters, Form.Items.EmailSubjectContextMenuAddDefaultTemplate);
		
		ParameterDetails = New Structure();
		ParameterDetails.Insert("Name", TextParameter.Key);
		ParameterDetails.Insert("Presentation", TextParameter.Value);
		ParameterDetails.Insert("CommandName", CommandName);
		ParameterDetails.Insert("TextButtonName", ButtonNameText);
		ParameterDetails.Insert("HTMLButtonName", HTMLButtonName);
		ParameterDetails.Insert("SubjectButtonName", ButtonNameContextMenuSubject);
		
		Form.EmailTextAdditionalParameters.Insert(CommandName, ParameterDetails);
	EndDo;

EndProcedure

Function ReportDistributionProgressText(DeliveryParameters, SentCount, QuantityToSend)
	
	If DeliveryParameters.UseNetworkDirectory Then
		Text = NStr("vi = 'Đang gửi báo cáo hàng loạt.
			|Báo cáo được đặt vào thư mục mạng %1 từ %2.
			|Xin vui lòng đợi...';
			|ru = 'Выполняется рассылка отчетов.
			|Отчеты помещены в сетевой каталог %1 из %2.
			|Пожалуйста, подождите...';
			|en = 'Distributing the reports.
			|Reports placed to the network directory: %1 out of %2.
			|Please wait…'; fa = 'Distributing the reports.
			|Reports placed to the network directory: %1 out of %2.
			|Please wait…';
			|it = 'Выполняется рассылка отчетов.
			|Отчеты помещены в сетевой каталог %1 из %2.
			|Пожалуйста, подождите...';
			|pl = 'Distributing the reports.
			|Reports placed to the network directory: %1 out of %2.
			|Please wait…';
			|tr = 'Rapor bültenleri gerçekleştirilmektedir.
			|Raporlar %2 üzerindeki %1 ağ dizinine yerleştirildi.
			|Lütfen bekleyin...'");
	ElsIf DeliveryParameters.UseFTPResource Then
		Text = NStr("vi = 'Đang gửi báo cáo hàng loạt.
			|Báo cáo đã được đăng tải trên FTP %1 từ %2.
			|Xin vui lòng đợi...';
			|ru = 'Выполняется рассылка отчетов.
			|Отчеты опубликованы на FTP %1 из %2.
			|Пожалуйста, подождите...';
			|en = 'Distributing the reports.
			|Reports published on FTP: %1 out of %2.
			|Please wait...'; fa = 'Distributing the reports.
			|Reports published on FTP: %1 out of %2.
			|Please wait...';
			|it = 'Выполняется рассылка отчетов.
			|Отчеты опубликованы на FTP %1 из %2.
			|Пожалуйста, подождите...';
			|pl = 'Distributing the reports.
			|Reports published on FTP: %1 out of %2.
			|Please wait...';
			|tr = 'Rapor bültenleri gerçekleştirilmektedir.
			|Raporlar %2 üzerindeki %1 FTP''de yayınlandı.
			|Lütfen bekleyin...'");
	Else 
		Text = NStr("vi = 'Đang gửi báo cáo hàng loạt.
			|Đã gửi %1 trong số %2.
			|Xin vui lòng đợi...';
			|ru = 'Выполняется рассылка отчетов.
			|Отправлено %1 из %2.
			|Пожалуйста, подождите...';
			|en = 'Distributing the reports.
			|Sent %1 out of %2.
			|Please wait...'; fa = 'Distributing the reports.
			|Sent %1 out of %2.
			|Please wait...';
			|it = 'Выполняется рассылка отчетов.
			|Отправлено %1 из %2.
			|Пожалуйста, подождите...';
			|pl = 'Distributing the reports.
			|Sent %1 out of %2.
			|Please wait...';
			|tr = 'Rapor bültenleri gerçekleştirilmektedir.
			|%2 üzerindeki %1 gönderildi.
			|Lütfen bekleyin...'");
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(Text,
		Format(SentCount, "NZ=0; NG="),
		Format(QuantityToSend, "NZ=0; NG=")); 
	
EndFunction

Function IsMemberOfPersonalReportGroup(Group) Export
	
	PersonalMailingsGroup = Catalogs.ReportMailings.PersonalMailings;
	
	If Not ValueIsFilled(Group) Then
		Return False;
	ElsIf Group = PersonalMailingsGroup Then	
		Return True;
	EndIf;
	
	Return Group.BelongsToItem(PersonalMailingsGroup);
	
EndFunction

Function GetReportDistributionState(BulkEmail) Export
	
	MailoutStatus = New Structure;
	MailoutStatus.Insert("BulkEmail", Catalogs.ReportMailings.EmptyRef());
	MailoutStatus.Insert("LastRunStart", Date(1, 1, 1));
	MailoutStatus.Insert("LastRunCompletion", Date(1, 1, 1));
	MailoutStatus.Insert("SuccessfulStart", Date(1, 1, 1));
	MailoutStatus.Insert("Executed", False);
	MailoutStatus.Insert("WithErrors", False);
	MailoutStatus.Insert("SessionNumber", 0);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ReportMailingStates.BulkEmail AS BulkEmail,
		|	ReportMailingStates.LastRunStart AS LastRunStart,
		|	ReportMailingStates.LastRunCompletion AS LastRunCompletion,
		|	ReportMailingStates.SuccessfulStart AS SuccessfulStart,
		|	ReportMailingStates.Executed AS Executed,
		|	ReportMailingStates.WithErrors AS WithErrors,
		|	ReportMailingStates.SessionNumber AS SessionNumber
		|INTO TT_MailoutStatus
		|FROM
		|	InformationRegister.ReportMailingStates AS ReportMailingStates
		|WHERE
		|	ReportMailingStates.BulkEmail = &ReportMailing
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReportsDistributionHistory.Recipient AS Recipient,
		|	ReportsDistributionHistory.EMAddress AS EMAddress,
		|	MAX(ReportsDistributionHistory.Executed) AS Executed,
		|	TT_MailoutStatus.BulkEmail AS BulkEmail
		|INTO TT_Recipients
		|FROM
		|	TT_MailoutStatus AS TT_MailoutStatus
		|		INNER JOIN InformationRegister.ReportsDistributionHistory AS ReportsDistributionHistory
		|		ON TT_MailoutStatus.BulkEmail = ReportsDistributionHistory.ReportMailing
		|			AND TT_MailoutStatus.LastRunStart = ReportsDistributionHistory.StartDistribution
		|			AND TT_MailoutStatus.SessionNumber = ReportsDistributionHistory.SessionNumber
		|WHERE
		|	ReportsDistributionHistory.ReportMailing = &ReportMailing
		|	AND ReportsDistributionHistory.EMAddress <> """"
		|
		|GROUP BY
		|	ReportsDistributionHistory.Recipient,
		|	ReportsDistributionHistory.EMAddress,
		|	TT_MailoutStatus.BulkEmail
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT_Recipients.BulkEmail AS BulkEmail,
		|	COUNT(DISTINCT TT_Recipients.EMAddress) AS Count
		|INTO TT_Undelivered
		|FROM
		|	TT_Recipients AS TT_Recipients
		|WHERE
		|	NOT TT_Recipients.Executed
		|
		|GROUP BY
		|	TT_Recipients.BulkEmail
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT_MailoutStatus.BulkEmail AS BulkEmail,
		|	TT_MailoutStatus.LastRunStart AS LastRunStart,
		|	TT_MailoutStatus.LastRunCompletion AS LastRunCompletion,
		|	TT_MailoutStatus.SuccessfulStart AS SuccessfulStart,
		|	TT_MailoutStatus.Executed AS Executed,
		|	TT_MailoutStatus.SessionNumber AS SessionNumber,
		|	CASE
		|		WHEN ISNULL(TT_Undelivered.Count, 0) = 0
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS WithErrors
		|FROM
		|	TT_MailoutStatus AS TT_MailoutStatus
		|		LEFT JOIN TT_Undelivered AS TT_Undelivered
		|		ON TT_MailoutStatus.BulkEmail = TT_Undelivered.BulkEmail";
	
	Query.SetParameter("ReportMailing", BulkEmail);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		FillPropertyValues(MailoutStatus, Selection);
	EndIf;
	
	Return MailoutStatus;
	
EndFunction

Procedure ResendByEmail(ReportsTable, DeliveryParameters, BulkEmail, LogParameters)
	
	If Not DeliveryParameters.UseEmail Or DeliveryParameters.Personal Or DeliveryParameters.NotifyOnly Then
		Return;
	EndIf;
	
	RecordManager = InformationRegisters.ReportMailingStates.CreateRecordManager();
	RecordManager.BulkEmail = BulkEmail;
	RecordManager.Read();
	
	If RecordManager.SessionNumber <> InfoBaseSessionNumber() Then
		Return;
	EndIf;
	
	RedistributionRecipients = ReportRedistributionRecipients(BulkEmail,
		RecordManager.LastRunStart, RecordManager.SessionNumber);
	
	If RedistributionRecipients.Count() = 0 Then
		Return;
	EndIf;
	
	DeliveryParameters.Recipients = RedistributionRecipients;
	DeliveryParameters.UseFolder = False;
	DeliveryParameters.UseNetworkDirectory = False;
	DeliveryParameters.UseFTPResource = False;
	DeliveryParameters.RecipientReportsPresentation = "";
	DeliveryParameters.Recipient = Undefined;
	DeliveryParameters.Images = New Structure;
	DeliveryParameters.EmailParameters.Attachments = New Map;

	LogRecord(LogParameters,
		EventLogLevel.Note,
		NStr("vi = 'Gửi lại vào email.';
			|ru = 'Повторная доставка на электронную почту.';
			|en = 'Resend the reports by email.'; fa = 'Resend the reports by email.';
			|it = 'Повторная доставка на электронную почту.';
			|pl = 'Resend the reports by email.';
			|tr = 'E-postaya yeniden dağıtım.'"));

	ExecuteBulkEmail(ReportsTable, DeliveryParameters, BulkEmail, LogParameters);
	
EndProcedure

Function RunReportsGeneration(Var_Reports, DeliveryParameters, MailingDescription, LogParameters) 

	RunInMultipleThreads = FileSystem.SharedDirectoryOfTemporaryFiles() <> TempFilesDir();
	
	If RunInMultipleThreads Then
		Return GenerateReportsInMultipleThreads(Var_Reports, DeliveryParameters, MailingDescription, LogParameters);
	Else
		WriteToLog = Common.CommonSettingsStorageLoad("ReportMailings",
			"ShouldLogReportDistributionAccelerationPrompt", True);
		If Not Common.FileInfobase() And Not Common.DataSeparationEnabled() And WriteToLog Then
			LogRecord(LogParameters, EventLogLevel.Information, NStr(
				"vi = 'Việc gửi báo cáo có thể hoạt động nhanh hơn. Để gửi báo cáo hàng loạt theo nhiều luồng, cần chỉ định thư mục tệp tạm thời của cụm máy chủ 1C:Enterprise.';
				|ru = 'Рассылки отчетов могут работать быстрее. Для рассылки отчетов в несколько потоков необходимо указать каталог временных файлов кластера серверов 1С:Предприятие.';
				|en = 'Reports can be sent faster. To send reports in multiple threads, specify a directory of temporary files of the 1C:Enterprise server cluster.'; fa = 'Reports can be sent faster. To send reports in multiple threads, specify a directory of temporary files of the 1C:Enterprise server cluster.';
				|it = 'Рассылки отчетов могут работать быстрее. Для рассылки отчетов в несколько потоков необходимо указать каталог временных файлов кластера серверов 1С:Предприятие.';
				|pl = 'Reports can be sent faster. To send reports in multiple threads, specify a directory of temporary files of the 1C:Enterprise server cluster.';
				|tr = 'Rapor bültenleri daha hızlı çalışabilir. Raporların birkaç akış halinde dağıtımı için 1C:Enterprise sunucu kümesinin geçici dosyalar dizinini belirtmeniz gerekmektedir.'"));
			Common.CommonSettingsStorageSave("ReportMailings", "ShouldLogReportDistributionAccelerationPrompt", False);
		EndIf;
		
		Return RunReportsGenerationInSingleThread(Var_Reports, DeliveryParameters, MailingDescription, LogParameters);
	EndIf;

EndFunction 

Function RunReportsGenerationInSingleThread(Var_Reports, DeliveryParameters, MailingDescription, LogParameters)

	// Add a tree of generated reports  - spreadsheet document and reports saved in formats (of files).
	ReportsTree = CreateReportsTree();
	
	// Row of the general (not personalized by recipients) reports tree.
	DeliveryParameters.GeneralReportsRow = DefineTreeRowForRecipient(ReportsTree, Undefined, DeliveryParameters);
	
	For Each RowReport In Var_Reports Do
		LogText = NStr("vi = 'Đang lập báo cáo ''%1''...';
						|ru = 'Отчет ''%1'' формируется...';
						|en = 'Generating report: %1'; fa = 'Generating report: %1';
						|it = 'Отчет ''%1'' формируется...';
						|pl = 'Generating report: %1';
						|tr = '''%1'' raporu oluşturuluyor...'");
		If RowReport.Settings = Undefined Then
			LogText = LogText + Chars.LF + NStr("vi = '(chưa đặt tùy chỉnh tự tạo)';
												|ru = '(пользовательские настройки не заданы)';
												|en = '(user settings are not set)'; fa = '(user settings are not set)';
												|it = '(impostazioni utente non configurate)';
												|pl = '(ustawienia użytkownika nie są skonfigurowane)';
												|tr = '(kullanıcı ayarları ayarlanmadı)'");
		EndIf;
		
		ReportPresentation = String(RowReport.Report);
		
		LogRecord(LogParameters,
			EventLogLevel.Note,
			StringFunctionsClientServer.SubstituteParametersToString(LogText, ReportPresentation));
		
		// Initialize report.
		ReportParameters = New Structure("Report, Settings, Formats, SendIfEmpty, DescriptionTemplate");
		FillPropertyValues(ReportParameters, RowReport);
		If Not InitializeReport(LogParameters, ReportParameters, DeliveryParameters.Personalized) Then
			Continue;
		EndIf;
		
		If DeliveryParameters.Personalized And Not ReportParameters.IsPersonalized Then
			ReportParameters.Errors = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể lập báo cáo ''%1'', bởi vì trong tùy chỉnh báo cáo chưa chỉ ra bộ lọc theo người nhận hàng loạt.';
					|ru = 'Отчет ''%1'' не может сформирован, так как в его настройках не указан отбор по получателю рассылки.';
					|en = 'Cannot generate report ""%1"". Recipient is required.'; fa = 'Cannot generate report ""%1"". Recipient is required.';
					|it = 'Il report ''%1'' non può essere generato perché nelle impostazioni non è indicata la selezione per destinatario di invio massivo.';
					|pl = 'Raport ""%1"" nie może zostać utworzony, ponieważ w jego ustawieniach nie wybrano odbiorców rozsyłki.';
					|tr = '''%1'' raporu, ayarlarında e-posta listesinin alıcısının seçimini belirtmediğinden oluşturulamıyor.'"),
				ReportPresentation);
			
			LogRecord(LogParameters, EventLogLevel.Error, ReportParameters.Errors);
			Return Undefined;
		EndIf;
		
		// Generate spreadsheet documents and save in formats.
		Try
			If ReportParameters.IsPersonalized Then
				// Broken down by recipients.
				For Each KeyAndValue In DeliveryParameters.Recipients Do
					GenerateAndSaveReport(
						LogParameters,
						ReportParameters,
						ReportsTree,
						DeliveryParameters,
						KeyAndValue.Key);
				EndDo;
			Else
				// Without personalization.
				GenerateAndSaveReport(
					LogParameters,
					ReportParameters,
					ReportsTree,
					DeliveryParameters,
					Undefined);
			EndIf;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã lập thành công báo cáo ''%1''.';
					|ru = 'Отчет ''%1'' успешно сформирован.';
					|en = 'The ""%1"" report is successfully generated.'; fa = 'The ""%1"" report is successfully generated.';
					|it = 'Отчет ''%1'' успешно сформирован.';
					|pl = 'The ""%1"" report is successfully generated.';
					|tr = '''%1'' raporu başarıyla oluşturuldu.'"), ReportPresentation);
			
			LogRecord(LogParameters, EventLogLevel.Note, MessageText);
		Except
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa lập báo cáo ''%1'':';
					|ru = 'Отчет ''%1'' не сформирован:';
					|en = 'Report ""%1"" was not generated:'; fa = 'Report ""%1"" was not generated:';
					|it = 'Il report ''%1'' non è stato generato:';
					|pl = 'Raport ''%1'' nie został utworzony:';
					|tr = '''%1'' raporu oluşturulamadı:'"), ReportPresentation);
			
			LogRecord(LogParameters, , MessageText, ErrorProcessing.DetailErrorDescription(
				ErrorInfo()));
		EndTry;
	EndDo;
	
	Return ReportsTree;
	
EndFunction 

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure AddToToDoListSetTempFilesDirectory(ToDoList)
	
	If Not Users.IsFullUser() 
	   Or Common.FileInfobase()
	   Or FileSystem.SharedDirectoryOfTemporaryFiles() <> TempFilesDir()
	   Or Common.DataSeparationEnabled()
	   Or Not Common.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		Return;
	EndIf;
	
	ToDoName = "ReportDistributionsCanBeAccelerated";
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If ModuleToDoListServer.UserTaskDisabled(ToDoName) Then
		Return;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT
	|	ReportMailings.Ref AS Ref
	|FROM
	|	Catalog.ReportMailings AS ReportMailings
	|WHERE
	|	NOT ReportMailings.IsFolder";

	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;

	Sections = ModuleToDoListServer.SectionsForObject(Metadata.Catalogs.ReportMailings.FullName());
	For Each Section In Sections Do
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = ToDoName + StrReplace(Section.FullName(), ".", "");
		ToDoItem.HasToDoItems       = True;
		ToDoItem.Presentation  = NStr("vi = 'Gửi báo cáo hàng loạt có thể hoạt động nhanh hơn';
										|ru = 'Рассылки отчетов могут работать быстрее';
										|en = 'Reports can be sent faster'; fa = 'گزارش‌ها را می‌توان سریع‌تر ارسال کرد';
										|it = 'Рассылки отчетов могут работать быстрее';
										|pl = 'Reports can be sent faster';
										|tr = 'Rapor bültenleri daha hızlı çalışabilir'");
		ToDoItem.Owner       = Section;
		ToDoItem.ToolTip  = NStr("vi = 'Để gửi báo cáo hàng loạt theo nhiều luồng, cần chỉ định thư mục tệp tạm thời của cụm máy chủ 1C:Enterprise.';
								|ru = 'Для рассылки отчетов в несколько потоков необходимо указать каталог временных файлов кластера серверов 1С:Предприятие.';
								|en = 'To send reports in multiple threads, specify a directory of temporary files of the 1C:Enterprise server cluster.'; fa = 'برای ارسال گزارش‌ها در چند رشته، پوشه فایل‌های موقت کلاستر سرور 1C:Enterprise را مشخص کنید.';
								|it = 'Для рассылки отчетов в несколько потоков необходимо указать каталог временных файлов кластера серверов 1С:Предприятие.';
								|pl = 'To send reports in multiple threads, specify a directory of temporary files of the 1C:Enterprise server cluster.';
								|tr = 'Raporların birkaç akış halinde dağıtımı için 1C:Enterprise sunucu kümesinin geçici dosyalar dizinini belirtmeniz gerekmektedir.'");	
		If Common.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
			AppSettingsModule = Common.CommonModule("ApplicationSettings");
			ToDoItem.Form = AppSettingsModule.CommonSettingsFormName();
		EndIf;
	EndDo;

EndProcedure

Procedure DeleteTempFiles(Val Path, LogParameters)
	
	Try
		DeleteFiles(Path);
	Except
		LogRecord(LogParameters, EventLogLevel.Warning,
		StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xóa tệp tạm thời""%1"" do nguyên nhân: 
					|%2';
					|ru = 'Не удалось удалить временный файл ""%1"" по причине:
					|%2';
					|en = 'Cannot delete temporary file %1. Reason:
					|%2'; fa = 'Cannot delete temporary file %1. Reason:
					|%2';
					|it = 'Non è stato possibile eliminare il file temporaneo ""%1"" a causa di: 
					|%2';
					|pl = 'Nie udało się usunąć tymczasowy plik ""%1"" z powodu:
					|%2';
					|tr = '%1 geçici dosyası silinemiyor. Nedeni:
					|%2'"),
				Path,
				ErrorProcessing.DetailErrorDescription(ErrorInfo())));
	EndTry;
	
EndProcedure

Procedure DeliverToNetworkDirectory(LogParameters, DeliveryParameters, Attachments, Result)
	
	TestMode = CommonClientServer.StructureProperty(DeliveryParameters, "TestMode", False);

	ServerNetworkDdirectory = DeliveryParameters.NetworkDirectoryWindows;

	If Common.IsLinuxServer() Then
		ServerNetworkDdirectory = DeliveryParameters.NetworkDirectoryLinux;
	EndIf;

	AllRecipients = GenerateArrayOfDistributionRecipients(LogParameters.Data, LogParameters);
	
	Try
		SentCount = 0;
		QuantityToSend = Attachments.Count();
		For Each Attachment In Attachments Do
			CopyFile(Attachment.Value, ServerNetworkDdirectory + Attachment.Key);
			If DeliveryParameters.AddReferences <> "" Then
				DeliveryParameters.RecipientReportsPresentation = StrReplace(
						DeliveryParameters.RecipientReportsPresentation, Attachment.Value,
					DeliveryParameters.NetworkDirectoryWindows + Attachment.Key);
			EndIf;
			SentCount = SentCount + 1;
			ProgressText = ReportDistributionProgressText(DeliveryParameters, SentCount,
				QuantityToSend);
			ProgressPercent = Round(SentCount * 100 / QuantityToSend);
			TimeConsumingOperations.ReportProgress(ProgressPercent, ProgressText);
		EndDo;
		Result = True;
		DeliveryParameters.ExecutedToNetworkDirectory = True;

		If TestMode Then // Remove all created items.
			For Each Attachment In Attachments Do
				DeleteFiles(ServerNetworkDdirectory + Attachment.Key);
			EndDo;
		EndIf;
		
		IsDeliveryCompleted = True;
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"vi = 'Đã sắp xếp báo cáo vào thư mục mạng ''%1'':';
			|ru = 'Отчеты помещены в сетевой каталог ''%1''.';
			|en = 'Report distributions are placed in the ''%1'' network directory.'; fa = 'Report distributions are placed in the ''%1'' network directory.';
			|it = 'Отчеты помещены в сетевой каталог ''%1''.';
			|pl = 'Report distributions are placed in the ''%1'' network directory.';
			|tr = 'Raporlar ''%1'' dijital kataloğuna yerleştirildi.'"), ServerNetworkDdirectory);

	Except
		IsDeliveryCompleted = False;
		MessageText = ErrorMessageTemplate();
		LogRecord(LogParameters,, MessageText, ErrorInfo());
	EndTry;
	
	If GetFunctionalOption("RetainReportDistributionHistory") And TypeOf(LogParameters.Data) = Type(
		"CatalogRef.ReportMailings") Then
		
		For Each Recipient In AllRecipients Do
			HistoryFields = ReportDistributionHistoryFields(LogParameters.Data, Recipient,
				DeliveryParameters.ExecutionDate);
			HistoryFields.Account = DeliveryParameters.Account;
			HistoryFields.Comment = MessageText;
			HistoryFields.Executed = IsDeliveryCompleted;
			HistoryFields.DeliveryDate = ?(IsDeliveryCompleted, CurrentSessionDate(), Date(1,1,1));
			HistoryFields.MethodOfObtaining = DistributionReceiptMethod(DeliveryParameters, Recipient);

			InformationRegisters.ReportsDistributionHistory.CommitResultOfDistributionToRecipient(HistoryFields);
		EndDo;
	EndIf;

EndProcedure

Procedure DeliverToFTPResource(LogParameters, DeliveryParameters, Attachments, Result)

	TestMode = CommonClientServer.StructureProperty(DeliveryParameters, "TestMode", False);

	Target = "ftp://" + DeliveryParameters.Server + ":" + Format(DeliveryParameters.Port, "NZ=0; NG=0")
		+ DeliveryParameters.Directory;
	AllRecipients = GenerateArrayOfDistributionRecipients(LogParameters.Data, LogParameters);
	
	Try
		If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
			ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
			Proxy = ModuleNetworkDownload.GetProxy("ftp");
		Else
			Proxy = Undefined;
		EndIf;
		If DeliveryParameters.Property("Password") Then
			Password = DeliveryParameters.Password;
		Else
			SetPrivilegedMode(True);
			DataFromStorage = Common.ReadDataFromSecureStorage(DeliveryParameters.Owner,
				"FTPPassword");
			SetPrivilegedMode(False);
			Password = ?(ValueIsFilled(DataFromStorage), DataFromStorage, "");
		EndIf;
		Join = New FTPConnection(DeliveryParameters.Server, DeliveryParameters.Port, DeliveryParameters.Login,
			Password, Proxy, DeliveryParameters.PassiveConnection, 15);
		Join.SetCurrentDirectory(DeliveryParameters.Directory);
		SentCount = 0;
		QuantityToSend = Attachments.Count();
		For Each Attachment In Attachments Do
			Join.Put(Attachment.Value, DeliveryParameters.Directory + Attachment.Key);
			If DeliveryParameters.AddReferences <> "" Then
				DeliveryParameters.RecipientReportsPresentation = StrReplace(
						DeliveryParameters.RecipientReportsPresentation, Attachment.Value, Target + Attachment.Key);
				SentCount = SentCount + 1;
				ProgressText = ReportDistributionProgressText(DeliveryParameters, SentCount,
					QuantityToSend);
				ProgressPercent = Round(SentCount * 100 / QuantityToSend);
				TimeConsumingOperations.ReportProgress(ProgressPercent, ProgressText);
			EndIf;
		EndDo;

		Result = True;
		DeliveryParameters.ExecutedAtFTP = True;

		If TestMode Then // Remove all created items.
			For Each Attachment In Attachments Do
				Join.Delete(DeliveryParameters.Directory + Attachment.Key);
			EndDo;
		EndIf;
		
		IsDeliveryCompleted = True;
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"vi = 'Đã đăng tải báo cáo trên ''%1''.';
				|ru = 'Отчеты опубликованы на ''%1''.';
				|en = 'Report distributions published on ''%1''.'; fa = 'Report distributions published on ''%1''.';
				|it = 'Отчеты опубликованы на ''%1''.';
				|pl = 'Report distributions published on ''%1''.';
				|tr = 'Raporlar ''%1'' kısmında yayınlandı.'"), Target);
				
	Except
		IsDeliveryCompleted = False;
		MessageText = ErrorMessageTemplate();
		If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
			ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
			DiagnosticsResult = ModuleNetworkDownload.ConnectionDiagnostics(DeliveryParameters.Server);
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1
						 |
						 |Kết quả chẩn đoán:
						 |%2';
						 |ru = '%1
						 |
						 |Результат диагностики:
						 |%2';
						 |en = '%1
						 |
						 |Diagnostics result:
						 |%2'; fa = '%1
						 |
						 |Diagnostics result:
						 |%2';
						 |it = '%1
						 |
						 |Результат диагностики:
						 |%2';
						 |pl = '%1
						 |
						 |Diagnostics result:
						 |%2';
						 |tr = '%1
						 |
						 |Tanılama sonucu:
						 |%2'"), MessageText, DiagnosticsResult.ErrorDescription);
		EndIf;
		
		LogRecord(LogParameters,, MessageText, ErrorInfo());
	EndTry;
	
	If GetFunctionalOption("RetainReportDistributionHistory") And TypeOf(LogParameters.Data) = Type(
			"CatalogRef.ReportMailings") Then
		
		For Each Recipient In AllRecipients Do
			HistoryFields = ReportDistributionHistoryFields(LogParameters.Data, Recipient,
				DeliveryParameters.ExecutionDate);
			HistoryFields.Account = DeliveryParameters.Account;
			HistoryFields.Comment = MessageText;
			HistoryFields.Executed = IsDeliveryCompleted;
			HistoryFields.DeliveryDate = ?(IsDeliveryCompleted, CurrentSessionDate(), Date(1,1,1));
			HistoryFields.MethodOfObtaining = DistributionReceiptMethod(DeliveryParameters, Recipient);

			InformationRegisters.ReportsDistributionHistory.CommitResultOfDistributionToRecipient(HistoryFields);
		EndDo;
	EndIf;

EndProcedure

Procedure DeliverToFolder(LogParameters, DeliveryParameters, Attachments, Result)

	If Not Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		Return;
	EndIf;
	
	TestMode = CommonClientServer.StructureProperty(DeliveryParameters, "TestMode", False);

	AllRecipients = GenerateArrayOfDistributionRecipients(LogParameters.Data, LogParameters);

	ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
	Try
		ModuleFilesOperationsInternal.OnExecuteDeliveryToFolder(DeliveryParameters, Attachments);
		Result = True;
		DeliveryParameters.ExecutedToFolder = True;
		
		IsDeliveryCompleted = True;
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"vi = 'Đã sắp xếp các báo cáo vào thư mục ''%1''.';
			|ru = 'Отчеты помещены в папку ''%1''.';
			|en = 'Report distributions are placed in the ''%1'' folder.'; fa = 'Report distributions are placed in the ''%1'' folder.';
			|it = 'Отчеты помещены в папку ''%1''.';
			|pl = 'Report distributions are placed in the ''%1'' folder.';
			|tr = 'Raporlar ''%1'' klasörüne yerleştirildi.'"), String(DeliveryParameters.Folder));

	Except
		IsDeliveryCompleted = False;
		MessageText = ErrorMessageTemplate();
		LogRecord(LogParameters,, MessageText, ErrorInfo());
	EndTry;

	If GetFunctionalOption("RetainReportDistributionHistory") And TypeOf(LogParameters.Data) = Type(
		"CatalogRef.ReportMailings") Then

		For Each Recipient In AllRecipients Do
			HistoryFields = ReportDistributionHistoryFields(LogParameters.Data, Recipient,
				DeliveryParameters.ExecutionDate);
			HistoryFields.Account = DeliveryParameters.Account;
			HistoryFields.Comment = MessageText;
			HistoryFields.Executed = IsDeliveryCompleted;
			HistoryFields.DeliveryDate = ?(IsDeliveryCompleted, CurrentSessionDate(), Date(1,1,1));
			HistoryFields.MethodOfObtaining = DistributionReceiptMethod(DeliveryParameters, Recipient);

			InformationRegisters.ReportsDistributionHistory.CommitResultOfDistributionToRecipient(
				HistoryFields);
		EndDo;
	EndIf;

EndProcedure

Procedure DeliverByEmail(LogParameters, DeliveryParameters, Attachments, Result)
	
	ErrorMessageTemplate = ErrorMessageTemplate();
	TestMode = CommonClientServer.StructureProperty(DeliveryParameters, "TestMode", False);
	
	If DeliveryParameters.NotifyOnly Then
		ErrorMessageTemplate = NStr("vi = 'Không thể gửi thông báo về giao dịch gửi hàng loạt qua email:';
									|ru = 'Невозможно отправить уведомление о рассылке по электронной почте:';
									|en = 'Cannot send report distribution notification by email:'; fa = 'Cannot send report distribution notification by email:';
									|it = 'Impossibile inviare la notifica di email massive per posta elettronica:';
									|pl = 'Niemożliwie wysłać powiadomienie o wysyłce pocztą elektroniczną:';
									|tr = 'Bülten bildirimi e-posta ile gönderilemedi:'");
		EmailAttachments1 = New Map;
	ElsIf Not DeliveryParameters.ShouldAttachReports Then
		EmailAttachments1 = New Map;
	Else
		ErrorMessageTemplate = NStr("vi = 'Không thể gửi báo cáo qua email:';
									|ru = 'Невозможно отправить отчет по электронной почте:';
									|en = 'Cannot send report by email:'; fa = 'Cannot send report by email:';
									|it = 'Impossibile inviare il report per posta elettronica:';
									|pl = 'Niemożliwie wysłać raport pocztą elektroniczną:';
									|tr = 'E-posta ile gönderilemedi:'");
		EmailAttachments1 = Attachments;
	EndIf;

	AreReportsSent = False;
	Try
		SendReportsToRecipient(EmailAttachments1, DeliveryParameters, LogParameters);
		AreReportsSent = True;
	Except
		ErrorInfo = ErrorInfo();
			
		ExtendedErrorPresentation = EmailOperations.ExtendedErrorPresentation(
				ErrorInfo, Common.DefaultLanguageCode(), False, DeliveryParameters.Account);
		LogRecord(LogParameters, EventLogLevel.Error, ErrorMessageTemplate,
			ExtendedErrorPresentation);
		
		If GetFunctionalOption("RetainReportDistributionHistory") And Not EmailClientUsed() And TypeOf(
			LogParameters.Data) = Type("CatalogRef.ReportMailings") Then
			Comment = StringFunctionsClientServer.SubstituteParametersToString(
				"%1 %2", ErrorMessageTemplate, ExtendedErrorPresentation);
			For Each RecipientRow In DeliveryParameters.Recipients Do
				RecipientAddresses = CommonClientServer.ParseStringWithEmailAddresses(
					RecipientRow.Value);
				RecordUnsuccessfulDistributionResult(DeliveryParameters, LogParameters, RecipientRow.Key,
					RecipientAddresses, Comment);
			EndDo;
		EndIf;
	EndTry;
	
	If AreReportsSent Then
		If Not DeliveryParameters.NotifyOnly Then
			Result = True;
		EndIf;
		DeliveryParameters.ExecutedByEmail = Result;
    EndIf;
	
EndProcedure

Function ErrorMessageTemplate()
	Return NStr("vi = 'Chưa thêm báo cáo';
				|ru = 'Отчеты не доставлены';
				|en = 'Reports are not delivered'; fa = 'Reports are not delivered';
				|it = 'I report non sono stati consegnati';
				|pl = 'Nie dostarcyono raportów';
				|tr = 'Raporlar teslim edilmedi'");
EndFunction

#EndRegion

#Region MultiThreadedReportGeneration

Function GenerateReportsInMultipleThreads(Var_Reports, DeliveryParameters, MailingDescription, LogParameters)
	
	PersonalizedReports   = New Map;
	NotPersonalizedReports = New Array;
	
	// Generate and save reports.
	ReportsNumber = 1;
	For Each RowReport In Var_Reports Do
		
		LogText = NStr("vi = 'Đang lập báo cáo ''%1''...';
						|ru = 'Отчет ''%1'' формируется...';
						|en = 'Generating report: %1'; fa = 'Generating report: %1';
						|it = 'Отчет ''%1'' формируется...';
						|pl = 'Generating report: %1';
						|tr = '''%1'' raporu oluşturuluyor...'");
		If RowReport.Settings = Undefined Then
			LogText = LogText + Chars.LF + NStr("vi = '(chưa đặt tùy chỉnh tự tạo)';
												|ru = '(пользовательские настройки не заданы)';
												|en = '(user settings are not set)'; fa = '(user settings are not set)';
												|it = '(impostazioni utente non configurate)';
												|pl = '(ustawienia użytkownika nie są skonfigurowane)';
												|tr = '(kullanıcı ayarları ayarlanmadı)'");
		EndIf;
		
		ReportPresentation = String(RowReport.Report);
		
		LogRecord(LogParameters,
			EventLogLevel.Note,
			StringFunctionsClientServer.SubstituteParametersToString(LogText, ReportPresentation));
		
		// Initialize report.
		ReportParameters = New Structure("Report, Settings, Formats, SendIfEmpty, DescriptionTemplate");
		FillPropertyValues(ReportParameters, RowReport);
		If Not InitializeReport(LogParameters, ReportParameters, DeliveryParameters.Personalized) Then
			Continue;
		EndIf;
		
		If DeliveryParameters.Personalized And Not ReportParameters.IsPersonalized Then
			ReportParameters.Errors = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể lập báo cáo ''%1'', bởi vì trong tùy chỉnh báo cáo chưa chỉ ra bộ lọc theo người nhận hàng loạt.';
					|ru = 'Отчет ''%1'' не может сформирован, так как в его настройках не указан отбор по получателю рассылки.';
					|en = 'Cannot generate report ""%1"". Recipient is required.'; fa = 'Cannot generate report ""%1"". Recipient is required.';
					|it = 'Il report ''%1'' non può essere generato perché nelle impostazioni non è indicata la selezione per destinatario di invio massivo.';
					|pl = 'Raport ""%1"" nie może zostać utworzony, ponieważ w jego ustawieniach nie wybrano odbiorców rozsyłki.';
					|tr = '''%1'' raporu, ayarlarında e-posta listesinin alıcısının seçimini belirtmediğinden oluşturulamıyor.'"),
				ReportPresentation);
			
			LogRecord(LogParameters, EventLogLevel.Error, ReportParameters.Errors);
			Continue;
		EndIf;
		
		If ReportParameters.IsPersonalized Then
			For Each KeyAndValue In DeliveryParameters.Recipients Do
				ReportParametersStructure = New Structure("Report, Settings, Formats, SendIfEmpty, DescriptionTemplate");
				FillPropertyValues(ReportParametersStructure, RowReport);
				
				If PersonalizedReports.Get(KeyAndValue.Key) = Undefined Then
					PersonalizedReports.Insert(KeyAndValue.Key, New Array);
				EndIf;
				PersonalizedReports[KeyAndValue.Key].Add(ReportParametersStructure);
			EndDo;
			
		Else
			ReportParametersStructure = New Structure("Report, Settings, Formats, SendIfEmpty, DescriptionTemplate");
			FillPropertyValues(ReportParametersStructure, RowReport);
			
			NotPersonalizedReports.Add(ReportParametersStructure);
		EndIf;
		
	EndDo;
	
	MethodParameters = New Map;
	
	// Generate MethodParameters for personalized reports.
	For Each KeyAndValue In PersonalizedReports Do
		ParametersArray = New Array;
		ParametersArray.Add(KeyAndValue.Value);
		ParametersArray.Add(LogParameters);
		ParametersArray.Add(DeliveryParameters);
		ParametersArray.Add(KeyAndValue.Key);
		
		MethodParameters.Insert(KeyAndValue.Key, ParametersArray);
	EndDo; 
	
	If (LogParameters <> Undefined) And LogParameters.Property("Metadata") Then
		LogParameters.Metadata = LogParameters.Metadata.FullName();
	EndIf;
	
	// Augment MethodParameters with batches of non-personalized reports.
	ReportsNumber  = 0;
	PortionNumber  = 1;
	PortionSize = 2;
	Batch = New Array;
	ReportCount = NotPersonalizedReports.Count();
	For Each Report In NotPersonalizedReports Do
		Batch.Add(Report);
		ReportsNumber = ReportsNumber + 1;
		
		If ReportsNumber % PortionSize = 0 Or ReportCount = ReportsNumber Then
			ParametersArray = New Array;
			ParametersArray.Add(Batch);
			ParametersArray.Add(LogParameters);
			ParametersArray.Add(DeliveryParameters);

			MethodParameters.Insert(PortionNumber, ParametersArray);

			Batch = New Array;
			PortionNumber = PortionNumber + 1;
		EndIf;
	EndDo;

	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID());
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Gửi báo cáo hàng loạt';
														|ru = 'Рассылка отчетов';
														|en = 'Report distribution'; fa = 'توزیع گزارش';
														|it = 'Email massive dei report';
														|pl = 'Rozsyłanie raportów';
														|tr = 'Rapor bülteni'");
	ExecutionParameters.WaitCompletion = Undefined;
	
	ResultAddress = PutToTempStorage(Undefined, New UUID());
	ExecutionParameters.Insert("ResultAddress", ResultAddress);
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunctionInMultipleThreads(
		"ReportMailing.ReportsBatchGenerationResult",
		ExecutionParameters,
		MethodParameters);
	
	ReportsTree = CreateReportsTree();
	
	// Row of the general (not personalized by recipients) reports tree.
	DeliveryParameters.GeneralReportsRow = DefineTreeRowForRecipient(ReportsTree, Undefined, DeliveryParameters);
	
	AddressesOfChecksResults = GetFromTempStorage(ExecutionResult.ResultAddress);
	
	If AddressesOfChecksResults = Undefined Then
		Return ReportsTree;
	EndIf;
	
	For Each AddressValidationResult In AddressesOfChecksResults Do
		
		ResultsFromThread = GetFromTempStorage(AddressValidationResult.Value.ResultAddress);
		If TypeOf(ResultsFromThread) = Type("Structure")Then
			If ResultsFromThread.Property("ReportsTree") And TypeOf(ResultsFromThread.ReportsTree) = Type("ValueTree") Then
				AddGeneratedReportsToTree(ReportsTree, ResultsFromThread.ReportsTree);
			EndIf;
			If ResultsFromThread.Property("ReportsForEmailText") And TypeOf(ResultsFromThread.ReportsForEmailText) = Type("Map") Then
				MergeReportsForEmailTextFromMultipleThreads(DeliveryParameters, ResultsFromThread.ReportsForEmailText);
			EndIf;
		EndIf;
		
	EndDo;
	
	Return ReportsTree;
	
EndFunction

// Generates reports.
//
// Parameters: See ExecuteBulkEmail
//
// Returns:
//   Structure:
//     * ReportsTree - See CreateReportsTree
//     * ReportsForEmailText - Array of Map
//
// ACC:299-off, ACC:581-off - An export function as it's called from a background job.
//
Function ReportsBatchGenerationResult(Var_Reports, LogParameters, DeliveryParameters, Recipient = Undefined) Export
	
	LogParameters.Metadata = Common.MetadataObjectByFullName(LogParameters.Metadata);
	
	// Add a tree of generated reports  - spreadsheet document and reports saved in formats (of files).
	ReportsTree = CreateReportsTree();
	
	For Each RowReport In Var_Reports Do
		ReportPresentation = String(RowReport.Report);
		
		// Initialize report.
		ReportParameters = New Structure("Report, Settings, Formats, SendIfEmpty, DescriptionTemplate");
		FillPropertyValues(ReportParameters, RowReport);
		If Not InitializeReport(LogParameters, ReportParameters, DeliveryParameters.Personalized) Then
			Continue;
		EndIf;
		
		If DeliveryParameters.Personalized And Not ReportParameters.IsPersonalized Then
			ReportParameters.Errors = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể lập báo cáo ''%1'', bởi vì trong tùy chỉnh báo cáo chưa chỉ ra bộ lọc theo người nhận hàng loạt.';
					|ru = 'Отчет ''%1'' не может сформирован, так как в его настройках не указан отбор по получателю рассылки.';
					|en = 'Cannot generate report ""%1"". Recipient is required.'; fa = 'Cannot generate report ""%1"". Recipient is required.';
					|it = 'Il report ''%1'' non può essere generato perché nelle impostazioni non è indicata la selezione per destinatario di invio massivo.';
					|pl = 'Raport ""%1"" nie może zostać utworzony, ponieważ w jego ustawieniach nie wybrano odbiorców rozsyłki.';
					|tr = '''%1'' raporu, ayarlarında e-posta listesinin alıcısının seçimini belirtmediğinden oluşturulamıyor.'"),
				ReportPresentation);
			
			LogRecord(LogParameters, EventLogLevel.Error, ReportParameters.Errors);
			Return Undefined;
		EndIf;
		
		// Generate spreadsheet documents and save in formats.
		Try
			If ReportParameters.IsPersonalized Then
				// Individual for each of the recipient.
				GenerateAndSaveReport(
					LogParameters,
					ReportParameters,
					ReportsTree,
					DeliveryParameters,
					Recipient);
			Else
				// No personalization.
				GenerateAndSaveReport(
					LogParameters,
					ReportParameters,
					ReportsTree,
					DeliveryParameters,
					Undefined);
			EndIf;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã lập thành công báo cáo ''%1''.';
					|ru = 'Отчет ''%1'' успешно сформирован.';
					|en = 'The ""%1"" report is successfully generated.'; fa = 'The ""%1"" report is successfully generated.';
					|it = 'Отчет ''%1'' успешно сформирован.';
					|pl = 'The ""%1"" report is successfully generated.';
					|tr = '''%1'' raporu başarıyla oluşturuldu.'"), ReportPresentation);
			
			LogRecord(LogParameters, EventLogLevel.Note, MessageText);
		Except
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa lập báo cáo ''%1'':';
					|ru = 'Отчет ''%1'' не сформирован:';
					|en = 'Report ""%1"" was not generated:'; fa = 'Report ""%1"" was not generated:';
					|it = 'Il report ''%1'' non è stato generato:';
					|pl = 'Raport ''%1'' nie został utworzony:';
					|tr = '''%1'' raporu oluşturulamadı:'"), ReportPresentation);
			
			LogRecord(LogParameters, , MessageText, ErrorProcessing.DetailErrorDescription(
				ErrorInfo()));
		EndTry;
	EndDo;

	Result = New Structure;
	Result.Insert("ReportsTree", ReportsTree);
	Result.Insert("ReportsForEmailText", DeliveryParameters.ReportsForEmailText);
	
	Return Result;
	
EndFunction
// ACC:299-on, ACC:581-on

Procedure AddGeneratedReportsToTree(TreeResult, GeneratedReportsTree)
	
	For Each GeneratedReportsTreeRow In GeneratedReportsTree.Rows Do
		
		TreeRowResult = Undefined;
		
		For Each TreeRow In TreeResult.Rows Do
			If TreeRow.Value = GeneratedReportsTreeRow.Value Then
				TreeRowResult = TreeRow;
				Break;
			EndIf;
		EndDo;

		If TreeRowResult = Undefined Then
			TreeRowResult = TreeResult.Rows.Add();
			FillPropertyValues(TreeRowResult, GeneratedReportsTreeRow);
		EndIf;
		
		If GeneratedReportsTreeRow.Rows.Count() > 0 Then
			AddGeneratedReportsToTree(TreeRowResult, GeneratedReportsTreeRow);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure MergeReportsForEmailTextFromMultipleThreads(DeliveryParameters, ReportsForEmailText)
	
	For Each ReportsByUsers In ReportsForEmailText Do
		ReportsForText = DeliveryParameters.ReportsForEmailText.Get(ReportsByUsers.Key);
		
		If ReportsForText = Undefined Then
			DeliveryParameters.ReportsForEmailText.Insert(ReportsByUsers.Key, ReportsByUsers.Value);
		Else  
			For Each FileStructure In ReportsByUsers.Value Do
				ReportsForText.Add(FileStructure);
			EndDo;
		EndIf; 
	EndDo;
	
EndProcedure

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("SetReportDistributionHistoryRetentionPeriodInMonths");
	Methods.Insert("ReportsBatchGenerationResult", True);
	Methods.Insert("ClearUpReportDistributionHistoryInBackgroundJob", True);
	Methods.Insert("SendBulkEmailsInBackgroundJob", True);
	Methods.Insert("SendBulkSMSMessagesWithReportDistributionArchivePasswordsInBackgroundJob", True);
	
EndProcedure

#EndRegion