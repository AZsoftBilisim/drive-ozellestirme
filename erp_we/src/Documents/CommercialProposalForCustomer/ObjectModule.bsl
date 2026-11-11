#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	AccountingSettings = CommercialProposalsDocuments.AccountingSettings();
	
	If Not AccountingSettings.PartnersAreUsed Then
		NotCheckedAttributeArray.Add("Client");
	EndIf;
	
	If Not AccountingSettings.StatusOfCommercialOffersToClientsIsUsed Then
		NotCheckedAttributeArray.Add("Status");
	EndIf;
	
	If Not AccountingSettings.ProductCharacteristicsAreUsed Then
		NotCheckedAttributeArray.Add("Goods.Characteristic");
	EndIf;
	
	If ValueIsFilled(Manager) Then
		ManagerContactInformation = CommercialProposalsDocuments.ManagerContactInformation(Manager);
		
		If IsBlankString(ManagerContactInformation.Email) Then
			
			MessageText = StrTemplate(NStr("vi = 'Người quản lý %1 không có địa chỉ email.';
											|ru = 'Для менеджера %1 не указан адрес электронной почты.';
											|en = 'The email address is not specified for the manager %1.'; fa = 'The email address is not specified for the manager %1.';
											|it = 'Per il manager%1 non è specificato l''indirizzo della posta elettronica.';
											|pl = 'U menedżera %1 nie jest podany adres e-mail.';
											|tr = '%1 Yönetici için e-posta adresi belirtilmemiştir.'"), Manager);
			Common.MessageToUser(MessageText, ThisObject, "Manager", , Cancel);
			
		ElsIf Not ManagerContactInformation.EmailMeetsRequirements_ Then
			
			MessageText = StrTemplate(NStr("vi = 'Người quản lý %1 có địa chỉ email không hợp lệ ""%2"".';
											|ru = 'Для менеджера %1 указан некорректный адрес электронной почты ""%2"".';
											|en = 'Incorrect email address ""%2"" is specified for the sales person %1.'; fa = 'Incorrect email address ""%2"" is specified for the sales person %1.';
											|it = 'Per il manager %1 l''indirizzo della posta elettronica indicato non è valido ""%2"".';
											|pl = 'U menedżera %1 został podany nieprawidłowy adres e-mail ""%2"".';
											|tr = '%1 Yönetici için yanlış e-posta adresi ""%2"" belirtilmiştir.'"), Manager, ManagerContactInformation.Email);
			Common.MessageToUser(MessageText, ThisObject, "Manager", , Cancel);
			
		EndIf;
		
	EndIf;
	
	CommercialProposalsDocumentsOverridable.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, NotCheckedAttributeArray);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	
	CommercialProposalsDocumentsOverridable.ProcessingDocumentFilling(ThisObject, FillingData, FillingText, StandardProcessing);
	
	InitializeDocumentData();
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentAmount = Goods.Total("AmountIncludingVAT");
	
	AdditionalProperties.Insert("IsNew",    IsNew());
	AdditionalProperties.Insert("WriteMode", WriteMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
	CommercialProposalsDocumentsOverridable.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	
	
	CommercialProposalsDocumentsOverridable.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	 CommercialProposalsDocumentsOverridable.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	 CommercialProposalsDocumentsOverridable.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Author = Users.CurrentUser();
	
	CommercialProposalsDocumentsOverridable.OnCopy(ThisObject);

EndProcedure
	
#EndRegion

#Region Private


Procedure InitializeDocumentData()

	AccountingSettings = CommercialProposalsDocuments.AccountingSettings();
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	If Not ValueIsFilled(Organization)
		And AccountingSettings.SingleOrganizationIsUsed 
		And ValueIsFilled(AccountingSettings.SoleCompany) Then
		
		Organization = AccountingSettings.SoleCompany;
		
	EndIf;
	
	If Not ValueIsFilled(Currency)
		And AccountingSettings.SingleCurrencyIsUsed
		And ValueIsFilled(AccountingSettings.OnlyCurrency) Then
		
		Currency = AccountingSettings.OnlyCurrency;
		
	EndIf;
	
	Author = Users.CurrentUser();

EndProcedure


#EndRegion

#EndIf
