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
	
	FilterSent = "All";
	MailingRecipientType = Parameters.MailingRecipientType;
	MailingDescription = Parameters.MailingDescription;
	MetadataObjectID = Parameters.MetadataObjectID;
	
	// ACC:1223-off - This is an example of a text message.
	Items.DecorationHint.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Ví dụ: Mật khẩu của bạn: ******* để gửi hàng loạt ""%1"".';
			|ru = 'Пример SMS: Ваш пароль: ******* для получения рассылки ""%1"".';
			|en = 'A text message example: Your password: ******* to receive the ""%1"" report distribution.'; fa = 'A text message example: Your password: ******* to receive the ""%1"" report distribution.';
			|it = 'Пример SMS: Ваш пароль: ******* для получения рассылки ""%1"".';
			|pl = 'A text message example: Your password: ******* to receive the ""%1"" report distribution.';
			|tr = 'SMS örneği: ""%1"" dağıtımının alınması için şifreniz: *******.'"), MailingDescription);
	// ACC:1223-on
	
	If Not IsTempStorageURL(Parameters.RecipientsAddress) Then
		Return;
	EndIf;
	
	Recipients.Load(GetFromTempStorage(Parameters.RecipientsAddress));

	DeleteFromTempStorage(Parameters.RecipientsAddress); 

	DefineRecipientsPhoneKind();
	PopulatePhoneNumbers();
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
		Items.Move(Items.Send, CommandBar); 
		Items.RecipientDescriptionAndPhone.Group = ColumnsGroup.Vertical; 
		Items.Close.Visible = False; 
		Items.Move(Items.Close, CommandBar);
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TypeOfRecipientsPhoneOnChange(Item)
	PopulatePhoneNumbers();
EndProcedure

&AtClient
Procedure FilterSentOnChange(Item)
	SetFiltersInSMSDistributionResult();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRecipients

&AtClient
Procedure RecipientsSelection(Item, RowSelected, Field, StandardProcessing)

	Recipient = Items.Recipients.CurrentData.Recipient;

	If ValueIsFilled(Recipient) Then
		ShowValue( , Recipient);
	EndIf;

EndProcedure

&AtClient
Procedure RecipientsBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure RecipientsBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

#EndRegion

#Region TableItemsEventHandlerOfSMSDistributionResultForm

&AtClient
Procedure SMSDistributionResultSelection(Item, RowSelected, Field, StandardProcessing)
	
	Recipient = Items.SMSDistributionResult.CurrentData.Recipient;

	If ValueIsFilled(Recipient) Then
		ShowValue( , Recipient);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Send(Command)
	Items.Send.Visible = False;
	Items.Pages.CurrentPage = Items.PageRuntimeState;
	
	SMSDistributionResult.Clear();
	PreparedSMSMessages = New Array;
	UnsentCount = 0;
	For Each RowRecipients In Recipients Do
		
		If Not ValueIsFilled(RowRecipients.ArchivePassword) Or Not ValueIsFilled(RowRecipients.Phone) Then

			ResultRow = SMSDistributionResult.Add();
			ResultRow.Recipient = RowRecipients.Recipient;
			ResultRow.NotSent = True;

			If Not ValueIsFilled(RowRecipients.ArchivePassword) Then
				ResultRow.Comment = NStr("vi = 'Chưa đặt mật khẩu.';
										|ru = 'Не установлен пароль.';
										|en = 'A password is not set.'; fa = 'A password is not set.';
										|it = 'Не установлен пароль.';
										|pl = 'A password is not set.';
										|tr = 'Şifre ayarlanmadı.'");
			EndIf;

			If Not ValueIsFilled(RowRecipients.Phone) Then
				ResultRow.Comment = ?(ValueIsFilled(ResultRow.Comment),
					ResultRow.Comment + Chars.LF + NStr("vi = 'Chưa điền số điện thoại.';
														|ru = 'Не указан номер телефона.';
														|en = 'A phone number is not specified.'; fa = 'A phone number is not specified.';
														|it = 'Numero di telefono non indicato.';
														|pl = 'Nie podano numeru telefonu.';
														|tr = 'Telefon numarası belirtilmedi.'"), 
					NStr("vi = 'Chưa điền số điện thoại.';
						|ru = 'Не указан номер телефона.';
						|en = 'A phone number is not specified.'; fa = 'A phone number is not specified.';
						|it = 'Numero di telefono non indicato.';
						|pl = 'Nie podano numeru telefonu.';
						|tr = 'Telefon numarası belirtilmedi.'"));
			EndIf;

			StringResultNoFilters = SMSDistributionResultNoFilters.Add();
			FillPropertyValues(StringResultNoFilters, ResultRow);
			UnsentCount = UnsentCount + 1;
			Continue;
		EndIf;
		
		PrepareSMS = New Structure("Recipient, SMSMessageText, PhoneNumbers");
		PrepareSMS.Recipient = RowRecipients.Recipient;
		// ACC:1223-off - This is a text message.
		PrepareSMS.SMSMessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Mật khẩu của bạn: %1 để gửi hàng loạt ""%2"".';
			|ru = 'Ваш пароль: %1 для получения рассылки ""%2"".';
			|en = 'Your password: %1 to receive the ""%2"" report distribution.'; fa = 'Your password: %1 to receive the ""%2"" report distribution.';
			|it = 'Ваш пароль: %1 для получения рассылки ""%2"".';
			|pl = 'Your password: %1 to receive the ""%2"" report distribution.';
			|tr = '""%2"" dağıtımının alınması için şifreniz: %1.'"), RowRecipients.ArchivePassword,
		MailingDescription);
		// ACC:1223-on
		PrepareSMS.PhoneNumbers = CommonClientServer.ValueInArray(RowRecipients.Phone);
		PreparedSMSMessages.Add(PrepareSMS);
		
	EndDo;
	
	StartupParameters = New Structure("PreparedSMSMessages, UnsentCount, Form");
	StartupParameters.PreparedSMSMessages = PreparedSMSMessages;
	StartupParameters.Form = ThisObject;
	StartupParameters.UnsentCount = UnsentCount;
	
	ReportMailingClient.SendBulkSMSMessages(StartupParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetFiltersInSMSDistributionResult()
	
	TableSMSDistributionResultNoFilters = FormAttributeToValue("SMSDistributionResultNoFilters");

	Builder = New QueryBuilder;
	Builder.DataSource = New DataSourceDescription(TableSMSDistributionResultNoFilters);

	Filter = Builder.Filter;

	Sent = Filter.Add("NotSent");
	Sent.ComparisonType	= ComparisonType.Equal;
	Sent.Value		= ?(FilterSent = "SentMessages", False, True);
	Sent.Use	= ?(FilterSent = "All", False, True);

	Builder.Execute();
	ResultTable1 = 	Builder.Result.Unload();

	ValueToFormAttribute(ResultTable1, "SMSDistributionResult");
	
EndProcedure

&AtServer
Procedure PopulatePhoneNumbers()
	
	RecipientsTable = FormAttributeToValue("Recipients");
	ArrayOfRecipients_ = RecipientsTable.UnloadColumn("Recipient");
	
	RecipientsWithPhoneNumbers = ContactsManager.ObjectsContactInformation(ArrayOfRecipients_,
		Enums.ContactInformationTypes.Phone, TypeOfRecipientsPhone);
	
	If RecipientsWithPhoneNumbers.Count() = 0 Then
		Return;
	EndIf;
	
	For Each BulkEmailRecipient In Recipients Do
		FilterParameters = New Structure("Object", BulkEmailRecipient.Recipient);
		FoundStringsWithPhoneNumbers = RecipientsWithPhoneNumbers.FindRows(FilterParameters);
		If FoundStringsWithPhoneNumbers.Count() > 0 Then
			BulkEmailRecipient.Phone = FoundStringsWithPhoneNumbers[0].Presentation;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure DefineRecipientsPhoneKind()
	
	RecipientsMetadata = Common.MetadataObjectByID(MetadataObjectID, False);
	CIGroupName = StrReplace(RecipientsMetadata.FullName(), ".", "");
	CIGroup = ContactsManager.ContactInformationKindByName(CIGroupName);
	
	Query = New Query;
	Query.Text = "SELECT TOP 1 Ref FROM Catalog.ContactInformationKinds WHERE Parent = &Parent AND Type = &Type";
	Query.SetParameter("Parent", CIGroup);
	Query.Parameters.Insert("Type", Enums.ContactInformationTypes.Phone);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		TypeOfRecipientsPhone = Selection.Ref;
	EndIf;
	
EndProcedure

#EndRegion
