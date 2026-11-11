#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If GLAccountSettingsServer.LocalAccountingAccountsCanBeConfigured() Then
		Items.RegulatedAccountingGroup.Visible = True;
	Else
		Items.RegulatedAccountingGroup.Visible = False;
		Items.AGroupOfInternationalAccounting.Title = "";
	EndIf;
	
	If GLAccountSettingsServer.SettingUpInternationalAccountingAccountsIsAvailable() Then
		Items.AGroupOfInternationalAccounting.Visible = True;
		DefaultChartOfAccountsForInternationalAccounting = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	Else
		Items.AGroupOfInternationalAccounting.Visible = False;
		Items.RegulatedAccountingGroup.Title = "";
	EndIf;
	
	If ValueIsFilled(Object.SettingsOwner)
		And AccessRight("Read", Metadata.FindByType(TypeOf(Object.SettingsOwner)))
		And CommonClientServer.HasAttributeOrObjectProperty(Object.SettingsOwner, "Organization") Then
		Organization = Common.ObjectAttributeValue(Object.SettingsOwner, "Organization");
	EndIf;
	
EndProcedure

#EndRegion


#Region FormHeaderItemsEventHandlers


#EndRegion


#Region FormTableItemsEventHandlersFinancialAccountingSettings

&AtClient
Procedure FinancialAccountingSettingsGLAccountOnChange(Item)
	
	CurrentData = Items.FinancialAccountingSettings.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	AccountProperties = FinancialAccountingServerCall.AccountProperties(CurrentData.GLAccount);
	
	For IndexOf = 1 To 3 Do
		If IndexOf <= AccountProperties.ExtDimensionCount Then
			ExtdimensionValueType = AccountProperties["ExtDimensionType" + IndexOf + "ValueType"];
			ExtraDimensionValue = ExtdimensionValueType.AdjustValue(CurrentData["ExtDimension" + IndexOf]);
			CurrentData["ExtDimension" + IndexOf] = ExtraDimensionValue;
		Else 
			CurrentData["ExtDimension" + IndexOf] = Undefined;
		EndIf;
	EndDo;
	
	ManagingElementsOfInternationalAccountingForm(ThisObject, CurrentData.GetID());
EndProcedure

&AtClient
Procedure FinancialAccountingSettingsExtDimension1OnChange(Item)
	
	CurrentData = Items.FinancialAccountingSettings.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	ChangeExtdimensionFieldSelectionParametersInt(CurrentData);
EndProcedure

&AtClient
Procedure FinancialAccountingSettingsExtDimension2OnChange(Item)
	
	CurrentData = Items.FinancialAccountingSettings.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	ChangeExtdimensionFieldSelectionParametersInt(CurrentData);
EndProcedure

&AtClient
Procedure FinancialAccountingSettingsExtDimension3OnChange(Item)
	
	CurrentData = Items.FinancialAccountingSettings.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	ChangeExtdimensionFieldSelectionParametersInt(CurrentData);
EndProcedure

&AtClient
Procedure FinancialAccountingSettingsOnActivateRow(Item)
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	ManagingElementsOfInternationalAccountingForm(ThisObject, CurrentData.GetID());
EndProcedure

&AtClient
Procedure FinancialAccountingSettingsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	If NewRow And Not Copy Then
		CurrentData.ChartOfAccounts = DefaultChartOfAccountsForInternationalAccounting;
	EndIf;
EndProcedure

&AtClient
Procedure FinancialAccountingSettingsBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	If Object.FinancialAccountingSettings.Count() > 0 Then
		Cancel = ValueIsFilled(DefaultChartOfAccountsForInternationalAccounting);
	EndIf;
	Return;
	
EndProcedure

#EndRegion


#Region Private


&AtClient
Procedure ChangeExtdimensionFieldSelectionParametersInt(CurrentData)
	
	WriteParameters = GLAccountSettingsClientServer.ExtdimensionSelectionOptions(
		Organization,
		CurrentData,
		"ExtDimension" + "%IndexOf%",
		"GLAccount");
		
	GLAccountSettingsClientServer.ChangeExtdimensionFieldSelectionParameters(
		ThisObject,
		CurrentData,
		"ExtDimension" + "%IndexOf%",
		"FinancialAccountingSettingsExtDimension" + "%IndexOf%",
		WriteParameters); 
	
EndProcedure
//
&AtClientAtServerNoContext
Procedure ManagingElementsOfInternationalAccountingForm(Form, RowID)
	
	CurrentData = Form.Object.FinancialAccountingSettings.FindByID(RowID);
	
	FormFields = New Structure("ExtDimension1, ExtDimension2, ExtDimension3",
		"FinancialAccountingSettingsExtDimension1", "FinancialAccountingSettingsExtDimension2", "FinancialAccountingSettingsExtDimension3");
	
	AccountProperties = FinancialAccountingServerCall.AccountProperties(CurrentData.GLAccount);
	
	For IndexOf = 1 To 3 Do
		If IndexOf <= AccountProperties.ExtDimensionCount Then
			ExtdimensionValueType = AccountProperties["ExtDimensionType" + IndexOf + "ValueType"];
			Form.Items[FormFields["ExtDimension" + IndexOf]].TypeRestriction = ExtdimensionValueType;
			Form.Items[FormFields["ExtDimension" + IndexOf]].InputHint  = AccountProperties["ExtDimensionType" + IndexOf + "Description"];
			Form.Items[FormFields["ExtDimension" + IndexOf]].Enabled = True;
		Else
			Form.Items[FormFields["ExtDimension" + IndexOf]].Enabled = False;
		EndIf;
	EndDo;
	
EndProcedure


#EndRegion


