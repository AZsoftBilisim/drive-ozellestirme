////////////////////////////////////////////////////////////////////////////////
// Subsystem "Mailing lists and notifications to clients".
//
////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
//  It contains general client procedures and functions when working with the functionality
//  of mailing lists and customer alerts.
//

#Region Internal

// Interactively add an email attachment.
//
// Parameters:
//  Form  - ClientApplicationForm - the form in which the attachment is added.
//
Procedure AddAttachmentExecute(Form) Export
	
	#If Not WebClient Then
		
		Dialog = New FileDialog(FileDialogMode.Open);
		Dialog.Multiselect = True;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Form", Form);
		
		FileSelectionEnd = New CallbackDescription("FileSelectionEnd", ThisObject, AdditionalParameters);
		
		Dialog.Show(FileSelectionEnd);
		
	#Else

		DescriptionAndEndOfPremises = New CallbackDescription("AddAttachmentExecuteCompletion",
		                                                                ThisObject, New Structure("Form", Form));
		BeginPutFile(DescriptionAndEndOfPremises, "", "", True, Form.UUID);
		Return;
		
	#EndIf
	
EndProcedure

Procedure FileSelectionEnd(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	Form = AdditionalParameters.Form;
	Attachments = Form.Attachments; // ValueTable
	
	For Each SelectedFile In SelectedFiles Do
		
		Form.Modified = True;
		
		NewRow = Attachments.Add(); // See AttachmentsTableRow
		NewRow.Placement = 2;
		NewRow.FileNameOnComputer = SelectedFile;
		
		FileName = FileNameWithoutDirectory(SelectedFile);
		NewRow.FileName = FileName;
		
		Extension                      = CommonClientServer.GetFileNameExtension(FileName);
		NewRow.PictureIndex      = FilesOperationsInternalClientServer.IndexOfFileIcon(Extension);
		File                            = New File(SelectedFile);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("TSRow", NewRow);
		NotificationAfterReceivingSize = New CallbackDescription("GettingFileSizeEnds", ThisObject, AdditionalParameters);
		File.BeginGettingSize(NotificationAfterReceivingSize);
		
	EndDo;
	
EndProcedure

Procedure GettingFileSizeEnds(Size, AdditionalParameters) Export
	
	If Size = Undefined Then
		Return;
	EndIf;
	
	TSRow = AdditionalParameters.TSRow; // See AttachmentsTableRow
	
	TSRow.Size              = Size;
	TSRow.SizePresentation = InteractionsClientServer.GetFileSizeStringPresentation(TSRow.Size);
	
EndProcedure

Procedure AddAttachmentExecuteCompletion(Result, Address, SelectedFile, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	Attachments = Form.Attachments; // ValueTable
	
	If Not Result Then
		Return;
	EndIf;
	
	NewRow = Attachments.Add(); // See AttachmentsTableRow
	NewRow.Placement = 4;
	NewRow.FileNameOnComputer = Address;
	NewRow.FileName = SelectedFile;
	
	Extension = CommonClientServer.GetFileNameExtension(SelectedFile);
	NewRow.PictureIndex = FilesOperationsInternalClientServer.IndexOfFileIcon(Extension);
	
	Form.Modified = True;
	Form.RefreshDataRepresentation();
	
EndProcedure

// Opens a file located in the Attachment table.
//
// Parameters:
//  Form  - ClientApplicationForm - The form in which the action is performed.
//
Procedure OpenAttachmentExecute(Form) Export
	
	curData = Form.Items.Attachments.CurrentData; // See AttachmentsTableRow
	If curData = Undefined Then
		Return;
	EndIf;
	
	If (curData.Placement = 0) Then
		
		FilesOperationsClient.OpenFile(
			FilesOperationsClient.FileData(curData.Ref, Form.UUID), False);
		
	ElsIf curData.Placement = 2 Then
		
		PathToFile = curData.FileNameOnComputer;
		#If Not WebClient Then
			Notification = New CallbackDescription("ApplicationLaunchComplete", ThisObject);
			CommonClient.OpenFileInViewer("" + PathToFile + "", Notification);
		#Else
			GetFile(PathToFile, curData.FileName, True);
		#EndIf
		
	ElsIf curData.Placement = 4 Then
		
		PathToFile = curData.FileNameOnComputer;
		#If Not WebClient Then
			GetFile(PathToFile, curData.FileName, False);
		#Else
			GetFile(PathToFile, curData.FileName, True);
		#EndIf
		
	EndIf;
	
EndProcedure

Procedure ApplicationLaunchComplete(Attached, AdditionalParameters) Export

	If Attached = Undefined Then
		Return;
	EndIf;

EndProcedure

// Places files located in the Attachments table in temporary storage.
//
// Parameters:
//  Attachments  - ValueTable - table containing attachments:
//    * Placement         - Number -
//    * FileNameOnComputer - String
//
Procedure PlaceAttachmentsInTemporaryStorage(Attachments) Export
	
	#If Not WebClient Then
	For Each AttachmentsTableRow In Attachments Do
		If AttachmentsTableRow.Placement = 2 Then 
			Data = New BinaryData(AttachmentsTableRow.FileNameOnComputer);
			AttachmentsTableRow.FileNameOnComputer = PutToTempStorage(Data, "");
			AttachmentsTableRow.Placement = 4;
		EndIf;
	EndDo;
	#EndIf
	
EndProcedure

// Handles dragging one or more files to the attachment table.
//
// Parameters:
//  Attachments  - ValueTable - table containing attachments:
//     * Placement         - Number -
//     * FileNameOnComputer - String -
//     * PictureIndex       - Number
//  DragParameters  - DragParameters - parameters for the drag and drop operation.
//
Procedure HandleDraggingAttachment(Attachments, DragParameters) Export
	
#If Not WebClient Then
    
    // The preprocessor instruction is needed so that the platform configuration check
    // does not find synchronous methods of working with files. In the web client, this procedure is still
    // not called due to the peculiarities of dragging files in the browser.
    
	FileNamesArray = New Array;
	
	If TypeOf(DragParameters.Value) = Type("File")
		And DragParameters.Value.IsFile() = True Then
		
		FileNamesArray.Add(DragParameters.Value.FullName);
		
	ElsIf TypeOf(DragParameters.Value) = Type("Array") Then
		
		If DragParameters.Value.Count() >= 1
			And TypeOf(DragParameters.Value[0]) = Type("File") Then
			
			For Each ReceivedFile1 In DragParameters.Value Do
				If TypeOf(ReceivedFile1) = Type("File") And ReceivedFile1.IsFile() Then
					FileNamesArray.Add(ReceivedFile1.FullName);
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	For Each SelectedFile In FileNamesArray Do
			
			NewRow = Attachments.Add();
			NewRow.Placement = 2;
			NewRow.FileNameOnComputer = SelectedFile;
			
			FileName = FileNameWithoutDirectory(SelectedFile);
			NewRow.FileName = FileName;
			
			Extension                      = CommonClientServer.GetFileNameExtension(FileName);
			NewRow.PictureIndex      = FilesOperationsInternalClientServer.IndexOfFileIcon(Extension);
			File                            = New File(SelectedFile);
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("TSRow", NewRow);
			NotificationAfterReceivingSize = New CallbackDescription("GettingFileSizeEnds", ThisObject, AdditionalParameters);
			File.BeginGettingSize(NotificationAfterReceivingSize);
	
	EndDo;
	
#EndIf

EndProcedure

// Deletes the file from the Attachment table and moves it to the attachment array for deletion.
//
// Parameters:
//  Form  - ClientApplicationForm - The form in which the action is performed.
//
Procedure MoveAttachmentToDeleted(Form) Export

	AttachmentsFormTable = Form.Items.Attachments; // FormTable
	Attachments_Data       = Form.Attachments; // FormDataCollection
	DeletedAttachments = Form.DeletedAttachments; // ValueList - 
	CurrentData = AttachmentsFormTable.CurrentData; // FormDataCollectionItem 
	If (CurrentData <> Undefined)  Then
		If CurrentData.Placement = 0 Then
			DeletedAttachments.Add(CurrentData.Ref);
		EndIf;
		IndexOf = Attachments_Data.IndexOf(CurrentData);
		Form.Attachments.Delete(IndexOf);
		Form.RefreshDataRepresentation();
		Form.Modified = True;
	EndIf;

EndProcedure

// Constructor function that describes the structure corresponding to the row in the Attachment table. 
// 
// Returns:
//  Structure - Contains:
//    * Placement - Number -
//    * Ref       - CatalogRef.OutgoingEmailAttachedFiles -
//    * FileName             - String - 
//    * FileNameOnComputer - String - 
//    * Size               - Number - 
// 	
Function AttachmentsTableRow() Export
	
	AttachmentTableRowData = New Structure;
	AttachmentTableRowData.Insert("Placement");
	AttachmentTableRowData.Insert("Ref");
	AttachmentTableRowData.Insert("FileName");
	AttachmentTableRowData.Insert("FileNameOnComputer");
	AttachmentTableRowData.Insert("Size");
	
	Return AttachmentTableRowData;
	
EndFunction

// Opens the subscription form for the subscriber and the mailing list and notification group.
//
// Parameters:
//  Subscriber                  - CatalogRef.Partners - the subscriber for which you want to access your subscription.
//  GroupOfMailoutsAndNotifications  - CatalogRef.GroupsOfMailoutsAndNotifications - the group for which you want to access your subscription.
//  Form                      - ClientApplicationForm - The form in which the action is performed.
//
Procedure OpenSubscriptionForm(Subscriber, GroupOfMailoutsAndNotifications, Form) Export
	
	Subscription = CustomerMailoutsAndNotificationsServerCall.SubscriptionForSubscriber(Subscriber, GroupOfMailoutsAndNotifications);
	EditSubscription(Subscription, Subscriber, GroupOfMailoutsAndNotifications, Form);
	
EndProcedure

// Opens the subscription form.
//
// Parameters:
//  Subscription                   - CatalogRef.SubscriptionsToCustomerMailoutsAndNotifications - subscription to open.
//  Subscriber                  - CatalogRef.Partners - subscriber.
//  GroupOfMailoutsAndNotifications  - CatalogRef.GroupsOfMailoutsAndNotifications - group.
//  Form                      - ClientApplicationForm - The form in which the action is performed.
//  Valid                  - Boolean - indicates that the subscription is valid.
//
Procedure EditSubscription(Subscription, Subscriber, GroupOfMailoutsAndNotifications, Form, Valid = True) Export

	If Subscription.IsEmpty() Then
		
		If CommonClientServer.HasAttributeOrObjectProperty(Form, "EditRight")
			And Not Form.EditRight Then
			Return;
		EndIf;
		
		FillingValues = New Structure;
		FillingValues.Insert("Owner", Subscriber);
		FillingValues.Insert("GroupOfMailoutsAndNotifications", GroupOfMailoutsAndNotifications);
		FillingValues.Insert("SubscriptionIsValid", Valid);
		FormParameters = New Structure("FillingValues", FillingValues);
		
	Else
		
		FormParameters = New Structure("Key", Subscription);
		
	EndIf;
	
	OpenForm("Catalog.SubscriptionsToCustomerMailoutsAndNotifications.ObjectForm",
	             FormParameters,
	             Form);

EndProcedure

// Generates parameters of the selection partner selection form.
//
// Parameters:
//  Form  - ClientApplicationForm - the form from which the selection is called.
//
// Returns:
//   Structure   - formed parameters of the selection form.
//
Function SelectionFormParametersBySelection(Form) Export

	PickFormHeader = NStr("vi = 'Lựa chọn thuê bao đối với nhóm gửi và thông báo';
							|ru = 'Подбор подписчиков для группы рассылок и оповещений';
							|en = 'Pick subscribers for the group of mailouts and notifications'; fa = 'Pick subscribers for the group of mailouts and notifications';
							|it = 'Selezione degli abbonati per gruppo di email massive e avvisi';
							|pl = 'Dobór subskrybentów do grupy wysyłek i powiadomień';
							|tr = 'Dağıtım ve bildirim grubu için abone seçimi'");
	TitleOfTransferSelectionFormButton = NStr("vi = 'Chuyển đến bản đăng ký';
												|ru = 'Перенести в подписку';
												|en = 'Move to subscription'; fa = 'Move to subscription';
												|it = 'Trasferire all''abbonamento';
												|pl = 'Przenieść do subskrypcji';
												|tr = 'Aboneliğe transfer'");
	
	FormParameters = New Structure;
	FormParameters.Insert("Title",                               PickFormHeader);
	FormParameters.Insert("TransferButtonTitle",                TitleOfTransferSelectionFormButton);
	FormParameters.Insert("UUID",                 Form.UUID);
	FormParameters.Insert("DesignedForSMSMessage",                     Form.DesignedForSMSMessage);
	FormParameters.Insert("DesignedForEmails",        Form.DesignedForEmails);
	FormParameters.Insert("PartnerSContactDetailsKindForEmails", Form.PartnerSContactDetailsKindForEmails);
	FormParameters.Insert("PartnerSContactDetailsKindForSMSMessage",   Form.PartnerSContactDetailsKindForSMSMessage);
	
	Return FormParameters;

EndFunction

// Handler for the configure notification subscription command from the object.
//
// Parameters:
//  Partner     - CatalogRef.Partners - the partner that the subscription will be configured for.
//  EventType  - Array, EnumRef.NotificationEventTypes - types of events to subscribe to.
//
Procedure SubscribeToAlertsFromPlace(Partner, EventType) Export

	ArrayOfAvailableNotificationGroups = CustomerMailoutsAndNotificationsServerCall.AvailableNotificationGroupsByEventType(EventType);
	ListOfAvailableNotificationGroups = New ValueList();
	ListOfAvailableNotificationGroups.LoadValues(ArrayOfAvailableNotificationGroups);
	NumberOfAvailableAlertGroups = ArrayOfAvailableNotificationGroups.Count();
	
	If NumberOfAvailableAlertGroups = 1 Then
		
		FillingValues = New Structure();
		FillingValues.Insert("Owner", Partner);
		FillingValues.Insert("GroupOfMailoutsAndNotifications", ArrayOfAvailableNotificationGroups[0]);
		FillingValues.Insert("SubscriptionIsValid", True);
		FormParameters = New Structure();
		FormParameters.Insert("FillingValues", FillingValues);
		
		OpenForm("Catalog.SubscriptionsToCustomerMailoutsAndNotifications.ObjectForm", FormParameters);
		
	ElsIf NumberOfAvailableAlertGroups > 1 Then
		
		FormParameters = New Structure();
		FormParameters.Insert("Subscriber", Partner);
		FormParameters.Insert("GroupsOfMailoutsAndNotifications", ListOfAvailableNotificationGroups);
		
		OpenForm("Catalog.SubscriptionsToCustomerMailoutsAndNotifications.Form.ListFormOfSubscriber", FormParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function FileNameWithoutDirectory(Val FullFileName)
	
	FileName = FullFileName;
	While True Do
		
		Position = Max(StrFind(FileName, "\"), StrFind(FileName, "/"));
		If Position = 0 Then
			Return FileName;
		EndIf;
		
		FileName = Mid(FileName, Position + 1);
		
	EndDo;
	Return FileName;
	
EndFunction

#EndRegion
