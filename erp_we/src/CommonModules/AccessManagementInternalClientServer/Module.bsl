///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Determines the profile assignment.
//
// Parameters:
//  Profile - CatalogObject.AccessGroupProfiles - a profile with the Assignment tabular section.
//          - FormDataStructure   - a profile object structure in the form.
//          - Structure              - a built-in profile details.
//          - FixedStructure - a built-in profile details.
//
// Returns:
//  String - ForAdministrators, ForUsers, ForExternalUsers,
//            BothForUsersAndExternalUsers.
//
Function ProfileAssignment(Profile) Export
	
	AssignmentForUsers = False;
	AssignmentForExternalUsers = False;
	
	For Each AssignmentDetails In Profile.Purpose Do
		If TypeOf(Profile.Purpose) = Type("Array")
		 Or TypeOf(Profile.Purpose) = Type("FixedArray") Then
			Type = TypeOf(AssignmentDetails);
		Else
			Type = TypeOf(AssignmentDetails.UsersType);
		EndIf;
		If Type = Type("CatalogRef.Users") Then
			AssignmentForUsers = True;
		EndIf;
		If Type <> Type("CatalogRef.Users") And Type <> Undefined Then
			AssignmentForExternalUsers = True;
		EndIf;
	EndDo;
	
	If AssignmentForUsers And AssignmentForExternalUsers Then
		Return "BothForUsersAndExternalUsers";
		
	ElsIf AssignmentForExternalUsers Then
		Return "ForExternalUsers";
	EndIf;
	
	Return "ForAdministrators";
	
EndFunction

// Checks whether the access kind matches the profile assignment.
//
// Parameters:
//  AccessKind        - String - Access kind name.
//                    - DefinedType.AccessValue - Access kind value type.
//  ProfileAssignment - String - returned by the ProfileAssignment function.
//  
// Returns:
//  Boolean
//
Function AccessKindMatchesProfileAssignment(Val AccessKind, ProfileAssignment) Export
	
	If AccessKind = "Users"
	 Or TypeOf(AccessKind) = Type("CatalogRef.Users") Then
		
		Return ProfileAssignment <> "BothForUsersAndExternalUsers"
		      And ProfileAssignment <> "ForExternalUsers";
		
	ElsIf AccessKind = "ExternalUsers"
	      Or TypeOf(AccessKind) = Type("CatalogRef.ExternalUsers") Then
		
		Return ProfileAssignment = "ForExternalUsers";
	EndIf;
	
	Return True;
	
EndFunction

#Region ManagingAccessKindsTableAndAccessValuesTableInEditors

// For internal use only.
Procedure FillAllAllowedPresentation(Form, AccessKindDetails, AddValuesCount = True) Export
	
	Parameters = AllowedValuesEditFormParameters(Form);
	
	If AccessKindDetails.AllAllowed Then
		If Form.IsAccessGroupProfile And Not AccessKindDetails.Predefined Then
			Name = "AllAllowedByDefault";
		Else
			Name = "AllAllowed";
		EndIf;
	Else
		If Form.IsAccessGroupProfile And Not AccessKindDetails.Predefined Then
			Name = "AllDeniedByDefault";
		Else
			Name = "AllDenied";
		EndIf;
	EndIf;
	
	AccessKindDetails.AllAllowedPresentation =
		Form.PresentationsAllAllowed.FindRows(New Structure("Name", Name))[0].Presentation;
	
	If Not AddValuesCount Then
		Return;
	EndIf;
	
	If Form.IsAccessGroupProfile And Not AccessKindDetails.Predefined Then
		Return;
	EndIf;
	
	Filter = FilterInAllowedValuesEditFormTables(Form, AccessKindDetails.AccessKind);
	
	ValuesCount = Parameters.AccessValues.FindRows(Filter).Count();
	
	If Form.IsAccessGroupProfile Then
		If ValuesCount = 0 Then
			NumberAndSubject = NStr("vi = 'chưa ấn định';
									|ru = 'не назначены';
									|en = 'not assigned'; fa = 'not assigned';
									|it = 'non assegnati';
									|pl = 'nie przeznaczono';
									|tr = 'atanmadı'");
		Else
			NumberAndSubject = Format(ValuesCount, "NG=") + " "
				+ UsersInternalClientServer.IntegerSubject(ValuesCount,
					"", NStr("vi = 'giá trị,giá trị,giá trị,,,,,,0';
							|ru = 'значения,значений,значений,,,,,,0';
							|en = 'value,values,,,0'; fa = 'value,values,,,0';
							|it = 'del valore, dei valori, dei valori,,,,,,0';
							|pl = 'wartości,wartości,wartości,,,,,,0';
							|tr = 'değerler,değerler,değerler,,,,,,0'"));
		EndIf;
		
		AccessKindDetails.AllAllowedPresentation =
			AccessKindDetails.AllAllowedPresentation
				+ " (" + NumberAndSubject + ")";
		Return;
	EndIf;
	
	If ValuesCount = 0 Then
		Presentation = ?(AccessKindDetails.AllAllowed,
			NStr("vi = 'Cho phép tất cả, không có ngoại lệ';
				|ru = 'Все разрешены, без исключений';
				|en = 'All allowed, no exceptions'; fa = 'همه مجاز، بدون استثنا';
				|it = 'Sono ammessi tutti, senza eccezioni';
				|pl = 'Wszystkie dozwolone, bez wyjątków';
				|tr = 'İstisnasız hepsine izin verildi'"),
			NStr("vi = 'Cấm tất cả, không có ngoại lệ';
				|ru = 'Все запрещены, без исключений';
				|en = 'All denied, no exceptions'; fa = 'All denied, no exceptions';
				|it = 'Sono proibiti tutti, senza eccezioni';
				|pl = 'Wszystkie zabronione, bez wyjątków';
				|tr = 'İstisnasız hepsi yasak'"));
	Else
		NumberAndSubject = Format(ValuesCount, "NG=") + " "
			+ UsersInternalClientServer.IntegerSubject(ValuesCount,
				"", NStr("vi = 'giá trị,giá trị,giá trị,,,,,,0';
						|ru = 'значения,значений,значений,,,,,,0';
						|en = 'value,values,,,0'; fa = 'value,values,,,0';
						|it = 'del valore, dei valori, dei valori,,,,,,0';
						|pl = 'wartości,wartości,wartości,,,,,,0';
						|tr = 'değerler,değerler,değerler,,,,,,0'"));
		
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			?(AccessKindDetails.AllAllowed,
				NStr("vi = 'Cho phép tất cả, ngoại trừ %1';
					|ru = 'Все разрешены, кроме %1';
					|en = 'All allowed, except %1'; fa = 'All allowed, except %1';
					|it = 'Sono ammessi tutti, tranne %1';
					|pl = 'Wszystkie dozwolone, z wyjątkiem %1';
					|tr = '%1 Hariç hepsine izin verildi'"),
				NStr("vi = 'Cấm tất cả, ngoại trừ %1';
					|ru = 'Все запрещены, кроме %1';
					|en = 'All denied, except %1'; fa = 'All denied, except %1';
					|it = 'Sono proibiti tutti, tranne %1';
					|pl = 'Wszystkie zabronione, z wyjątkiem %1';
					|tr = '%1 hariç hepsi yasak'")),
			NumberAndSubject);
	EndIf;
	
	AccessKindDetails.AllAllowedPresentation = Presentation;
	
EndProcedure

// For internal use only.
Procedure FillNumbersOfAccessValuesRowsByKind(Form, AccessKindDetails) Export
	
	Parameters = AllowedValuesEditFormParameters(Form);
	
	Filter = FilterInAllowedValuesEditFormTables(Form, AccessKindDetails.AccessKind);
	AccessValuesByKind = Parameters.AccessValues.FindRows(Filter);
	
	CurrentNumber = 1;
	For Each String In AccessValuesByKind Do
		String.RowNumberByKind = CurrentNumber;
		CurrentNumber = CurrentNumber + 1;
	EndDo;
	
EndProcedure

// For internal use only.
//
// Parameters:
//  Form - See AllowedValuesEditFormParameters
//  ProcessingAtClient - Boolean
//
Procedure OnChangeCurrentAccessKind(Form, ProcessingAtClient = True) Export
	
	Items = Form.Items;
	Parameters = AllowedValuesEditFormParameters(Form);
	
	CanEditValues = False;
	
	If ProcessingAtClient Then
		CurrentData = Items.AccessKinds.CurrentData;
	Else
		CurrentData = Parameters.AccessKinds.FindByID(
			?(Items.AccessKinds.CurrentRow = Undefined, -1, Items.AccessKinds.CurrentRow));
	EndIf;
	
	If CurrentData <> Undefined Then
		
		If CurrentData.AccessKind <> Undefined
		   And Not CurrentData.Used Then
			
			If Not Items.AccessKindNotUsedText.Visible Then
				Items.AccessKindNotUsedText.Visible = True;
			EndIf;
		Else
			If Items.AccessKindNotUsedText.Visible Then
				Items.AccessKindNotUsedText.Visible = False;
			EndIf;
		EndIf;
		
		Form.CurrentAccessKind = CurrentData.AccessKind;
		
		If Not Form.IsAccessGroupProfile Or CurrentData.Predefined Then
			CanEditValues = True;
		EndIf;
		
		If CanEditValues Then
			
			If Form.IsAccessGroupProfile Then
				Items.AccessKindsTypes.CurrentPage = Items.PresetAccessKind;
			EndIf;
			
			// Set a value filter.
			RefreshRowsFilter = False;
			RowFilter = Items.AccessValues.RowFilter;
			Filter = FilterInAllowedValuesEditFormTables(Form, CurrentData.AccessKind);
			
			If RowFilter = Undefined Then
				RefreshRowsFilter = True;
				
			ElsIf Filter.Property("AccessGroup") And RowFilter.AccessGroup <> Filter.AccessGroup Then
				RefreshRowsFilter = True;
				
			ElsIf RowFilter.AccessKind <> Filter.AccessKind
			        And Not (RowFilter.AccessKind = "" And Filter.AccessKind = Undefined) Then
				
				RefreshRowsFilter = True;
			EndIf;
			
			If RefreshRowsFilter Then
				If CurrentData.AccessKind = Undefined Then
					Filter.AccessKind = "";
				EndIf;
				Items.AccessValues.RowFilter = New FixedStructure(Filter);
			EndIf;
			
		ElsIf Form.IsAccessGroupProfile Then
			Items.AccessKindsTypes.CurrentPage = Items.NormalAccessKind;
		EndIf;
		
		If CurrentData.AccessKind = Form.AccessKindUsers
		 Or CurrentData.AccessKind = Form.AccessKindExternalUsers Then
			
			LabelPattern = ?(CurrentData.AllAllowed,
				NStr("vi = 'Giá trị bị cấm (%1) - người sử dụng được ủy quyền và nhóm của họ luôn được phép';
					|ru = 'Запрещенные значения (%1) - авторизованный пользователь и его группы всегда разрешены';
					|en = 'Forbidden values (%1): Authorized user and their groups are always allowed'; fa = 'Forbidden values (%1): Authorized user and their groups are always allowed';
					|it = 'Запрещенные значения (%1) - авторизованный пользователь и его группы всегда разрешены';
					|pl = 'Forbidden values (%1): Authorized user and their groups are always allowed';
					|tr = 'Yasak değerler (%1) - yetkili kullanıcıya ve gruplarına her zaman izin verilir'"),
				NStr("vi = 'Giá trị bị cấm (%1) - người sử dụng được ủy quyền và nhóm của họ luôn được phép';
					|ru = 'Разрешенные значения (%1) - авторизованный пользователь и его группы всегда разрешены';
					|en = 'Allowed values (%1): Authorized user and their groups are always allowed'; fa = 'Allowed values (%1): Authorized user and their groups are always allowed';
					|it = 'Разрешенные значения (%1) - авторизованный пользователь и его группы всегда разрешены';
					|pl = 'Allowed values (%1): Authorized user and their groups are always allowed';
					|tr = 'İzin verilen değerler (%1) - yetkili kullanıcıya ve gruplarına her zaman izin verilir'") );
		Else
			LabelPattern = ?(CurrentData.AllAllowed,
				NStr("vi = 'Giá trị bị cấm (%1)';
					|ru = 'Запрещенные значения (%1)';
					|en = 'Denied values (%1)'; fa = 'Denied values (%1)';
					|it = 'I valori proibiti (%1)';
					|pl = 'Niedozwolone wartości (%1)';
					|tr = 'Yasak değerler (%1)'"),
				NStr("vi = 'Giá trị được phép (%1)';
					|ru = 'Разрешенные значения (%1)';
					|en = 'Allowed values (%1)'; fa = 'Allowed values (%1)';
					|it = 'I valori ammessi (%1)';
					|pl = 'Dozwolone wartości (%1)';
					|tr = 'İzin verilen değerler (%1)'") );
		EndIf;
		
		// Refresh the field AccessKindLabel.
		Form.AccessKindLabel = StringFunctionsClientServer.SubstituteParametersToString(LabelPattern,
			String(CurrentData.AccessKindPresentation));
		
		FillAllAllowedPresentation(Form, CurrentData);
		
	Else
		If Items.AccessKindNotUsedText.Visible Then
			Items.AccessKindNotUsedText.Visible = False;
		EndIf;
		
		Form.CurrentAccessKind = Undefined;
		Items.AccessValues.RowFilter = New FixedStructure(
			FilterInAllowedValuesEditFormTables(Form, Undefined));
		
		If Parameters.AccessKinds.Count() = 0 Then
			Parameters.AccessValues.Clear();
		EndIf;
	EndIf;
	
	Form.CurrentTypeOfValuesToSelect  = Undefined;
	Form.CurrentTypesOfValuesToSelect = New ValueList;
	
	If CanEditValues Then
		Filter = New Structure("AccessKind", CurrentData.AccessKind);
		AccessKindsTypesDetails = Form.AllTypesOfValuesToSelect.FindRows(Filter);
		HierarchyOfItems = True;
		For Each AccessKindTypeDetails In AccessKindsTypesDetails Do
			
			Form.CurrentTypesOfValuesToSelect.Add(
				AccessKindTypeDetails.ValuesType,
				AccessKindTypeDetails.TypePresentation);
				
			HierarchyOfItems = HierarchyOfItems And AccessKindTypeDetails.HierarchyOfItems;
		EndDo;
		
		Items.AccessValuesIncludeSubordinateAccessValues.Visible = HierarchyOfItems;
	Else
		If CurrentData <> Undefined Then
			
			Filter = FilterInAllowedValuesEditFormTables(
				Form, CurrentData.AccessKind);
			
			For Each String In Parameters.AccessValues.FindRows(Filter) Do
				Parameters.AccessValues.Delete(String);
			EndDo
		EndIf;
	EndIf;
	
	If Form.CurrentTypesOfValuesToSelect.Count() = 0 Then
		Form.CurrentTypesOfValuesToSelect.Add(Undefined, NStr("vi = 'Không xác định';
																|ru = 'Неопределено';
																|en = 'Undefined'; fa = 'تعریف‌نشده';
																|it = 'Indefinito';
																|pl = 'Undefined';
																|tr = 'Tanımsız'"));
	EndIf;
	
	Items.AccessValues.Enabled = CanEditValues;
	
EndProcedure

// For internal use only.
// See AccessManagementInternal.OnCreateAtServerAllowedValuesEditForm
//
// Returns:
//   ClientApplicationForm:
//     * Items - FormAllItems:
//         ** Purpose                - FormTable
//         ** AccessKinds               - FormTable
//         ** AccessValues           - FormTable
//         ** AllAccessKinds            - FormTable
//         ** PresentationsAllAllowed - FormTable
//         ** AllTypesOfValuesToSelect - FormTable
//     * CurrentAccessGroup                - CatalogRef.AccessGroups
//     * Purpose                          - See PurposeFromForm
//     * AccessKinds                         - See AccessKindsFromForm
//     * AccessValues                     - See AccessValuesFromForm
//     * UseExternalUsers    - Boolean - an attribute will be created if it is not in the form
//     * AccessKindLabel                   - String - a presentation of the current access kind in the form
//     * IsAccessGroupProfile              - Boolean
//     * CurrentAccessKind                   - DefinedType.AccessValue
//     * CurrentTypesOfValuesToSelect       - ValueList
//     * CurrentTypeOfValuesToSelect        - DefinedType.AccessValue
//     * TablesStorageAttributeName         - String
//     * AccessKindUsers              - DefinedType.AccessValue
//     * AccessKindExternalUsers       - DefinedType.AccessValue
//     * AllAccessKinds                      - See AllAccessKindsFromForm
//     * PresentationsAllAllowed           - See PresentationsAllAllowedFromForm
//     * AllTypesOfValuesToSelect           - See AllTypesOfValuesToSelectFromForm
//
Function AllowedValuesEditFormParameters(Form, CurrentObject = Undefined) Export
	
	PathToTables = "";
	
	If CurrentObject <> Undefined Then
		TablesStorage = CurrentObject;
		
	ElsIf ValueIsFilled(Form.TablesStorageAttributeName) Then
		PathToTables = Form.TablesStorageAttributeName + ".";
		TablesStorage = Form[Form.TablesStorageAttributeName];
	Else
		TablesStorage = Form;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("Purpose",                PurposeFromForm(TablesStorage));
	Parameters.Insert("AccessKinds",               AccessKindsFromForm(TablesStorage));
	Parameters.Insert("AccessValues",           AccessValuesFromForm(TablesStorage));
	Parameters.Insert("AllAccessKinds",            AllAccessKindsFromForm(Form));
	Parameters.Insert("PresentationsAllAllowed", PresentationsAllAllowedFromForm(Form));
	Parameters.Insert("AllTypesOfValuesToSelect", AllTypesOfValuesToSelectFromForm(Form));
	Parameters.Insert("PathToTables",   PathToTables);
	
	Return Parameters;
	
EndFunction

// For internal use only.
//
// Parameters:
//  Form - See AllowedValuesEditFormParameters
//  AccessKind - String
//             - DefinedType.AccessValue
// 
// Returns:
//  Filter - Structure:
//   * AccessGroup - CatalogRef.AccessGroups
//   * AccessKind - DefinedType.AccessValue - a blank reference of the main access kind value type.
//
Function FilterInAllowedValuesEditFormTables(Form, AccessKind = "NoFilterByAccessKind") Export
	
	Filter = New Structure;
	
	Structure = New Structure("CurrentAccessGroup", "AttributeNotExists");
	FillPropertyValues(Structure, Form);
	
	If Structure.CurrentAccessGroup <> "AttributeNotExists" Then
		Filter.Insert("AccessGroup", Structure.CurrentAccessGroup);
	EndIf;
	
	If AccessKind <> "NoFilterByAccessKind" Then
		Filter.Insert("AccessKind", AccessKind);
	EndIf;
	
	Return Filter;
	
EndFunction

// For internal use only.
Procedure FillAccessKindsPropertiesInForm(Form) Export
	
	Parameters = AllowedValuesEditFormParameters(Form);
	
	AccessKindsFilter = FilterInAllowedValuesEditFormTables(Form);
	AccessKinds = Parameters.AccessKinds.FindRows(AccessKindsFilter);
	
	For Each String In AccessKinds Do
		
		String.Used = True;
		
		If String.AccessKind <> Undefined Then
			Filter = New Structure("Ref", String.AccessKind);
			FoundRows = Form.AllAccessKinds.FindRows(Filter);
			If FoundRows.Count() > 0 Then
				String.AccessKindPresentation = FoundRows[0].Presentation;
				String.Used            = FoundRows[0].Used;
			EndIf;
		EndIf;
		
		FillAllAllowedPresentation(Form, String);
		
		FillNumbersOfAccessValuesRowsByKind(Form, String);
	EndDo;
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AllowedValuesEditFormParameters
//  Cancel - Boolean
//  CheckedTablesAttributes - Array of String
//  Errors - See CommonClientServer.AddUserError.Errors
//  DontCheck - Boolean
//
Procedure ProcessingOfCheckOfFillingAtServerAllowedValuesEditForm(
		Form, Cancel, CheckedTablesAttributes, Errors, DontCheck = False) Export
	
	Items = Form.Items;
	Parameters = AllowedValuesEditFormParameters(Form);
	If Parameters.Purpose <> Undefined Then
		ProfileAssignment = ProfileAssignment(Parameters);
	EndIf;
	
	CheckedTablesAttributes.Add(Parameters.PathToTables + "AccessKinds.AccessKind");
	CheckedTablesAttributes.Add(Parameters.PathToTables + "AccessValues.AccessKind");
	CheckedTablesAttributes.Add(Parameters.PathToTables + "AccessValues.AccessValue");
	
	If DontCheck Then
		Return;
	EndIf;
	
	AccessKindsFilter = FilterInAllowedValuesEditFormTables(Form);
	
	AccessKinds = Parameters.AccessKinds.FindRows(AccessKindsFilter);
	AccessKindIndex = AccessKinds.Count();
	
	// Checking for unfilled or duplicate access kinds.
	While AccessKindIndex > 0 Do
		AccessKindIndex = AccessKindIndex - 1;
		AccessKindRow = AccessKinds[AccessKindIndex];
		
		// Checking whether the access kind is filled.
		If AccessKindRow.AccessKind = Undefined Then
			CommonClientServer.AddUserError(Errors,
				Parameters.PathToTables + "AccessKinds[%1].AccessKind",
				NStr("vi = 'Chưa chọn dạng truy cập.';
					|ru = 'Вид доступа не выбран.';
					|en = 'The access kind is not selected.'; fa = 'The access kind is not selected.';
					|it = 'Non è selezionata la modalità d''accesso.';
					|pl = 'Typ dostępu nie jest wybrany.';
					|tr = 'Erişim türü seçilmedi.'"),
				"AccessKinds",
				AccessKinds.Find(AccessKindRow),
				NStr("vi = 'Chưa chọn dạng truy cập trong dòng %1.';
					|ru = 'Вид доступа в строке %1 не выбран.';
					|en = 'No access kind selected in line #%1.'; fa = 'No access kind selected in line #%1.';
					|it = 'La modalità d''accesso nella riga %1 non è selezionata.';
					|pl = 'Typ dostępu w wierszu %1 nie jest wybrany.';
					|tr = '%1 satırdaki erişim türü seçilmedi.'"),
				Parameters.AccessKinds.IndexOf(AccessKindRow));
			Cancel = True;
			Continue;
		EndIf;
		
		// Checking whether the access kind matches the profile assignment.
		If Parameters.Purpose <> Undefined
		  And Not AccessKindMatchesProfileAssignment(AccessKindRow.AccessKind, ProfileAssignment) Then
			
			CommonClientServer.AddUserError(Errors,
				Parameters.PathToTables + "AccessKinds[%1].AccessKind",
				StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Dạng truy cập ""%1"" không tương ứng với việc ấn định hồ sơ.';
																				|ru = 'Вид доступа ""%1"" не соответствует назначению профиля.';
																				|en = 'Access kind ""%1"" does not match the profile assignment.'; fa = 'Access kind ""%1"" does not match the profile assignment.';
																				|it = 'La modalità d''accesso ""%1"" non corrisponde alla destinazione del profilo.';
																				|pl = 'Typ dostępu ""%1"" nie odpowiada przeznaczeniu profilu.';
																				|tr = '""%1"" erişim türü profilin amacına uygun değildir.'"),
					AccessKindRow.AccessKindPresentation),
				"AccessKinds",
				AccessKinds.Find(AccessKindRow),
				StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Dạng truy cập ""%1"" trong dòng %2 không tương ứng với mục đích của hồ sơ.';
																				|ru = 'Вид доступа ""%1"" в строке %2 не соответствует назначению профиля.';
																				|en = 'Access kind ""%1"" in line #%2 does not match the profile assignment.'; fa = 'Access kind ""%1"" in line #%2 does not match the profile assignment.';
																				|it = 'Tipo di accesso ""%1"" nella riga %2 non corrisponde alla destinazione del profilo.';
																				|pl = 'Rodzaj dostępu ""%1"" w wierszu %2 nie odpowiada przeznaczeniu profilu.';
																				|tr = '%2 satırındaki ""%1"" erişim türü profilin amacına uygun değildir.'"),
					AccessKindRow.AccessKindPresentation, "%1"),
				Parameters.AccessKinds.IndexOf(AccessKindRow));
			Cancel = True;
			Continue;
		EndIf;
		
		// Checking for duplicate access kinds.
		AccessKindsFilter.Insert("AccessKind", AccessKindRow.AccessKind);
		FoundAccessKinds = Parameters.AccessKinds.FindRows(AccessKindsFilter);
		
		If FoundAccessKinds.Count() > 1 Then
			CommonClientServer.AddUserError(Errors,
				Parameters.PathToTables + "AccessKinds[%1].AccessKind",
				StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Dạng truy cập ""%1"" bị lặp lại.';
																				|ru = 'Вид доступа ""%1"" повторяется.';
																				|en = 'Duplicate access kind: ""%1"".'; fa = 'Duplicate access kind: ""%1"".';
																				|it = 'La modalità di accesso ""%1"" viene ripetuta.';
																				|pl = 'Typ dostępu ""%1"" powtarza się.';
																				|tr = '""%1"" erişim türü tekrarlandı.'"),
					AccessKindRow.AccessKindPresentation),
				"AccessKinds",
				AccessKinds.Find(AccessKindRow),
				StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Dạng truy cập ""%1"" trong dòng %2 bị lặp lại.';
																				|ru = 'Вид доступа ""%1"" в строке %2 повторяется.';
																				|en = 'Duplicate access kind ""%1"" in line #%2.'; fa = 'Duplicate access kind ""%1"" in line #%2.';
																				|it = 'Tipo di accesso ""%1"" nella riga %2 viene ripetuto.';
																				|pl = 'Rodzaj dostępu ""%1"" w wierszu %2 powtarza się.';
																				|tr = '""%1"" erişim türü %2 satırında tekrarlanıyor.'"),
					AccessKindRow.AccessKindPresentation, "%1"),
				Parameters.AccessKinds.IndexOf(AccessKindRow));
			Cancel = True;
			Continue;
		EndIf;
		
		AccessValuesFilter = FilterInAllowedValuesEditFormTables(
			Form, AccessKindRow.AccessKind);
		
		AccessValues = Parameters.AccessValues.FindRows(AccessValuesFilter);
		AccessValueIndex = AccessValues.Count();
		
		While AccessValueIndex > 0 Do
			AccessValueIndex = AccessValueIndex - 1;
			AccessValueRow = AccessValues[AccessValueIndex];
			
			// Checking whether the access value is filled.
			If AccessValueRow.AccessValue = Undefined Then
				Items.AccessKinds.CurrentRow = AccessKindRow.GetID();
				Items.AccessValues.CurrentRow = AccessValueRow.GetID();
				
				CommonClientServer.AddUserError(Errors,
					Parameters.PathToTables + "AccessValues[%1].AccessValue",
					NStr("vi = 'Chưa chọn giá trị.';
						|ru = 'Значение не выбрано.';
						|en = 'No value is selected.'; fa = 'No value is selected.';
						|it = 'Il valore non è selezionato.';
						|pl = 'Nie wybrano żadnej wartości.';
						|tr = 'Değer seçilmedi'"),
					"AccessValues",
					AccessValues.Find(AccessValueRow),
					NStr("vi = 'Chưa chọn giá trị trong dòng %1.';
						|ru = 'Значение в строке %1 не выбрано.';
						|en = 'No value selected in line #%1.'; fa = 'No value selected in line #%1.';
						|it = 'Il valore nella riga %1 non è selezionato.';
						|pl = 'Wartość w wierszu %1 nie jest wybrana.';
						|tr = '%1Satırdaki değer seçilmedi.'"),
					Parameters.AccessValues.IndexOf(AccessValueRow));
				Cancel = True;
				Continue;
			EndIf;
			
			// Checking for duplicate values.
			AccessValuesFilter.Insert("AccessValue", AccessValueRow.AccessValue);
			FoundValues = Parameters.AccessValues.FindRows(AccessValuesFilter);
			
			If FoundValues.Count() > 1 Then
				Items.AccessKinds.CurrentRow = AccessKindRow.GetID();
				Items.AccessValues.CurrentRow = AccessValueRow.GetID();
				
				CommonClientServer.AddUserError(Errors,
					Parameters.PathToTables + "AccessValues[%1].AccessValue",
					NStr("vi = 'Giá trị lặp lại.';
						|ru = 'Значение повторяется.';
						|en = 'Duplicate value.'; fa = 'Duplicate value.';
						|it = 'Il valore viene ripetuto.';
						|pl = 'Wartość jest powtarzana.';
						|tr = 'Değer tekrarlandı.'"),
					"AccessValues",
					AccessValues.Find(AccessValueRow),
					NStr("vi = 'Lặp lại giá trị trong dòng %1.';
						|ru = 'Значение в строке %1 повторяется.';
						|en = 'Duplicate value in line #%1.'; fa = 'Duplicate value in line #%1.';
						|it = 'Il valore nella riga %1 viene ripetuto.';
						|pl = 'Wartość w wierszu %1 jest powtarzana.';
						|tr = '%1 satırındaki değer tekrarlandı.'"),
					Parameters.AccessValues.IndexOf(AccessValueRow));
				Cancel = True;
				Continue;
			EndIf;
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Parameters:
//  Data - Structure:
//   * Description - String
//   * User - CatalogRef.Users
//   
// Returns:
//  String
//
Function PresentationAccessGroups(Data) Export
	
	Return Data.Description + ": " + Data.User;
	
EndFunction

// For internal use only.
// See AccessManagementInternal.OnCreateAtServerAllowedValuesEditForm
//
// Returns:
//   FormDataCollection of FormDataCollectionItem:
//     * UserType - DefinedType.User - assignment type.
//
Function PurposeFromForm(Form)
	
	OptionalAttributes = New Structure("Purpose");
	FillPropertyValues(OptionalAttributes, Form);
	Return OptionalAttributes.Purpose;
	
EndFunction

// For internal use only.
// See AccessManagementInternal.OnCreateAtServerAllowedValuesEditForm
//
// Returns:
//   FormDataCollection of FormDataCollectionItem:
//    * AccessGroup              - CatalogRef.AccessGroups
//    * AccessKind                 - DefinedType.AccessValue
//    * Predefined          - Boolean - (profile only)
//    * AllAllowed               - Boolean
//    * AccessKindPresentation    - String - setting presentation,
//    * AllAllowedPresentation  - String - setting presentation,
//    * Used               - Boolean
//
Function AccessKindsFromForm(Form)
	
	Return Form.AccessKinds;
	
EndFunction

// For internal use only.
// See AccessManagementInternal.OnCreateAtServerAllowedValuesEditForm
//
// Returns:
//   FormDataCollection of FormDataCollectionItem:
//    * AccessGroup     - CatalogRef.AccessGroups
//    * AccessKind        - DefinedType.AccessValue
//    * AccessValue   - DefinedType.AccessValue
//    * RowNumberByKind - Number
//
Function AccessValuesFromForm(Form)
	
	Return Form.AccessValues;
	
EndFunction

// For internal use only.
// See AccessManagementInternal.OnCreateAtServerAllowedValuesEditForm
//
// Returns:
//   FormDataCollection of FormDataCollectionItem:
//    * Ref        - DefinedType.AccessValue
//    * Presentation - String
//    * Used  - Boolean
//
Function AllAccessKindsFromForm(Form)
	
	OptionalAttributes = New Structure("AllAccessKinds");
	FillPropertyValues(OptionalAttributes, Form);
	Return OptionalAttributes.AllAccessKinds;
	
EndFunction

// For internal use only.
// See AccessManagementInternal.OnCreateAtServerAllowedValuesEditForm
//
// Returns:
//   FormDataCollection of FormDataCollectionItem:
//    * Name           - String
//    * Presentation - String
//
Function PresentationsAllAllowedFromForm(Form)
	
	OptionalAttributes = New Structure("PresentationsAllAllowed");
	FillPropertyValues(OptionalAttributes, Form);
	Return OptionalAttributes.PresentationsAllAllowed;
	
EndFunction

// For internal use only.
// See AccessManagementInternal.OnCreateAtServerAllowedValuesEditForm
//
// Returns:
//   FormDataCollection of FormDataCollectionItem:
//    * AccessKind        - DefinedType.AccessValue
//    * ValuesType       - DefinedType.AccessValue
//    * TypePresentation - String
//    * TableName        - String
//    * HierarchyOfItems - Boolean
//
Function AllTypesOfValuesToSelectFromForm(Form)
	
	OptionalAttributes = New Structure("AllTypesOfValuesToSelect");
	FillPropertyValues(OptionalAttributes, Form);
	Return OptionalAttributes.AllTypesOfValuesToSelect;
	
EndFunction

// For internal use only.
Procedure AddMetadataObjectCollectionWithRights(Collections) Export
	
	Collections.Add("Subsystems",              NStr("vi = 'Phân hệ';
													|ru = 'Подсистемы';
													|en = 'Subsystems'; fa = 'Subsystems';
													|it = 'Subsystems';
													|pl = 'Subsystems';
													|tr = 'Alt sistemler'"));
	Collections.Add("SessionParameters",         NStr("vi = 'Tham số phiên làm việc';
														|ru = 'Параметры сеанса';
														|en = 'Session parameters'; fa = 'Session parameters';
														|it = 'Parametri della sessione';
														|pl = 'Parametry sesji';
														|tr = 'Oturum parametreleri'"));
	Collections.Add("CommonAttributes",          NStr("vi = 'Mục tin chung';
														|ru = 'Общие реквизиты';
														|en = 'Common attributes'; fa = 'Common attributes';
														|it = 'Requisiti generali';
														|pl = 'Informacje ogólne';
														|tr = 'Ortak öznitelikler'"));
	Collections.Add("ExchangePlans",             NStr("vi = 'Sơ đồ trao đổi';
														|ru = 'Планы обмена';
														|en = 'Exchange plans'; fa = 'Exchange plans';
														|it = 'Piani di scambio';
														|pl = 'Plany wymiany';
														|tr = 'Değiştirme planları'"));
	Collections.Add("FilterCriteria",          NStr("vi = 'Tiêu chí lọc';
													|ru = 'Критерии отбора';
													|en = 'Filter criteria'; fa = 'معیارهای فیلتر';
													|it = 'Criteri di selezione';
													|pl = 'Kryteria wyboru';
													|tr = 'Filtre kriteri'"));
	Collections.Add("CommonForms",              NStr("vi = 'Biểu mẫu chung';
													|ru = 'Общие формы';
													|en = 'Common forms'; fa = 'Common forms';
													|it = 'Form comuni';
													|pl = 'Wspólne formularze';
													|tr = 'Ortak formlar'"));
	Collections.Add("CommonCommands",            NStr("vi = 'Lệnh chung';
														|ru = 'Общие команды';
														|en = 'Common commands'; fa = 'فرمان‌های مشترک';
														|it = 'Comandi comuni';
														|pl = 'Polecenia wspólne';
														|tr = 'Ortak komutlar'"));
	Collections.Add("WebServices",              NStr("vi = 'Web-service';
													|ru = 'Web-сервисы';
													|en = 'Web services'; fa = 'Web services';
													|it = 'Servizi web';
													|pl = 'Web services';
													|tr = 'Web servisleri'"));
	Collections.Add("HTTPServices",             NStr("vi = 'Dịch vụ HTTP';
													|ru = 'HTTP-сервисы';
													|en = 'HTTP services'; fa = 'HTTP services';
													|it = 'Servizi HTTP';
													|pl = 'HTTP services';
													|tr = 'HTTP-servisler'"));
	Collections.Add("Constants",               NStr("vi = 'Hằng';
													|ru = 'Константы';
													|en = 'Constants'; fa = 'ثابت‌ها';
													|it = 'Costanti';
													|pl = 'Constants';
													|tr = 'Sabitler'"));
	Collections.Add("Catalogs",             NStr("vi = 'Danh mục';
												|ru = 'Справочники';
												|en = 'Catalogs'; fa = 'فهرست‌ها';
												|it = 'Directory';
												|pl = 'Kartoteki';
												|tr = 'Kataloglar'"));
	Collections.Add("Documents",               NStr("vi = 'Chứng từ';
													|ru = 'Документы';
													|en = 'Documents'; fa = 'اسناد';
													|it = 'Documenti';
													|pl = 'Documents';
													|tr = 'Belgeler'"));
	Collections.Add("DocumentJournals",       NStr("vi = 'Nhật ký văn bản';
													|ru = 'Журналы документов';
													|en = 'Document journals'; fa = 'Document journals';
													|it = 'Registri dei documenti';
													|pl = 'Dzienniki dokumentów';
													|tr = 'Belge günlükleri'"));
	Collections.Add("Enums",            NStr("vi = 'Liệt kê';
											|ru = 'Перечисления';
											|en = 'Enumerations'; fa = 'Enumerations';
											|it = 'Enumerazioni';
											|pl = 'Enumerations';
											|tr = 'Transferler'"));
	Collections.Add("Reports",                  NStr("vi = 'Báo cáo';
													|ru = 'Отчеты';
													|en = 'Reports'; fa = 'گزارش‌ها';
													|it = 'Report';
													|pl = 'Reports';
													|tr = 'Raporlar'"));
	Collections.Add("DataProcessors",               NStr("vi = 'Bộ xử lý';
														|ru = 'Обработки';
														|en = 'Data processors'; fa = 'Data processors';
														|it = 'Elaborazioni';
														|pl = 'Data processors';
														|tr = 'Veri işlemcileri'"));
	Collections.Add("ChartsOfCharacteristicTypes", NStr("vi = 'Hệ thống dạng đặc tính';
														|ru = 'Планы видов характеристик';
														|en = 'Charts of characteristic types'; fa = 'Charts of characteristic types';
														|it = 'Piani dei tipi di caratteristiche';
														|pl = 'Plany rodzajów charakterystyk';
														|tr = 'Özellik türü listeleri'"));
	Collections.Add("ChartsOfAccounts",             NStr("vi = 'Hệ thống tài khoản';
														|ru = 'Планы счетов';
														|en = 'Charts of accounts'; fa = 'سرفصل‌های حساب';
														|it = 'Piani dei conti';
														|pl = 'Plany rachunków';
														|tr = 'Hesap planları'"));
	Collections.Add("ChartsOfCalculationTypes",       NStr("vi = 'Hệ thống dạng tính toán';
															|ru = 'Планы видов расчета';
															|en = 'Charts of calculation types'; fa = 'Charts of calculation types';
															|it = 'Piani dei tipi di calcolo';
															|pl = 'Plany rodzajów obliczeń';
															|tr = 'Hesaplama türü planları'"));
	Collections.Add("InformationRegisters",        NStr("vi = 'Biểu ghi thông tin';
														|ru = 'Регистры сведений';
														|en = 'Information registers'; fa = 'ثبت‌های اطلاعاتی';
														|it = 'Registri delle informazioni';
														|pl = 'Rejestry informacji';
														|tr = 'Bilgi kayıtları'"));
	Collections.Add("AccumulationRegisters",      NStr("vi = 'Biểu ghi tích lũy';
														|ru = 'Регистры накопления';
														|en = 'Accumulation registers'; fa = 'ثبت‌های انباشتی';
														|it = 'Registri di accumulo';
														|pl = 'Rejestry kumulacji';
														|tr = 'Birikim kayıtları'"));
	Collections.Add("AccountingRegisters",     NStr("vi = 'Biểu ghi kế toán';
													|ru = 'Регистры бухгалтерии';
													|en = 'Accounting registers'; fa = 'Accounting registers';
													|it = 'Registri contabilità';
													|pl = 'Rejestry księgowości';
													|tr = 'Muhasebe kayıtları'"));
	Collections.Add("CalculationRegisters",         NStr("vi = 'Biểu ghi tính toán';
														|ru = 'Регистры расчета';
														|en = 'Calculation registers'; fa = 'Calculation registers';
														|it = 'Registri di calcolo';
														|pl = 'Rejestry rozliczenia';
														|tr = 'Mutabakat işlemleri kayıtları'"));
	Collections.Add("BusinessProcesses",          NStr("vi = 'Quy trình nghiệp vụ';
														|ru = 'Бизнес-процессы';
														|en = 'Business processes'; fa = 'فرایندهای تجاری';
														|it = 'Processi aziendali';
														|pl = 'Business processes';
														|tr = 'İş süreçleri'"));
	Collections.Add("Tasks",                  NStr("vi = 'Nhiệm vụ';
													|ru = 'Задачи';
													|en = 'Tasks'; fa = 'وظایف';
													|it = 'Obiettivi';
													|pl = 'Tasks';
													|tr = 'Görevler'"));
	Collections.Add("ExternalDataSources",  NStr("vi = 'Nguồn dữ liệu ngoài';
												|ru = 'Внешние источники данных';
												|en = 'External data sources'; fa = 'External data sources';
												|it = 'Fonti dati esterne';
												|pl = 'Zewnętrzne źródła danych';
												|tr = 'Harici veri kaynakları'"));
	
EndProcedure

#EndRegion