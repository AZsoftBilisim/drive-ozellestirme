////////////////////////////////////////////////////////////////////////////////
// Client procedures and functions that control system settings (localization)
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#EndRegion

#Region Internal

// Add a settings search index.
// 
// Parameters:
//  SearchIndex - Map of KeyAndValue - The search index for form elements.
Procedure AddSettingsSearchIndex(SearchIndex) Export
	
EndProcedure

// Add search forms.
// 
// Parameters:
//  ArrayOfForms - Array of String - Array of forms to search for.
Procedure AddSearchForms(ArrayOfForms) Export
EndProcedure

#EndRegion

#Region Private

#Region EventHandlers_NSICatalogPanel_ProductClassifiers

Procedure HandlingNavigationalLinkOfForm__ProductClassifiers(Item, FormattedStringURL, StandardProcessing, Form) Export
	
	StandardProcessing = False;
	Return;
EndProcedure

#EndRegion

#Region EventHandlers_UT_PurchasingAdministrationPanel

Procedure ProcessingNavigationLinkOf__Form(Item, FormattedStringURL, StandardProcessing, Form) Export
	
	StandardProcessing = False;
	Return;
EndProcedure

Procedure WhenChanging_PurchaseDetails(Item, Form) Export
	Return
EndProcedure

#EndRegion

#Region EventHandlers_AdministrationPanelUT_Treasury

Procedure ProcessingNavigationalLinkOfForm_Treasury(Item, FormattedStringURL, StandardProcessing, Form) Export
	
	StandardProcessing = False;
	Return;
	
EndProcedure


// Handler for changing form details
// 
// Parameters:
//     Item - FormField - Changed Bank details
//     Form - ClientApplicationForm - Form settings "of the Treasury"
//
Procedure WhenChangingBankingDetails_Treasury(Item, Form) Export
	Return
EndProcedure

#EndRegion

#Region EventHandlers_AdministrationPanel_ProductSettings

Procedure ProcessingNavigationLinkOfForm_ProductSettings(Item, FormattedStringURL, StandardProcessing, Form) Export
	
	StandardProcessing = False;
	Return;
EndProcedure

Procedure OpenItemCertificateSettings(OwnerForm) Export 
	

EndProcedure

Procedure WhenYouChangeBankingDetails_ProductSettings(Item, Form) Export
	Return
EndProcedure

// The collection of parameters for changing the schedule of a routine task is being updated.
//
// Parameters:
//	Form - See DataProcessor.TMAdministrationPanel.Form.ProductSettings.
//	CommandName - String - the name of the Command that initialized the change in the schedule of the routine task.
//	JobParameters - Structure - collection of parameters for changing the schedule of a routine task.
//
Procedure AddParametersForChangingScheduleOfRoutineTask_ItemSettings(Form, CommandName, JobParameters) Export
	
	Return;
	
EndProcedure

#EndRegion

#Region EventHandlers_AdminPanel__InitialFilling

Procedure ProcessingFormSNavigationLink_InitialFilling(Item, FormattedStringURL, StandardProcessing, Form) Export
	
	StandardProcessing = False;
	Return;
EndProcedure

Procedure WhenChangingBankingDetails_InitialFilling(Item, Form) Export
	Return
EndProcedure

#EndRegion

#Region EventHandlers_AdministrationPanelUT_Sales

Procedure ProcessingNavigationLinkOf_SaleForm(Item, FormattedStringURL, StandardProcessing, Form) Export
	
	StandardProcessing = False;
	Return;
EndProcedure

// Handler ON changing Attributes
//
// Parameters:
//  Item - FormAllItems
//  Form - ClientApplicationForm
//
Procedure WhenChangingBankingDetails_Sales(Item, Form) Export
	Return
EndProcedure

#EndRegion

#Region EventHandlers_UT_EnterpriseAdministrationPanel

Procedure ProcessingNavigationLinkOfForm_Enterprise(Item, FormattedStringURL, StandardProcessing, Form) Export
	
	StandardProcessing = False;
	Return;
EndProcedure

Procedure WhenChangingBankingDetails_Enterprise(Item, Form) Export
	Return
EndProcedure

Procedure NameOfCurrencySelectionFormFromClassifier_Enterprise(DataProcessorForm) Export
	
	
EndProcedure

#EndRegion

#Region EventHandlers_AdministrationPanelUT_FinancialResult

Procedure ProcessingNavigationLinkOfForm_FinancialResult(Item, FormattedStringURL, StandardProcessing, Form) Export
	Return;
EndProcedure

Procedure WhenChangingBankingDetails_FinancialResult(Item, Form) Export
	Return
EndProcedure

#EndRegion

#Region EventHandlers_AdministrationPanelUT_WarehouseAndDelivery

Procedure WhenChangingBankDetails_WarehouseAndDelivery(Item, Form) Export
	Return
EndProcedure

#EndRegion

#Region EventHandlers_AdministrationPanelUT_HardwareSettings

// A common method for processing form commands See DataProcessor.TMAdministrationPanel.Form.CWPAndEquipmentSettings
// 
// Parameters:
//  Command - FormCommand - 
//  Form - ClientApplicationForm -
//
Procedure ProcessingCommand_SettingsOfEquipmentRMC(Command, Form) Export
	
	
	Return;
EndProcedure

#EndRegion

#Region EventHandlers_AdministrationPanelKA_Production

Procedure WhenChangingProps__(Item, Form) Export
	Return
EndProcedure

#EndRegion

#Region EventHandlers_KaAdministrationPanel_NonCurrentAssets

Procedure PushEventHandling_NonCurrentAssets(Item, Form) Export
	
	
	Return;
	
EndProcedure

Procedure WhenChangingDetailsBeginningOfSelection_NonCurrentAssets(Form, Item, ChoiceData, StandardProcessing) Export

	
	Return;
	
EndProcedure

Procedure FixedAndIntangibleAssetsAccountingOnChange(Form, Cancel) Export

	
EndProcedure

Procedure WhenLoweringVersionOfAccountingForNonCurrentAssets(Form, QueryText) Export

	
EndProcedure
 

#EndRegion

#EndRegion