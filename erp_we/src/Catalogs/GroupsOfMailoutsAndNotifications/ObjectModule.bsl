
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not DesignedForEmails And Not DesignedForSMSMessage Then
		
		ErrorText = NStr("vi = 'Chưa chỉ ra dạng gửi thông báo nào.';
						|ru = 'Не указан ни один вид доставки сообщений.';
						|en = 'No message delivery kind is specified.'; fa = 'No message delivery kind is specified.';
						|it = 'Non è specificato alcun tipo di consegna del messaggio.';
						|pl = 'Nie określono żadnego rodzaju dostarczania wiadomości.';
						|tr = 'Mesaj teslim türü belirtilmedi.'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"DesignedForEmails",
			,
			Cancel);
		
	EndIf;
	
	If Not DesignedForEmails Then
		
		NotCheckedAttributeArray.Add("Account");
		NotCheckedAttributeArray.Add("PartnerSContactDetailsKindForEmails");
		NotCheckedAttributeArray.Add("ContactPersonSContactDetailsKindForEmails");
		
	EndIf;
	
	If Not DesignedForSMSMessage Then
		
		NotCheckedAttributeArray.Add("PartnerSContactDetailsKindForSMSMessage");
		NotCheckedAttributeArray.Add("ContactPersonSContactDetailsKindForSMSMessage");
		
	EndIf;
	
	If Forced And Not SendToCustomer Then
		
		NotCheckedAttributeArray.Add("PartnerSContactDetailsKindForEmails");
		NotCheckedAttributeArray.Add("PartnerSContactDetailsKindForSMSMessage");
		
	EndIf;
	
	If Forced And (Not SendToRoleContactPersons) And (Not SendToAContactPersonOfANotificationObject) Then
		
		NotCheckedAttributeArray.Add("ContactPersonSContactDetailsKindForEmails");
		NotCheckedAttributeArray.Add("ContactPersonSContactDetailsKindForSMSMessage");
		
	EndIf;
	
	If Not SendToRoleContactPersons Then
		
		NotCheckedAttributeArray.Add("ContactRole");
		
	EndIf;
	
	If Forced Then
		
		If Not SendToCustomer 
			 And Not SendToAContactPersonOfANotificationObject 
			 And Not SendToRoleContactPersons Then
			
			ErrorText = NStr("vi = 'Cần chỉ ra ít nhất một dạng đánh địa chỉ.';
							|ru = 'Необходимо указать хотя бы один вид адресатов.';
							|en = 'Specify at least one recipient kind.'; fa = 'Specify at least one recipient kind.';
							|it = 'È necessario specificare almeno un tipo di destinatari.';
							|pl = 'Należy wskazać chociażby jeden rodzaj adresatów.';
							|tr = 'En az bir alıcı türü belirtilmeli.'");
		
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"SendToCustomer",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not Forced Then
		
		SendToCustomer                         = False;
		SendToAContactPersonOfANotificationObject = False;
		SendToRoleContactPersons              = False;
		
	EndIf;
	
	If Not SendToRoleContactPersons Then
		ContactRole = Catalogs.RolesOfPartnerContactPersons.EmptyRef();
	EndIf;
	
	PartnerSCIIsRequired        = Not Forced Or SendToCustomer;
	KIOfContactPersonIsRequired = Not Forced Or SendToAContactPersonOfANotificationObject Or SendToRoleContactPersons;
	
	If Not DesignedForEmails And ValueIsFilled(Account) Then
		Account = Catalogs.EmailAccounts.EmptyRef();
	EndIf;
	
	If (Not DesignedForEmails) Or (Not PartnerSCIIsRequired) 
		And ValueIsFilled(PartnerSContactDetailsKindForEmails) Then
		PartnerSContactDetailsKindForEmails = Catalogs.ContactInformationKinds.EmptyRef();
	EndIf;
	
	If (Not DesignedForEmails) Or (Not KIOfContactPersonIsRequired) 
		And ValueIsFilled(ContactPersonSContactDetailsKindForEmails) Then
		ContactPersonSContactDetailsKindForEmails = Catalogs.ContactInformationKinds.EmptyRef();
	EndIf;
	
	If (Not DesignedForSMSMessage) Or (Not KIOfContactPersonIsRequired)
		And ValueIsFilled(ContactPersonSContactDetailsKindForSMSMessage) Then
		ContactPersonSContactDetailsKindForSMSMessage = Catalogs.ContactInformationKinds.EmptyRef();
	EndIf;
	
	If (Not DesignedForSMSMessage) Or (Not PartnerSCIIsRequired) 
		And ValueIsFilled(PartnerSContactDetailsKindForSMSMessage) Then
		PartnerSContactDetailsKindForSMSMessage = Catalogs.ContactInformationKinds.EmptyRef();
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

#EndRegion

#EndIf

