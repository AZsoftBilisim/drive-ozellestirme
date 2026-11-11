
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ShowInvalidUsers = False;
	
	If Not Parameters.ChoiceMode Then
		
		// only if there is no selection mode, we do filtering
		
		If ShowInvalidUsers Then
			CommonClientServer.DeleteDynamicListFilterGroupItems(UsersList, "Invalid");
		Else	
			CommonClientServer.SetDynamicListFilterItem(
				UsersList,
				"Invalid",
				False);
		EndIf;
			
	EndIf;
	
	UseGroups = GetFunctionalOption("UseUserGroups");
	
	If TypeOf(Parameters.CurrentRow) = Type("CatalogRef.UserGroups") Then
		If UseGroups Then
			Items.UserGroups.CurrentRow = Parameters.CurrentRow;
		Else
			Parameters.CurrentRow = Undefined;
		EndIf;
	Else
		CurrentItem = Items.UsersList;
		Items.UserGroups.CurrentRow = Catalogs.UserGroups.AllUsers;
		UpdateDataCompositionParameterValue(UsersList, "UsersGroup", Catalogs.UserGroups.AllUsers);
		UpdateDataCompositionParameterValue(UsersList, "SelectHierarchy", True);
	EndIf;
	
	// Configuring persistent data for a list of users
	UpdateDataCompositionParameterValue(UsersList, "BlankUUID", New UUID("00000000-0000-0000-0000-000000000000"));
	AllUsersUserGroup = Catalogs.UserGroups.AllUsers;
	
	UseLimitsForDiscountAdjustmentsInSalesByUsers = GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByUsers");
	UseRetailSales = GetFunctionalOption("UseRetailSales");
	
	Items.TheUserWithAListOfTheMaximumPercentage.Visible  = UseLimitsForDiscountAdjustmentsInSalesByUsers;
	Items.UserGroupsMaximumPercentage.Visible = UseLimitsForDiscountAdjustmentsInSalesByUsers;
	
	Items.UserGroupsCWP_Use.Visible = UseRetailSales;
	Items.CWP_Use.Visible                    = UseRetailSales;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RefreshFormContentOnGroupChange();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_UserGroups" Then
		If Source = Items.UserGroups.CurrentRow Then
			Items.UsersList.Refresh();
		EndIf;
	EndIf;
	
	If EventName = "Write_SalesSettingsForUsers" Then
		Items.UsersList.Refresh();
		Items.UserGroups.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Settings[SelectHierarchy] = Undefined Then
		SelectHierarchy = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UserGroupsOnActivateRow(Item)
	
	RefreshFormContentOnGroupChange();
	
EndProcedure

&AtClient
Procedure SelectHierarchyOnChange(Item)
	
	RefreshFormContentOnGroupChange();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUserGroups

&AtClient
Procedure UserGroupsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.UserGroups.CurrentData;
	
	Ref = SalesSettingsForUsersServerCall.SettingObjectRestrictions(CurrentData.Ref);
	If Ref = Undefined Then
		FillingValues = New Structure("Owner", CurrentData.Ref);
		FormParameters = New Structure("FillingValues", FillingValues);
	Else
		FormParameters = New Structure("Key", Ref);
	EndIf;
	FormParameters.Insert("FieldName", Field.Name);
	OpenForm("Catalog.SalesSettingsForUsers.Form.ItemForm", FormParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsersList

&AtClient
Procedure UsersListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.UsersList.CurrentData;
	
	Ref = SalesSettingsForUsersServerCall.SettingObjectRestrictions(CurrentData.Ref);
	If Ref = Undefined Then
		FillingValues = New Structure("Owner", CurrentData.Ref);
		FormParameters = New Structure("FillingValues", FillingValues);
	Else
		FormParameters = New Structure("Key", Ref);
	EndIf;
	FormParameters.Insert("FieldName", Field.Name);
	OpenForm("Catalog.SalesSettingsForUsers.Form.ItemForm", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowInvalidUsers(Command)
	
	ShowInvalidUsers = Not ShowInvalidUsers;
	
	Items.FormShowInvalidUsers.Check = ShowInvalidUsers;
	
	If ShowInvalidUsers Then
		CommonClientServer.DeleteDynamicListFilterGroupItems(UsersList, "Invalid");
	Else	
		CommonClientServer.SetDynamicListFilterItem(
			UsersList,
			"Invalid",
			False);
	EndIf;
		
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
	ItemField.Field = New DataCompositionField(Items.PercentRateOfManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaximumPercentageForManualMarkup.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersList.ThereAreSpecificationsByPriceGroups");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialPrice);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UserGroupsPercentRateOfManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UserGroupsMaximumPercentageForManualMarkup.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UserGroups.ThereAreSpecificationsByPriceGroups");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialPrice);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UserGroupsPercentRateOfManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UserGroupsMaximumPercentageForManualMarkup.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UserGroups.LimitDiscountAdjustments");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không hạn chế';
													|ru = 'Нет ограничений';
													|en = 'No restrictions'; fa = 'No restrictions';
													|it = 'Niente restrizioni';
													|pl = 'Brak ograniczeń';
													|tr = 'Kısıtlama yok'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PercentRateOfManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaximumPercentageForManualMarkup.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UserGroupsPercentRateOfManualDiscount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UserGroupsMaximumPercentageForManualMarkup.Name);
	
	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, False, True, False, ));
	Item.Appearance.SetParameterValue("Format", "NFD=2; NZ=0,00");
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CWP_Use.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersList.CWP_Use");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, False, True, False, ));
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Right);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Có hạn chế';
													|ru = 'Есть ограничения';
													|en = 'There are limitations'; fa = 'There are limitations';
													|it = 'Ci sono restrizioni';
													|pl = 'Istnieją ograniczenia';
													|tr = 'Kısıtlama var'"));
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CWP_Use.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsersList.CWP_Use");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, False, True, False, ));
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Right);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không hạn chế';
													|ru = 'Нет ограничений';
													|en = 'No restrictions'; fa = 'No restrictions';
													|it = 'Niente restrizioni';
													|pl = 'Brak ograniczeń';
													|tr = 'Kısıtlama yok'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UserGroupsCWP_Use.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UserGroups.CWP_Use");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, False, True, False, ));
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Right);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Có hạn chế';
													|ru = 'Есть ограничения';
													|en = 'There are limitations'; fa = 'There are limitations';
													|it = 'Ci sono restrizioni';
													|pl = 'Istnieją ograniczenia';
													|tr = 'Kısıtlama var'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UserGroupsCWP_Use.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UserGroups.CWP_Use");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , False, False, True, False, ));
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Right);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không hạn chế';
													|ru = 'Нет ограничений';
													|en = 'No restrictions'; fa = 'No restrictions';
													|it = 'Niente restrizioni';
													|pl = 'Brak ograniczeń';
													|tr = 'Kısıtlama yok'"));

EndProcedure

#Region Other

&AtClient
Procedure RefreshFormContentOnGroupChange()
	
	If Not UseGroups
	 Or Items.UserGroups.CurrentRow = AllUsersUserGroup Then
		//
		Items.ShowUsersFromSubgroupsGroup.CurrentPage = Items.GroupPropertyCannotBeSet;
		UpdateDataCompositionParameterValue(UsersList, "SelectHierarchy", True);
		UpdateDataCompositionParameterValue(UsersList, "UsersGroup", AllUsersUserGroup);
	Else
		Items.ShowUsersFromSubgroupsGroup.CurrentPage = Items.SetPropertyGroup;
		UpdateDataCompositionParameterValue(UsersList, "SelectHierarchy", SelectHierarchy);
		UpdateDataCompositionParameterValue(UsersList, "UsersGroup", Items.UserGroups.CurrentRow);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDataCompositionParameterValue(Val ParametersOwner, Val ParameterName, Val ParameterValue)
	
	For Each Parameter In ParametersOwner.Parameters.Items Do
		If String(Parameter.Parameter) = ParameterName Then
			If Parameter.Use And Parameter.Value = ParameterValue Then
				Return;
			EndIf;
			Break;
		EndIf;
	EndDo;
	
	ParametersOwner.Parameters.SetParameterValue(ParameterName, ParameterValue);
	
EndProcedure

#EndRegion

#EndRegion
