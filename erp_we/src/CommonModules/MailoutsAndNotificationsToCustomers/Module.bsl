////////////////////////////////////////////////////////////////////////////////
// Subsystem "Mailing lists and notifications to clients".
//
////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
//  It contains common server procedures and is intended for configuration, as well 
//  as the formation of messages on mailings and alerts.
//

#Region Internal

#Region AttachmentsOperations

// Generates texthtml From a formatted document before writing the object.
// Pictures of the FD will be saved as files attached to object.
//
// Parameters:
//  FormattedDocument  - FormattedDocument -  which will be converted to HTML.
//  HTMLText                - String - the resulting HTML will be saved in it.
//  EmailTextType          - EnumRef.EmailEditingMethods - to determine whether to perform conversions.
//  AttachmentsNamesToIDsMapsTable  - ValueTable - allows you to determine which attachment
//                                                                      corresponds to which image.
//
Procedure FormattedDocumentInHtml5BeforeWriting(FormattedDocument, HTMLText, EmailTextType, AttachmentsNamesToIDsMapsTable) Export

	// Prepare an HTML document from the contents of a formatted document
	If EmailTextType = Enums.EmailEditingMethods.HTML Then
		
		AttachmentsNamesToIDsMapsTable.Clear();
		
		AttachmentsStructure = New Structure;
		FormattedDocument.GetHTML(HTMLText, AttachmentsStructure);
		For Each Attachment In AttachmentsStructure Do
			
			NewRow = AttachmentsNamesToIDsMapsTable.Add();
			NewRow.FileName = Attachment.Key;
			NewRow.FileIDForHTML = New UUID;
			NewRow.Picture = Attachment.Value;
			
		EndDo;
		
		If AttachmentsNamesToIDsMapsTable.Count() > 0 Then
			
			HTMLDocument = Interactions.GetHTMLDocumentObjectFromHTMLText(HTMLText);
			Interactions.ChangePicturesNamesToMailAttachmentsIDsInHTML( HTMLDocument, AttachmentsNamesToIDsMapsTable.Unload());
			HTMLText = Interactions.GetHTMLTextFromHTMLDocumentObject(HTMLDocument);
			
		Else
			
			If IsBlankString(FormattedDocument.GetText()) Then
				HTMLText = "";
			EndIf;
			
		EndIf;
		
	EndIf;

EndProcedure

// Adds to the list of attachments to delete attachments that match the images of the message body.
//
// Parameters:
//  Ref            - DocumentRef - link to the owner of the attached files.
//  DeletedAttachments - Array - array of attachments to delete.
//
Procedure AddAttachmentsWithNonEmptyIDToListOfDeletedOnes(Ref, DeletedAttachments) Export
	
	FormattedDocumentPicturesAttachmentsTable = Interactions.GetEmailAttachmentsWithNonBlankIDs(Ref);
	For Each Attachment In FormattedDocumentPicturesAttachmentsTable Do
		DeletedAttachments.Add(Attachment.Ref);
	EndDo;
	
EndProcedure

// Deletes attachments according to the passed array of attachments.
//
// Parameters:
//  DeletedAttachments  - ValueList of CatalogRef - array of attachments to delete.
//
Procedure DeleteAttachments(DeletedAttachments) Export
	
	For Each DeletedAttachment In DeletedAttachments Do
		ObjectAttachment = DeletedAttachment.Value.GetObject(); 
		ObjectAttachment.Delete();
	EndDo;
	
	DeletedAttachments.Clear();
	
EndProcedure

// Saves the images of the formatted document as an attached file of the object.
//
// Parameters:
//  Ref                                          - DocumentRef - link to the owner of the attached files.
//  EmailTextType                                 - EnumRef.EmailEditingMethods - to determine whether to perform conversions.
//  AttachmentsNamesToIDsMapsTable  - ValueTable - allows you to determine which attachment
//                                                                      corresponds to which image.
//  UUID                         - UUID - unique ID of the form to save from.
//
Procedure SaveFormattedDocumentPicturesAsAttachedFiles(Ref,
	                                                                        EmailTextType,
	                                                                        AttachmentsNamesToIDsMapsTable,
	                                                                        UUID) Export
	
	If EmailTextType = Enums.EmailEditingMethods.HTML Then
		
		For Each Attachment In AttachmentsNamesToIDsMapsTable Do
			
			BinaryPictureData = Attachment.Picture.GetBinaryData();
			PictureAddressInTempStorage = PutToTempStorage(BinaryPictureData, UUID);
			
			AttachmentParameters = New Structure;
			AttachmentParameters.Insert("FileName", "_" + StrReplace(Attachment.FileIDForHTML, "-", "_"));
			AttachmentParameters.Insert("Size", BinaryPictureData.Size());
			AttachmentParameters.Insert("EmailFileID", Attachment.FileIDForHTML);
			
			AttachedFile = EmailManagement.WriteEmailAttachmentFromTempStorage(
			Ref,
			PictureAddressInTempStorage,
			AttachmentParameters);
			
			If AttachedFile <> Undefined Then
				AttachedFileObject = AttachedFile.GetObject(); // CatalogObject.IncomingEmailAttachedFiles
				AttachedFileObject.EmailFileID = Attachment.FileIDForHTML;
				AttachedFileObject.Write();
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Saves object attachments as attached files.
//
// Parameters:
//  Ref                   - DocumentRef - link to the owner of the attached files.
//  Attachments                 - ValueTable - the attachments table.
//  UUID  - UUID - unique ID of the form to save from.
//
Procedure SaveAttachments(Ref, Attachments, UUID) Export
	
	For Each AttachmentsTableRow In Attachments Do
		
		Size = 0;
		FileName = AttachmentsTableRow.FileName;
		
		If AttachmentsTableRow["Placement"] = 4 Then
			
			AttachmentParameters = New Structure;
			AttachmentParameters.Insert("FileName", FileName);
			AttachmentParameters.Insert("Size",Size);
			
			// from temporary storage
			AttachmentsTableRow["Ref"] = EmailManagement.WriteEmailAttachmentFromTempStorage(
							Ref, AttachmentsTableRow.FileNameOnComputer, AttachmentParameters);
			
		ElsIf AttachmentsTableRow["Placement"] = 1 Then
			
			AttachmentsTableRow["Ref"] = EmailManagement.WriteEmailAttachmentByCopyOtherEmailAttachment(
			Ref, AttachmentsTableRow["Ref"], UUID);
			
		EndIf;
		
		AttachmentsTableRow["Placement"] = 0;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ScheduledJobs

// Analyzes data for notifications to clients and writes to the notification queue.
// 
// Parameters:
//   NotificationKind - CatalogRef.CustomerNotificationKinds - The type of alert that data should be analyzed for.
//
Procedure DataAnalysisForNotificationsToCustomers(NotificationKind) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DataAnalysisForNotificationsToCustomers);
	
	If TypeOf(NotificationKind) <> Type("CatalogRef.CustomerNotificationKinds") Or NotificationKind.IsEmpty() Then
		Return;
	EndIf;
	
	Attributes = Common.ObjectAttributesValues(NotificationKind, "EventType");
	EventType = Attributes.EventType;
	
	If EventType.IsEmpty() Then
		Return;
	EndIf;
	
	Common.OnStartExecuteScheduledJob();
	
	If EventType = Enums.NotificationEventTypes.HappyBirthdayWishes Then
		DataAnalysisBirthdayGreetings(NotificationKind);
	ElsIf EventType = Enums.NotificationEventTypes.ARAPOverdue Then
		AnalysisOverdueDebt(NotificationKind);
	ElsIf EventType = Enums.NotificationEventTypes.ScheduledPayments Then
		AnalysisPlannedPayments(NotificationKind);
	ElsIf EventType = Enums.NotificationEventTypes.PlannedShipments Then
		AnalysisPlannedShipments(NotificationKind);
	ElsIf EventType = Enums.NotificationEventTypes.SurveyEnd Then
		AnalysisEndOfSurvey(NotificationKind);
	Else
		ConfigurationModificationOverridable.DataAnalysisForAlertType(NotificationKind);
	EndIf;

EndProcedure

// Generates the documents "SMS Message" and "outgoing Email" according to the data of the RS "queue of events for messages to Clients".
// The routine tasks
// "Receiving and sending emails" and "sending SMS"are responsible for sending prepared messages.
//
Procedure MessageGenerationByCustomerNotifications() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.MessageGenerationByCustomerNotifications);
	
	SetPrivilegedMode(True);
	
	RecordText = NStr("vi = 'Bắt đầu tạo tin nhắn lần lượt thông báo cho khách hàng';
						|ru = 'Начало формирования сообщений по очереди оповещений для клиентов';
						|en = 'Start generating messages according to the customer notification queue'; fa = 'Start generating messages according to the customer notification queue';
						|it = 'Inizio della creazione dei messaggi a turno degli avvisi per i clienti';
						|pl = 'Początek tworzenia wiadomości w kolejce powiadomień dla klientów';
						|tr = 'Müşteriler için bildirim mesaj sırasının oluşturulmasının başlatılması'",
	                   CommonClientServer.DefaultLanguageCode());
	
	PerformLogEntry(RecordText, EventLogLevel.Information);
	DateOfProcessing = CurrentSessionDate(); 
	
	Query = New Query;
	Query.Text = "SELECT DISTINCT
	               |	EventQueueForNotificationsToCustomers.NotificationKind AS NotificationKind
	               |FROM
	               |	InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
	               |WHERE
	               |	EventQueueForNotificationsToCustomers.Period < &DateOfProcessing";
	
	Query.SetParameter("DateOfProcessing", DateOfProcessing);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			
			ProcessMessageQueueByAlertType(Selection.NotificationKind, DateOfProcessing);
			InformationRegisters.EventQueueForNotificationsToCustomers.DeleteEntriesByNotificationTypeFromQueue(Selection.NotificationKind, DateOfProcessing);
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			RecordText = NStr("vi = 'Lỗi trong khi tạo tin nhắn cảnh báo khách hàng';
								|ru = 'Ошибка при формировании сообщений по оповещениям клиентов';
								|en = 'An error occurred while generating messages of customer notifications'; fa = 'An error occurred while generating messages of customer notifications';
								|it = 'Errore durante la formazione dei messaggi degli avvisi per i clienti';
								|pl = 'Błąd podczas tworzenia wiadomości po powiadomieniach klientów';
								|tr = 'Müşteri bildirimlerinde mesaj oluştururken hata oluştu'", CommonClientServer.DefaultLanguageCode()) + " : ";
			RecordText = RecordText + DetailErrorDescription(ErrorInfo());
			PerformLogEntry(RecordText ,EventLogLevel.Error);
			Continue;
		
		EndTry;
			
	EndDo;
	
	RecordText = NStr("vi = 'Kết thúc lập các thông báo trên thư của khách hàng';
						|ru = 'Окончание формирования сообщений по рассылкам клиентов';
						|en = 'End generating customer mailout messages'; fa = 'End generating customer mailout messages';
						|it = 'Fine della creazione dei messaggi per email massive dei clienti';
						|pl = 'Zakończenie tworzenia wiadomości po wysyłkach klientów';
						|tr = 'Müşteri dağıtımları için mesajların sonuçlandırılması'",
	                   CommonClientServer.DefaultLanguageCode());
	PerformLogEntry(RecordText ,EventLogLevel.Information);
	
EndProcedure

// Generates the "SMS message" and "outgoing Email" documents based on the "Mailing to clients"
// documents that are in the "Ready to send" status. The routine tasks
// "Receiving and sending emails" and "sending SMS"are responsible for sending prepared messages.
//
Procedure MessageGenerationForCustomerMailouts() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.MessageGenerationForCustomerMailouts);
	
	SetPrivilegedMode(True);
	
	RecordText = NStr("vi = 'Bắt đầu tạo tin nhắn thư của khách hàng';
						|ru = 'Начало формирования сообщений по рассылкам клиентов';
						|en = 'Start generating messages for customer mailouts'; fa = 'Start generating messages for customer mailouts';
						|it = 'Inizio della creazione de messaggi per email massive dei clienti';
						|pl = 'Początek tworzenia wiadomości po wysyłkach klientów';
						|tr = 'Müşteri dağıtımları için mesaj oluşturulmasının başlatılması'",
	                   CommonClientServer.DefaultLanguageCode());
	PerformLogEntry(RecordText ,EventLogLevel.Information);
	
	NumberOfProcessedMailings = 0;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	MailoutToCustomers.Ref,
	|	MailoutToCustomers.MailingDate,
	|	MailoutToCustomers.UpdateDate,
	|	MailoutToCustomers.GroupOfMailoutsAndNotifications,
	|	MailoutToCustomers.DesignedForEmails,
	|	MailoutToCustomers.DesignedForSMSMessage,
	|	MailoutToCustomers.Subject,
	|	MailoutToCustomers.EmailText,
	|	MailoutToCustomers.HTMLEmailText,
	|	MailoutToCustomers.SMSMessageText,
	|	MailoutToCustomers.AddresseeFilter,
	|	MailoutToCustomers.EmailTextType,
	|	MailoutToCustomers.SendInTransliteration,
	|	GroupsOfMailoutsAndNotifications.Forced,
	|	GroupsOfMailoutsAndNotifications.SendToCustomer,
	|	GroupsOfMailoutsAndNotifications.SendToRoleContactPersons,
	|	GroupsOfMailoutsAndNotifications.SendToAContactPersonOfANotificationObject,
	|	GroupsOfMailoutsAndNotifications.PartnerSContactDetailsKindForEmails,
	|	GroupsOfMailoutsAndNotifications.PartnerSContactDetailsKindForSMSMessage,
	|	GroupsOfMailoutsAndNotifications.ContactPersonSContactDetailsKindForEmails,
	|	GroupsOfMailoutsAndNotifications.ContactPersonSContactDetailsKindForSMSMessage,
	|	GroupsOfMailoutsAndNotifications.ContactRole,
	|	MailoutToCustomers.EmployeeResponsible,
	|	MailoutToCustomers.Number,
	|	MailoutToCustomers.Date,
	|	GroupsOfMailoutsAndNotifications.Account,
	|	ISNULL(EmailAccounts.Email, """") AS AccountEmailAddress,
	|	ISNULL(EmailAccounts.UserName, """") AS AccountUserName,
	|	ISNULL(EmailAccountSettings.DeleteEmailsAfterSend, FALSE) AS DeleteAfterSend,
	|	MailoutToCustomers.Basis,
	|	MailoutToCustomers.HasAttachments
	|FROM
	|	Document.MailoutToCustomers AS MailoutToCustomers
	|		INNER JOIN Catalog.GroupsOfMailoutsAndNotifications AS GroupsOfMailoutsAndNotifications
	|			LEFT JOIN Catalog.EmailAccounts AS EmailAccounts
	|				LEFT JOIN InformationRegister.EmailAccountSettings AS EmailAccountSettings
	|				ON EmailAccounts.Ref = EmailAccountSettings.EmailAccount
	|			ON GroupsOfMailoutsAndNotifications.Account = EmailAccounts.Ref
	|		ON MailoutToCustomers.GroupOfMailoutsAndNotifications = GroupsOfMailoutsAndNotifications.Ref
	|WHERE
	|	NOT MailoutToCustomers.DeletionMark
	|	AND MailoutToCustomers.Status = VALUE(Enum.CustomerMailoutStatuses.ForDispatch)
	|	AND MailoutToCustomers.MailingDate < &DateOfMailingsToBePrepared
	|	AND CASE
	|			WHEN MailoutToCustomers.UpdateDate = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE CASE
	|					WHEN MailoutToCustomers.UpdateDate > &DateOfMailingsToBePrepared
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		END";
	
	Query.SetParameter("DateOfMailingsToBePrepared", CurrentSessionDate() + 3600);
	
	MailingListSelection = Query.Execute().Select();
	
	While MailingListSelection.Next() Do
		
		BeginTransaction();
		
		Try
			
			DocumentObject        = MailingListSelection.Ref.GetObject(); // DocumentObject.MailoutToCustomers
			DocumentObject.Status = Enums.CustomerMailoutStatuses.ForDispatch;
			DocumentObject.Write();
			
			ArrayOfCreatedInteractions = New Array;
			If TypeOf(MailingListSelection.Basis) = Type("DocumentRef.PollPurpose") And ValueIsFilled(MailingListSelection.Basis) Then
				TheseGrounds = DataAndPurposeOfSurveys(MailingListSelection.Basis);
			Else
				TheseGrounds = Undefined;
			EndIf;
			
			SelectionOfMailingRecipients = SelectionOfMailingRecipients(MailingListSelection, TheseGrounds);
			
			If MailingListSelection.DesignedForEmails Then
				CreateEmailsForDistribution(MailingListSelection, SelectionOfMailingRecipients, ArrayOfCreatedInteractions, TheseGrounds);
			Else
				CreateSMSForDistribution(MailingListSelection, SelectionOfMailingRecipients, ArrayOfCreatedInteractions , TheseGrounds);
			EndIf;
			
			DocumentObject.Status = Enums.CustomerMailoutStatuses.Executed;
			DocumentObject.Write();
			
			Interactions.CalculateReviewedBySubjects(ArrayOfCreatedInteractions);
			Interactions.CalculateReviewedByContacts(ArrayOfCreatedInteractions);
			
			NumberOfProcessedMailings = NumberOfProcessedMailings + 1;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			RecordText = NStr("vi = 'Lỗi trong khi tạo thư trên thư của khách hàng';
								|ru = 'Ошибка при формировании сообщений по рассылкам клиентов';
								|en = 'An error occurred while generating messages of customer mailouts'; fa = 'An error occurred while generating messages of customer mailouts';
								|it = 'Errore durante la formazione dei messaggi per email massive dei clienti';
								|pl = 'Błąd przy tworzeniu wiadomości po wysyłkach klientów';
								|tr = 'Müşteri dağıtımları için mesaj oluştururken hata oluştu'", CommonClientServer.DefaultLanguageCode()) + " : ";
			RecordText = RecordText + DetailErrorDescription(ErrorInfo());
			PerformLogEntry(RecordText ,EventLogLevel.Error);
			Return;
			
		EndTry;
		
	EndDo;
	
	RecordText = NStr("vi = 'Kết thúc lập các thông báo trên thư của khách hàng. Đã xử lý thư %1.';
						|ru = 'Окончание формирования сообщений по рассылкам клиентов. Обработано рассылок %1.';
						|en = 'End generating customer mailout messages. Processed mailouts: %1.'; fa = 'End generating customer mailout messages. Processed mailouts: %1.';
						|it = 'Fine della creazione dei messaggi per email massive dei clienti. Email massive elaborate %1.';
						|pl = 'Zakończenie tworzenia wiadomości po wysyłkach klientów. Opracowano wysyłek %1.';
						|tr = 'Müşteri dağıtımları için mesaj oluşturma işlemi tamamlandı. İşlenen dağıtımlar %1.'",
	                   CommonClientServer.DefaultLanguageCode());
	RecordText = StringFunctionsClientServer.SubstituteParametersToString(RecordText, String(NumberOfProcessedMailings));
	PerformLogEntry(RecordText ,EventLogLevel.Information);
	
EndProcedure

// Removes documents interactions on the mailing lists and alerts which have expired shelf life.
//
Procedure DeleteInteractionsRelatedToMailoutsAndNotifications() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DeleteInteractionsRelatedToMailoutsAndNotifications);
	
	SetPrivilegedMode(True);
	
	RecordText = NStr("vi = 'Bắt đầu cài đặt cờ xóa cho các tương tác gửi đi cho khách hàng';
						|ru = 'Начало установки пометки удаления для взаимодействий по рассылке клиентам';
						|en = 'Start setting a deletion mark for interactions on customer mailout'; fa = 'Start setting a deletion mark for interactions on customer mailout';
						|it = 'Avvio dell''installazione del flag di eliminazione per le interazioni per email massive ai clienti';
						|pl = 'Początek ustawiania znaku usuwania do interakcji po wysyłce klientom';
						|tr = 'Müşteri dağıtım etkileşimleri için silme işareti koymaya başlatılması'",
	                   CommonClientServer.DefaultLanguageCode());
	PerformLogEntry(RecordText ,EventLogLevel.Information);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Interactions.Ref
	|FROM
	|	DocumentJournal.Interactions AS Interactions
	|		INNER JOIN Document.MailoutToCustomers AS MailoutToCustomers
	|			INNER JOIN Catalog.GroupsOfMailoutsAndNotifications AS GroupsOfMailoutsAndNotifications
	|			ON MailoutToCustomers.GroupOfMailoutsAndNotifications = GroupsOfMailoutsAndNotifications.Ref
	|		ON Interactions.InteractionBasis = MailoutToCustomers.Ref
	|WHERE
	|	MailoutToCustomers.Status = VALUE(Enum.CustomerMailoutStatuses.Executed)
	|	AND NOT Interactions.DeletionMark
	|	AND GroupsOfMailoutsAndNotifications.MessageRetentionPeriod <> 0
	|	AND CASE
	|			WHEN Interactions.EmailSendingRelevanceDate > Interactions.Date
	|				THEN DATEADD(Interactions.EmailSendingRelevanceDate, DAY, GroupsOfMailoutsAndNotifications.MessageRetentionPeriod) < &CurrentDate
	|			ELSE DATEADD(Interactions.Date, DAY, GroupsOfMailoutsAndNotifications.MessageRetentionPeriod) < &CurrentDate
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	Interactions.Ref
	|FROM
	|	DocumentJournal.Interactions AS Interactions
	|		INNER JOIN Catalog.CustomerNotificationKinds AS CustomerNotificationKinds
	|			INNER JOIN Catalog.GroupsOfMailoutsAndNotifications AS GroupsOfMailoutsAndNotifications
	|			ON CustomerNotificationKinds.GroupOfMailoutsAndNotifications = GroupsOfMailoutsAndNotifications.Ref
	|		ON Interactions.InteractionBasis = CustomerNotificationKinds.Ref
	|WHERE
	|	NOT Interactions.DeletionMark
	|	AND GroupsOfMailoutsAndNotifications.MessageRetentionPeriod <> 0
	|	AND CASE
	|			WHEN Interactions.EmailSendingRelevanceDate > Interactions.Date
	|				THEN DATEADD(Interactions.EmailSendingRelevanceDate, DAY, GroupsOfMailoutsAndNotifications.MessageRetentionPeriod) < &CurrentDate
	|			ELSE DATEADD(Interactions.Date, DAY, GroupsOfMailoutsAndNotifications.MessageRetentionPeriod) < &CurrentDate
	|		END";
	
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		DocumentObject = Selection.Ref.GetObject();
		DocumentObject.SetDeletionMark(True);
		DocumentObject.Write();
		
	EndDo;
	
	RecordText = NStr("vi = 'Bắt đầu cài đặt cờ xóa cho các tương tác gửi đi cho khách hàng';
						|ru = 'Начало установки пометки удаления для взаимодействий по рассылке клиентам';
						|en = 'Start setting a deletion mark for interactions on customer mailout'; fa = 'Start setting a deletion mark for interactions on customer mailout';
						|it = 'Avvio dell''installazione del flag di eliminazione per le interazioni per email massive ai clienti';
						|pl = 'Początek ustawiania znaku usuwania do interakcji po wysyłce klientom';
						|tr = 'Müşteri dağıtım etkileşimleri için silme işareti koymaya başlatılması'",
	                   CommonClientServer.DefaultLanguageCode());
	PerformLogEntry(RecordText ,EventLogLevel.Information);
	
EndProcedure

#EndRegion

#Region HandlingDataChangesForCustomerAlerts

// Handler for subscribing to the "before writing" event of the data and accumulation registers
//  for forming a queue of client notifications. Acts as a router for various types of sources.
//
// Parameters:
//  Source  - InformationRegisterRecordSet, AccumulationRegisterRecordSet - a set of records whose data is
//                                                                           analyzed before recording.
//  Cancel     - Boolean - ability to opt out of recording a set of records.
//
Procedure SourceOfPreWriteAlertRegisters(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If TypeOf(Source) = Type("AccumulationRegisterRecordSet.BonusPoints") Then
		
		ProcessChangeOfBonusPoints(Source, "BeforeWrite");
		
	ElsIf TypeOf(Source) = Type("InformationRegisterRecordSet.SalesOrderStates") Then
		
		HandleChangingStateOfCustomerOrders(Source, "BeforeWrite");
		
	EndIf;
	
	ConfigurationModificationOverridable.NotificationSourceBeforeWrite(Source, Cancel, Undefined, Undefined);
	
EndProcedure

// Handler for subscribing to the "on write" event of the data and accumulation registers
//  for forming a queue of client notifications. Acts as a router for various types of sources.
//
// Parameters:
//  Source  - InformationRegisterRecordSet, AccumulationRegisterRecordSet - a set of records whose data is
//                                                                           analyzed during recording.
//  Cancel     - Boolean - ability to opt out of recording a set of records.
//
Procedure SourceOfNotificationWhenWritingRegisters(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If TypeOf(Source) = Type("AccumulationRegisterRecordSet.BonusPoints") Then
		
		ProcessChangeOfBonusPoints(Source, "OnWrite");
		
	ElsIf TypeOf(Source) = Type("InformationRegisterRecordSet.SalesOrderStates") Then
		
		HandleChangingStateOfCustomerOrders(Source, "OnWrite");
		
	EndIf;
	
	ConfigurationModificationOverridable.SourceOfRecordingAlert(Source, Cancel);
	
EndProcedure

// Handler for subscribing to the "before recording" event of documents for creating a queue
// of client notifications. Acts as a router for various types of sources.
//
// Parameters:
//  Source        - DocumentRef - a document whose data is analyzed before recording.
//  Cancel           - Boolean - option to refuse to record a document.
//  WriteMode     - DocumentWriteMode - the recording mode of the document.
//  PostingMode - DocumentPostingMode - the mode of the document.
//
Procedure SourceOfNotificationBeforeRecordingDocuments(Source, Cancel, WriteMode, PostingMode) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If TypeOf(Source) = Type("DocumentObject.CustomerCommercialInvoice") Then
		
		ProcessInvoiceChanges(Source, "BeforeWrite", WriteMode);
		
	ElsIf TypeOf(Source) = Type("DocumentObject.CashAccountReceiptNote")
			Or TypeOf(Source) = Type("DocumentObject.BankAccountReceiptNote")
			Or TypeOf(Source) = Type("DocumentObject.PaymentCardTransaction") Then
			
			ProcessChangeInPaymentReceipt(Source, "BeforeWrite", WriteMode);
	
	EndIf;
	
	ConfigurationModificationOverridable.NotificationSourceBeforeWrite(Source, Cancel, WriteMode, PostingMode);
	
EndProcedure

// Handler for subscribing to the "on record" event of documents for creating a queue
// of client notifications. Acts as a router for various types of sources.
//
// Parameters:
//  Source  - DocumentObject - a document whose data is analyzed during recording.
//  Cancel     - Boolean - option to refuse to record a document.
//
Procedure SourceOfNotificationWhenRecordingDocuments(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If TypeOf(Source) = Type("DocumentObject.CustomerCommercialInvoice") Then
		
		ProcessInvoiceChanges(Source, "OnWrite", Undefined);
		
	ElsIf TypeOf(Source) = Type("DocumentObject.CashAccountReceiptNote")
			Or TypeOf(Source) = Type("DocumentObject.BankAccountReceiptNote")
			Or TypeOf(Source) = Type("DocumentObject.PaymentCardTransaction") Then
			
			ProcessChangeInPaymentReceipt(Source, "OnWrite", Undefined);
		
	EndIf;
	
	ConfigurationModificationOverridable.SourceOfRecordingAlert(Source, Cancel);
	
EndProcedure

#EndRegion

// Retrieves data from the "survey Assignment" document, the reasons for mailing to clients
//
// Parameters:
//  Basis  - DocumentRef.PollPurpose - the document whose data is received.
//
// Returns:
//   QueryResultSelection, Undefined - the data of the document "Assignment of surveys" contains:
//    * Ref          - DocumentRef.PollPurpose - 
//    * StartDate      - Date - 
//    * EndDate   - Date - 
//    * Description    - String -
//    * FreeSurvey  - Boolean -
//    * RespondentsType - String -
//
Function DataAndPurposeOfSurveys(Basis) Export

	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	PollPurpose.Ref,
	|	PollPurpose.StartDate,
	|	PollPurpose.EndDate,
	|	PollPurpose.Description,
	|	PollPurpose.FreeSurvey,
	|	PollPurpose.RespondentsType
	|FROM
	|	Document.PollPurpose AS PollPurpose
	|WHERE
	|	PollPurpose.Ref = &Basis";
	
	Query.SetParameter("Basis", Basis);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return Undefined;
	Else
		Selection = Result.Select();
		Selection.Next();
		Return Selection;
	EndIf;

EndFunction

// Sets visibility on the document form of an informational message that prompts the Manager to sign
// the client for notifications on this document.
//
// Parameters:
//  GroupSubscribeToAlerts  - FormGroup - the group of the form where the pages with the message and an empty page are located.
//  Partner                     - CatalogRef.Partners - the partner to subscribe to.
//  EventType                  - EnumRef.NotificationEventTypes, Array - types of notification events for which
//    groups of newsletters and notifications will be found and you will be asked to subscribe to them.
//
Procedure SetVisibilityOfSubscribingToAlertsInObject(GroupSubscribeToAlerts, Partner, EventType) Export
		
	ShowSubscriptionsToAlerts = CustomerMailoutsAndNotificationsServerCall.ShowSubscriptionsToAlertsInMapItem(
		Partner,
		EventType);
		
	If ShowSubscriptionsToAlerts Then
		GroupSubscribeToAlerts.Visible = True;
	Else
		GroupSubscribeToAlerts.Visible = False;
	EndIf;
	
EndProcedure

// Generates a query that places partners in the temporary table according to the selection settings.
//
// Parameters:
//  Data  - Structure - contains the following properties:
//    * AddresseeFilter - ValueStorage - contains the settings of the data layout selection for the partner.
//    * Basis      - DocumentRef - the basis of mailing to clients.
//  SelectionOnBasisOf_ - Boolean - it contains a sign
//                                        that the selection based on the mailing list is set in the layout settings.
// Returns:
//   Query - partner selection request
//
Function RequestSelectionByLayout(Data, SelectionOnBasisOf_) Export
	
	Settings = Data.AddresseeFilter.Get();
	
	BasedOnTheSurvey = ValueIsFilled(Data.Basis) 
	                    And TypeOf(Data.Basis) = Type("DocumentRef.PollPurpose");
	
	TemplateName = ?(BasedOnTheSurvey, "PartnerFilterSurveyPurpose", "PartnerFilter");
	
	// Request formation
	FilterScheme = DataProcessors.SelectPartnersByFilter.GetTemplate(TemplateName);
	
	TemplateComposer = New DataCompositionTemplateComposer();
	CalculationSettingsComposer = New DataCompositionSettingsComposer;
	CalculationSettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(FilterScheme));
	CalculationSettingsComposer.LoadSettings(Settings);
	
	DataCompositionTemplate = TemplateComposer.Execute(FilterScheme, CalculationSettingsComposer.GetSettings(),,,
	                                                    Type("DataCompositionValueCollectionTemplateGenerator"));
	
	Template = Documents.MailoutToCustomers.GetTemplate("MailoutStatus");
	
	ThereIsSelectionOnLayout = False;
	If DataCompositionTemplate.ParameterValues.Count() > 0 Then
		If Not (BasedOnTheSurvey 
			And DataCompositionTemplate.ParameterValues.Count() = 1 
			And DataCompositionTemplate.ParameterValues[0].Value = Data.Basis) Then
			ThereIsSelectionOnLayout = True;
		EndIf;
	EndIf;
	
	For Each ParameterValues_2 In DataCompositionTemplate.ParameterValues Do
		If ParameterValues_2.Value = Data.Basis Then
			SelectionOnBasisOf_ = True;
			Break;
		EndIf;
	EndDo;
	
	Query = New Query;
	
	If ThereIsSelectionOnLayout Then
		
		Query.Text = DataCompositionTemplate.DataSets.MainDataSet.Query;
		
		For Each Parameter In DataCompositionTemplate.ParameterValues Do
			Query.Parameters.Insert(Parameter.Name, Parameter.Value);
		EndDo;
		
		TheTextToPut = "INTO PartnerFilter";
		InsertPosition =  StrFind(Query.Text, "Catalog.Partners AS Partners") - 5;
		LeftPart     = Left(Query.Text, InsertPosition);
		RightPart    = Right(Query.Text, StrLen(Query.Text) -InsertPosition);
		Query.Text = LeftPart + TheTextToPut + Chars.LF + RightPart;
		Query.Text = Query.Text + "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////";
		
	EndIf;
	
	Return Query;
	
EndFunction

// Sets parameters for dynamic lists for the text representation of the message type.
//
// Parameters:
//  List  - DynamicList - the list where the parameters are placed.
//
Procedure NotificationGroupsSetDynamicListParameters(List) Export

	CommonClientServer.SetDynamicListParameter(List,
	                                                                   "ForEmailsAndSMS",
	                                                                   NStr("vi = 'E-mail và SMS';
																			|ru = 'Email и SMS';
																			|en = 'Email and SMS message'; fa = 'Email and SMS message';
																			|it = 'Email e SMS';
																			|pl = 'E-mail i SMS';
																			|tr = 'E-posta ve SMS'"));
	CommonClientServer.SetDynamicListParameter(List,
	                                                                   "ForEmails_2",
	                                                                   NStr("vi = 'Email';
																			|ru = 'Email';
																			|en = 'Email'; fa = 'ایمیل';
																			|it = 'Email';
																			|pl = 'Email';
																			|tr = 'Email'"));
	CommonClientServer.SetDynamicListParameter(List,
	                                                                   "ForSMS",
	                                                                   NStr("vi = 'SMS';
																			|ru = 'SMS';
																			|en = 'SMS'; fa = 'پیامک';
																			|it = 'SMS';
																			|pl = 'SMS';
																			|tr = 'SMS'"));
	CommonClientServer.SetDynamicListParameter(List,
	                                                                   "UseOtherInteractions",
	                                                                   GetFunctionalOption("UseOtherInteractions"));
	
EndProcedure

// Initializes the SCD settings linker by first placing the SCD in temporary storage.
//
// Parameters:
//  DCSTemplate  - DataCompositionSchema - The SCD whose settings linker will be initialized.
//  UUID  - UUID - unique ID of the form for placing the SKD in temporary storage.
//  
// Returns:
//   DataCompositionSettingsComposer - initialized SKD settings linker
//
Function InitializeDCS(DCSTemplate, UUID) Export

	SchemaURL = PutToTempStorage(DCSTemplate,UUID);
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
	
	Return SettingsComposer;

EndFunction 

// Fills in the form details for a group of mailings and notifications.
//
// Parameters:
//  Form  - ClientApplicationForm - the form that will be filled in.
//  GroupOfMailoutsAndNotifications  - CatalogRef.GroupsOfMailoutsAndNotifications - the details of the form will be filled in based on this information.
//
Procedure FillInFormDetailsForMailingAndNotificationGroup(Form, GroupOfMailoutsAndNotifications) Export

	GroupDetails_ = Common.ObjectAttributesValues(GroupOfMailoutsAndNotifications,
	    "DesignedForEmails, DesignedForSMSMessage, PartnerSContactDetailsKindForEmails,
		|PartnerSContactDetailsKindForSMSMessage, ContactPersonSContactDetailsKindForSMSMessage,
		|ContactPersonSContactDetailsKindForEmails, Forced");
	FillPropertyValues(Form, GroupDetails_);

EndProcedure

// Adds a value to the array if it is not present in the array.
//
// Parameters:
//  ArrayToAdd - Array - the array to which it is added.
//  ValueToAdd - Arbitrary - the value that will be added to the array if missing.
//
Procedure AddToArray(ArrayToAdd, ValueToAdd) Export

	If Not ValueIsFilled(ValueToAdd) Then
		Return;
	EndIf;
	
	If ArrayToAdd.Find(ValueToAdd) = Undefined Then
		ArrayToAdd.Add(ValueToAdd);
	EndIf;

EndProcedure

// Generates an address string from an array of addresses by adding a separator between the array elements.
//
// Parameters:
//  AddressesArray - Array - an array containing the addresses.
//  Separator - String - the separator that will be added between addresses in the resulting string.
//
// Returns:
//   String   - the generated string.
//
Function AddressStringFromArray(AddressesArray, Separator) Export

	StringToReturn = "";
	
	For Each ArrayElement In AddressesArray Do
		StringToReturn = StringToReturn + ?(IsBlankString(StringToReturn),"" , Separator) + ArrayElement;
	EndDo;
	
	Return StringToReturn;

EndFunction

// Forms the structure of the CI selection lists. Used in the "mailing and notification Groups" and "Subscriptions" forms.
//
// Parameters:
//  < Parameter1> - <Type.View> - <parameter description>
//                 <continuation of the parameter description>
//  < Parameter2> - <Type.View> - <parameter description>
//                 <continuation of the parameter description>.
//
// Returns:
//   Structure   - contains the following properties: 
//      Partneradress of electronic mail - types of partner information of the "e-mail address" type.
//      Partnerthelephone - types of partner's AI of the "Phone" type.
//      Contact personsadress of electronic mail - types of a contact person of the "e-mail address" type.
//      Contact Personelephone - types of a contact person of the "Phone" type.
//
Function StructureOfKiSelectionLists() Export

	StructureOfSelectionLists = New Structure;
	
	StructureOfSelectionLists = New Structure;
	StructureOfSelectionLists.Insert("PartnersEmailAddress",       New ValueList);
	StructureOfSelectionLists.Insert("PartnersPhoneNumber_",                     New ValueList);
	StructureOfSelectionLists.Insert("ContactPersonsEmailAddress", New ValueList);
	StructureOfSelectionLists.Insert("ContactPersonsPhone",               New ValueList);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ContactInformationKinds.Ref,
	|	ContactInformationKinds.Description,
	|	ContactInformationKinds.Parent AS Parent,
	|	ContactInformationKinds.Type AS Type
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	(ContactInformationKinds.Parent = VALUE(Catalog.ContactInformationKinds.CatalogPartners)
	|			OR ContactInformationKinds.Parent = VALUE(Catalog.ContactInformationKinds.CatalogContactPersonsForPartners))
	|	AND (ContactInformationKinds.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|			OR ContactInformationKinds.Type = VALUE(Enum.ContactInformationTypes.Email))
	|TOTALS BY
	|	Parent,
	|	Type";
	
	ParentSelection = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While ParentSelection.Next() Do
		
		SelectionType = ParentSelection.Select(QueryResultIteration.ByGroups);
		
		While SelectionType.Next() Do
			
			If SelectionType.Parent = Catalogs.ContactInformationKinds.CatalogPartners Then
				If SelectionType.Type = Enums.ContactInformationTypes.Email Then
					KeyName = "PartnersEmailAddress";
				Else
					KeyName = "PartnersPhoneNumber_";
				EndIf;
			Else
				If SelectionType.Type = Enums.ContactInformationTypes.Email Then
					KeyName = "ContactPersonsEmailAddress";
				Else
					KeyName = "ContactPersonsPhone";
				EndIf;
			EndIf;
			
			DetailsSelection = SelectionType.Select();
			
			ListOfTypesOfCI = New ValueList;
			
			While DetailsSelection.Next() Do
				
				ListOfTypesOfCI.Add(DetailsSelection.Ref, DetailsSelection.Description);
				
			EndDo;
			
			StructureOfSelectionLists.Insert(KeyName, ListOfTypesOfCI);
			
		EndDo;
		
	EndDo;
	
	Return StructureOfSelectionLists;

EndFunction

// Copies values from one list of values to another
//
// Parameters:
//  Receiver  - ValueList - a list of values to copy elements to.
//  Source  - ValueList - a list of values from which elements will be copied.
//
Procedure CopyValuesFromListOfValues(Receiver, Source) Export

	Receiver.Clear();
	
	For Indus = 0 To Source.Count() - 1 Do 
		
		ListItem = Source.Get(Indus);
		Receiver.Add(ListItem.Value, ListItem.Presentation);
		
	EndDo;

EndProcedure

// Generates the context help text for the "Send notification object to contact person" setting.
//
// Returns:
//   String   - the text of the context hint.
//
Function ExplanationTextContactPersonOfNotificationObject() Export
	
	Return NStr("vi = 'Nếu có thể thì thông báo sẽ được gửi cho cá nhân đã chỉ ra trong đối tượng là
	                   |nguồn thông báo. Ví dụ, thông báo về trạng thái ""Đơn hàng của khách"" đã thay đổi sẽ 
	                   |được gửi cho người liên hệ trong chứng từ.';
	                   |ru = 'Когда это возможно, оповещение будет отправлено контактному лицу, указанному в объекте, являющемся
	                   |источником оповещения. Например, оповещение по изменившемуся состоянию ""Заказа клиента"" будет 
	                   |послано контактному лицу, указанному в документе.';
	                   |en = 'When it is possible, a notification will be sent to a contact person specified in
	                   |the notification source. For example, a notification of the changed ""Sales order"" state
	                   |will be sent to the contact person specified in the document.'; fa = 'When it is possible, a notification will be sent to a contact person specified in
	                   |the notification source. For example, a notification of the changed ""Sales order"" state
	                   |will be sent to the contact person specified in the document.';
	                   |it = 'Appena possibile, l''avviso verrà inviato alla persona di contatto elencata nell''oggetto che è la fonte dell''avviso.
	                   | Ad esempio, una notifica sullo stato modificato dell ''""Ordine cliente"" verrà
	                   | inviata alla persona di contatto indicata nel documento.';
	                   |pl = 'Gdy jest to możliwe, powiadomienie zostanie wysłane osobie kontaktowej, podanej w obiekcie, która
	                   |źródłem powiadomienia. Na przykład, powiadomienie po zmianie stanu ""Zamówienia klienta"" zostanie 
	                   | wysłane osobie kontaktowej, podanej w dokumencie.';
	                   |tr = 'Mümkün olduğunda, bildirim, bildirimin kaynağı olan nesnede belirtilen
	                   |irtibat kişisine gönderilecektir. Örneğin, bir ""Müşteri siparişi"" değişen durumuna 
	                   |ilişkin bir uyarı, belgede belirtilen irtibat kişisine gönderilecektir.'");
	
EndFunction

// Generates a string with information about the subscription recipients.
//
// Parameters:
//  Data          - Structure - contains information about the subscription.
//  Forced  - Boolean - a sign that messages will be forcibly poisoned.
//
// Returns:
//   String   - a line with information about the recipients of the subscription.
//
Function TextToWhomMessagesWillBeSent(Data, Forced = False) Export

	TextAddressees = "";
	If Data.SendToCustomer Then
		TextAddressees = NStr("vi = 'Bạn hàng';
								|ru = 'Партнер';
								|en = 'Partner'; fa = 'شریک تجاری';
								|it = 'Partner';
								|pl = 'Partner';
								|tr = 'İş ortağı'");
	EndIf;
	
	If Data.SendToAContactPersonOfANotificationObject Then
		AddCommaIfNotEmptyText(TextAddressees);
		TextAddressees = TextAddressees + NStr("vi = 'người liên hệ của đối tượng thông báo';
												|ru = 'контактное лицо объекта оповещения';
												|en = 'contact person of a notification object'; fa = 'contact person of a notification object';
												|it = 'persona di contatto dell''oggetto di notifica';
												|pl = 'osoba kontaktowa obiektu powiadomienia';
												|tr = 'Bildirim nesnesi irtibat kişisi'");
	EndIf;
	
	If Forced Then
		
		If Data.PoisoningContactPersonRoles Then
			AddCommaIfNotEmptyText(TextAddressees);
			CLText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'người liên hệ vai trò ""%1""';
																					|ru = 'контактные лица роли ""%1""';
																					|en = 'contact persons of the ""%1"" role'; fa = 'contact persons of the ""%1"" role';
																					|it = 'Persone di contatto del ruolo ""%1""';
																					|pl = 'osoby kontaktowe role ""%1""';
																					|tr = '""%1"" rolündeki irtibat kişileri'"),
			Data.NameOfContactPersonRole);
			TextAddressees = TextAddressees + CLText;
		EndIf;
		
	Else
		
		If Data.NumberOfAdditionalAddressees_ Then
			
			AddCommaIfNotEmptyText(TextAddressees);
			CLText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'người liên hệ - %1 người';
																					|ru = 'контактные лица - %1 чел';
																					|en = 'contact persons - %1 pers'; fa = 'contact persons - %1 pers';
																					|it = 'Persone di contatto - %1';
																					|pl = 'osoby kontaktowe - %1 osób';
																					|tr = 'irtibat kişileri - %1 kişi'"),
			Data.NumberOfAdditionalAddressees_);
			TextAddressees = TextAddressees + CLText;
			
		EndIf;
		
	EndIf;
	
	TextAddressees = TextAddressees + ?(IsBlankString(TextAddressees), "", ".");
	TextAddressees = Upper(Left(TextAddressees, 1)) + Right(TextAddressees, StrLen(TextAddressees) - 1);
	
	Return TextAddressees;
	
EndFunction

#EndRegion

#Region Private

#Region AnalyzeDataForCustomerAlerts

Procedure DataAnalysisBirthdayGreetings(NotificationKind)

	Query = New Query;
	Query.Text = "SELECT
	|	CustomerNotificationKinds.GroupOfMailoutsAndNotifications,
	|	GroupsOfMailoutsAndNotifications.Forced,
	|	GroupsOfMailoutsAndNotifications.SendToAContactPersonOfANotificationObject
	|FROM
	|	Catalog.CustomerNotificationKinds AS CustomerNotificationKinds
	|		INNER JOIN Catalog.GroupsOfMailoutsAndNotifications AS GroupsOfMailoutsAndNotifications
	|		ON CustomerNotificationKinds.GroupOfMailoutsAndNotifications = GroupsOfMailoutsAndNotifications.Ref
	|WHERE
	|	CustomerNotificationKinds.Ref = &NotificationKind";
	
	Query.SetParameter("NotificationKind", NotificationKind);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Query = New Query;
	
	If Selection.Forced Then
		
		If Not Selection.SendToAContactPersonOfANotificationObject Then
			Return;
		EndIf;
		
		Query.Text = "
		|SELECT
		|	ContactPersonsForPartners.Ref AS NotificationSource,
		|	BEGINOFPERIOD(DATEADD(&CurrentDate, DAY, 1), DAY) AS DateSent,
		|	BEGINOFPERIOD(DATEADD(&CurrentDate, DAY, 2), DAY) AS EmailSendingRelevanceDate,
		|	ContactPersonsForPartners.Owner AS Subscriber
		|FROM
		|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
		|		LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|		ON ContactPersonsForPartners.Ref = EventQueueForNotificationsToCustomers.NotificationSource
		|			AND (EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind)
		|WHERE
		|	NOT ContactPersonsForPartners.DeletionMark
		|	AND ContactPersonsForPartners.BirthDate <> DATETIME(1, 1, 1)
		|	AND DAY(ContactPersonsForPartners.BirthDate) = DAY(DATEADD(&CurrentDate, DAY, 1))
		|	AND MONTH(ContactPersonsForPartners.BirthDate) = MONTH(DATEADD(&CurrentDate, DAY, 1))
		|	AND EventQueueForNotificationsToCustomers.NotificationSource IS NULL ";
		
	Else
		
		Query.Text = "
		|SELECT
		|	ContactPersonsForPartners.Ref AS NotificationSource,
		|	BEGINOFPERIOD(DATEADD(&CurrentDate, DAY, 1), DAY) AS DateSent,
		|	BEGINOFPERIOD(DATEADD(&CurrentDate, DAY, 2), DAY) AS EmailSendingRelevanceDate,
		|	ContactPersonsForPartners.Owner AS Subscriber
		|FROM
		|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
		|		LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|		ON ContactPersonsForPartners.Ref = EventQueueForNotificationsToCustomers.NotificationSource
		|			AND (EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind)
		|		INNER JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
		|		ON ContactPersonsForPartners.Owner = SubscriptionsToCustomerMailoutsAndNotifications.Owner
		|			AND (SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid)
		|			AND (SubscriptionsToCustomerMailoutsAndNotifications.SendToAContactPersonOfANotificationObject)
		|			AND (NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark)
		|			AND (SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications)
		|WHERE
		|	NOT ContactPersonsForPartners.DeletionMark
		|	AND ContactPersonsForPartners.BirthDate <> DATETIME(1, 1, 1)
		|	AND DAY(ContactPersonsForPartners.BirthDate) = DAY(DATEADD(&CurrentDate, DAY, 1))
		|	AND MONTH(ContactPersonsForPartners.BirthDate) = MONTH(DATEADD(&CurrentDate, DAY, 1))
		|	AND EventQueueForNotificationsToCustomers.NotificationSource IS NULL ";
		
	EndIf;
	
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("NotificationKind", NotificationKind);
	Query.SetParameter("GroupOfMailoutsAndNotifications", Selection.GroupOfMailoutsAndNotifications);
	
	SamplingQueue = Query.Execute().Select();
		
	While SamplingQueue.Next() Do
		
		InformationRegisters.EventQueueForNotificationsToCustomers.ExecuteRecordToRegister(
		                NotificationKind,
		                SamplingQueue.Subscriber,
		                SamplingQueue.NotificationSource,
		                SamplingQueue.DateSent,
		                SamplingQueue.EmailSendingRelevanceDate);
		
	EndDo;

EndProcedure

Procedure AnalysisOverdueDebt(NotificationKind)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	CustomerNotificationKinds.GroupOfMailoutsAndNotifications,
	|	GroupsOfMailoutsAndNotifications.Forced,
	|	GroupsOfMailoutsAndNotifications.SendToCustomer,
	|	GroupsOfMailoutsAndNotifications.SendToRoleContactPersons
	|FROM
	|	Catalog.CustomerNotificationKinds AS CustomerNotificationKinds
	|		INNER JOIN Catalog.GroupsOfMailoutsAndNotifications AS GroupsOfMailoutsAndNotifications
	|		ON CustomerNotificationKinds.GroupOfMailoutsAndNotifications = GroupsOfMailoutsAndNotifications.Ref
	|WHERE
	|	CustomerNotificationKinds.Ref = &NotificationKind";
	
	Query.SetParameter("NotificationKind", NotificationKind);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Query = New Query;
	
	If Selection.Forced Then
		
		If Not Selection.SendToCustomer And Not Selection.SendToRoleContactPersons Then
			Return;
		EndIf;
		
		Query.Text = "
		|SELECT
		|	NestedQuery.NotificationSource AS NotificationSource,
		|	SUM(NestedQuery.SumBalance) AS SumBalance,
		|	SUM(NestedQuery.AmountDueBalance) AS AmountDueBalance
		|FROM
		|	(SELECT
		|		CustomersARAPAccountingBalance.AccountingDimensionByPartners.Partner AS NotificationSource,
		|		CustomersARAPAccountingBalance.ARAPObject AS ARAPObject,
		|		CustomersARAPAccountingBalance.SumBalance AS SumBalance,
		|		CustomersARAPAccountingBalance.AmountDueBalance AS AmountDueBalance
		|	FROM
		|		AccumulationRegister.CustomersARAPAccounting.Balance(&CurrentDate, ) AS CustomersARAPAccountingBalance
		|			LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|				ON CustomersARAPAccountingBalance.AccountingDimensionByPartners.Partner = EventQueueForNotificationsToCustomers.NotificationSource
		|					AND (EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind)
		|	WHERE
		|		NOT &NewOnlineARAPAccounting
		|		AND EventQueueForNotificationsToCustomers.NotificationSource IS NULL 
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CustomersARAPAccountingByDueDatesBalance.AccountingDimensionByPartners.Partner AS NotificationSource,
		|		CustomersARAPAccountingByDueDatesBalance.ARAPObject AS ARAPObject,
		|		CustomersARAPAccountingByDueDatesBalance.DebtBalance AS SumBalance,
		|		CustomersARAPAccountingByDueDatesBalance.DebtBalance AS AmountDueBalance
		|	FROM
		|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(, PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)) AS CustomersARAPAccountingByDueDatesBalance
		|			LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|				ON CustomersARAPAccountingByDueDatesBalance.AccountingDimensionByPartners.Partner = EventQueueForNotificationsToCustomers.NotificationSource
		|					AND (EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind)
		|	WHERE
		|		&NewOnlineARAPAccounting
		|		AND EventQueueForNotificationsToCustomers.NotificationSource IS NULL 
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CustomersARAPAccountingCashFlowPlanBalance.AccountingDimensionByPartners.Partner AS NotificationSource,
		|		CustomersARAPAccountingCashFlowPlanBalance.ARAPObject AS ARAPObject,
		|		CustomersARAPAccountingCashFlowPlanBalance.AmountDueBalance AS SumBalance,
		|		CustomersARAPAccountingCashFlowPlanBalance.AmountDueBalance AS AmountDueBalance
		|	FROM
		|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(, PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)) AS CustomersARAPAccountingCashFlowPlanBalance
		|			LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|				ON CustomersARAPAccountingCashFlowPlanBalance.AccountingDimensionByPartners.Partner = EventQueueForNotificationsToCustomers.NotificationSource
		|					AND (EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind)
		|	WHERE
		|		&NewOnlineARAPAccounting
		|		AND EventQueueForNotificationsToCustomers.NotificationSource IS NULL 
		|	) AS NestedQuery
		|GROUP BY
		|	NestedQuery.NotificationSource
		|HAVING
		|	SUM(NestedQuery.AmountDueBalance) > 0"
		
	Else
		
		Query.Text = "
		|SELECT
		|	NestedQuery.NotificationSource AS NotificationSource,
		|	SUM(NestedQuery.SumBalance) AS SumBalance,
		|	SUM(NestedQuery.AmountDueBalance) AS AmountDueBalance
		|FROM
		|	(SELECT
		|		CustomersARAPAccountingBalance.AccountingDimensionByPartners.Partner AS NotificationSource,
		|		CustomersARAPAccountingBalance.ARAPObject AS ARAPObject,
		|		CustomersARAPAccountingBalance.SumBalance AS SumBalance,
		|		CustomersARAPAccountingBalance.AmountDueBalance AS AmountDueBalance
		|	FROM
		|		AccumulationRegister.CustomersARAPAccounting.Balance(
		|			&CurrentDate,
		|			AccountingDimensionByPartners.Partner IN
		|				(SELECT
		|					SubscriptionsToCustomerMailoutsAndNotifications.Owner
		|				FROM
		|					Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
		|						LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|						ON
		|							SubscriptionsToCustomerMailoutsAndNotifications.Owner = EventQueueForNotificationsToCustomers.NotificationSource
		|								AND EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind
		|				WHERE
		|					NOT &NewOnlineARAPAccounting
		|					AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications
		|					AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
		|					AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
		|					AND (SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer
		|						OR SubscriptionsToCustomerMailoutsAndNotifications.NumberOfAddresseesContactPersons > 0)
		|					AND EventQueueForNotificationsToCustomers.NotificationSource IS NULL )) AS CustomersARAPAccountingBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CustomersARAPAccountingByDueDatesBalance.AccountingDimensionByPartners.Partner AS NotificationSource,
		|		CustomersARAPAccountingByDueDatesBalance.ARAPObject AS ARAPObject,
		|		CustomersARAPAccountingByDueDatesBalance.DebtBalance AS SumBalance,
		|		CustomersARAPAccountingByDueDatesBalance.DebtBalance AS AmountDueBalance
		|	FROM
		|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
		|			,
		|			PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			AND AccountingDimensionByPartners.Partner IN
		|				(SELECT
		|					SubscriptionsToCustomerMailoutsAndNotifications.Owner
		|				FROM
		|					Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
		|						LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|						ON
		|							SubscriptionsToCustomerMailoutsAndNotifications.Owner = EventQueueForNotificationsToCustomers.NotificationSource
		|								AND EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind
		|				WHERE
		|					&NewOnlineARAPAccounting
		|					AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications
		|					AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
		|					AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
		|					AND (SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer
		|						OR SubscriptionsToCustomerMailoutsAndNotifications.NumberOfAddresseesContactPersons > 0)
		|					AND EventQueueForNotificationsToCustomers.NotificationSource IS NULL )) AS CustomersARAPAccountingByDueDatesBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CustomersARAPAccountingCashFlowPlanBalance.AccountingDimensionByPartners.Partner AS NotificationSource,
		|		CustomersARAPAccountingCashFlowPlanBalance.ARAPObject AS ARAPObject,
		|		CustomersARAPAccountingCashFlowPlanBalance.AmountDueBalance AS SumBalance,
		|		CustomersARAPAccountingCashFlowPlanBalance.AmountDueBalance AS AmountDueBalance
		|	FROM
		|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(
		|			,
		|			PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			AND AccountingDimensionByPartners.Partner IN
		|				(SELECT
		|					SubscriptionsToCustomerMailoutsAndNotifications.Owner
		|				FROM
		|					Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
		|						LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|						ON
		|							SubscriptionsToCustomerMailoutsAndNotifications.Owner = EventQueueForNotificationsToCustomers.NotificationSource
		|								AND EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind
		|				WHERE
		|					&NewOnlineARAPAccounting
		|					AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications
		|					AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
		|					AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
		|					AND (SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer
		|						OR SubscriptionsToCustomerMailoutsAndNotifications.NumberOfAddresseesContactPersons > 0)
		|					AND EventQueueForNotificationsToCustomers.NotificationSource IS NULL )) AS CustomersARAPAccountingCashFlowPlanBalance
		|	) AS NestedQuery
		|GROUP BY
		|	NestedQuery.NotificationSource
		|HAVING
		|	SUM(NestedQuery.AmountDueBalance) > 0";
		
	EndIf;
	
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("NotificationKind", NotificationKind);
	Query.SetParameter("GroupOfMailoutsAndNotifications", Selection.GroupOfMailoutsAndNotifications);
	Query.SetParameter("NewOnlineARAPAccounting", Constants.NewOnlineARAPAccounting.Get());
	
	SamplingQueue = Query.Execute().Select();
		
	While SamplingQueue.Next() Do
		
		InformationRegisters.EventQueueForNotificationsToCustomers.ExecuteRecordToRegister(
		                NotificationKind,
		                SamplingQueue.NotificationSource,
		                SamplingQueue.NotificationSource,
		                Date(1,1,1),
		                Date(1,1,1));
		
	EndDo;
	
EndProcedure

Procedure AnalysisPlannedPayments(NotificationKind)

	Query = New Query;
	Query.Text = "
	|SELECT
	|	CustomerNotificationKinds.GroupOfMailoutsAndNotifications,
	|	GroupsOfMailoutsAndNotifications.Forced,
	|	GroupsOfMailoutsAndNotifications.SendToCustomer,
	|	GroupsOfMailoutsAndNotifications.SendToRoleContactPersons
	|FROM
	|	Catalog.CustomerNotificationKinds AS CustomerNotificationKinds
	|		INNER JOIN Catalog.GroupsOfMailoutsAndNotifications AS GroupsOfMailoutsAndNotifications
	|		ON CustomerNotificationKinds.GroupOfMailoutsAndNotifications = GroupsOfMailoutsAndNotifications.Ref
	|WHERE
	|	CustomerNotificationKinds.Ref = &NotificationKind";
	
	Query.SetParameter("NotificationKind", NotificationKind);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Query = New Query;
	
	If Selection.Forced Then
		
		If Not Selection.SendToCustomer And Not Selection.SendToRoleContactPersons Then
			Return;
		EndIf;
		
		Query.Text = "
		|SELECT
		|	CalculationData.Partner AS NotificationSource,
		|	SUM(CalculationData.AmountDueBalance) AS SumBalance
		|FROM (SELECT
		|		CustomersARAPAccountingBalance.AccountingDimensionByPartners.Partner AS Partner,
		|		CustomersARAPAccountingBalance.AmountDueBalance AS AmountDueBalance
		|	FROM
		|		AccumulationRegister.CustomersARAPAccounting.Balance(DATEADD(&CurrentDate, DAY, 2), ) AS CustomersARAPAccountingBalance
		|			LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|			ON CustomersARAPAccountingBalance.AccountingDimensionByPartners.Partner = EventQueueForNotificationsToCustomers.NotificationSource
		|				AND (EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind)
		|	WHERE
		|		NOT &NewOnlineARAPAccounting
		|		AND EventQueueForNotificationsToCustomers.NotificationSource IS NULL 
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CustomersARAPAccountingByDueDatesBalance.AccountingDimensionByPartners.Partner AS Partner,
		|		CustomersARAPAccountingByDueDatesBalance.DebtBalance AS AmountDueBalance
		|	FROM
		|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(, PlannedRepaymentDate < BEGINOFPERIOD(DATEADD(&CurrentDate, DAY, 2), DAY)) AS CustomersARAPAccountingByDueDatesBalance
		|			LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|			ON CustomersARAPAccountingByDueDatesBalance.AccountingDimensionByPartners.Partner = EventQueueForNotificationsToCustomers.NotificationSource
		|				AND (EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind)
		|	WHERE
		|		&NewOnlineARAPAccounting
		|		AND EventQueueForNotificationsToCustomers.NotificationSource IS NULL 
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CustomersARAPAccountingCashFlowPlanBalance.AccountingDimensionByPartners.Partner AS Partner,
		|		CustomersARAPAccountingCashFlowPlanBalance.AmountDueBalance AS AmountDueBalance
		|	FROM
		|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(, PlannedRepaymentDate < BEGINOFPERIOD(DATEADD(&CurrentDate, DAY, 2), DAY) ) AS CustomersARAPAccountingCashFlowPlanBalance
		|			LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|			ON CustomersARAPAccountingCashFlowPlanBalance.AccountingDimensionByPartners.Partner = EventQueueForNotificationsToCustomers.NotificationSource
		|				AND (EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind)
		|	WHERE
		|		&NewOnlineARAPAccounting
		|		AND EventQueueForNotificationsToCustomers.NotificationSource IS NULL 
		|	) AS CalculationData
		|	
		|GROUP BY
		|	CalculationData.Partner
		|
		|HAVING
		|	SUM(CalculationData.AmountDueBalance) > 0";
		
	Else
		
		Query.Text = "
		|SELECT
		|	CalculationData.Partner AS NotificationSource,
		|	SUM(CalculationData.AmountDueBalance) AS AmountDueBalance
		|FROM (SELECT
		|		CustomersARAPAccountingBalance.AccountingDimensionByPartners.Partner AS Partner,
		|		CustomersARAPAccountingBalance.AmountDueBalance AS AmountDueBalance
		|	FROM
		|		AccumulationRegister.CustomersARAPAccounting.Balance(
		|				DATEADD(&CurrentDate, DAY, 2),
		|				NOT &NewOnlineARAPAccounting
		|				AND AccountingDimensionByPartners.Partner IN
		|					(SELECT
		|						SubscriptionsToCustomerMailoutsAndNotifications.Owner
		|					FROM
		|						Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
		|							LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|							ON
		|								SubscriptionsToCustomerMailoutsAndNotifications.Owner = EventQueueForNotificationsToCustomers.NotificationSource
		|									AND EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind
		|					WHERE
		|						SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications
		|						AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
		|						AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
		|						AND (SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer
		|							OR SubscriptionsToCustomerMailoutsAndNotifications.NumberOfAddresseesContactPersons > 0)
		|						AND EventQueueForNotificationsToCustomers.NotificationSource IS NULL )) AS CustomersARAPAccountingBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CustomersARAPAccountingByDueDatesBalance.AccountingDimensionByPartners.Partner AS Partner,
		|		CustomersARAPAccountingByDueDatesBalance.DebtBalance AS AmountDueBalance
		|	FROM
		|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
		|				,
		|				PlannedRepaymentDate < BEGINOFPERIOD(DATEADD(&CurrentDate, DAY, 2), DAY)
		|				AND &NewOnlineARAPAccounting
		|				AND AccountingDimensionByPartners.Partner IN
		|					(SELECT
		|						SubscriptionsToCustomerMailoutsAndNotifications.Owner
		|					FROM
		|						Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
		|							LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|							ON
		|								SubscriptionsToCustomerMailoutsAndNotifications.Owner = EventQueueForNotificationsToCustomers.NotificationSource
		|									AND EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind
		|					WHERE
		|						SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications
		|						AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
		|						AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
		|						AND (SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer
		|							OR SubscriptionsToCustomerMailoutsAndNotifications.NumberOfAddresseesContactPersons > 0)
		|						AND EventQueueForNotificationsToCustomers.NotificationSource IS NULL )) AS CustomersARAPAccountingByDueDatesBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CustomersARAPAccountingCashFlowPlanBalance.AccountingDimensionByPartners.Partner AS Partner,
		|		CustomersARAPAccountingCashFlowPlanBalance.AmountDueBalance AS AmountDueBalance
		|	FROM
		|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(
		|				,
		|				PlannedRepaymentDate < BEGINOFPERIOD(DATEADD(&CurrentDate, DAY, 2), DAY)
		|				AND &NewOnlineARAPAccounting
		|				AND AccountingDimensionByPartners.Partner IN
		|					(SELECT
		|						SubscriptionsToCustomerMailoutsAndNotifications.Owner
		|					FROM
		|						Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
		|							LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|							ON
		|								SubscriptionsToCustomerMailoutsAndNotifications.Owner = EventQueueForNotificationsToCustomers.NotificationSource
		|									AND EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind
		|					WHERE
		|						SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications
		|						AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
		|						AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
		|						AND (SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer
		|							OR SubscriptionsToCustomerMailoutsAndNotifications.NumberOfAddresseesContactPersons > 0)
		|						AND EventQueueForNotificationsToCustomers.NotificationSource IS NULL )) AS CustomersARAPAccountingCashFlowPlanBalance
		|	) AS CalculationData
		|GROUP BY
		|	CalculationData.Partner
		|
		|HAVING
		|	SUM(CalculationData.AmountDueBalance) > 0";
		
	EndIf;
	
	DateOfAnalysis = CurrentSessionDate();
	
	Query.SetParameter("CurrentDate", DateOfAnalysis);
	Query.SetParameter("NotificationKind", NotificationKind);
	Query.SetParameter("GroupOfMailoutsAndNotifications", Selection.GroupOfMailoutsAndNotifications);
	Query.SetParameter("NewOnlineARAPAccounting", Constants.NewOnlineARAPAccounting.Get());
	
	SamplingQueue = Query.Execute().Select();
		
	While SamplingQueue.Next() Do
		
		InformationRegisters.EventQueueForNotificationsToCustomers.ExecuteRecordToRegister(
		                NotificationKind,
		                SamplingQueue.NotificationSource,
		                SamplingQueue.NotificationSource,
		                Date(1, 1, 1),
		                BegOfDay(DateOfAnalysis + 86400 * 2));
		
	EndDo;

EndProcedure

Procedure AnalysisPlannedShipments(NotificationKind)

	Query = New Query;
	Query.Text = "
	|SELECT
	|	CustomerNotificationKinds.GroupOfMailoutsAndNotifications,
	|	GroupsOfMailoutsAndNotifications.Forced,
	|	GroupsOfMailoutsAndNotifications.SendToCustomer,
	|	GroupsOfMailoutsAndNotifications.SendToRoleContactPersons,
	|	GroupsOfMailoutsAndNotifications.SendToAContactPersonOfANotificationObject
	|FROM
	|	Catalog.CustomerNotificationKinds AS CustomerNotificationKinds
	|		INNER JOIN Catalog.GroupsOfMailoutsAndNotifications AS GroupsOfMailoutsAndNotifications
	|		ON CustomerNotificationKinds.GroupOfMailoutsAndNotifications = GroupsOfMailoutsAndNotifications.Ref
	|WHERE
	|	CustomerNotificationKinds.Ref = &NotificationKind";
	
	Query.SetParameter("NotificationKind", NotificationKind);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Query = New Query;
	
	If Selection.Forced Then
		
		If Not Selection.SendToCustomer And Not Selection.SendToRoleContactPersons And Not Selection.SendToAContactPersonOfANotificationObject Then
			Return;
		EndIf;
		
		Query.Text =
		"SELECT DISTINCT
		|	Filter.ReferenceOrder AS NotificationSource,
		|	Filter.ReferenceOrder.Partner AS Subscriber,
		|	&EventDate AS EventDate
		|FROM
		|	#ShipmentOrdersTurnoverExpanded AS Filter
		|		INNER JOIN AccumulationRegister.ShipmentAndReturnReferences AS RequirementsForRegistration__
		|		ON Filter.ReferenceOrder = RequirementsForRegistration__.ReferenceOrder
		|		AND Filter.RowCode = RequirementsForRegistration__.RowCode
		|		AND (Filter.ForRegistrationQuantityTurnover
		|			- Filter.IssuedQuantityTurnover) > 0
		|		AND RequirementsForRegistration__.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
		|		AND RequirementsForRegistration__.Count > 0
		|		AND RequirementsForRegistration__.Active
		|		AND RequirementsForRegistration__.Period = &EventDate
		|		LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|		ON Filter.ReferenceOrder.Partner = EventQueueForNotificationsToCustomers.Subscriber
		|		AND Filter.ReferenceOrder = EventQueueForNotificationsToCustomers.NotificationSource
		|		AND EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind
		|WHERE
		|	EventQueueForNotificationsToCustomers.NotificationSource IS NULL";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"ReferenceOrder IN (SELECT
			|			OpenedOrders.ReferenceOrder 
			|		FROM
			|			InformationRegister.ShipmentAndReturnReferencesToFulfill AS OpenedOrders
			|		WHERE
			|			VALUETYPE(OpenedOrders.ReferenceOrder) = TYPE(Document.SalesOrder))";
		TableFormationParameters.Group = "ReferenceOrder, RowCode";
		TableFormationParameters.Indicators = "ToRegister, Issued_1";
		TableFormationParameters.Resources = "Count";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		Query.Text = StrReplace(Query.Text,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
	Else
		
		Query.Text =
		"SELECT DISTINCT
		|	Filter.ReferenceOrder AS NotificationSource,
		|	Filter.ReferenceOrder.Partner AS Subscriber,
		|	&EventDate AS EventDate
		|FROM
		|	#ShipmentOrdersTurnoverExpanded AS Filter
		|		INNER JOIN AccumulationRegister.ShipmentAndReturnReferences AS RequirementsForRegistration__
		|		ON Filter.ReferenceOrder = RequirementsForRegistration__.ReferenceOrder
		|		AND Filter.RowCode = RequirementsForRegistration__.RowCode
		|		AND (Filter.ForRegistrationQuantityTurnover
		|			- Filter.IssuedQuantityTurnover) > 0
		|		AND RequirementsForRegistration__.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
		|		AND RequirementsForRegistration__.Count > 0
		|		AND RequirementsForRegistration__.Active
		|		AND RequirementsForRegistration__.Period = &EventDate
		|		INNER JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
		|		ON Filter.ReferenceOrder.Partner = SubscriptionsToCustomerMailoutsAndNotifications.Owner
		|		AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
		|		AND SubscriptionsToCustomerMailoutsAndNotifications.SendToAContactPersonOfANotificationObject
		|		AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
		|		AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications
		|		LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|		ON Filter.ReferenceOrder.Partner = EventQueueForNotificationsToCustomers.Subscriber
		|		AND Filter.ReferenceOrder = EventQueueForNotificationsToCustomers.NotificationSource
		|		AND EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind
		|WHERE
		|	EventQueueForNotificationsToCustomers.NotificationSource IS NULL";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"ReferenceOrder IN (SELECT
			|			OpenedOrders.ReferenceOrder 
			|		FROM
			|			InformationRegister.ShipmentAndReturnReferencesToFulfill AS OpenedOrders
			|		WHERE
			|			VALUETYPE(OpenedOrders.ReferenceOrder) = TYPE(Document.SalesOrder))";
		TableFormationParameters.Group = "ReferenceOrder, RowCode";
		TableFormationParameters.Indicators = "ToRegister, Issued_1";
		TableFormationParameters.Resources = "Count";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		Query.Text = StrReplace(Query.Text,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
	EndIf;
	
	DateOfAnalysis = CurrentSessionDate(); 
	
	Query.SetParameter("EventDate", BegOfDay(DateOfAnalysis + 86400));
	Query.SetParameter("NotificationKind", NotificationKind);
	Query.SetParameter("GroupOfMailoutsAndNotifications", Selection.GroupOfMailoutsAndNotifications);
	
	SamplingQueue = Query.Execute().Select();
		
	While SamplingQueue.Next() Do
		
		InformationRegisters.EventQueueForNotificationsToCustomers.ExecuteRecordToRegister(
		                NotificationKind,
		                SamplingQueue.Subscriber,
		                SamplingQueue.NotificationSource,
		                Date(1, 1, 1),
		                EndOfDay(SamplingQueue.EventDate));
		
	EndDo;

EndProcedure

Procedure AnalysisEndOfSurvey(NotificationKind)

	Query = New Query;
	Query.Text = "
	|SELECT
	|	CustomerNotificationKinds.GroupOfMailoutsAndNotifications,
	|	GroupsOfMailoutsAndNotifications.Forced,
	|	GroupsOfMailoutsAndNotifications.SendToCustomer,
	|	GroupsOfMailoutsAndNotifications.SendToRoleContactPersons,
	|	GroupsOfMailoutsAndNotifications.SendToAContactPersonOfANotificationObject
	|FROM
	|	Catalog.CustomerNotificationKinds AS CustomerNotificationKinds
	|		INNER JOIN Catalog.GroupsOfMailoutsAndNotifications AS GroupsOfMailoutsAndNotifications
	|		ON CustomerNotificationKinds.GroupOfMailoutsAndNotifications = GroupsOfMailoutsAndNotifications.Ref
	|WHERE
	|	CustomerNotificationKinds.Ref = &NotificationKind";
	
	Query.SetParameter("NotificationKind", NotificationKind);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Query = New Query;
	
	If Selection.Forced Then
		
		If (Not Selection.SendToCustomer) Or (Not Selection.SendToAContactPersonOfANotificationObject) Then
			Return;
		EndIf;
		
		Query.Text = "
		|SELECT
		|	PollPurpose.Ref,
		|	PollPurpose.RespondentsType,
		|	PollPurpose.FreeSurvey
		|INTO EndingSurveys
		|FROM
		|	Document.PollPurpose AS PollPurpose
		|WHERE
		|	PollPurpose.Posted
		|	AND PollPurpose.StartDate < &CurrentDate
		|	AND DAY(PollPurpose.EndDate) = DAY(DATEADD(&CurrentDate, DAY, 2))
		|	AND (PollPurpose.RespondentsType = VALUE(Catalog.Partners.EmptyRef)
		|			OR PollPurpose.RespondentsType = VALUE(Catalog.ContactPersonsForPartners.EmptyRef))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	EndingSurveys.Ref AS Survey,
		|	Partners.Ref AS Respondent,
		|	EndingSurveys.RespondentsType
		|INTO SurveysRespondents
		|FROM
		|	EndingSurveys AS EndingSurveys
		|		INNER JOIN Catalog.Partners AS Partners
		|		ON (TRUE)
		|			AND (EndingSurveys.FreeSurvey)
		|			AND (EndingSurveys.RespondentsType = VALUE(Catalog.Partners.EmptyRef))
		|			AND (NOT Partners.DeletionMark)
		|
		|UNION ALL
		|
		|SELECT
		|	EndingSurveys.Ref,
		|	ContactPersons.Ref,
		|	EndingSurveys.RespondentsType
		|FROM
		|	EndingSurveys AS EndingSurveys
		|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersons
		|		ON (TRUE)
		|			AND (EndingSurveys.FreeSurvey)
		|			AND (EndingSurveys.RespondentsType = VALUE(Catalog.ContactPersonsForPartners.EmptyRef))
		|			AND (NOT ContactPersons.DeletionMark)
		|
		|UNION ALL
		|
		|SELECT
		|	EndingSurveys.Ref,
		|	PollPurposeRespondents.Respondent,
		|	EndingSurveys.RespondentsType
		|FROM
		|	EndingSurveys AS EndingSurveys
		|		INNER JOIN Document.PollPurpose.Respondents AS PollPurposeRespondents
		|		ON EndingSurveys.Ref = PollPurposeRespondents.Ref
		|			AND (NOT EndingSurveys.FreeSurvey)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	SurveysRespondents.Survey AS NotificationSource,
		|	CASE
		|		WHEN SurveysRespondents.RespondentsType = VALUE(Catalog.Partners.EmptyRef)
		|			THEN SurveysRespondents.Respondent
		|		ELSE SurveysRespondents.Respondent.Owner
		|	END AS Subscriber,
		|	ENDOFPERIOD(DATEADD(&CurrentDate, DAY, 2), DAY) AS EmailSendingRelevanceDate
		|INTO RespondentsWhoDidNotCompleteSurveys
		|FROM
		|	SurveysRespondents AS SurveysRespondents
		|		LEFT JOIN Document.Questionnaire AS Questionnaire
		|		ON SurveysRespondents.Survey = Questionnaire.Survey
		|			AND SurveysRespondents.Respondent = Questionnaire.Respondent
		|			AND (Questionnaire.Posted)
		|WHERE
		|	Questionnaire.Ref IS NULL 
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RespondentsWhoDidNotCompleteSurveys.NotificationSource,
		|	RespondentsWhoDidNotCompleteSurveys.Subscriber,
		|	RespondentsWhoDidNotCompleteSurveys.EmailSendingRelevanceDate
		|FROM
		|	RespondentsWhoDidNotCompleteSurveys AS RespondentsWhoDidNotCompleteSurveys
		|		LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|		ON RespondentsWhoDidNotCompleteSurveys.NotificationSource = EventQueueForNotificationsToCustomers.NotificationSource
		|			AND RespondentsWhoDidNotCompleteSurveys.Subscriber = EventQueueForNotificationsToCustomers.Subscriber
		|			AND (EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind)
		|WHERE
		|	EventQueueForNotificationsToCustomers.NotificationKind IS NULL ";
		
	Else
		
		Query.Text = "
		|SELECT
		|	PollPurpose.Ref,
		|	PollPurpose.RespondentsType,
		|	PollPurpose.FreeSurvey
		|INTO EndingSurveys
		|FROM
		|	Document.PollPurpose AS PollPurpose
		|WHERE
		|	PollPurpose.Posted
		|	AND PollPurpose.StartDate < &CurrentDate
		|	AND DAY(PollPurpose.EndDate) = DAY(DATEADD(&CurrentDate, DAY, 2))
		|	AND (PollPurpose.RespondentsType = VALUE(Catalog.Partners.EmptyRef)
		|			OR PollPurpose.RespondentsType = VALUE(Catalog.ContactPersonsForPartners.EmptyRef))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	EndingSurveys.Ref AS Survey,
		|	Partners.Ref AS Respondent,
		|	EndingSurveys.RespondentsType
		|INTO SurveysRespondents
		|FROM
		|	EndingSurveys AS EndingSurveys
		|		INNER JOIN Catalog.Partners AS Partners
		|		ON (TRUE)
		|			AND (EndingSurveys.FreeSurvey)
		|			AND (EndingSurveys.RespondentsType = VALUE(Catalog.Partners.EmptyRef))
		|			AND (NOT Partners.DeletionMark)
		|
		|UNION ALL
		|
		|SELECT
		|	EndingSurveys.Ref,
		|	ContactPersons.Ref,
		|	EndingSurveys.RespondentsType
		|FROM
		|	EndingSurveys AS EndingSurveys
		|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersons
		|		ON (TRUE)
		|			AND (EndingSurveys.FreeSurvey)
		|			AND (EndingSurveys.RespondentsType = VALUE(Catalog.ContactPersonsForPartners.EmptyRef))
		|			AND (NOT ContactPersons.DeletionMark)
		|
		|UNION ALL
		|
		|SELECT
		|	EndingSurveys.Ref,
		|	PollPurposeRespondents.Respondent,
		|	EndingSurveys.RespondentsType
		|FROM
		|	EndingSurveys AS EndingSurveys
		|		INNER JOIN Document.PollPurpose.Respondents AS PollPurposeRespondents
		|		ON EndingSurveys.Ref = PollPurposeRespondents.Ref
		|			AND (NOT EndingSurveys.FreeSurvey)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	SurveysRespondents.Survey AS NotificationSource,
		|	CASE
		|		WHEN SurveysRespondents.RespondentsType = VALUE(Catalog.Partners.EmptyRef)
		|			THEN SurveysRespondents.Respondent
		|		ELSE SurveysRespondents.Respondent.Owner
		|	END AS Subscriber,
		|	ENDOFPERIOD(DATEADD(&CurrentDate, DAY, 2), DAY) AS EmailSendingRelevanceDate
		|INTO RespondentsWhoDidNotCompleteSurveys
		|FROM
		|	SurveysRespondents AS SurveysRespondents
		|		LEFT JOIN Document.Questionnaire AS Questionnaire
		|		ON SurveysRespondents.Survey = Questionnaire.Survey
		|			AND SurveysRespondents.Respondent = Questionnaire.Respondent
		|			AND (Questionnaire.Posted)
		|WHERE
		|	Questionnaire.Ref IS NULL 
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RespondentsWhoDidNotCompleteSurveys.NotificationSource,
		|	RespondentsWhoDidNotCompleteSurveys.Subscriber,
		|	RespondentsWhoDidNotCompleteSurveys.EmailSendingRelevanceDate
		|FROM
		|	RespondentsWhoDidNotCompleteSurveys AS RespondentsWhoDidNotCompleteSurveys
		|		INNER JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
		|		ON RespondentsWhoDidNotCompleteSurveys.Subscriber = SubscriptionsToCustomerMailoutsAndNotifications.Owner
		|			AND (SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid)
		|			AND (SubscriptionsToCustomerMailoutsAndNotifications.SendToAContactPersonOfANotificationObject)
		|			AND (SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer)
		|			AND (NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark)
		|			AND (SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications)
		|		LEFT JOIN InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|		ON RespondentsWhoDidNotCompleteSurveys.NotificationSource = EventQueueForNotificationsToCustomers.NotificationSource
		|			AND RespondentsWhoDidNotCompleteSurveys.Subscriber = EventQueueForNotificationsToCustomers.Subscriber
		|			AND (EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind)
		|WHERE
		|	EventQueueForNotificationsToCustomers.NotificationKind IS NULL ";
		
	EndIf;
	
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("NotificationKind", NotificationKind);
	Query.SetParameter("GroupOfMailoutsAndNotifications", Selection.GroupOfMailoutsAndNotifications);
	
	SamplingQueue = Query.Execute().Select();
		
	While SamplingQueue.Next() Do
		
		InformationRegisters.EventQueueForNotificationsToCustomers.ExecuteRecordToRegister(
		                NotificationKind,
		                SamplingQueue.Subscriber,
		                SamplingQueue.NotificationSource,
		                Date(1, 1, 1),
		                EndOfDay(SamplingQueue.EmailSendingRelevanceDate));
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ProformaInvoices

Procedure ProcessInvoiceChanges(Source, EventType, WriteMode)

	CreatingInvoiceIsUsed      = MailoutsAndNotificationsToCustomersCached.EventTypeUsed(Enums.NotificationEventTypes.AccountStatement);
	ChangingAccountIsUsed     = MailoutsAndNotificationsToCustomersCached.EventTypeUsed(Enums.NotificationEventTypes.ChangeOfAccount);
	AccountCancellationIsUsed = MailoutsAndNotificationsToCustomersCached.EventTypeUsed(Enums.NotificationEventTypes.CommercialInvoiceCancellation);
	
	If EventType = "BeforeWrite" Then
		
		If WriteMode <> DocumentWriteMode.Posting Then
			Return;
		EndIf;
		
		If Not CreatingInvoiceIsUsed And Not ChangingAccountIsUsed And Not AccountCancellationIsUsed Then
			Return;
		EndIf;
		
		Source.AdditionalProperties.Insert("DataBeforeRecording", CustomerInvoiceDetails(Source.Ref));
		
	ElsIf EventType = "OnWrite" Then
		
		
		If Not Source.AdditionalProperties.Property("DataBeforeRecording") Then
			Return;
		EndIf;
		
		DataBeforeRecording = Source.AdditionalProperties.DataBeforeRecording;
		
		If DataBeforeRecording.Count() = 0 Then
			
			If CreatingInvoiceIsUsed Then
				
				WritingToQueueByEventType(Enums.NotificationEventTypes.AccountStatement,
				                            Source.Ref,
				                            Source.Partner,
				                            Date(1, 1, 1),
				                            CurrentSessionDate()+ 86400*3);
				
				Return;
				
			EndIf;
			
		Else
			
			If Not DataBeforeRecording[0].Canceled_ And Source.Canceled_ Then
				
				If AccountCancellationIsUsed Then
					
					WritingToQueueByEventType(Enums.NotificationEventTypes.CommercialInvoiceCancellation,
					                            Source.Ref,
					                            Source.Partner,
					                            Date(1, 1, 1),
					                            CurrentSessionDate()+ 86400*3);
					
					Return;
					
				EndIf;
				
			EndIf;
			
			If DataBeforeRecording[0].BankAccount <> Source.BankAccount 
				Or DataBeforeRecording[0].Currency <> Source.Currency
				Or DataBeforeRecording[0].Contract <> Source.Contract
				Or DataBeforeRecording[0].CashAccount <> Source.CashAccount
				Or DataBeforeRecording[0].Counterparty <> Source.Counterparty
				Or DataBeforeRecording[0].DocumentAmount <> Source.DocumentAmount
				Or DataBeforeRecording[0].PaymentMethod <> Source.PaymentMethod Then
				
				If ChangingAccountIsUsed Then
					
					WritingToQueueByEventType(Enums.NotificationEventTypes.ChangeOfAccount,
					                            Source.Ref,
					                            Source.Partner,
					                            Date(1, 1, 1),
					                            CurrentSessionDate()+ 86400*3);
					
					Return;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;

EndProcedure

Function CustomerInvoiceDetails(ProformaInvoice)

	Query = New Query;
	Query.Text = "
	|SELECT
	|	CustomerCommercialInvoice.DocumentAmount,
	|	CustomerCommercialInvoice.Currency,
	|	CustomerCommercialInvoice.PaymentMethod,
	|	CustomerCommercialInvoice.BankAccount,
	|	CustomerCommercialInvoice.CashAccount,
	|	CustomerCommercialInvoice.Canceled_,
	|	CustomerCommercialInvoice.Counterparty,
	|	CustomerCommercialInvoice.Contract
	|FROM
	|	Document.CustomerCommercialInvoice AS CustomerCommercialInvoice
	|WHERE
	|	CustomerCommercialInvoice.Ref = &ProformaInvoice
	|	AND CustomerCommercialInvoice.Posted";
	
	Query.SetParameter("ProformaInvoice", ProformaInvoice);
	
	Return Query.Execute().Unload();

EndFunction

#EndRegion

#Region StateOfOrders

Procedure HandleChangingStateOfCustomerOrders(Source, EventType)

	TypeOfAlertEvent = Enums.NotificationEventTypes.OrderStatusChange;
	
	If Source.Filter.Find("OrderDocument") = Undefined Then
		Return;
	EndIf;
	
	SalesOrder = Source.Filter.OrderDocument.Value;
	
	If EventType = "BeforeWrite" Then
		
		If Not MailoutsAndNotificationsToCustomersCached.EventTypeUsed(TypeOfAlertEvent) Then
			Return;
		EndIf;
		
		If Not TypeOf(SalesOrder) = Type("DocumentRef.SalesOrder") Then
			Return;
		EndIf;
		
		Source.AdditionalProperties.Insert("DataBeforeRecording", OrderStateRegisterData(SalesOrder));
		
		
	ElsIf EventType = "OnWrite" Then
		
		If Not Source.AdditionalProperties.Property("DataBeforeRecording") Then
			 Return;
		EndIf;
		
		DataAfterRecording = OrderStateRegisterData(SalesOrder);
		
		If DataAfterRecording.Count() = 0 Then
			Return;
		EndIf;
		
		If Not TablesAreDifferent(DataAfterRecording, Source.AdditionalProperties.DataBeforeRecording) Then
			Return;
		EndIf;
		
		CurrentData = DataAfterRecording[0];
		
		If Not CurrentData.Posted Then
			Return;
		EndIf;
		
		If CurrentData.State = Enums.SalesOrderStates.ReadyForClosure Then
			
			Return;
			
		EndIf;
		
		ArrayOfAlertTypes = MailoutsAndNotificationsToCustomersCached.CurrentNotificationKindsByEventType(TypeOfAlertEvent);
		Recipient = CurrentData.Partner;
		
		For Each NotificationKind In ArrayOfAlertTypes Do
		
			InformationRegisters.EventQueueForNotificationsToCustomers.ExecuteRecordToRegister(NotificationKind,
			                                                                             Recipient,
			                                                                             SalesOrder,
			                                                                             Date(1, 1, 1),
			                                                                             CurrentSessionDate() + 86400);
		
		EndDo;
		
	EndIf;

EndProcedure

Function OrderStateRegisterData(SalesOrder)

	Query = New Query;
	Query.Text = "
	|SELECT
	|	ISNULL(SalesOrderStates.State, UNDEFINED) AS State,
	|	SalesOrder.Posted,
	|	SalesOrder.Partner
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|		LEFT JOIN InformationRegister.SalesOrderStates AS SalesOrderStates
	|		ON SalesOrderStates.OrderDocument = SalesOrder.Ref
	|WHERE
	|	SalesOrder.Ref = &SalesOrder";
	
	Query.SetParameter("SalesOrder", SalesOrder);
	
	Return Query.Execute().Unload();

EndFunction

#EndRegion

#Region AccrualWriteOffOfBonuses

Procedure ProcessChangeOfBonusPoints(Source, EventType);

	AccrualOfBonusesIsUsed = MailoutsAndNotificationsToCustomersCached.EventTypeUsed(Enums.NotificationEventTypes.BonusAccrual);
	DebitingBonusesIsUsed = MailoutsAndNotificationsToCustomersCached.EventTypeUsed(Enums.NotificationEventTypes.DeductionOfBonuses);
	
	If Source.Filter.Find("Recorder") = Undefined Then
		Return;
	EndIf;
		
	Recorder = Source.Filter.Recorder.Value;
	
	If EventType = "BeforeWrite" Then
		
		If Not AccrualOfBonusesIsUsed And Not DebitingBonusesIsUsed Then
			Return;
		EndIf;
		
		If TypeOf(Recorder) = Type("DocumentRef.RetailSalesReport") Then
			CashRegisterShift = Common.ObjectAttributeValue(Recorder, "CashRegisterShift");
			If Not CashRegisterShift.IsEmpty() Then
				Return;
			EndIf;
		EndIf;
		
		If ArchiveReceipt(Recorder) Then
			Return;
		EndIf;
		
		Source.AdditionalProperties.Insert("DataBeforeRecording", RegisterDataAccrualOfBonuses(Recorder));
		
	ElsIf EventType = "OnWrite" Then
		
		If Not Source.AdditionalProperties.Property("DataBeforeRecording") Then
			 Return;
		EndIf;
		
		If ArchiveReceipt(Recorder) Then
			Return;
		EndIf;
		
		DataAfterRecording = RegisterDataAccrualOfBonuses(Recorder);
		
		If TablesAreDifferent(DataAfterRecording.Accrual, Source.AdditionalProperties.DataBeforeRecording.Accrual) Then
			
			ArrayOfIntendedRecipients = DataAfterRecording.Accrual.UnloadColumn("Partner");
			For Each Recipient In ArrayOfIntendedRecipients Do
				
				WritingToQueueByEventType(Enums.NotificationEventTypes.BonusAccrual,
				                            Recorder,
				                            Recipient,
				                            Date(1, 1, 1),
				                            CurrentSessionDate() + 86400);
			EndDo;
			
		EndIf;
		
		If TablesAreDifferent(DataAfterRecording.WriteOff, Source.AdditionalProperties.DataBeforeRecording.WriteOff) Then
		
			ArrayOfIntendedRecipients = DataAfterRecording.WriteOff.UnloadColumn("Partner");
			For Each Recipient In ArrayOfIntendedRecipients Do
				
				WritingToQueueByEventType(Enums.NotificationEventTypes.DeductionOfBonuses,
				                            Recorder,
				                            Recipient,
				                            Date(1, 1, 1),
				                            CurrentSessionDate() + 86400);
			EndDo;
		
		EndIf;
		
	EndIf;
	
EndProcedure

Function RegisterDataAccrualOfBonuses(Recorder)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	BonusPoints.Partner AS Partner,
	|	SUM(BonusPoints.Accrued) AS Accrued
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|WHERE
	|	BonusPoints.Recorder = &Recorder
	|	AND BonusPoints.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|GROUP BY
	|	BonusPoints.Partner
	|
	|ORDER BY
	|	Partner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BonusPoints.Partner AS Partner,
	|	SUM(BonusPoints.Accrued) AS Accrued
	|FROM
	|	AccumulationRegister.BonusPoints AS BonusPoints
	|WHERE
	|	BonusPoints.Recorder = &Recorder
	|	AND BonusPoints.RecordType = VALUE(AccumulationRecordType.Expense)
	|
	|GROUP BY
	|	BonusPoints.Partner
	|
	|ORDER BY
	|	Partner";
	
	Query.SetParameter("Recorder", Recorder);
	Result = Query.ExecuteBatch();
	
	StructureOfData = New Structure;
	StructureOfData.Insert("Accrual", Result[0].Unload());
	StructureOfData.Insert("WriteOff", Result[1].Unload());
	
	Return StructureOfData;
	
EndFunction

Function ArchiveReceipt(Recorder)
	
	If TypeOf(Recorder) = Type("DocumentRef.CashRegisterReceipt") Or TypeOf(Recorder) = Type("DocumentRef.CashRegisterReceiptReturn") Then
		Return Common.ObjectAttributeValue(Recorder, "Archived");
	Else
		Return False;
	EndIf
	
EndFunction

#EndRegion

#Region ReceiptOfPayment

Procedure ProcessChangeInPaymentReceipt(Source, EventType, WriteMode)

	PaymentReceiptIsUsed = MailoutsAndNotificationsToCustomersCached.EventTypeUsed(Enums.NotificationEventTypes.CashReceiptFromCustomer);
	
	If EventType = "BeforeWrite" Then
		
		If WriteMode <> DocumentWriteMode.Posting Then
			Return;
		EndIf;
		
		If Not PaymentReceiptIsUsed Then
			Return;
		EndIf;
		
		Source.AdditionalProperties.Insert("DataBeforeRecording", PaymentReceiptData(Source.Ref));
		
	ElsIf EventType = "OnWrite" Then
		
		If Not Source.AdditionalProperties.Property("DataBeforeRecording") Then
			Return;
		EndIf;
		
		DecryptionOfPaymentBeforeRecording = Source.AdditionalProperties.DataBeforeRecording;
		DecryptionOfPaymentBeforeRecording.GroupBy("Partner,Currency", "Sum");
		
		ARAPDetails = Source.ARAPDetails.Unload(,"Partner,Sum");
		ARAPDetails.Columns.Add("Currency");
		ARAPDetails.GroupBy("Partner", "Sum");
		
		For Each CurRow In ARAPDetails Do
			
			LineBeforeRecording = DecryptionOfPaymentBeforeRecording.Find(CurRow.Partner, "Partner");
			
			If LineBeforeRecording = Undefined
				Or LineBeforeRecording.Currency <> Source.Currency
				Or LineBeforeRecording.Sum <> CurRow.Sum Then
				
				WritingToQueueByEventType(Enums.NotificationEventTypes.CashReceiptFromCustomer,
				                            Source.Ref,
				                            CurRow.Partner,
				                            Date(1, 1, 1),
				                            CurrentSessionDate()+ 86400*3);
				
			EndIf;
			
		EndDo;
		
	EndIf;

EndProcedure

Function PaymentReceiptData(PaymentDocument)

	Query = New Query;
	Query.Text = "
		|SELECT
		|	CashAccountReceiptNoteARAPDetails.Partner AS Partner,
		|	CashAccountReceiptNoteARAPDetails.Sum AS Sum,
		|	CashAccountReceiptNoteARAPDetails.Ref.Currency AS Currency
		|FROM
		|	Document.CashAccountReceiptNote.ARAPDetails AS CashAccountReceiptNoteARAPDetails
		|WHERE
		|	CashAccountReceiptNoteARAPDetails.Ref = &PaymentDocument
		|	AND CashAccountReceiptNoteARAPDetails.Ref.Posted
		|	
		|UNION ALL
		|	
		|SELECT
		|	BankAccountReceiptNoteARAPDetails.Partner AS Partner,
		|	BankAccountReceiptNoteARAPDetails.Sum AS Sum,
		|	BankAccountReceiptNoteARAPDetails.Ref.Currency AS Currency
		|	
		|FROM
		|	Document.BankAccountReceiptNote.ARAPDetails AS BankAccountReceiptNoteARAPDetails
		|WHERE
		|	BankAccountReceiptNoteARAPDetails.Ref = &PaymentDocument
		|	AND BankAccountReceiptNoteARAPDetails.Ref.Posted
		|	
		|UNION ALL
		|	
		|SELECT
		|	PaymentCardTransactionARAPDetails.Partner AS Partner,
		|	PaymentCardTransactionARAPDetails.Sum AS Sum,
		|	PaymentCardTransactionARAPDetails.Ref.Currency AS Currency
		|	
		|FROM
		|	Document.PaymentCardTransaction.ARAPDetails AS PaymentCardTransactionARAPDetails
		|WHERE
		|	PaymentCardTransactionARAPDetails.Ref = &PaymentDocument
		|	AND PaymentCardTransactionARAPDetails.Ref.Posted
		|
		|";
	
	Query.SetParameter("PaymentDocument", PaymentDocument);
	
	Return Query.Execute().Unload();

EndFunction

#EndRegion

#Region CreatingInteractionsByQueueOfAlerts

// Gets data of the notification type
// 
// Parameters:
//  NotificationKind - CatalogRef.CustomerNotificationKinds - 
// Returns:
//  Undefined, QueryResultSelection - Contains:
//   * NotificationKind - CatalogRef.CustomerNotificationKinds -
//   * GroupOfMailoutsAndNotifications - CatalogRef.GroupsOfMailoutsAndNotifications - 
//   * DesignedForEmails - Boolean -
//   * DesignedForSMSMessage - Boolean -
//   * SMSMessageTemplate - CatalogRef.MessageTemplates -
//   * EmailTemplate - CatalogRef.MessageTemplates -
//   * SendingCondition - String -
//   * EventType - String -
//   * Forced - Boolean -
//   * Account - CatalogRef.EmailAccounts - 
//   * PartnerSContactDetailsKindForEmails - CatalogRef.ContactInformationKinds - 
//   * PartnerSContactDetailsKindForSMSMessage - CatalogRef.ContactInformationKinds - 
//   * ContactPersonSContactDetailsKindForEmails - CatalogRef.ContactInformationKinds - 
//   * ContactPersonSContactDetailsKindForSMSMessage - CatalogRef.ContactInformationKinds - 
//   * SendToCustomer - Boolean - 
//   * SendToAContactPersonOfANotificationObject - Boolean -
//   * SendToRoleContactPersons - Boolean -
//   * ContactRole - CatalogRef.RolesOfPartnerContactPersons - 
//   * EmployeeResponsible - CatalogRef.Users - 
//   * AccountUserName - String -
//   * AccountEmailAddress - String -
//   * DeleteEmailsAfterSend - Boolean -
//   * Description - String - 
//   * ConditionParameters - ValueTable - Contains:
//     ** ThisIsAPreviousMessageParameter - Boolean -
//     ** ParameterName - String -
//   * SendingConditionsAreUsed - Boolean -
//   
Function NotificationTypeData(NotificationKind)

	Query = New Query;
	Query.Text = "
	|SELECT
	|	CustomerNotificationKinds.Ref AS NotificationKind,
	|	CustomerNotificationKinds.GroupOfMailoutsAndNotifications,
	|	CustomerNotificationKinds.DesignedForEmails,
	|	CustomerNotificationKinds.DesignedForSMSMessage,
	|	CustomerNotificationKinds.SMSMessageTemplate,
	|	CustomerNotificationKinds.EmailTemplate,
	|	CustomerNotificationKinds.SendingCondition,
	|	CustomerNotificationKinds.EventType,
	|	GroupsOfMailoutsAndNotifications.Forced,
	|	GroupsOfMailoutsAndNotifications.Account,
	|	GroupsOfMailoutsAndNotifications.PartnerSContactDetailsKindForEmails,
	|	GroupsOfMailoutsAndNotifications.PartnerSContactDetailsKindForSMSMessage,
	|	GroupsOfMailoutsAndNotifications.ContactPersonSContactDetailsKindForEmails,
	|	GroupsOfMailoutsAndNotifications.ContactPersonSContactDetailsKindForSMSMessage,
	|	GroupsOfMailoutsAndNotifications.SendToCustomer,
	|	GroupsOfMailoutsAndNotifications.SendToAContactPersonOfANotificationObject,
	|	GroupsOfMailoutsAndNotifications.SendToRoleContactPersons,
	|	GroupsOfMailoutsAndNotifications.ContactRole,
	|	GroupsOfMailoutsAndNotifications.EmployeeResponsible,
	|	ISNULL(EmailAccounts.UserName, """") AS AccountUserName,
	|	ISNULL(EmailAccounts.Email, """") AS AccountEmailAddress,
	|	ISNULL(EmailAccountSettings.DeleteEmailsAfterSend, FALSE) AS DeleteEmailsAfterSend,
	|	CustomerNotificationKinds.Description,
	|	CustomerNotificationKinds.ConditionParameters.(
	|		ThisIsAPreviousMessageParameter,
	|		ParameterName
	|	),
	|	CustomerNotificationKinds.SendingConditionsAreUsed
	|FROM
	|	Catalog.CustomerNotificationKinds AS CustomerNotificationKinds
	|		INNER JOIN Catalog.GroupsOfMailoutsAndNotifications AS GroupsOfMailoutsAndNotifications
	|			LEFT JOIN Catalog.EmailAccounts AS EmailAccounts
	|				LEFT JOIN InformationRegister.EmailAccountSettings AS EmailAccountSettings
	|				ON EmailAccounts.Ref = EmailAccountSettings.EmailAccount
	|			ON GroupsOfMailoutsAndNotifications.Account = EmailAccounts.Ref
	|		ON CustomerNotificationKinds.GroupOfMailoutsAndNotifications = GroupsOfMailoutsAndNotifications.Ref
	|WHERE
	|	CustomerNotificationKinds.Ref = &CustomerNotificationKind
	|	AND NOT CustomerNotificationKinds.DeletionMark";
	
	Query.SetParameter("CustomerNotificationKind", NotificationKind);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	Return Selection;

EndFunction 

Procedure ProcessMessageQueueByAlertType(NotificationKind, DateOfProcessing );
	
	NotificationTypeData    = NotificationTypeData(NotificationKind);
	If NotificationTypeData = Undefined Then
		Return;
	EndIf;
	
	EventTypeData       = Enums.NotificationEventTypes.DataForProcessingAlertQueue(NotificationTypeData.EventType);
	RecipientData_       = RecipientDataByNotificationType(NotificationTypeData, DateOfProcessing, EventTypeData);
	MessageTemplateData = DataForAlertTypeTemplates(NotificationTypeData, DateOfProcessing, EventTypeData);
	
	ArrayOfCreatedInteractions = New Array;
	
	GenerateMessagesByNotificationType(NotificationTypeData, EventTypeData, RecipientData_,
	                                      MessageTemplateData, ArrayOfCreatedInteractions);
	
EndProcedure



// LongDesc
// 
// Parameters:
// 	NotificationTypeData - See NotificationTypeData
// 	EventTypeData - See Enums.NotificationEventTypes.DataForProcessingAlertQueue
// 	RecipientData_ - Map - LongDesc
// 	MessageTemplateData - See DataForAlertTypeTemplates
// 	ArrayOfCreatedInteractions - Array - LongDesc
//
Procedure GenerateMessagesByNotificationType(NotificationTypeData, EventTypeData, RecipientData_,
	                                            MessageTemplateData, ArrayOfCreatedInteractions)

	If NotificationTypeData.DesignedForEmails Then
		
		If MessageTemplateData.EmailTemplateData.TemplateData.TemplateByExternalDataProcessor Then
			
			For Each RecipientData In RecipientData_ Do
			
				SourceData__ = RecipientData_.Get(RecipientData.Key);
				If SourceData__ = Undefined Then
					Continue;
				EndIf;
				
				TemplateData = MessageTemplateData.EmailTemplateData.TemplateData; // See MessageTemplatesClientServer.TemplateParametersDetails
				
				EmailData = MessageTemplates.GenerateMessage(TemplateData.Ref,
				                                                      RecipientData.Key,
				                                                      New UUID);
				
				For Each DataBySubscriber In SourceData__ Do
					
					If Not DataBySubscriber.Value.Property("ArrayOfRecipients_")
						Or TypeOf(DataBySubscriber.Value.ArrayOfRecipients_) <> Type("Array")
						Or DataBySubscriber.Value.ArrayOfRecipients_.Count() = 0 Then
						
						Continue;
						
					Else
						
						RecipientData_ =  DataBySubscriber.Value;
						
					EndIf;
					
					CreateNotificationEmailTemplateDefinedByExternalProcessing(RecipientData_, EmailData, NotificationTypeData,
					                                                          MessageTemplateData.EmailTemplateData, ArrayOfCreatedInteractions)
					
				EndDo;
					
			EndDo;
		Else
		
			For Each TemplateDataString In MessageTemplateData.EmailTemplateData.TableOfOutputFields Do
				
				SourceData__ = RecipientData_.Get(TemplateDataString.NotificationSource);
				If SourceData__ = Undefined Then
					Continue;
				EndIf;
				AddresseeData_ = SourceData__.Get(TemplateDataString.Subscriber);
				If RecipientData_ = Undefined Then
					Continue;
				EndIf;
				
				CreateNotificationEmail(AddresseeData_, TemplateDataString,
				                          NotificationTypeData, MessageTemplateData.EmailTemplateData,
				                          EventTypeData, 
				                          ArrayOfCreatedInteractions);
				
			EndDo;
			
		EndIf;
			
			Interactions.SetFoldersForEmailsArray(ArrayOfCreatedInteractions);
		
	EndIf;
	
	If NotificationTypeData.DesignedForSMSMessage Then
		
		If MessageTemplateData.SMSTemplateData.TemplateData.TemplateByExternalDataProcessor Then
			
			For Each RecipientData In RecipientData_ Do
			
				SourceData__ = RecipientData_.Get(RecipientData.Key);
				If SourceData__ = Undefined Then
					Return;
				EndIf;
				
				TemplateData = MessageTemplateData.SMSTemplateData.TemplateData; // See MessageTemplatesClientServer.TemplateParametersDetails
				
				MessageData = MessageTemplates.GenerateMessage(TemplateData.Ref,
				                                                         RecipientData.Key,
				                                                         New UUID);
				
				For Each DataBySubscriber In SourceData__ Do
					
					If Not DataBySubscriber.Value.Property("ArrayOfRecipients_")
						Or TypeOf(DataBySubscriber.Value.ArrayOfRecipients_) <> Type("Array")
						Or DataBySubscriber.Value.ArrayOfRecipients_.Count() = 0 Then
						
						Continue;
						
					Else
						
						RecipientData_ =  DataBySubscriber.Value;
						
					EndIf;
					
					CreateSMSByAlertTemplateDefinedByExternalProcessing(RecipientData_, MessageData, NotificationTypeData,
					                                                       MessageTemplateData.SMSTemplateData, ArrayOfCreatedInteractions)
					
				EndDo;
					
			EndDo;
		Else
		
			For Each TemplateDataString In MessageTemplateData.SMSTemplateData.TableOfOutputFields Do
				
				SourceData__ = RecipientData_.Get(TemplateDataString.NotificationSource);
				If SourceData__ = Undefined Then
					Continue;
				EndIf;
				AddresseeData_ = SourceData__.Get(TemplateDataString.Subscriber);
				If RecipientData_ = Undefined Then
					Continue;
				EndIf;
				
				CreateSMSByNotification(AddresseeData_, TemplateDataString,
				                       NotificationTypeData, MessageTemplateData.SMSTemplateData,
				                       EventTypeData, ArrayOfCreatedInteractions);
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Interactions.CalculateReviewedBySubjects(ArrayOfCreatedInteractions);
	Interactions.CalculateReviewedByContacts(ArrayOfCreatedInteractions);

EndProcedure

#Region CreatingSMSMessageBasedOnAlert

Procedure CreateSMSByAlertTemplateDefinedByExternalProcessing(RecipientData_, MessageData, NotificationTypeData, 
	                                                             TemplateData, ArrayOfCreatedInteractions)
	
	DocumentMessageSMS    = Documents.SMSMessage.CreateDocument();
	FillInRecipientsOfSMSMessage(DocumentMessageSMS, RecipientData_);
	
	If DocumentMessageSMS.Recipients.Count() = 0 Then
		Return;
	EndIf;
	
	FillInHeaderDataOfSMSMessageDocument(DocumentMessageSMS, NotificationTypeData, RecipientData_, TemplateData);
	DocumentMessageSMS.MessageText = MessageData.Text;
	
	RecordDocumentMessageSMS(DocumentMessageSMS, Undefined);
	ArrayOfCreatedInteractions.Add(DocumentMessageSMS.Ref);
	
EndProcedure

Procedure CreateSMSByNotification(RecipientData_,
                                TemplateDataString,
                                NotificationTypeData,
                                TemplateData,
                                EventTypeData,
                                ArrayOfCreatedInteractions)
	
	If Not MessageSatisfiesSendCondition(NotificationTypeData, TemplateDataString, RecipientData_) Then
		Return;
	EndIf;
	
	DocumentMessageSMS    = Documents.SMSMessage.CreateDocument();
	FillInRecipientsOfSMSMessage(DocumentMessageSMS, RecipientData_);
	
	If DocumentMessageSMS.Recipients.Count() = 0 Then
		Return;
	EndIf;
	
	FillInHeaderDataOfSMSMessageDocument(DocumentMessageSMS, NotificationTypeData, RecipientData_, TemplateData);
	
	ParametersMap  = DetailsValuesByParameters(TemplateDataString, TemplateData.TemplateData, EventTypeData);
	DocumentMessageSMS.MessageText = MessageTemplates.InsertParametersInRowAccordingToParametersTable(
	                                                        TemplateData.TemplateData.Text,
	                                                        ParametersMap);
	
	RecordDocumentMessageSMS(DocumentMessageSMS,Undefined);
	RecordAlertData(TemplateDataString, NotificationTypeData);
	ArrayOfCreatedInteractions.Add(DocumentMessageSMS.Ref);
	
EndProcedure

Procedure FillInRecipientsOfSMSMessage(DocumentMessageSMS, RecipientData_)

	ArrayOfPhones = New Array;
	
	For Each RecipientData In RecipientData_.ArrayOfRecipients_ Do
		For Each PhoneData_ In RecipientData.ContactInformation.ArrayOfPhoneNumbers_ Do
			
			PhoneNumber = "";
			PreparePhoneNumber(PhoneData_.FieldsValues,
			                         PhoneData_.Presentation,
			                         PhoneNumber);
			
			If IsBlankString(PhoneNumber) Then
				Continue;
			EndIf;
			
			If ArrayOfPhones.Find(PhoneNumber) = Undefined Then
				ArrayOfPhones.Add(PhoneNumber);
			Else
				Continue;
			EndIf;
			
			AddresseeData = New Structure;
			AddresseeData.Insert("Recipient", RecipientData.Recipient);
			AddresseeData.Insert("RecipientPresentation1", RecipientData.RecipientPresentation1);
			AddresseeData.Insert("ContactInformationPresentation", PhoneData_.Presentation);
			AddresseeData.Insert("ContactInformation", PhoneNumber);
			
			AddSMSRecipient(DocumentMessageSMS, AddresseeData);
			
		EndDo;
	EndDo;

EndProcedure

// LongDesc
// 
// Parameters:
// 	DocumentMessageSMS - DocumentObject.SMSMessage - The document to be filled in.
// 	NotificationTypeData - QueryResultSelection, Undefined - data of the notification type.
// 	RecipientData_ - Structure - LongDesc:
// 	 * DateSent              -Date - date the message was sent.
// 	 * EmailSendingRelevanceDate - Date  - the date after which the message should not be sent.
// 	TemplateData - Structure - message template data.
//
Procedure FillInHeaderDataOfSMSMessageDocument(DocumentMessageSMS, NotificationTypeData, RecipientData_, TemplateData)
	
	DocumentData = New Structure;
	DocumentData.Insert("EmployeeResponsible", NotificationTypeData.EmployeeResponsible);
	DocumentData.Insert("Ref", NotificationTypeData.NotificationKind);
	DocumentData.Insert("Subject", NotificationTypeData.Description);
	DocumentData.Insert("Comment", CommentForNotificationMessage(NotificationTypeData));
	DocumentData.Insert("SendInTransliteration", TemplateData.TemplateData.Transliterate);
	DocumentData.Insert("Basis", Undefined);
	DocumentData.Insert("MailingDate", RecipientData_.DateSent);
	DocumentData.Insert("UpdateDate", RecipientData_.EmailSendingRelevanceDate);
	
	FillInDetailsOfDocumentMessageSMS(DocumentData, DocumentMessageSMS);
	
EndProcedure

#EndRegion

#Region CreatingSMSMessageBasedOnAlert

Procedure CreateNotificationEmailTemplateDefinedByExternalProcessing(RecipientData_,
	                                                                EmailData, 
	                                                                NotificationTypeData, 
	                                                                EmailTemplateData,
	                                                                ArrayOfCreatedInteractions)
	
	MailMessage = Documents.OutgoingEmail.CreateDocument();
	
	FillInEmailRecipients(MailMessage, RecipientData_);
	
	If MailMessage.CCRecipients.Count() = 0 And MailMessage.EmailRecipients.Count() = 0 Then
		Return;
	EndIf;
	
	TemplateData = EmailTemplateData.TemplateData;
	TableOfAttachedFiles = EmailData.Attachments;
	
	FillInHeaderDataOfEmailDocument(MailMessage, NotificationTypeData, RecipientData_, TemplateData, TableOfAttachedFiles);
	
	MailMessage.Subject = EmailData.Subject;
	If TemplateData.EmailFormat1 = Enums.EmailEditingMethods.NormalText Then
		MailMessage.Text = EmailData.Text;
	Else
		MailMessage.HTMLText = EmailData.Text;
		MailMessage.Text     = Interactions.GetPlainTextFromHTML(MailMessage.HTMLText);
	EndIf;
	
	GenerateRecipientsLists(MailMessage);
	
	MailMessage.Write();
	
	For Each Attachment In TableOfAttachedFiles Do
		
		AttachmentParameters = New Structure;
		AttachmentParameters.Insert("FileName", Attachment.Description);
		AttachmentParameters.Insert("Size", Attachment.Size);
		
		AttachedFile = EmailManagement.WriteEmailAttachmentFromTempStorage(
		                                MailMessage.Ref, Attachment.TempStorageAddress, AttachmentParameters);
		
		If AttachedFile <> Undefined Then
			AttachedFileObject = AttachedFile.GetObject();
			AttachedFileObject.EmailFileID = Attachment.EmailFileID;
			AttachedFileObject.Write();
		EndIf;
			
	EndDo;
	
	ArrayOfCreatedInteractions.Add(MailMessage.Ref);
	SetReviewedFlagAfterEmailCreation(MailMessage);
	
EndProcedure

Procedure CreateNotificationEmail(RecipientData_,
	                                TemplateDataString,
	                                NotificationTypeData,
	                                EmailTemplateData,
	                                EventTypeData,
	                                ArrayOfCreatedInteractions)
	
	If Not MessageSatisfiesSendCondition(NotificationTypeData, TemplateDataString, RecipientData_) Then
		Return;
	EndIf;
	
	MailMessage = Documents.OutgoingEmail.CreateDocument();
	
	FillInEmailRecipients(MailMessage, RecipientData_);
	TemplateData               = EmailTemplateData.TemplateData;
	TableOfAttachedFiles = EmailTemplateData.TableOfAttachedFiles;
	TableOfPrintedForms         = EmailTemplateData.TableOfPrintedForms;
	
	If MailMessage.CCRecipients.Count() = 0 And MailMessage.EmailRecipients.Count() = 0 Then
		Return;
	EndIf;
	
	FillInHeaderDataOfEmailDocument(MailMessage, NotificationTypeData, RecipientData_, TemplateData, TableOfAttachedFiles);
	
	ParametersMap     = DetailsValuesByParameters(TemplateDataString, TemplateData, EventTypeData);
	MailMessage.Subject                = MessageTemplates.InsertParametersInRowAccordingToParametersTable(
	                                                          TemplateData.Subject,
	                                                          ParametersMap);
	If TemplateData.EmailFormat1 = Enums.EmailEditingMethods.NormalText Then
		MailMessage.Text = MessageTemplates.InsertParametersInRowAccordingToParametersTable(
		                                                          TemplateData.Text,
		                                                          ParametersMap);
	Else
		MailMessage.HTMLText = MessageTemplates.InsertParametersInRowAccordingToParametersTable(
		                                                                TemplateData.Text,
		                                                                ParametersMap);
		MailMessage.Text     = Interactions.GetPlainTextFromHTML(MailMessage.HTMLText);
	EndIf;
	
	GenerateRecipientsLists(MailMessage);
	MailMessage.Write();
	
	For Each Attachment In TableOfAttachedFiles Do
		
		AttachmentParameters = New Structure;
		AttachmentParameters.Insert("FileName", Attachment.Description);
		AttachmentParameters.Insert("Size",   Attachment.Size);
		
		AttachedFile = EmailManagement.WriteEmailAttachmentFromTempStorage(
		                                MailMessage.Ref, Attachment.TempStorageAddress, AttachmentParameters);
		
		If AttachedFile <> Undefined Then
			AttachedFileObject = AttachedFile.GetObject();
			AttachedFileObject.EmailFileID = Attachment.EmailFileID;
			AttachedFileObject.Write();
		EndIf;
			
	EndDo;
	
	AddAttachmentsPrintedFormsNotificationLetter(MailMessage, TemplateData, TemplateDataString, TableOfPrintedForms);
		
	ArrayOfCreatedInteractions.Add(MailMessage.Ref);
	RecordAlertData(TemplateDataString, NotificationTypeData);
	SetReviewedFlagAfterEmailCreation(MailMessage);
	
EndProcedure

// Adds attachments of the printed form to the letter created by notification
// 
// Parameters:
// 	MailMessage - DocumentObject.OutgoingEmail - The document to be filled in.
// 	TemplateParameters - Structure - data of the notification type.
// 	TemplateDataString - ValueTableRow - contains columns:
// 	 * NotificationSource             -DocumentObject - the document for which you want to send an alert.
// 	SelectedPrintedForms - ValueTable - contains columns:
// 	 * Name - String - name of the printed form 
// 	Template Data - Structure - Message template data.
//
Procedure AddAttachmentsPrintedFormsNotificationLetter(MailMessage, TemplateParameters, TemplateDataString, SelectedPrintedForms)
	
	NotificationSource = TemplateDataString.NotificationSource;
	If Not ValueIsFilled(NotificationSource) Then
		Return;
	EndIf;
	
	MetadataObject3     = NotificationSource.Metadata(); 
	MetadataObjectName = MetadataObject3.Name;
	
	PrintCommandsSources   = PrintManagement.PrintCommandsSources();
	If PrintCommandsSources.Find(MetadataObject3) = Undefined Then
		
		Return;
		
	EndIf;
	
	SelectedPrintCommands = New Map;
	For Each LineSelectedPrintedForms In SelectedPrintedForms Do
		
		If LineSelectedPrintedForms.Name = MetadataObjectName Then
			SelectedPrintCommands.Insert(LineSelectedPrintedForms.Id, True);
		EndIf;
		
	EndDo;
	
	ObjectPrintCommands = PrintManagement.ObjectPrintCommandsAvailableForAttachments(MetadataObject3); 
	
	AttachmentsPrintedForms = New Array;
	
	For Each Attachment In ObjectPrintCommands Do
		If Not Attachment.TurnedOff
			And StrFind(Attachment.Id, ",") = 0
			And Not IsBlankString(Attachment.PrintManager)
			And Not Attachment.SkipPreview
			And Not Attachment.HiddenByFunctionalOptions Then
			
			TeamIsSelected = SelectedPrintCommands.Get(Attachment.UUID);
			If TeamIsSelected = Undefined 
				Or TeamIsSelected = False Then
				
				Continue;
				
			EndIf;
			
			SelectedPrintCommands.Insert(Attachment.UUID, False);
			
			AttachmentData = New Structure;
			AttachmentData.Insert("NameOfPrintForm",            Attachment.Id);
			AttachmentData.Insert("IDOfPrintCommand",  Attachment.UUID);
			AttachmentData.Insert("Presentation",               Attachment.Presentation);
			AttachmentData.Insert("PrintManager",              Attachment.PrintManager);
			AttachmentData.Insert("FileType",                    "MXL");
			AttachmentData.Insert("Status",                      "PrintForm");
			AttachmentData.Insert("ParameterName",                 "");
			AttachmentData.Insert("PrintParameters",             Attachment.AdditionalParameters);
			
			AttachmentsPrintedForms.Add(AttachmentData);
			
		EndIf;
	EndDo;
		
	If AttachmentsPrintedForms.Count() = 0 Then
		Return;
	EndIf;
	
	SaveFormats = New Array;
	If TypeOf(TemplateParameters.AttachmentsFormats) = Type("ValueList") Then
		For Each AttachmentFormat1 In TemplateParameters.AttachmentsFormats Do
			SaveFormats.Add(?(TypeOf(AttachmentFormat1.Value) = Type("SpreadsheetDocumentFileType"),
				AttachmentFormat1.Value,
				SpreadsheetDocumentFileType[AttachmentFormat1.Value]));
		EndDo;
	Else
		SaveFormats.Add(StandardSubsystemsServer.TableDocumentFileTypePDF());
	EndIf;
	
	For Each AttachmentPrintForm In AttachmentsPrintedForms Do 
		
		If AttachmentPrintForm.Status = "PrintForm" Then
			PrintManagerName = AttachmentPrintForm.PrintManager;
			PrintParameters    = AttachmentPrintForm.PrintParameters;
			ObjectsArray     = New Array;
			
			ObjectsArray.Add(NotificationSource);
			
			TemplatesNames = ?(IsBlankString(AttachmentPrintForm.NameOfPrintForm), AttachmentPrintForm.IDOfPrintCommand, AttachmentPrintForm.NameOfPrintForm);
			
			Try
				PrintCommand = New Structure;
				PrintCommand.Insert("Id",           TemplatesNames);
				PrintCommand.Insert("PrintManager",          PrintManagerName);
				PrintCommand.Insert("AdditionalParameters", PrintParameters);
				
				SettingsForSaving = PrintManagement.SettingsForSaving();
				SettingsForSaving.SaveFormats = SaveFormats;
				SettingsForSaving.PackToArchive = TemplateParameters.PackToArchive;
				SettingsForSaving.TransliterateFilesNames = TemplateParameters.TransliterateFileNames;
				SettingsForSaving.SignatureAndSeal = TemplateParameters.SignatureAndSeal;
				
				PrintFormsCollection = PrintManagement.PrintToFile(PrintCommand, ObjectsArray, SettingsForSaving);
				
			Except
				// Error when creating an external printed form. We create a letter further, without this printed form.
				ErrorInfo = ErrorInfo();
				ErrorText = NStr("vi = 'Lỗi khi tạo mẫu in bên ngoài. Nguyên nhân:';
								|ru = 'Ошибка при создании внешней печатной формы. По причине:';
								|en = 'An error occurred when creating an external print form. Reason:'; fa = 'An error occurred when creating an external print form. Reason:';
								|it = 'Errore durante la creazione di moduli di stampa esterni. Causa:';
								|pl = 'Błąd podczas tworzenia zewnętrznego formularza drukowania. Z powodu:';
								|tr = 'Harici yazdırma formu şu nedenle oluşturulamadı:'") + Chars.LF
						+ DetailErrorDescription(ErrorInfo);
				
				PerformLogEntry(ErrorText, EventLogLevel.Error);

				Continue;
				
			EndTry;
			
			For Each PrintForm In PrintFormsCollection Do
				
				AttachmentParameters = New Structure;
				AttachmentParameters.Insert("FileName", PrintForm.FileName);
				AttachmentParameters.Insert("Size",   PrintForm.BinaryData.Size());
				
				AddressInTempStorage = PutToTempStorage(PrintForm.BinaryData);
				EmailManagement.WriteEmailAttachmentFromTempStorage(
				                                MailMessage.Ref, AddressInTempStorage, AttachmentParameters);
				
			EndDo;
				
		EndIf;
	EndDo;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	MailMessage - DocumentObject.OutgoingEmail - LongDesc
// 	NotificationTypeData - QueryResultSelection, Undefined - LongDesc:
// 	RecipientData_ - Structure - LongDesc:
// 	* DateSent             - Date  - the date on which the message should be sent.
// 	* EmailSendingRelevanceDate - Date - the date after which you do not need to send the message.
// 	TemplateData - Structure - LongDesc:
//
Procedure FillInHeaderDataOfEmailDocument(MailMessage, NotificationTypeData, RecipientData_, TemplateData, TableOfAttachedFiles)
	
	MailMessage.Author                    = Users.CurrentUser();
	MailMessage.EmployeeResponsible            = NotificationTypeData.EmployeeResponsible;
	MailMessage.Date                     = CurrentSessionDate();
	MailMessage.Importance                 = Enums.InteractionImportanceOptions.Ordinary;
	MailMessage.Encoding                = "UTF-8";
	MailMessage.Account            = NotificationTypeData.Account;
	
	MailMessage.SenderPresentation = InteractionsClientServer.GetAddresseePresentation(
	                                            NotificationTypeData.AccountUserName,
	                                            NotificationTypeData.AccountEmailAddress,
	                                            "");
	MailMessage.EmailStatus             = Enums.OutgoingEmailStatuses.Outgoing;
	MailMessage.TextType                = ?(TemplateData.EmailFormat1 = Enums.EmailEditingMethods.HTML, 
	                                            Enums.EmailTextTypes.HTML, 
	                                            Enums.EmailTextTypes.PlainText);
	
	MailMessage.RequestDeliveryReceipt            = False;
	MailMessage.RequestReadReceipt           = False;
	MailMessage.DisplaySourceEmailBody = False;
	MailMessage.IncludeOriginalEmailBody   = False;
	MailMessage.DeleteAfterSend          = NotificationTypeData.DeleteEmailsAfterSend;
	MailMessage.Comment                   = CommentForNotificationMessage(NotificationTypeData);
	MailMessage.InteractionBasis       = NotificationTypeData.NotificationKind;
	MailMessage.DateToSendEmail            = RecipientData_.DateSent;
	MailMessage.EmailSendingRelevanceDate      = RecipientData_.EmailSendingRelevanceDate;
	MailMessage.HasAttachments                  = TableOfAttachedFiles.Count() > 0;
	
EndProcedure

Procedure FillInEmailRecipients(MailMessage, RecipientData_)

	AddressesArray = New Array;
	RecipientPresentation1 = "";
	
	For Each RecipientData In RecipientData_.ArrayOfRecipients_ Do
		For Each EMAddress In RecipientData.ContactInformation.DSAddressesArray Do
			
			If AddressesArray.Find(EMAddress.Presentation) = Undefined Then
				AddressesArray.Add(EMAddress.Presentation);
			Else
				Continue;
			EndIf;
			
			Recipient = New Structure("ContactInformation, RecipientPresentation1, Recipient",
			                             EMAddress.Presentation,
			                             RecipientData.RecipientPresentation1, 
			                             RecipientData.Recipient);
			
			If CommonClientServer.EmailAddressMeetsRequirements(Recipient.ContactInformation) Then
				 AddEmailRecipient(MailMessage.EmailRecipients, Recipient);
			EndIf;
			
		EndDo;
	EndDo;

EndProcedure

Procedure SetReviewedFlagAfterEmailCreation(MailMessage)
	
	Attributes = InformationRegisters.InteractionsFolderSubjects.InteractionAttributes();
	Attributes.SubjectOf = MailMessage.Ref;
	Attributes.Reviewed = True;
	InformationRegisters.InteractionsFolderSubjects.WriteInteractionFolderSubjects(MailMessage.Ref, Attributes);
	
EndProcedure

#EndRegion

Procedure RecordAlertData(TemplateDataString, NotificationTypeData)
	
	If NotificationTypeData.SendingConditionsAreUsed Then
		StructureMessageData = New Structure;
		For Each Parameter In NotificationTypeData.ConditionParameters.Unload() Do
			If Not Parameter.ThisIsAPreviousMessageParameter And Not StructureMessageData.Property(Parameter.ParameterName) Then
				StructureMessageData.Insert(Parameter.ParameterName, TemplateDataString[Parameter.ParameterName]);
			EndIf;
		EndDo;
		
		If StructureMessageData.Count() > 0 Then
			RecordManager = InformationRegisters.DataOfLastNotifications.CreateRecordManager();
			RecordManager.NotificationKind              = NotificationTypeData.NotificationKind;
			RecordManager.NotificationSource         = TemplateDataString.NotificationSource;
			RecordManager.Subscriber                  = TemplateDataString.Subscriber;
			RecordManager.DataOfLastNotification = New ValueStorage(StructureMessageData);
			RecordManager.Write(True);
		EndIf;
		
	EndIf;
	
EndProcedure

// The message satisfies the sending condition.
// 
// Parameters:
//  NotificationTypeData - Undefined, QueryResultSelection - Notification Type Data:
//   * NotificationKind - CatalogRef.CustomerNotificationKinds -
//   * GroupOfMailoutsAndNotifications - CatalogRef.GroupsOfMailoutsAndNotifications -
//   * DesignedForEmails - Boolean -
//   * DesignedForSMSMessage - Boolean -
//   * SMSMessageTemplate - CatalogRef.MessageTemplates -
//   * EmailTemplate - CatalogRef.MessageTemplates -
//   * SendingCondition - String -
//   * EventType - String -
//   * Forced - Boolean -
//   * Account - CatalogRef.EmailAccounts -
//   * PartnerSContactDetailsKindForEmails - CatalogRef.ContactInformationKinds -
//   * PartnerSContactDetailsKindForSMSMessage - CatalogRef.ContactInformationKinds -
//   * ContactPersonSContactDetailsKindForEmails - CatalogRef.ContactInformationKinds -
//   * ContactPersonSContactDetailsKindForSMSMessage - CatalogRef.ContactInformationKinds -
//   * SendToCustomer - Boolean -
//   * SendToAContactPersonOfANotificationObject - Boolean -
//   * SendToRoleContactPersons - Boolean -
//   * ContactRole - CatalogRef.RolesOfPartnerContactPersons -
//   * EmployeeResponsible - CatalogRef.Users -
//   * AccountUserName - String -
//   * AccountEmailAddress - String -
//   * DeleteEmailsAfterSend - Boolean -
//   * Description - String -
//   * ConditionParameters - ValueTable - Contains:
//    ** ThisIsAPreviousMessageParameter - Boolean -
//    ** ParameterName - String -
//   * SendingConditionsAreUsed - Boolean -
// TemplateDataString - ValueTableRow - Template Data String
// RecipientData_ - Structure - Contains:
//   * DataOfLastNotification - ValueStorage -  
// 
// Returns:
//  Boolean - The message meets the send condition
Function MessageSatisfiesSendCondition(NotificationTypeData, TemplateDataString, RecipientData_)
	
	If Not NotificationTypeData.SendingConditionsAreUsed Then
		Return True;
	EndIf;
	
	LastAlertDataRequired = (StrFind(NotificationTypeData.SendingCondition, "PreviousMessage") > 0);
	
	If LastAlertDataRequired
		And RecipientData_.DataOfLastNotification = Undefined Then
		Return True;
	EndIf;
	
	If LastAlertDataRequired Then
		PreviousMessageData = RecipientData_.DataOfLastNotification.Get();
		If PreviousMessageData = Undefined Then
			Return True;
		EndIf;
	EndIf;
	
	SendingCondition = NotificationTypeData.SendingCondition;
	
	Try
		
		ParametersOfSendingCondition = New Structure;
		ParametersOfSendingCondition.Insert("TemplateType", "SMS");
		ParametersOfSendingCondition.Insert("Text", SendingCondition);
		MatchingConditionParameters = MessageTemplates.ParametersFromMessageText(ParametersOfSendingCondition);
		
		CurMessage = New Structure;
		PreviousMessage = New Structure;
		
		For Each MapItem In MatchingConditionParameters Do
			For Each Parameter In MapItem.Value Do
				If MapItem.Key = "PreviousMessage" Then
					
					PreviousMessage.Insert(Parameter.Key, PreviousMessageData[Parameter.Key]);
					
				ElsIf MapItem.Key = "CurMessage" Then
					
					CurMessage.Insert(Parameter.Key, TemplateDataString[Parameter.Key]);
					
				Else
					
					Continue;
					
				EndIf;
				
				SendingCondition = StrReplace(SendingCondition, "[PreviousMessage", "Parameters.PreviousMessage");
				SendingCondition = StrReplace(SendingCondition, "[CurMessage",    "Parameters.CurMessage");
				SendingCondition = StrReplace(SendingCondition, "]", "");
				
			EndDo;
		EndDo;
		
		Parameters = New Structure;
		Parameters.Insert("PreviousMessage", PreviousMessage);
		Parameters.Insert("CurMessage",    CurMessage);
		
		If Common.CalculateInSafeMode(SendingCondition, Parameters) = False Then
			Return False;
		Else
			Return True;
		EndIf;
	
	Except
		// If the check failed, then skip it.
		Return True;
	EndTry;
	
	Return True;
	
EndFunction

Function DetailsValuesByParameters(TemplateDataString, TemplateData, EventTypeData)

	MatchingMessageTextParameters = MessageTemplates.ParametersFromMessageText(TemplateData);
	ParametersMap = MatchingMessageTextParameters.Get(EventTypeData.Name);

	If ParametersMap <> Undefined Then
		TemplateDataStringMatching = ValueTableRowToMap(TemplateDataString);
		FillInParametersAccordingTo(ParametersMap, TemplateDataStringMatching);
	EndIf;
	
	If MatchingMessageTextParameters[MessageTemplates.CommonAttributesNodeName()] <> Undefined Then
		MessageTemplates.FillCommonAttributes(MatchingMessageTextParameters[MessageTemplates.CommonAttributesNodeName()]);
	EndIf;
	
	Return MatchingMessageTextParameters;

EndFunction

Function ValueTableRowToMap(ValueTableRow)
	
	Map = New Map;
	For Each Column In ValueTableRow.Owner().Columns Do
		Map.Insert(Column.Name, ValueTableRow[Column.Name]);
	EndDo;
	
	Return Map;
	
EndFunction

Procedure FillInParametersAccordingTo(ParametersMap, TemplateDataStringMatching, Prefix = "")
	
	For Each Parameter In ParametersMap Do
		
		If StrFind(Parameter.Key, "~") And ValueIsFilled(TemplateDataStringMatching[Prefix]) Then
			FillPropertiesAndContactInformationAttributes(ParametersMap, TemplateDataStringMatching[Prefix]);
		ElsIf TypeOf(Parameter.Value) = Type("Map") Then
			FillInParametersAccordingTo(Parameter.Value, TemplateDataStringMatching, Prefix + Parameter.Key);
		Else
			If TemplateDataStringMatching[Prefix] <> Undefined Then
				ParametersMap[Parameter.Key] = Common.ObjectAttributeValue(TemplateDataStringMatching[Prefix], Parameter.Key);
			Else
				ParametersMap[Parameter.Key] = TemplateDataStringMatching[Parameter.Key];
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

Function PropertiesAttributesValues(SubjectOf)
	
	PropertiesValues = New ValueTable;
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		GetAddlInfo = ModulePropertyManager.UseAddlInfo(SubjectOf);
		GetAddlAttributes = ModulePropertyManager.UseAddlAttributes(SubjectOf);
		
		If GetAddlAttributes Or GetAddlInfo Then
			PropertiesValues = ModulePropertyManager.PropertiesValues(SubjectOf, GetAddlAttributes, GetAddlInfo);
		EndIf;
		
	EndIf;
	
	Return PropertiesValues;
	
EndFunction

Function ContactInformationAttributesValues(SubjectOf)
	
	ObjectsContactInformation = Undefined;
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManager = Common.CommonModule("ContactsManager");	
		
		ObjectsWithContactInformation = New Array;
		ObjectsWithContactInformation.Add(SubjectOf);
		ContactInformationKinds = ModuleContactsManager.ObjectContactInformationKinds(SubjectOf.Ref);
		If ContactInformationKinds.Count() > 0 Then
			ObjectsContactInformation = ModuleContactsManager.ObjectsContactInformation(ObjectsWithContactInformation,,, CurrentSessionDate());
		EndIf;
	EndIf;
	
	Return ObjectsContactInformation;
	
EndFunction

Function ParameterNameWithoutFormatString(Val TemplateParameterFromText)
	
	Result = New Structure;
	Result.Insert("Name",   "");
	Result.Insert("Format", "");
	
	PositionFormatText = StrFind(TemplateParameterFromText, "{", SearchDirection.FromEnd);
	If PositionFormatText > 0 Then
		Result.Name = Left(TemplateParameterFromText, PositionFormatText - 1);
		Result.Format = Mid(TemplateParameterFromText, PositionFormatText + 1, StrLen(TemplateParameterFromText) - PositionFormatText - 1);
	Else
		Result.Name = TemplateParameterFromText;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure FillPropertiesAndContactInformationAttributes(MessageTextParameters, SubjectOf) Export 
	
	ObjectMetadata = SubjectOf.Metadata();
	PropertiesValues = PropertiesAttributesValues(SubjectOf);
	ObjectsContactInformation = ContactInformationAttributesValues(SubjectOf);
	
	For Each BasisParameter In MessageTextParameters Do
		
		If StrStartsWith(BasisParameter.Key, "Property") Then
			
			For Each ParameterProperty In BasisParameter.Value Do
				If PropertiesValues <> Undefined Then
					For Each RowProperty In PropertiesValues Do
						ParameterDetails = ParameterNameWithoutFormatString(ParameterProperty.Key);
						IDForFormulas = Common.ObjectAttributeValue(RowProperty.Property, "IDForFormulas");
						If StrCompare(IDForFormulas, ParameterDetails.Name) = 0 Then
							If IsBlankString(ParameterDetails.Format) Then
								BasisParameter.Value[ParameterProperty.Key] = String(RowProperty.Value);
							Else
								BasisParameter.Value[ParameterProperty.Key] = Format(RowProperty.Value, ParameterDetails.Format);
							EndIf;
						EndIf;
					EndDo;
				EndIf;
			EndDo;
			
		ElsIf StrStartsWith(BasisParameter.Key, "~CI") Then
			
			For Each ContactInformationParameter In BasisParameter.Value Do
				
				For Each ObjectContactInformation In ObjectsContactInformation Do
					IDForFormulas = Common.ObjectAttributeValue(ObjectContactInformation.Kind, "IDForFormulas");
					
					If StrCompare(IDForFormulas, ContactInformationParameter.Key) = 0 Then
						If ValueIsFilled(MessageTextParameters[ContactInformationParameter.Key]) Then
							PreviousValue1 = MessageTextParameters[ContactInformationParameter.Key] +", ";
						Else
							PreviousValue1 = "";
						EndIf;
						BasisParameter.Value[ContactInformationParameter.Key] = PreviousValue1 + String(ObjectContactInformation.Presentation);
					EndIf;
				EndDo;
				
			EndDo;
			
		ElsIf TypeOf(BasisParameter.Value) = Type("Map") Then
			
			ObjectMetadataByKey = ObjectMetadata.Attributes.Find(BasisParameter.Key);
			If ObjectMetadataByKey <> Undefined  Then
				FillPropertiesAndContactInformationAttributes(BasisParameter.Value, SubjectOf[BasisParameter.Key]);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Generates template data based on the type of alert.
// 
// Parameters:
// 	NotificationTypeData - See NotificationTypeData
// 	ProcessingDate - Date - 
// EventTypeData - See Enums.NotificationEventTypes.DataForProcessingAlertQueue
// Returns:
// 	Structure - LongDesc:
// * EmailTemplateData - See MessagesTemplateData
// * SMSTemplateData - See MessagesTemplateData
//
Function DataForAlertTypeTemplates(NotificationTypeData, ProcessingDate, EventTypeData)

	MessageTemplateData = New Structure;
	MessageTemplateData.Insert("SMSTemplateData",Undefined);
	MessageTemplateData.Insert("EmailTemplateData", Undefined);
	If NotificationTypeData.SendingConditionsAreUsed Then
		ConditionParameters = NotificationTypeData.ConditionParameters.Unload();
	Else
		ConditionParameters = Undefined;
	EndIf;
	
	If NotificationTypeData.DesignedForSMSMessage Then
		MessageTemplateData.SMSTemplateData = MessagesTemplateData(ProcessingDate,
		                                                                  NotificationTypeData.NotificationKind,
		                                                                  NotificationTypeData.SMSMessageTemplate,
		                                                                  ConditionParameters,
		                                                                  False,
		                                                                  EventTypeData);
	EndIf;
	
	If NotificationTypeData.DesignedForEmails Then
		MessageTemplateData.EmailTemplateData = MessagesTemplateData(ProcessingDate,
		                                                                     NotificationTypeData.NotificationKind,
		                                                                     NotificationTypeData.EmailTemplate,
		                                                                     ConditionParameters,
		                                                                     True,
		                                                                     EventTypeData);
	EndIf;
	
	Return MessageTemplateData;

EndFunction

// Generates message template data
// 
// Parameters:
// 	ProcessingDate - Date - 
// 	NotificationKind - CatalogRef.CustomerNotificationKinds - 
// 	MessageTemplate - CatalogRef.MessageTemplates - 
// 	ConditionParameters - ValueTable - LongDesc
// 	DesignedForLetter - Boolean - LongDesc
// 	EventTypeData - See Enums.NotificationEventTypes.DataForProcessingAlertQueue
// Returns:
//  Structure - Contains:
//   * TemplateData - See MessageTemplatesClientServer.TemplateParametersDetails
//   * TableOfOutputFields - ValueTable -
//   * TableOfAttachedFiles - ValueTable - 
//
Function MessagesTemplateData(ProcessingDate, NotificationKind, MessageTemplate, ConditionParameters, DesignedForLetter, EventTypeData)

	ReturnStructure = New Structure;
	ReturnStructure.Insert("TemplateData",               Undefined);
	ReturnStructure.Insert("TableOfOutputFields",       Undefined);
	ReturnStructure.Insert("TableOfAttachedFiles", Undefined);
	ReturnStructure.Insert("TableOfPrintedForms",         Undefined);
	
	TemplateData = MessageTemplates.TemplateParameters(MessageTemplate);
	ReturnStructure.TemplateData = TemplateData;
	
	If TemplateData.TemplateByExternalDataProcessor Then
		Return ReturnStructure;
	EndIf;
	
	MatchingMessageTextParameters = MessageTemplates.ParametersFromMessageText(TemplateData);
	
	If MatchingMessageTextParameters.Count() = 0 Then
		EventType = Common.ObjectAttributeValue(NotificationKind, "EventType");
		If Not ValueIsFilled(EventType) Then
			Return Undefined;
		EndIf;
		MatchingMessageTextParameters.Insert(Common.EnumerationValueName(EventType), New Map);
	EndIf;
	
	For Each MapItem In MatchingMessageTextParameters Do
		
		If EventTypeData.Name <> MapItem.Key Then
			Continue;
		EndIf;
			
		Try
	
			DCSTemplate = Enums.NotificationEventTypes.GetTemplate(MapItem.Key);
			RemoveUsageRestrictionFromField("Subscriber", DCSTemplate.DataSets.Data);
			RemoveUsageRestrictionFromField("NotificationSource", DCSTemplate.DataSets.Data);
			
			SchemaURL = PutToTempStorage(DCSTemplate, New UUID);
			SettingsComposer = New DataCompositionSettingsComposer;
			SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
			
			SettingsComposer.LoadSettings(DCSTemplate.DefaultSettings);
			SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.Full);
			TemplateComposer = New DataCompositionTemplateComposer();
			
			For Each SelectedField In MapItem.Value Do 
				TMReportFunctionsClientServer.AddSelectedField(SettingsComposer, SelectedField.Key);
			EndDo;
			TMReportFunctionsClientServer.AddSelectedField(SettingsComposer, "NotificationSource");
			TMReportFunctionsClientServer.AddSelectedField(SettingsComposer, "Subscriber");
			
			If ConditionParameters <> Undefined Then
				For Each Parameter In ConditionParameters Do
					If (Not Parameter.ThisIsAPreviousMessageParameter) 
						  And (MapItem.Value.Get(Parameter.ParameterName) = Undefined) Then
						TMReportFunctionsClientServer.AddSelectedField(SettingsComposer, Parameter.ParameterName);
					EndIf;
				EndDo;
			EndIf;
			
			DataCompositionTemplate = TemplateComposer.Execute(DCSTemplate, SettingsComposer.GetSettings(),,,Type("DataCompositionValueCollectionTemplateGenerator"));
			QueryText = DataCompositionTemplate.DataSets.Data.Query;
			
			Query = New Query;
			Query.Text = QueryText;
			
			For Each ParameterValue In DataCompositionTemplate.ParameterValues Do
				
				If TypeOf(ParameterValue.Value) = Type("DataCompositionExpression") Then
					Query.SetParameter(ParameterValue.Name, Common.CalculateInSafeMode(ParameterValue.Value));
				EndIf;
				
			EndDo;
			
			Query.SetParameter("NotificationKind", NotificationKind);
			Query.SetParameter("ProcessingDate", ProcessingDate);
			Query.SetParameter("CurrentDate", CurrentSessionDate());
			Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
			
			ReturnStructure.TableOfOutputFields = Query.Execute().Unload();
			
			Break;
			
		Except
			
			Return Undefined
			
		EndTry;
		
	EndDo;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	MessageTemplatesAttachedFiles.Ref,
	|	MessageTemplatesAttachedFiles.Size,
	|	MessageTemplatesAttachedFiles.EmailFileID,
	|	MessageTemplatesAttachedFiles.Description,
	|	MessageTemplatesAttachedFiles.Extension,
	|	UNDEFINED AS TempStorageAddress
	|FROM
	|	Catalog.MessageTemplatesAttachedFiles AS MessageTemplatesAttachedFiles
	|WHERE
	|	NOT MessageTemplatesAttachedFiles.DeletionMark
	|	AND MessageTemplatesAttachedFiles.FileOwner = &MessageTemplate
	|	AND MessageTemplatesAttachedFiles.EmailFileID <> """"";
	
	Query.SetParameter("MessageTemplate", MessageTemplate);
	
	Result = Query.Execute();
	
	TableOfAttachedFiles = Result.Unload();
	UniqueRoomId = New UUID;
	For Each AttachedFile In TableOfAttachedFiles Do
		
		AttachedFile.TempStorageAddress = PutToTempStorage(
		                                     FilesOperations.FileBinaryData(AttachedFile["Ref"]),
		                                     UniqueRoomId);
	EndDo;
	
	ReturnStructure.TableOfAttachedFiles = TableOfAttachedFiles;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	MessageTemplatesPrintFormsAndAttachments.Id AS Id,
	|	MessageTemplatesPrintFormsAndAttachments.LineNumber AS LineNumber,
	|	MessageTemplatesPrintFormsAndAttachments.Name AS Name
	|FROM
	|	Catalog.MessageTemplates.PrintFormsAndAttachments AS MessageTemplatesPrintFormsAndAttachments
	|WHERE
	|	MessageTemplatesPrintFormsAndAttachments.Ref = &MessageTemplate";
	
	Query.SetParameter("MessageTemplate", MessageTemplate);
	
	ReturnStructure.TableOfPrintedForms = Query.Execute().Unload();
	
	Return ReturnStructure;

EndFunction

Procedure RemoveUsageRestrictionFromField(FieldName, DataSet)
	
	NotificationSourceField = DataSet.Fields.Find(FieldName);
	If NotificationSourceField <> Undefined Then
		NotificationSourceField.UseRestriction.Field = False;
	EndIf;
	
EndProcedure

Function RecipientDataByNotificationType(NotificationTypeData, DateOfProcessing, EventTypeData)
	
	QueryTemplate = "
	|%TemporaryTableSubscribers%
	|%TemporaryTableContactPersonsAlerts%
	|%TemporaryTableSubscriberContactPersons%
	|%ContactInformationSubscribers%
	|%ContactInformationOfAlertContactPersons%
	|%ContactInformationOfSubscriberSContactPersons%
	|
	|TOTALS BY
	|	NotificationSource,
	|	Subscriber,
	|	Recipient
	|";
	
	ResultingQueryContainsText = False;
	
	ProcessRequestTextBySubscribersForAlerts(QueryTemplate,
	                                                 NotificationTypeData,
	                                                 DateOfProcessing,
	                                                 EventTypeData,
	                                                 ResultingQueryContainsText);
	
	ProcessRequestTextForContactPersonsForNotifications(QueryTemplate,
	                                                     NotificationTypeData,
	                                                     DateOfProcessing,
	                                                     EventTypeData,
	                                                     ResultingQueryContainsText);
	 
	ProcessRequestTextForSubscriberSContactPersons(QueryTemplate,
	                                                  NotificationTypeData,
	                                                  DateOfProcessing,
	                                                  EventTypeData,
	                                                  ResultingQueryContainsText);
	
	QueryTextByContactPersons = "";
	
	Query = New Query;
	Query.Text = QueryTemplate;
	
	Query.SetParameter("NotificationKind", NotificationTypeData.NotificationKind);
	Query.SetParameter("DateOfProcessing", DateOfProcessing);
	Query.SetParameter("ContactRole", NotificationTypeData.ContactRole);
	Query.SetParameter("TypeOfContactPersonSCIForEmails", NotificationTypeData.ContactPersonSContactDetailsKindForEmails);
	Query.SetParameter("TypeOfContactPersonSKiForSMS", NotificationTypeData.ContactPersonSContactDetailsKindForSMSMessage);
	Query.SetParameter("PartnerContactDetailsKindForMails", NotificationTypeData.PartnerSContactDetailsKindForEmails);
	Query.SetParameter("PartnerContactDetailsKindForSMSMessage", NotificationTypeData.PartnerSContactDetailsKindForSMSMessage);
	Query.SetParameter("GroupOfMailoutsAndNotifications", NotificationTypeData.GroupOfMailoutsAndNotifications);
	
	MatchingRecipientData = New Map;
	
	SampleResults = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SampleResults.Next() Do
		
		MatchingSubscribers = New Map;
		
		SubscriberSelection = SampleResults.Select(QueryResultIteration.ByGroups);
		While SubscriberSelection.Next() Do
			
			StructureSubscriberData = New Structure;
			ArrayOfRecipients_ = New Array;
			
			SampleRecipient = SubscriberSelection.Select(QueryResultIteration.ByGroups);
			While SampleRecipient.Next() Do
				
				ArrayOfPhoneNumbers_  = New Array;
				DSAddressesArray         = New Array;
				RecipientPresentation1 = "";
				
				DetailsSelection = SampleRecipient.Select();
				While DetailsSelection.Next() Do
					
					RecipientPresentation1 = ?(IsBlankString(RecipientPresentation1), DetailsSelection.RecipientPresentation1, RecipientPresentation1);
					
					If NotificationTypeData.DesignedForSMSMessage 
						And (Not IsBlankString(DetailsSelection.PhonePresentation_) Or Not IsBlankString(DetailsSelection.ValueOfPhoneFields)) Then
						
						ArrayOfPhoneNumbers_.Add(New Structure("Presentation, FieldsValues",
						                                                DetailsSelection.PhonePresentation_, DetailsSelection.ValueOfPhoneFields));
						
					EndIf;
					
					If NotificationTypeData.DesignedForEmails 
						And (Not IsBlankString(DetailsSelection.PresentationLetter) Or Not IsBlankString(DetailsSelection.MessageFieldValues)) Then
						
						DSAddressesArray.Add(New Structure("Presentation, FieldsValues",
						                                         DetailsSelection.PresentationLetter, DetailsSelection.MessageFieldValues));
						
					EndIf;
					
				EndDo;
				
				StructureOfContactInformation = New Structure;
				StructureOfContactInformation.Insert("ArrayOfPhoneNumbers_", ArrayOfPhoneNumbers_);
				StructureOfContactInformation.Insert("DSAddressesArray", DSAddressesArray);
				
				RecipientStructure = New Structure;
				RecipientStructure.Insert("Recipient", SampleRecipient.Recipient);
				RecipientStructure.Insert("RecipientPresentation1", RecipientPresentation1);
				RecipientStructure.Insert("ContactInformation", StructureOfContactInformation);
				
				ArrayOfRecipients_.Add(RecipientStructure);
				
			EndDo;
			
			StructureSubscriberData.Insert("ArrayOfRecipients_", ArrayOfRecipients_);
			StructureSubscriberData.Insert("DateSent", Date(1,1,1));
			StructureSubscriberData.Insert("EmailSendingRelevanceDate", Date(1,1,1));
			StructureSubscriberData.Insert("DataOfLastNotification", Undefined);
			MatchingSubscribers.Insert(SubscriberSelection.Subscriber, StructureSubscriberData);
			
		EndDo;
		
		MatchingRecipientData.Insert(SampleResults.NotificationSource, MatchingSubscribers);
		
	EndDo;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	EventQueueForNotificationsToCustomers.NotificationSource AS NotificationSource,
	|	EventQueueForNotificationsToCustomers.Subscriber AS Subscriber,
	|	MAX(EventQueueForNotificationsToCustomers.DateSent) AS DateSent,
	|	MAX(EventQueueForNotificationsToCustomers.EmailSendingRelevanceDate) AS EmailSendingRelevanceDate
	|INTO MailingDates
	|FROM
	|	InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
	|WHERE
	|	EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind
	|	AND EventQueueForNotificationsToCustomers.Period < &DateOfProcessing
	|
	|GROUP BY
	|	EventQueueForNotificationsToCustomers.NotificationSource,
	|	EventQueueForNotificationsToCustomers.Subscriber
	|
	|INDEX BY
	|	NotificationSource,
	|	Subscriber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MailingDates.NotificationSource,
	|	MailingDates.Subscriber,
	|	MailingDates.DateSent,
	|	MailingDates.EmailSendingRelevanceDate,
	|	ISNULL(DataOfLastNotifications.DataOfLastNotification, UNDEFINED) AS DataOfLastNotification
	|FROM
	|	MailingDates AS MailingDates
	|		LEFT JOIN InformationRegister.DataOfLastNotifications AS DataOfLastNotifications
	|		ON MailingDates.NotificationSource = DataOfLastNotifications.NotificationSource
	|			AND MailingDates.Subscriber = DataOfLastNotifications.Subscriber
	|			AND (DataOfLastNotifications.NotificationKind = &NotificationKind)";
	
	Query.SetParameter("NotificationKind", NotificationTypeData.NotificationKind);
	Query.SetParameter("DateOfProcessing", DateOfProcessing);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		SourceData = MatchingRecipientData.Get(Selection.NotificationSource);
		If SourceData <> Undefined Then
			SubscriberData_ = SourceData.Get(Selection.Subscriber); // Structure
			If SubscriberData_ <> Undefined Then
				SubscriberData_.DateSent               = Selection.DateSent; 
				SubscriberData_.EmailSendingRelevanceDate   = Selection.EmailSendingRelevanceDate;
				SubscriberData_.DataOfLastNotification = Selection.DataOfLastNotification;
			EndIf;
		EndIf;
		
	EndDo;
	
	Return MatchingRecipientData;
	
EndFunction

Procedure ProcessRequestTextBySubscribersForAlerts(QueryTemplate, NotificationTypeData, ProcessingDate, EventTypeData, ResultingQueryContainsText)
	
	If Not EventTypeData.SendToCustomer And  Not EventTypeData.SendToPartnerSContactPersons  Then
		
		TextTemporaryTableSubscribers = "";
		TextContactInformationSubscribers = "";
		
	Else
		
		TextTemporaryTableSubscribers = "
		|SELECT
		|	EventQueueForNotificationsToCustomers.NotificationSource,
		|	EventQueueForNotificationsToCustomers.Subscriber
		|INTO Subscribers
		|FROM
		|	InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|WHERE
		|	EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind
		|	AND EventQueueForNotificationsToCustomers.Period < &DateOfProcessing
		|;
		|
		|/////////////////////////////////////////////////////";
		
		If NotificationTypeData.Forced Then
			
			If EventTypeData.SendToCustomer And NotificationTypeData.SendToCustomer Then
				
				ResultingQueryContainsText = True;
				
				TextContactInformationSubscribers = "
				|SELECT
				|	Subscribers.NotificationSource AS NotificationSource,
				|	Subscribers.Subscriber AS Subscriber,
				|	Subscribers.Subscriber AS Recipient,
				|	Partners.DescriptionFull AS RecipientPresentation1,
				|	ISNULL(ContactInformationForSMS.Presentation, """") AS PhonePresentation_,
				|	SUBSTRING(ISNULL(ContactInformationForSMS.FieldValues, """"), 1, 1024) AS ValueOfPhoneFields,
				|	ISNULL(ContactInformationForEmails.Presentation, """") AS PresentationLetter,
				|	SUBSTRING(ISNULL(ContactInformationForEmails.FieldValues, """"), 1, 1024) AS MessageFieldValues
				|FROM
				|	Subscribers AS Subscribers
				|		LEFT JOIN Catalog.Partners.ContactInformation AS ContactInformationForEmails
				|		ON Subscribers.Subscriber = ContactInformationForEmails.Ref
				|			AND (ContactInformationForEmails.Kind = &PartnerContactDetailsKindForMails)
				|		LEFT JOIN Catalog.Partners.ContactInformation AS ContactInformationForSMS
				|		ON Subscribers.Subscriber = ContactInformationForSMS.Ref
				|			AND (ContactInformationForSMS.Kind = &PartnerContactDetailsKindForSMSMessage)
				|		INNER JOIN Catalog.Partners AS Partners
				|		ON Subscribers.Subscriber = Partners.Ref";
				
			EndIf;

			
		Else
			
			If EventTypeData.SendToCustomer Then
				
				ResultingQueryContainsText = True;
				
				TextContactInformationSubscribers = "
				|SELECT
				|	Subscribers.NotificationSource AS NotificationSource,
				|	Subscribers.Subscriber,
				|	Subscribers.Subscriber AS Recipient,
				|	Partners.DescriptionFull AS RecipientPresentation1,
				|	ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForMails, UNDEFINED) AS ContactDetailsKindForMails,
				|	ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForSMSMessage, UNDEFINED) AS ContactDetailsKindForSMSMessage
				|INTO SubscribersTypesOfKi
				|FROM
				|	Subscribers AS Subscribers
				|		INNER JOIN Catalog.Partners AS Partners
				|			LEFT JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
				|			ON (NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark)
				|				AND (SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid)
				|				AND (SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer)
				|				AND (SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications)
				|				AND Partners.Ref = SubscriptionsToCustomerMailoutsAndNotifications.Owner
				|		ON Subscribers.Subscriber = Partners.Ref
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT
				|	SubscribersTypesOfKi.NotificationSource,
				|	SubscribersTypesOfKi.Subscriber,
				|	SubscribersTypesOfKi.Recipient,
				|	SubscribersTypesOfKi.RecipientPresentation1,
				|	ISNULL(ContactInformationPhone.Presentation, """") AS PhonePresentation_,
				|	SUBSTRING(ISNULL(ContactInformationPhone.FieldValues, """"), 1, 1024) AS ValueOfPhoneFields,
				|	ISNULL(ContactInformationLetters.Presentation, """") AS PresentationLetter,
				|	SUBSTRING(ISNULL(ContactInformationLetters.FieldValues, """"), 1, 1024) AS MessageFieldValues
				|FROM
				|	SubscribersTypesOfKi AS SubscribersTypesOfKi
				|		LEFT JOIN Catalog.Partners.ContactInformation AS ContactInformationLetters
				|		ON SubscribersTypesOfKi.Recipient = ContactInformationLetters.Ref
				|			AND SubscribersTypesOfKi.ContactDetailsKindForMails = ContactInformationLetters.Kind
				|		LEFT JOIN Catalog.Partners.ContactInformation AS ContactInformationPhone
				|		ON SubscribersTypesOfKi.Recipient = ContactInformationPhone.Ref
				|			AND SubscribersTypesOfKi.ContactDetailsKindForSMSMessage = ContactInformationPhone.Kind";
				
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	QueryTemplate = StrReplace(QueryTemplate, "%TemporaryTableSubscribers%", TextTemporaryTableSubscribers);
	QueryTemplate = StrReplace(QueryTemplate, "%ContactInformationSubscribers%", TextContactInformationSubscribers);
	
EndProcedure

Procedure ProcessRequestTextForContactPersonsForNotifications(QueryTemplate, NotificationTypeData, ArrayOfAlertSources, EventTypeData, ResultingQueryContainsText)
	
	If EventTypeData.SendNotificationsToObjectSContactPersons Then
		
		TextTemporaryTableTemporaryTableContactPersonsAlerts = "
		|SELECT
		|	EventQueueForNotificationsToCustomers.NotificationSource AS NotificationSource,
		|	EventQueueForNotificationsToCustomers.Subscriber AS Subscriber,
		|	EventQueueForNotificationsToCustomers.NotificationSource" + EventTypeData.PathToContactPerson + " AS ContactPersonOfANotificationObject
		|INTO ContactPersonsNotificationObject
		|FROM
		|	InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
		|WHERE
		|	EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind
		|	AND EventQueueForNotificationsToCustomers.Period < &DateOfProcessing
		|;
		|
		|/////////////////////////////////////////////////////";
		
		If NotificationTypeData.Forced Then
			
			TextContactInformationContactPersonsAlerts = "
			|SELECT
			|	ContactPersonsNotificationObject.NotificationSource AS NotificationSource,
			|	ContactPersonsNotificationObject.Subscriber,
			|	ContactPersonsNotificationObject.ContactPersonOfANotificationObject AS Recipient,
			|	ContactPersonsForPartners.Description AS RecipientPresentation1,
			|	ISNULL(ContactInformationForSMS.Presentation, """") AS PhonePresentation_,
			|	SUBSTRING(ISNULL(ContactInformationForSMS.FieldValues, """"), 1, 1024) AS ValueOfPhoneFields,
			|	ISNULL(ContactInformationForEmails.Presentation, """") AS PresentationLetter,
			|	SUBSTRING(ISNULL(ContactInformationForEmails.FieldValues, """"), 1, 1024) AS MessageFieldValues
			|FROM
			|	ContactPersonsNotificationObject AS ContactPersonsNotificationObject
			|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactInformationForEmails
			|		ON ContactPersonsNotificationObject.ContactPersonOfANotificationObject = ContactInformationForEmails.Ref
			|			AND (ContactInformationForEmails.Kind = &TypeOfContactPersonSCIForEmails)
			|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactInformationForSMS
			|		ON ContactPersonsNotificationObject.ContactPersonOfANotificationObject = ContactInformationForSMS.Ref
			|			AND (ContactInformationForSMS.Kind = &TypeOfContactPersonSKiForSMS)
			|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
			|		ON ContactPersonsNotificationObject.ContactPersonOfANotificationObject = ContactPersonsForPartners.Ref";
			
		Else
			
			TextTemporaryTableTemporaryTableContactPersonsAlerts = TextTemporaryTableTemporaryTableContactPersonsAlerts + "
			|SELECT
			|	ContactPersonsNotificationObject.NotificationSource AS NotificationSource,
			|	ContactPersonsNotificationObject.Subscriber,
			|	ContactPersonsNotificationObject.ContactPersonOfANotificationObject AS Recipient,
			|	ContactPersonsForPartners.Description AS RecipientPresentation1,
			|	ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForMails, UNDEFINED) AS ContactDetailsKindForMails,
			|	ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForSMSMessage, UNDEFINED) AS ContactDetailsKindForSMSMessage
			|INTO ContactPersonsAndTypesOfCI
			|FROM
			|	ContactPersonsNotificationObject AS ContactPersonsNotificationObject
			|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
			|			LEFT JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
			|			ON (NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark)
			|				AND (SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid)
			|				AND (SubscriptionsToCustomerMailoutsAndNotifications.SendToAContactPersonOfANotificationObject)
			|				AND (SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications)
			|				AND ContactPersonsForPartners.Owner = SubscriptionsToCustomerMailoutsAndNotifications.Owner
			|		ON ContactPersonsNotificationObject.ContactPersonOfANotificationObject = ContactPersonsForPartners.Ref
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////";
			
			TextContactInformationContactPersonsAlerts = "
			|SELECT
			|	ContactPersonsAndTypesOfCI.NotificationSource,
			|	ContactPersonsAndTypesOfCI.Subscriber,
			|	ContactPersonsAndTypesOfCI.Recipient,
			|	ContactPersonsAndTypesOfCI.RecipientPresentation1,
			|	ISNULL(ContactInformationPhone.Presentation, """") AS PhonePresentation_,
			|	SUBSTRING(ISNULL(ContactInformationPhone.FieldValues, """"), 1, 1024) AS ValueOfPhoneFields,
			|	ISNULL(ContactInformationLetters.Presentation, """") AS PresentationLetter,
			|	SUBSTRING(ISNULL(ContactInformationLetters.FieldValues, """"), 1, 1024) AS MessageFieldValues
			|FROM
			|	ContactPersonsAndTypesOfCI AS ContactPersonsAndTypesOfCI
			|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactInformationLetters
			|		ON ContactPersonsAndTypesOfCI.Recipient = ContactInformationLetters.Ref
			|			AND ContactPersonsAndTypesOfCI.ContactDetailsKindForMails = ContactInformationLetters.Kind
			|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactInformationPhone
			|		ON ContactPersonsAndTypesOfCI.Recipient = ContactInformationPhone.Ref
			|			AND ContactPersonsAndTypesOfCI.ContactDetailsKindForSMSMessage = ContactInformationPhone.Kind";
			
		EndIf;
		
	Else
		
		TextTemporaryTableTemporaryTableContactPersonsAlerts = "";
		TextContactInformationContactPersonsAlerts = "";
		
	EndIf;
	
	If Not IsBlankString(TextContactInformationContactPersonsAlerts) Then
		If ResultingQueryContainsText Then
			TextContactInformationContactPersonsAlerts = TextUnion() + TextContactInformationContactPersonsAlerts;
		EndIf;
		ResultingQueryContainsText = True;
	EndIf;
	
	QueryTemplate = StrReplace(QueryTemplate, "%TemporaryTableContactPersonsAlerts%", TextTemporaryTableTemporaryTableContactPersonsAlerts);
	QueryTemplate = StrReplace(QueryTemplate, "%ContactInformationOfAlertContactPersons%", TextContactInformationContactPersonsAlerts);
	
EndProcedure

Procedure ProcessRequestTextForSubscriberSContactPersons(QueryTemplate,
	                                                        NotificationTypeData,
	                                                        ProcessingDate,
	                                                        EventTypeData,
	                                                        ResultingQueryContainsText)

	If EventTypeData.SendToPartnerSContactPersons Then
		
		If NotificationTypeData.Forced Then
			
			TextTemporaryTableContactPersonsOfSubscribers = "
			|SELECT DISTINCT
			|	EventQueueForNotificationsToCustomers.NotificationSource,
			|	EventQueueForNotificationsToCustomers.Subscriber,
			|	ContactPersonsForPartners.Ref AS Recipient
			|INTO SubscriberSContactPersons
			|FROM
			|	InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
			|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
			|		ON EventQueueForNotificationsToCustomers.Subscriber = ContactPersonsForPartners.Owner
			|		INNER JOIN Catalog.ContactPersonsForPartners.ContactPersonRoles AS ContactPersonsOfPartnersRoleOfContactPerson
			|		ON (ContactPersonsOfPartnersRoleOfContactPerson.Ref = ContactPersonsForPartners.Ref)
			|			AND (ContactPersonsOfPartnersRoleOfContactPerson.ContactRole = &ContactRole)
			|WHERE
			|	EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind
			|	AND EventQueueForNotificationsToCustomers.Period < &DateOfProcessing
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////";
			
			TextContactInformationContactPersonsOfSubscribers = "
			|SELECT
			|	SubscriberSContactPersons.NotificationSource AS NotificationSource,
			|	SubscriberSContactPersons.Subscriber,
			|	SubscriberSContactPersons.Recipient AS Recipient,
			|	ContactPersonsForPartners.Description AS RecipientPresentation1,
			|	ISNULL(ContactInformationForSMS.Presentation, """") AS PhonePresentation_,
			|	SUBSTRING(ISNULL(ContactInformationForSMS.FieldValues, """"), 1, 1024) AS ValueOfPhoneFields,
			|	ISNULL(ContactInformationForEmails.Presentation, """") AS PresentationLetter,
			|	SUBSTRING(ISNULL(ContactInformationForEmails.FieldValues, """"), 1, 1024) AS MessageFieldValues
			|FROM
			|	SubscriberSContactPersons AS SubscriberSContactPersons
			|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactInformationForEmails
			|		ON SubscriberSContactPersons.Recipient = ContactInformationForEmails.Ref
			|			AND (ContactInformationForEmails.Kind = &TypeOfContactPersonSCIForEmails)
			|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactInformationForSMS
			|		ON SubscriberSContactPersons.Recipient = ContactInformationForSMS.Ref
			|			AND (ContactInformationForSMS.Kind = &TypeOfContactPersonSKiForSMS)
			|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
			|		ON SubscriberSContactPersons.Recipient = ContactPersonsForPartners.Ref";

		Else
			
			TextTemporaryTableContactPersonsOfSubscribers = "
			|SELECT DISTINCT
			|	EventQueueForNotificationsToCustomers.NotificationSource,
			|	EventQueueForNotificationsToCustomers.Subscriber,
			|	SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactPerson AS Recipient,
			|	SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactDetailsKindForMails,
			|	SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactDetailsKindForSMSMessage
			|INTO SubscriberSContactPersons
			|FROM
			|	InformationRegister.EventQueueForNotificationsToCustomers AS EventQueueForNotificationsToCustomers
			|		INNER JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
			|			INNER JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications.ContactPersons AS SubscriptionsToCustomerMailoutsAndNotificationsContactPersons
			|			ON SubscriptionsToCustomerMailoutsAndNotifications.Ref = SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.Ref
			|		ON EventQueueForNotificationsToCustomers.Subscriber = SubscriptionsToCustomerMailoutsAndNotifications.Owner
			|			AND (SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications)
			|			AND (NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark)
			|			AND (SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid)
			|WHERE
			|	EventQueueForNotificationsToCustomers.NotificationKind = &NotificationKind
			|	AND EventQueueForNotificationsToCustomers.Period < &DateOfProcessing
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
			TextContactInformationContactPersonsOfSubscribers = "
			|SELECT
			|	SubscriberSContactPersons.NotificationSource AS NotificationSource,
			|	SubscriberSContactPersons.Subscriber,
			|	SubscriberSContactPersons.Recipient AS Recipient,
			|	ContactPersonsForPartners.Description AS RecipientPresentation1,
			|	ISNULL(ContactInformationForSMS.Presentation, """") AS PhonePresentation_,
			|	SUBSTRING(ISNULL(ContactInformationForSMS.FieldValues, """"), 1, 1024) AS ValueOfPhoneFields,
			|	ISNULL(ContactInformationForEmails.Presentation, """") AS PresentationLetter,
			|	SUBSTRING(ISNULL(ContactInformationForEmails.FieldValues, """"), 1, 1024) AS MessageFieldValues
			|FROM
			|	SubscriberSContactPersons AS SubscriberSContactPersons
			|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactInformationForEmails
			|		ON SubscriberSContactPersons.Recipient = ContactInformationForEmails.Ref
			|			AND (ContactInformationForEmails.Kind = SubscriberSContactPersons.ContactDetailsKindForMails)
			|		LEFT JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactInformationForSMS
			|		ON SubscriberSContactPersons.Recipient = ContactInformationForSMS.Ref
			|			AND (ContactInformationForSMS.Kind = SubscriberSContactPersons.ContactDetailsKindForSMSMessage)
			|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
			|		ON SubscriberSContactPersons.Recipient = ContactPersonsForPartners.Ref";
			
		EndIf;
		
	Else
		
		TextTemporaryTableContactPersonsOfSubscribers = "";
		TextContactInformationContactPersonsOfSubscribers = "";
		
	EndIf;
	
	If Not IsBlankString(TextContactInformationContactPersonsOfSubscribers) Then
		
		If ResultingQueryContainsText Then
			TextContactInformationContactPersonsOfSubscribers = TextUnion() + TextContactInformationContactPersonsOfSubscribers;
		EndIf;
		
		ResultingQueryContainsText = True;
		
	EndIf;
	
	QueryTemplate = StrReplace(QueryTemplate, "%TemporaryTableSubscriberContactPersons%", TextTemporaryTableContactPersonsOfSubscribers);
	QueryTemplate = StrReplace(QueryTemplate, "%ContactInformationOfSubscriberSContactPersons%", TextContactInformationContactPersonsOfSubscribers);

EndProcedure

Function CommentForNotificationMessage(NotificationTypeData)

	CommentText1 =  NStr("vi = 'Đã tạo dạng thông báo ""%1""';
						|ru = 'Создано по виду оповещения ""%1""';
						|en = 'Created by notification kind ""%1""'; fa = 'Created by notification kind ""%1""';
						|it = 'Creato dal tipo di avviso ""%1""';
						|pl = 'Utworzono według typu powiadomienia ""%1""';
						|tr = '""%1"" bildirim türüne göre oluşturuldu'");
	CommentText1 = StringFunctionsClientServer.SubstituteParametersToString(CommentText1, NotificationTypeData.Description);
	
	Return CommentText1;
	
EndFunction

#EndRegion

#Region CreatingMailingDocuments

Procedure ProcessRequestTextMailingRecipients(Data, Query, ThereIsSelectionOnLayout)

	If Data.Forced Then
		
		QueryTextPartners       = "";
		QueryTextContactPersons = "";
		
		If Data.SendToCustomer Then
			
			QueryTextPartners = "
			|SELECT DISTINCT
			|	PartnersContactInformation.Ref AS Partner,
			|	PartnersContactInformation.Ref AS Recipient,
			|	PartnersContactInformation.Presentation AS ContactInformationPresentation,
			|	CASE
			|		WHEN &DesignedForLetters
			|			THEN PartnersContactInformation.EMAddress
			|		ELSE PartnersContactInformation.PhoneNumber
			|	END AS ContactInformation,
			|	SUBSTRING(PartnersContactInformation.FieldValues, 1, 1024) AS FieldValues,
			|	Partners.DescriptionFull AS RecipientPresentation1
			|FROM
			|	Catalog.Partners.ContactInformation AS PartnersContactInformation
			|		INNER JOIN Catalog.Partners AS Partners
			|		ON PartnersContactInformation.Ref = Partners.Ref
			|			AND (PartnersContactInformation.Kind = &TypeOfPartnerContactInformation)
			|			AND (NOT Partners.DeletionMark)
			|			AND &SelectionConnection";
			
			ProcessRequestTextForDistributionPartners(Query, QueryTextPartners, Data, ThereIsSelectionOnLayout);
			
		EndIf;
		
		If Data.SendToRoleContactPersons Then
			
			QueryTextContactPersons ="
			|SELECT DISTINCT
			|	ContactPersonsForPartners.Owner AS Partner,
			|	ContactPersonsOfPartnersContactInformation.Ref AS Recipient,
			|	ContactPersonsOfPartnersContactInformation.Presentation AS ContactInformationPresentation,
			|	CASE
			|		WHEN &DesignedForLetters
			|			THEN ContactPersonsOfPartnersContactInformation.EMAddress
			|		ELSE ContactPersonsOfPartnersContactInformation.PhoneNumber
			|	END AS ContactInformation,
			|	SUBSTRING(ContactPersonsOfPartnersContactInformation.FieldValues, 1, 1024) AS FieldValues,
			|	ContactPersonsForPartners.Description AS RecipientPresentation1
			|FROM
			|	Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
			|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
			|		ON ContactPersonsOfPartnersContactInformation.Ref = ContactPersonsForPartners.Ref
			|			AND (NOT ContactPersonsForPartners.DeletionMark)
			|		AND &SelectionConnection
			|		INNER JOIN Catalog.ContactPersonsForPartners.ContactPersonRoles AS ContactPersonsOfPartnersRoleOfContactPerson
			|		ON ContactPersonsOfPartnersContactInformation.Ref = ContactPersonsOfPartnersRoleOfContactPerson.Ref
			|			AND (ContactPersonsOfPartnersRoleOfContactPerson.ContactRole = &ContactRole)
			|			AND (ContactPersonsOfPartnersContactInformation.Kind = &TypeOfContactInformationOfContactPerson)
			|		";
			
			ProcessRequestTextByMailingContactPersons(Query, QueryTextContactPersons, Data, ThereIsSelectionOnLayout);
			Query.SetParameter("ContactRole", Data.ContactRole);
			
		EndIf;
		
		If (Not Data.SendToCustomer) And (Not Data.SendToRoleContactPersons) Then
			Query.Text = "";
		Else
			TextIsNeeded = Data.SendToCustomer And Data.SendToRoleContactPersons;
			Query.Text = Query.Text + QueryTextPartners + ?(TextIsNeeded, TextUnion(), "") + QueryTextContactPersons;
		EndIf;
		
	Else // By subscriptions
		
		QueryTextSubscribers = "
		|SELECT
		|	SubscriptionsToCustomerMailoutsAndNotifications.Owner AS Partner,
		|	SubscriptionsToCustomerMailoutsAndNotifications.Owner AS Recipient,
		|	PartnersContactInformation.Presentation AS ContactInformationPresentation,
		|	CASE
		|		WHEN &DesignedForLetters
		|			THEN PartnersContactInformation.EMAddress
		|		ELSE PartnersContactInformation.PhoneNumber
		|	END AS ContactInformation,
		|	SUBSTRING(PartnersContactInformation.FieldValues, 1, 1024) AS FieldValues,
		|	Partners.DescriptionFull AS RecipientPresentation1
		|FROM
		|	Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
		|		INNER JOIN Catalog.Partners AS Partners
		|		ON SubscriptionsToCustomerMailoutsAndNotifications.Owner = Partners.Ref
		|		INNER JOIN Catalog.Partners.ContactInformation AS PartnersContactInformation
		|		ON SubscriptionsToCustomerMailoutsAndNotifications.Owner = PartnersContactInformation.Ref
		|			AND (CASE
		|				WHEN &DesignedForLetters
		|					THEN SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForMails = PartnersContactInformation.Kind
		|				ELSE SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForSMSMessage = PartnersContactInformation.Kind
		|			END)
		|		AND &SelectionConnection
		|WHERE
		|	SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
		|	AND SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer
		|	AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
		|	AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	ContactPersonsForPartners.Owner AS Partner,
		|	SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactPerson AS Recipient,
		|	ContactPersonsOfPartnersContactInformation.Presentation AS ContactInformationPresentation,
		|	CASE
		|		WHEN &DesignedForLetters
		|			THEN ContactPersonsOfPartnersContactInformation.EMAddress
		|		ELSE ContactPersonsOfPartnersContactInformation.PhoneNumber
		|	END AS ContactInformation,
		|	SUBSTRING(ContactPersonsOfPartnersContactInformation.FieldValues, 1, 1024),
		|	ContactPersonsForPartners.Description
		|FROM
		|	Catalog.SubscriptionsToCustomerMailoutsAndNotifications.ContactPersons AS SubscriptionsToCustomerMailoutsAndNotificationsContactPersons
		|		INNER JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
		|		ON SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.Ref = SubscriptionsToCustomerMailoutsAndNotifications.Ref
		|		AND &SelectionConnection
		|		INNER JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
		|		ON SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactPerson = ContactPersonsOfPartnersContactInformation.Ref
		|			AND (CASE
		|				WHEN &DesignedForLetters
		|					THEN SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactDetailsKindForMails = ContactPersonsOfPartnersContactInformation.Kind
		|				ELSE SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactDetailsKindForSMSMessage = ContactPersonsOfPartnersContactInformation.Kind
		|			END)
		|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
		|		ON SubscriptionsToCustomerMailoutsAndNotificationsContactPersons.ContactPerson = ContactPersonsForPartners.Ref
		|WHERE
		|	NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
		|	AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
		|	AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications";
		
		Query.SetParameter("GroupOfMailoutsAndNotifications", Data.GroupOfMailoutsAndNotifications);
		
		If ThereIsSelectionOnLayout Then
			SelectionGuideText ="INNER JOIN PartnerFilter AS PartnerFilter
			                         |ON SubscriptionsToCustomerMailoutsAndNotifications.Owner = PartnerFilter.Partner";
		Else
			TextSelectionConnectionPartners = "";
		EndIf;
		
		QueryTextSubscribers = StrReplace(QueryTextSubscribers, "AND &SelectionConnection", SelectionGuideText);
		Query.Text = Query.Text + QueryTextSubscribers;
		
	EndIf;

EndProcedure

// Adds a connection to the temporary selection table to the request text for distribution partners, if necessary
//  , and sets the value of the partner's contact information View parameter.
//
// Parameters:
//  Query                - Query - a request that is generated dynamically.
//  QueryText          - String - the text of the request to be processed.
//  Data                - Structure - contains the details of the document "Mailing to clients".
//  ThereIsSelectionOnLayout - Boolean - indicates that the partner selection is set.
//
Procedure ProcessRequestTextForDistributionPartners(Query, QueryText, Data, ThereIsSelectionOnLayout) Export
	
	If ThereIsSelectionOnLayout Then
		SelectionGuideText ="INNER JOIN PartnerFilter AS PartnerFilter
		|ON PartnersContactInformation.Ref = PartnerFilter.Partner";
	Else
		SelectionGuideText = "";
	EndIf;
	
	QueryText = StrReplace(QueryText, "AND &SelectionConnection", SelectionGuideText);
	
	Query.SetParameter("TypeOfPartnerContactInformation",
	?(Data.DesignedForEmails,
	Data.PartnerSContactDetailsKindForEmails,
	Data.PartnerSContactDetailsKindForSMSMessage));
	
EndProcedure

// Adds, if necessary, a connection to the temporary selection table to the text of the request for mailing contact persons
//  and sets the value of the parameter viewcontact informationcontact Face.
//
// Parameters:
//  Query                - Query - a request that is generated dynamically.
//  QueryText          - String - the text of the request to be processed.
//  Data                - Structure - contains the details of the document "Mailing to clients".
//  ThereIsSelectionOnLayout - Boolean - indicates that the partner selection is set.
//
Procedure ProcessRequestTextByMailingContactPersons(Query, QueryText, Data, ThereIsSelectionOnLayout) Export

	If ThereIsSelectionOnLayout Then
		SelectionGuideText ="INNER JOIN PartnerFilter AS PartnerFilter
		|ON ContactPersonsForPartners.Owner = PartnerFilter.Partner";
	Else
		SelectionGuideText = "";
	EndIf;
	
	QueryText = StrReplace(QueryText, "AND &SelectionConnection", SelectionGuideText);
	
	Query.SetParameter("TypeOfContactInformationOfContactPerson",
	?(Data.DesignedForEmails,
	Data.ContactPersonSContactDetailsKindForEmails,
	Data.ContactPersonSContactDetailsKindForSMSMessage));

EndProcedure

Procedure ProcessRequestTextMailingListAddresseesSurveyAssignments(Data, TheseGrounds, Query, ThereIsSelectionOnLayout)
	
	If Data.Forced Then
		
		If TypeOf(TheseGrounds.RespondentsType) = Type("CatalogRef.Partners") And Data.SendToCustomer Then
			
			If TheseGrounds.FreeSurvey Then
				
				QueryTextRespondents = "
				|SELECT DISTINCT
				|	PartnersContactInformation.Ref AS Partner,
				|	PartnersContactInformation.Ref AS Recipient,
				|	PartnersContactInformation.Presentation AS ContactInformationPresentation,
				|	CASE
				|		WHEN &DesignedForLetters
				|			THEN PartnersContactInformation.EMAddress
				|		ELSE PartnersContactInformation.PhoneNumber
				|	END AS ContactInformation,
				|	SUBSTRING(PartnersContactInformation.FieldValues, 1, 1024) AS FieldValues,
				|	Partners.DescriptionFull AS RecipientPresentation1
				|FROM
				|	Catalog.Partners.ContactInformation AS PartnersContactInformation
				|		INNER JOIN Catalog.Partners AS Partners
				|		ON PartnersContactInformation.Ref = Partners.Ref
				|			AND (PartnersContactInformation.Kind = &TypeOfPartnerContactInformation)
				|			AND (NOT Partners.DeletionMark)
				|		AND &SelectionConnection";
				
			Else
				
				QueryTextRespondents = "
				|SELECT DISTINCT
				|	PollPurposeRespondents.Respondent AS Partner,
				|	PollPurposeRespondents.Respondent AS Recipient,
				|	PartnersContactInformation.Presentation AS ContactInformationPresentation,
				|	CASE
				|		WHEN &DesignedForLetters
				|			THEN PartnersContactInformation.EMAddress
				|		ELSE PartnersContactInformation.PhoneNumber
				|	END AS ContactInformation,
				|	SUBSTRING(PartnersContactInformation.FieldValues, 1, 1024) AS FieldValues,
				|	Partners.DescriptionFull AS RecipientPresentation1
				|FROM
				|	Document.PollPurpose.Respondents AS PollPurposeRespondents
				|		INNER JOIN Catalog.Partners.ContactInformation AS PartnersContactInformation
				|		ON PollPurposeRespondents.Respondent = PartnersContactInformation.Ref
				|			AND (PartnersContactInformation.Kind = &TypeOfPartnerContactInformation)
				|		INNER JOIN Catalog.Partners AS Partners
				|		ON PollPurposeRespondents.Respondent = Partners.Ref
				|		AND &SelectionConnection
				|WHERE
				|	PollPurposeRespondents.Ref = &PollPurpose"
				
			EndIf;
			
			ProcessRequestTextForDistributionPartners(Query, QueryTextRespondents, Data, ThereIsSelectionOnLayout);
			
		ElsIf TypeOf(TheseGrounds.RespondentsType) = Type("CatalogRef.ContactPersonsForPartners") And Data.SendToAContactPersonOfANotificationObject Then
			
			If TheseGrounds.FreeSurvey Then
				
				QueryTextRespondents ="
				|SELECT DISTINCT
				|	ContactPersonsForPartners.Owner AS Partner,
				|	ContactPersonsOfPartnersContactInformation.Ref AS Recipient,
				|	ContactPersonsOfPartnersContactInformation.Presentation AS ContactInformationPresentation,
				|	CASE
				|		WHEN &DesignedForLetters
				|			THEN ContactPersonsOfPartnersContactInformation.EMAddress
				|		ELSE ContactPersonsOfPartnersContactInformation.PhoneNumber
				|	END AS ContactInformation,
				|	SUBSTRING(ContactPersonsOfPartnersContactInformation.FieldValues, 1, 1024) AS FieldValues,
				|	ContactPersonsForPartners.Description AS RecipientPresentation1
				|FROM
				|	Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
				|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
				|		ON ContactPersonsOfPartnersContactInformation.Ref = ContactPersonsForPartners.Ref
				|			AND (ContactPersonsOfPartnersContactInformation.Kind = &TypeOfContactInformationOfContactPerson)
				|			AND (NOT ContactPersonsForPartners.DeletionMark)
				|		AND &SelectionConnection
				|";
				
			Else
				
				QueryTextRespondents = "
				|SELECT DISTINCT
				|	Partners.Ref AS Partner,
				|	PollPurposeRespondents.Respondent AS Recipient,
				|	ContactPersonsOfPartnersContactInformation.Presentation AS ContactInformationPresentation,
				|	CASE
				|		WHEN &DesignedForLetters
				|			THEN ContactPersonsOfPartnersContactInformation.EMAddress
				|		ELSE ContactPersonsOfPartnersContactInformation.PhoneNumber
				|	END AS ContactInformation,
				|	SUBSTRING(ContactPersonsOfPartnersContactInformation.FieldValues, 1, 1024) AS FieldValues,
				|	ContactPersonsForPartners.Description AS RecipientPresentation1
				|FROM
				|	Document.PollPurpose.Respondents AS PollPurposeRespondents
				|		INNER JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
				|		ON PollPurposeRespondents.Respondent = ContactPersonsOfPartnersContactInformation.Ref
				|			AND (ContactPersonsOfPartnersContactInformation.Kind = &TypeOfContactInformationOfContactPerson)
				|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
				|		ON ContactPersonsOfPartnersContactInformation.Ref = ContactPersonsForPartners.Ref
				|		AND &SelectionConnection
				|		INNER JOIN Catalog.Partners AS Partners
				|		ON ContactPersonsForPartners.Owner = Partners.Ref
				|WHERE
				|	PollPurposeRespondents.Ref = &PollPurpose";
				
			EndIf;
			
			ProcessRequestTextByMailingContactPersons(Query, QueryTextRespondents, Data, ThereIsSelectionOnLayout);
			
		EndIf;
		
	Else
		
		Query.SetParameter("GroupOfMailoutsAndNotifications", Data.GroupOfMailoutsAndNotifications);
		
		If TypeOf(TheseGrounds.RespondentsType) = Type("CatalogRef.Partners")  Then
			
			If TheseGrounds.FreeSurvey Then
				
				QueryTextRespondents = "
				|SELECT DISTINCT
				|	SubscriptionsToCustomerMailoutsAndNotifications.Owner AS Partner,
				|	SubscriptionsToCustomerMailoutsAndNotifications.Owner AS Recipient,
				|	PartnersContactInformation.Presentation AS ContactInformationPresentation,
				|	CASE
				|		WHEN &DesignedForLetters
				|			THEN PartnersContactInformation.EMAddress
				|		ELSE PartnersContactInformation.PhoneNumber
				|	END AS ContactInformation,
				|	SUBSTRING(PartnersContactInformation.FieldValues, 1, 1024) AS FieldValues,
				|	Partners.DescriptionFull AS RecipientPresentation1
				|FROM
				|	Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
				|		INNER JOIN Catalog.Partners AS Partners
				|		ON SubscriptionsToCustomerMailoutsAndNotifications.Owner = Partners.Ref
				|		INNER JOIN Catalog.Partners.ContactInformation AS PartnersContactInformation
				|		ON SubscriptionsToCustomerMailoutsAndNotifications.Owner = PartnersContactInformation.Ref
				|			AND (CASE
				|				WHEN &DesignedForLetters
				|					THEN SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForMails = PartnersContactInformation.Kind
				|				ELSE SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForSMSMessage = PartnersContactInformation.Kind
				|			END)
				|		AND &SelectionConnection
				|WHERE
				|	SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
				|	AND SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer
				|	AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
				|	AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications";
				
			Else
				
				QueryTextRespondents = "
				|SELECT DISTINCT
				|	PollPurposeRespondents.Respondent AS Partner,
				|	PollPurposeRespondents.Respondent AS Recipient,
				|	PartnersContactInformation.Presentation AS ContactInformationPresentation,
				|	CASE
				|		WHEN &DesignedForLetters
				|			THEN PartnersContactInformation.EMAddress
				|		ELSE PartnersContactInformation.PhoneNumber
				|	END AS ContactInformation,
				|	SUBSTRING(PartnersContactInformation.FieldValues, 1, 1024) AS FieldValues,
				|	Partners.DescriptionFull AS RecipientPresentation1
				|FROM
				|	Document.PollPurpose.Respondents AS PollPurposeRespondents
				|		INNER JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
				|			ON PollPurposeRespondents.Respondent = SubscriptionsToCustomerMailoutsAndNotifications.Owner
				|				AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
				|				AND SubscriptionsToCustomerMailoutsAndNotifications.SendToCustomer
				|				AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
				|				AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications			
				|		INNER JOIN Catalog.Partners.ContactInformation AS PartnersContactInformation
				|		ON PollPurposeRespondents.Respondent = PartnersContactInformation.Ref
				|			AND (CASE
				|				WHEN &DesignedForLetters
				|					THEN SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForMails = PartnersContactInformation.Kind
				|				ELSE SubscriptionsToCustomerMailoutsAndNotifications.PartnerContactDetailsKindForSMSMessage = PartnersContactInformation.Kind
				|			END)
				|		INNER JOIN Catalog.Partners AS Partners
				|		ON PollPurposeRespondents.Respondent = Partners.Ref
				|		AND &SelectionConnection
				|WHERE
				|	PollPurposeRespondents.Ref = &PollPurpose"
				
			EndIf;
			
			ProcessRequestTextForDistributionPartners(Query, QueryTextRespondents, Data, ThereIsSelectionOnLayout);
			
		ElsIf TypeOf(TheseGrounds.RespondentsType) = Type("CatalogRef.ContactPersonsForPartners") Then
			
			If TheseGrounds.FreeSurvey Then
				
				QueryTextRespondents = "
				|SELECT DISTINCT
				|	CatalogPartners.Ref AS Partner,
				|	ContactPersonsForPartners.Ref AS Recipient,
				|	ContactPersonsOfPartnersContactInformation.Presentation AS ContactInformationPresentation,
				|	CASE
				|		WHEN &DesignedForLetters
				|			THEN ContactPersonsOfPartnersContactInformation.EMAddress
				|		ELSE ContactPersonsOfPartnersContactInformation.PhoneNumber
				|	END AS ContactInformation,
				|	SUBSTRING(ContactPersonsOfPartnersContactInformation.FieldValues, 1, 1024) AS FieldValues,
				|	ContactPersonsForPartners.Description AS RecipientPresentation1
				|FROM
				|	Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
				|		INNER JOIN Catalog.Partners AS CatalogPartners
				|		ON SubscriptionsToCustomerMailoutsAndNotifications.Owner = CatalogPartners.Ref
				|		INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
				|		ON (CatalogPartners.Ref = ContactPersonsForPartners.Owner)
				|		INNER JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
				|		ON (ContactPersonsForPartners.Ref = ContactPersonsOfPartnersContactInformation.Ref)
				|			AND (CASE
				|				WHEN &DesignedForLetters
				|					THEN SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForMails = ContactPersonsOfPartnersContactInformation.Kind
				|				ELSE SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForSMSMessage = ContactPersonsOfPartnersContactInformation.Kind
				|			END)
				|		AND &SelectionConnection
				|WHERE
				|	NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
				|	AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
				|	AND SubscriptionsToCustomerMailoutsAndNotifications.SendToAContactPersonOfANotificationObject
				|	AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications";

			Else
				
				QueryTextRespondents = "
				|SELECT DISTINCT
				|	PollPurposeRespondents.Respondent AS Partner,
				|	PollPurposeRespondents.Respondent AS Recipient,
				|	ContactPersonsOfPartnersContactInformation.Presentation AS ContactInformationPresentation,
				|	CASE
				|		WHEN &DesignedForLetters
				|			THEN ContactPersonsOfPartnersContactInformation.EMAddress
				|		ELSE ContactPersonsOfPartnersContactInformation.PhoneNumber
				|	END AS ContactInformation,
				|	SUBSTRING(ContactPersonsOfPartnersContactInformation.FieldValues, 1, 1024) AS FieldValues,
				|	ContactPersonsForPartners.Description AS RecipientPresentation1
				|FROM
				|	Document.PollPurpose.Respondents AS PollPurposeRespondents
				|	INNER JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
				|		ON PollPurposeRespondents.Respondent = ContactPersonsForPartners.Ref
				|	INNER JOIN Catalog.Partners AS Partners
				|		ON ContactPersonsForPartners.Owner = Partners.Ref
				|		INNER JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
				|			ON Partners.Ref = SubscriptionsToCustomerMailoutsAndNotifications.Owner
				|				AND SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid
				|				AND SubscriptionsToCustomerMailoutsAndNotifications.SendToAContactPersonOfANotificationObject
				|				AND NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark
				|				AND SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications			
				|		INNER JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
				|		ON ContactPersonsForPartners.Ref = ContactPersonsOfPartnersContactInformation.Ref
				|			AND (CASE
				|				WHEN &DesignedForLetters
				|					THEN SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForMails = ContactPersonsOfPartnersContactInformation.Kind
				|				ELSE SubscriptionsToCustomerMailoutsAndNotifications.ContactPersonContactDetailsKindOfNotificationObjectForSMSMessage = ContactPersonsOfPartnersContactInformation.Kind
				|			END)
				|		AND &SelectionConnection
				|WHERE
				|	PollPurposeRespondents.Ref = &PollPurpose"
				
			EndIf;
			
			ProcessRequestTextByMailingContactPersons(Query, QueryTextRespondents, Data, ThereIsSelectionOnLayout);

		EndIf;
		
	EndIf;
	
	Query.Text = Query.Text + QueryTextRespondents;
	Query.SetParameter("PollPurpose", TheseGrounds.Ref); 
	
EndProcedure

Function SelectionOfMailingRecipients(Data, TheseGrounds)
	
	SelectionOnBasisOf_ = False;
	Query = RequestSelectionByLayout(Data, SelectionOnBasisOf_);
	RequestTextSelectionByLayout = Query.Text;
	
	ThereIsSelectionOnLayout = Not IsBlankString(Query.Text);
	
	If TheseGrounds <> Undefined And SelectionOnBasisOf_ Then
		
		If TypeOf(TheseGrounds.Ref) = Type("DocumentRef.PollPurpose") Then
			
			ProcessRequestTextMailingListAddresseesSurveyAssignments(Data, TheseGrounds, Query, ThereIsSelectionOnLayout);
			
		EndIf;
		
	Else
		
		ProcessRequestTextMailingRecipients(Data, Query, ThereIsSelectionOnLayout);
		
	EndIf;
	
	If Query.Text = RequestTextSelectionByLayout Then
		Query.Text = "";
	EndIf;
	
	
	QueryTextAdditionalRecipients = "
	|SELECT DISTINCT
	|	CASE
	|		WHEN MailoutToCustomersAdditionalRecipients.Contact REFS Catalog.Partners
	|			THEN Partners.Ref
	|		ELSE ContactPersonsForPartners.Owner
	|	END AS Partner,
	|	MailoutToCustomersAdditionalRecipients.Contact AS Recipient,
	|	MailoutToCustomersAdditionalRecipients.ContactInformation AS ContactInformationPresentation,
	|	MailoutToCustomersAdditionalRecipients.ContactInformation AS ContactInformation,
	|	"""" AS FieldValues,
	|	CASE
	|		WHEN MailoutToCustomersAdditionalRecipients.Contact REFS Catalog.Partners
	|			THEN ISNULL(Partners.DescriptionFull, """")
	|		ELSE ISNULL(ContactPersonsForPartners.Description, """")
	|	END AS RecipientPresentation1
	|FROM
	|	Document.MailoutToCustomers.AdditionalRecipients AS MailoutToCustomersAdditionalRecipients
	|		LEFT JOIN Catalog.Partners AS Partners
	|		ON MailoutToCustomersAdditionalRecipients.Contact = Partners.Ref
	|		LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|		ON MailoutToCustomersAdditionalRecipients.Contact = ContactPersonsForPartners.Ref
	|WHERE
	|	MailoutToCustomersAdditionalRecipients.Ref = &MailoutToCustomers
	|TOTALS BY
	|	Partner,
	|   Recipient";
	
	Query.SetParameter("DesignedForLetters", Data.DesignedForEmails);
	Query.SetParameter("MailoutToCustomers", Data.Ref);
	
	Query.Text = Query.Text + ?(IsBlankString(Query.Text), "", TextUnion()) + QueryTextAdditionalRecipients;
	
	Return Query.Execute().Select(QueryResultIteration.ByGroups);
	
EndFunction 

Procedure CreateEmailsForDistribution(Data, SelectionOfMailingRecipients, ArrayOfCreatedInteractions, TheseGrounds)
	
	NewsletterIsPersonalized = NewsletterIsPersonalized(Data);
	AddresseesAddresses = New Map;
	ArrayOfMailingRecipients = New Array;
	
	While SelectionOfMailingRecipients.Next() Do
		
		If Not NewsletterIsPersonalized Then
			ArrayOfMailingRecipients.Clear();
		EndIf;
		
		SampleRecipient = SelectionOfMailingRecipients.Select(QueryResultIteration.ByGroups);
		While SampleRecipient.Next() Do
			
			If NewsletterIsPersonalized Then
				ArrayOfMailingRecipients.Clear();
			EndIf;
		
			DetailsSelection = SampleRecipient.Select();
			While DetailsSelection.Next() Do
				
				ArrayOfMailingRecipients.Add(DestinationDataForSelection(DetailsSelection));
				
			EndDo;
			
			If NewsletterIsPersonalized Then
				CreateEmailForMailingListRecipient(Data, ArrayOfMailingRecipients, AddresseesAddresses,
				                                 NewsletterIsPersonalized, ArrayOfCreatedInteractions, TheseGrounds);
			EndIf;
			
		EndDo;
		
		If Not NewsletterIsPersonalized Then
			CreateEmailForMailingListRecipient(Data, ArrayOfMailingRecipients, AddresseesAddresses,
			                                 NewsletterIsPersonalized, ArrayOfCreatedInteractions, TheseGrounds);
		EndIf;
		
	EndDo;
	
	If ArrayOfCreatedInteractions.Count() > 0 Then
		Interactions.SetFoldersForEmailsArray(ArrayOfCreatedInteractions);
	EndIf;
	
EndProcedure

Function DestinationDataForSelection(Selection)
	
	AddresseeData = New Structure;
	AddresseeData.Insert("FieldValues",                     Selection.FieldValues);
	AddresseeData.Insert("ContactInformation",              Selection.ContactInformation);
	AddresseeData.Insert("Partner",                           Selection.Partner);
	AddresseeData.Insert("Recipient",                        Selection.Recipient);
	AddresseeData.Insert("ContactInformationPresentation", Selection.ContactInformationPresentation);
	AddresseeData.Insert("RecipientPresentation1",           Selection.RecipientPresentation1);
	
	Return AddresseeData;
	
EndFunction

Function AlreadyPoisonedAtThisAddress(MailingAddress, AddresseesAddresses)
	
	AddressesArray = AddresseesAddresses.Get(MailingAddress.Recipient);
	If AddressesArray = Undefined Then
		
		AddressesArray = New Array;
		AddressesArray.Add(MailingAddress.ContactInformation);
		AddresseesAddresses.Insert(MailingAddress.Recipient, AddressesArray);
		
	Else
		If AddressesArray.Find(MailingAddress.ContactInformation) = Undefined Then
			AddressesArray.Add(MailingAddress.ContactInformation);
		Else
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

Procedure CreateEmailForMailingListRecipient(Data, ArrayOfMailingRecipients, AddresseesAddresses,
	                                       NewsletterIsPersonalized, ArrayOfCreatedEmails, TheseGrounds)
	
	MailMessage = Documents.OutgoingEmail.CreateDocument();
	
	RecipientPresentation1 = "";
	
	For Each RecipientData In ArrayOfMailingRecipients Do
		
		If AlreadyPoisonedAtThisAddress(RecipientData, AddresseesAddresses) Then
			Continue;
		EndIf;
		
		If NewsletterIsPersonalized Then
			TabularSection = MailMessage.EmailRecipients;
		Else
		
			TabularSection = ?(TypeOf(RecipientData.Recipient) = Type("CatalogRef.Partners") Or (Not Data.SendToCustomer), 
			                   MailMessage.EmailRecipients,
			                   MailMessage.CCRecipients);
		
		EndIf;
		
		RecipientPresentation1 = RecipientData.RecipientPresentation1;
		
		If CommonClientServer.EmailAddressMeetsRequirements(RecipientData.ContactInformation) Then
			AddEmailRecipient(TabularSection, RecipientData);
		EndIf;
		
	EndDo;
		
	If MailMessage.CCRecipients.Count() = 0 And MailMessage.EmailRecipients.Count() = 0 Then
		Return;
	EndIf;
	
	MailMessage.Author                    = Users.CurrentUser();
	MailMessage.EmployeeResponsible            = Data.EmployeeResponsible;
	MailMessage.Date                     = CurrentSessionDate();
	MailMessage.Importance                 = Enums.InteractionImportanceOptions.Ordinary;
	MailMessage.Encoding                = "UTF-8";
	MailMessage.Account            = Data.Account;
	MailMessage.SenderPresentation = InteractionsClientServer.GetAddresseePresentation(Data.AccountUserName,
	                                                                                           Data.AccountEmailAddress,
	                                                                                           "");
	
	MailMessage.EmailStatus = Enums.OutgoingEmailStatuses.Outgoing;
	MailMessage.Subject                    = Data.Subject;
	MailMessage.TextType               = ?(Data.EmailTextType = Enums.EmailEditingMethods.HTML, 
	                                   Enums.EmailTextTypes.HTML, 
	                                   Enums.EmailTextTypes.PlainText);
	MailMessage.InteractionBasis = Data.Ref;
	MailMessage.RequestDeliveryReceipt  = False;
	MailMessage.RequestReadReceipt = False;
	MailMessage.DisplaySourceEmailBody = False;
	MailMessage.IncludeOriginalEmailBody   = False;
	MailMessage.DeleteAfterSend = Data.DeleteAfterSend;
	MailMessage.Comment = CommentForNewsletterMessage(Data);
	MailMessage.DateToSendEmail = Data.MailingDate;
	MailMessage.EmailSendingRelevanceDate = Data.UpdateDate;
	MailMessage.HasAttachments             = Data.HasAttachments;

	If MailMessage.TextType = Enums.EmailTextTypes.PlainText Then
		MailMessage.Text = GenerateMessageText(Data.EmailText, RecipientPresentation1, TheseGrounds);
	Else
		MailMessage.HTMLText = GenerateMessageText(Data.HTMLEmailText, RecipientPresentation1, TheseGrounds);
		MailMessage.Text     = Interactions.GetPlainTextFromHTML(MailMessage.HTMLText);
	EndIf;
	
	GenerateRecipientsLists(MailMessage);
	
	MailMessage.Write();
	
	SubjectOf = MessageSubject(Data.Basis, MailMessage.Ref);
	
	Attributes = InformationRegisters.InteractionsFolderSubjects.InteractionAttributes();
	Attributes.SubjectOf                 = SubjectOf;
	Attributes.Reviewed             = True;
	Attributes.CalculateReviewedItems = False;
	
	InformationRegisters.InteractionsFolderSubjects.WriteInteractionFolderSubjects(MailMessage.Ref, Attributes);
	
	ArrayOfCreatedEmails.Add(MailMessage.Ref);
	
EndProcedure

Procedure GenerateRecipientsLists(MailMessage)
	
	MailMessage.EmailRecipientsList       = InteractionsClientServer.GetAddressesListPresentation(MailMessage.EmailRecipients, False);
	MailMessage.CcRecipientsList        = InteractionsClientServer.GetAddressesListPresentation(MailMessage.CCRecipients, False);
	MailMessage.BccRecipientsList = "";
	
EndProcedure

Procedure AddEmailRecipient(TabularSection, Recipient)

	NewRow = TabularSection.Add();
	NewRow.Address         = Recipient.ContactInformation;
	NewRow.Presentation = Recipient.RecipientPresentation1;
	NewRow.Contact       = Recipient.Recipient;
	
EndProcedure

Function MessageSubject(MailingListBasis, Message)

	If ValueIsFilled(MailingListBasis) And InteractionsClientServer.IsSubject(MailingListBasis) Then
		Return MailingListBasis;
	Else
		Return Message;
	EndIf;

EndFunction 

Procedure CreateSMSForDistribution(Data, SelectionOfMailingRecipients, ArrayOfCreatedInteractions, TheseGrounds)
	
	NewsletterIsPersonalized = NewsletterIsPersonalized(Data);
	AddresseesAddresses = New Map;
	ArrayOfMailingRecipients = New Array;
	
	While SelectionOfMailingRecipients.Next() Do
		
		SampleRecipient = SelectionOfMailingRecipients.Select(QueryResultIteration.ByGroups);
		While SampleRecipient.Next() Do
			
			If NewsletterIsPersonalized Then
				ArrayOfMailingRecipients.Clear();
			EndIf;
		
			DetailsSelection = SampleRecipient.Select();
			While DetailsSelection.Next() Do
				
				ArrayOfMailingRecipients.Add(DestinationDataForSelection(DetailsSelection));
				
			EndDo;
			
			If NewsletterIsPersonalized Then
				CreateSMSForMailingRecipients(Data, ArrayOfMailingRecipients, AddresseesAddresses, ArrayOfCreatedInteractions, TheseGrounds);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	If Not NewsletterIsPersonalized Then
		CreateSMSForMailingRecipients(Data, ArrayOfMailingRecipients, AddresseesAddresses, ArrayOfCreatedInteractions, TheseGrounds);
	EndIf;
	
EndProcedure

Procedure CreateSMSForMailingRecipients(Data, ArrayOfMailingRecipients, AddresseesAddresses, ArrayOfCreatedInteractions, TheseGrounds)
	
	DocumentMessageSMS = Documents.SMSMessage.CreateDocument();
	RecipientPresentation1 = "";

	For Each MailingAddress In ArrayOfMailingRecipients Do
		
		PreparePhoneNumber(MailingAddress.FieldValues,
		                         MailingAddress.ContactInformationPresentation,
		                         MailingAddress.ContactInformation);
		
		If IsBlankString(MailingAddress.ContactInformation) Then
			Continue;
		EndIf;
		
		If AlreadyPoisonedAtThisAddress(MailingAddress, AddresseesAddresses) Then
			Continue;
		EndIf;
		
		RecipientPresentation1 = MailingAddress.RecipientPresentation1;
		
		AddSMSRecipient(DocumentMessageSMS, MailingAddress);
	
	EndDo;
	
	If DocumentMessageSMS.Recipients.Count() = 0 Then
		Return;
	EndIf;
	
	FillInDetailsOfDocumentMessageSMS(Data, DocumentMessageSMS);
	DocumentMessageSMS.MessageText = GenerateMessageText(Data.SMSMessageText, RecipientPresentation1, TheseGrounds);

	RecordDocumentMessageSMS(DocumentMessageSMS, Data.Basis);
	ArrayOfCreatedInteractions.Add(DocumentMessageSMS.Ref);
	
EndProcedure

Procedure RecordDocumentMessageSMS(DocumentMessageSMS, Basis)

	Interactions.SetStateOutgoingDocumentSMSMessage(DocumentMessageSMS);
	
	DocumentMessageSMS.Write();
	
	SubjectOf = MessageSubject(Basis, DocumentMessageSMS.Ref);
	
	Attributes = InformationRegisters.InteractionsFolderSubjects.InteractionAttributes();
	Attributes.SubjectOf                 = SubjectOf;
	Attributes.Reviewed             = True;
	Attributes.CalculateReviewedItems = False;
	
	InformationRegisters.InteractionsFolderSubjects.WriteInteractionFolderSubjects(DocumentMessageSMS.Ref, Attributes);

EndProcedure

Procedure AddSMSRecipient(DocumentMessageSMS, AddresseeData)
	
	NewRow = DocumentMessageSMS.Recipients.Add();
	NewRow.Contact               = AddresseeData.Recipient;
	NewRow.ContactPresentation = AddresseeData.RecipientPresentation1;
	NewRow.HowToContact          = AddresseeData.ContactInformationPresentation;
	NewRow.SendingNumber      = AddresseeData.ContactInformation;
	NewRow.MessageState    = Enums.SMSMessagesState.Outgoing;

EndProcedure

Procedure PreparePhoneNumber(FieldValues, Presentation, PhoneNumber)

	XMLFieldValues = ContactsManager.ContactInformationToXML(FieldValues,
	                                                                            Presentation,
	                                                                            Enums.ContactInformationTypes.Phone);
	
	FieldsStructure = ContactsManager.InfoAboutPhone(XMLFieldValues);
	
	CountryCode     = ?(FieldsStructure.Property("CountryCode"), FieldsStructure.CountryCode, "");
	CityCode     = ?(FieldsStructure.Property("CityCode"), FieldsStructure.CityCode, "");
	PhoneNumber = ?(FieldsStructure.Property("PhoneNumber"), FieldsStructure.PhoneNumber, "");
	
	// By field values
	If Not IsBlankString(CountryCode) And Not IsBlankString(CityCode) And Not IsBlankString(PhoneNumber) Then
		If CountryCode = "7" Or CountryCode = "8" Then
			CountryCode = "+7";
		EndIf;
		PhoneNumberToSend = CountryCode + CityCode + PhoneNumber;
		
		If PhoneNumberMeetsRequirementsForSendingSMS(PhoneNumberToSend) Then
			PhoneNumber = PhoneNumberToSend;
		Return;
		
	EndIf;

	EndIf;
	
	// By phone number
	If Not IsBlankString(PhoneNumber) Then
		
		PhoneNumberToSend = PhoneNumber;
		If StrLen(PhoneNumberToSend) = 10 Then
			PhoneNumberToSend = "+7" + PhoneNumberToSend;
		ElsIf StrLen(PhoneNumberToSend) = 11 
				And Left(PhoneNumberToSend, 1) = "7" Or Left(PhoneNumberToSend, 1) = "8" Then
				PhoneNumberToSend = "+7" + Right(PhoneNumberToSend, 10);
		EndIf;
			
		If PhoneNumberMeetsRequirementsForSendingSMS(PhoneNumberToSend) Then
			PhoneNumber = PhoneNumberToSend;
			Return;
		EndIf;
		
	EndIf;
	
	If Not IsBlankString(Presentation) Then
		
		// By submission in XXXXXXXXXXXXX format
		PhoneNumberToSend = Presentation;
		If StrLen(PhoneNumberToSend) = 10 Then
			PhoneNumberToSend = "+7" + PhoneNumberToSend;
		ElsIf StrLen(PhoneNumberToSend) = 11 
				And Left(PhoneNumberToSend, 1) = "7" Or Left(PhoneNumberToSend, 1) = "8" Then
				PhoneNumberToSend = "+7" + Right(PhoneNumberToSend, 10);
		EndIf;
			
		If PhoneNumberMeetsRequirementsForSendingSMS(PhoneNumberToSend) Then
			PhoneNumber = PhoneNumberToSend;
			Return;
		EndIf;
		
		// By representation in the format +X(XXX)XXXXXXX
		FieldsStructure = FieldStructureByPhonePresentation(Presentation);
		CountryCode     = ?(FieldsStructure.Property("CountryCode"), FieldsStructure.CountryCode, "");
		CityCode     = ?(FieldsStructure.Property("CityCode"), FieldsStructure.CityCode, "");
		PhoneNumber = ?(FieldsStructure.Property("PhoneNumber"), FieldsStructure.PhoneNumber, "");
		
		If Not IsBlankString(CountryCode) And Not IsBlankString(CityCode) And Not IsBlankString(PhoneNumber) Then
			
			If CountryCode = "7" Or CountryCode = "8" Then
				CountryCode = "+7";
			EndIf;
			PhoneNumberToSend = CountryCode + CityCode + PhoneNumber;
			
			If PhoneNumberMeetsRequirementsForSendingSMS(PhoneNumberToSend) Then
				PhoneNumber = PhoneNumberToSend;
				Return;
			EndIf;
			
		EndIf;
	
	EndIf;
	
	PhoneNumber = "";

EndProcedure

// Forms the structure of contact information fields of the Phone or mobile Phone type based on the phone representation.
//
// Parameters:
//  Presentation  - String - string information with the phone number.
//
// Returns:
//   Structure   - the formed structure.
//
Function FieldStructureByPhonePresentation(Presentation)
	
	CurrRow = TrimAll(Presentation);
	
	// Let's cut out an extension number with a comment.
	PosAdd = StrFind(Upper(CurrRow), "EXT.");
	If PosAdd <> 0 Then
		ExtensionWithComment = TrimAll(Mid(CurrRow, PosAdd+4));
		
		CurrRow = TrimAll(Left(CurrRow, PosAdd-1));
		
		If StrEndsWith(CurrRow, ",") Then
			CurrRow = Left(CurrRow, StrLen(CurrRow)-1);
		EndIf;
		
		PosAdd = StrFind(Upper(ExtensionWithComment), ", ");
		
		If PosAdd <> 0 Then
			PhoneExtension = TrimAll(Left(ExtensionWithComment, PosAdd-1));
			Comment = TrimAll(Mid(ExtensionWithComment, PosAdd+2));
		Else
			PhoneExtension = ExtensionWithComment;
		EndIf;
		
	EndIf;
	
	// cut out the area code
	Pos = StrFind(CurrRow, "(");
	If Pos <> 0 Then
		CountryCode = TrimAll(Left(CurrRow, Pos-1));
		
		CurrRow = TrimAll(Mid(CurrRow, Pos+1));
		Pos = StrFind(CurrRow, ")");
		
		If Pos <> 0 Then
			CityCode = TrimAll(Left(CurrRow, Pos-1));
			CurrRow = TrimAll(Mid(CurrRow, Pos+1));
		EndIf;
	EndIf;
	
	Pos = StrFind(CurrRow, ", ");
	// If there is no extension number, we are guided by the phone number and comment.
	If PosAdd = 0 And Pos <> 0 Then
		// cut out the comment
		PhoneNumber = TrimAll(Left(CurrRow, Pos-1));
		Comment = TrimAll(Mid(CurrRow, Pos+2));
	Else
		// all that's left is the number
		PhoneNumber = CurrRow;
	EndIf;
	
	Result = New Structure;
	Result.Insert("CountryCode", CountryCode);
	Result.Insert("CityCode", CityCode);
	Result.Insert("PhoneNumber", PhoneNumber);
	Result.Insert("PhoneExtension", PhoneExtension);
	Result.Insert("Comment", Comment);
	
	Return Result;
	
EndFunction

Function PhoneNumberMeetsRequirementsForSendingSMS(PhoneNumberToSend)

	If StrLen(PhoneNumberToSend) <> 12 Then
		Return False;
	EndIf;
	
	If Left(PhoneNumberToSend, 2) <> "+7" Then
		Return False;
	EndIf;
	
	If Not StringFunctionsClientServer.OnlyNumbersInString(Right(PhoneNumberToSend, 10)) Then
		Return False;
	EndIf;
	
	Return True;

EndFunction 

Function GenerateMessageText(MessageTemplate, RecipientPresentation1, TheseGrounds)
	
	MessageText = MessageTemplate;
	
	MessageText = StrReplace(MessageText, "[AddresseePresentation]", RecipientPresentation1);
	MessageText = StrReplace(MessageText, "[CurrentDate]", Format(CurrentSessionDate(), "DLF=D"));
	
	If TheseGrounds <> Undefined Then
		If TypeOf(TheseGrounds.Ref) = Type("DocumentRef.PollPurpose") Then
			MessageText = StrReplace(MessageText, "[SurveyStartDate]", Format(TheseGrounds.StartDate, "DLF=D"));
			MessageText = StrReplace(MessageText, "[SurveyEndDate]", Format(TheseGrounds.EndDate, "DLF=D"));
			MessageText = StrReplace(MessageText, "[SurveyDescription]", TheseGrounds.Description);
		EndIf;
	EndIf;
	
	Return MessageText;
	
EndFunction

Procedure FillInDetailsOfDocumentMessageSMS(Data, DocumentMessageSMS)
	
	DocumentMessageSMS.Date                     = CurrentSessionDate();
	DocumentMessageSMS.Author                    = Users.CurrentUser();
	DocumentMessageSMS.Importance                 = Enums.InteractionImportanceOptions.Ordinary;
	DocumentMessageSMS.EmployeeResponsible            = Data.EmployeeResponsible;
	DocumentMessageSMS.InteractionBasis  = Data.Ref;
	DocumentMessageSMS.Subject                     = Data.Subject;
	DocumentMessageSMS.SendInTransliteration     = Data.SendInTransliteration;
	DocumentMessageSMS.DateToSendEmail       = Data.MailingDate;
	DocumentMessageSMS.EmailSendingRelevanceDate = Data.UpdateDate;
	
	If TypeOf(Data) = Type("Structure") Then
		If Data.Property("Comment") Then
			DocumentMessageSMS.Comment = Data.Comment;
		EndIf;
	Else
		DocumentMessageSMS.Comment = CommentForNewsletterMessage(Data);
	EndIf;
	
EndProcedure

Function CommentForNewsletterMessage(Data)

	CommentText1 = NStr("vi = 'Đã tạo để gửi ""%1"" số %2 ngày %3.';
						|ru = 'Создано по рассылке ""%1"" № %2 от %3.';
						|en = 'Created for mailout ""%1"" No. %2 dated %3.'; fa = 'Created for mailout ""%1"" No. %2 dated %3.';
						|it = 'Creato in base alla email massive ""%1"" № %2 di %3.';
						|pl = 'Utworzono według wysyłki ""%1"" № %2 od %3.';
						|tr = '%3''ten ""%1"" № %2 dağıtımı tarafından oluşturuldu.'");
	CommentText1 = StringFunctionsClientServer.SubstituteParametersToString(Data.Subject,
	                                                                           Data.Number,
	                                                                           Data.Date);
	
	Return CommentText1
	
EndFunction

Function NewsletterIsPersonalized(Data)
	
	MessageTemplate = MailingMessageTemplate(Data);
	
	Return StrFind(MessageTemplate, "[AddresseePresentation]") > 0;
	
EndFunction

Function MailingMessageTemplate(Data)

	MessageTemplate = "";
	
	If Data.DesignedForEmails Then
		
		If Data.EmailTextType = Enums.EmailEditingMethods.HTML Then
			MessageTemplate = Data.HTMLEmailText;
		Else
			MessageTemplate = Data.EmailText;
		EndIf;
		
	Else
		MessageTemplate = Data.SMSMessageText;
	EndIf;
	
	Return MessageTemplate;

EndFunction 

#EndRegion

#Region Other

Function TablesAreDifferent(Table1, Table2)

	If Table1.Count() <> Table2.Count() Then
		Return True;
	EndIf;
	
	If Table1.Columns.Count() <> Table2.Columns.Count() Then
		Return True
	EndIf;
	
	For IndLine = 0 To Table1.Count() - 1 Do
		For IndColumn = 0 To Table1.Columns.Count() - 1 Do
		
			If Table1[IndLine][IndColumn] <> Table2[IndLine][IndColumn] Then
				Return True;
			EndIf;
				
		EndDo;
	EndDo;
	
	Return False;

EndFunction

Procedure WritingToQueueByEventType(TypeOfAlertEvent, NotificationSource, Subscriber, DateSent, UpdateDate)
	
	ArrayOfAlertTypes = MailoutsAndNotificationsToCustomersCached.CurrentNotificationKindsByEventType(TypeOfAlertEvent);
	
	For Each NotificationKind In ArrayOfAlertTypes Do
			
			InformationRegisters.EventQueueForNotificationsToCustomers.ExecuteRecordToRegister(NotificationKind,
			                                                                             Subscriber,
			                                                                             NotificationSource,
			                                                                             DateSent,
			                                                                             UpdateDate);
		
	EndDo;
	
EndProcedure

Procedure AddCommaIfNotEmptyText(String)

	String = String + ?(IsBlankString(String), "", ", ");

EndProcedure

Procedure AddSubscribersBySelection(AddressInTempStorage,
	                                  GroupOfMailoutsAndNotifications,
	                                  DesignedForSMSMessage,
	                                  DesignedForEmails) Export
	
	TableOfPartners = GetFromTempStorage(AddressInTempStorage);
	
	If TableOfPartners.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text ="
	|SELECT
	|	TableOfPartners.Partner,
	|	TableOfPartners.ContactDetailsKindForMails,
	|	TableOfPartners.CIKindPhone
	|INTO SelectedPartners
	|FROM
	|	&TableOfPartners AS TableOfPartners
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectedPartners.Partner,
	|	SelectedPartners.ContactDetailsKindForMails,
	|	SelectedPartners.CIKindPhone,
	|	ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.Ref, VALUE(Catalog.SubscriptionsToCustomerMailoutsAndNotifications.EmptyRef)) AS Subscription,
	|	ISNULL(SubscriptionsToCustomerMailoutsAndNotifications.SubscriptionIsValid, FALSE) AS SubscriptionIsValid
	|FROM
	|	SelectedPartners AS SelectedPartners
	|		LEFT JOIN Catalog.SubscriptionsToCustomerMailoutsAndNotifications AS SubscriptionsToCustomerMailoutsAndNotifications
	|		ON SelectedPartners.Partner = SubscriptionsToCustomerMailoutsAndNotifications.Owner
	|			AND (SubscriptionsToCustomerMailoutsAndNotifications.GroupOfMailoutsAndNotifications = &GroupOfMailoutsAndNotifications)
	|			AND (NOT SubscriptionsToCustomerMailoutsAndNotifications.DeletionMark)";
	
	Query.SetParameter("TableOfPartners", TableOfPartners);
	Query.SetParameter("GroupOfMailoutsAndNotifications", GroupOfMailoutsAndNotifications);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		If Selection.Subscription.IsEmpty() Then
			
			ObjectSubscription = Catalogs.SubscriptionsToCustomerMailoutsAndNotifications.CreateItem();
			ObjectSubscription.Owner = Selection.Partner;
			ObjectSubscription.GroupOfMailoutsAndNotifications = GroupOfMailoutsAndNotifications;
			ObjectSubscription.SendToCustomer = True;
			
			If DesignedForSMSMessage Then
				ObjectSubscription.PartnerContactDetailsKindForSMSMessage = Selection.CIKindPhone;
			EndIf;
			If DesignedForEmails Then
				ObjectSubscription.PartnerContactDetailsKindForMails = Selection.ContactDetailsKindForMails;
			EndIf;
			
		Else
			
			If Selection.SubscriptionIsValid Then
				Continue
			EndIf;
			
			ObjectSubscription = Selection.Subscription.GetObject();
			
		EndIf;
		
		ObjectSubscription.SubscriptionIsValid  = True;
		ObjectSubscription.Write();
		
	EndDo;

EndProcedure

Function TextUnion()
	
	Return "
		|
		|UNION
		|";
	
EndFunction

Function PerformLogEntry(RecordText ,LevelOfImportance)

	WriteLogEvent(
		NStr("vi = 'Bản tin và thông báo cho khách hàng';
			|ru = 'Рассылки и оповещения клиентам';
			|en = 'Mailouts and notifications to customers'; fa = 'ارسال انبوه و اعلان‌ها به مشتریان';
			|it = 'Email massivo e avvisi ai clienti';
			|pl = 'Subskrypcje i powiadomienia dla klientów';
			|tr = 'Müşteriye bülten ve bildirim'", CommonClientServer.DefaultLanguageCode()), 
		LevelOfImportance, , ,
		RecordText);

EndFunction 

#EndRegion

#EndRegion

