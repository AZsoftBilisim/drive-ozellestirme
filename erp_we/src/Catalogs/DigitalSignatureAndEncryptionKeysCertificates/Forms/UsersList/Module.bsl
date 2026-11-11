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
	
	CertificateUsers = Parameters.Users;
	CertificateRecipient = Parameters.User;
	DisplayMode = Parameters.DisplayMode;
	
	If CertificateUsers = Undefined Then
		CertificateUsers = New Array;
	EndIf;
	
	If CertificateUsers.Count() > 0
		Or CertificateRecipient <> Users.CurrentUser()
		Or Not ValueIsFilled(CertificateRecipient) Then
		ChoiceMode = "UsersList";
	Else
		ChoiceMode = "JustForMe";
	EndIf;
	
	FillInTheFullList(CertificateUsers, CertificateRecipient);
	FormControl(ThisObject);
	ConfigureConditionalFormatting();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChoiceModeOnChange(Item)
	
	FormControl(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsersTable

&AtClient
Procedure UsersTableNoKeyUsedOnChange(Item)
	
	CurrentData = Items.UsersTable.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.Check = False Then
		CurrentData.NoKeyUsed = Not CurrentData.NoKeyUsed;
		ShowMessageBox(, NStr("ru = 'Необходимо сначала выбрать пользователя.';
								|vi = 'First, select a user.';
								|en = 'First, select a user.'; fa = 'First, select a user.';
								|it = 'First, select a user.';
								|pl = 'First, select a user.';
								|tr = 'Önce kullanıcı seçilmelidir.'"));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedUsers

&AtClient
Procedure SelectedUsersBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	PickingParameters = New Structure;
	PickingParameters.Insert("ChoiceMode", True);
	PickingParameters.Insert("CloseOnChoice", False);
	PickingParameters.Insert("MultipleChoice", True);
	PickingParameters.Insert("AdvancedPick", True);
	PickingParameters.Insert("HideUsersWithoutMatchingIBUsers", True);
	
	Selected_ = New Array;
	For Each String In SelectedUsers Do
		Selected_.Add(String.User);
	EndDo;
	
	PickingParameters.Insert("SelectedUsers", Selected_);
	PickingParameters.Insert("PickFormHeader",
		NStr("vi = 'Chọn người dùng mà họ có chứng chỉ sẽ có trong danh sách lựa chọn';
			|ru = 'Выберите пользователей, у которых сертификат будет доступен в списке выбора';
			|en = 'Select users who will see the certificate in the choice list'; fa = 'Select users who will see the certificate in the choice list';
			|it = 'Выберите пользователей, у которых сертификат будет доступен в списке выбора';
			|pl = 'Select users who will see the certificate in the choice list';
			|tr = 'Seçim listesinde sertifikası mevcut olacak kullanıcıları seçin'"));
	PickingParameters.Insert("PickingCompletionButtonTitle", NStr("vi = 'Chọn';
																	|ru = 'Выбрать';
																	|en = 'Select'; fa = 'انتخاب';
																	|it = 'Выбрать';
																	|pl = 'Select';
																	|tr = 'Seç'"));
	
	Handler = New CallbackDescription("Add_Users", ThisObject);
	
	OpenForm("Catalog.Users.ChoiceForm", PickingParameters,,,,, Handler);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If DisplayMode Then
		Result = Undefined;
	Else	
		Result = New Structure;
		Result.Insert("Users", New Array);
		Result.Insert("User", PredefinedValue("Catalog.Users.EmptyRef"));
		
		If ChoiceMode = "UsersList" Then
			If Items.UsersTable.Visible Then
				For Each UserRow1 In UsersTable Do
					If UserRow1.Check Then
						UserData = New Structure("User, NoKeyUsed");
						FillPropertyValues(UserData, UserRow1);
						Result.Users.Add(UserData);
					EndIf;
				EndDo;
			Else
				For Each UserRow1 In SelectedUsers Do
					UserData = New Structure("User, NoKeyUsed");
					FillPropertyValues(UserData, UserRow1);
					Result.Users.Add(UserData);
				EndDo;
			EndIf;
		Else
			Result.User = UsersClient.CurrentUser();
		EndIf;
		If Result.Users.Count() = 1 Then
			Result.User = Result.Users[0].User;
		EndIf;
	EndIf;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure CancelCheck(Command)
	
	ChangeTheListLabels(False);
	
EndProcedure

&AtClient
Procedure SelectAllItems(Command)
	
	ChangeTheListLabels(True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Add_Users(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	SelectedUsers.Clear();
	For Each User In Result Do
		NewRow = SelectedUsers.Add();
		NewRow.User = User;
		If User = CertificateRecipient Then
			NewRow.Main = True;
		EndIf;
	EndDo;

EndProcedure

&AtClient
Procedure ChangeTheListLabels(CheckMarkValue)
	
	For Each UserRow1 In UsersTable Do
		UserRow1.Check = CheckMarkValue;
	EndDo;
	
EndProcedure

&AtServer
Procedure ConfigureConditionalFormatting()
	
	If Items.UsersTable.Visible Then
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("BackColor");
		AppearanceColorItem.Value = StyleColors.AddedAttributeBackground;
		AppearanceColorItem.Use = True;
		
		DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		DataFilterItem.LeftValue  = New DataCompositionField("UsersTable.Main");
		DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
		DataFilterItem.RightValue = True;
		DataFilterItem.Use  = True;
		
		DesignFieldElement = ConditionalAppearanceItem.Fields.Items.Add();
		DesignFieldElement.Field = New DataCompositionField("UsersTable");
		DesignFieldElement.Use = True;
	EndIf;
	
	If Items.UsersTable.Visible Then
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("BackColor");
		AppearanceColorItem.Value = StyleColors.AddedAttributeBackground;
		AppearanceColorItem.Use = True;
		
		DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		DataFilterItem.LeftValue  = New DataCompositionField("SelectedUsers.Main");
		DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
		DataFilterItem.RightValue = True;
		DataFilterItem.Use  = True;
		
		DesignFieldElement = ConditionalAppearanceItem.Fields.Items.Add();
		DesignFieldElement.Field = New DataCompositionField("SelectedUsers");
		DesignFieldElement.Use = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInTheFullList(CertificateUsers, CertificateRecipient)
	
	UsersArray = New Array;
	If CertificateUsers <> Undefined Then
		UsersArray = CertificateUsers;
	ElsIf ValueIsFilled(CertificateRecipient) And ChoiceMode = "UsersList" Then
		AddingOptions = New Structure("User, NoKeyUsed", CertificateRecipient, False);
		UsersArray.Add(AddingOptions);
	EndIf;
	
	UsersParameter = New Array;
	For Each UserData In UsersArray Do
		UsersParameter.Add(UserData.User);
	EndDo;
	
	QueryText = 
	"SELECT ALLOWED
	|	Users.Ref AS User,
	|	CASE
	|		WHEN Users.Ref IN (&Users)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Check,
	|	CASE
	|		WHEN Users.Ref = &CertificateRecipient
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Main
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	(NOT Users.DeletionMark
	|				AND NOT Users.Invalid
	|				AND (NOT Users.IsInternal
	|						AND Users.IBUserID <> &EmptyIDOfTheIBUser
	|					OR Users.Ref = &CurrentUser)
	|			OR Users.Ref IN (&Users))
	|
	|ORDER BY
	|	Users.Description";
	
	Query = New Query(QueryText);
	Query.SetParameter("Users", UsersParameter);
	Query.SetParameter("CurrentUser", Users.AuthorizedUser());
	Query.SetParameter("EmptyIDOfTheIBUser", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("CertificateRecipient", CertificateRecipient);
	
	Result = Query.Execute().Unload();
	SelectedUsers.Clear();
	
	If Result.Count() > 30 Then
		SelectedUsers.Clear();
		For Each UserData In UsersArray Do
			NewRow = SelectedUsers.Add();
			FillPropertyValues(NewRow, UserData);
			If UserData.User = CertificateRecipient Then
				NewRow.Main = True;
			EndIf;
		EndDo;
		Items.UsersTable.Visible = False;
		Items.SelectedUsers.Visible = True;
	Else
		UsersTable.Load(Result);
		For Each UserData In UsersArray Do
			SearchParameters = New Structure;
			SearchParameters.Insert("User", UserData.User);
			TableRow = UsersTable.FindRows(SearchParameters);
			If TableRow.Count() > 0 Then
				TableRow[0].NoKeyUsed = UserData.NoKeyUsed;
			EndIf;
		EndDo;
		Items.UsersTable.Visible = True;
		Items.SelectedUsers.Visible = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(TheFormContext)
	
	FormItems = TheFormContext.Items;
	
	If TheFormContext.DisplayMode Then
		FormItems.UsersTable.ReadOnly = True;
		FormItems.SelectedUsers.ReadOnly = True;
		FormItems.ChoiceMode.ReadOnly = True;
		FormItems.SelectionMethodList.ReadOnly = True;
	Else	
		FormItems.UsersTable.ReadOnly = Not TheFormContext.ChoiceMode = "UsersList";
		FormItems.SelectedUsers.ReadOnly = Not TheFormContext.ChoiceMode = "UsersList";
	EndIf;	
	
	FormItems.UsersSelectAll.Enabled = Not FormItems.UsersTable.ReadOnly;
	FormItems.UsersCancelCheck.Enabled = Not FormItems.UsersTable.ReadOnly;
		
EndProcedure

#EndRegion
