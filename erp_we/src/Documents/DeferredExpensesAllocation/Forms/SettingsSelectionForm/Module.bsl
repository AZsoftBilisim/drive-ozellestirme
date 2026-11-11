
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	AccountingForLocal = GetFunctionalOption("UseAccountingOfOtherIncomeExpensesInLocalAccounting");

	RuleMa = Parameters.CostAllocationRuleManag;
	DocumentMA = Parameters.DocumentMan;
	Items.GroupManagementAccounting.Visible = Parameters.Property("ManagementAccounting") And Parameters.ManagementAccounting;
	Items.GroupCreateManAccounting.Visible = Not ValueIsFilled(DocumentMA);
	Items.DocumentMA.Visible = ValueIsFilled(DocumentMA);

	RURule = Parameters.CostAllocationRuleLocal;
	UrlDocument = Parameters.DocumentCompl;
	Items.RegulatedAccountingGroup.Visible = 
		AccountingForLocal And Parameters.Property("LocalAccounting") And Parameters.LocalAccounting;
	Items.GroupCreateLocalAccounting.Visible = Not ValueIsFilled(UrlDocument);
	Items.UrlDocument.Visible = ValueIsFilled(UrlDocument);
	RuleTa = Parameters.CostAllocationRuleTax;
	DocumentTA = Parameters.DocumentTA;
	Items.LocalizationGroupTaxAccounting.Visible = 
		AccountingForLocal And Parameters.Property("TaxAccounting") And Parameters.TaxAccounting;
	Items.GroupCreateTaxAccounting.Visible = Not ValueIsFilled(DocumentTA);
	Items.DocumentTA.Visible = ValueIsFilled(DocumentTA);
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(ThisForm);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FormItemsManagement();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ManagementAccountingOnChange(Item)
	If ManagementAccounting And Not ValueIsFilled(RBPRule) Then
		RBPRule = RuleMa;
		LocalAccounting = RURule = RBPRule;
		TaxAccounting = RuleTa = RBPRule;
	Else
		CheckRelevanceOfRBPRule();
	EndIf;
	FormItemsManagement()
EndProcedure

&AtClient
Procedure LocalAccountingOnChange(Item)
	If LocalAccounting And Not ValueIsFilled(RBPRule) Then
		RBPRule = RURule;
		ManagementAccounting = RuleMa = RBPRule;
		TaxAccounting = RuleTa = RBPRule;
	Else
		CheckRelevanceOfRBPRule();
	EndIf;
	FormItemsManagement()
EndProcedure

&AtClient
Procedure TaxAccountingOnChange(Item)
	If TaxAccounting And Not ValueIsFilled(RBPRule) Then
		RBPRule = RuleTa;
		ManagementAccounting = RuleMa = RBPRule;
		LocalAccounting = RURule = RBPRule;
	Else
		CheckRelevanceOfRBPRule();
	EndIf;
	FormItemsManagement()
EndProcedure

&AtClient
Procedure RuleMaOnChange(Item)
	FormItemsManagement()
EndProcedure

&AtClient
Procedure RURuleOnChange(Item)
	FormItemsManagement()
EndProcedure

&AtClient
Procedure RuleTaOnChange(Item)
	FormItemsManagement()
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Create(Command)
	Result = New Structure("RBPRule", RBPRule);
	Result.Insert("ManagementAccounting", ManagementAccounting);
	Result.Insert("LocalAccounting", LocalAccounting);
	Result.Insert("TaxAccounting", TaxAccounting);
	Close(Result);
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtClient
Procedure FormItemsManagement()
	
	Items.ManagementAccounting.Enabled = Not ValueIsFilled(RBPRule) Or RuleMa = RBPRule;
	Items.RuleMa.Enabled = Not ManagementAccounting;
	
	Items.LocalAccounting.Enabled = Not ValueIsFilled(RBPRule) Or RURule = RBPRule;
	Items.RURule.Enabled = Not LocalAccounting;
	Items.TaxAccounting.Enabled = Not ValueIsFilled(RBPRule) Or RuleTa = RBPRule;
	Items.RuleTa.Enabled = Not TaxAccounting;
	Items.FormCreate.Enabled = ValueIsFilled(RBPRule);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CheckRelevanceOfRBPRule()
	If Not ManagementAccounting 
		And Not LocalAccounting
		And Not TaxAccounting
	 Then
		RBPRule = Catalogs.CostAllocationRules.EmptyRef();
	EndIf;
EndProcedure



#EndRegion