
#Region FormEventHandlers

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ValueIsFilled(ItemAddressInStorage) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ItemsTree = FormDataToValue(Parameters.ReportItems, Type("ValueTree"));
	AddressOfReportItems = PutToTempStorage(ItemsTree, UUID);
	Title = Parameters.ItemKind;
	TheseAreLines = Parameters.TheseAreLines;
	
	ObjectData = Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisForm);
	ValueSources.Load(ObjectData.ValueSources);
	Catalogs.FinancialReportItems.FillInPresentationOfAdditionalFields(Object, Items.SelectAdditionalFields);
	
	HierarchyOfValuesIsUsed = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.HierarchyOfAnalyticsValuesIsUsed(
		DimensionKind);
	Parameters.Property("UseToEnterPlan", UseToEnterPlan);
	
	FormControl();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisForm, CurrentObject, Cancel);
	ObjectData = GetFromTempStorage(ItemAddressInStorage);
	ObjectData.ValueSources = ValueSources.Unload();
	PutToTempStorage(ObjectData, ItemAddressInStorage);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure DimensionKindOnChange(Item)
	
	Object.NameForPrinting = String(DimensionKind);
	
	PresentationExpression = Undefined;
	SortingExpression = Undefined;
	
	OnChangeDimensionKind();
	
EndProcedure

&AtClient
Procedure PresentationExpressionStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	BudgetReportingClient.ChangingExpressionOfSortingViewInFormulaEditor(ThisObject,
		"PresentationExpression");
	
EndProcedure

&AtClient
Procedure SortingExpressionStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	BudgetReportingClient.ChangingExpressionOfSortingViewInFormulaEditor(ThisObject,
		"SortingExpression");
	
EndProcedure

&AtClient
Procedure SelectAdditionalFields(Command)
	
	FieldFormParameters = BudgetReportingServerCall.SettingsForAdditionalFields(Object, DimensionKind, TheseAreLines);
	CallbackDescription = New CallbackDescription("UpdatingAdditionalFields", ThisForm);
	OpenForm("Catalog.FinancialReportItems.Form.SetUpAdditionalFields",
					FieldFormParameters,,,,,CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure DefaultAnalyticsSourcesOnChange(Item)
	
	If SelectedValueSources Then
		FillInDefaultSources();
	Else
		FormControl();
	EndIf;
	
EndProcedure

&AtClient
Procedure SourceAllElementsOnChange(Item)
	
	If Not SourceAllElements Then
		ShowItemHierarchy = False;
		Composer.Settings.Filter.Items.Clear();
		SortingExpression = Undefined;
	EndIf;
	
	FormControl();
	
EndProcedure

&AtClient
Procedure ShowItemHierarchyOnChange(Item)
	
	OnChangeDimensionKind(ShowItemHierarchy);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	FinancialReportingClient.FinishEditingReportElement(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtServer
Procedure LoadAdditionalFields(Result)
	
	Object.AdditionalFields.Load(GetFromTempStorage(Result));
	Catalogs.FinancialReportItems.FillInPresentationOfAdditionalFields(Object, Items.SelectAdditionalFields);
	
EndProcedure

&AtClient
Procedure UpdatingAdditionalFields(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	LoadAdditionalFields(Result);
	
EndProcedure

&AtClient
Procedure SelectSources(Command)
	
	SourceSelectionOptions_ = New Structure("ItemAddressInStorage, AddressOfReportItems, ValueSources", 
				ItemAddressInStorage, AddressOfReportItems, ValueSources);
	
	Notification = New CallbackDescription("SelectingValueSources", ThisForm);
	OpenForm("Catalog.FinancialReportItems.Form.ValueSources", SourceSelectionOptions_,,,,,
		Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FormControl()
	
	Items.SelectSources.Enabled = SelectedValueSources;
	If Items.SelectSources.Enabled 
		And ValueSources.Count() Then
		Items.SelectSources.Title = NStr("vi = 'Thay đổi nguồn (%1)';
										|ru = 'Изменить источники (%1)';
										|en = 'Change sources (%1)'; fa = 'Change sources (%1)';
										|it = 'Cambiare fonti (%1)';
										|pl = 'Zmień źródła (%1)';
										|tr = 'Kaynakları değiştir (%1)'");
		Items.SelectSources.Title = StringFunctionsClientServer.SubstituteParametersToString(
					Items.SelectSources.Title, ValueSources.Count());
	Else
		Items.SelectSources.Title = NStr("vi = 'Chưa chỉ ra';
										|ru = 'Не указаны';
										|en = 'Not specified'; fa = 'مشخص نشده';
										|it = 'Non indicate';
										|pl = 'Nie określone';
										|tr = 'Belirtilmemiş'");
	EndIf;
	Items.ShowItemHierarchy.Enabled = SourceAllElements And HierarchyOfValuesIsUsed;
	Items.AdditionalSelectionGroup.Visible = ShowItemHierarchy And UseToEnterPlan;
	Items.SortingExpression.Enabled = SourceAllElements;
	
EndProcedure

&AtClient
Procedure SelectingValueSources(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ValueSources.Clear();
	CommonClientServer.SupplementTableFromArray(ValueSources, Result, "Source");
	
	FormControl();
	
EndProcedure

&AtServer
Procedure FillInDefaultSources()
	Cache = Undefined;
	
	CalculatedValueSources = BudgetReportingCacheCalculationServer.SourcesOfDefaultValues(Cache,
		AddressOfReportItems, ItemAddressInStorage);
	ValueSources.Load(CalculatedValueSources);
	
	FormControl();
	
EndProcedure

&AtServer
Procedure OnChangeDimensionKind(DownloadSelectionSettings = True)

	Composer.Settings.Filter.Items.Clear();

	If DownloadSelectionSettings Then

		HierarchyOfValuesIsUsed = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.HierarchyOfAnalyticsValuesIsUsed(
			DimensionKind);

		If HierarchyOfValuesIsUsed And ValueIsFilled(ItemAddressInStorage) Then
			ObjectData = GetFromTempStorage(ItemAddressInStorage);
			Catalogs.FinancialReportItems.SetFilterSettings(ThisObject, Composer,
				ObjectData.ItemKind, ObjectData.AdditionalSelection);
		EndIf;

		If Not HierarchyOfValuesIsUsed Then
			ShowItemHierarchy = False;
		EndIf;

	EndIf;

	FormControl();

EndProcedure

#EndRegion

