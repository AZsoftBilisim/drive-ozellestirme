///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

// Object value before it is written (intended for the "OnWrite" event handler).
Var IsNew, PreviousParent, PreviousComposition, IsFullUser;

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	VerifiedObjectAttributes = New Array;
	Errors = Undefined;
	
	// Check the parent.
	If Parent = Users.AllUsersGroup() Then
		CommonClientServer.AddUserError(Errors,
			"Object.Parent",
			NStr("vi = 'Nhóm ""Tất cả người sử dụng ngoài"" không thể là lớp trên.';
				|ru = 'Группа ""Все пользователи"" не может быть родителем.';
				|en = 'Cannot set the ""All users"" group as a parent.'; fa = 'Cannot set the ""All users"" group as a parent.';
				|it = 'Группа ""Все пользователи"" не может быть родителем.';
				|pl = 'Cannot set the ""All users"" group as a parent.';
				|tr = '""Tüm kullanıcılar"" grubu üst grup olamaz.'"),
			"");
	EndIf;
	
	// Checking for unfilled and duplicate users.
	VerifiedObjectAttributes.Add("Content.User");
	
	For Each CurrentRow In Content Do;
		LineNumber = Content.IndexOf(CurrentRow);
		
		// Check whether the value is filled.
		If Not ValueIsFilled(CurrentRow.User) Then
			CommonClientServer.AddUserError(Errors,
				"Object.Content[%1].User",
				NStr("vi = 'Chưa chọn người sử dụng.';
					|ru = 'Пользователь не выбран.';
					|en = 'User is not selected.'; fa = 'User is not selected.';
					|it = 'Utente non selezionato.';
					|pl = 'Nie wybrano użytkownika.';
					|tr = 'Kullanıcı seçilmedi.'"),
				"Object.Content",
				LineNumber,
				NStr("vi = 'Chưa chọn người sử dụng trong dòng %1.';
					|ru = 'Пользователь в строке %1 не выбран.';
					|en = 'User is not selected in line #%1.'; fa = 'User is not selected in line #%1.';
					|it = 'Utente nella riga %1 non selezionato.';
					|pl = 'Nie wybrano użytkownika w wierszu %1.';
					|tr = '#%1 satırında kullanıcı seçilmedi.'"));
			Continue;
		EndIf;
		
		// Checking for duplicate values.
		FoundValues = Content.FindRows(New Structure("User", CurrentRow.User));
		If FoundValues.Count() > 1 Then
			CommonClientServer.AddUserError(Errors,
				"Object.Content[%1].User",
				NStr("vi = 'Người sử dụng trùng lặp.';
					|ru = 'Пользователь повторяется.';
					|en = 'Duplicate user.'; fa = 'Duplicate user.';
					|it = 'L''utente si ripete.';
					|pl = 'Użytkownik powtarza się.';
					|tr = 'Kullanıcı tekrarlandı.'"),
				"Object.Content",
				LineNumber,
				NStr("vi = 'Người sử dụng tại dòng %1 bị trùng lặp.';
					|ru = 'Пользователь в строке %1 повторяется.';
					|en = 'Duplicate user in line #%1.'; fa = 'Duplicate user in line #%1.';
					|it = 'L''utente nella riga %1 si ripete.';
					|pl = 'Użytkownik w wierszu %1 powtarza się.';
					|tr = '%1 satırındaki kullanıcı tekrarlandı.'"));
		EndIf;
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, VerifiedObjectAttributes);
	
EndProcedure

// Cancels actions that cannot be performed on the "All users" group.
Procedure BeforeWrite(Cancel)
	
	// ACC:75-off - The DataExchange.Load check must follow the locking of registers.
	If Common.FileInfobase() Then
		UsersInternal.LockRegistersBeforeWritingToFileInformationSystem(True);
	EndIf;
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	IsNew = IsNew();
	IsFullUser = Users.IsFullUser();
	
	If Not IsNew Then
		PreviousValues1 = Common.ObjectAttributesValues(Ref,
			"Parent" + ?(IsFullUser, "", ", Content"));
		PreviousParent = PreviousValues1.Parent;
		PreviousComposition   = ?(IsFullUser,
			Undefined, PreviousValues1.Content.Unload());
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	AllUsersGroup = Users.AllUsersGroup();
	
	If Ref = AllUsersGroup Then
		If Not Parent.IsEmpty() Then
			ErrorText = NStr("vi = 'Nhóm ""Tất cả người sử dụng"" có thể chỉ ở gốc.';
							|ru = 'Группа ""Все пользователи"" может быть только в корне.';
							|en = 'The position of the ""All users"" group cannot be changed. It is the root of the group tree.'; fa = 'The position of the ""All users"" group cannot be changed. It is the root of the group tree.';
							|it = 'Группа ""Все пользователи"" может быть только в корне.';
							|pl = 'The position of the ""All users"" group cannot be changed. It is the root of the group tree.';
							|tr = '""Tüm kullanıcılar"" grubu yalnızca kökte olabilir.'");
			Raise ErrorText;
		EndIf;
		If Content.Count() > 0 Then
			ErrorText = NStr("vi = 'Cấm thêm người tham gia vào nhóm ""Tất cả người sử dụng"".';
							|ru = 'Добавление участников в группу ""Все пользователи"" запрещено.';
							|en = 'Cannot add members to the ""All users"" group.'; fa = 'Cannot add members to the ""All users"" group.';
							|it = 'Добавление участников в группу ""Все пользователи"" запрещено.';
							|pl = 'Cannot add members to the ""All users"" group.';
							|tr = '""Tüm kullanıcılar"" grubuna üye eklenmesine izin verilmiyor.'");
			Raise ErrorText;
		EndIf;
	Else
		If Parent = AllUsersGroup Then
			ErrorText = NStr("vi = 'Nhóm ""Tất cả người sử dụng ngoài"" không thể là lớp trên.';
							|ru = 'Группа ""Все пользователи"" не может быть родителем.';
							|en = 'Cannot set the ""All users"" group as a parent.'; fa = 'Cannot set the ""All users"" group as a parent.';
							|it = 'Группа ""Все пользователи"" не может быть родителем.';
							|pl = 'Cannot set the ""All users"" group as a parent.';
							|tr = '""Tüm kullanıcılar"" grubu üst grup olamaz.'");
			Raise ErrorText;
		EndIf;
	EndIf;
	
	If Not IsFullUser And Ref <> AllUsersGroup Then
		CompositionChange = UsersInternal.ColumnValueDifferences("User",
			Content.Unload(), PreviousComposition);
		CheckChangeCompositionRight(CompositionChange);
	EndIf;
	
	ChangesInComposition = UsersInternal.GroupsCompositionNewChanges();
	
	If Ref = AllUsersGroup Then
		UsersInternal.UpdateAllUsersGroupComposition(
			Catalogs.Users.EmptyRef(), ChangesInComposition);
	Else
		If PreviousParent <> Parent Then
			UsersInternal.UpdateGroupsHierarchy(Ref, ChangesInComposition, False);
			
			If ValueIsFilled(PreviousParent) Then
				UsersInternal.UpdateHierarchicalUserGroupCompositions(PreviousParent,
					ChangesInComposition);
			EndIf;
		EndIf;
		
		UsersInternal.UpdateHierarchicalUserGroupCompositions(Ref,
			ChangesInComposition);
	EndIf;
	
	UsersInternal.AfterUserGroupsUpdate(ChangesInComposition);
	
	SSLSubsystemsIntegration.AfterAddChangeUserOrGroup(Ref, IsNew);
	
	If Common.SubsystemExists(
		"StandardSubsystems.SaaSOperations.AccessManagementSaaS") Then
		ModuleAccessManagementInternalSaaS = Common.CommonModule(
			"AccessManagementInternalSaaS");
		ModuleAccessManagementInternalSaaS.SendUserGroupChangeMessage(ThisObject);
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	UsersInternal.UpdateGroupsCompositionBeforeDeleteUserOrGroup(Ref);
	
	If Common.SubsystemExists(
		"StandardSubsystems.SaaSOperations.AccessManagementSaaS") Then
		ModuleAccessManagementInternalSaaS = Common.CommonModule(
			"AccessManagementInternalSaaS");
		ModuleAccessManagementInternalSaaS.SendUserGroupChangeMessage(
			ThisObject, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckChangeCompositionRight(CompositionChange)
	
	If Not ValueIsFilled(CompositionChange) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Users", CompositionChange);
	Query.Text =
	"SELECT
	|	Users.Description AS Description
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Ref IN(&Users)
	|	AND NOT Users.Prepared";
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	UsersContent = QueryResult.Unload().UnloadColumn("Description");
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không đủ quyền truy cập để thay đổi:
		           |%1
		           |
		           |Trong thành phần người tham gia nhóm người sử dụng, có thể đưa vào và loại trừ
		           |chỉ những người sử dụng mới mà vẫn chưa được người quản trị phê duyệt
		           |(nghĩa là, người quản trị vẫn chưa được phép đăng nhập vào ứng dụng).';
		           |ru = 'Недостаточно прав доступа для изменения:
		           |%1
		           |
		           |В состав участников групп пользователей можно включать и исключать
		           |только новых пользователей, которые еще не одобрены администратором
		           |(то есть администратор еще не разрешил вход в приложение).';
		           |en = 'Insufficient access rights to modify:
		           |%1
		           |
		           |Only new users who have not yet been approved by the administrator
		           |can be included in or excluded from user groups
		           |(that is, the administrator has not yet allowed users to log in).'; fa = 'Insufficient access rights to modify:
		           |%1
		           |
		           |Only new users who have not yet been approved by the administrator
		           |can be included in or excluded from user groups
		           |(that is, the administrator has not yet allowed users to log in).';
		           |it = 'Недостаточно прав доступа для изменения:
		           |%1
		           |
		           |В состав участников групп пользователей можно включать и исключать
		           |только новых пользователей, которые еще не одобрены администратором
		           |(то есть администратор еще не разрешил вход в приложение).';
		           |pl = 'Insufficient access rights to modify:
		           |%1
		           |
		           |Only new users who have not yet been approved by the administrator
		           |can be included in or excluded from user groups
		           |(that is, the administrator has not yet allowed users to log in).';
		           |tr = 'Değiştirmek için yetersiz izinler:
		           |%1
		           |
		           |Kullanıcı gruplarının üyeleri dahil edilebilir ve hariç tutulabilir
		           |yalnızca yönetici tarafından henüz onaylanmamış yeni kullanıcılar
		           |(yani, yönetici henüz programa girişe izin vermemiştir).'"),
		StrConcat(UsersContent, Chars.LF));
	Raise(ErrorText, ErrorCategory.AccessViolation);
	
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf