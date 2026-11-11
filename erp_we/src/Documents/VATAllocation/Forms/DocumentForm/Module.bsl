
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not TMDataExchange.MonthClosingOperationsAreAvailableInThisNode(Cancel) Then
		Return;
	EndIf;
	
	If Parameters.Property("RegistrationPeriod") Then
		Object.Date = Parameters.RegistrationPeriod;
	EndIf;
	
	// Control of document creation in a subordinate RIB node with filters
	DataExchangeTMERP.ControlOfCreationOfDocumentsInDistributedInformationSecurity(Object, Cancel);

	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.VATAllocation.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormItemsManagement();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	Items.GroupComment.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();

	ItemsAndDimensionsSelectionParameters = Documents.VATAllocation.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateCaptionPeriod();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	Notify("Write_VATAllocation");
	
	DocumentCorrectionClient.AfterWrite(Object);
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Items.GroupComment.Picture = CommonClientServer.CommentPicture(Object.Comment);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	PeriodOnChangeServer();
	UpdateCaptionPeriod();
	
EndProcedure

&AtClient
Procedure BaseRevenueOnChange(Item)
	
	BaseRevenueOnChangeLocalization(Item.Name);
	
EndProcedure

&AtClient
Procedure WriteOffVATByExpensesAndAssetsToRecordItemsOnChange(Item)
	
	WriteOffVATByExpensesAndAssetsToRecordItemsOnChangeServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	UpdateCaptionPeriod();
	
EndProcedure

&AtClient
Procedure CostItemNotVATStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OptionOfVATAllocationBaseDeterminationOnChange(Item)
	
	OptionOfVATAllocationBaseDeterminationOnChangeServer();
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure Fill(Command)
	
	FillInRevenueDistributionDatabase();
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateRevenueDataServer();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure OptionOfVATAllocationBaseDeterminationOnChangeServer()
	
	Object.AllocationBaseIsSetManually = 
		?(OptionOfVATAllocationBaseDetermination = 1, True, False);
		
	If Object.AllocationBaseIsSetManually Then
		FillInRevenueDistributionDatabase();
	Else
		UpdateRevenueDataServer();
	EndIf;
	
	FormItemsManagement();
	
EndProcedure

#EndRegion

#Region InitializationAndFilling

&AtServer
Procedure OnReadCreateAtServer()
	
	UpdateAccountingPolicySettings();
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	AccountingOfOtherIncomeExpensesIsUsed = GetFunctionalOption("UseAccountingOfOtherIncomeExpenses");
	
	OptionOfVATAllocationBaseDetermination = ?(Object.AllocationBaseIsSetManually, 1, 0);
	
	If Not Object.AllocationBaseIsSetManually Then
		UpdateRevenueDataServer();
	EndIf;
	
	OnReadCreateAtServerLocalization();
	
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(ThisObject);
EndProcedure

&AtServer
Procedure FormItemsManagement()

	Items.AllocationBaseGroup.CurrentPage = 
		?(Object.AllocationBaseIsSetManually,
			Items.TheBaseGroupIsSpecifiedManually,
			Items.TheBaseGroupIsSpecifiedAutomatically);
	
	FormItemsManagementLocalization(ThisObject);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	RulesForDebiting = Documents.VATAllocation.FillInRulesForDebitingVAT(Object.Organization);
	FillPropertyValues(Object,RulesForDebiting);
	
	UpdateAccountingPolicySettings();
	
	ItemsAndDimensionsSelectionParameters = Documents.VATAllocation.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure PeriodOnChangeServer()
	
	UpdateAccountingPolicySettings();
	ItemsAndDimensionsSelectionParameters = Documents.VATAllocation.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure WriteOffVATByExpensesAndAssetsToRecordItemsOnChangeServer()

	ItemsAndDimensionsSelectionParameters = Documents.VATAllocation.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure SetStartOfPeriod()
	
	If Not ValueIsFilled(Object.Organization) Then
		Return;
	EndIf;
	
	CorrectionStructure = New Structure("Patch, CorrectedDocument");
	FillPropertyValues(CorrectionStructure, Object);
	Documents.VATAllocation.SetStartOfPeriod(Object.BeginOfPeriod, Object.Date, Object.Organization, CorrectionStructure);
	
EndProcedure

&AtServer
Procedure UpdateAccountingPolicySettings()
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"VATAccountingSettings",
		Object.Organization,
		?(Object.Patch, Common.ObjectAttributeValue(Object.CorrectedDocument, "Date"), Object.Date));
		
	If AccountingPolicyParameters <> Undefined Then
		FrequencyOfVATAllocation = AccountingPolicyParameters.FrequencyOfVATAllocation;
	EndIf;
	SetStartOfPeriod();
	UpdateAccountingPolicySettingsLocalization();
	
EndProcedure

&AtClient
Procedure UpdateCaptionPeriod()
	
	If FrequencyOfVATAllocation = PredefinedValue("Enum.Periodicity.Month") Then
		PeriodPresentation = Format(Object.BeginOfPeriod, NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
																|ru = 'ДФ=''ММММ гггг ""г.""''';
																|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
																|it = 'ДФ=''ММММ гггг ""a.""''';
																|pl = 'DF=''ММММ yyyy ""r.""''';
																|tr = 'DF=''MMMM yyyy ""yıl.""'''"));
	Else
		PeriodPresentation = Format(Object.BeginOfPeriod, NStr("vi = 'ДФ=''к ""Quý"" ""năm"" гггг''';
																|ru = 'ДФ=''к ""Квартал"" гггг  ""г.""''';
																|en = 'DF=''q ""Quarter"" yyyy  ""y.""'''; fa = 'DF=''q ""Quarter"" yyyy  ""y.""''';
																|it = 'ДФ=''в ''''Trimestre'''' aaaa  ''''a.''''''';
																|pl = 'DF=''q ""Kwartał"" yyyy  ""r.""''';
																|tr = 'DF=''ç ""Çeyrek"" yyyy  ""y.""'''"));
	EndIf;
	
	LabelPeriod = PeriodPresentation;
	UpdateCaptionPeriodLocalization();
	
EndProcedure

#EndRegion

#Region AutoFill

&AtServer
Procedure FillInRevenueDistributionDatabase()
	
	AdditionalRevenueGenerationParameters = New Structure();
	AdditionalRevenueGenerationParameters.Insert("DateOfDistribution", Object.Date);
	
	Result = Documents.VATAllocation.GetVATDistributionBase(
					?(Object.Patch, Common.ObjectAttributeValue(Object.CorrectedDocument, "Date"), Object.Date),
					Object.BeginOfPeriod,
					Object.Organization,
					AdditionalRevenueGenerationParameters);
	Documents.VATAllocation.FillInDistributionDatabase(Object, Result);
	
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure UpdateRevenueDataServer()
	
	AdditionalRevenueGenerationParameters = New Structure();
	AdditionalRevenueGenerationParameters.Insert("DateOfDistribution", Object.Date);
	
	Result = Documents.VATAllocation.GetVATDistributionBase(
					?(Object.Patch, Common.ObjectAttributeValue(Object.CorrectedDocument, "Date"), Object.Date),
					Object.BeginOfPeriod,
					Object.Organization,
					AdditionalRevenueGenerationParameters);
	Documents.VATAllocation.FillInDistributionDatabase(ThisObject, Result);
	Documents.VATAllocation.FillInDistributionDatabase(Object, Result);
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure EditDocumentsExport(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("TempStorageAddress", CommitDatabaseExportDocumentsIntoTemporaryStorage());
	FormParameters.Insert("EditMode", True);
	FormParameters.Insert("Organization", Object.Organization);
	
	CallbackDescription = New CallbackDescription("FormDocumentsExportClosing", ThisObject);
	OpenForm("Document.VATAllocation.Form.FormOfDocumentsExport", FormParameters, ThisForm, , , , CallbackDescription);
	
EndProcedure

&AtServer
Function CommitDatabaseExportDocumentsIntoTemporaryStorage()
	
	Return PutToTempStorage(Object.DocumentsExport.Unload(), UUID);
	
EndFunction

&AtClient
Procedure FormDocumentsExportClosing(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FormDocumentsExportClosingServer(Result);
	
EndProcedure

&AtServer
Procedure FormDocumentsExportClosingServer(TempStorageAddress)
	
	Object.DocumentsExport.Load(GetFromTempStorage(TempStorageAddress));
	
	Object.VATRevenue0 = 
		Object.DocumentsExport.Total("RevenueAmount")
		+ Object.DocumentsExport.Total("RevenueAdjustment");
	
	DocumentsExportOnChangeLocalization();
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure ViewDocumentsExport(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("TempStorageAddress", PlaceExportDocumentsInTemporaryStorage());
	FormParameters.Insert("EditMode", False);
	FormParameters.Insert("Organization", Object.Organization);
	
	OpenForm("Document.VATAllocation.Form.FormOfDocumentsExport", FormParameters, ThisForm);
	
EndProcedure

&AtServer
Function PlaceExportDocumentsInTemporaryStorage()
	
	Return PutToTempStorage(DocumentsExport.Unload(), UUID);
	
EndFunction

#EndRegion

#Region Localization

&AtServer
Procedure FormItemsManagementLocalization(Form)
	Return;
EndProcedure

&AtServer
Procedure OnReadCreateAtServerLocalization() 
	
	Return;
	
EndProcedure

&AtServer
Procedure UpdateAccountingPolicySettingsLocalization()
EndProcedure

&AtServer
Procedure UpdateCaptionPeriodLocalization()
EndProcedure

&AtServer
Procedure BaseRevenueOnChangeLocalization(TagName)
	
	
EndProcedure

&AtServer
Procedure DocumentsExportOnChangeLocalization()
EndProcedure

&AtClient
Procedure ApplicationOfThe5PercentRuleOnChange(Item)
EndProcedure


#EndRegion

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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
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
