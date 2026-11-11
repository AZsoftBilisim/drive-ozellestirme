
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ObjectData = Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisForm);
	ValueSources.Load(ObjectData.ValueSources);
	
	ItemsTree = FormDataToValue(Parameters.ReportItems, Type("ValueTree"));
	AddressOfReportItems = PutToTempStorage(ItemsTree, UUID);
	
	Title = Parameters.ItemKind;
	TheseAreLines = Parameters.TheseAreLines;

	Catalogs.FinancialReportItems.FillInPresentationOfAdditionalFields(Object, Items.SelectAdditionalFields);
	
	HierarchyOfValuesIsUsed = ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.HierarchyOfAnalyticsValuesIsUsed(
		DimensionKind);
	Parameters.Property("UseToEnterPlan", UseToEnterPlan);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	If ThisIsDimensionOther Then
		If EnableEdit Then
			TypeOfAnalytics = 1;
		Else
			TypeOfAnalytics = 2;
		EndIf;
	Else
		TypeOfAnalytics = 0;
	EndIf;

	DataOfTypeOfAnalytics = Common.ObjectAttributesValues(DimensionKind, "ValueType, AdditionalProperty");
	If DataOfTypeOfAnalytics.ValueType = New TypeDescription("CatalogRef.ObjectsPropertiesValues") Then
		ValuesOwner = DataOfTypeOfAnalytics.AdditionalProperty;
		ParameterRelationships = New ChoiceParameterLink("Filter.Owner", "ValuesOwner");
		Array = CommonClientServer.ValueInArray(ParameterRelationships);
		Items.DimensionValue.ChoiceParameterLinks = New FixedArray(Array);
	EndIf;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ThisIsDimensionOther Then
		If EnableEdit And SourceAllElements Then
			Object.NameForPrinting = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
				DimensionKind,
				?(ShowItemHierarchy, "AllHierarchy", "All"));
		Else
			If EnableEdit Then
				Object.NameForPrinting = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
					DimensionKind,
					"AddedAndOther");
			Else
				Object.NameForPrinting = BudgetReportingClientServer.PresentationOfOtherBudgetingAnalytics(
					DimensionKind,
					"OtherItems");
			EndIf;
		EndIf;
	Else
		Object.NameForPrinting = String(Object.DimensionValue);
	EndIf;
	
	Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisForm, CurrentObject, Cancel);
	
	ObjectData = GetFromTempStorage(ItemAddressInStorage);
	ObjectData.ValueSources = ValueSources.Unload();
	ObjectData.NameForPrinting = Object.NameForPrinting; 
	PutToTempStorage(ObjectData, ItemAddressInStorage);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ValueIsFilled(ItemAddressInStorage) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FormControl();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	Errors = Undefined;
	
	If Not ThisIsDimensionOther Then
		If Not ValueIsFilled(Object.DimensionValue) Then
			ErrorText = NStr("vi = 'Chưa điền giá trị chỉ số';
							|ru = 'Не заполнено значение аналитики';
							|en = 'Dimension value is required'; fa = 'Dimension value is required';
							|it = 'Valore dell''analitica non compilato';
							|pl = 'Nie wypełniono wartości analityki';
							|tr = 'Boyut değeri doldurulmadı'");
			CommonClientServer.AddUserError(Errors,
				"DimensionValue",
				ErrorText, "");
		EndIf;
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
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
Procedure DefaultAnalyticsSourcesOnChange(Item)
	
	If SelectedValueSources Then
		FillInDefaultSources();
	EndIf;
	FormControl();
	
EndProcedure

&AtClient
Procedure DimensionKindOnChange(Item)
	
	PresentationExpression = Undefined;
	SortingExpression = Undefined;
	
	OnChangeDimensionKind();
	
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

&AtClient
Procedure SelectAdditionalFields(Command)
	
	FormParameters = BudgetReportingServerCall.SettingsForAdditionalFields(Object, DimensionKind, TheseAreLines);
	CallbackDescription = New CallbackDescription("UpdatingAdditionalFields", ThisForm);
	OpenForm("Catalog.FinancialReportItems.Form.SetUpAdditionalFields", 
					FormParameters,,,,,CallbackDescription,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectSources(Command)
	
	SourceSelectionOptions_ = New Structure;
	SourceSelectionOptions_.Insert("ItemAddressInStorage", ItemAddressInStorage);
	SourceSelectionOptions_.Insert("AddressOfReportItems",    AddressOfReportItems);
	SourceSelectionOptions_.Insert("ValueSources",       ValueSources);
	SourceSelectionOptions_.Insert("FillType",              True);
	
	Notification = New CallbackDescription("SelectingValueSources", ThisForm);
	OpenForm("Catalog.FinancialReportItems.Form.ValueSources", SourceSelectionOptions_
												,,,,,Notification,FormWindowOpeningMode.LockOwnerWindow);
	
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
			Items.SelectSources.Title,
			ValueSources.Count());
	Else
		Items.SelectSources.Title = NStr("vi = 'Chưa chỉ ra';
										|ru = 'Не указаны';
										|en = 'Not specified'; fa = 'مشخص نشده';
										|it = 'Non indicate';
										|pl = 'Nie określone';
										|tr = 'Belirtilmemiş'");
	EndIf;
	
	Items.DimensionValue.Enabled = Not ThisIsDimensionOther;
	Items.DimensionValue.AutoMarkIncomplete = Not ThisIsDimensionOther;
	Items.GroupSources_2.Enabled = EnableEdit;
	Items.SourceAllElements.Enabled = EnableEdit;
	Items.ShowItemHierarchy.Enabled = SourceAllElements And HierarchyOfValuesIsUsed;
	Items.AdditionalSelectionGroup.Visible = ShowItemHierarchy And UseToEnterPlan;
	Items.SortingExpression.Enabled = SourceAllElements;
	
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
	
	CalculatedValueSources = BudgetReportingCacheCalculationServer.SourcesOfDefaultValues(Cache, AddressOfReportItems, ItemAddressInStorage, False); 
	ValueSources.Load(CalculatedValueSources);
	
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

&AtClient
Procedure TypeOfAnalysisWhenChanging(Item)
	
	If TypeOfAnalytics = 2 Then //other values
		ThisIsDimensionOther = True;
		SourceAllElements = False;
		EnableEdit = False;
	ElsIf TypeOfAnalytics = 1 Then //add values
		ThisIsDimensionOther = True;
		EnableEdit = True;
	ElsIf TypeOfAnalytics = 0 Then //fixed value
		ThisIsDimensionOther = False;
		EnableEdit = False;
		SourceAllElements = False;
	EndIf;
	
	If ThisIsDimensionOther Then
		Object.DimensionValue = BudgetingClientServer.EmptyDimensionValue();
	EndIf;
	
	FormControl();

EndProcedure

#EndRegion