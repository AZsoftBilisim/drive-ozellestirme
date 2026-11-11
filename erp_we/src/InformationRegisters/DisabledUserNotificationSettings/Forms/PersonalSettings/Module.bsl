
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	User = Users.AuthorizedUser();
	NotificationKind = Parameters.NotificationKind;
	FillInTreeOfNotificationKinds();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSettingsTree

&AtClient
Procedure SettingsTreeSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	If Field.Name = "NotificationKind" Then
		RowData = Items.SettingsTree.RowData(RowSelected);
		If RowData <> Undefined Then
			Value = RowData.NotificationKind;
			OpenValueAsync(Value);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	SaveAtServer();
	
	ShowUserNotification(
		NStr("vi = 'Lưu tùy chỉnh:';
			|ru = 'Сохранение настроек:';
			|en = 'Save settings:'; fa = 'Save settings:';
			|it = 'Save settings:';
			|pl = 'Save settings:';
			|tr = 'Ayarların kaydedilmesi:'"),,
		NStr("vi = 'Đã lưu các tùy chỉnh cá nhân đối với thông báo.';
			|ru = 'Персональные настройки оповещений сохранены.';
			|en = 'Personal notification settings are saved.'; fa = 'Personal notification settings are saved.';
			|it = 'Personal notification settings are saved.';
			|pl = 'Personal notification settings are saved.';
			|tr = 'Kişisel bildirim ayarları kaydedildi.'"),
		PictureLib.Information32);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.isEnabled.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingsTree.IsFolder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

&AtServer
Procedure FillInTreeOfNotificationKinds()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	NotificationKinds.Ref AS NotificationKind,
		|	DisabledUserNotificationSettings.User IS NULL AS isEnabled,
		|	NotificationKinds.IsFolder AS IsFolder,
		|	CASE
		|		WHEN NotificationKinds.IsFolder
		|				AND NOT NotificationKinds.DeletionMark
		|			THEN 0
		|		WHEN NotificationKinds.IsFolder
		|				AND NotificationKinds.DeletionMark
		|			THEN 1
		|		WHEN NOT NotificationKinds.IsFolder
		|				AND NOT NotificationKinds.DeletionMark
		|				AND NOT NotificationKinds.Supplied
		|			THEN 3
		|		WHEN NOT NotificationKinds.IsFolder
		|				AND NotificationKinds.DeletionMark
		|			THEN 4
		|		WHEN NOT NotificationKinds.IsFolder
		|				AND NOT NotificationKinds.DeletionMark
		|				AND NotificationKinds.Supplied
		|			THEN 5
		|	END AS PictureIndex
		|FROM
		|	Catalog.UserNotificationKinds AS NotificationKinds
		|		LEFT JOIN InformationRegister.DisabledUserNotificationSettings AS DisabledUserNotificationSettings
		|		ON NotificationKinds.Ref = DisabledUserNotificationSettings.NotificationKind
		|			AND (DisabledUserNotificationSettings.User = &User)
		|WHERE
		|	CASE
		|		WHEN NOT NotificationKinds.IsFolder
		|			THEN NotificationKinds.Running
		|		END
		|	AND NOT NotificationKinds.DeletionMark
		|
		|ORDER BY
		|	NotificationKinds.Description
		|TOTALS BY
		|	NotificationKind HIERARCHY";
	
	Query.SetParameter("User", User);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	SelectionWithHierarchy=QueryResult.Select(QueryResultIteration.ByGroupsWithHierarchy,"NotificationKind");
	FillTreeRows(SelectionWithHierarchy, SettingsTree.GetItems());
	
EndProcedure

&AtServer
Procedure FillTreeRows(Selection, TreeItems)
	
	While Selection.Next() Do
		If Selection.RecordType()=QueryRecordType.GroupTotal Then
			FillTreeRows(Selection.Select(QueryResultIteration.ByGroups), TreeItems);
			Continue;
		EndIf;
		TreeItem = TreeItems.Add();
		FillPropertyValues(TreeItem, Selection);
		If ValueIsFilled(NotificationKind) And Selection.NotificationKind = NotificationKind Then
			Items.SettingsTree.CurrentRow = TreeItem.GetID();
		EndIf;
		If Selection.RecordType()=QueryRecordType.TotalByHierarchy Then
			FillTreeRows(Selection.Select(QueryResultIteration.ByGroupsWithHierarchy,"NotificationKind"), TreeItem.GetItems());
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SaveAtServer()
	RecordSet = InformationRegisters.DisabledUserNotificationSettings.CreateRecordSet();
	RecordSet.Filter.User.Set(User);
	AddDisabledNotificationKindsToSet(RecordSet, SettingsTree.GetItems());
	SetPrivilegedMode(True);
	RecordSet.Write(ReplacementMode.Replace);
	SetPrivilegedMode(False);
	Modified = False;
EndProcedure

&AtServer
Procedure AddDisabledNotificationKindsToSet(RecordSet, TreeItems)
	
	For Each TableRow In TreeItems Do
		If Not TableRow.IsFolder And Not TableRow.isEnabled Then
			NewRecord = RecordSet.Add();
			NewRecord.User = User;
			NewRecord.NotificationKind = TableRow.NotificationKind;
		EndIf;
		AddDisabledNotificationKindsToSet(RecordSet, TableRow.GetItems());
	EndDo;
	
EndProcedure

#EndRegion