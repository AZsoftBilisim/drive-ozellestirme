#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetOptionsForAllocatingExpensesByExpenseItemSettings();
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(ThisObject);
	SetFormItemsVisibility();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("ChangedSettingsForDistributionOfItemByItemExpenses");
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ConstantsSet" And Source = "UseLocal" Then
		SetFormItemsVisibility();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExpenseItemOnChange(Item)
	SetOptionsForAllocatingExpensesByExpenseItemSettings();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetOptionsForAllocatingExpensesByExpenseItemSettings()
	
	ExpenseItem = Common.ObjectAttributesValues(Record.ExpenseItem, 
		"CostAllocationOptionManag,CostAllocationOptionLocal,CostAllocationOptionTax") ;
	CostAllocationOptionManag =	ExpenseItem.CostAllocationOptionManag;
	CostAllocationOptionLocal =	ExpenseItem.CostAllocationOptionLocal;
	CostAllocationOptionTax =	ExpenseItem.CostAllocationOptionTax;

	YouCanConfigureMan = 
		Enums.CostAllocationOptions.VariantUsesAllocationRule(CostAllocationOptionManag);
	YouCanConfigureLocal = 
		Enums.CostAllocationOptions.VariantUsesAllocationRule(CostAllocationOptionLocal);
	CanBeCustomizedTa = Not CostAllocationOptionTax = CostAllocationOptionLocal And 
		Enums.CostAllocationOptions.VariantUsesTaAllocationRule(CostAllocationOptionTax);

	If Not YouCanConfigureMan And ValueIsFilled(Record.SettingsManAccounting) Then
		Record.SettingsManAccounting = Undefined;
		Modified = True;
	EndIf;
	If Not YouCanConfigureLocal And ValueIsFilled(Record.SettingsLocal) Then
		Record.SettingsLocal = Undefined;
		Modified = True;
	EndIf;
	If Not CanBeCustomizedTa And ValueIsFilled(Record.SettingsTaxAccounting) Then
		Record.SettingsTaxAccounting = Undefined;
		Modified = True;
	EndIf;
	
	Items.SettingsManAccounting.Enabled =		YouCanConfigureMan;
	Items.SettingsLocal.Enabled =	YouCanConfigureLocal;
	Items.SettingsTaxAccounting.Enabled =		CanBeCustomizedTa;
	
	StringIsNotConfigurable = NStr("vi = 'chưa được tùy chỉnh theo từng doanh nghiệp và bộ phận';
									|ru = 'не настраивается в разрезе организаций и подразделний';
									|en = 'cannot be set by companies and business units'; fa = 'cannot be set by companies and business units';
									|it = 'не настраивается в разрезе организаций и подразделний';
									|pl = 'cannot be set by companies and business units';
									|tr = 'iş yeri ve departman kesitinde ayarlanmaz'");
	Items.SettingsManAccounting.InputHint =	?(YouCanConfigureMan, "", StringIsNotConfigurable);
	Items.SettingsLocal.InputHint =	?(YouCanConfigureLocal, "", StringIsNotConfigurable);
	Items.SettingsTaxAccounting.InputHint =	?(CanBeCustomizedTa, "", StringIsNotConfigurable);
	
	// Settings for selections and parameters for creating new rules
	PurposeOfTheUprRule = Catalogs.CostAllocationRules.GetRuleAssignmentForDistributionOption(CostAllocationOptionManag);
	PurposeOfTheReglRule = Catalogs.CostAllocationRules.GetRuleAssignmentForDistributionOption(CostAllocationOptionLocal);
	TaRuleAssignment = Catalogs.CostAllocationRules.GetRuleAssignmentForDistributionOption(CostAllocationOptionTax);
	
EndProcedure

&AtServer
Procedure SetFormItemsVisibility()
	
	
EndProcedure 

#EndRegion
