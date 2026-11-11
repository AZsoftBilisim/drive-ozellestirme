
#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	InitializationDuringCreationOnServer();
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	#EndRegion
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting And Not DataOnTraceableGoodsIsCorrect() Then
		Cancel = True;	
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_EntryOfCapitalAssetsBalance2_4", WriteParameters, Object.Ref);
	Notify("Write_OBEntry", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInServiceDetailsOfTS();
	RefreshFormTitle();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	ConfigureDependentFormElementsOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ConfigureDependentFormElementsOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure RecordInOperationalAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure PostInFinancialAndTaxAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure RecordInMAOnChange(Item)
	
	ConfigureDependentFormElementsOnServer(Item.Name);
	
EndProcedure

&AtClient
Procedure RecordInLocalAccountingOnChange(Item)
	
	Object.PostInAccounting = Object.RecordInLocalAccounting;
	Object.RecordInTA = Object.RecordInLocalAccounting;
	
	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting,PostInAccounting,RecordInTA");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	ConfigureDependentFormElementsOnServer("RecordInManAccounting");

EndProcedure

&AtClient
Procedure AssetsKindOnChange(Item)
	
	If Not ValueIsFilled(Object.AssetsKind) Then
		Object.AssetsKind = PredefinedValue("Enum.KindsOfNonCurrentAssets.FixedAsset");
	EndIf;
	
	If TypeOfAssetsBeforeTheChange = Object.AssetsKind Then
		Return;
	EndIf;
	
	If Object.OtherExpenses.Count() <> 0 Then
		QueryText = NStr("vi = 'Nếu bạn thay đổi loại tài sản, chi phí sẽ bị xóa. Tiếp tục?';
						|ru = 'При изменении вида активов будут удалены расходы. Продолжить?';
						|en = 'When changing the asset type, expenses will be deleted. Continue?'; fa = 'When changing the asset type, expenses will be deleted. Continue?';
						|it = 'Se sarà modificato il tipo dell''attivo saranno cancellate le spese. Continuare?';
						|pl = 'Podczas zmiany rodzaju aktywów będą usunięte rozchody. Kontynuować?';
						|tr = 'Varlık türünü değiştirirseniz, giderler silinecektir. Devam edilsin mi?'");
		CallbackDescription = New CallbackDescription("AssetsKindOnChangeCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		AssetsKindOnChangeCompletion(DialogReturnCode.Yes, Undefined);
	EndIf; 
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations
#EndRegion

#Region FormTableItemsEventHandlersOtherExpenses

&AtClient
Procedure OtherExpensesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	ListOfObjects = TMCommonUseClientServer.Array(ValueSelected);
	NonCurrentAssetsClientServer.ProcessingElementSelection(Object.OtherExpenses, "NonCurrentAsset", ListOfObjects);
	
EndProcedure

&AtClient
Procedure OtherExpensesExpenseItemOnChange(Item)
	
	TableRow = Items.OtherExpenses.CurrentData;
	If ValueIsFilled(TableRow.ExpenseItem) Then
		ItemOfOtherExpensesInCaseOfChangeOfBudget(CachedValues);
	Else
		TableRow.AcceptedByTheKNU = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OtherExpensesSumComplOnChange(Item)
	
	CurrentRow = Items.OtherExpenses.CurrentData;
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePDAmount");
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure OtherExpensesAmountFAOnChange(Item)
	
	CurrentRow = Items.OtherExpenses.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure OtherExpensesAmountPermanentDifferencesOnChange(Item)
	
	CurrentRow = Items.OtherExpenses.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure Pick(Command)
	
	PickingParameters = New Structure;
	PickingParameters.Insert("CloseOnChoice", False);
	PickingParameters.Insert("MultipleChoice", True);
	PickingParameters.Insert("Context", "ACC, MA");
	
	If Object.AssetsKind = PredefinedValue("Enum.KindsOfNonCurrentAssets.FixedAsset") Then
		OpenForm("Catalog.Assets.ChoiceForm", 
						PickingParameters, Items.OtherExpenses,,,,, 
						FormWindowOpeningMode.LockOwnerWindow);
	ElsIf Object.AssetsKind = PredefinedValue("Enum.KindsOfNonCurrentAssets.ConstructionObjects") Then
		OpenForm("Catalog.ConstructionObjects.ChoiceForm", 
						PickingParameters, Items.OtherExpenses,,,,, 
						FormWindowOpeningMode.LockOwnerWindow);
	ElsIf Object.AssetsKind = PredefinedValue("Enum.KindsOfNonCurrentAssets.IA") Then
		OpenForm("Catalog.IntangibleAssets.ChoiceForm", 
						PickingParameters, Items.OtherExpenses,,,,, 
						FormWindowOpeningMode.LockOwnerWindow);
	ElsIf Object.AssetsKind = PredefinedValue("Enum.KindsOfNonCurrentAssets.RDTopicsStages") Then
		OpenForm("Catalog.RDTopicsStages.ChoiceForm", 
						PickingParameters, Items.OtherExpenses,,,,, 
						FormWindowOpeningMode.LockOwnerWindow);
	Else
		MessageText = NStr("vi = 'Loại tài sản phải được chọn';
							|ru = 'Необходимо выбрать вид активов';
							|en = 'Select asset type'; fa = 'Select asset type';
							|it = 'E'' necessario scegliere il tipo dell''attivo';
							|pl = 'Należy wybrać rodzaj aktywów';
							|tr = 'Varlıkların türünü seçmek gereklidir'");
		CommonClient.MessageToUser(MessageText, , "AssetsKind", "Object"); 
	EndIf; 
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

#Region AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)

	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()

	TypeOfAssetsBeforeTheChange = Object.AssetsKind;
	
	LimitSelectionOfAssetsAndCostItems(ThisObject);
	FillInServiceDetailsOfTS();
	
	RefreshFormTitle();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Removing the blank mark in the "Regulated" accounting section
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OtherExpensesSum.Name);
	FilterGroup = DataCompositionClientServer.AddSelectionGroup(Item.Filter.Items, DataCompositionFilterItemsGroupType.OrGroup);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.RecordInLocalAccounting", True);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.OtherExpenses.AmountExcludingVAT", 0, DataCompositionComparisonType.NotEqual);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OtherExpensesAmountExcludingVAT.Name);
	FilterGroup = DataCompositionClientServer.AddSelectionGroup(Item.Filter.Items, DataCompositionFilterItemsGroupType.OrGroup);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.RecordInLocalAccounting", True);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.OtherExpenses.Sum", 0, DataCompositionComparisonType.NotEqual);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OtherExpensesSumCompl1.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OtherExpensesSumCompl.Name);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.RecordInManAccounting", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure InitializationDuringCreationOnServer()

	If Parameters.Property("ActivateLine") Then
		Items.GroupPages.CurrentPage = Items.ExpensesPage;
		If Parameters.ActivateLine <= Object.OtherExpenses.Count() Then
			Items.OtherExpenses.CurrentRow = Parameters.ActivateLine - 1;
		EndIf;
	EndIf;
	
	If Not GetFunctionalOption("UseConstructionObjects") Then
		ListItem = Items.AssetsKind.ChoiceList.FindByValue(Enums.KindsOfNonCurrentAssets.ConstructionObjects);
		If ListItem <> Undefined Then
			Items.AssetsKind.ChoiceList.Delete(ListItem);
		EndIf; 
	EndIf; 
	
	If GetFunctionalOption("UseTraceableImportedGoodsAccounting") Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());	
		AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, 
			Items.TraceableGoodsCCDNumber.Name, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTS()

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInAttributeAcceptedByCNU");
	StructureOfActions.Insert("RecalculateAmountTa");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.OtherExpenses, StructureOfActions);

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientAtServerWithoutContext(Form, ChangedBankingDetails)
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	Object = Form.Object;
	FormServiceParameters = Form.FormServiceParameters;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", FormServiceParameters.ComplianceCAAccountingIsKept);
	
	
	ItemDetailsParameters = PropertyValuesOfDependentProps_EnteringResidues2_4(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "OtherExpenses");
	EndIf; 
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	OnChangeAttributes(ChangedBankingDetails);
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll Then
		
		Items.PictureDocumentOfMigrationTo24.Visible = False;
		Items.DecorationForSwitchingTo24.Visible = False;
		Items.EnterBalanceBy.Visible = False;
		
		ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
		Items.OtherExpensesTheGroupAmountsUPR.Title = StrTemplate(NStr("vi = 'Kế toán quản trị (%1)';
																		|ru = 'Управленческий учет (%1)';
																		|en = 'Management accounting (%1)'; fa = 'Management accounting (%1)';
																		|it = 'Contabilità gestionale (%1)';
																		|pl = 'Ewidencja zarządcza (%1)';
																		|tr = 'Yönetim muhasebesi (%1)'"), String(ManagementAccountingCurrency));
	
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplianceCAAccountingIsKept",
			NonCurrentAssetsInternal.ComplianceCAAccountingIsKept(),
			FormServiceParameters);
	
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then

		AccountingForTraceableGoodsLocalization.SetVisibilityOfTraceableGoodsPage(ThisObject, Object.Date);

	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()))),
			FormServiceParameters);
		
		//	
		Items.RecordInLocalAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.RecordInManAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.DecorationIsReflectionOption.Visible = Items.RecordInLocalAccounting.Visible Or Items.RecordInManAccounting.Visible;
	
		If Not FormServiceParameters.FALocalAccountingIsConductedIndependently 
			And Not UpdateAll Then

			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = True;
			Object.PostInAccounting = True;
			Object.RecordInTA = False;
			
		EndIf;
		
		NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(
			ThisObject, Object.Organization, EndOfMonth(Object.Date) + 1);
		
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or StructureOfChangedProps.Property("PostInFinancialAndTaxAccounting")
		Or StructureOfChangedProps.Property("RecordInMA")
		Or UpdateAll Then
		
		PropertyValue = 
			Not Object.RecordInOperationalAccounting
			And (Object.RecordInMA Or Object.PostInFinancialAndTaxAccounting);
			
		Items.RecordInLocalAccounting.ReadOnly = PropertyValue;
		Items.RecordInManAccounting.ReadOnly = PropertyValue;
				
	EndIf; 
	
	If StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
			
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
		If ValueIsFilled(LocalAccountingCurrency) Then
			
			ComplCurrencyPresentation = String(LocalAccountingCurrency);
			
			Items.OtherExpensesSumCompl1.Title = StrTemplate(NStr("vi = 'Số tiền tài chính (%1)';
																	|ru = 'Сумма регл. (%1)';
																	|en = 'Local accounting amount (%1)'; fa = 'Local accounting amount (%1)';
																	|it = 'Importo regolatorio (%1)';
																	|pl = 'Wartość reglam. (%1)';
																	|tr = 'Tutar (yerel) (%1)'"), ComplCurrencyPresentation);
			Items.OtherExpensesTheGroupAmountsRegl.Title = StrTemplate(NStr("vi = 'Kế toán tài chính (%1)';
																			|ru = 'Регламентированный учет (%1)';
																			|en = 'Local accounting (%1)'; fa = 'Local accounting (%1)';
																			|it = 'Contabilità di regolamentazione (%1)';
																			|pl = 'Ewidencja reglamentowana (%1)';
																			|tr = 'Yerel muhasebe (%1)'"), ComplCurrencyPresentation);
		
		Else
			Items.OtherExpensesSumCompl1.Title = NStr("vi = 'Số tiền tài chính';
														|ru = 'Сумма регл.';
														|en = 'Local amount'; fa = 'مبلغ محلی';
														|it = 'Importo reg.';
														|pl = 'Wartość regl.';
														|tr = 'Tutar (yerel)'");
			Items.OtherExpensesTheGroupAmountsRegl.Title = NStr("vi = 'Kế toán tài chính';
																|ru = 'Регламентированный учет';
																|en = 'Local accounting'; fa = 'حسابداری محلی';
																|it = 'Contabilità di regolamentazione';
																|pl = 'Księgowość';
																|tr = 'Yerel muhasebe'");
		EndIf;
		
	EndIf;
	
	EntryOfCapitalAssetsBalanceLocalization.FormOfInvestmentInNonCurrentAssets_ConfigureDependentElementsOfForm(
		ThisObject, StructureOfChangedProps);
		
	ConfigureDependentFormElementsOnClientAtServerWithoutContext(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure OnChangeAttributes(ChangedBankingDetails)

	If Not ValueIsFilled(ChangedBankingDetails) Then
		Return; 
	EndIf; 
	
	AttributesList = StrSplit(ChangedBankingDetails, ",");
	
	If AttributesList.Find("RecordInOperationalAccounting") <> Undefined
		Or AttributesList.Find("PostInFinancialAndTaxAccounting") <> Undefined
		Or AttributesList.Find("RecordInMA") <> Undefined Then
		
		If Object.RecordInOperationalAccounting
			And Not Object.RecordInLocalAccounting
			And Not Object.RecordInManAccounting Then
				
			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = True;
			Object.PostInAccounting = True;
			Object.RecordInTA = FormServiceParameters.ComplianceCAAccountingIsKept;
			
			AttributesList.Add("RecordInLocalAccounting,PostInAccounting,RecordInTA,RecordInManAccounting");

		ElsIf Not Object.RecordInOperationalAccounting
			And Object.PostInFinancialAndTaxAccounting
			And Not Object.RecordInMA Then
				
			Object.RecordInLocalAccounting = True;
			Object.PostInAccounting = True;
			Object.RecordInTA = FormServiceParameters.ComplianceCAAccountingIsKept;
			Object.RecordInManAccounting = False;
			
			AttributesList.Add("RecordInLocalAccounting,PostInAccounting,RecordInTA,RecordInManAccounting");

		ElsIf Not Object.RecordInOperationalAccounting
			And Object.RecordInMA
			And Not Object.PostInFinancialAndTaxAccounting Then
				
			Object.RecordInLocalAccounting = False;
			Object.PostInAccounting = False;
			Object.RecordInTA = False;
			Object.RecordInManAccounting = True;
			
			AttributesList.Add("RecordInLocalAccounting,PostInAccounting,RecordInTA,RecordInManAccounting");

		ElsIf Not Object.RecordInOperationalAccounting
			And Object.RecordInMA
			And Object.PostInFinancialAndTaxAccounting Then
				
			Object.RecordInLocalAccounting = True;
			Object.PostInAccounting = True;
			Object.RecordInTA = FormServiceParameters.ComplianceCAAccountingIsKept;
			Object.RecordInManAccounting = True;
			
			AttributesList.Add("RecordInLocalAccounting,PostInAccounting,RecordInTA,RecordInManAccounting");

		EndIf;
		
	EndIf; 
	
	ChangedBankingDetails = StrConcat(AttributesList, ",");

EndProcedure

&AtClientAtServerNoContext
Function PropertyValuesOfDependentProps_EnteringResidues2_4(Object, AuxiliaryAttributes, ChangedBankingDetails)

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = New Array;
	
	If StructureOfChangedProps.Property("RecordInManAccounting")
		Or UpdateAll Then
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"OtherExpenses.AmountExcludingVAT", 
			"OtherExpensesAmountExcludingVAT", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
		TMCommonUseClientServer.AddItemDetailsParameters(
			"OtherExpenses.Sum", 
			"OtherExpensesSum", 
			"Visible", 
			Object.RecordInManAccounting, 
			ItemDetailsParameters);
		
	EndIf; 
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		PropertyValue = Object.RecordInLocalAccounting;
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"OtherExpenses.SumCompl", 
			"", 
			"Visible", 
			PropertyValue, 
			ItemDetailsParameters);
			
		//
		PropertyValue = 
			Object.RecordInLocalAccounting
			And (Not AuxiliaryAttributes.ComplianceCAAccountingIsKept
				Or AuxiliaryAttributes.STSIsApplied);
			
		TMCommonUseClientServer.AddItemDetailsParameters(
			"", 
			"OtherExpensesSumCompl1", 
			"ItemVisibility", 
			PropertyValue, 
			ItemDetailsParameters);
		
		
		
	EndIf; 
	
	Return ItemDetailsParameters;
	
EndFunction

&AtServer
Procedure RefreshFormTitle()
	
	Title = NonCurrentAssetsServerCall.PresentationOfInputBalances(Object);

EndProcedure

&AtClientAtServerNoContext
Procedure LimitSelectionOfAssetsAndCostItems(Form)

	ArticleSelectionParameters = New Array;
	ArticleSelectionParameters.Add(New ChoiceParameter("Filter.ExpensesOccur", PredefinedValue("Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue")));
	
	If Form.Object.AssetsKind = PredefinedValue("Enum.KindsOfNonCurrentAssets.ConstructionObjects") Then
		
		AssetHeader = NStr("vi = 'Đối tượng xây dựng cơ bản';
							|ru = 'Объект строительства';
							|en = 'Assets under construction'; fa = 'دارایی‌های در جریان ساخت';
							|it = 'Oggetto di costruzione';
							|pl = 'Obiekt budownictwa';
							|tr = 'İnşaat nesnesi'");
		AssetType_ = New TypeDescription("CatalogRef.ConstructionObjects");
		ArticleSelectionParameters.Add(New ChoiceParameter("Filter.ExpensesOnConstructionObjects", True));
		
	ElsIf Form.Object.AssetsKind = PredefinedValue("Enum.KindsOfNonCurrentAssets.IA") Then
		
		AssetHeader = NStr("vi = 'TSCĐ vô hình (chi phí nghiên cứu triển khai)';
							|ru = 'Нематериальный актив (расходы на НИОКР)';
							|en = 'Intangible asset (R&D expenses)'; fa = 'دارایی نامشهود (هزینه‌های تحقیق و توسعه)';
							|it = 'Bene immateriale (spese in Ricerca&Sviluppo)';
							|pl = 'Składnik aktywów niematerialnych (wydatki na prace naukowo-badawcze i doświadczalno-konstrukcyjne)';
							|tr = 'Maddi Olmayan Duran varlık (Ar-Ge harcamaları)'");
		AssetType_ = New TypeDescription("CatalogRef.IntangibleAssets");
		ArticleSelectionParameters.Add(New ChoiceParameter("Filter.IntangibleAssetsAndRDExpenses", True));
		ArticleSelectionParameters.Add(New ChoiceParameter("Filter.ResearchAndDevelopmentExpenses", False));
		
	ElsIf Form.Object.AssetsKind = PredefinedValue("Enum.KindsOfNonCurrentAssets.RDTopicsStages") Then
		
		AssetHeader = NStr("vi = 'Đề tài, giai đoạn nghiên cứu và phát triển';
							|ru = 'Тема, этап исследований и разработок';
							|en = 'Research and development topic, stage'; fa = 'موضوع، مرحله تحقیق و توسعه';
							|it = 'Тема, этап исследований и разработок';
							|pl = 'Temat, etap badań i opracowań';
							|tr = 'Konu, araştırma ve geliştirme aşaması'");
		AssetType_ = New TypeDescription("CatalogRef.RDTopicsStages");
		ArticleSelectionParameters.Add(New ChoiceParameter("Filter.ResearchAndDevelopmentExpenses", True));
	
	Else
		
		AssetHeader = NStr("vi = 'Tài sản cố định';
							|ru = 'Основное средство';
							|en = 'Fixed asset'; fa = 'دارایی ثابت';
							|it = 'Capitale fisso';
							|pl = 'Środek trwały';
							|tr = 'Sabit kıymetler'");
		AssetType_ = New TypeDescription("CatalogRef.Assets");
		ArticleSelectionParameters.Add(New ChoiceParameter("Filter.ExpensesOnAssets", True));
	EndIf;
	
	Form.Items.OtherExpensesNonCurrentAsset.Title = AssetHeader;
	Form.Items.OtherExpensesNonCurrentAsset.TypeRestriction = AssetType_;
	Form.Items.OtherExpensesExpenseItem.ChoiceParameters = New FixedArray(ArticleSelectionParameters);
	
EndProcedure

&AtServer
Procedure ItemOfOtherExpensesInCaseOfChangeOfBudget(CachedValues)
	
	TableRow = Object.OtherExpenses.FindByID(Items.OtherExpenses.CurrentRow);
	
	StructureOfActions = New Structure("FillInAttributeAcceptedByCNU");
	BatchProcessingOfTablePartServer.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	FillInPDAmount(TableRow);
	
EndProcedure

&AtServer
Procedure FillInPDAmount(TableRow)

	If Not TableRow.AcceptedByTheKNU And FormServiceParameters.CalculationOfPermanentAndTemporaryDifferencesIsKept Then
		TableRow.AmountPermanentDifferences = TableRow.SumCompl;
	EndIf;

EndProcedure

&AtClient
Procedure AssetsKindOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Object.OtherExpenses.Clear();
		LimitSelectionOfAssetsAndCostItems(ThisObject);
	Else
		Object.AssetsKind = TypeOfAssetsBeforeTheChange;
	EndIf;
	
	TypeOfAssetsBeforeTheChange = Object.AssetsKind;
	
EndProcedure

&AtServer
Function AvailableFixedAssets()
	
	ListOfNonCurrentAssets = Object.OtherExpenses.Unload(,"NonCurrentAsset").UnloadColumn("NonCurrentAsset");
	
	AvailableFixedAssets = New Array();
	For Each NonCurrentAsset In ListOfNonCurrentAssets Do
		If TypeOf(NonCurrentAsset) = Type("CatalogRef.Assets")Then
			AvailableFixedAssets.Add(NonCurrentAsset);		
		EndIf;
	EndDo;
	
	Return AvailableFixedAssets;
	
EndFunction

&AtClient
Function DataOnTraceableGoodsIsCorrect()
	
	DataCorrect = True;
	FixedAssets = AvailableFixedAssets();
	For Each Page1 In Object.TraceableGoods Do
		If FixedAssets.Find(Page1.FixedAsset) = Undefined Then
			MessageString = NStr("vi = 'Dữ liệu phần bảng hàng hóa được truy xuất nguồn gốc không tương ứng với dữ liệu về tài sản dài hạn. 
			|Giá trị %1 không có trong phần bảng ""Chi phí"".';
			|ru = 'Данные табличной части прослеживаемых товаров не соответствуют данным о внеоборотных активах. 
			|Значение %1 отсутствует в табличной части ""Расходы"".';
			|en = 'Data of the traceable goods table does not correspond to the data of fixed assets. 
			|The %1 value is missing in the ""Expenses"" table.'; fa = 'Data of the traceable goods table does not correspond to the data of fixed assets. 
			|The %1 value is missing in the ""Expenses"" table.';
			|it = 'I dati della parte tabellare degli articoli tracciabili non corrispondono ai dati sulle attività non correnti. 
			|Il valore %1 mana nella parte tabellare ""Uscite"".';
			|pl = 'Dane sekcji tabelarycznej towarów identyfikowalnych nie są zgodne z danymi o aktywach trwałych. 
			|Brak wartości %1 w sekcji tabelarycznej ""Rozchody"".';
			|tr = 'İzlenebilir mallar tablosundaki veriler duran varlıklardaki verilerle uyuşmuyor. 
			|""Giderler"" tablo bölümünde %1 değeri eksik.'"); 
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, Page1.FixedAsset);
			CommonClient.MessageToUser(MessageString,Object.Ref);
			DataCorrect = False;	
		EndIf;	
	EndDo;

	Return DataCorrect;

EndFunction

&AtClient
Procedure GenerateStatement(Command)
	
	AvailableFixedAssets = AvailableFixedAssets();
	Filter = New Structure;
    Filter.Insert("Organization", Object.Organization);   
	Filter.Insert("FixedAsset", AvailableFixedAssets);
	ReportPeriod = New StandardPeriod();
	ReportPeriod.StartDate = BegOfDay(Object.Date);
	ReportPeriod.EndDate = EndOfDay(Object.Date);
 	Filter.Insert("Period", ReportPeriod);		
	FormParameters = New Structure("Filter, GenerateOnOpen, VariantKey", Filter, True, "Main");	
	AccountingForTraceableGoodsClientLocalization.GenerateStatement(FormParameters);
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
		
	If CurrentPage = Items.GroupPages.ChildItems.TraceableProductsPage Then
		Items.TraceableGoodsFixedAsset.ChoiceList.LoadValues(AvailableFixedAssets());
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
