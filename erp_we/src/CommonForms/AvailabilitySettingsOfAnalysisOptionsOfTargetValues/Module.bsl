#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	FillInUserTree();
	
	FillInAccessibilitySettings();
	
	SetFormItemEnabled();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	If Not ClosingInProgress And Modified Then
		Cancel = True;
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		QueryText = NStr("vi = 'Tùy chỉnh đã thay đổi. Ghi lại thay đổi tùy chỉnh?';
						|ru = 'Настройки были изменены. Записать изменения настроек?';
						|en = 'Settings were changed. Save changes?'; fa = 'Settings were changed. Save changes?';
						|it = 'Le impostazioni sono state cambiate. Salvare le modifiche delle impostazioni?';
						|pl = 'Ustawienia zostały zmienione. Chcesz zapisać zmiany w ustawieniach?';
						|tr = 'Ayarlar değiştirildi. Ayar değişiklikleri kaydedilsin mi?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
	EndIf;
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Yes Then
		ClosingInProgress = True;
		WriteSettingsServer();
		Close();
		
	ElsIf Response = DialogReturnCode.No Then
		ClosingInProgress = True;
		Close();
		
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsersTree

&AtClient
Procedure UsersTreeOnActivateRow(Item)
	
	AttachIdleHandler("ProcessActivationOfUserTreeRow",0.2,True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAnalysisOptionTree

&AtClient
Procedure AnalysisOptionTreeAvailabilityByPurposeOnChange(Item)
	
	UseUnsavedSettings = True;
	
	If Items.AnalysisOptionTree.CurrentData <> Undefined Then
		UpdateAccessibilityCompositionDown(Items.AnalysisOptionTree.CurrentRow,
			Items.AnalysisOptionTree.CurrentData.AvailabilityByPurpose);
		UpdateAccessibilityComposition(Items.AnalysisOptionTree.CurrentRow);
		
	EndIf;
	
	UpdateSelectedAnalysisOptions();
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure AnalysisOptionTreeEnabledOnChange(Item)
	
	UseUnsavedSettings = True;
	
	If Items.AnalysisOptionTree.CurrentData.Enabled = 2 Then
		Items.AnalysisOptionTree.CurrentData.Enabled = 0;
		
	EndIf;
	
	If Items.AnalysisOptionTree.CurrentData <> Undefined Then
		UpdateAccessibilityComposition(Items.AnalysisOptionTree.CurrentRow);
		
	EndIf;
	
	UpdateSelectedAnalysisOptions();
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteSettings(Command)
	
	WriteSettingsServer();
	
	Modified = False;
	UseUnsavedSettings = False;
	
EndProcedure

&AtClient
Procedure SaveSettingsAndClose(Command)
	
	WriteSettingsServer();
	
	Modified = False;
	UseUnsavedSettings = False;
	
	Close();
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	UseUnsavedSettings = True;
	
	UpdateAccessibilityCompositionDown(Undefined, True);
	
	UpdateSelectedAnalysisOptions();
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure AccessReportByResponsiblePersons(Command)
	
	ParametersOfFormToOpen = New Structure;
	ParametersOfFormToOpen.Insert("PurposeUseKey", UUID);
	ParametersOfFormToOpen.Insert("VariantKey", "AvailabilityToThoseResponsible");
	ParametersOfFormToOpen.Insert("GenerateOnOpen", True);
	
	OpenForm("Report.AvailabilityOfTargetValueAnalysisOptions.Form", ParametersOfFormToOpen);
	
EndProcedure

&AtClient
Procedure AccessReportByDepartmentEmployees(Command)
	
	ParametersOfFormToOpen = New Structure;
	ParametersOfFormToOpen.Insert("PurposeUseKey", UUID);
	ParametersOfFormToOpen.Insert("VariantKey", "AccessibilityToDepartmentEmployees");
	ParametersOfFormToOpen.Insert("GenerateOnOpen", True);
	
	OpenForm("Report.AvailabilityOfTargetValueAnalysisOptions.Form", ParametersOfFormToOpen);
	
EndProcedure

&AtClient
Procedure ClearAll(Command)
	
	UseUnsavedSettings = True;
	
	UpdateAccessibilityCompositionDown(Undefined, False);
	
	UpdateSelectedAnalysisOptions();
	
	Modified = True;
	
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
	ItemField.Field = New DataCompositionField(Items.UserPicture.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersTree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0; // Row Group - Division

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AvailabilitySettingsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersTree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1; // User string

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AvailabilitySettingsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersTree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0; // Row Group - Division

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersTree.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.BusinessStructure.EmptyRef();

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Chưa chỉ ra bộ phận>';
													|ru = '<Подразделение не указано>';
													|en = '<Business unit is not specified>'; fa = '<Business unit is not specified>';
													|it = '<Reparto non indicato>';
													|pl = '<Nie określono działu>';
													|tr = '<Departman belirtilmedi>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionTreeEnabled.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionTreeAnalysisOption.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionTreeAnalysisType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AnalysisOptionTree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0; // Row group - A target indicator or a group of goals

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionTreeAvailabilityByPurpose.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionTreeTarget.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AnalysisOptionTree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1; // The line of the analysis option

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AnalysisOptionTree.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AnalysisOptionTree.RowType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0; // Row group - A target indicator or a group of goals


	Item.Appearance.SetParameterValue("BackColor", StyleColors.ReportGroup1BackColor);

EndProcedure

#Region OnChangeAttributes

&AtClient 
Procedure UpdateSelectedAnalysisOptions()
	
	CurUserData = UsersTree.FindByID(Items.UsersTree.CurrentRow);
	
	DivisionUsers = New Array;
	
	If CurUserData.RowType = 1 Then
		
		DivisionUsers.Add(CurUserData.User);
		
	ElsIf CurUserData.RowType = 0 Then
		
		FillInArrayOfUsers(Items.UsersTree.CurrentRow, DivisionUsers);
		
	EndIf;
	
	For Each DivisionUser In DivisionUsers Do 
		FilterByUser = New Structure("User", DivisionUser);
		LinesToUpdate = AvailabilitySettings.FindRows(FilterByUser);
		
		For Each LineToUpdate_ In LinesToUpdate Do 
			AvailabilitySettings.Delete(LineToUpdate_);
			
		EndDo;
		
	EndDo;
	
	FillInSelectedAnalysisOptions(DivisionUsers);
	
EndProcedure

&AtClient 
Procedure UpdateAccessibilityComposition(RowID)
	
	CurrentData = AnalysisOptionTree.FindByID(RowID);
	
	CurParentData = CurrentData.GetParent();
	
	If Not CurParentData = Undefined Then
		ParentItems1 = CurParentData.GetItems();
		
		NumberOfZeros = 0;
		QuantityOfUnits = 0;
		NumberOfTwos = 0;
		For Each ParentItem1 In ParentItems1 Do 
			If ParentItem1.RowType = 0 Then 
				AccessibilityValue = ParentItem1.AvailabilityByPurpose;
				
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
				CurParentData.AvailabilityByPurpose = 1;
				
			Else
				CurParentData.AvailabilityByPurpose = 2;
				
			EndIf;
		Else
			If NumberOfZeros = ItemCount Then
				CurParentData.AvailabilityByPurpose = 0;
				
			Else
				CurParentData.AvailabilityByPurpose = 2;
				
			EndIf;
		EndIf;
		
		UpdateAccessibilityComposition(CurParentData.GetID());
		
	EndIf;
	
EndProcedure

&AtClient 
Procedure UpdateAccessibilityCompositionDown(RowID, State)
	
	If RowID = Undefined Then
		CollectionOfAnalysisOptions = AnalysisOptionTree.GetItems();
		
	Else
		CurrentData = AnalysisOptionTree.FindByID(RowID);
		
		State = ?(State = 2, 0, State);
		
		If CurrentData.RowType = 0 Then
			CurrentData.AvailabilityByPurpose = State;
			
		ElsIf CurrentData.RowType = 1 Then
			CurrentData.Enabled = State;
			
		EndIf;
		
		CollectionOfAnalysisOptions = CurrentData.GetItems();
		
	EndIf;
	
	For Each ElementOfAnalysisOptionsCollection In CollectionOfAnalysisOptions Do
		If ElementOfAnalysisOptionsCollection.RowType = 0 Then
			ElementOfAnalysisOptionsCollection.AvailabilityByPurpose = State;
			
			UpdateAccessibilityCompositionDown(ElementOfAnalysisOptionsCollection.GetID(), State);
			
		ElsIf ElementOfAnalysisOptionsCollection.RowType = 1 Then
			ElementOfAnalysisOptionsCollection.Enabled = State;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

&AtServer 
Procedure WriteSettingsServer()
	
	AccessibilitySettingsValue = FormAttributeToValue("AvailabilitySettings");
	AccessibilitySettingsValue.Indexes.Add("AnalysisOption");
	
	AnalysisOptionsSaved = GetAnalysisOptions(, False, True);
	AnalysisOptionsSaved.GroupBy("AnalysisOption");
	
	For Each StringAnalysisOption In AnalysisOptionsSaved Do 
		
		SelectionByAnalysisOption = New Structure("AnalysisOption", StringAnalysisOption.AnalysisOption);
		SettingsToWrite = AccessibilitySettingsValue.FindRows(SelectionByAnalysisOption);
		
		AnalysisOptionObject = StringAnalysisOption.AnalysisOption.GetObject(); // CatalogObject.AnalysisOptionsOfTargetValues -
		AnalysisOptionObject.AvailabilitySettings.Clear();
		
		If SettingsToWrite.Count() > 0 Then
			For Each RecordedSetting In SettingsToWrite Do 
				NewRow = AnalysisOptionObject.AvailabilitySettings.Add();
				NewRow.User = RecordedSetting.User;
				NewRow.ViewOption = Common.ObjectAttributeValue(
					RecordedSetting.AnalysisOption, "DisplayOptionDefault");
			EndDo;
		EndIf;
		
		AnalysisOptionObject.Write();
		
	EndDo;
	
EndProcedure

&AtClient 
Procedure FillInSelectedAnalysisOptions(DivisionUsers, RowID = Undefined, IncludingInaccessibleOnes = False)
	If RowID = Undefined Then
		// Processing all
		CollectionOfAnalysisOptions = AnalysisOptionTree.GetItems();
	Else
		CurrentData = AnalysisOptionTree.FindByID(RowID);
		
		CollectionOfAnalysisOptions = CurrentData.GetItems();
	EndIf;
	
	For Each ElementOfAnalysisOptionsCollection In CollectionOfAnalysisOptions Do
		ItemID = ElementOfAnalysisOptionsCollection.GetID();
		
		If ElementOfAnalysisOptionsCollection.RowType = 0 Then
			FillInSelectedAnalysisOptions(DivisionUsers, ItemID, IncludingInaccessibleOnes);
		ElsIf ElementOfAnalysisOptionsCollection.RowType = 1
			And (ElementOfAnalysisOptionsCollection.Enabled Or IncludingInaccessibleOnes) Then
			For Each DivisionUser In DivisionUsers Do 
				NewlySelectedAnalysisOption = AvailabilitySettings.Add();
				NewlySelectedAnalysisOption.AnalysisOption = ElementOfAnalysisOptionsCollection.AnalysisOption;
				NewlySelectedAnalysisOption.User = DivisionUser;
			EndDo;
		EndIf;
	EndDo;
EndProcedure

&AtServer 
Procedure FillInAnalysisOptionsTree()
	
	If Not Items.UsersTree.SelectedRows.Count() = 0 Then
		ValueAnalysisOptions = GetAnalysisOptions(Items.UsersTree.SelectedRows);
		
	Else
		ValueAnalysisOptions = Undefined;
		
	EndIf;

	If Not ValueAnalysisOptions = Undefined Then
		ValueToFormData(ValueAnalysisOptions, AnalysisOptionTree);
		
		Items.AnalysisOptionPages.CurrentPage = Items.PageAnalysisOptionTree;
		Items.SaveSettingsAndCloseForm.Enabled = True;
		Items.FormShouldSaveSettings.Enabled = True;
		
	Else
		DisplayOptionsAvailabilityMessagePage(Items);
		
	EndIf;
	
EndProcedure

&AtServer 
Procedure FillInUserTree()
	
	Query = New Query;
	
	Query.Text = "
	|SELECT
	|	Users.Ref AS User,
	|	Users.Department AS Department,
	|	Users.Department.DeletionMark AS DepartmentDeletionMark,
	|	1 AS RowType,
	|	CASE
	|		WHEN Users.Ref.DeletionMark
	|			THEN 2
	|		ELSE 3
	|	END AS CustomPicture
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	NOT Users.Invalid
	|
	|ORDER BY
	|	Users.Department.Description,
	|	Users.Description
	|TOTALS
	|	AVG(CASE
	|			WHEN User IS NULL
	|				THEN 1
	|			ELSE 0
	|		END) AS RowType,
	|	AVG(CASE
	|			WHEN DepartmentDeletionMark
	|				THEN 1
	|			WHEN NOT DepartmentDeletionMark
	|					OR DepartmentDeletionMark IS NULL
	|				THEN 0
	|			WHEN DepartmentDeletionMark IS NULL
	|				THEN 0
	|		END) AS CustomPicture
	|BY
	|	Department HIERARCHY";
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		UserTreeValue = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
		UserTreeValue.Columns.Delete(UserTreeValue.Columns.Find("DepartmentDeletionMark"));
		ValueToFormData(UserTreeValue, UsersTree);
		
		Items.UsersTree.CurrentRow = 0;
		
	EndIf;
	
EndProcedure

&AtClient 
Procedure FillInArrayOfUsers(RowID, UsersArray)
	
	If RowID = Undefined Then
		CollectionOfUsers = UsersTree.GetItems();
		
	Else
		CurrentData = UsersTree.FindByID(RowID);
		
		CollectionOfUsers = CurrentData.GetItems();
		
	EndIf;
	
	For Each UserCollectionElement In CollectionOfUsers Do
		If UserCollectionElement.RowType = 0 Then
			FillInArrayOfUsers(UserCollectionElement.GetID(), UsersArray);
			
		ElsIf UserCollectionElement.RowType = 1 Then
			UsersArray.Add(UserCollectionElement.User);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer 
Procedure FillInAccessibilitySettings()
	
	Query = New Query;
	Query.Text = "SELECT
	|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref AS AnalysisOption,
	|	OptionsForAnalyzingAccessibilitySettingsTargets.User AS User,
	|	OptionsForAnalyzingAccessibilitySettingsTargets.User.Department AS Department
	|FROM
	|	Catalog.AnalysisOptionsOfTargetValues.AvailabilitySettings AS OptionsForAnalyzingAccessibilitySettingsTargets
	|WHERE
	|	NOT OptionsForAnalyzingAccessibilitySettingsTargets.User.Ref IS NULL
	|
	|ORDER BY
	|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.AttributeOfAdditionalSortingHierarchical,
	|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.AddlOrderingAttribute,
	|	User";
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		ObjectAvailabilitySettings = QueryResult.Unload();
		ValueToFormData(ObjectAvailabilitySettings, AvailabilitySettings);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext  
Procedure DisplayOptionsAvailabilityMessagePage(Items)
	Items.AnalysisOptionPages.CurrentPage = Items.MessagePage;
	Items.SaveSettingsAndCloseForm.Enabled = False;
	Items.FormShouldSaveSettings.Enabled = False;
	
EndProcedure

&AtServer 
Procedure PrepareTreeOfAnalysisOptions(AnalysisOptionTree, InitialValidationLine = Undefined)
	
	If InitialValidationLine = Undefined Then
		TreeRows = AnalysisOptionTree.Rows;
	Else
		TreeRows = InitialValidationLine.Rows;
	EndIf;
	
	For Each TreeRow In TreeRows Do 
		If Not TreeRow.Target = NULL And Not TreeRow.AnalysisOption = NULL Then
			TreeRow.Rows.Clear();
			
		ElsIf TreeRow.Rows.Count() Then
			PrepareTreeOfAnalysisOptions(AnalysisOptionTree, TreeRow);
			
		EndIf;
		
		If Not TreeRow.Parent = Undefined And TreeRow.Target = TreeRow.Parent.Target Then
			LinesOfCurTreeLine = TreeRow.Rows;
			
			InsertPosition = TreeRows.IndexOf(TreeRow);
			For Each RowOfCurTreeRow In LinesOfCurTreeLine Do 
				TransferredLine = TreeRow.Parent.Rows.Insert(InsertPosition);
				FillPropertyValues(TransferredLine, RowOfCurTreeRow);
				
				InsertPosition = InsertPosition + 1;
				
			EndDo;
			
			TreeRow.Rows.Clear();
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer 
Function GetSummaryText()
	
	Text = "
	|TOTALS
	|	CASE
	|		WHEN MAX(Enabled) = 1
	|				AND MIN(Enabled) = 1
	|			THEN 1
	|		WHEN MAX(Enabled) = 0
	|				AND MIN(Enabled) = 0
	|			THEN 0
	|		WHEN MAX(Enabled) = 1
	|				AND MIN(Enabled) = 0
	|			THEN 2
	|	END AS AvailabilityByPurpose,
	|	CASE
	|		WHEN MAX(Enabled) = 1
	|				AND MIN(Enabled) = 1
	|			THEN 1
	|		WHEN MAX(Enabled) = 0
	|				AND MIN(Enabled) = 0
	|			THEN 0
	|		WHEN MAX(Enabled) = 1
	|				AND MIN(Enabled) = 0
	|			THEN 2
	|	END AS Enabled,
	|	CASE
	|		WHEN AnalysisOption IS NULL
	|			THEN 0
	|		ELSE 1
	|	END AS RowType
	|BY
	|	Target HIERARCHY,
	|	AnalysisOption";
	
	Return Text;
	
EndFunction

&AtServer 
Function GetTextOfTotalsIfThereIsDivision()
	
	Text = "
	|TOTALS
	|	CASE
	|		WHEN MAX(AvailabilityByPurpose) = 2
	|			THEN 2
	|		WHEN MAX(AvailabilityByPurpose) = 1
	|				AND MIN(AvailabilityByPurpose) = 0
	|			THEN 2
	|		WHEN MAX(AvailabilityByPurpose) = 1
	|				AND MIN(AvailabilityByPurpose) = 1
	|			THEN 1
	|		WHEN MAX(AvailabilityByPurpose) = 0
	|			THEN 0
	|	END AS AvailabilityByPurpose,
	|	CASE
	|		WHEN MAX(Enabled) = 2
	|			THEN 2
	|		WHEN MAX(Enabled) = 1
	|				AND MIN(Enabled) = 0
	|			THEN 2
	|		WHEN MAX(Enabled) = 1
	|				AND MIN(Enabled) = 1
	|			THEN 1
	|		WHEN MAX(Enabled) = 0
	|			THEN 0
	|	END AS Enabled,	
	|	CASE
	|		WHEN AnalysisOption IS NULL 
	|			THEN 0
	|		ELSE 1
	|	END AS RowType
	|BY
	|	Target HIERARCHY,
	|	AnalysisOption";
	
	Return Text;
	
EndFunction

&AtServer 
Function GetUserPackageText()
	
	Return "SELECT
		|	COUNT(DISTINCT Users.Ref) AS UsersCount
		|INTO Users
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	NOT Users.Invalid
		|	AND Users.Department IN HIERARCHY (&Departments)
		|;";
	
EndFunction

&AtServer 
Function GetUserPackageTextWithoutParameters()
	
	Return "SELECT
		|	COUNT(DISTINCT Users.Ref) AS UsersCount
		|INTO Users
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	NOT Users.Invalid
		|;";
	
EndFunction

&AtServer 
Function GetUserPackageTextByUser()
	
	Return "SELECT
		|	COUNT(DISTINCT Users.Ref) AS UsersCount
		|INTO Users
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	NOT Users.Invalid
		|	AND Users.Ref = &User
		|;";
	
EndFunction

&AtServer 
Function GetPackageTextOfUsersOfEmptyDivision()
	
	Return "SELECT
		|	COUNT(DISTINCT Users.Ref) AS UsersCount
		|INTO Users
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	NOT Users.Invalid
		|	AND Users.Department = &Department
		|;";
	
EndFunction

&AtServer 
Function GetAnalysisOptions(Val FilterParameters = Undefined, ResultInTree = True, AllAnalysisOptions = False)
	
	ValueAnalysisOptions = Undefined;
	
	Query = New Query;
	
	AccessibilitySettingsValue = FormAttributeToValue("AvailabilitySettings");
	
	If UseUnsavedSettings Then
		Query.SetParameter("UnsavedAccessibilitySettings", AccessibilitySettingsValue);
		Query.Text = "
		|SELECT
		|	UnsavedAccessibilitySettings.User,
		|	UnsavedAccessibilitySettings.Department,
		|	UnsavedAccessibilitySettings.AnalysisOption
		|INTO UnsavedAccessibilitySettings
		|FROM
		|	&UnsavedAccessibilitySettings AS UnsavedAccessibilitySettings
		|WHERE
		|	&UnsavedSelectionParameter
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AnalysisOptionsOfTargetValues.Owner AS Target,
		|	CASE
		|		WHEN Users.UsersCount = COUNT(UnsavedAccessibilitySettings.AnalysisOption)
		|			THEN 1
		|		WHEN COUNT(UnsavedAccessibilitySettings.AnalysisOption) = 0
		|			THEN 0
		|		ELSE 2
		|	END AS AvailabilityByPurpose,
		|	AnalysisOptionsOfTargetValues.Ref AS AnalysisOption,
		|	AnalysisOptionsOfTargetValues.Ref.AnalysisType AS AnalysisType,
		|	CASE
		|		WHEN Users.UsersCount = COUNT(UnsavedAccessibilitySettings.AnalysisOption)
		|			THEN 1
		|		WHEN COUNT(UnsavedAccessibilitySettings.AnalysisOption) = 0
		|			THEN 0
		|		ELSE 2
		|	END AS Enabled,
		|	2 AS RowType
		|FROM
		|	Catalog.AnalysisOptionsOfTargetValues AS AnalysisOptionsOfTargetValues
		|		LEFT JOIN UnsavedAccessibilitySettings AS UnsavedAccessibilitySettings
		|		ON (UnsavedAccessibilitySettings.AnalysisOption = AnalysisOptionsOfTargetValues.Ref),
		|	TTTableOfUsers AS Users
		|
		|WHERE
		|	(NOT AnalysisOptionsOfTargetValues.Ref.DeletionMark)
		|	AND &SelectionIfUserField
		|
		|GROUP BY
		|	AnalysisOptionsOfTargetValues.Owner,
		|	AnalysisOptionsOfTargetValues.Ref,
		|	AnalysisOptionsOfTargetValues.Ref.AnalysisType,
		|	Users.UsersCount,
		|	CASE
		|		WHEN UnsavedAccessibilitySettings.User IS NULL 
		|			THEN 0
		|		ELSE 1
		|	END
		|
		|ORDER BY 
		|	AnalysisOptionsOfTargetValues.Owner.AttributeOfAdditionalSortingHierarchical, 
		|	AnalysisOptionsOfTargetValues.Ref.AddlOrderingAttribute
		|
		|";
		
	Else
		Query.Text = "
		|SELECT
		|	VACAccessibilitySettings.Ref AS AnalysisOption,
		|	VACAccessibilitySettings.User,
		|	VACAccessibilitySettings.User.Department AS Department
		|INTO VACAccessibilitySettings
		|FROM
		|	Catalog.AnalysisOptionsOfTargetValues.AvailabilitySettings AS VACAccessibilitySettings
		|WHERE
		|	&FilterParameter
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AnalysisOptionsOfTargetValues.Owner AS Target,
		|	CASE
		|		WHEN Users.UsersCount = COUNT(VACAccessibilitySettings.AnalysisOption)
		|			THEN 1
		|		WHEN COUNT(VACAccessibilitySettings.AnalysisOption) = 0
		|			THEN 0
		|		ELSE 2
		|	END AS AvailabilityByPurpose,
		|	AnalysisOptionsOfTargetValues.Ref AS AnalysisOption,
		|	AnalysisOptionsOfTargetValues.Ref.AnalysisType AS AnalysisType,
		|	CASE
		|		WHEN Users.UsersCount = COUNT(VACAccessibilitySettings.AnalysisOption)
		|			THEN 1
		|		WHEN COUNT(VACAccessibilitySettings.AnalysisOption) = 0
		|			THEN 0
		|		ELSE 2
		|	END AS Enabled,
		|	2 AS RowType
		|	
		|FROM
		|	Catalog.AnalysisOptionsOfTargetValues AS AnalysisOptionsOfTargetValues
		|		LEFT JOIN VACAccessibilitySettings AS VACAccessibilitySettings
		|		ON (VACAccessibilitySettings.AnalysisOption = AnalysisOptionsOfTargetValues.Ref),
		|	TTTableOfUsers AS Users
		|
		|WHERE
		|	(NOT AnalysisOptionsOfTargetValues.Ref.DeletionMark)
		|	AND &SelectionIfUserField
		|
		|GROUP BY
		|	AnalysisOptionsOfTargetValues.Owner,
		|	AnalysisOptionsOfTargetValues.Ref,
		|	AnalysisOptionsOfTargetValues.Ref.AnalysisType,
		|	Users.UsersCount,
		|	CASE
		|		WHEN VACAccessibilitySettings.User IS NULL 
		|			THEN 0
		|		ELSE 1
		|	END
		|
		|ORDER BY 
		|	AnalysisOptionsOfTargetValues.Owner.AttributeOfAdditionalSortingHierarchical, 
		|	AnalysisOptionsOfTargetValues.Ref.AddlOrderingAttribute
		|
		|";
		
	EndIf;
	
	// Let's check what types of values are found in the selection parameter
	ThereAreDivisions = False;
	ThereAreEmptyDivisions = False;
	ThereAreUsers = False;
	FinalSubdivision = True;
	
	If Not FilterParameters = Undefined Then
		SelectionUnits = New Array;
		SelectionUsers = New Array;
		
		For Each FilterParameter In FilterParameters Do 
			String = UsersTree.FindByID(FilterParameter);
			
			If ValueIsFilled(String.User) Then 
				ThereAreUsers = True;
				SelectionUsers.Add(String.User);
			ElsIf ValueIsFilled(String.Department) Then 
				ThereAreDivisions = True;
				SelectionUnits.Add(String.Department);
			ElsIf Not ValueIsFilled(String.Department) Then 
				ThereAreEmptyDivisions = True;
				SelectionUnits.Add(String.Department);
			EndIf;
			
			If String.RowType = 0 And ValueIsFilled(String.Department) Then
				SubordinateRows = String.GetItems();
				
				For Each SubordinateRow In SubordinateRows Do 
					If SubordinateRow.Department <> String.Department Then
						FinalSubdivision = False;
					EndIf;
				EndDo;
				
			EndIf;
		EndDo;
		
	EndIf;
	
	If ThereAreUsers Then
		TemporaryTablePackageText = GetUserPackageTextByUser();
		Query.Text = TemporaryTablePackageText + Query.Text;
		Query.Text = StrReplace(Query.Text, "TTTableOfUsers", "Users");
	ElsIf AllAnalysisOptions Then
		TemporaryTablePackageText = GetUserPackageTextWithoutParameters();
		Query.Text = TemporaryTablePackageText + Query.Text;
		Query.Text = StrReplace(Query.Text, "TTTableOfUsers", "Users");
	ElsIf ThereAreEmptyDivisions Or FinalSubdivision Then
		TemporaryTablePackageText = GetPackageTextOfUsersOfEmptyDivision();
		Query.Text = TemporaryTablePackageText + Query.Text;
		Query.Text = StrReplace(Query.Text, "TTTableOfUsers", "Users");
	ElsIf ThereAreDivisions Then
		TemporaryTablePackageText = GetUserPackageText();
		Query.Text = TemporaryTablePackageText + Query.Text;
		Query.Text = StrReplace(Query.Text, "TTTableOfUsers", "Users");
	EndIf;
	
	If Not AllAnalysisOptions Then
		If ThereAreEmptyDivisions Then
			If UseUnsavedSettings Then
				Query.Text = StrReplace(Query.Text,
						"&UnsavedSelectionParameter",
						"UnsavedAccessibilitySettings.Department = &Department");
			Else
				Query.Text = StrReplace(Query.Text,
						"&FilterParameter",
						"VACAccessibilitySettings.User.Department = &Department");
			EndIf;
			Query.SetParameter("Department", Catalogs.BusinessStructure.EmptyRef());
			
		ElsIf ThereAreDivisions And FinalSubdivision Then
			
			If UseUnsavedSettings Then
				Query.Text = StrReplace(Query.Text,
						"&UnsavedSelectionParameter",
						"UnsavedAccessibilitySettings.Department = &Department");
			Else
				Query.Text = StrReplace(Query.Text,
						"&FilterParameter",
						"VACAccessibilitySettings.User.Department = &Department");
			EndIf;
			Query.SetParameter("Department", SelectionUnits[0]);
			
		ElsIf ThereAreDivisions Then
			
			If UseUnsavedSettings Then
				Query.Text = StrReplace(Query.Text,
						"&UnsavedSelectionParameter",
						"UnsavedAccessibilitySettings.Department IN HIERARCHY(&Departments)");
			Else
				Query.Text = StrReplace(Query.Text,
						"&FilterParameter",
						"VACAccessibilitySettings.User.Department IN HIERARCHY(&Departments)");
			EndIf;
			
			Query.SetParameter("Departments", SelectionUnits);
			
		ElsIf ThereAreUsers Then
			
			If UseUnsavedSettings Then
				Query.Text = StrReplace(Query.Text,
						"&UnsavedSelectionParameter",
						"UnsavedAccessibilitySettings.User = &User");
			Else
				Query.Text = StrReplace(Query.Text,
						"&FilterParameter",
						"VACAccessibilitySettings.User = &User");
			EndIf;
			
			Query.SetParameter("User", SelectionUsers[0]);
			
		EndIf;
	Else
		If UseUnsavedSettings Then
			Query.Text = StrReplace(Query.Text, "&UnsavedSelectionParameter", "TRUE");
		Else
			Query.Text = StrReplace(Query.Text, "&FilterParameter", "TRUE");
		EndIf;
	EndIf;
	
	QueryTextTotals = "";
	
	UserFieldsToAdd = New Structure;
	DimensionFieldsToAdd = New Array;
	SelectionIfUserField = "TRUE";
	
	If ResultInTree Then
		If ThereAreEmptyDivisions Or ThereAreDivisions Then
			QueryTextTotals = GetTextOfTotalsIfThereIsDivision();
			
			FieldPresentation = "UsersCount";
			FieldPath = "Users.UsersCount";
			UserFieldsToAdd.Insert(FieldPresentation, FieldPath);
		Else
			QueryTextTotals = GetSummaryText();
		EndIf;
		
	Else
		QueryTextTotals = "";
		
		If UseUnsavedSettings Then
			FieldPresentation = "User";
			FieldPath = "UnsavedAccessibilitySettings.User";
			UserFieldsToAdd.Insert(FieldPresentation, FieldPath);
			
			FieldPresentation = "Department";
			FieldPath = "UnsavedAccessibilitySettings.Department";
			UserFieldsToAdd.Insert(FieldPresentation, FieldPath);
			
			DimensionFieldsToAdd.Add("UnsavedAccessibilitySettings.User");
			DimensionFieldsToAdd.Add("UnsavedAccessibilitySettings.Department");
			
			If Not AllAnalysisOptions Then
				SelectionIfUserField = "NOT (UnsavedAccessibilitySettings.User IS NULL)";
			EndIf;
		Else
			FieldPresentation = "User";
			FieldPath = "VACAccessibilitySettings.User";
			UserFieldsToAdd.Insert(FieldPresentation, FieldPath);
			
			FieldPresentation = "Department";
			FieldPath = "VACAccessibilitySettings.Department";
			UserFieldsToAdd.Insert(FieldPresentation, FieldPath);
			
			DimensionFieldsToAdd.Add("VACAccessibilitySettings.User");
			DimensionFieldsToAdd.Add("VACAccessibilitySettings.Department");
			
			If Not AllAnalysisOptions Then
				SelectionIfUserField = "NOT (VACAccessibilitySettings.User IS NULL)";
			EndIf;
		EndIf;
	EndIf;
	Query.Text = StrReplace(Query.Text, "&SelectionIfUserField", SelectionIfUserField);
	If UserFieldsToAdd.Count() > 0
		Or DimensionFieldsToAdd.Count() > 0 Then
		QuerySchema = New QuerySchema();
		QuerySchema.SetQueryText(Query.Text);
		
		QueryPackages = QuerySchema.QueryBatch;
		LastRequestPacket = QueryPackages.Get(QueryPackages.Count()-1);
		RequestColumns = LastRequestPacket.Columns;
		PackageOperator = LastRequestPacket.Operators[0];
		
		If UserFieldsToAdd.Count() > 0 Then
			SelectedFields = PackageOperator.SelectedFields;
			For Each KeyAndValue In UserFieldsToAdd Do
				NewField = SelectedFields.Add(KeyAndValue.Value);
				NewColumn = RequestColumns.Find(NewField);
				NewColumn.Alias = KeyAndValue.Key;
			EndDo;
		EndIf;
		
		If DimensionFieldsToAdd.Count() > 0 Then
			GroupFields = PackageOperator.Group;
			For Each NameOfDimensionField In DimensionFieldsToAdd Do
				GroupFields.Add(NameOfDimensionField);
			EndDo;
		EndIf;
		
		Query.Text = QuerySchema.GetQueryText();
	EndIf;
	
	Query.Text = Query.Text + QueryTextTotals;
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		If ResultInTree Then
			ValueAnalysisOptions = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
			
			PrepareTreeOfAnalysisOptions(ValueAnalysisOptions);
			
			DeleteRowsWithoutSubordinates(ValueAnalysisOptions);
			
		Else
			ValueAnalysisOptions = QueryResult.Unload().Copy(, "AnalysisOption, User, Department");
		EndIf;
		
	EndIf;
	
	Return ValueAnalysisOptions;
	
EndFunction

&AtServer 
Procedure SetFormItemEnabled()
	
	If UsersTree.GetItems().Count() = 0 Then
		Items.PagesUserTree.CurrentPage = Items.PageMessageAboutUsers;
		Items.AnalysisOptionPages.Visible = False;
		Items.SaveSettingsAndCloseForm.Enabled = False;
		Items.FormShouldSaveSettings.Enabled = False;
		
	EndIf;
	
EndProcedure

&AtServer 
Procedure DeleteRowsWithoutSubordinates(AnalysisOptionTree, InitialValidationLine = Undefined)
	
	If InitialValidationLine = Undefined Then
		TreeRows = AnalysisOptionTree.Rows;
	Else
		TreeRows = InitialValidationLine.Rows;
	EndIf;
	
	RowIndex = TreeRows.Count() - 1;
	While RowIndex >= 0 Do 
		RowToValidate = TreeRows[RowIndex];
		
		If RowToValidate.RowType = 1 Then
			RowIndex = RowIndex - 1;
			Continue;
			
		EndIf;
		
		If RowToValidate.Rows.Count() Then
			DeleteRowsWithoutSubordinates(AnalysisOptionTree, RowToValidate);
			
		Else
			TreeRows.Delete(RowToValidate);
			
		EndIf;
		
		RowIndex = RowIndex - 1;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ProcessActivationOfUserTreeRow()

	FillInAnalysisOptionsTree();
	
	Items.AnalysisOptionTree.CurrentRow = 0;
	
EndProcedure

#EndRegion

ClosingInProgress = False;

#EndRegion

