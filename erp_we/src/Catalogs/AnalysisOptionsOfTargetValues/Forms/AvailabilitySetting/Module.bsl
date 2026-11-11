
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	DisplayOptionDefault = Parameters.DisplayOptionDefault;

	FillInAccessibilitySettings();
	
	SetSearchGroupVisibility(Items);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAvailabilitySettings

&AtClient
Procedure AvailabilitySettingsAvailabilityByDepartmentOnChange(Item)
	
	If Items.AvailabilitySettings.CurrentData <> Undefined Then
		
		UpdateAccessibilityCompositionDown(Items.AvailabilitySettings.CurrentRow, 
			Items.AvailabilitySettings.CurrentData.AvailabilityByDepartment);
			
		UpdateAccessibilityComposition(Items.AvailabilitySettings.CurrentRow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AvailabilitySettingsEnabledOnChange(Item)
	
	If Items.AvailabilitySettings.CurrentData <> Undefined Then
		
		UpdateAccessibilityCompositionDown(Items.AvailabilitySettings.CurrentRow, 
			Number(Items.AvailabilitySettings.CurrentData.Enabled));
			
		UpdateAccessibilityComposition(Items.AvailabilitySettings.CurrentRow);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedUsers

&AtClient
Procedure SelectedUsersEnabledOnChange(Item)
	
	SelectedUser = Items.SelectedUsers.CurrentData;
	
	RowToRefresh = AvailabilitySettings.FindByID(SelectedUser.AvailabilityConfigurationID);
	RowToRefresh.Enabled = SelectedUser.Enabled;
	
	UpdateAccessibilityComposition(SelectedUser.AvailabilityConfigurationID);
			
	If Not SelectedUser.Enabled Then
		
		SelectedUsers.Delete(SelectedUsers.IndexOf(SelectedUser));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	If Items.AccessibilityConfigurationPages.CurrentPage = Items.SelectedUserPage Then
		For Each SelectedUser In SelectedUsers Do
			CurrentData = AvailabilitySettings.FindByID(SelectedUser.AvailabilityConfigurationID);
			CurrentData.Enabled = SelectedUser.Enabled;
			CurrentData.ViewOption = SelectedUser.ViewOption;
			
		EndDo; 
	Else
		SelectedUsers.Clear();
		
		FillInSelectedUsersList();
		
	EndIf;
	
	StorageAddressOfSelectedUsers = StorageAddressOfSelectedUsers();
	
	Close(StorageAddressOfSelectedUsers);
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	UpdateAccessibilityCompositionDown(Undefined, True);
	
	UpdateListOfSelectedUsers();
	
EndProcedure

&AtClient
Procedure ShowOnlySelectedUsers(Command)
	
	OnlySelectedOnes = Items.FormShowOnlySelectedUsers.Check;
	
	If OnlySelectedOnes Then
		
		For Each SelectedUser In SelectedUsers Do 
			
			CurrentData = AvailabilitySettings.FindByID(SelectedUser.AvailabilityConfigurationID);
			CurrentData.Enabled = SelectedUser.Enabled;
			
			UpdateAccessibilityComposition(SelectedUser.AvailabilityConfigurationID);
			
		EndDo;
		
		Items.AccessibilityConfigurationPages.CurrentPage = Items.AvailabilityConfigurationPage;
		
	Else
		
		SelectedUsers.Clear();
		
		FillInSelectedUsersList();
		
		Items.AccessibilityConfigurationPages.CurrentPage = Items.SelectedUserPage;
		
	EndIf;
	
	Items.FormShowOnlySelectedUsers.Check = Not OnlySelectedOnes;
	
	SetSearchGroupVisibility(Items);
	
EndProcedure

&AtClient
Procedure ClearAll(Command)
	
	UpdateAccessibilityCompositionDown(Undefined, False);
	
	UpdateListOfSelectedUsers();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AvailabilitySettingsUser.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AvailabilitySettingsEnabled.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AvailabilitySettings.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AvailabilitySettingsDepartment.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AvailabilitySettingsAvailabilityByDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AvailabilitySettings.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AvailabilitySettingsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AvailabilitySettings.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Chưa chỉ ra bộ phận>';
													|ru = '<Подразделение не указано>';
													|en = '<Business unit is not specified>'; fa = '<Business unit is not specified>';
													|it = '<Reparto non indicato>';
													|pl = '<Nie określono działu>';
													|tr = '<Departman belirtilmedi>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AvailabilitySettingsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AvailabilitySettings.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AvailabilitySettings.AvailabilityByDepartment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AvailabilitySettingsUser.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AvailabilitySettings.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AvailabilitySettings.Enabled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedUsersUser.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedUsers.Enabled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedUsersDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedUsers.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Chưa chỉ ra bộ phận>';
													|ru = '<Подразделение не указано>';
													|en = '<Business unit is not specified>'; fa = '<Business unit is not specified>';
													|it = '<Reparto non indicato>';
													|pl = '<Nie określono działu>';
													|tr = '<Departman belirtilmedi>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AvailabilitySettingsViewOption.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AvailabilitySettings.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AvailabilitySettings.Enabled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Enabled", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AvailabilitySettingsViewOption.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AvailabilitySettings.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Enabled", False);
	
EndProcedure

#Region OnChangeAttributes

&AtClient 
Procedure UpdateAccessibilityComposition(RowID)
	
	CurrentData = AvailabilitySettings.FindByID(RowID);
	
	CurParentData = CurrentData.GetParent();
	
	If Not CurParentData = Undefined Then
		ParentItems1 = CurParentData.GetItems();
		
		NumberOfZeros = 0;
		QuantityOfUnits = 0;
		NumberOfTwos = 0;
		For Each ParentItem1 In ParentItems1 Do 
			If ParentItem1.RowType = 0 Then 
				AccessibilityValue = ParentItem1.AvailabilityByDepartment;
				
			ElsIf ParentItem1.RowType = 1 Then 
				AccessibilityValue = ParentItem1.Enabled;
				
			EndIf;
			
			If AccessibilityValue = 0 Then
				NumberOfZeros = NumberOfZeros + 1;
				
			ElsIf AccessibilityValue = 1 Then
				QuantityOfUnits = QuantityOfUnits + 1;
				
			ElsIf AccessibilityValue = 2 Then
				NumberOfTwos = NumberOfTwos + 1;
				
			EndIf;
			
		EndDo;
		
		ItemCount = ParentItems1.Count();
		
		If NumberOfZeros = 0 Then
			If QuantityOfUnits = ItemCount Then
				CurParentData.AvailabilityByDepartment = 1;
				
			Else
				CurParentData.AvailabilityByDepartment = 2;
				
			EndIf;
		Else
			If NumberOfZeros = ItemCount Then
				CurParentData.AvailabilityByDepartment = 0;
				
			Else
				CurParentData.AvailabilityByDepartment = 2;
				
			EndIf;
		EndIf;
		
		UpdateAccessibilityComposition(CurParentData.GetID());
		
	EndIf;
	
EndProcedure

&AtClient 
Procedure UpdateAccessibilityCompositionDown(RowID, State)
	
	If RowID = Undefined Then
		CollectionOfUsers = AvailabilitySettings.GetItems();
		
	Else
		CurrentData = AvailabilitySettings.FindByID(RowID);
		
		State = ?(State = 2, 0, State);
		
		If CurrentData.RowType = 0 Then
			CurrentData.AvailabilityByDepartment = State;
			
		ElsIf CurrentData.RowType = 1 Then
			CurrentData.Enabled = State;
			
			CurrentData.ViewOption = DisplayOptionDefault;
		EndIf;
		
		CollectionOfUsers = CurrentData.GetItems();
		
	EndIf;
	
	For Each UserCollectionElement In CollectionOfUsers Do
		If UserCollectionElement.RowType = 0 Then
			UserCollectionElement.AvailabilityByDepartment = State;
			
			UpdateAccessibilityCompositionDown(UserCollectionElement.GetID(), State);
			
		ElsIf UserCollectionElement.RowType = 1 Then
			UserCollectionElement.Enabled = State;
			
			UserCollectionElement.ViewOption = DisplayOptionDefault;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

// Puts a table of values with the selected users in temporary storage
// and returns the address.
// 
// Returns:
//	String - the address of the value storage of the value table in the temporary storage.
//
&AtServer 
Function StorageAddressOfSelectedUsers()
	
	SelectedUsersObject = FormAttributeToValue("SelectedUsers");
	
	AddressOfAccessibilitySettings = PutToTempStorage(New ValueStorage(SelectedUsersObject));
	
	Return AddressOfAccessibilitySettings;
	
EndFunction

&AtServer 
Procedure FillInAccessibilitySettings()
	
	Query = New Query;
	
	Query.SetParameter("AvailabilitySettings", Parameters.Users.Unload());
	Query.SetParameter("DisplayOptionDefault", DisplayOptionDefault);
	Query.Text = "SELECT
	|	AvailabilitySettings.User AS User,
	|	AvailabilitySettings.ViewOption AS ViewOption
	|INTO AvailabilitySettings
	|FROM
	|	&AvailabilitySettings AS AvailabilitySettings
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Users.Department AS Department,
	|	Users.Ref AS User,
	|	&DisplayOptionDefault AS DisplayOptionDefault
	|INTO Users
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	NOT Users.Invalid
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AvailabilitySettings.User AS User,
	|	COUNT(AvailabilitySettings.User) AS Count,
	|	AvailabilitySettings.ViewOption AS ViewOption
	|INTO UsersInUnsavedVersion
	|FROM
	|	AvailabilitySettings AS AvailabilitySettings
	|
	|GROUP BY
	|	AvailabilitySettings.User,
	|	AvailabilitySettings.ViewOption
	|
	|INDEX BY
	|	User
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Users.Department AS Department,
	|	Users.User AS User,
	|	FALSE AS AvailabilityByDepartment,
	|	1 AS RowType,
	|	CASE
	|		WHEN UsersInUnsavedVersion.Count = 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Enabled,
	|	CASE
	|		WHEN UsersInUnsavedVersion.ViewOption = VALUE(Enum.DisplayOptionsOfAnalysisOptions.EmptyRef)
	|				OR UsersInUnsavedVersion.ViewOption IS NULL
	|			THEN Users.DisplayOptionDefault
	|		ELSE UsersInUnsavedVersion.ViewOption
	|	END AS ViewOption
	|FROM
	|	Users AS Users
	|		LEFT JOIN UsersInUnsavedVersion AS UsersInUnsavedVersion
	|		ON Users.User = UsersInUnsavedVersion.User
	|
	|ORDER BY
	|	Users.Department.Description,
	|	Users.User.Description
	|TOTALS
	|	CASE
	|		WHEN MAX(Enabled) = TRUE
	|				AND MIN(Enabled) = TRUE
	|			THEN 1
	|		WHEN MAX(Enabled) = FALSE
	|				AND MIN(Enabled) = FALSE
	|			THEN 0
	|		WHEN MAX(Enabled) = TRUE
	|				AND MIN(Enabled) = FALSE
	|			THEN 2
	|	END AS AvailabilityByDepartment,
	|	AVG(CASE
	|			WHEN User IS NULL
	|				THEN 1
	|			ELSE 0
	|		END) AS RowType
	|BY
	|	Department HIERARCHY";
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		AccessibilitySettingsValue = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
		ValueToFormData(AccessibilitySettingsValue, AvailabilitySettings);
		
	EndIf;
	
EndProcedure

&AtClient 
Procedure FillInSelectedUsersList(RowID = Undefined)
	
	If RowID = Undefined Then
		// Processing all
		CollectionOfUsers = AvailabilitySettings.GetItems();
		
	Else
		CurrentData = AvailabilitySettings.FindByID(RowID);
		
		CollectionOfUsers = CurrentData.GetItems();
		
	EndIf;
	
	For Each UserCollectionElement In CollectionOfUsers Do
		
		ItemID = UserCollectionElement.GetID();
		
		If UserCollectionElement.RowType = 0 Then
			FillInSelectedUsersList(ItemID);
			
		ElsIf UserCollectionElement.RowType = 1 And UserCollectionElement.Enabled Then
			NewSelectedUser = SelectedUsers.Add();
			NewSelectedUser.User = UserCollectionElement.User;
			NewSelectedUser.Enabled = True;
			NewSelectedUser.Department = UserCollectionElement.Department;
			NewSelectedUser.ViewOption = UserCollectionElement.ViewOption;
			NewSelectedUser.AvailabilityConfigurationID = ItemID;
			
		EndIf;
	EndDo;
	
	SelectedUsers.Sort("User");
	
EndProcedure

&AtClient 
Procedure UpdateListOfSelectedUsers()
	
	SelectedUsers.Clear();
	
	FillInSelectedUsersList();
	
EndProcedure

&AtClientAtServerNoContext 
Procedure SetSearchGroupVisibility(Items)
	
	OnlySelectedOnes = Items.FormShowOnlySelectedUsers.Check;
	
	Items.SearchGroupBySelected.Visible = OnlySelectedOnes;

EndProcedure

#EndRegion

#EndRegion
