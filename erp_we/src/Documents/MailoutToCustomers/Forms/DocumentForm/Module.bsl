
#Region FormEventHandlers

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure


&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Object.Ref.IsEmpty() Then
		OnCreatReadAtServer();
		InitializeComposerServer(Undefined);
	EndIf;
	
	ConfigurationModificationOverridable.OnCreateAtServer(ThisForm, StandardProcessing, Cancel);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnCreatReadAtServer();
	
	If Object.DesignedForEmails Then
		FillAttachments();
	EndIf;
	
	SavedSettingsComposer = CurrentObject.AddresseeFilter.Get();
	InitializeComposerServer(SavedSettingsComposer);
	HeaderTextDestinationFilter(ThisObject);
	
	If Object.AdditionalRecipients.Count() > 0 
		And Object.Status <> Enums.CustomerMailoutStatuses.InProcessing
		And Object.Status <> Enums.CustomerMailoutStatuses.Executed Then
		
		FillInCITablesForAdditionalRecipients();
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	SetPrivilegedMode(True);
	
	ProcessAttachmentsWhenWriting(CurrentObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not Cancel Then
		
		MailoutsAndNotificationsToCustomersClient.PlaceAttachmentsInTemporaryStorage(Attachments);
		
	EndIf;
	
	Object.HasAttachments = (Attachments.Count() <> 0) And Object.DesignedForEmails;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If Object.DesignedForEmails Then
		FillAttachments();
	EndIf;
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment)
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Object.DesignedForEmails And Object.EmailTextType = Enums.EmailEditingMethods.HTML Then
	
		MailoutsAndNotificationsToCustomers.FormattedDocumentInHtml5BeforeWriting(
		          EmailTextFormattedDocument,
		          CurrentObject.HTMLEmailText,
		          CurrentObject.EmailTextType,
		          AttachmentsNamesToIDsMapsTable);
		
		If IsBlankString(CurrentObject.HTMLEmailText) Then
			
			CommonClientServer.MessageToUser(
			           NStr("vi = 'Chưa điền nội dung thư';
							|ru = 'Не заполнен текст письма';
							|en = 'Email text is not filled in'; fa = 'Email text is not filled in';
							|it = 'Non è inserito il testo della lettera';
							|pl = 'Nie wprowadzono tekstu listu';
							|tr = 'Mesaj metni doldurulmadı'"),
			           ,
			           "EmailTextFormattedDocument",
			           ,
			           Cancel);
			
		EndIf;
		
	Else
		
		CurrentObject.HTMLEmailText = "";
		
	EndIf;

	If Cancel Then
		Return;
	EndIf;
	
	CurrentObject.FilterPresentation  = String(SettingsComposer.Settings.Filter);
	CurrentObject.AddresseeFilter       = New ValueStorage(SettingsComposer.GetSettings());
	
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
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DistributionTransportOnChange(Item)
	
	PurposeOfMailingByFlagTransport(ThisForm);
	AvailabilityControl(ThisForm);
	
	If Object.AdditionalRecipients.Count() > 0 Then
		FillInCITablesForAdditionalRecipients();
	EndIf;

EndProcedure

&AtClient
Procedure GroupOfMailoutsAndNotificationsOnChange(Item)
	
	GroupOfMailingsAndNotificationsWhenChangesOccurOnServer();
	
EndProcedure

&AtClient
Procedure EmailTextTypeOnChange(Item)
	
	If EmailTextType = 0 Then
		
		InteractionsClient.PromptOnChangeMessageFormatToPlainText(ThisForm);
		
	Else
		
		EmailTextFormattedDocument.Add(Object.EmailText);
		Object.EmailText     = "";
		Object.EmailTextType = PredefinedValue("Enum.EmailEditingMethods.HTML");
		
		AvailabilityControl(ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SendInTransliterationOnChange(Item)
	
	CharsLeft = InteractionsClientServer.GenerateInfoLabelMessageCharsCount(
	                        Object.SendInTransliteration,
	                        Object.SMSMessageText);
	
EndProcedure

&AtClient
Procedure BasisClick(Item, StandardProcessing)
	
	If ValueIsFilled(Object.Basis) Then
		StandardProcessing = False;
		ShowValue(, Object.Basis);
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsComposerSettingsFilterOnChange(Item)
	
	HeaderTextDestinationFilter(ThisObject);
	
EndProcedure

&AtClient
Procedure SettingsComposerSettingsFilterBeforeRowChange(Item, Cancel)
	
	If BasedOnTheSurvey Then
		If Item.CurrentData <> Undefined 
			And Item.CurrentData.LeftValue = New DataCompositionField("SurveyPurpose") Then
			Cancel = True;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttachments

&AtClient
Procedure AttachmentsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	MailoutsAndNotificationsToCustomersClient.AddAttachmentExecute(ThisForm);
	
EndProcedure

&AtClient
Procedure AttachmentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenAttachmentExecute();
	
EndProcedure

&AtClient
Procedure AttachmentsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
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

&AtClient
Procedure SMSMessageTextOnChange(Item)
	
	CharsLeft      = InteractionsClientServer.GenerateInfoLabelMessageCharsCount(
	                          Object.SendInTransliteration,
	                          Object.SMSMessageText);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttachments

&AtClient
Procedure AdditionalRecipientsContactChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	CurrentData = Items.AdditionalRecipients.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(ValueSelected) = Type("Type") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If ValueSelected = CurrentData.Contact Then
		Return;
	EndIf;
	
	CurrentData.Contact = ValueSelected;
	
	DataForCalculation = New Structure("DesignedForEmails, Contact, AddressesTable");
	DataForCalculation.DesignedForEmails = Object.DesignedForEmails;
	DataForCalculation.Contact = CurrentData.Contact;
	DataForCalculation.AddressesTable = CurrentData.AddressesTable;
	CurrentData.ContactInformation = FillInAddressTable(DataForCalculation);
	
EndProcedure

&AtClient
Procedure AdditionalRecipientsOnActivateCell(Item)
	
	CurrentData = Items.AdditionalRecipients.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Item.CurrentItem.Name = "AdditionalRecipientsContactInformation" Then
		ChoiceList = Items.AdditionalRecipientsContactInformation.ChoiceList;
		ChoiceList.Clear();
		For Each AddressesTableRow In CurrentData.AddressesTable Do
			ChoiceList.Add(AddressesTableRow.Presentation, StringWithView(AddressesTableRow.Presentation, AddressesTableRow.ContactInformationKind));
		EndDo;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function StringWithView(Presentation, CIKind)

	Return Presentation + " (" + String(CIKind) + ")";

EndFunction

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

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
Procedure AddTheDestinationViewParameter(Command)
	
	AddParameter("AddresseePresentation");
	
EndProcedure

&AtClient
Procedure AddTheCurrentDateParameter(Command)
	
	AddParameter("CurrentDate");
	
EndProcedure

&AtClient
Procedure AddTheSurveyStartDateParameter(Command)
	
	AddParameter("SurveyStartDate");
	
EndProcedure

&AtClient
Procedure AddTheSurveyEndDateParameter(Command)
	
	AddParameter("SurveyEndDate");
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	TMCommonUseClient.WriteAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure AddTheSurveyNameParameter(Command)
	
	AddParameter("SurveyDescription");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	BasedOnTheSurvey = ValueIsFilled(Object.Basis) And TypeOf(Object.Basis) = Type("DocumentRef.PollPurpose");
	
	GroupOfMailingsAndNotificationsWhenChangesOccurOnServer(True);
	
	CharsLeft = InteractionsClientServer.GenerateInfoLabelMessageCharsCount(
	                   Object.SendInTransliteration,
	                   Object.SMSMessageText);
	SetEmailEditingMethod();
	
	If Object.Status = Enums.CustomerMailoutStatuses.InProcessing 
		Or Object.Status = Enums.CustomerMailoutStatuses.Executed Then
		
		Items.Status.ChoiceList.Clear();
		Items.Status.ChoiceList.Add(Object.Status);
		
	EndIf;
	
	AvailabilityControl(ThisForm);
	
	Items.AddTheSurveyStartDateEmailParameter.Visible    = BasedOnTheSurvey;
	Items.AddTheSurveyEndDateEmailParameter.Visible = BasedOnTheSurvey;
	Items.AddTheSurveyNameParameterEmail.Visible  = BasedOnTheSurvey;
	Items.SurveyStartDate.Visible                          = BasedOnTheSurvey;
	Items.SurveyEndDate.Visible                       = BasedOnTheSurvey;
	Items.SurveyDescription.Visible                        = BasedOnTheSurvey;
	
	Items.CommentPage.Picture  = CommonClientServer.CommentPicture(Object.Comment);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	
	Form.Items.DistributionTransport.Enabled = Form.SMSMessagesAreAvailable And Form.SendingByEmailIsAvailable;
	
	If Form.Object.DesignedForEmails Then
		
		Form.Items.PagesTexts.CurrentPage = Form.Items.PageEmail;
		
		If Form.EmailTextType = 0 Then
			Form.Items.EmailTextPages.CurrentPage = Form.Items.PageEmailTextNormal;
		Else
			Form.Items.EmailTextPages.CurrentPage = Form.Items.PageEmailTextHTML;
		EndIf;
		
	Else
		
		Form.Items.PagesTexts.CurrentPage = Form.Items.PageSMSMessage;
		
	EndIf;
	
	GroupNotSpecified = Form.Object.GroupOfMailoutsAndNotifications.IsEmpty();
	EditingDenied = Form.Object.Status = PredefinedValue("Enum.CustomerMailoutStatuses.InProcessing")
		Or Form.Object.Status = PredefinedValue("Enum.CustomerMailoutStatuses.Executed"); 
	
	Form.Items.MessagePage.ReadOnly = GroupNotSpecified Or EditingDenied;
	Form.Items.AddresseesPage.ReadOnly  = GroupNotSpecified Or EditingDenied;
	Form.Items.HeaderGroup.ReadOnly       = EditingDenied;
	Form.Items.AttachmentsContextMenuAddAttachment.Enabled = Not (GroupNotSpecified Or EditingDenied);
	Form.Items.AttachmentsContextMenuDeleteAttachment.Enabled  = Not (GroupNotSpecified Or EditingDenied);
	Form.Items.GroupAddMessageParameter.Enabled            = Not (GroupNotSpecified Or EditingDenied);
	Form.Items.GroupAddSMSMessageParameter.Enabled               = Not (GroupNotSpecified Or EditingDenied);
	Form.Items.AddAttachment.Enabled                        = Not (GroupNotSpecified Or EditingDenied);
	
EndProcedure

&AtServer
Procedure GroupOfMailingsAndNotificationsWhenChangesOccurOnServer(ReadingExistingOne = False)
	
	If ValueIsFilled(Object.GroupOfMailoutsAndNotifications) Then
		GroupDetails_ = Common.ObjectAttributesValues(Object.GroupOfMailoutsAndNotifications, "DesignedForEmails, DesignedForSMSMessage");
		SendingByEmailIsAvailable = GroupDetails_.DesignedForEmails;
		SMSMessagesAreAvailable   = GroupDetails_.DesignedForSMSMessage;
	Else
		SendingByEmailIsAvailable = False;
		SMSMessagesAreAvailable   = False;
	EndIf;
	
	If Object.Ref.IsEmpty() Or Not ReadingExistingOne  Then
		
		OldValueTransport = DistributionTransport;
		If SMSMessagesAreAvailable And Not SendingByEmailIsAvailable Then
			DistributionTransport = 1;
		ElsIf SendingByEmailIsAvailable And Not SMSMessagesAreAvailable Then
			DistributionTransport = 0;
		EndIf;
		PurposeOfMailingByFlagTransport(ThisForm);
		If OldValueTransport <> DistributionTransport And Object.AdditionalRecipients.Count() > 0 Then
			FillInCITablesForAdditionalRecipients();
		EndIf;
		
	Else
		DistributionTransport = ?(Object.DesignedForEmails, 0, 1);
	EndIf;
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure PurposeOfMailingByFlagTransport(Form)

	Form.Object.DesignedForEmails = (Form.DistributionTransport = 0);
	Form.Object.DesignedForSMSMessage              = (Form.DistributionTransport = 1);
	
EndProcedure

&AtClient
Procedure PromptOnChangeFormatOnClose(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		
		SetHTML(EmailTextFormattedDocument, Object.HTMLEmailText, New Structure);
		EmailTextType = 1;
		
	Else
		
		Object.EmailTextType    = PredefinedValue("Enum.EmailEditingMethods.NormalText");
		Object.EmailText = EmailTextFormattedDocument.GetText();
		EmailTextFormattedDocument.Delete();

	EndIf;
	
	AvailabilityControl(ThisForm);
	
EndProcedure

&AtServerNoContext
Procedure SetHTML(PropsFormattedDocument, HTMLText, Attachments)
	
	PropsFormattedDocument.SetHTML(HTMLText, Attachments);
	
EndProcedure

&AtServer
Procedure SetEmailEditingMethod()
	
	If Object.EmailTextType = Enums.EmailEditingMethods.HTML Then
		
		EmailTextType = 1;
		AttachmentsStructure = New Structure;
		If Not Object.Ref.IsEmpty() Then
			If Not IsBlankString(Object.HTMLEmailText) Then
				
				Object.HTMLEmailText = Interactions.ProcessHTMLTextForFormattedDocument(Object.Ref , Object.HTMLEmailText,AttachmentsStructure)
				
			EndIf;
		ElsIf ValueIsFilled(Parameters.CopyingValue) Then
			If Not IsBlankString(Object.HTMLEmailText) Then
				
				Object.HTMLEmailText = Interactions.ProcessHTMLTextForFormattedDocument(Parameters.CopyingValue , Object.HTMLEmailText,AttachmentsStructure)
				
			EndIf;
		EndIf;
		
		EmailTextFormattedDocument.SetHTML(Object.HTMLEmailText, AttachmentsStructure);
		
	Else
		
		Object.EmailTextType = Enums.EmailEditingMethods.NormalText;
		EmailTextType = 0;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillAttachments(Var_Parameters = Undefined)
	
	Attachments.Clear();
	AttachmentsTable = SelfServiceServer.MetadataObjectAttachments(Object.Ref, True, False);
	For Each AttachmentsTableRow In AttachmentsTable Do
		NewRow = Attachments.Add();
		FillPropertyValues(NewRow, AttachmentsTableRow);
		NewRow.Placement = 0;
	EndDo;
	
EndProcedure

&AtServer
Procedure ProcessAttachmentsWhenWriting(CurrentObject)
	
	If Object.DesignedForEmails Then
		
		MailoutsAndNotificationsToCustomers.AddAttachmentsWithNonEmptyIDToListOfDeletedOnes(CurrentObject.Ref, DeletedAttachments);
		
		MailoutsAndNotificationsToCustomers.DeleteAttachments(DeletedAttachments);
		
		MailoutsAndNotificationsToCustomers.SaveFormattedDocumentPicturesAsAttachedFiles(
				CurrentObject.Ref,
				CurrentObject.EmailTextType,
				AttachmentsNamesToIDsMapsTable,
				UUID);
				
		MailoutsAndNotificationsToCustomers.SaveAttachments(CurrentObject.Ref, Attachments, UUID);
		
	ElsIf Attachments.Count() > 0 Or DeletedAttachments.Count() > 0 Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	MailoutToCustomersAttachedFiles.Ref
		|FROM
		|	Catalog.MailoutToCustomersAttachedFiles AS MailoutToCustomersAttachedFiles
		|WHERE
		|	MailoutToCustomersAttachedFiles.FileOwner = &FileOwner";
		
		Query.SetParameter("FileOwner", Object.Ref);
		
		Result = Query.Execute();
		If Not Result.IsEmpty() Then
			
			Selection = Result.Select();
			
			While Selection.Next() Do
				
				AttachedFileObject = Selection.Ref.GetObject(); // CatalogObject.MailoutToCustomersAttachedFiles
				AttachedFileObject.Delete();
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeComposerServer(CompositionSetup)
		
	TemplateName = ?(BasedOnTheSurvey, "PartnerFilterSurveyPurpose", "PartnerFilter");
	
	CompositionSchema = DataProcessors.SelectPartnersByFilter.GetTemplate(TemplateName);
	PartnersAndCounterparties.HeaderOfSKDFieldDependingOnFOUsePartnersAsCounterparties(
	                      CompositionSchema.DataSets.MainDataSet, "Partner", NStr("vi = 'Đối tác';
																					|ru = 'Контрагент';
																					|en = 'Counterparty'; fa = 'طرف حساب';
																					|it = 'Controparte';
																					|pl = 'Counterparty';
																					|tr = 'Cari hesap'"));
	SchemaURL = PutToTempStorage(CompositionSchema,UUID);
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
	
	If CompositionSetup = Undefined Then
		SettingsComposer.LoadSettings(CompositionSchema.DefaultSettings);
		SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
		If BasedOnTheSurvey Then
			FilterItemsArray = CommonClientServer.FindFilterItemsAndGroups(SettingsComposer.Settings.Filter,"SurveyPurpose");
			For Each SelectionElementAssignmentOfSurveys In FilterItemsArray Do
				SelectionElementAssignmentOfSurveys.Use = True;
				SelectionElementAssignmentOfSurveys.RightValue = Object.Basis;
			EndDo; 
		EndIf;
	Else
		SettingsComposer.LoadSettings(CompositionSetup);
		SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	EndIf;
	
	HeaderTextDestinationFilter(ThisObject);
	
EndProcedure

&AtServerNoContext
Function FillInAddressTable(DataForCalculation)

	Contact        = DataForCalculation.Contact;
	AddressesTable = DataForCalculation.AddressesTable;
	
	CatalogName = Contact.Metadata().Name;
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT ALLOWED
	|	Table.Kind AS ContactInformationKind,
	|	Table.Type AS ContactInformationType,
	|	Table.Presentation AS Presentation
	|FROM
	|	&CatalogName AS Table
	|WHERE
	|	Table.Ref = &Contact
	|	AND Table.Type = &CIType
	|	AND Table.Presentation <> """"";
	
	Query.Text = StrReplace(Query.Text, "&CatalogName", "Catalog." + CatalogName + ".ContactInformation");
	
	Query.SetParameter("Contact", Contact);
	Query.SetParameter("CIType", RequiredTypeOfContactInformation(DataForCalculation.DesignedForEmails));
	
	AddressesTable.Load(Query.Execute().Unload());
	
	If AddressesTable.Count() > 0 Then
		Return  AddressesTable[0].Presentation;
	ElsIf AddressesTable.Count() = 0 Then
		Return "";
	EndIf;

EndFunction

&AtServer
Procedure FillInCITablesForAdditionalRecipients()

	AddressesTable = New ValueTable;
	AddressesTable.Columns.Add("Presentation",  New TypeDescription("String"));
	AddressesTable.Columns.Add("ContactInformationKind",  New TypeDescription("CatalogRef.ContactInformationKinds"));
	
	QueryText ="
	|SELECT ALLOWED DISTINCT
	|	Contacts.Contact,
	|	Contacts.ContactInformation
	|INTO AllContacts
	|FROM
	|	&Contacts AS Contacts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Contacts.Contact
	|INTO Contacts
	|FROM
	|	AllContacts AS Contacts
	|WHERE
	|	Contacts.Contact <> UNDEFINED
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PartnersContactInformation.Presentation AS Presentation,
	|	PartnersContactInformation.Kind AS ContactInformationKind,
	|	PartnersContactInformation.Ref AS Contact
	|FROM
	|	Catalog.Partners.ContactInformation AS PartnersContactInformation
	|WHERE
	|	PartnersContactInformation.Ref IN
	|			(SELECT
	|				Contacts.Contact
	|			FROM
	|				Contacts AS Contacts)
	|	AND PartnersContactInformation.Presentation <> """"
	|	AND PartnersContactInformation.Type = &CIType
	|
	|UNION ALL
	|
	|SELECT
	|	ContactPersonsOfPartnersContactInformation.Presentation,
	|	ContactPersonsOfPartnersContactInformation.Kind,
	|	ContactPersonsOfPartnersContactInformation.Ref
	|FROM
	|	Catalog.ContactPersonsForPartners.ContactInformation AS ContactPersonsOfPartnersContactInformation
	|WHERE
	|	ContactPersonsOfPartnersContactInformation.Ref IN
	|			(SELECT
	|				Contacts.Contact
	|			FROM
	|				Contacts AS Contacts)
	|	AND ContactPersonsOfPartnersContactInformation.Presentation <> """"
	|	AND ContactPersonsOfPartnersContactInformation.Type = &CIType
	|TOTALS BY
	|	Contact";
	
	Query = New Query(QueryText);
	Query.SetParameter("Contacts",Object.AdditionalRecipients.Unload());
	Query.SetParameter("CIType", RequiredTypeOfContactInformation(Object.DesignedForEmails));
	
	SampleContact = Query.Execute().Select(QueryResultIteration.ByGroups);
	
	While SampleContact.Next() Do
		
		AddressesTable.Clear();
		
		DetailsSelection = SampleContact.Select();
		While DetailsSelection.Next() Do
			
			NewRow = AddressesTable.Add();
			FillPropertyValues(NewRow, DetailsSelection);
			
		EndDo;
		
		If AddressesTable.Count() > 0 Then
			
			FoundRows = Object.AdditionalRecipients.FindRows(New Structure("Contact", SampleContact.Contact));
			For Each FoundRow In FoundRows Do
			
				FoundRow.AddressesTable.Load(AddressesTable);
			
			EndDo;
			
		EndIf;
		
	EndDo;

EndProcedure

&AtServerNoContext
Function RequiredTypeOfContactInformation(Val PurposeOfMailingList)

	Return ?(PurposeOfMailingList,
	          Enums.ContactInformationTypes.Email,
	          Enums.ContactInformationTypes.Phone);

EndFunction

&AtClient
Procedure AddParameter(ParameterName)

	InsertedText_ = "[" + ParameterName + "]";
	
	If Object.DesignedForSMSMessage Then
		
		PasteIntoEditableText(Items.SMSMessageText, InsertedText_);
		
	Else
		
		If Object.EmailTextType = PredefinedValue("Enum.EmailEditingMethods.NormalText") Then
			
			PasteIntoEditableText( Items.EmailText, InsertedText_);
			
		Else
			
			BoldBeginning = Undefined;
			BoldEnd  = Undefined;
			Items.EmailTextFormattedDocument.GetTextSelectionBounds(BoldBeginning, BoldEnd);
			EmailTextFormattedDocument.Insert(BoldBeginning, InsertedText_, FormattedDocumentItemType.Text);
			
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure PasteIntoEditableText( Item, InsertText1)

	BeginningOfTheLine = 0;
	BeginningOfTheColumn = 0;
	EndOfRow = 0;
	EndOfColumn = 0;
	
 	Item.GetTextSelectionBounds(BeginningOfTheLine, BeginningOfTheColumn, EndOfRow, EndOfColumn);
	
	If (EndOfColumn = BeginningOfTheColumn) And (EndOfColumn + StrLen(InsertText1)) > Item.Width / 8 Then
		Item.SelectedText = "";
	EndIf;
	
	Item.SelectedText = InsertText1;
	
	CurrentItem = Item;

EndProcedure

&AtClientAtServerNoContext
Procedure HeaderTextDestinationFilter(Form)

	If IsBlankString(String(Form.SettingsComposer.Settings.Filter)) Then
		Form.TitleAddresseeFilter = NStr("vi = 'chưa thiết lập';
										|ru = 'не установлен';
										|en = 'not set'; fa = 'not set';
										|it = 'non impostato';
										|pl = 'nie ustawiono';
										|tr = 'yapılandırılmadı'");
	Else
		Form.TitleAddresseeFilter = NStr("vi = 'đã thiết lập';
										|ru = 'установлен';
										|en = 'set'; fa = 'set';
										|it = 'impostato';
										|pl = 'set';
										|tr = 'yapılandırıldı'");
	EndIf;

EndProcedure

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
