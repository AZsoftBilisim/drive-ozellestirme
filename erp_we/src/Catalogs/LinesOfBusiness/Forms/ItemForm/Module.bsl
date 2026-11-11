
#Region Variables

&AtClient
Var RefreshInterface;

&AtClient
Var ObjectRecorded;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Object.Ref.IsEmpty() Then
		Object.Status = Enums.LineOfBusinessStatuses.Used;
		WhenReadingCreating();
	EndIf;
	
	NotUT = Not GetFunctionalOption("TradeManagement");
	Items.GroupTypeOfActivity.Visible = GetFunctionalOption("SupportOfBankingAndTreasuryStateContracts") And NotUT;
	Items.AccountingObjectsGroup.Visible = NotUT;
	Items.GroupNonCurrentAssets.Enabled = Object.CostAccounting;
	Items.TheGroupTaxationRegime.Visible = GetFunctionalOption("UseSeparateAccountingByTaxation") And NotUT;
	Items.GroupSeparationBeyondTheNeedsOfTheIndentation.Visible = GetFunctionalOption("UseOrderSupplyWithAssignment");
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ConfigureItemAvailability(ThisObject);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	
	LinesOfBusinessLocalization.WhenCreatingElementFormOnServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	WhenReadingCreating();
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	FormEvents.OnReadAtServer(ThisForm, CurrentObject);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
	LinesOfBusinessLocalization.OnReadAtServerItemForm(ThisObject, CurrentObject);
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit And RefreshInterface = True And ObjectRecorded = True Then
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ObjectRecorded = True;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure IncomeAccountingOnChange(Item)
	
	RefreshInterface = True;
	
EndProcedure

&AtClient
Procedure CostAccountingOnChange(Item)
	
	RefreshInterface = True;
	
	If Not Object.CostAccounting Then
		CashManagement = False;
		Object.CashAndBankAccountsSeparately = False;
		Object.CashAndBankAccountsByCorrespondence = False;
		Object.FixedAndIntangibleAssetsAccounting = False;
		Object.ExcessOfAssignedGoodsAndLaborDemandIsAllowed = True;
	EndIf;
	
	SetItemsAvailability(ThisObject);
	
EndProcedure

&AtClient
Procedure CashOnChange(Item)
	
	RefreshInterface = True;
	
	If CashManagement Then
		Object.CashAndBankAccountsSeparately = True;
		CashManagementMethod = "SeparateAccounting";
	Else
		Object.CashAndBankAccountsSeparately = False;
		Object.CashAndBankAccountsByCorrespondence = False;
		CashManagementMethod = "";
	EndIf;
	
	SetItemsAvailability(ThisObject);
	
EndProcedure

&AtClient
Procedure NonCurrentAssetsOnChange(Item)
	
	RefreshInterface = True;
	
EndProcedure

&AtClient
Procedure CashManagementMethodOnChange(Item)
	
	RefreshInterface = True;
	
	Object.CashAndBankAccountsSeparately = CashManagementMethod = "SeparateAccounting";
	Object.CashAndBankAccountsByCorrespondence = Not Object.CashAndBankAccountsSeparately;
	
EndProcedure

&AtClient
Procedure TaxRegimeInCaseOfChange(Item)
	
	If TaxationTreatment = 1 Then
		Object.VATTaxationIsDeterminedInDocuments = True;
		Object.VATTaxation = Undefined;
	Else
		Object.VATTaxationIsDeterminedInDocuments = False;
	EndIf;
	
	Items.VATTaxation.Enabled = Not Object.VATTaxationIsDeterminedInDocuments;
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingLocalizationAttribute(Item)
	
	LinesOfBusinessClientLocalization.OnChangeAttribute(Item.Name, ThisForm);
	
EndProcedure

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, Var_Parameters = Undefined) Export
	
	If Var_Parameters.ServerCallRequired_ Then
		AtEndOfChangingLocalizationDetailsOnServer(TagName);
	EndIf;
	
	SetItemsAvailability(ThisObject);
	
EndProcedure

&AtServer
Procedure AtEndOfChangingLocalizationDetailsOnServer(TagName)
	
	LinesOfBusinessLocalization.OnChangeAttribute(TagName, ThisForm);
	
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	Items.NameForPrinting.ChoiceList.Clear();
	Items.NameForPrinting.ChoiceList.Add(Object.Description);
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	Notification = New CallbackDescription("UnblockingAttributesOfObjectEnd", ThisObject);
	UnlockOptions = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	UnlockOptions.Insert("NotificationAboutUnblocking", Notification);
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm, UnlockOptions);
	SetItemsAvailability(ThisObject);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteLocalizationCommand(Command)
	
	LinesOfBusinessClientLocalization.ExecuteCommand(CurrentItem.Name, ThisForm);
	
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, Var_Parameters) Export
	
	If Var_Parameters.ServerCallRequired_ Then
		RunLocalizationCommandOnServer(CommandName);
	EndIf;
	
EndProcedure

&AtServer
Procedure RunLocalizationCommandOnServer(CommandName)
	
	LinesOfBusinessLocalization.ExecuteCommand(CommandName, ThisForm);
	
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure WhenReadingCreating()
	
	CashManagement = Object.CashAndBankAccountsSeparately Or Object.CashAndBankAccountsByCorrespondence;
	
	If Object.CashAndBankAccountsSeparately Then
		CashManagementMethod = "SeparateAccounting";
	ElsIf Object.CashAndBankAccountsByCorrespondence Then
		CashManagementMethod = "ByCorrespondence";
	EndIf;
	
	FillParameters = Catalogs.LinesOfBusiness.FillingParametersTaxationVATSales();
	VATAccountingERP.FillInSalesVATTaxSelectionList(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	
	If Object.VATTaxationIsDeterminedInDocuments Then
		TaxationTreatment = 1;
	Else
		TaxationTreatment = 0;
	EndIf;
	
	Items.VATTaxation.Enabled = Not Object.VATTaxationIsDeterminedInDocuments;
	
	LinesOfBusinessLocalization.OnReadCreateAtServer(ThisForm);
	
	SetItemsAvailability(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetItemsAvailability(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	
	Items.GroupSeparationBeyondTheNeedsOfTheIndentation.Enabled = Object.CostAccounting;
	Items.GroupNonCurrentAssets.Enabled = Object.CostAccounting;
	Items.GroupMethodOfAccountingForTheDS.Enabled = Form.CashManagement;

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureItemAvailability(Form)

	Return;

EndProcedure

&AtClient
Procedure UnblockingAttributesOfObjectEnd(Result, AdditionalParameters) Export

	If Result = True Then
		ConfigureItemAvailability(ThisObject);
	EndIf;

EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
