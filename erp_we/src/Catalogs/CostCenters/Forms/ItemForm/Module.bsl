

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	OnReadCreateAtServer();

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);

EndProcedure


&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)

	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	CurrentObject.NotUsed = Use = "NotUsed";
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	If Not FullFunctionality Then
		Object.CostAllocationOptionLocal = Object.CostAllocationOptionManag;
		Object.CostAllocationRuleLocal = Object.CostAllocationRuleManag;
		Object.CostAllocationOptionTax = Object.CostAllocationOptionManag;
		Object.CostAllocationRuleTax = Object.CostAllocationRuleManag;
	EndIf;

EndProcedure


&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

	OnReadCreateAtServer();

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	// StandardSubsystems.Properties
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

	// Working out the visibility of form elements that are not directly related to the FO
	If EventName = "Write_ConstantsSet" Then
		FormItemsManagement();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseOnChange(Item)
	Modified = True;
EndProcedure

&AtClient
Procedure ExpensesOccurOnChange(Item)
	
	ProcessAssignmentDirectionSwitching();
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure CostAllocationOptionManagOnChange(Item)
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure CostAllocationOptionLocalOnChange(Item)
	
	Object.CostAllocationOptionTax = Object.CostAllocationOptionLocal;
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure CostAllocationOptionTaxOnChange(Item)
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure SwitchToUseFullFeaturesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	FullFunctionality = True;
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure SwitchToDisableFullFeaturesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	FullFunctionality = False;
	CallbackDescription = New CallbackDescription("SwitchDisableFullAlertCapabilities", ThisObject);
	ShowQueryBox(CallbackDescription, 
		StrTemplate(NStr("vi = 'Khi tắt tính năng đầy đủ, tất cả tùy chỉnh gắn với giá trị tùy chỉnh kế toán quản trị.%1 
		|Tiếp tục?';
		|ru = 'При отключении полных возможностей все настройки приравниваются к значению настроек упр. учета.%1 
		|Продолжить?';
		|en = 'If you disable the full mode, all the settings become equal to management accounting settings.%1 
		|Continue?'; fa = 'If you disable the full mode, all the settings become equal to management accounting settings.%1 
		|Continue?';
		|it = 'Alla disattivazione delle piene funzionalità, tutte le impostazioni vengono adeguate al valore delle impostazioni della contabilità gestionale.%1
		|Continuare?';
		|pl = 'Przy wyłączeniu pełnych możliwości wszystkie ustawienia przyrównywane do wartości ustawień ewidencji zarządczej.%1 
		|Kontynuować?';
		|tr = 'Tüm fırsatlar reddedildiğinde, tüm ayarlar yönetim muhasebe ayarlarının değerine eşitleniyor.%1 
		|Devam edilsin mi?'"), Chars.CR), QuestionDialogMode.YesNoCancel);
EndProcedure

&AtClient
Procedure TheRuleOfAllocationOfCommonCostsOnChange(Item)

	BringOptionsAndRulesToManSettings();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)

	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);

EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		
		OpenForm("Catalog.CostCenters.Form.AttributeUnlocking",,,,,, 
		New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
		FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
    
    If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
        ObjectAttributesLockClient.SetFormItemEnabled(ThisObject, Result);
    EndIf;

EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties 

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);

EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()

	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);

EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)

	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);

EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	// General settings or full features
	Items.AGroupOfSimpleFeatures.Visible = Not FullFunctionality;
	Items.FullFeaturesGroup.Visible = FullFunctionality;

	// Settings for selections and parameters for creating new rules
	PurposeOfTheUprRule = Catalogs.CostAllocationRules.GetRuleAssignmentForDistributionOption(Object.CostAllocationOptionManag);
	PurposeOfTheReglRule = Catalogs.CostAllocationRules.GetRuleAssignmentForDistributionOption(Object.CostAllocationOptionLocal);
	
	// Distribution rules
	Items.CostAllocationRuleManag.Visible = Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToCostCenters 
		Or Enums.CostAllocationOptions.VariantUsesAllocationRule(Object.CostAllocationOptionManag);
	Items.CostAllocationRuleLocal.Visible = Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCostCenters 
		Or Enums.CostAllocationOptions.VariantUsesAllocationRule(Object.CostAllocationOptionLocal);
	Items.TheRuleOfAllocationOfCommonCosts.Visible = Items.CostAllocationRuleManag.Visible;
	
	// Inscriptions
	Items.TheLabelDoesNotRequireTheDistributionOfUpr.Visible = 
		Not Object.CostAllocationOptionManag.IsEmpty() 
		And Not (Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToCostCenters) 
		And Enums.CostAllocationOptions.OptionWithoutDistribution(Object.CostAllocationOptionManag);
	Items.TheLabelDoesNotRequireTheDistributionOfRegl.Visible = 
		Not Object.CostAllocationOptionLocal.IsEmpty() 
		And Not (Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCostCenters) 
		And Enums.CostAllocationOptions.OptionWithoutDistribution(Object.CostAllocationOptionLocal);
	Items.LabelDistributionRuleReglAsUpr.Visible = 
		Not Object.CostAllocationOptionLocal.IsEmpty() 
		And Not Enums.CostAllocationOptions.VariantUsesAllocationRule(Object.CostAllocationOptionLocal) 
		And Not Enums.CostAllocationOptions.OptionWithoutDistribution(Object.CostAllocationOptionLocal) 
		And (Object.CostAllocationOptionManag = Object.CostAllocationOptionLocal);
	Items.InscriptionDoesNotRequireDistribution.Visible = Items.TheLabelDoesNotRequireTheDistributionOfUpr.Visible; 
	
	
	// Functional settings
	ProductionOptions = New Array();
	ProductionOptions.Add(Enums.CostAllocationOptions.ToProductionCosts);
	ProductionOptions.Add(Enums.CostAllocationOptions.ToProductionCostDirect);
	
	Items.ProductionSetupGroup.Visible = 
		ProductionOptions.Find(Object.CostAllocationOptionManag)<>Undefined
		Or ProductionOptions.Find(Object.CostAllocationOptionLocal)<>Undefined
		Or CalculationOfCostLocalization.GetFunctionalOptionAITAccounting()
			And (Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToLinesOfBusiness
				Or Object.CostAllocationOptionTax = Enums.CostAllocationOptions.ToLinesOfBusiness)
		Or False;
	
EndProcedure

&AtServer
Procedure DetermineUseOfFullCapabilities()
	
	FullFunctionality = False;
	
	FullFunctionality = (Object.CostAllocationOptionManag <> Object.CostAllocationOptionLocal);
	If FullFunctionality Then
		Return;
	EndIf;
	FullFunctionality = FullFunctionality Or (Object.CostAllocationOptionLocal <> Object.CostAllocationOptionTax);
	FullFunctionality = FullFunctionality Or (Object.CostAllocationOptionManag <> Object.CostAllocationOptionTax);
	If FullFunctionality Then
		Return;
	EndIf;
	
	Rules = New Map();
	If Object.CostAllocationOptionManag = Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToLinesOfBusiness 
			Or Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToCostCenters 
			Or Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToDeferredExpenses 
			Or Object.CostAllocationOptionManag = Enums.CostAllocationOptions.ToProductionCosts 
	Then
		Rules.Insert(Object.CostAllocationRuleManag);
	EndIf;
	
	If Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToLinesOfBusiness 
			Or Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToCostCenters 
			Or Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToDeferredExpenses 
			Or Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToProductionCosts 
	Then
		Rules.Insert(Object.CostAllocationRuleLocal);
	EndIf;

	If Object.CostAllocationOptionLocal = Enums.CostAllocationOptions.ToDeferredExpenses 
	Then
		Rules.Insert(Object.CostAllocationRuleTax);
	EndIf;

	FullFunctionality = FullFunctionality Or Rules.Count() > 1;
	
EndProcedure

#EndRegion

#Region OtherOnClient
&AtClient
Procedure SwitchDisableFullAlertCapabilities(QuestionResult, AdditionalParameters) Export
	
	If (QuestionResult = DialogReturnCode.Yes) Then
		BringOptionsAndRulesToManSettings();
		FormItemsManagement();
	EndIf;
	
EndProcedure
#EndRegion


#Region OtherOnServer

&AtServer
Procedure OnReadCreateAtServer()
	
	DetermineUseOfFullCapabilities();
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(ThisObject);
	FormItemsManagement();
	Use = ?(Object.NotUsed, "NotUsed","Used")
	
EndProcedure

&AtServer
Procedure ProcessAssignmentDirectionSwitching()

	DefaultOption = Enums.CostAllocationOptions.DoNotAllocate;
	DefaultRule = Catalogs.CostAllocationRules.EmptyRef();
	If (Object.ExpensesOccur = Enums.ExpenseTypes.ExpenseToCostCenters) Then
		DefaultOption = Enums.CostAllocationOptions.ToCostCenters;
	ElsIf (Object.ExpensesOccur = Enums.ExpenseTypes.OtherExpenses) Then
		DefaultOption = Enums.CostAllocationOptions.ToProductionCosts;
	EndIf;
	Object.CostAllocationOptionManag =	DefaultOption;
	Object.CostAllocationOptionLocal =	DefaultOption;
	Object.CostAllocationOptionTax =		DefaultOption;
	Object.CostAllocationRuleManag =	DefaultRule;
	Object.CostAllocationRuleLocal =	DefaultRule;
	Object.CostAllocationRuleTax =		DefaultRule;

EndProcedure

&AtServer
Procedure BringOptionsAndRulesToManSettings()
	
	Object.CostAllocationOptionLocal = Object.CostAllocationOptionManag; 
	Object.CostAllocationRuleLocal = Object.CostAllocationRuleManag;
	
	Object.CostAllocationOptionTax = Object.CostAllocationOptionManag; 
	Object.CostAllocationRuleTax = Object.CostAllocationRuleManag;
	 
EndProcedure

#EndRegion
