
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
	
	If DimensionType = Enums.TypesOfBudgetReportDimensions.AccountingRegisterDimension Then
		Items.DimensionName.ChoiceList.Clear();
		Items.DimensionName.ChoiceList.Add("Organization",   NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Organizacja';
																	|tr = 'İş yeri'"));
		Items.DimensionName.ChoiceList.Add("Department", NStr("vi = 'Bộ phận';
																|ru = 'Подразделение';
																|en = 'Business unit'; fa = 'Business unit';
																|it = 'Reparto';
																|pl = 'Dział';
																|tr = 'Departman'"));
		If Catalogs.LinesOfBusiness.AccountingByDirectionsIsUsed() Then
			Items.DimensionName.ChoiceList.Add("LineOfBusiness", NStr("vi = 'Lĩnh vực hoạt động';
																		|ru = 'Направление деятельности';
																		|en = 'Line of business'; fa = 'خط کسب‌وکار';
																		|it = 'Settore di attività';
																		|pl = 'Rodzaj działalności';
																		|tr = 'Faaliyet alanı'"));
		EndIf;
		Items.DimensionName.TextEdit = False;
	ElsIf DimensionType = Enums.TypesOfBudgetReportDimensions.ExtDimension Then
		DimensionName = "<ExtDimensionType>";
		Items.DimensionName.Visible = False;
		Items.ExtDimensionType.Visible = True;
		Items.ExtDimensionType.TypeRestriction = FinancialReportingServer.TypeDescriptionByValue(ExtDimensionType);
	Else
		BudgetingModel = Parameters.BudgetingModel;
		If GetFunctionalOption("GenerateBudgetsByBusinessUnits",
				New Structure("BudgetingModel", BudgetingModel)) Then
			Items.DimensionName.ChoiceList.Insert(0, NStr("vi = 'Bộ phận';
															|ru = 'Подразделение';
															|en = 'Business unit'; fa = 'Business unit';
															|it = 'Reparto';
															|pl = 'Dział';
															|tr = 'Departman'"));
		EndIf;
		If GetFunctionalOption("GenerateBudgetsByCompanies",
				New Structure("BudgetingModel", BudgetingModel)) Then
			Items.DimensionName.ChoiceList.Insert(0, NStr("vi = 'Doanh nghiệp';
															|ru = 'Организация';
															|en = 'Company'; fa = 'Company';
															|it = 'Azienda';
															|pl = 'Firma';
															|tr = 'İş yeri'"));
		EndIf;
		Items.AdditionalSelectionGroup.Visible = False;
	EndIf;
	
	AdditionalFormMode = Parameters.AdditionalFormMode;
	
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

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ValueIsFilled(ItemAddressInStorage) Then
		StandardProcessing = False;
	EndIf;
	
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
Procedure DimensionNameOnChange(Item)
	
	If Not ValueIsFilled(DimensionName) Then
		Return;
	EndIf;
	
	Object.NameForPrinting = Items.DimensionName.ChoiceList.FindByValue(DimensionName).Presentation;
	If DimensionType = PredefinedValue("Enum.TypesOfBudgetReportDimensions.AccountingRegisterDimension") Then
		ConfigureSelectionField();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExtDimensionTypeOnChange(Item)
	
	ExtDimensionTypeOnChangeServer();
	
EndProcedure

&AtClient
Procedure DefaultAnalyticsSourcesOnChange(Item)
	
	If SelectedValueSources Then
		FillInDefaultSources();
	Else
		FormControl();
	EndIf;
	
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
	
	ThisIsFinReport = AdditionalFormMode = Enums.AdditionalModesOfReportItems.ReportKind;
	
	Items.GroupSources_2.Visible = Not ThisIsFinReport;
	
	Items.Accuracy.Visible = ThisIsFinReport And Not Parameters.DoNotOutputAccuracy;
	
	Items.SelectSources.Enabled = SelectedValueSources;
	If Items.SelectSources.Enabled And ValueSources.Count() Then
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
	
EndProcedure

&AtServer
Procedure ExtDimensionTypeOnChangeServer()
	
	Object.NameForPrinting = Common.ObjectAttributeValue(ExtDimensionType, "Description");
	ConfigureSelectionField();
	
EndProcedure

&AtServer
Procedure ConfigureSelectionField()
	
	Catalogs.FinancialReportItems.SetFilterSettings(ThisForm, ThisForm.Composer, Object.ItemKind, Composer.Settings);
	
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
	
	CalculatedValueSources = BudgetReportingCacheCalculationServer.SourcesOfDefaultValues(Cache, AddressOfReportItems, ItemAddressInStorage);
	ValueSources.Load(CalculatedValueSources);
	FormControl();
	
EndProcedure

#EndRegion
