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
	SetConditionalAppearance();
	
	FillPropertyValues(ThisObject, Parameters, "MailingRecipientType, RecipientsEmailAddressKind");
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Người nhận E-mail (%1)';
			|ru = 'Получатели рассылки (%1)';
			|en = 'Report recipients (%1)'; fa = 'Report recipients (%1)';
			|it = 'Destinatari di newsletter (%1)';
			|pl = 'Adresacji subskrypcji (%1)';
			|tr = 'Bülten alıcıları (%1)'"),
		Parameters.MailingDescription);
	
	For Each TableRow In Parameters.Recipients Do
		NewRow = Recipients.Add();
		NewRow.Recipient = TableRow.Recipient;
		NewRow.Excluded = TableRow.Excluded;
	EndDo;
	
	Items.RecipientsRecipient.TypeRestriction = MailingRecipientType;
	
	FillRecipientsTypeInfo(Cancel);
	FillMailAddresses();
	
	If Not Common.SubsystemExists("StandardSubsystems.ImportDataFromFile") Then
		Items.PasteFromClipboard.Visible = False;
	EndIf;
	
	RefreshRecipientCount(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RecipientsEmailAddressKindOnChange(Item)
	FillMailAddresses();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRecipients

&AtClient
Procedure PickRecipients(Command)
	OpenAddRecipientsForm(True);
EndProcedure

&AtClient
Procedure OpenAddRecipientsForm(IsPick)
	SelectedUsers = New Array;
	For Each String In Recipients Do
		SelectedUsers.Add(String.Recipient);
	EndDo;
	
	ChoiceFormParameters = New Structure;
	
	// Standard attributes of the choice form. See "Client application form extension for dynamic lists" in Syntax Assistant.
	ChoiceFormParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.FoldersAndItems);
	ChoiceFormParameters.Insert("CloseOnChoice", ?(IsPick, False, True));
	ChoiceFormParameters.Insert("CloseOnOwnerClose", True);
	ChoiceFormParameters.Insert("MultipleChoice", IsPick);
	ChoiceFormParameters.Insert("ChoiceMode", True);
	
	// Expected attributes.
	ChoiceFormParameters.Insert("WindowOpeningMode", FormWindowOpeningMode.LockOwnerWindow);
	ChoiceFormParameters.Insert("SelectGroups", True);
	ChoiceFormParameters.Insert("UsersGroupsSelection", True);
	
	// Extended pick form opening parameters.
	// See the "Users" catalog list form for the attribute description.
	If IsPick Then
		ChoiceFormParameters.Insert("AdvancedPick", True);
		ChoiceFormParameters.Insert("PickFormHeader", NStr("vi = 'Chọn người nhận để gửi';
															|ru = 'Подбор получателей рассылки';
															|en = 'Pick recipients'; fa = 'Pick recipients';
															|it = 'Selezione di destinatari di newsletter';
															|pl = 'Wybór odbiorców subskrypcji';
															|tr = 'Bülten alıcı seçimi'"));
		ChoiceFormParameters.Insert("SelectedUsers", SelectedUsers);
	EndIf;
	
	OpenForm(ChoiceFormPath, ChoiceFormParameters, Items.Recipients);
EndProcedure

&AtClient
Procedure RecipientsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	AddDragRecipient(ValueSelected);
	RefreshRecipientCount(ThisObject);
EndProcedure

&AtClient
Procedure RecipientsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	Cancel = True;
	OpenAddRecipientsForm(False);
EndProcedure

&AtClient
Procedure RecipientsExcludedOnChange(Item)
	RefreshRecipientCount(ThisObject);
EndProcedure

&AtClient
Procedure RecipientsAfterDeleteRow(Item)
	RefreshRecipientCount(ThisObject);
EndProcedure

&AtClient
Procedure RecipientsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	If Not ValueIsFilled(Item.CurrentData.Recipient) Then
		Cancel = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	Result = New Structure;
	Result.Insert("Recipients", Recipients);
	Result.Insert("RecipientsEmailAddressKind", RecipientsEmailAddressKind);
	Close(Result);
EndProcedure

&AtClient
Procedure PasteFromClipboard(Command)
	SearchParameters = New Structure;
	SearchParameters.Insert("TypeDescription", MailingRecipientType);
	SearchParameters.Insert("ChoiceParameters", Undefined);
	SearchParameters.Insert("FieldPresentation", "Recipients");
	SearchParameters.Insert("Scenario", "RefsSearch");
	
	ExecutionParameters = New Structure;
	Handler = New CallbackDescription("PasteFromClipboardCompletion", ThisObject, ExecutionParameters);
	
	ModuleDataImportFromFileClient = CommonClient.CommonModule("ImportDataFromFileClient");
	ModuleDataImportFromFileClient.ShowRefFillingForm(SearchParameters, Handler);
EndProcedure

&AtClient
Procedure SelectCheckBoxes(Command)
	
	For Each Recipient In Recipients Do
		Recipient.Excluded = True;
	EndDo;
	
	RefreshRecipientCount(ThisObject);
	
EndProcedure

&AtClient
Procedure ClearCheckBoxes(Command)
	
	For Each Recipient In Recipients Do
		Recipient.Excluded = False;
	EndDo;
	
	RefreshRecipientCount(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AddDragRecipient(RecipientOrRecipientsSet)
	// Delete users who have been deleted in the pickup form or who are already in the list.
	If IsPickupUsersOrGroup(RecipientOrRecipientsSet) Then
		Count = Recipients.Count();
		For Number = 1 To Count Do
			ReverseIndex = Count - Number;
			RecipientRow = Recipients.Get(ReverseIndex);
			
			IndexInArray = RecipientOrRecipientsSet.Find(RecipientRow.Recipient);
			If IndexInArray = Undefined Then
				Recipients.Delete(RecipientRow); // User is deleted in the pickup form.
			Else
				RecipientOrRecipientsSet.Delete(IndexInArray); // User is already in the list.
			EndIf;
		EndDo;
	EndIf;
	
	// Add selected rows.
	NewRowArray = ChoicePickupDragToTabularSection(RecipientOrRecipientsSet);
	
	// Prepare notification text.
	If NewRowArray.Count() > 0 Then
		If NewRowArray.Count() = 1 Then
			NotificationTitle = NStr("vi = 'Người nhận đã thêm vào danh sách gửi đi';
									|ru = 'Получатель добавлен в рассылку';
									|en = 'The user is added to the recipient list.'; fa = 'The user is added to the recipient list.';
									|it = 'Destinatario aggiunto alla newsletter';
									|pl = 'Odbiorca został dodany do subskrypcji';
									|tr = 'Alıcı bültene eklendi'");
		Else
			NotificationTitle = NStr("vi = 'Người nhận đã thêm vào danh sách gửi đi';
									|ru = 'Получатели добавлены в рассылку';
									|en = 'The users are added to the recipient list.'; fa = 'The users are added to the recipient list.';
									|it = 'Destinatari aggiunti alla newsletter';
									|pl = 'Odbiorcy zostali dodani do subskrypcji';
									|tr = 'Bültene eklenen alıcılar'");
		EndIf;
		
		NotificationText1 = "";
		For Each RecipientRow In NewRowArray Do
			NotificationText1 = NotificationText1 + ?(NotificationText1 = "", "", ", ") + RecipientRow;
		EndDo;
		ShowUserNotification(NotificationTitle,, NotificationText1, PictureLib.ExecuteTask);
		
		FillMailAddresses();
	EndIf;
EndProcedure

&AtClient
Function IsPickupUsersOrGroup(RecipientOrRecipientsSet)
	Return TypeOf(RecipientOrRecipientsSet) = Type("Array")
		And MailingRecipientType.ContainsType(Type("CatalogRef.Users"));
EndFunction

&AtClient
Function ChoicePickupDragToTabularSection(ValueSelected)
	NewRowArray = New Array;
	If TypeOf(ValueSelected) = Type("Array") Then
		For Each PickingItem In ValueSelected Do
			Result = ChoicePickupDragItemToTabularSection(PickingItem);
			AddValueToNotificationArray(Result, NewRowArray);
		EndDo;
	Else
		Result = ChoicePickupDragItemToTabularSection(ValueSelected);
		AddValueToNotificationArray(Result, NewRowArray);
	EndIf;
	Return NewRowArray;
EndFunction

&AtClient
Procedure AddValueToNotificationArray(Text, NewRowArray)
	If ValueIsFilled(Text) Then
		NewRowArray.Add(Text);
	EndIf;
EndProcedure

&AtClient
Function ChoicePickupDragItemToTabularSection(AttributeValue)
	Filter = New Structure("Recipient", AttributeValue);
	FoundRows = Recipients.FindRows(Filter);
	
	If FoundRows.Count() > 0 Then
		Return Undefined;
	EndIf;
	
	String = Recipients.Add();
	String.Recipient = AttributeValue;
	
	Return AttributeValue;
EndFunction

&AtClient
Procedure PasteFromClipboardCompletion(Result, Parameter) Export

	If Result <> Undefined Then 
		For Each Recipient In Result Do 
			NewRow = Recipients.Add();
			NewRow.Recipient = Recipient;
		EndDo;
		
		FillMailAddresses();
	EndIf;
	

EndProcedure

&AtServer
Procedure FillMailAddresses()
	
	RecipientsParameters = ReportMailingClientServer.RecipientsParameters();
	FillPropertyValues(RecipientsParameters, ThisObject);
	RecipientsParameters.Personal = False;
	RecipientsParameters.MailingRecipientType = MetadataObjectID;
	RecipientsParameters.Recipients = Recipients;
	
	RecipientsMetadata = Common.MetadataObjectByID(MetadataObjectID, False);
	If RecipientsMetadata.Hierarchical And RecipientsMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
		ArrayOfRecipients_ = New Array;
		For Each BulkEmailRecipient In Recipients Do
			ArrayOfRecipients_.Add(BulkEmailRecipient.Recipient);
		EndDo;
		RecipientsAttributeIsGroup = Common.ObjectsAttributeValue(ArrayOfRecipients_, "IsFolder");
	Else
		RecipientsAttributeIsGroup = Undefined;
	EndIf;
	
	BulkEmailRecipients = ReportMailing.GenerateMailingRecipientsList(RecipientsParameters);
	For Each BulkEmailRecipient In Recipients Do
		If BulkEmailRecipients.Count() = 0 Then
			If BulkEmailRecipient.Recipient = Undefined Then 
				Continue;
			EndIf;
		Else	
			RecipientEmailAddr = BulkEmailRecipients.Get(BulkEmailRecipient.Recipient);
			BulkEmailRecipient.Address = ?(RecipientEmailAddr <> Undefined, RecipientEmailAddr, "")
		EndIf;
		IsFolder = ?(RecipientsAttributeIsGroup <> Undefined, RecipientsAttributeIsGroup.Get(BulkEmailRecipient.Recipient), False);
		IsFolder = ?(IsFolder <> Undefined, IsFolder, False);
		If IsFolder Or TypeOf(BulkEmailRecipient.Recipient) = Type("CatalogRef.UserGroups") Then
			BulkEmailRecipient.PictureIndex = 3;
		Else
			BulkEmailRecipient.PictureIndex = 1;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RecipientsRecipient.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RecipientsExcluded.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Recipients.Excluded");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", Metadata.StyleItems.OverdueDataColor.Value);

EndProcedure

&AtServer
Procedure FillRecipientsTypeInfo(Cancel)
	RecipientsTypesTable = ReportMailingCached.RecipientsTypesTable();
	FoundItems = RecipientsTypesTable.FindRows(New Structure("RecipientsType", MailingRecipientType));
	If FoundItems.Count() = 1 Then
		RecipientRow = FoundItems[0];
		MetadataObjectID            = RecipientRow.MetadataObjectID;
		ChoiceFormPath                           = RecipientRow.ChoiceFormPath;
		ContactInformationOfRecipientsTypeGroup = RecipientRow.CIGroup;
		// CI group is used for the RecipientsEmailAddressKind field in the ChoiceParameterLinks.Filter.
	Else
		Cancel = True;
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Procedure RefreshRecipientCount(Form)
	
	RecipientsParameters = ReportMailingClientServer.RecipientsParameters();
	FillPropertyValues(RecipientsParameters, Form);
	RecipientsParameters.Personal = False;
	RecipientsParameters.MailingRecipientType = Form.MetadataObjectID;

	NumberOfRecipients = RecipientsCountIncludingGroups(RecipientsParameters);

	Form.ResultTotalCount = NumberOfRecipients.Total;
	If NumberOfRecipients.ExcludedCount <> Undefined Then
		Form.ResultExcludedCount = NumberOfRecipients.ExcludedCount;
		Form.Items.ResultExcludedCount.Visible = True;
	Else
		Form.ResultExcludedCount = 0;
		Form.Items.ResultExcludedCount.Visible = False;
	EndIf;

EndProcedure

&AtServerNoContext
Function RecipientsCountIncludingGroups(Val RecipientsParameters)

	Return Catalogs.ReportMailings.RecipientsCountIncludingGroups(RecipientsParameters);

EndFunction

#EndRegion