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
Var IsNew, PreviousParent, PreviousAllAuthorizationObjects, PreviousRolesSet;

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If AdditionalProperties.Property("VerifiedObjectAttributes") Then
		VerifiedObjectAttributes = AdditionalProperties.VerifiedObjectAttributes;
	Else
		VerifiedObjectAttributes = New Array;
	EndIf;
	
	Errors = Undefined;
	
	// Check the parent.
	ErrorText = ParentCheckErrorText();
	If ValueIsFilled(ErrorText) Then
		CommonClientServer.AddUserError(Errors,
			"Object.Parent", ErrorText, "");
	EndIf;
	
	// Checking for unfilled and duplicate external users.
	VerifiedObjectAttributes.Add("Content.ExternalUser");
	
	// Check the group purpose.
	ErrorText = PurposeCheckErrorText();
	If ValueIsFilled(ErrorText) Then
		CommonClientServer.AddUserError(Errors,
			"Object.Purpose", ErrorText, "");
	EndIf;
	VerifiedObjectAttributes.Add("Purpose");
	
	For Each CurrentRow In Content Do
		LineNumber = Content.IndexOf(CurrentRow);
		
		// Check whether the value is filled.
		If Not ValueIsFilled(CurrentRow.ExternalUser) Then
			CommonClientServer.AddUserError(Errors,
				"Object.Content[%1].ExternalUser",
				NStr("vi = 'Chưa chọn người sử dụng ngoài.';
					|ru = 'Внешний пользователь не выбран.';
					|en = 'The external user is not specified.'; fa = 'The external user is not specified.';
					|it = 'L''utente esterno non è selezionato.';
					|pl = 'Nie wybrano użytkownika zewnętrznego.';
					|tr = 'Dış kullanıcı seçilmedi.'"),
				"Object.Content",
				LineNumber,
				NStr("vi = 'Chưa chọn người sử dụng ngoài trong dòng %1.';
					|ru = 'Внешний пользователь в строке %1 не выбран.';
					|en = 'The external user is not specified in line #%1.'; fa = 'The external user is not specified in line #%1.';
					|it = 'L''utente esterno nella riga %1 non è selezionato.';
					|pl = 'Nie wybrano użytkownika zewnętrznego w wierszu %1.';
					|tr = '%1Satırında dış kullanıcı seçilmedi.'"));
			Continue;
		EndIf;
		
		// Checking for duplicate values.
		FoundValues = Content.FindRows(New Structure("ExternalUser", CurrentRow.ExternalUser));
		If FoundValues.Count() > 1 Then
			CommonClientServer.AddUserError(Errors,
				"Object.Content[%1].ExternalUser",
				NStr("vi = 'Người sử dụng ngoài trùng lặp.';
					|ru = 'Внешний пользователь повторяется.';
					|en = 'Duplicate external user.'; fa = 'Duplicate external user.';
					|it = 'L''utente esterno viene ripetuto.';
					|pl = 'Użytkownik zewnętrzny powtarza się.';
					|tr = 'Dış kullanıcı tekrarlandı.'"),
				"Object.Content",
				LineNumber,
				NStr("vi = 'Người sử dụng ngoài bị trùng lặp trong dòng %1.';
					|ru = 'Внешний пользователь в строке %1 повторяется.';
					|en = 'Duplicate external user in line #%1.'; fa = 'Duplicate external user in line #%1.';
					|it = 'L''utente esterno nella riga %1 viene ripetuto.';
					|pl = 'Użytkownik zewnętrzny w wierszu %1 powtarza się.';
					|tr = '%1Satırında dış kullanıcı tekrarlandı.'"));
		EndIf;
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, VerifiedObjectAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	// ACC:75-off - The DataExchange.Load check must follow the locking of registers.
	If Common.FileInfobase() Then
		UsersInternal.LockRegistersBeforeWritingToFileInformationSystem(True);
	EndIf;
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not UsersInternal.CannotEditRoles() Then
		QueryResult = Common.ObjectAttributeValue(Ref, "Roles");
		If TypeOf(QueryResult) = Type("QueryResult") Then
			PreviousRolesSet = QueryResult.Unload();
		Else
			PreviousRolesSet = Roles.Unload(New Array);
		EndIf;
	EndIf;
	
	IsNew = IsNew();
	
	If Ref = ExternalUsers.AllExternalUsersGroup() Then
		FillPurposeWithAllExternalUsersTypes();
		AllAuthorizationObjects = False;
	EndIf;
	
	If Not IsNew Then
		PreviousValues1 = Common.ObjectAttributesValues(Ref,
			"Parent, AllAuthorizationObjects");
		PreviousAllAuthorizationObjects = PreviousValues1.AllAuthorizationObjects;
		PreviousParent              = PreviousValues1.Parent;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If UsersInternal.CannotEditRoles() Then
		IsExternalUserGroupRoleCompositionChanged = False;
	Else
		IsExternalUserGroupRoleCompositionChanged =
			UsersInternal.ColumnValueDifferences("Role",
				Roles.Unload(), PreviousRolesSet).Count() <> 0;
	EndIf;
	
	AllExternalUsersGroup = ExternalUsers.AllExternalUsersGroup();
	
	ErrorText = ParentCheckErrorText(AllExternalUsersGroup);
	If ValueIsFilled(ErrorText) Then
		Raise ErrorText;
	EndIf;
	
	If Ref = AllExternalUsersGroup Then
		If Not Parent.IsEmpty() Then
			ErrorText = NStr("vi = 'Nhóm ""Tất cả người sử dụng ngoài"" có thể chỉ ở gốc.';
							|ru = 'Группа ""Все внешние пользователи"" может быть только в корне.';
							|en = 'The position of the ""All external users"" group cannot be changed. It is the root of the group tree.'; fa = 'The position of the ""All external users"" group cannot be changed. It is the root of the group tree.';
							|it = 'Группа ""Все внешние пользователи"" может быть только в корне.';
							|pl = 'The position of the ""All external users"" group cannot be changed. It is the root of the group tree.';
							|tr = '""Tüm harici kullanıcılar"" grubu yalnızca kökte bulunabilir.'");
			Raise ErrorText;
		EndIf;
		If Content.Count() > 0 Then
			ErrorText = NStr("vi = 'Cấm thêm người tham gia vào nhóm ""Tất cả người sử dụng ngoài"".';
							|ru = 'Добавление участников в группу ""Все внешние пользователи"" запрещено.';
							|en = 'Cannot add members to the ""All external users"" group. '; fa = 'Cannot add members to the ""All external users"" group. ';
							|it = 'Добавление участников в группу ""Все внешние пользователи"" запрещено.';
							|pl = 'Cannot add members to the ""All external users"" group. ';
							|tr = '""Tüm harici kullanıcılar"" grubuna üye eklenmesine izin verilmiyor.'");
			Raise ErrorText;
		EndIf;
	Else
		ErrorText = PurposeCheckErrorText();
		If ValueIsFilled(ErrorText) Then
			Raise ErrorText;
		EndIf;
	EndIf;
	
	ChangesInComposition = UsersInternal.GroupsCompositionNewChanges();
	
	If Ref = AllExternalUsersGroup Then
		UsersInternal.UpdateAllUsersGroupComposition(
			Catalogs.ExternalUsers.EmptyRef(), ChangesInComposition);
		
	ElsIf AllAuthorizationObjects Then
		UsersInternal.UpdateGroupCompositionsByAuthorizationObjectType(Ref,
			Undefined, ChangesInComposition);
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
	
	If IsExternalUserGroupRoleCompositionChanged Then
		UsersInternal.UpdateExternalUsersRoles(Ref);
	EndIf;
	
	SSLSubsystemsIntegration.AfterAddChangeUserOrGroup(Ref, IsNew);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	UsersInternal.UpdateGroupsCompositionBeforeDeleteUserOrGroup(Ref);
	
EndProcedure

#EndRegion

#Region Private

Procedure FillPurposeWithAllExternalUsersTypes()
	
	Purpose.Clear();
	
	BlankRefs = UsersInternalCached.BlankRefsOfAuthorizationObjectTypes();
	For Each EmptyRef In BlankRefs Do
		NewRow = Purpose.Add();
		NewRow.UsersType = EmptyRef;
	EndDo;
	
EndProcedure

Function ParentCheckErrorText(AllExternalUsersGroup = Undefined)
	
	If AllExternalUsersGroup = Undefined Then
		AllExternalUsersGroup = ExternalUsers.AllExternalUsersGroup();
	EndIf;
	
	If Parent = AllExternalUsersGroup Then
		Return NStr("vi = 'Nhóm ""Tất cả người sử dụng ngoài"" không thể là lớp trên.';
					|ru = 'Группа ""Все внешние пользователи"" не может быть родителем.';
					|en = 'Cannot set the ""All external users"" group as a parent.'; fa = 'Cannot set the ""All external users"" group as a parent.';
					|it = 'Группа ""Все внешние пользователи"" не может быть родителем.';
					|pl = 'Cannot set the ""All external users"" group as a parent.';
					|tr = '""Tüm harici Kullanıcılar"" grubu üst grup olamaz.'");
	EndIf;
	
	If Ref = AllExternalUsersGroup Then
		If Not Parent.IsEmpty() Then
			Return NStr("vi = 'Nhóm ""Tất cả người sử dụng ngoài"" không thể là lớp trên.';
						|ru = 'Группа ""Все внешние пользователи"" не может быть перемещена.';
						|en = 'Cannot move the ""All external users"" group.'; fa = 'Cannot move the ""All external users"" group.';
						|it = 'Группа ""Все внешние пользователи"" не может быть перемещена.';
						|pl = 'Cannot move the ""All external users"" group.';
						|tr = '""Tüm harici kullanıcılar"" grubu taşınamaz.'");
		EndIf;
	Else
		If Parent = AllExternalUsersGroup Then
			Return NStr("vi = 'Không thể thêm nhóm con vào nhóm ""Tất cả người sử dụng ngoài"".';
						|ru = 'Невозможно добавить подгруппу в группу ""Все внешние пользователи"".';
						|en = 'Cannot add a subgroup to the ""All external users"" group. '; fa = 'Cannot add a subgroup to the ""All external users"" group. ';
						|it = 'Невозможно добавить подгруппу в группу ""Все внешние пользователи"".';
						|pl = 'Cannot add a subgroup to the ""All external users"" group. ';
						|tr = '""Tüm harici kullanıcılar"" grubuna alt grup ekleyemezsiniz.'");
			
		ElsIf Common.ObjectAttributeValue(Parent, "AllAuthorizationObjects") = True Then
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể thêm nhóm con vào nhóm ""%1"",
				           |bởi vì nhóm có bao gồm tất cả người sử dụng của dạng đã chỉ ra.';
				           |ru = 'Невозможно добавить подгруппу в группу ""%1"",
				           |так как в нее входят все внешние пользователи указанного вида.';
				           |en = 'Cannot add a subgroup to group ""%1"" as
				           |it contains all external users of the specified types.'; fa = 'Cannot add a subgroup to group ""%1"" as
				           |it contains all external users of the specified types.';
				           |it = 'Невозможно добавить подгруппу в группу ""%1"",
				           |так как в нее входят все внешние пользователи указанного вида.';
				           |pl = 'Cannot add a subgroup to group ""%1"" as
				           |it contains all external users of the specified types.';
				           |tr = 'Belirtilen türdeki tüm harici kullanıcıları içerdiğinden alt grup  ""1"", 2  grubuna eklenemez.'"), Parent);
		EndIf;
		
		If AllAuthorizationObjects And ValueIsFilled(Parent) Then
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể chuyển nhóm ""%1"",
				           |bởi vì nhóm có bao gồm tất cả người sử dụng của dạng đã chỉ ra.';
				           |ru = 'Невозможно переместить группу ""%1"",
				           |так как в нее входят все внешние пользователи указанного вида.';
				           |en = 'Cannot move group ""%1"" as
				           |it contains all external users of the specified types.'; fa = 'Cannot move group ""%1"" as
				           |it contains all external users of the specified types.';
				           |it = 'Невозможно переместить группу ""%1"",
				           |так как в нее входят все внешние пользователи указанного вида.';
				           |pl = 'Cannot move group ""%1"" as
				           |it contains all external users of the specified types.';
				           |tr = 'Grubu, belirtilen türdeki tüm harici kullanıcıları içerdiğinden ""1"",2 grubuna taşınamıyor.'"), Ref);
		EndIf;
	EndIf;
	
	Return "";
	
EndFunction

Function PurposeCheckErrorText()
	
	// Checking whether the group purpose is filled.
	If Purpose.Count() = 0 Then
		Return NStr("vi = 'Chưa chỉ ra dạng người tham gia nhóm.';
					|ru = 'Не указан вид участников группы.';
					|en = 'The type of group members is not specified.'; fa = 'The type of group members is not specified.';
					|it = 'Non è indicato il tipo di partecipanti del gruppo.';
					|pl = 'Nie wskazano rodzaju członków grupy.';
					|tr = 'Grup üyelerin türü belirtilmedi.'");
	EndIf;
	
	// Checking whether the group of all authorization objects of the specified type is unique.
	If AllAuthorizationObjects Then
		
		// Checking whether the purpose matches the "All external users" group.
		AllExternalUsersGroup = ExternalUsers.AllExternalUsersGroup();
		AllExternalUsersPurpose = Common.ObjectAttributeValue(
			AllExternalUsersGroup, "Purpose").Unload().UnloadColumn("UsersType");
		PurposesArray = Purpose.UnloadColumn("UsersType");
		
		If CommonClientServer.ValueListsAreEqual(AllExternalUsersPurpose, PurposesArray) Then
			Return
				NStr("vi = 'Không thể tạo nhóm trùng với mục đích
				           |của nhóm định trước ""Tất cả người sử dụng ngoài"".';
				           |ru = 'Невозможно создать группу, совпадающую по назначению
				           |с предопределенной группой ""Все внешние пользователи"".';
				           |en = 'Cannot create a group having the same purpose
				           | as the predefined group ""All external users.""'; fa = 'Cannot create a group having the same purpose
				           | as the predefined group ""All external users.""';
				           |it = 'Impossibile creare il gruppo, la cui assegnazione corrisponde
				           |con il gruppo predefinito ""Tutti gli utenti esterni"".';
				           |pl = 'Nie można utworzyć grupy, której przeznaczenie
				           |pokrywa się z grupą predefiniowaną ""Wszyscy użytkownicy zewnętrzni"".';
				           |tr = 'Öntanımlı ""Tüm harici kullanıcılar"" grubu ile
				           | aynı amaca sahip grup oluşturulamaz.'");
		EndIf;
		
		Query = New Query;
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("UsersTypes", Purpose.Unload());
		
		Query.Text =
		"SELECT
		|	UsersTypes.UsersType
		|INTO UsersTypes
		|FROM
		|	&UsersTypes AS UsersTypes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PRESENTATION(ExternalUsersGroups.Ref) AS RefPresentation
		|FROM
		|	Catalog.ExternalUsersGroups.Purpose AS ExternalUsersGroups
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				UsersTypes AS UsersTypes
		|			WHERE
		|				ExternalUsersGroups.Ref <> &Ref
		|				AND ExternalUsersGroups.Ref.AllAuthorizationObjects
		|				AND VALUETYPE(UsersTypes.UsersType) = VALUETYPE(ExternalUsersGroups.UsersType))";
		
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
		
			Selection = QueryResult.Select();
			Selection.Next();
			
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã có một nhóm ""%1"" có 
				           | thành viên bao gồm tất cả người sử dụng thuộc các dạng đã chỉ định.';
				           |ru = 'Уже существует группа ""%1"",
				           |в число участников которой входят все пользователи указанных видов.';
				           |en = 'An existing group ""%1""
				           | includes all users of the specified types.'; fa = 'An existing group ""%1""
				           | includes all users of the specified types.';
				           |it = 'Esiste già il gruppo ""%1"",
				           |, i membri del quale sono tutti gli utenti dei tipi indicati.';
				           |pl = 'Grupa ""%1"", 
				           |do której należą wszyscy użytkownicy wskazanych rodzajów, już istnieje.';
				           |tr = '""%1"" grup zaten var ve 
				           | belirtilen türünden tüm kullanıcıları içermektedir.'"),
				Selection.RefPresentation);
		EndIf;
	EndIf;
	
	// Check if the type of the authentication objects matches their parent's type.
	// It's acceptable if their parent's type is not specified.
	If ValueIsFilled(Parent) Then
		
		ParentUsersType = Common.ObjectAttributeValue(
			Parent, "Purpose").Unload().UnloadColumn("UsersType");
		UsersType = Purpose.UnloadColumn("UsersType");
		
		For Each UserType In UsersType Do
			If ParentUsersType.Find(UserType) = Undefined Then
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Dạng người tham gia trong nhóm cần có trong nhóm
					           |người sử dụng ngoài lớp trên ""%1"".';
					           |ru = 'Вид участников группы должен быть как у вышестоящей
					           |группы внешних пользователей ""%1"".';
					           |en = 'The group members type must be identical to the members type
					           |of the parent external user group ""%1.""'; fa = 'The group members type must be identical to the members type
					           |of the parent external user group ""%1.""';
					           |it = 'Il tipo di partecipanti del gruppo deve corrispondere al gruppo soprastante 
					           |degli utenti esterni"" %1"".';
					           |pl = 'Rodzaj członków grupy powinien być taki sam, jak w wyższej
					           |grupie użytkowników zewnętrznych ""%1"".';
					           |tr = '""%1"" Grup üyelerinin türü, ""
					           |"" harici kullanıcı grubundaki gibi olmalıdır.'"), Parent);
			EndIf;
		EndDo;
	EndIf;
	
	// If the membership type of external user group is changed to "All users of the specified types",
	// check if the group has child groups.
	If AllAuthorizationObjects
		And ValueIsFilled(Ref) Then
		Query = New Query;
		Query.SetParameter("Ref", Ref);
		Query.Text =
		"SELECT
		|	PRESENTATION(ExternalUsersGroups.Ref) AS RefPresentation
		|FROM
		|	Catalog.ExternalUsersGroups AS ExternalUsersGroups
		|WHERE
		|	ExternalUsersGroups.Parent = &Ref";
		
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			Return
				NStr("vi = 'Không thể thay đổi dạng thành viên nhóm
				           |vì trong đó có các nhóm con.';
				           |ru = 'Невозможно изменить вид участников группы,
				           |так как у нее имеются подгруппы.';
				           |en = 'Cannot change the type of group 
				           | members as the group contains subgroups.'; fa = 'Cannot change the type of group 
				           | members as the group contains subgroups.';
				           |it = 'Impossibile modificare il tipo dei membri del gruppo
				           |poiché il gruppo ha dei sottogruppi.';
				           |pl = 'Zmiana rodzaju członków grupy nie jest możliwa,
				           |ponieważ posiada ona podgrupy.';
				           |tr = '""
				           |"" grubu alt gruplara sahip olduğundan dolayı katılımcıların türü değiştirilemez.'");
		EndIf;
	EndIf;
	
	// When changing the type of authentication objects, check if they have
	// child items with a different type (cleating the type is acceptable).
	If ValueIsFilled(Ref) Then
		
		Query = New Query;
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("UsersTypes", Purpose);
		Query.Text =
		"SELECT
		|	UsersTypes.UsersType AS UsersType
		|INTO UsersTypes
		|FROM
		|	&UsersTypes AS UsersTypes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PRESENTATION(ExternalUsersGroupsPurpose.Ref) AS RefPresentation
		|FROM
		|	Catalog.ExternalUsersGroups.Purpose AS ExternalUsersGroupsPurpose
		|WHERE
		|	ExternalUsersGroupsPurpose.Ref.Parent = &Ref
		|	AND NOT TRUE IN
		|				(SELECT TOP 1
		|					TRUE
		|				FROM
		|					UsersTypes AS UsersTypes
		|				WHERE
		|					VALUETYPE(ExternalUsersGroupsPurpose.UsersType) = VALUETYPE(UsersTypes.UsersType))";
		
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			
			Selection = QueryResult.Select();
			Selection.Next();
			
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể thay đổi dạng thành viên nhóm
				           |vì trong đó có nhóm con ""%1"" với mục đích khác cho các thành viên.';
				           |ru = 'Невозможно изменить вид участников группы,
				           |так как у нее имеется подгруппа ""%1"" с другим назначением участников.';
				           |en = 'Cannot change the type of group members
				           |as the group contains the subgroup ""%1"" with different member types.'; fa = 'Cannot change the type of group members
				           |as the group contains the subgroup ""%1"" with different member types.';
				           |it = 'Impossibile modificare il tipo dei partecipanti del gruppo
				           |poiché il gruppo ha un sottogruppo ""%1"" con un''assegnazione diversa dei partecipanti.';
				           |pl = 'Zmiana rodzaju członków grupy nie jest możliwa,
				           |ponieważ posiada ona podgrupę ""%1"" z innym przeznaczeniem członków.';
				           |tr = 'Grup, farklı üye türlerine sahip ""%1"" alt grubunu içerdiğinden
				           |grup üyelerinin türü değiştirilemiyor.'"),
				Selection.RefPresentation);
		EndIf;
	EndIf;
	
	Return "";
	
EndFunction

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf