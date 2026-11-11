#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	LimitedTransactions = LimitsByBudgetingDataServer.UsedLimitedOFOperations();
	ControlOfLimits = (LimitedTransactions.Count() > 0);
	
	If Object.Ref.IsEmpty() Then
		FillInAnalystTypesField(False);
		If LimitedTransactions.Count() = 1 Then
			Object.LimitedTransaction = LimitedTransactions[0];
			SetDataLayoutScheme();
			BudgetingServer.InitializeRuleSettingsComposer(Object, ThisObject, SettingsComposer.Settings);
			FillInAnalyticsSettings();
		EndIf;
	EndIf;
	
	Items.GroupLimits_2.Visible = ControlOfLimits;
	Items.LimitedTransaction.Visible = (LimitedTransactions.Count() > 1);
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	CustomizeFormElements();
	// End StandardSubsystems.ObjectAttributesLock
	
	SetConditionalAppearance();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	FillInAnalystTypesField(False);
	
	SetDataLayoutScheme();
	BudgetingServer.InitializeRuleSettingsComposer(Object, ThisObject, SettingsComposer.Settings);
	FillInAnalyticsSettings();

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If EnableAdvancedSettingsForFillingInAnalyticsInCaseOfErrorsInAuto() Then
		Cancel = True;
		Return;
	EndIf;
	
	TableHierarchyOfAnalysts = DimensionsHierarchy.Unload();
	TableHierarchyOfAnalysts.Columns.FillInTheSpecifiedValue.Name = "FillInAnalyticsWithSpecifiedValue";
	CurrentObject.DimensionsHierarchy.Load(TableHierarchyOfAnalysts);
	CurrentObject.DimensionHierarchyIsOverwritten = True;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	CustomizeFormElements();
	// End StandardSubsystems.ObjectAttributesLock
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ArticleBudgetIndicatorWhenChanging(Item)
	
	ItemBudgetIndicatorForChangesOnServer();
	
EndProcedure

&AtClient
Procedure BudgetFlowItemStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	If Not ValueIsFilled(Object.LimitedTransaction) Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa chỉ định giao dịch bị giới hạn.';
										|ru = 'Не указана лимитируемая операция.';
										|en = 'A limited operation is required.'; fa = 'A limited operation is required.';
										|it = 'A limited operation is required.';
										|pl = 'A limited operation is required.';
										|tr = 'Limite tabi işlem belirtilmedi.'"));
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure LimitedTransactionOnChange(Item)
	
	LimitedOperationONChangeATServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDimensionsHierarchy

&AtClient
Procedure DimensionsHierarchyOnChange(Item)
	UpdateAnalyticsHierarchyPresentation(DimensionsHierarchy);
EndProcedure

&AtClient
Procedure DimensionsHierarchyOnActivateRow(Item)
	
	FormSelectionParameters = New Array;
	
	CurrentData = Items.DimensionsHierarchy.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.AdditionalProperty) Then
		NewChoiceParameter = New ChoiceParameter("Filter.Owner", CurrentData.AdditionalProperty);
		FormSelectionParameters.Add(NewChoiceParameter);
	EndIf;
	
	Items.DimensionsHierarchyDimensionValue.ChoiceParameters = New FixedArray(FormSelectionParameters);
	
EndProcedure

&AtClient
Procedure DimensionsHierarchyUsedOnChange(Item)
	
	CurrentData = Items.DimensionsHierarchy.CurrentData;
	If Not CurrentData.Used Then
		CurrentData.DimensionPopulationExpression = "";
		CurrentData.FillInTheSpecifiedValue = False;
		CurrentData.DimensionValue = Undefined;
	ElsIf Object.LimitedTransaction = PredefinedValue("Enum.LimitedTransactions.Expenses")
		And Not Object.AdvancedModeOfDimensionFillSetting Then
		If EnableAdvancedSettingsForFillingInAnalyticsInCaseOfErrorsInAuto(False) Then
			EnableAdvancedConfigurationModeForFillingInAnalyticsServer();
			CommonClient.MessageToUser(NStr("vi = 'Có đối tượng phân tích khoản mục mà cần tùy chỉnh điền thủ công';
											|ru = 'Имеются аналитики статьи, требующие ручной настройки заполнения';
											|en = 'There are item dimensions that require manual population setup'; fa = 'There are item dimensions that require manual population setup';
											|it = 'Имеются аналитики статьи, требующие ручной настройки заполнения';
											|pl = 'There are item dimensions that require manual population setup';
											|tr = 'Doldurmanın manuel olarak ayarlanmasını gerektiren kalem boyutları mevcuttur'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure HierarchyOfAnalyticsExpressionOfAnalyticsFillingStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)

	StandardProcessing = False;

	CurrentData = Items.DimensionsHierarchy.CurrentData;

	FormParameters = New Structure;
	FormParameters.Insert("DimensionKind",               CurrentData.DimensionKind);
	FormParameters.Insert("AddressOfDataCompositionSchema", AddressOfDataCompositionSchema);
	FormParameters.Insert("DataSourceSection",      Undefined);
	FormParameters.Insert("CurrentExpression",           CurrentData.DimensionPopulationExpression);

	OpenForm("CommonForm.SelectDimensionFillingField", FormParameters, Item);

EndProcedure

&AtClient
Procedure HierarchyOfAnalyticsExpressionOfAnalyticsFillingClearing(Item, StandardProcessing)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure HierarchyOfAnalyticsExpressionOfAnalyticsFillingChoiceProcessing(Item, ValueSelected, AdditionalData, StandardProcessing)

	StandardProcessing = False;
	CurrentData = Items.DimensionsHierarchy.CurrentData;
	CurrentData.DimensionPopulationExpression = ValueSelected;

	ExpressionFillingAnalyticsSelectionProcessingServer(CurrentData.GetID());
	Modified = True;
	Items.DimensionsHierarchy.EndEditRow(False);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("NotificationAboutUnblocking", ThisObject);
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject, ProcedureParameters);
	
EndProcedure

&AtClient
Procedure MarkAllAnalytics(Command)
	For Each HierarchyLine In DimensionsHierarchy Do
		HierarchyLine.Used = True;
	EndDo;
EndProcedure

&AtClient
Procedure UncheckAllAnalytics(Command)
	For Each HierarchyLine In DimensionsHierarchy Do
		HierarchyLine.Used = False;
	EndDo;
EndProcedure

&AtClient
Procedure DisableAdvancedSetupModeOfDimensionPopulation(Command)
	
	ClearMessages();
	DisableAdvancedSetupModeOfDimensionPopulationServer();
	
EndProcedure

&AtClient
Procedure EnableAdvancedConfigurationModeForFillingInAnalytics(Command)
	
	ClearMessages();
	EnableAdvancedConfigurationModeForFillingInAnalyticsServer();
	
EndProcedure

&AtClient
Procedure FillInTheAnalyticsSettingsForTheDataSource(Command)
	
	ClearMessages();
	FillInTheAnalyticsSettingsForTheDataSourceServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ItemBudgetIndicatorForChangesOnServer()
	
	Object.Description = Common.ObjectAttributeValue(Object.BudgetFlowOrBalanceItem, "Description");
	FillInAnalystTypesField();
	FillInAnalyticsSettings();
	
EndProcedure

&AtServer
Procedure LimitedOperationONChangeATServer()
	
	CustomizeFormElements();
	SetDataLayoutScheme();
	BudgetingServer.InitializeRuleSettingsComposer(Object, ThisObject, SettingsComposer.Settings);
	FillInAnalyticsSettings();
	
EndProcedure

&AtServer
Procedure SetDataLayoutScheme()
	
	If Object.LimitedTransaction = Enums.LimitedTransactions.Expenses Then
		
		DataSource = New Structure("Receipt, Expense", Enums.AccountingDataTypes.IncomeExpenses,
			Enums.AccountingDataTypes.Products);
		
		CorrespondencesTable = DataSourcesServer.TableOfCorrespondenceRegisters(DataSource);
		
		DataCompositionSchema = DataSourcesServer.DataCompositionSchemaAccordingToCorrespondenceTableOfRegisters(CorrespondencesTable);
		BudgetingServer.SetFieldPropertiesForRuleSettings(DataCompositionSchema, Object);
		AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
		
	Else
		
		AddressOfDataCompositionSchema = Undefined;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAnalyticsSettings()
	
	If DimensionsHierarchy.Count() = 0 Then
		Return;
	ElsIf Object.LimitedTransaction <> Enums.LimitedTransactions.Expenses Then
		Object.AdvancedModeOfDimensionFillSetting = False;
		Return;
	EndIf;
	
	ArrayOfAnalyticsTypes = DimensionsHierarchy.Unload(New Structure("DimensionName", ""), "DimensionKind").UnloadColumn("DimensionKind");
	AdditionalProperties = Common.ObjectsAttributeValue(ArrayOfAnalyticsTypes, "AdditionalProperty");
	
	For Each StringHierarchy In DimensionsHierarchy Do
		If Not ValueIsFilled(StringHierarchy.DimensionKind) Then
			Continue;
		EndIf;
		StringHierarchy.AdditionalProperty = AdditionalProperties[StringHierarchy.DimensionKind];
	EndDo;
	
	BudgetingServer.CheckAvailabilityOfAnalyticsFields(ThisObject, Object, , "DimensionsHierarchy");
	
EndProcedure

&AtServer
Procedure FillInAnalystTypesField(InteractiveUpdate = True)
	
	If Not ValueIsFilled(Object.BudgetFlowOrBalanceItem) Then
		DimensionsHierarchy.Clear();
		Return;
	EndIf;
	
	If InteractiveUpdate Then
		SourceOfSpecifiedHierarchy = DimensionsHierarchy.Unload(, "Used, DimensionKind, DimensionName, DimensionPopulationExpression, FillInTheSpecifiedValue, DimensionValue"); // ValueTable -
		SourceOfSpecifiedHierarchy.Columns.Add("LineNumber",
			New TypeDescription("Number", New NumberQualifiers(2, 0, AllowedSign.Nonnegative)));
		LineCounter = 0;
		For Each HierarchyLine In SourceOfSpecifiedHierarchy Do
			LineCounter = LineCounter + 1;
			HierarchyLine.LineNumber  = LineCounter;
		EndDo;
		SourceOfSpecifiedHierarchy.Columns.FillInTheSpecifiedValue.Name = "FillInAnalyticsWithSpecifiedValue";
	Else
		SourceOfSpecifiedHierarchy = Object.DimensionsHierarchy.Unload();
		If Not Object.DimensionHierarchyIsOverwritten Then
			SourceOfSpecifiedHierarchy.FillValues(True, "Used");
		EndIf;
	EndIf;
	
	DimensionsHierarchy.Clear();
	
	HierarchyTable = Catalogs.BudgetingLimits.DimensionsHierarchy(
		Object.Owner,
		Object.BudgetFlowOrBalanceItem,
		SourceOfSpecifiedHierarchy);
	
	HierarchyTable.Columns.FillInAnalyticsWithSpecifiedValue.Name = "FillInTheSpecifiedValue";
	DimensionsHierarchy.Load(HierarchyTable);
	
	UpdateAnalyticsHierarchyPresentation(DimensionsHierarchy);
	
	If Not InteractiveUpdate Then
		// Checking when reading that the displayed hierarchy of analysts
		// does not match the hierarchy of analysts in the object.
		// The modification flag must be set.
		If Not Modified Then
			If HierarchyTable.Count() <> Object.DimensionsHierarchy.Count() Then
				Modified = True;
			Else
				RowIndex = 0;
				For Each HierarchyLine In HierarchyTable Do
					ObjectHierarchyRow = Object.DimensionsHierarchy[RowIndex];
					If ObjectHierarchyRow.DimensionKind <> HierarchyLine.DimensionKind
						Or ObjectHierarchyRow.DimensionName <> HierarchyLine.DimensionName
						Or ObjectHierarchyRow.Used <> HierarchyLine.Used Then
						Modified = True;
						Break;
					EndIf;
					RowIndex = RowIndex + 1;
				EndDo;
			EndIf;
			If Modified Then
				Message = New UserMessage;
				Message.Text = NStr("vi = 'Thay đổi phân cấp chỉ số';
									|ru = 'Изменена иерархия аналитик';
									|en = 'Dimensions hierarchy is changed'; fa = 'Dimensions hierarchy is changed';
									|it = 'Gerarchia analitica modificata';
									|pl = 'Zmieniono hierarchię analityczną';
									|tr = 'Boyut hiyerarşisi değiştirildi'");
				Message.Field = "DimensionsHierarchy";
				Message.Message();
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	BudgetingServer.SetConditionalSettingsForFillingInAnalytics(ConditionalAppearance, "DimensionsHierarchy");
	
	// 
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("DimensionsHierarchy.DimensionKind");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Filled;
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("DimensionsHierarchy.Used");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.Use = True;
	DataFilterItem.LeftValue = New DataCompositionField("DimensionsHierarchy.DimensionPopulationExpression");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Appearance = ConditionalAppearanceItem.Appearance.Items.Find("MarkIncomplete");
	Appearance.Use = True;
	Appearance.Value = True;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Use = True;
	FormattedField.Field = New DataCompositionField("HierarchyOfAnalyticsExpressionOfAnalyticsFilling");
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateAnalyticsHierarchyPresentation(DimensionsHierarchy)
	Prefix = "";
	For Each TableRow In DimensionsHierarchy Do
		TableRow.RepresentationInTheHierarchy = Prefix + TableRow.Presentation;
		Prefix = Prefix + "   ";
	EndDo;
EndProcedure

&AtClient
Procedure NotificationAboutUnblocking(Result, AdditionalParameters) Export
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	ArticleViewOnly = Items.BudgetFlowItem.ReadOnly;
	Items.DimensionsHierarchy.ReadOnly = ArticleViewOnly;
	Items.DimensionsHierarchyMarkAllAnalytics.Enabled = Not ArticleViewOnly;
	Items.DimensionsHierarchyUncheckAllAnalytics.Enabled = Not ArticleViewOnly;
	Items.DimensionsHierarchyFillInTheAnalyticsSettingsForTheDataSource.Enabled = Not ArticleViewOnly;
	Items.DisableAdvancedSetupModeOfDimensionPopulation.Enabled = Not ArticleViewOnly;
	Items.EnableAdvancedConfigurationModeForFillingInAnalytics.Enabled = Not ArticleViewOnly;
	
	BDRLimitRule = (Object.LimitedTransaction = Enums.LimitedTransactions.Expenses);
	Items.DimensionsHierarchyFillInTheSpecifiedValue.Visible = BDRLimitRule And Object.AdvancedModeOfDimensionFillSetting;
	Items.HierarchyAnalyticsGroupFillingInAnalytics.Visible = BDRLimitRule And Object.AdvancedModeOfDimensionFillSetting;
	
	Items.EnableAdvancedConfigurationModeForFillingInAnalytics.Visible = Not Object.AdvancedModeOfDimensionFillSetting;
	Items.GroupHierarchyAnalyticsExplanation.Visible = Not Object.AdvancedModeOfDimensionFillSetting;
	
	Items.DisableAdvancedSetupModeOfDimensionPopulation.Visible = Object.AdvancedModeOfDimensionFillSetting;
	
EndProcedure

&AtServer
Procedure EnableAdvancedConfigurationModeForFillingInAnalyticsServer(Val AnalyticsFillInExpressions = Undefined)
	
	Object.AdvancedModeOfDimensionFillSetting = True;
	FillInAnalyticsSettings();
	BudgetingServer.SetSettingsForFillingInAnalyticsAutomatically(ThisObject, "DimensionsHierarchy", AnalyticsFillInExpressions);
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure DisableAdvancedSetupModeOfDimensionPopulationServer()
	
	Object.AdvancedModeOfDimensionFillSetting = False;
	If EnableAdvancedSettingsForFillingInAnalyticsInCaseOfErrorsInAuto(False) Then
		Object.AdvancedModeOfDimensionFillSetting = True;
		Common.MessageToUser(NStr("vi = 'Có đối tượng phân tích của khoản mục mà cần tùy chỉnh điền thủ công';
									|ru = 'Имеются аналитики статьи, требующие ручной настройки заполнения';
									|en = 'There are item dimensions that require manual population setup'; fa = 'There are item dimensions that require manual population setup';
									|it = 'Имеются аналитики статьи, требующие ручной настройки заполнения';
									|pl = 'There are item dimensions that require manual population setup';
									|tr = 'Doldurmanın manuel olarak ayarlanmasını gerektiren kalem boyutları mevcuttur'"));
	Else
		FillInAnalyticsSettings();
		CustomizeFormElements();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInTheAnalyticsSettingsForTheDataSourceServer()
	
	BudgetingServer.SetSettingsForFillingInAnalyticsAutomatically(ThisObject, "DimensionsHierarchy");
	
EndProcedure

&AtServer
Procedure ExpressionFillingAnalyticsSelectionProcessingServer(RowID) 
	
	BudgetingServer.CheckAnalyticsFillExpressionAfterSelection(ThisObject, RowID, "DimensionsHierarchy");
	
EndProcedure

&AtServer
Function EnableAdvancedSettingsForFillingInAnalyticsInCaseOfErrorsInAuto(ChangeSettings = True)
	
	Result = False;
	If Object.LimitedTransaction = Enums.LimitedTransactions.Expenses
		And Not Object.AdvancedModeOfDimensionFillSetting Then
		DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchema);
		DimensionKinds = DimensionsHierarchy.Unload(New Structure("Used", True), "DimensionKind");
		AnalyticsFillInExpressions = BudgetingServer.ExpressionsForFillingInAnalyticsAccordingToDataLayoutScheme(DataCompositionSchema, DimensionKinds);
		SearchParameters = New Structure("Ambiguous_", True);
		FoundRows = AnalyticsFillInExpressions.FindRows(SearchParameters);
		If FoundRows.Count() Then
			If ChangeSettings Then
				EnableAdvancedConfigurationModeForFillingInAnalyticsServer(AnalyticsFillInExpressions);
			EndIf;
			Result = True;
		Else
			For Each StringHierarchy In DimensionsHierarchy Do
				If Not StringHierarchy.Used Or Not ValueIsFilled(StringHierarchy.DimensionKind) Then
					Continue;
				EndIf;
				If Not StringHierarchy.FillInTheSpecifiedValue Then
					StringHierarchy.DimensionPopulationExpression = AnalyticsFillInExpressions.Find(StringHierarchy.DimensionKind, "DimensionKind").Expression;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	Return Result;

EndFunction

#EndRegion

