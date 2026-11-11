
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If PrintFormOpeningIsRequired Then
		Return;
	EndIf;
	
	If ValueIsFilled(Object.Basis) Then
		If Not AccessRight("Read", Metadata.FindByType(TypeOf(Object.Basis))) Then
			Items.BaseGroup_.Visible = False;
		EndIf;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		
		SetElementFormTitle(True);
		SelfServiceServer.SelfServiceFormsWhenCreatedOnServer(ThisForm, Cancel);
		If Cancel Then
			Return;
		EndIf;
		
	EndIf;
	
	Items.PartnersAndContactPersons.RowFilter = New FixedStructure("Partner", Object.Partner);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	If CurrentObject.Status <> Enums.CustomerComplaintStatuses.Registered1 Then
		PrintFormOpeningIsRequired = True;
		Return;
	EndIf;
	
	FillAttachments();
	SetElementFormTitle(False);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	SetPrivilegedMode(True);
	
	MailoutsAndNotificationsToCustomers.DeleteAttachments(DeletedAttachments);
	MailoutsAndNotificationsToCustomers.SaveAttachments(CurrentObject.Ref, Attachments, UUID);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	For Each MemberString In Object.PartnersAndContactPersons Do
	
		If MemberString.Partner = Object.Partner And Not ValueIsFilled(MemberString.ContactPerson) Then
			
			FieldName = CommonClientServer.PathToTabularSection("Object.PartnersAndContactPersons",
			                                                           MemberString.LineNumber,
			                                                           "ContactPerson");
			
			CommonClientServer.MessageToUser(
			       NStr("vi = 'Cần chỉ ra người liên hệ';
						|ru = 'Необходимо указать контактное лицо';
						|en = 'Specify a contact person'; fa = 'Specify a contact person';
						|it = 'È necessario specificare una persona di riferimento';
						|pl = 'Należy wskazać osobę do kontaktu';
						|tr = 'İrtibat kişisi belirtilmeli'"),
			       Object.Ref,
			       FieldName,
			       ,
			       Cancel);
		EndIf;
	
	EndDo;
	
	If Not Cancel Then
		
		MailoutsAndNotificationsToCustomersClient.PlaceAttachmentsInTemporaryStorage(Attachments);
		
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
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If PrintFormOpeningIsRequired Then
		
		Cancel = True;
		SelfServiceClient.PrintCustomerClaim(Object.Ref);
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
		
	SetElementFormTitle(False);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BasisClick(Item, StandardProcessing)
	
	If ValueIsFilled(Object.Basis) Then
		StandardProcessing = False;
		ShowValue(, Object.Basis);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPartnersAndContactPersons

&AtClient
Procedure PartnersAndContactPersonsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If NewRow Then
		CurrentData.Partner = Object.Partner;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttachments

&AtClient
Procedure AttachmentsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	MailoutsAndNotificationsToCustomersClient.AddAttachmentExecute(ThisForm);
	
EndProcedure

&AtClient
Procedure AttachmentsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	OpenAttachmentExecute();
	
EndProcedure

&AtClient
Procedure AttachmentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenAttachmentExecute();
	
EndProcedure

&AtClient
Procedure AttachmentsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
	MailoutsAndNotificationsToCustomersClient.HandleDraggingAttachment(Attachments, DragParameters);
	
EndProcedure

&AtClient
Procedure AttachmentsBeforeDeleteRow(Item, Cancel)
	
	DeleteAttachmentExecute();
	Cancel = True;

EndProcedure

&AtClient
Procedure AttachmentsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddAttachmentExecute()
	
	MailoutsAndNotificationsToCustomersClient.AddAttachmentExecute(ThisForm);
	
EndProcedure

&AtClient
Procedure OpenAttachmentExecute()
	
	MailoutsAndNotificationsToCustomersClient.OpenAttachmentExecute(ThisForm);
	
EndProcedure

&AtClient
Procedure DeleteAttachmentExecute()

	MailoutsAndNotificationsToCustomersClient.MoveAttachmentToDeleted(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetElementFormTitle(IsNewObject)

	If IsNewObject Then
		
		Title = NStr("vi = 'Khiếu nại (tạo mới)';
					|ru = 'Претензия (создание)';
					|en = 'Complaint (Create)'; fa = 'Complaint (Create)';
					|it = 'Reclamo (generazione)';
					|pl = 'Roszczenie (tworzenie)';
					|tr = 'Şikayet (oluşturma)'");
		
	Else
		
		Title = Object.Description + " (" + NStr("vi = 'khiếu nại';
												|ru = 'претензия';
												|en = 'complaint'; fa = 'complaint';
												|it = 'reclamo';
												|pl = 'roszczenie';
												|tr = 'şikayet'") + ")";
		
	EndIf;

EndProcedure

&AtServer
Procedure FillAttachments()

	Attachments.Clear();
	AttachmentsTable = SelfServiceServer.MetadataObjectAttachments(Object.Ref, True);
	For Each AttachmentsTableRow In AttachmentsTable Do
		NewRow = Attachments.Add();
		FillPropertyValues(NewRow, AttachmentsTableRow);
		NewRow.Placement = 0;
	EndDo;

EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
