
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Filter") Then
		Items.FormSetTheDisplayOfAll.Visible = False;
		User = Parameters.Filter.User;
	EndIf;
	
	DescriptionOfForms = New Map;
	For Each EnumerationValue In OpenFormsOnApplicationStart.FormsUsedWhenStartingSystem() Do
		DescriptionOfForms.Insert(
			EnumerationValue, 
			OpenFormsOnApplicationStartClientServerOverridable.FormSettings(EnumerationValue));
	EndDo;
	
	ShapeParameter = Common.FixedData(DescriptionOfForms);
	
	UpdateFormSettingsTableOnServer();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If Upper(EventName) = Upper("Write_ConfigureFormOpeningOnStartingApplication") Then
		If TypeOf(Source) = Type("Structure") Then
			UpdateFormSettingsTableEntry(Source);			
		Else
			UpdateFormSettingsTable();
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFormSettings

&AtClient
Procedure FormSettingsSelection(Item, RowSelected, Field, StandardProcessing)
	OpenRegisterEntryForm();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeSetting(Command)
	OpenRegisterEntryForm();
EndProcedure

&AtClient
Procedure SetTheDisplayOfAll(Command)
	
	ShowAll = Not ShowAll;
	Items.FormSetTheDisplayOfAll.Check = ShowAll;
	
	UpdateFormSettingsTable();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// FormSettings

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FormSettingsFormSettings.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FormSettings.RequiredSettings");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa đặt tùy chỉnh đối với biểu mẫu>';
													|ru = '<для формы не задаются настройки>';
													|en = '<settings are not specified for the form>'; fa = '<settings are not specified for the form>';
													|it = '<nessuna impostazione per il modulo>';
													|pl = '<nie określono ustawień dla formularza>';
													|tr = '<form ayarları ayarlanmadı>'"));

	// FormSettings

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FormSettingsFormSettings.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FormSettings.RequiredSettings");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FormSettings.SettingsAreSet");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa đặt tùy chỉnh>';
													|ru = '<настройки не заданы>';
													|en = '<settings are not specified>'; fa = '<settings are not specified>';
													|it = '<impostazioni non stabilite>';
													|pl = '<ustawienia nie są określone>';
													|tr = '<Ayarlar yapılmadı>'"));

	// FormSettings

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FormSettingsFormSettings.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FormSettings.FormIsAvailable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<biểu mẫu không khả dụng (không đủ quyền)>';
													|ru = '<форма недоступна (недостаточно прав)>';
													|en = '<form unavailable (insufficient rights)>'; fa = '<form unavailable (insufficient rights)>';
													|it = '<nessun accesso al modulo (diritti insufficienti)>';
													|pl = '<formularz niedostępny (za mało uprawnień)>';
													|tr = '<form erişilebilir değil (yeterli yetki mevcut değil)>'"));

EndProcedure

&AtClient
Procedure OpenRegisterEntryForm()
	CurrentData = Items.FormSettings.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not CurrentData.FormIsAvailable Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Vai trò ""%1"" không khả dụng đối với người sử dụng.';
				|ru = 'Пользователю недоступна роль ""%1"".';
				|en = '""%1"" role is unavailable to user.'; fa = '""%1"" role is unavailable to user.';
				|it = 'All''utente non è accessibile il ruolo ""%1"".';
				|pl = 'Użytkownik jest niedostępny dla roli ""%1"".';
				|tr = 'Kullanıcıya ""%1"" rol erişilebilir değil.'"),
			ShapeParameter[CurrentData.OpenedForm].Role);
			
		ShowMessageBox(, MessageText);
		
		Return;
		
	EndIf;
	
	ParametersOfFormToOpen = New Structure;
	
	ParametersOfFormToOpen.Insert("User",     CurrentData.User);
	ParametersOfFormToOpen.Insert("OpenedForm", CurrentData.OpenedForm);
	
	If CurrentData.OpenByDefault
	 Or CurrentData.SettingsAreSet Then
		
		KeyForRecordingFormParameters = KeyForRecordingFormParameters(CurrentData.User, CurrentData.OpenedForm);
		
		If Not KeyForRecordingFormParameters.IsEmpty() Then
			ParametersOfFormToOpen.Insert("Key", KeyForRecordingFormParameters);
		EndIf;
		
	EndIf;
	
	If CurrentData.RequiredSettings Then
		NameOfFormToOpen_ = CurrentData.SettingsFormName;
	Else
		NameOfFormToOpen_ = "InformationRegister.ConfigureFormOpeningOnStartingApplication.RecordForm";
	EndIf;
	
	CallbackDescription = New CallbackDescription("UpdateFormSettingsTable", ThisForm);
	
	OpenForm(NameOfFormToOpen_, ParametersOfFormToOpen, ThisForm,,,,CallbackDescription);
		
EndProcedure

&AtServer
Function KeyForRecordingFormParameters(User, OpenedForm)
	
	DimensionStructure = New Structure;
	DimensionStructure.Insert("User",     User);
	DimensionStructure.Insert("OpenedForm", OpenedForm);
	
	Return InformationRegisters.ConfigureFormOpeningOnStartingApplication.CreateRecordKey(DimensionStructure);
	
EndFunction

&AtClient
Procedure UpdateFormSettingsTable(Result = Undefined, AdditionalParameters = Undefined) Export
	
	UpdateFormSettingsTableOnServer(Result, AdditionalParameters); 
	
EndProcedure

&AtServer
Procedure UpdateFormSettingsTableOnServer(Result = Undefined, AdditionalParameters = Undefined) Export
	
	FormSettings.Clear();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Users.Ref AS User,
	|	Users.IBUserID
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	(Users.Ref = &UserForSelection
	|			OR &UserForSelection = UNDEFINED)
	|	AND NOT Users.Invalid
	|	AND NOT Users.IsInternal
	|
	|ORDER BY
	|	Users.Description";
	
	If Not User.IsEmpty() Then
		Query.SetParameter("UserForSelection", User);
	ElsIf Not Users.IsFullUser(,, False) Then
		Query.SetParameter("UserForSelection", Users.CurrentUser());
	Else
		Query.SetParameter("UserForSelection", Undefined);
	EndIf;
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If Not ValueIsFilled(Selection.IBUserID) Then
			Continue;
		EndIf;
			
		IBUser = InfoBaseUsers.FindByUUID(Selection.IBUserID);
		If IBUser = Undefined Then
			Continue;
		EndIf;
		
		IsFullUser = IBUser.Roles.Contains(Metadata.Roles.FullAccess);
		
		For Each FormParameters In ShapeParameter Do
			
			IsInRole = IsFullUser
				Or IBUser.Roles.Contains(Metadata.Roles[FormParameters.Value.Role]);
			
			If ShowAll Or IsInRole Then
				
			 	NewRow = FormSettings.Add();
				
				NewRow.User     = Selection.User;
				NewRow.OpenedForm = FormParameters.Key;
				NewRow.FormIsAvailable	 = IsInRole;
				
				FillPropertyValues(NewRow, FormParameters.Value, "LaunchParameter, RequiredSettings, SettingsFormName");
			 
			EndIf;
			
		EndDo;
			
	EndDo;
	
	Query.Text =
	"SELECT
	|	FormSettingsTable.User,
	|	FormSettingsTable.RequiredSettings,
	|	FormSettingsTable.OpenedForm,
	|	FormSettingsTable.LaunchParameter,
	|	FormSettingsTable.SettingsFormName,
	|	FormSettingsTable.FormIsAvailable
	|INTO FormSettings
	|FROM
	|	&FormSettingsTable AS FormSettingsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FormSettings.User,
	|	FormSettings.OpenedForm,
	|	FormSettings.RequiredSettings,
	|	FormSettings.LaunchParameter,
	|	FormSettings.SettingsFormName,
	|	FormSettings.FormIsAvailable,
	|	ISNULL(ConfigureFormOpeningOnStartingApplication.ParameterPresentationText, """") AS FormSettings,
	|	ISNULL(ConfigureFormOpeningOnStartingApplication.OpenByDefault, FALSE) AS OpenByDefault,
	|	CASE
	|		WHEN ConfigureFormOpeningOnStartingApplication.User IS NULL 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS SettingsAreSet
	|FROM
	|	FormSettings AS FormSettings
	|		LEFT JOIN InformationRegister.ConfigureFormOpeningOnStartingApplication AS ConfigureFormOpeningOnStartingApplication
	|		ON FormSettings.User = ConfigureFormOpeningOnStartingApplication.User
	|			AND FormSettings.OpenedForm = ConfigureFormOpeningOnStartingApplication.OpenedForm";
	
	Query.SetParameter("FormSettingsTable", FormAttributeToValue("FormSettings"));
	
	FormSettings.Load(Query.Execute().Unload());
	
	If Not FormSettings.Count() Then
		Items.FormChangeSetting.Enabled = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateFormSettingsTableEntry(RegisterRecordKey)
	
	FilterParameters = New Structure("User, OpenedForm");
	FillPropertyValues(FilterParameters, RegisterRecordKey);
	
	FoundRows = FormSettings.FindRows(FilterParameters);
	If FoundRows.Count() = 0 Then
		Return; // the alert is not intended for this form
	EndIf;
	
	FormSettingsTableRow = FoundRows[0];
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ConfigureFormOpeningOnStartingApplication.ParameterPresentationText,
	|	ConfigureFormOpeningOnStartingApplication.OpenByDefault
	|FROM
	|	InformationRegister.ConfigureFormOpeningOnStartingApplication AS ConfigureFormOpeningOnStartingApplication
	|WHERE
	|	ConfigureFormOpeningOnStartingApplication.User = &User
	|	AND ConfigureFormOpeningOnStartingApplication.OpenedForm = &OpenedForm";
	
	Query.SetParameter("User",     FilterParameters.User);
	Query.SetParameter("OpenedForm", FilterParameters.OpenedForm);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		FormSettingsTableRow.FormSettings       = Selection.ParameterPresentationText;
		FormSettingsTableRow.OpenByDefault = Selection.OpenByDefault;
		FormSettingsTableRow.SettingsAreSet = True;
	Else
		FormSettingsTableRow.FormSettings       = "";
		FormSettingsTableRow.OpenByDefault = False;
		FormSettingsTableRow.SettingsAreSet = False;
	EndIf;
	
EndProcedure

#EndRegion
