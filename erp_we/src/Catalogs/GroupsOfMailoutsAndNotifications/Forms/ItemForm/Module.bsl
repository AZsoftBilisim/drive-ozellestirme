
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	SetConditionalAppearance();
	
	SetHeaders();
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	If Object.Ref.IsEmpty() Then
		OnCreatReadAtServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnCreatReadAtServer();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not DeleteCreatedMessages Then
		Object.MessageRetentionPeriod = 0;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisForm);
	ConfigureNavigationBar();
	AvailabilityControl(ThisObject);
	Items.DetailsPage.Picture = CommonClientServer.CommentPicture(Object.LongDesc);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.GroupsOfMailoutsAndNotifications.Form.SelectionFormOfUserAccount" Then
		
		If TypeOf(ValueSelected) = Type("Structure") Then
			
			Object.Account               = ValueSelected.Account;
			TheAccountDoesNotStoreEmails        = ValueSelected.DeleteAfterSend;
			TheAccountIsNotAvailableForSending = False;
			AvailabilityControl(ThisForm);
			
		EndIf;
		
	ElsIf TypeOf(ValueSelected) = Type("CatalogRef.Partners")
		And Not ValueSelected.IsEmpty() Then
		
		MailoutsAndNotificationsToCustomersClient.OpenSubscriptionForm(ValueSelected, Object.Ref, ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_SMSMessageSendingSettings" Then
		CheckSMSSettings();
	ElsIf EventName = "Write_EmailAccounts" Then
		CheckAvailableAccounts();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If DeleteCreatedMessages And Object.MessageRetentionPeriod = 0 Then
		MessageText = NStr("vi = 'Chưa chỉ ra thời hạn lưu thông báo.';
							|ru = 'Не указан срок хранения сообщений.';
							|en = 'Message storage period is not specified.'; fa = 'Message storage period is not specified.';
							|it = 'Non è stato specificato alcun periodo di archiviazione dei messaggi.';
							|pl = 'Nie określono terminu przechowywania wiadomości.';
							|tr = 'Mesaj saklama süresi belirtilmedi.'");
		CommonClientServer.MessageToUser(MessageText,,"Object.MessageRetentionPeriod",,Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DesignedForEmailsOnChange(Item)
	
	AvailabilityControl(ThisObject);
	FillInDefaultKiTypes();
	
EndProcedure

&AtClient
Procedure DeleteCreatedMessagesOnChange(Item)
	
	AvailabilityControl(ThisObject);
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Procedure AccountStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenForm("Catalog.GroupsOfMailoutsAndNotifications.Form.SelectionFormOfUserAccount", ,ThisForm);
	
EndProcedure

&AtClient
Procedure DesignedForSMSMessageOnChange(Item)
	
	AvailabilityControl(ThisObject);
	FillInDefaultKiTypes();
	
EndProcedure

&AtClient
Procedure SubscriptionTypeOnChange(Item)
	
	Object.Forced = ?(SubscriptionType = 0, False, True);
	FillInDefaultKiTypes();
	VisibilityManagement();
	
EndProcedure

&AtClient
Procedure SendToRoleContactPersonsOnChange(Item)
	
	FillInDefaultKiTypes();
	AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure SendToCustomerOnChange(Item)
	
	FillInDefaultKiTypes();
	AvailabilityControl(ThisObject);
	
EndProcedure

&AtClient
Procedure SendToAContactPersonOfANotificationObjectOnChange(Item)
	
	FillInDefaultKiTypes();
	AvailabilityControl(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

&AtClient
Procedure ConfigureSMSMessageSending(Command)
	
	OpenForm("CommonForm.OutboundSMSSettings");
	
EndProcedure

&AtClient
Procedure SetUpEmailAccounts(Command)
	
	OpenForm("Catalog.EmailAccounts.ListForm");
	
EndProcedure

&AtClient
Procedure CreateSubscription(Command)
	
	OpenForm("Catalog.Partners.ChoiceForm", , ThisObject);
	
EndProcedure

&AtClient
Procedure CreateBulkMail(Command)
	
	FillingValues = New Structure;
	FillingValues.Insert("GroupOfMailoutsAndNotifications", Object.Ref);
	FormParameters = New Structure("FillingValues", FillingValues);
	
	OpenForm("Document.MailoutToCustomers.ObjectForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure CreateNotificationKind(Command)
	
	FillingValues = New Structure;
	FillingValues.Insert("GroupOfMailoutsAndNotifications", Object.Ref);
	FormParameters = New Structure("FillingValues", FillingValues);
	
	OpenForm("Catalog.CustomerNotificationKinds.ObjectForm", FormParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnCreatReadAtServer()
	
	ReadRightAccounts = AccessRight("Read", Metadata.Catalogs.EmailAccounts);
	
	FillInListsForSelectingTypeOfCI();
	SMSMessageIsSetUp = SendSMSMessage.SMSMessageSendingSetupCompleted();
	FillInAvailableAccounts();
	
	If ValueIsFilled(Object.Account) 
		And AvailableAccountsForSending.FindRows(New Structure("Account", Object.Account)).Count() = 0 Then
		
		TheAccountIsNotAvailableForSending = True;
		
	EndIf;
	
	DeleteCreatedMessages = (Object.MessageRetentionPeriod > 0);
	SubscriptionType = ?(Object.Forced,1,0);
	
	VisibilityManagement();
	ConfigureNavigationBar();
	Items.DetailsPage.Picture = CommonClientServer.CommentPicture(Object.LongDesc);
	
EndProcedure

&AtServer
Procedure ConfigureNavigationBar()
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("UseSubscriptionData", Not Object.Forced);
	
	TMCommonUse.ConfigureFormByParameters(ThisObject, SettingsStructure);
	
EndProcedure

&AtServer
Procedure VisibilityManagement()
	
	Items.CreateBulkMail.Visible = AccessRight("Insert", Metadata.Documents.MailoutToCustomers);
	Items.CreateNotificationKind.Visible = AccessRight("Insert", Metadata.Catalogs.CustomerNotificationKinds);
	Items.CreateSubscription.Visible      = AccessRight("Insert", Metadata.Catalogs.SubscriptionsToCustomerMailoutsAndNotifications);
	
	UseOtherInteractions = GetFunctionalOption("UseOtherInteractions");
	
	Items.GroupAccountsAreNotConfigured.Visible         = Not ThereAreAvailableAccounts;
	Items.Account.Enabled                        = ReadRightAccounts;
	Items.SetUpEmailAccounts.Visible = ReadRightAccounts;
	
	Items.SMSGroup.Visible                      = UseOtherInteractions;
	Items.TheSMSGroupIsNotConfigured.Visible           = UseOtherInteractions 
	                                                    And Not SMSMessageIsSetUp 
	                                                    And AccessRight("View", Metadata.CommonForms.OutboundSMSSettings);
	
	Items.AddresseeSettingsGroupForced.Visible = Object.Forced;
	Items.DecorationSubscriptionTypeExplanation.Title  = ExplanationTextMailingType(Object.Forced);
	
	Items.DecorationPartnerSContactPersonExplanation.Title = MailoutsAndNotificationsToCustomers.ExplanationTextContactPersonOfNotificationObject();
	
	AvailabilityControl(ThisObject);

EndProcedure

&AtClientAtServerNoContext
Function ExplanationTextMailingType(Forced)

	If Not Forced Then
		ExplanationText = NStr("vi = 'Thư và thông báo sẽ được gửi theo tùy chỉnh đăng ký. Dạng thông tin liên hệ,
		                             |được chỉ ra trong biểu mẫu này sẽ được dùng như là giá trị mặc định và có thể 
		                             |thay đổi khi tạo đăng ký.';
		                             |ru = 'Рассылки и оповещения будут отправляться согласно настройкам подписок. Виды контактной информации,
		                             |указанные в данной форме, будут использованы как значения по умолчанию и могут быть 
		                             |изменены при оформлении подписок.';
		                             |en = 'Mailouts and notifications are sent according to subscription settings. Contact details kinds
		                             |specified in this form are used as the default values and can be 
		                             |changed upon registering subscriptions.'; fa = 'Mailouts and notifications are sent according to subscription settings. Contact details kinds
		                             |specified in this form are used as the default values and can be 
		                             |changed upon registering subscriptions.';
		                             |it = 'Mailing e avvisi verranno inviati in base alle impostazioni di abbonamenti. I tipi di informazioni di contatto,
		                             |specificate in questo modulo verranno utilizzati come valori predefiniti e possono essere 
		                             | modificati al momento della sottoscrizione di abbonamenti.';
		                             |pl = 'Subskrypcje i powiadomienia będą wysyłane zgodnie z ustawieniami subskrypcji. Rodzaje danych kontaktowych,
		                             |wskazane w danym formularzu zostaną wykorzystane jako wartości domyślne i mogą być 
		                             | zmienione przy tworzeniu subskrypcji.';
		                             |tr = 'Abonelik ayarlarına göre bağlantı ve uyarılar gönderilecektir. Bu formda belirtilen 
		                             |iletişim bilgileri türleri varsayılan değerler olarak kullanılacaktır ve abone olurken 
		                             |değiştirilebilir.'");
	Else
		ExplanationText = NStr("vi = 'Thư và thông báo sẽ được gửi một cách bắt buộc. Không thể tùy chỉnh đăng ký. Trong biểu mẫu này
		                             |cần tùy chỉnh cấu hình ai sẽ là người nhận thư và các dạng thông tin liên hệ, theo đó
		                             |địa chỉ E-mail và số điện thoại của người nhận địa chỉ sẽ được xác định.';
		                             |ru = 'Рассылки и оповещения будут отправляться принудительно. Настройка подписок невозможна. В данной форме
		                             |необходимо настроить, кто будет получателем сообщений и виды контактной информации, согласно
		                             |которым будут определяться адреса электронной почты и номера телефонов адресатов.';
		                             |en = 'Mailouts and notifications are sent regardless of subscription settings. You cannot configure subscriptions. In this form,
		                             |you need to configure message recipients and contact details kinds according to
		                             |which email addresses and recipient phone numbers are determined.'; fa = 'Mailouts and notifications are sent regardless of subscription settings. You cannot configure subscriptions. In this form,
		                             |you need to configure message recipients and contact details kinds according to
		                             |which email addresses and recipient phone numbers are determined.';
		                             |it = 'Mail e avvisi saranno inviati nel modo coercitivo. Le sottoscrizioni non possono essere configurate. In questo modulo
		                             |è necessario configurare il destinatario di messaggi e tipi di informazioni di riferimento, in base
		                             |ai quali verranno determinati gli indirizzi e-mail e i numeri di telefono dei destinatari.';
		                             |pl = 'Subskrypcje i powiadomienia będą wysyłane przymusowo. Ustawienia subskrypcji są niedostępne. W danym formularzu
		                             |należy ustawić, kto będzie otrzymywać wiadomości i rodzaje danych kontaktowych, zgodnie
		                             |z którymi będą określane adresy poczty elektronicznej i numery telefonów adresatów.';
		                             |tr = 'Bülten ve uyarılar zorunlu olarak gönderilecektir. Abonelikler yapılandırılamaz. Bu formda,
		                             |mesajların kim tarafından alınacağını ve iletişim bilgileri türlerini, buna göre
		                             |alıcıların e-posta adreslerini ve telefon numaralarını belirleyecek şekilde yapılandırılması gerekir.'");
	EndIf;
	
	Return ExplanationText;

EndFunction 

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	
	SettingUpContactPersonSCIIsRequired = SettingUpContactPersonSCIIsRequired(Form.Object);
	PartnerCISettingsRequired        = PartnerCISettingsRequired(Form.Object);
	ObjectRecorded                       = Not Form.Object.Ref.IsEmpty();
	
	Form.Items.Account.Enabled                                  = Form.Object.DesignedForEmails
	                                                                            And Form.ReadRightAccounts;
	Form.Items.PartnerSContactDetailsKindForEmails.Enabled        = Form.Object.DesignedForEmails
	                                                                            And PartnerCISettingsRequired;
	Form.Items.ContactPersonSContactDetailsKindForEmails.Enabled = Form.Object.DesignedForEmails
	                                                                            And SettingUpContactPersonSCIIsRequired;
	Form.Items.SetUpEmailAccounts.Enabled         = Form.Object.DesignedForEmails;
	
	Form.Items.PartnerSContactDetailsKindForSMSMessage.Enabled          = Form.Object.DesignedForSMSMessage
	                                                                            And PartnerCISettingsRequired;
	Form.Items.ContactPersonSContactDetailsKindForSMSMessage.Enabled   = Form.Object.DesignedForSMSMessage
	                                                                            And SettingUpContactPersonSCIIsRequired;
	Form.Items.ConfigureSMSMessageSending.Enabled                           = Form.Object.DesignedForSMSMessage;
	
	Form.Items.MessageRetentionPeriod.Enabled  = Form.DeleteCreatedMessages;
	If Form.TheAccountIsNotAvailableForSending Or Not Form.ReadRightAccounts Then
		Form.Items.PageAccount.CurrentPage = Form.Items.PageAccountIsNotAvailable;
	Else
		Form.Items.PageAccount.CurrentPage = Form.Items.PageAccountIsAvailable;
	EndIf;
	
	Form.Items.ContactRole.Enabled = Form.Object.SendToRoleContactPersons;
	
	Form.Items.CreateBulkMail.Enabled      = ObjectRecorded;
	Form.Items.CreateNotificationKind.Enabled = ObjectRecorded;
	Form.Items.CreateSubscription.Enabled      = ObjectRecorded And Not Form.Object.Forced;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

#Region MessageRetentionPeriod
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MessageRetentionPeriod.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeleteCreatedMessages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MessageRetentionPeriod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
#EndRegion
	
EndProcedure

&AtServer
Function FillInListsForSelectingTypeOfCI()
	
	StructureOfSelectionLists = MailoutsAndNotificationsToCustomers.StructureOfKiSelectionLists();
	
	MailoutsAndNotificationsToCustomers.CopyValuesFromListOfValues(
	     Items.PartnerSContactDetailsKindForEmails.ChoiceList,
	     StructureOfSelectionLists.PartnersEmailAddress);
	
	MailoutsAndNotificationsToCustomers.CopyValuesFromListOfValues(
	     Items.PartnerSContactDetailsKindForSMSMessage.ChoiceList,
	     StructureOfSelectionLists.PartnersPhoneNumber_);
	
	MailoutsAndNotificationsToCustomers.CopyValuesFromListOfValues(
	     Items.ContactPersonSContactDetailsKindForEmails.ChoiceList,
	     StructureOfSelectionLists.ContactPersonsEmailAddress);
	
	MailoutsAndNotificationsToCustomers.CopyValuesFromListOfValues(
	     Items.ContactPersonSContactDetailsKindForSMSMessage.ChoiceList,
	     StructureOfSelectionLists.ContactPersonsPhone);
		 
	Items.PartnerSContactDetailsKindForEmails.ChoiceButton        = (Items.PartnerSContactDetailsKindForEmails.ChoiceList.Count() > 1);
	Items.PartnerSContactDetailsKindForSMSMessage.ChoiceButton          = (Items.PartnerSContactDetailsKindForSMSMessage.ChoiceList.Count() > 1);
	Items.ContactPersonSContactDetailsKindForEmails.ChoiceButton = (Items.ContactPersonSContactDetailsKindForEmails.ChoiceList.Count() > 1);
	Items.ContactPersonSContactDetailsKindForSMSMessage.ChoiceButton   = (Items.ContactPersonSContactDetailsKindForSMSMessage.ChoiceList.Count() > 1);

EndFunction

&AtServer
Procedure CheckSMSSettings()
	
	SMSMessageIsSetUp = SendSMSMessage.SMSMessageSendingSetupCompleted();
	VisibilityManagement();
	
EndProcedure

&AtServer
Procedure CheckAvailableAccounts()

	FillInAvailableAccounts();
	VisibilityManagement();

EndProcedure

&AtServer
Procedure FillInAvailableAccounts()

	AvailableAccountsForSending.Clear();
	
	If ReadRightAccounts Then
		EmailManagement.GetAvailableAccountsForSending(
		Items.Account.ChoiceList, AvailableAccountsForSending);
		ThereAreAvailableAccounts = AvailableAccountsForSending.Count() > 0;
	Else
		ThereAreAvailableAccounts = False;
		Items.DecorationErrorAccount.ToolTip = NStr("vi = 'Bạn không có quyền đọc tài khoản email, liên hệ với quản trị viên của bạn.';
													|ru = 'У вас нет прав на чтение учетных записей электронной почты, обратитесь к администратору.';
													|en = 'You are not authorized to read email accounts. Please contact the administrator.'; fa = 'You are not authorized to read email accounts. Please contact the administrator.';
													|it = 'Non si ha le autorizzazioni per leggere gli account di posta elettronica, contattare l''amministratore.';
													|pl = 'Nie posiadasz uprawnień do odczytu kont poczty elektronicznej, skontaktuj się z administratorem.';
													|tr = 'E-posta hesaplarını okuma izniniz mevcut değil, lütfen yöneticiyle iletişime geç.'");
	EndIf;

EndProcedure 

&AtClient
Procedure FillInDefaultKiTypes()

	SettingUpContactPersonSCIIsRequired = SettingUpContactPersonSCIIsRequired(Object);
	PartnerCISettingsRequired        = PartnerCISettingsRequired(Object);
	
	If Object.DesignedForSMSMessage Then
		
		If Object.PartnerSContactDetailsKindForSMSMessage.IsEmpty()
			And PartnerCISettingsRequired
			And Items.PartnerSContactDetailsKindForSMSMessage.ChoiceList.Count() = 1 Then
			
			Object.PartnerSContactDetailsKindForSMSMessage =
			       Items.PartnerSContactDetailsKindForSMSMessage.ChoiceList.Get(0).Value;
			
		EndIf;
		
		If Object.ContactPersonSContactDetailsKindForSMSMessage.IsEmpty()
			And SettingUpContactPersonSCIIsRequired
			And Items.ContactPersonSContactDetailsKindForSMSMessage.ChoiceList.Count() = 1 Then
			
			Object.ContactPersonSContactDetailsKindForSMSMessage = 
			       Items.ContactPersonSContactDetailsKindForSMSMessage.ChoiceList.Get(0).Value;
			
		EndIf;
		
	EndIf;
	
	If Object.DesignedForEmails Then
		
		If Object.ContactPersonSContactDetailsKindForEmails.IsEmpty()
			And SettingUpContactPersonSCIIsRequired
			And Items.ContactPersonSContactDetailsKindForEmails.ChoiceList.Count() = 1 Then
			
			Object.ContactPersonSContactDetailsKindForEmails = 
			       Items.ContactPersonSContactDetailsKindForEmails.ChoiceList.Get(0).Value;
			
		EndIf;
				
		If Object.PartnerSContactDetailsKindForEmails.IsEmpty()
			And PartnerCISettingsRequired
			And Items.PartnerSContactDetailsKindForEmails.ChoiceList.Count() = 1 Then
			
			Object.PartnerSContactDetailsKindForEmails = 
			       Items.PartnerSContactDetailsKindForEmails.ChoiceList.Get(0).Value;
			
		EndIf;
		
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Function SettingUpContactPersonSCIIsRequired(Object)

	Return Not Object.Forced 
	        Or Object.SendToAContactPersonOfANotificationObject 
	        Or Object.SendToRoleContactPersons;

EndFunction

&AtClientAtServerNoContext
Function PartnerCISettingsRequired(Object)

	Return Not Object.Forced Or Object.SendToCustomer;

EndFunction

&AtServer
Procedure SetHeaders()

	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	            ThisObject, "SendToCustomer", NStr("vi = 'thông tin liên hệ của đối tác';
													|ru = 'на контактную информацию контрагента';
													|en = 'for the counterparty contact details'; fa = 'for the counterparty contact details';
													|it = 'informazioni di contatto del contraente';
													|pl = 'na dane kontaktowe kontrahenta';
													|tr = 'cari hesabın iletişim bilgisine'"), UsePartnersAsCounterparties);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	            ThisObject, "PartnerSContactDetailsKindForEmails", NStr("vi = 'dành cho đối tác';
																		|ru = 'для контрагента';
																		|en = 'for counterparty'; fa = 'for counterparty';
																		|it = 'per il contraente';
																		|pl = 'dla kontrahenta';
																		|tr = 'cari hesap için'"), UsePartnersAsCounterparties);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	            ThisObject, "PartnerSContactDetailsKindForSMSMessage", NStr("vi = 'dành cho đối tác';
																			|ru = 'для контрагента';
																			|en = 'for counterparty'; fa = 'for counterparty';
																			|it = 'per il contraente';
																			|pl = 'dla kontrahenta';
																			|tr = 'cari hesap için'"), UsePartnersAsCounterparties);

EndProcedure

#EndRegion
