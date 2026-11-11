#Region Variables

&AtClient
Var CallAgainBeforeClosing; // Used for non-modal questions before closing

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
	
		Return;
	
	EndIf;
	
	// Getting parameters
	UpdateAdd = Parameters.UpdateAdd;
	FillingRuleAddress = Parameters.FillingRuleAddress;
	If Parameters.Property("EditMode") Then
		Items.FormFillInTheDocumentSave.Title = NStr("vi = 'Lưu lại';
													|ru = 'Сохранить';
													|en = 'Save'; fa = 'ذخیره';
													|it = 'Salvare';
													|pl = 'Save';
													|tr = 'Sakla'");
	EndIf; 
	If Parameters.Property("ChangeResultTo") Then
		ChangeResultTo = Parameters.ChangeResultTo;
	Else
		Items.ChangeResultTo.Visible = False;
	EndIf; 
	If Parameters.Property("RoundingPrecision") Then
		RoundingPrecision = Parameters.RoundingPrecision;
	Else
		Items.RoundingPrecision.Visible = False;
	EndIf;
	If Parameters.Property("PlanByAmount") Then
		PlanByAmount = Parameters.PlanByAmount;
	EndIf;
	If Parameters.Property("NumberOfPeriods") Then
		NumberOfPeriods = Parameters.NumberOfPeriods;
	EndIf;
	If Parameters.Property("Filter") Then
		FilterPlan_ = TMCommonUseClientServer.ConvertCorrespondenceToStructure(Parameters.Filter);
	EndIf;
	If Parameters.Property("BeginOfPeriod") Then
		BeginOfPeriod    = Parameters.BeginOfPeriod;
	EndIf;
	If Parameters.Property("PeriodEnding") Then
		PeriodEnding = Parameters.PeriodEnding;
	EndIf;
	Items.FormFillInTheDocumentSave.Enabled = Not Parameters.ReadOnly;
	
	PlanProfile = Parameters.PlanProfile;
	DetailsOfPlanType = Common.ObjectAttributesValues(PlanProfile, "PlanType, FillInAssignmentInTabularForm");
	PlanType = DetailsOfPlanType.PlanType;
	
	AddressOfDataConversionScheme = Planning.GetAddressOfDataConversionScheme(PlanType, UUID, DetailsOfPlanType.FillInAssignmentInTabularForm);
	CustomSettingsAddress = Parameters.CustomSettingsAddress;
	If Parameters.Property("AllocateByWorkdays") Then
		AllocateByWorkdays = Parameters.AllocateByWorkdays;
	Else
		Items.AllocateByWorkdays.Visible = False;
	EndIf; 
	
	SelectedModeColor = StyleColors.FormTextColor;
	UnselectedModeColor = StyleColors.HyperlinkColor;
	
	// The tree is filled with data from the tabular part of the document
	RestoreTreeFromTablePart(FillingRule, FillingRuleAddress, PlanByAmount);
	
	InitializeSettingsComposer(CustomSettingsAddress, AddressOfDataConversionScheme);
	
	UseAdvancedPopulationOptions = AdvancedFeaturesAreUsed(ThisForm);
	
	CustomizeForm();
	
	If ValueIsFilled(FillingRuleQuantitySource) Then
		InitializeSourceSettingsComposers(False);
	EndIf;
	
	If ValueIsFilled(FillingRulePriceSource) And PlanByAmount Then
		InitializeSourceSettingsComposers(True);
	EndIf;

	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If CallAgainBeforeClosing = True Then
		CallAgainBeforeClosing = False;
		Return;
	EndIf;
	
	If Modified Then
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục mà không lưu lại';
												|ru = 'Продолжить без сохранения';
												|en = 'Continue without saving'; fa = 'Continue without saving';
												|it = 'Continuare senza salvare';
												|pl = 'Kontynuuj bez zapisywania';
												|tr = 'Kaydetmeden devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);
		Result = Undefined;
		
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		ShowQueryBox(Notification, 
			NStr("vi = 'Đã thay đổi tùy chỉnh quy tắc. Tiếp tục mà không lưu lại?';
				|ru = 'Настройки правила были изменены. Продолжить без сохранения?';
				|en = 'Rule settings were changed. Continue without saving?'; fa = 'Rule settings were changed. Continue without saving?';
				|it = 'Le impostazioni della regola sono state modificate. Continuare senza salvare?';
				|pl = 'Ustawienia reguły uległy zmianie. Kontynuować bez zapisywania?';
				|tr = 'Kural ayarları değiştirildi. Kaydetmeden devam edilsin mi?'"), 
			Buttons);
		Cancel = True;
		CallAgainBeforeClosing = True;
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	Result = QuestionResult;
	If Result  = DialogReturnCode.Yes Then
		Close();
		Return;
	EndIf;
	CallAgainBeforeClosing = False;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FillingRuleQuantitySourceChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	FillingRuleQuantitySourceChoiceProcessingServer(ValueSelected);
	
EndProcedure

&AtServer
Procedure FillingRuleQuantitySourceChoiceProcessingServer(ValueSelected)

	RootElementOfRows = RootItem(FillingRule);
	SourceElements__ = RootElementOfRows.GetItems();
	NeedInitializationOfTeamBuilder = False;
	
	PopulationFields = Undefined;
	If TypeOf(ValueSelected) = Type("Structure") Then
		Source = ValueSelected.Value;
		SettingOfFilterByPeriod = ValueSelected.SettingOfFilterByPeriod;
		ValueSelected.Property("PopulationFields",PopulationFields);
	Else
		Source = ValueSelected.Ref;
		SettingOfFilterByPeriod = Common.ObjectAttributeValue(ValueSelected.Ref, "SettingOfFilterByPeriod");
	EndIf;
	
	If SourceElements__.Count() > 0 Then
		
		SourceItem = SourceElements__.Get(0);
		If SourceItem.Source <> Source Then
			
			SourceItem.CustomSettingsAddress = PutToTempStorage(Undefined, UUID);
			
		EndIf;
		
	Else
		
		SourceItem = SourceElements__.Add();
		SourceItem.CustomSettingsAddress = PutToTempStorage(Undefined, UUID);
		
	EndIf;
	
	If SourceItem.Source <> Source Then
		SourceItem.FilterFromHeaderIsSet = False;
		NeedInitializationOfTeamBuilder = True;
	EndIf;
	
	SourceItem.Source = Source;
	SourceItem.Use = True;
	SourceItem.PeriodVariant = SettingOfFilterByPeriod;
	If PopulationFields = Undefined Then
		SourceItem.PopulationFields = GetFillFields(SourceItem.Source, SourceItem.PeriodVariant,
		AddressOfDataConversionScheme, PlanProfile, SourceItem.CustomSettingsAddress, True, NumberOfPeriods);
	EndIf;
	
	FillingRuleQuantitySource = SourceItem.Source;
	QuantitySourcePeriodOption   = SourceItem.PeriodVariant;
	FillingRuleQuantityDate     = SourceItem.Date;
	FillingRuleQuantityPeriod   = SourceItem.Period;
	
	Items.FillingRuleQuantityPeriod.Visible     = QuantitySourcePeriodOption = 2;
	Items.FillingRuleQuantityDate.Visible       = QuantitySourcePeriodOption = 1;
	
	If NeedInitializationOfTeamBuilder Then
		InitializeSourceSettingsComposers(False);
	EndIf;
	
	Modified = True;

EndProcedure

&AtClient
Procedure FillingRuleQuantitySourceOnChange(Item)
	
	If Not ValueIsFilled(FillingRuleQuantitySource) Then
	
		RootElementOfRows = RootItem(FillingRule);
		SourceElements__ = RootElementOfRows.GetItems();
		
		If SourceElements__.Count() > 0 Then
			
			SourceElements__.Clear();
			
		EndIf;
		
		CustomizeForm();
		
	EndIf; 
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure FillingRulePriceSourceChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	FillingRulePriceSourceChoiceProcessingServer(ValueSelected);
	
EndProcedure

&AtServer
Procedure FillingRulePriceSourceChoiceProcessingServer(ValueSelected)

	RootElementOfRows = RootItem(FillingRule, True);
	SourceElements__ = RootElementOfRows.GetItems();
	NeedInitializationOfTeamBuilder = False;
	
	PopulationFields = Undefined;
	If TypeOf(ValueSelected) = Type("Structure") Then
		Source = ValueSelected.Value;
		SettingOfFilterByPeriod = ValueSelected.SettingOfFilterByPeriod;
		ValueSelected.Property("PopulationFields",PopulationFields);
	Else
		Source = ValueSelected.Ref;
		SettingOfFilterByPeriod = Common.ObjectAttributeValue(ValueSelected.Ref, "SettingOfFilterByPeriod");
	EndIf;
	
	If SourceElements__.Count() > 0 Then
		
		SourceItem = SourceElements__.Get(0);
		If SourceItem.Source <> Source Then
			
			SourceItem.CustomSettingsAddress = PutToTempStorage(Undefined, UUID);
			
		EndIf;
		
	Else
		
		SourceItem = SourceElements__.Add();
		SourceItem.CustomSettingsAddress = PutToTempStorage(Undefined, UUID);
		
	EndIf;
	
	If SourceItem.Source <> Source Then
		NeedInitializationOfTeamBuilder = True;
	EndIf;
	
	SourceItem.Source = Source;
	SourceItem.Use = True;
	SourceItem.Attach = True;
	SourceItem.PeriodVariant = SettingOfFilterByPeriod;
	If PopulationFields = Undefined Then
		SourceItem.PopulationFields = GetFillFields(SourceItem.Source, SourceItem.PeriodVariant,
		AddressOfDataConversionScheme, PlanProfile, SourceItem.CustomSettingsAddress, True, NumberOfPeriods);
	EndIf; 
	
	FillingRulePriceSource = SourceItem.Source;
	PriceSourcePeriodOption   = SourceItem.PeriodVariant;
	FillingRulePriceDate     = SourceItem.Date;
	FillingRulePricePeriod   = SourceItem.Period;
	
	Items.FillingRulePricePeriod.Visible     = PriceSourcePeriodOption = 2;
	Items.FillingRulePriceDate.Visible       = PriceSourcePeriodOption = 1;
	
	If NeedInitializationOfTeamBuilder Then
		InitializeSourceSettingsComposers(True);
	EndIf;
	
	Modified = True;

EndProcedure
 
&AtClient
Procedure FillingRuleQuantityPeriodOnChange(Item)
	
	SourceItem = GetFirstElementOfFillRule();
	
	SourceItem.Period = FillingRuleQuantityPeriod;
	
EndProcedure

&AtClient
Procedure FillingRulePriceSourceOnChange(Item)
	
	If Not ValueIsFilled(FillingRulePriceSource) Then
	
		RootElementOfRows = RootItem(FillingRule, True);
		SourceElements__ = RootElementOfRows.GetItems();
		
		If SourceElements__.Count() > 0 Then
			
			SourceElements__.Clear();
			
		EndIf;
		
		CustomizeForm();
		
	EndIf;
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure FillingRulePricePeriodOnChange(Item)
	
	SourceItem = GetFirstElementOfFillRule(True);
	
	SourceItem.Period = FillingRulePricePeriod;
	
EndProcedure

&AtClient
Procedure FillingRuleQuantityDateOnChange(Item)
	
	SourceItem = GetFirstElementOfFillRule();
	
	SourceItem.Date = FillingRuleQuantityDate;
	
EndProcedure

&AtClient
Procedure FillingRulePriceDateOnChange(Item)
	
	SourceItem = GetFirstElementOfFillRule(True);
	
	SourceItem.Date = FillingRulePriceDate;
	
EndProcedure

&AtClient
Procedure SettingsComposerUserSettingsOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure FillingInQuantityClick(Item)
	
	Items.FillingSourcesGroup.CurrentPage = Items.GroupSourceOfFillingQuantity;
	
	SourcesOfFillingWhenChangingPage(ThisObject);
	
EndProcedure

&AtClient
Procedure FillingInPriceClick(Item)
	
	Items.FillingSourcesGroup.CurrentPage = Items.GroupSourceOfPriceFilling;
	
	SourcesOfFillingWhenChangingPage(ThisObject);
	
EndProcedure

&AtClient
Procedure OpenAndSetUpSeasonalIndexesClick(Item)
	OpenForm("InformationRegister.SeasonalIndexes.Form.SeasonalIndexes");
EndProcedure

&AtClient
Procedure ChangeQuantityResultToOnChange(Item)
	SourceItem = GetFirstElementOfFillRule(False);
	SourceItem.ChangeResultTo = ChangeQuantityResultTo;
EndProcedure

&AtClient
Procedure ChangePriceResultToOnChange(Item)
	SourceItem = GetFirstElementOfFillRule(True);
	SourceItem.ChangeResultTo = ChangePriceResultTo;
EndProcedure

&AtClient
Procedure ChangeSeasonalCoefficientQuantityOnChange(Item)
	ParameterChangeToSeasonalFactor = DataCompositionClientServer.GetParameter(QuantitySourceSettingsComposer,
		"ChangeToTheSeasonalIndex");
		
	If ParameterChangeToSeasonalFactor <> Undefined Then
	
		ParameterChangeToSeasonalFactor.Use = True;
		ParameterChangeToSeasonalFactor.Value = ChangeQuantityToSeasonalFactor;
	
	EndIf;
EndProcedure

&AtClient
Procedure ChangeSeasonalCoefficientPriceOnChange(Item)
	ParameterChangeToSeasonalFactor = DataCompositionClientServer.GetParameter(PriceSourceSettingsComposer,
		"ChangeToTheSeasonalIndex");
		
	If ParameterChangeToSeasonalFactor <> Undefined Then
	
		ParameterChangeToSeasonalFactor.Use = True;
		ParameterChangeToSeasonalFactor.Value = ChangeToSeasonalCoefficientPrice;
	
	EndIf;
EndProcedure


#EndRegion

#Region FormTableItemsEventHandlersQuantitySourceSettingsComposerCustomSettings

&AtClient
Procedure QuantitySourceSettingsComposerCustomSettingsOnChange(Item)
	
	Parameter = DataCompositionClientServer.GetParameter(QuantitySourceSettingsComposer, "ChangeToTheSeasonalIndex");
	
	If Parameter <> Undefined And Parameter.UserSettingID = String(Item.CurrentRow) Then
		ChangeQuantityToSeasonalFactor = Item.CurrentData.Value;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPriceSourceSettingsComposerCustomSettings

&AtClient
Procedure PriceSourceSettingsComposerCustomSettingsOnChange(Item)
	
	Parameter = DataCompositionClientServer.GetParameter(PriceSourceSettingsComposer, "ChangeToTheSeasonalIndex");
	
	If Parameter <> Undefined And Parameter.UserSettingID = String(Item.CurrentRow) Then
		ChangeToSeasonalCoefficientPrice = Item.CurrentData.Value;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFillingRule

&AtClient
Procedure FillingRuleBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	// The root element is not copied
	If Item.CurrentData.ElementType = 2 And Copy Then
		
		Cancel = True;
		Return;
		
	EndIf;
	
	// The source is being copied
	If Item.CurrentData.ElementType = 0 And Copy Then
		
		Return;
		
	EndIf;
	
	// The conversion method is copied with subordinates
	If Item.CurrentData.ElementType = 1 And Copy Then
		
		Cancel = True;
		CopyLineWithSubordinates(
			FillingRule, 
			FillingRule.FindByID(Item.CurrentRow).GetParent(), 
			FillingRule.FindByID(Item.CurrentRow), 
			Copy);
		Return;
		
	EndIf;
	
	If ANewLineIsAdded Then
		
		ANewLineIsAdded = False;
		Return;
		
	EndIf;
		
	Cancel = True;
	ANewLineIsAdded = True;
		
	// The source cannot be placed in another source
	If Item.CurrentData.ElementType = 0 Then
		
		Item.CurrentRow = Item.CurrentData.GetParent().GetID();
		
	EndIf;
	
	// Adding a new source
	Item.AddRow();
	
EndProcedure

&AtClient
Procedure FillingRuleBeforeDeleteRow(Item, Cancel)
	
	// The root element is not deleted
	If Item.CurrentData.ElementType = 2 Then
		
		Cancel = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillingRuleSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Item.CurrentItem.Name = "FillingRuleExclude" Then
		If Item.CurrentData.Attach = True Then
			Item.CurrentData.Exclude = False;
		Else
			Item.CurrentData.Exclude = Not Item.CurrentData.Exclude;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure FillingRuleOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		If Not Copy And ConversionOptionIsAdded Then
			
			Item.CurrentData.ElementType = 1;
			Item.CurrentData.TransformationOption = PredefinedValue("Enum.ConversionOptions.Addition");
			ConversionOptionIsAdded = False;
			
		EndIf;
		
		If Item.CurrentData.ElementType = 0 Then
			
			If IsTempStorageURL(Item.CurrentData.CustomSettingsAddress) Then
				
				Item.CurrentData.CustomSettingsAddress = PutToTempStorage(
					GetFromTempStorage(Item.CurrentData.CustomSettingsAddress),
					UUID);
				
			Else
				
				Item.CurrentData.CustomSettingsAddress = PutToTempStorage(Undefined, UUID);
				
			EndIf;
			
		EndIf;
		
		Item.CurrentData.Attach = Item.CurrentData.GetParent().Attach;
		
	EndIf;
	
	If Item.CurrentItem.Name = "RuleForFillingInASetting" 
		Or Item.CurrentItem.Name = "FillingRuleChangeResultTo"
		Or Item.CurrentItem.Name = "FillingRulePopulationFields" Then
		
		If ValueIsFilled(Item.CurrentData.Source) Then
			
			Item.CurrentData.FilterFromHeaderIsSet = True;
			
			FormParameters = New Structure("Source, CustomSettingsAddress, ChangeResultTo, FilterPlan_", 
				Item.CurrentData.Source,
				Item.CurrentData.CustomSettingsAddress,
				Item.CurrentData.ChangeResultTo,
				?(Item.CurrentData.FilterFromHeaderIsSet, Undefined, FilterPlan_));
				
			AdditionalParameters = New Structure("SourceItem", Item.CurrentData);
			Notification = New CallbackDescription("FillRuleSetupCompletion", ThisObject, AdditionalParameters);
			OpenForm("Catalog.PlanningDataSources.Form.FormSetting", 
				FormParameters, 
				ThisForm,
				UUID,
				,
				,
				Notification, 
				FormWindowOpeningMode.LockOwnerWindow);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillingRuleDragStart(Item, DragParameters, StandardProcessing)
	
	For Each String In DragParameters.Value Do
		
		If FillingRule.FindByID(String).ElementType = 2 Then
			
			DragParameters.AllowedActions = DragAllowedActions.DontProcess;
			Break;
			
		EndIf;
		
	EndDo;
	
	DragParameters.Value = New Structure("DragAndDropSource, DragValue", UUID, DragParameters.Value);
	
EndProcedure

&AtClient
Procedure FillingRuleDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	If TypeOf(DragParameters.Value) <> Type("Structure") Then
		
		Return;
		
	EndIf;
	
	If DragParameters.Value.Property("DragAndDropSource") = Undefined Then
		
		Return;
		
	EndIf;
	
	If DragParameters.Value.DragAndDropSource <> UUID Then
		
		Return;
		
	EndIf;
	
	If String <> Undefined And (FillingRule.FindByID(String).ElementType = 2 Or FillingRule.FindByID(String).ElementType = 1) Then
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillingRuleDrag(Item, DragParameters, StandardProcessing, String, Field)

	If String <> Undefined And (FillingRule.FindByID(String).ElementType = 2 Or FillingRule.FindByID(String).ElementType = 1) Then
		
		Modified = True;
		StandardProcessing = False;
		
		For Each IDOfRowToDrag In DragParameters.Value.DragValue Do

			DraggableLine = FillingRule.FindByID(IDOfRowToDrag);
			
			CopyLineWithSubordinates(
				FillingRule, 
				FillingRule.FindByID(String), 
				DraggableLine, 
				DragParameters.Action = DragAction.Copy);
			
			If DragParameters.Action = DragAction.Move Then
				
				DraggableLine.GetParent().GetItems().Delete(DraggableLine);
				
			EndIf;
				
		EndDo;
		
	EndIf;
		
EndProcedure

&AtClient
Procedure FillingRuleSourceChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
		
	If TypeOf(ValueSelected) = Type("Structure") Then
		ThisIsAnotherSource = Items.FillingRule.CurrentData.Source <> ValueSelected.Value;
		Items.FillingRule.CurrentData.Source = ValueSelected.Value;
		Items.FillingRule.CurrentData.PeriodVariant = ValueSelected.SettingOfFilterByPeriod;
	Else
		ThisIsAnotherSource = Items.FillingRule.CurrentData.Source <> ValueSelected;
		Items.FillingRule.CurrentData.Source = ValueSelected;
		Items.FillingRule.CurrentData.PeriodVariant = GeneralPurposeTMServerCall.ObjectAttributeValue(ValueSelected, "SettingOfFilterByPeriod");
	EndIf;
		
	Items.FillingRule.CurrentData.Use = True;
	If ThisIsAnotherSource Then
		Items.FillingRule.CurrentData.CustomSettingsAddress = PutToTempStorage(Undefined, UUID);
	EndIf;
	Items.FillingRule.CurrentData.PopulationFields = GetFillFields(Items.FillingRule.CurrentData.Source,
		Items.FillingRule.CurrentData.PeriodVariant, AddressOfDataConversionScheme, PlanProfile, 
		Items.FillingRule.CurrentData.CustomSettingsAddress, True, NumberOfPeriods);
	
EndProcedure

&AtClient
Procedure FillingRuleTransformationOptionOnChange(Item)
	
	Items.FillingRule.CurrentData.Use = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddANewConversionOption(Command)
	
	// The conversion method cannot be placed in the source
	If Items.FillingRule.CurrentData.ElementType = 0 Then
		
		Items.FillingRule.CurrentRow = Items.FillingRule.CurrentData.GetParent().GetID();
		
	EndIf;
	
	ANewLineIsAdded = True;
	ConversionOptionIsAdded = True;
	
	// Adding a new conversion method
	Items.FillingRule.AddRow();
	Items.FillingRule.CurrentItem = Items.FillingRuleTransformationOption;
	
EndProcedure

&AtClient
Procedure FillInTheDocumentSave(Command)
	
	ClearMessages();
	
	If Not UseAdvancedPopulationOptions Then
		Save_ComposerSettings();
	EndIf;
	
	RuleIsCorrect = FillInTheDocumentSaveServer();
	If Not RuleIsCorrect Then
		QueryText = NStr("vi = 'Quy tắc bị lỗi. Tiếp tục điền chứng từ hoặc quay lại soạn quy tắc?';
						|ru = 'Правила содержат ошибки. Продолжить заполнение документа или вернуться к редактированию правила?';
						|en = 'Rules contain errors. Continue populating the document or return to editing the rule?'; fa = 'Rules contain errors. Continue populating the document or return to editing the rule?';
						|it = 'Le regole contengono errori. Continuare a compilare il documento o tornare alla modifica della regola?';
						|pl = 'Reguły zawierają błędy. Kontynuować wypełnianie dokumentu czy wrócić do edycji reguły?';
						|tr = 'Kurallarda hata mevcut. Belge doldurulmaya devam edilsin veya kural düzenlemelerine dönülsün mü?'");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Continuare';
												|pl = 'Continue';
												|tr = 'Devam et'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Soạn quy tắc';
												|ru = 'Редактировать правила';
												|en = 'Edit rules'; fa = 'Edit rules';
												|it = 'Modificare le regole';
												|pl = 'Edycja reguły';
												|tr = 'Kuralları düzenle'"));
		ShowQueryBox(New CallbackDescription("FillInTheDocumentSaveCompletion", ThisObject), QueryText, Buttons);
		Return;
		
	EndIf;
	
	FillInDocumentSaveClose();
	
EndProcedure

&AtClient
Procedure FillInTheDocumentSaveCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes  Then
		Return;
	EndIf; 
	
	FillInTheDocumentSaveServer(True);
	
	FillInDocumentSaveClose();
	
EndProcedure

&AtClient
Procedure FillInDocumentSaveClose()
	
	Modified = False;
	
	Settings = New Structure;
	Settings.Insert("UpdateAdd", UpdateAdd);
	Settings.Insert("ChangeResultTo", ChangeResultTo);
	Settings.Insert("RoundingPrecision", RoundingPrecision);
	Settings.Insert("AllocateByWorkdays", AllocateByWorkdays);
	
	SourceItem = GetFirstElementOfFillRule(False);
	
	Settings.Insert("FilterIs_Specified", SourceItem.FilterFromHeaderIsSet);
	
	Close(Settings);
	
EndProcedure
 
&AtClient
Procedure Ungroup(Command)
	
	// Only one group can be ungrouped
	SelectedRows = Items.FillingRule.SelectedRows;
	
	If SelectedRows.Count() = 1 And FillingRule.FindByID(SelectedRows[0]).ElementType = 1 Then
		
		UngroupableString = FillingRule.FindByID(SelectedRows[0]);
		
		For Each RowToCopy In UngroupableString.GetItems() Do
			
			CopyLineWithSubordinates(
				FillingRule, 
				UngroupableString.GetParent(), 
				RowToCopy, 
				False);
			
		EndDo;
		
		UngroupableString.GetParent().GetItems().Delete(UngroupableString);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupSources(Command)
	
	// Grouping is only possible for elements with one parent
	PreviousParent_ = Undefined;
	
	SelectedRows = Items.FillingRule.SelectedRows;
	GroupingIsPossible = SelectedRows.Count() > 0;
	
	IndexOfFirstSelectedRow = Undefined;
	
	For Each SelectedRow In SelectedRows Do
		
		FormDataTreeItem = FillingRule.FindByID(SelectedRow);
		
		CurrentParent = FormDataTreeItem.GetParent();
		
		// Root element or different parents
		If FormDataTreeItem.ElementType = 2 
			Or PreviousParent_ <> Undefined 
			And CurrentParent <> PreviousParent_ Then
			
			GroupingIsPossible = False;
			Break;
			
		EndIf;
		
		PreviousParent_ = CurrentParent;
		
		If IndexOfFirstSelectedRow = Undefined Then
			
			IndexOfFirstSelectedRow = FormDataTreeItem.GetParent().GetItems().IndexOf(FormDataTreeItem);
			
		Else
			
			IndexOfFirstSelectedRow = Min(IndexOfFirstSelectedRow, 
				FormDataTreeItem.GetParent().GetItems().IndexOf(FormDataTreeItem));
			
		EndIf;
		
	EndDo;
	
	If GroupingIsPossible Then
		
		NewConversionOption = PreviousParent_.GetItems().Insert(IndexOfFirstSelectedRow);
		NewConversionOption.Use = True;
		NewConversionOption.ElementType = 1;
		NewConversionOption.Attach = NewConversionOption.GetParent().Attach;
		NewConversionOption.TransformationOption = PredefinedValue("Enum.ConversionOptions.Addition");
		
		ArrayOfSelectedRows = New Array();
		For Each SelectedRow In SelectedRows Do
			ArrayOfSelectedRows.Add(SelectedRow);
		EndDo;
		
		For Each SelectedRow In ArrayOfSelectedRows Do
			
			RowToCopy = FillingRule.FindByID(SelectedRow);
			
			CopyLineWithSubordinates(
				FillingRule, 
				NewConversionOption, 
				RowToCopy, 
				False);
			
			RowToCopy = FillingRule.FindByID(SelectedRow);
			RowToCopy.GetParent().GetItems().Delete(RowToCopy);
			
		EndDo;
		
		Items.FillingRule.Expand(NewConversionOption.GetID(), True);
		Items.FillingRule.CurrentRow = NewConversionOption.GetID();
		Items.FillingRule.CurrentItem = Items.FillingRuleTransformationOption;
		Items.FillingRule.ChangeRow();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearCheckBoxes(Command)
	
	EstablishTaggingWithSubordinates(FillingRule, False);
	
EndProcedure

&AtClient
Procedure SelectCheckBoxes(Command)
	
	EstablishTaggingWithSubordinates(FillingRule, True);
	
EndProcedure

&AtClient
Procedure CheckFillingRule(Command)
	
	ClearMessages();
	
	SelectionByResources = SelectionByResources(SettingsComposer);
	RuleIsCorrect = CheckFillingRuleServer(FillingRule, FillingRuleAddress, AddressOfDataConversionScheme, PlanProfile, PlanByAmount, SelectionByResources);
	If RuleIsCorrect Then
		ShowMessageBox(,NStr("vi = 'Quy tắc không bị lỗi.';
							|ru = 'Правило не содержит ошибок.';
							|en = 'The rule does not contain errors.'; fa = 'The rule does not contain errors.';
							|it = 'La regola non contiene errori.';
							|pl = 'Reguła nie zawiera błędów.';
							|tr = 'Kuralda hata mevcut değil.'"),60);
	EndIf;
	
EndProcedure

&AtClient
Procedure EnableAdvancedMode(Command)
	
	Save_ComposerSettings();
	UseAdvancedPopulationOptions = True;
	CustomizeForm();
	
EndProcedure

&AtClient
Procedure TurnOffAdvancedMode(Command)
	
	If AdvancedFeaturesAreUsed(ThisForm) Then
		QueryText = NStr("vi = 'Sẽ xóa các tùy chỉnh cho phép, tiếp tục?';
						|ru = 'Расширенные настройки будут удалены, продолжить?';
						|en = 'Advanced settings will be removed, continue?'; fa = 'Advanced settings will be removed, continue?';
						|it = 'Le impostazioni avanzate verranno eliminate, continuare?';
						|pl = 'Ustawienia rozszerzone zostaną usunięte, kontynuować?';
						|tr = 'Gelişmiş ayarlar silinecektir, devam edilsin mi?'");
		Notification = New CallbackDescription("TurnOffAdvancedModeCompletion", ThisObject);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	Else
		TurnOffAdvancedModeCompletion(DialogReturnCode.Yes, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillRuleSetupCompletion(SetupParameters, AdditionalParameters) Export
	
	If SetupParameters <> Undefined Then
		SourceItem = AdditionalParameters.SourceItem;
		
		SourceItem.ChangeResultTo = SetupParameters.ChangeResultTo;
		SourceItem.PopulationFields = SetupParameters.PopulationFields;
		ThisForm.Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplyDefaultSettings(Command)
	
	TreeElements = FillingRule.GetItems();
	If TreeElements.Count() > 0 Then
		
		RootElementOfRows = TreeElements.Get(0);
		SourceElements__ = RootElementOfRows.GetItems();
		If SourceElements__.Count() > 0 Then
			
			For IndexOf = 0 To SourceElements__.Count() - 1 Do
				
				SourceItem = SourceElements__.Get(IndexOf);
				SourceItem.CustomSettingsAddress = PutToTempStorage(Undefined, UUID);
				
				SourceItem.PopulationFields = GetFillFields(SourceItem.Source, SourceItem.PeriodVariant,
					AddressOfDataConversionScheme, PlanProfile, SourceItem.CustomSettingsAddress, True, NumberOfPeriods);
				
				UserSettings = GetFromTempStorage(SourceItem.CustomSettingsAddress);
			
				If UserSettings <> Undefined Then
					QuantitySourceSettingsComposer.LoadUserSettings(UserSettings);
				EndIf;
				
			EndDo;
			
			If Not UseAdvancedPopulationOptions Then
				
				ParameterChangeToSeasonalFactor = DataCompositionClientServer.GetParameter(
					QuantitySourceSettingsComposer,
					"ChangeToTheSeasonalIndex");
			
				If ParameterChangeToSeasonalFactor <> Undefined Then
					ChangeQuantityToSeasonalFactor = ParameterChangeToSeasonalFactor.Value;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If TreeElements.Count() > 1 Then
		
		RootElementOfPriceLines = TreeElements.Get(1);
		SourceElements__ = RootElementOfPriceLines.GetItems();
		If SourceElements__.Count() > 0 Then
			
			For IndexOf = 0 To SourceElements__.Count() - 1 Do
				
				SourceItem = SourceElements__.Get(0);
				SourceItem.CustomSettingsAddress = PutToTempStorage(Undefined, UUID);
				
				SourceItem.PopulationFields = GetFillFields(SourceItem.Source, SourceItem.PeriodVariant,
					AddressOfDataConversionScheme, PlanProfile, SourceItem.CustomSettingsAddress, True, NumberOfPeriods);
				
				UserSettings = GetFromTempStorage(SourceItem.CustomSettingsAddress);
			
				If UserSettings <> Undefined Then
					PriceSourceSettingsComposer.LoadUserSettings(UserSettings);
				EndIf;
				
			EndDo;
			
			If Not UseAdvancedPopulationOptions Then
				
				ParameterChangeToSeasonalFactor = DataCompositionClientServer.GetParameter(
					PriceSourceSettingsComposer,
					"ChangeToTheSeasonalIndex");
			
				If ParameterChangeToSeasonalFactor <> Undefined Then
					ChangeToSeasonalCoefficientPrice = ParameterChangeToSeasonalFactor.Value;
				EndIf;
				
			EndIf;
			
		EndIf;
	
	EndIf;
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure Preview(Command)
	
	ClearMessages();
	
	If Not UseAdvancedPopulationOptions Then
		Save_ComposerSettings();
	Else
		PutToTempStorage(SettingsComposer.UserSettings, CustomSettingsAddress);
	EndIf;
	
	RuleIsCorrect = CheckFillingRuleServer(FillingRule, FillingRuleAddress, AddressOfDataConversionScheme, PlanProfile, PlanByAmount, SelectionByResources(SettingsComposer));
	
	If Not RuleIsCorrect Then
		QueryText = NStr("vi = 'Quy tắc có lỗi. Mở xem trước hoặc quay lại chỉnh sửa quy tắc?';
						|ru = 'Правила содержат ошибки. Открыть предпросмотр или вернуться к редактированию правила?';
						|en = 'The rules contain errors. Do you want to open the preview or go back to editing the rules?'; fa = 'The rules contain errors. Do you want to open the preview or go back to editing the rules?';
						|it = 'Правила содержат ошибки. Открыть предпросмотр или вернуться к редактированию правила?';
						|pl = 'The rules contain errors. Do you want to open the preview or go back to editing the rules?';
						|tr = 'Kurallarda hatalar mevcut. Önizleme açılsın veya kural düzenlemelerine dönülsün mü?'");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Продолжить';
												|pl = 'Continue';
												|tr = 'Devam et'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Chỉnh sửa quy tắc';
												|ru = 'Редактировать правила';
												|en = 'Edit rules'; fa = 'Edit rules';
												|it = 'Modificare le regole';
												|pl = 'Edycja reguły';
												|tr = 'Kuralları düzenle'"));
		ShowQueryBox(New CallbackDescription("OpenPreviewSaveEnd", ThisObject), QueryText, Buttons);
		Return;
		
	EndIf;
	
	OpenPreview();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillRuleElementTypeConversionOption.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRuleTransformationOption.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillRuleElementTypeSource.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRuleSource.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RuleForFillingInASetting.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRuleChangeResultTo.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRulePopulationFields.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FillingRule.ElementType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRuleUse.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRuleExclude.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRuleAttach.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FillingRule.ElementType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;

	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillRuleElementTypeSource.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRuleSource.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRuleSources.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RuleForFillingInASetting.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRuleChangeResultTo.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRulePopulationFields.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FillingRule.ElementType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillRuleElementTypeConversionOption.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRuleTransformationOption.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRuleSources.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FillingRule.ElementType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRulePeriod.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FillingRule.PeriodVariant");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(0);
	ValueList.Add(1);
	ValueList.Add(3);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRuleDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FillingRule.PeriodVariant");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(0);
	ValueList.Add(2);
	ValueList.Add(3);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRuleExclude.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FillingRule.Attach");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FillingRuleAttach.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FillingRule.Attach");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", False);

EndProcedure

#Region Other

&AtServer
Procedure CustomizeForm()
	
	QuantitySourcePeriodOption = 0;
	PriceSourcePeriodOption = 0;
	If Not UseAdvancedPopulationOptions Then
		
		RootElementOfRows = RootItem(FillingRule);
		SourceElements__ = RootElementOfRows.GetItems();
		
		If SourceElements__.Count() > 0 Then
			
			SourceItem = SourceElements__.Get(0);
			
			FillingRuleQuantitySource = SourceItem.Source;
			QuantitySourcePeriodOption   = SourceItem.PeriodVariant;
			FillingRuleQuantityDate     = SourceItem.Date;
			FillingRuleQuantityPeriod   = SourceItem.Period;
			ChangeQuantityResultTo       = SourceItem.ChangeResultTo;
			
		EndIf;
		
		If PlanByAmount Then
			
			RootElementOfRows = RootItem(FillingRule, True);
			SourceElements__ = RootElementOfRows.GetItems();
			
			If SourceElements__.Count() > 0 Then
				
				SourceItem = SourceElements__.Get(0);
				
				FillingRulePriceSource = SourceItem.Source;
				PriceSourcePeriodOption   = SourceItem.PeriodVariant;
				FillingRulePriceDate     = SourceItem.Date;
				FillingRulePricePeriod   = SourceItem.Period;
				ChangePriceResultTo       = SourceItem.ChangeResultTo;
				
			EndIf;
		
		EndIf; 
	
	EndIf; 

	Items.ChangeQuantityResultTo.Visible = PlanByAmount Or ValueIsFilled(ChangeQuantityResultTo);
	Items.EnableAdvancedMode.Visible = Not UseAdvancedPopulationOptions;
	Items.TurnOffAdvancedMode.Visible = UseAdvancedPopulationOptions;
	
	Items.SimplifiedSetupGroup.Visible = Not UseAdvancedPopulationOptions;
	Items.FillingRule.Visible = UseAdvancedPopulationOptions;
	Items.SettingsComposerUserSettings.Visible = UseAdvancedPopulationOptions;
	
	Items.FillingRuleQuantityPeriod.Visible     = QuantitySourcePeriodOption = 2;
	Items.FillingRuleQuantityDate.Visible       = QuantitySourcePeriodOption = 1;
	
	Items.FillingRuleQuantitySource.Title = ?(PlanByAmount, NStr("vi = 'Nguồn';
																|ru = 'Источник';
																|en = 'Source'; fa = 'منبع';
																|it = 'Источник';
																|pl = 'Source';
																|tr = 'Kaynak'"),  NStr("vi = 'Nguồn số lượng';
																						|ru = 'Источник количества';
																						|en = 'Quantity source'; fa = 'Quantity source';
																						|it = 'Источник количества';
																						|pl = 'Quantity source';
																						|tr = 'Kaynak miktar'"));
	Items.FillingRulePriceSource.Visible   = PlanByAmount;
	
	Items.HyperlinksOfFillingSources.Visible = PlanByAmount;
	Items.FillingRulePricePeriod.Visible     = PlanByAmount And PriceSourcePeriodOption = 2;
	Items.FillingRulePriceDate.Visible       = PlanByAmount And PriceSourcePeriodOption = 1;
	
	AvailabilityOfEditingFillInSettings = AccessRight("Update", Metadata.Catalogs.PlanningDataSources);
	Items.FillingRule.ReadOnly = Not AvailabilityOfEditingFillInSettings;
	Items.FillingRuleExclude.Enabled = AvailabilityOfEditingFillInSettings;
	Items.FillingRule.CommandBar.Enabled = AvailabilityOfEditingFillInSettings;
	Items.FillingRule.ContextMenu.Enabled = AvailabilityOfEditingFillInSettings;
	Items.FillingRuleCheckFillingRule.Enabled = AvailabilityOfEditingFillInSettings;
	
	Items.FillingSourcesGroup.CurrentPage = Items.GroupSourceOfFillingQuantity;
	SourcesOfFillingWhenChangingPage(ThisObject);
	
EndProcedure

// Parameters:
//  Form - ClientApplicationForm - Form
&AtClientAtServerNoContext
Procedure SourcesOfFillingWhenChangingPage(Form)
	
	Items = Form.Items;
	PageQuantity = Items.FillingSourcesGroup.CurrentPage = Items.GroupSourceOfFillingQuantity;
	
	Items.FillingInQuantity.Hyperlink = Not PageQuantity;
	Items.FillingInPrice.Hyperlink = PageQuantity;
	
	Items.FillingInQuantity.TextColor = ?(PageQuantity, Form.SelectedModeColor, Form.UnselectedModeColor);
	Items.FillingInPrice.TextColor = ?(Not PageQuantity, Form.SelectedModeColor, Form.UnselectedModeColor);
	
EndProcedure

&AtServer
Procedure InitializeSettingsComposer(CustomSettingsAddress, AddressOfDataConversionScheme)
	
	DataCompositionSchema = GetFromTempStorage(AddressOfDataConversionScheme);
	
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(PutToTempStorage(DataCompositionSchema, UUID)));
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	UserSettings = GetFromTempStorage(CustomSettingsAddress);
	
	If UserSettings <> Undefined Then
		
		SettingsComposer.LoadUserSettings(UserSettings);
		
	EndIf;
	
EndProcedure

&AtServer
Function FillInTheDocumentSaveServer(SkipVerification = False)
	
	RuleIsCorrect = False;
	
	If Not SkipVerification Then
		
		SelectionByResources = SelectionByResources(SettingsComposer);
		RuleIsCorrect = CheckFillingRuleServer(FillingRule, FillingRuleAddress, AddressOfDataConversionScheme, PlanProfile, PlanByAmount, SelectionByResources);
	
	EndIf; 
	
	If SkipVerification Or RuleIsCorrect Then
	
		PlaceFillRuleInTemporaryStorage(FillingRule, FillingRuleAddress, PlanByAmount);
		PutToTempStorage(SettingsComposer.UserSettings, CustomSettingsAddress);
		
	Else
		
		Return RuleIsCorrect;
		
	EndIf; 
	
	Return True;

EndFunction

&AtClient
Procedure CopyLineWithSubordinates(Tree, Receiver, Source, Copy, CopiedLines = Undefined)
	
	// Copied strings are saved to an array
	If CopiedLines = Undefined Then
		
		CopiedLines = New Array;
		
	EndIf;
	
	// If the source line is in the copied lines, the copying is completed
	If CopiedLines.Find(Source.GetID()) <> Undefined Then
		
		Return;
		
	EndIf;
	
	NewRow = Receiver.GetItems().Add();
	FillPropertyValues(NewRow, Source);
	NewRow.Attach = Receiver.Attach;
	
	// The added line is placed in the copied lines
	CopiedLines.Add(NewRow.GetID());
	
	// A new settings store is created for the copied data sources
	If NewRow.ElementType = 0 And Copy Then
		
		If IsTempStorageURL(NewRow.CustomSettingsAddress) Then
		
			NewRow.CustomSettingsAddress = PutToTempStorage(
				GetFromTempStorage(NewRow.CustomSettingsAddress),
				UUID);
		
		Else
		
			NewRow.CustomSettingsAddress = PutToTempStorage(Undefined, UUID);
		
		EndIf; 
		
	EndIf;
	
	// Subordinate lines are copied
	For Each SubordinateSourceString In Source.GetItems() Do
		
		CopyLineWithSubordinates(Tree, NewRow, SubordinateSourceString, Copy, CopiedLines);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function RootItem(Tree, FillingInPrices = False)
	
	TreeElements = Tree.GetItems();
	
	// The root element has already been added
	If Not FillingInPrices And TreeElements.Count() > 0 Then
		
		Return TreeElements.Get(0);
		
	ElsIf FillingInPrices And TreeElements.Count() > 1 Then
		
		Return TreeElements.Get(1);
		
	EndIf;
	
	// Adding a root element
	If FillingInPrices Then
		RootItem = TreeElements.Add();
		
		RootItem.Sources = NStr("vi = 'Nguồn điền đơn giá';
								|ru = 'Источники заполнения цен';
								|en = 'Price population sources'; fa = 'Price population sources';
								|it = 'Fonti di compilazione prezzi';
								|pl = 'Źródła wypełniania cen';
								|tr = 'Fiyat doldurma kaynakları'");
		RootItem.ElementType = 2; // Root element
		RootItem.Attach = True;
	Else
		RootItem = TreeElements.Add();
		
		RootItem.Sources = NStr("vi = 'Nguồn điền số lượng';
								|ru = 'Источники заполнения количества';
								|en = 'Quantity filling sources'; fa = 'منابع پرکردن مقدار';
								|it = 'Fonti di riempimento quantità';
								|pl = 'Źródła wypełniania ilości';
								|tr = 'Miktar doldurma kaynakları'");
		RootItem.ElementType = 2; // Root element
		RootItem.Attach = False;
	EndIf; 
		
	Return RootItem;
	
EndFunction



// LongDesc
// 
// Parameters:
// 	TabularSection - ValueTable - The TS of an object containing a fill-in rule:
//                                  * Source - CatalogRef.PlanningDataSources - 
//                                  * LineNumber - Number - 
// 	LineToAdd - FormDataTreeItem - tree element with fields:
// 	* Source - CatalogRef.PlanningDataSources -
// 	Parent - Number - LongDesc
&AtServerNoContext
Procedure AddTreeRowToTablePart(TabularSection, LineToAdd, Parent = 0)
	
	TablePartIsNewLine = TabularSection.Add();
	
	TablePartIsNewLine.Use = LineToAdd.Use;
	TablePartIsNewLine.Exclude = LineToAdd.Exclude;
	TablePartIsNewLine.Attach = LineToAdd.Attach;
	TablePartIsNewLine.ChangeResultTo = LineToAdd.ChangeResultTo;
	TablePartIsNewLine.TransformationOption = LineToAdd.TransformationOption;
	TablePartIsNewLine.Source = LineToAdd.Source;
	TablePartIsNewLine.FilterFromHeaderIsSet = LineToAdd.FilterFromHeaderIsSet;
	TablePartIsNewLine.Period = New ValueStorage(LineToAdd.Period);
	TablePartIsNewLine.Date = New ValueStorage(LineToAdd.Date);
	TablePartIsNewLine.ElementType = LineToAdd.ElementType;
	TablePartIsNewLine.LineNumber = TabularSection.Count();
	TablePartIsNewLine.RowNumberParent = Parent;
	
	If LineToAdd.ElementType = 0 Then
		If IsTempStorageURL(LineToAdd.CustomSettingsAddress) Then
			TablePartIsNewLine.UserSettings = New ValueStorage(GetFromTempStorage(LineToAdd.CustomSettingsAddress));
		Else
			TablePartIsNewLine.UserSettings = New ValueStorage(Undefined);
		EndIf; 
	EndIf;
	
	For Each TreeRow In LineToAdd.GetItems() Do
		
		TreeRow.Attach = LineToAdd.Attach;
		AddTreeRowToTablePart(TabularSection, TreeRow, TablePartIsNewLine.LineNumber);
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure RestoreTreeFromTablePart(Tree, FillingRuleAddress, PlanByAmount)
	
	TabularSection = GetFromTempStorage(FillingRuleAddress); // See Planning.SelectDataByRules.FillInRuleObject
	
	Tree.GetItems().Clear();
	
	RootElementOfRows = RootItem(Tree);
	AddedTreeRows = New Array;
	AddedTreeRows.Add(RootElementOfRows);
	
	If PlanByAmount Then
		RootElementOfColumns = RootItem(Tree, True);
		AddedJoiningTreeRows = New Array;
		AddedJoiningTreeRows.Add(RootElementOfColumns);
	EndIf; 
	
	OffsetOfAccessionTree = 0;
	SourcePeriodOption = Common.ObjectsAttributeValue(TabularSection.UnloadColumn("Source"), "SettingOfFilterByPeriod");
	
	For Each LineOfATabularSection In TabularSection Do
		
		If LineOfATabularSection.Attach = True Then
			If Not PlanByAmount Then
				Continue;
			EndIf; 
			IndexOf = ?(LineOfATabularSection.RowNumberParent =0, 0, LineOfATabularSection.RowNumberParent - OffsetOfAccessionTree);
			TreeNewRowCollection = AddedJoiningTreeRows[IndexOf].GetItems(); // FormDataTreeItemCollection - 
			TreeNewLine = TreeNewRowCollection.Add();
		Else
			OffsetOfAccessionTree = OffsetOfAccessionTree + 1;
			TreeNewRowCollection = AddedTreeRows[LineOfATabularSection.RowNumberParent].GetItems(); // FormDataTreeItemCollection -
			TreeNewLine = TreeNewRowCollection.Add();
		EndIf; 
		
		FillPropertyValues(TreeNewLine, LineOfATabularSection, "Use, Exclude, Attach,
			|ChangeResultTo, TransformationOption, Source, ElementType, FilterFromHeaderIsSet");
		
		PeriodStorage = LineOfATabularSection.Period;// ValueStorage
		DateStorage = LineOfATabularSection.Date;// ValueStorage
		
		TreeNewLine.Period = PeriodStorage.Get();
		TreeNewLine.Date = DateStorage.Get();
		TreeNewLine.PeriodVariant = SourcePeriodOption.Get(LineOfATabularSection.Source);
		
		If LineOfATabularSection.ElementType = 0 Then
			
			UserSettingsStorage = LineOfATabularSection.UserSettings;// ValueStorage
			
			TreeNewLine.CustomSettingsAddress = PutToTempStorage(
				UserSettingsStorage.Get(), 
				New UUID);
			
		EndIf;
		
		If LineOfATabularSection.Attach = True Then
			AddedJoiningTreeRows.Add(TreeNewLine);
		Else
			AddedTreeRows.Add(TreeNewLine);
		EndIf;
		
		If LineOfATabularSection.ElementType = 0 Then
			
			UserSettingsStorage = LineOfATabularSection.UserSettings;// ValueStorage
			TreeNewLine.PopulationFields = GetFillFields(LineOfATabularSection.Source, TreeNewLine.PeriodVariant, 
				Undefined, Undefined, UserSettingsStorage.Get());
		EndIf;
		
	EndDo;
		
EndProcedure

// LongDesc
// 
// Parameters:
//  FillingInPrices - Boolean - 
//
// Returns:
//  FormDataTreeItem - tree element with fields:
//   * Source - CatalogRef.PlanningDataSources -
//
&AtClient
Function GetFirstElementOfFillRule(FillingInPrices = False)

	RootElementOfRows = RootItem(FillingRule, FillingInPrices);
	SourceElements__ = RootElementOfRows.GetItems();
	
	If SourceElements__.Count() > 0 Then
		
		SourceItem = SourceElements__.Get(0);
		
	Else
		
		SourceItem = SourceElements__.Add();
		
	EndIf;
	
	Return SourceItem;

EndFunction 
 
&AtServerNoContext
Function GetFillFields(Val Source,
	Val PeriodVariant,
	Val AddressOfDataConversionScheme, 
	Val PlanProfile, 
	AddressCustomSettings = Undefined, 
	DeleteUnusedFields = False,
	NumberOfPeriods = 0)

	PopulationFields = "";
	
	If Not ValueIsFilled(Source) Then
		
		Return PopulationFields;
	
	EndIf; 
	
	If DeleteUnusedFields Then
		SchemaFields = Planning.GetDataConversionSchemeFields(AddressOfDataConversionScheme, PlanProfile); 
	EndIf;
	
	// If there is one period in the document, then we put all the data from the source into it
	If DeleteUnusedFields And PeriodVariant <> 3 And NumberOfPeriods = 1 Then
		
		IndexOf = SchemaFields.Find("Period");
		If IndexOf <> Undefined Then
			SchemaFields.Delete(IndexOf);
		EndIf; 
	
	EndIf; 
	
	If IsTempStorageURL(AddressCustomSettings) Then
	
		UserSettings = GetFromTempStorage(AddressCustomSettings);
	
	Else
		
		UserSettings = AddressCustomSettings;
	
	EndIf; 
	
	Attributes = Common.ObjectAttributesValues(Source, 
		"DCSTemplateName, DataCompositionSchema, StorageOfDataCompositionSettings");
	If ValueIsFilled(Attributes.DCSTemplateName) Then
		DataCompositionSchema = Catalogs.PlanningDataSources.LayoutSchemeByTemplateName(Attributes.DCSTemplateName);
		If DataCompositionSchema = Undefined Then
			DataCompositionSchema = Attributes.DataCompositionSchema.Get();
		EndIf; 
	Else
		DataCompositionSchema = Attributes.DataCompositionSchema.Get();
	EndIf;
	
	// Loading Settings
	SettingsComposer = New DataCompositionSettingsComposer;
	SetPrivilegedMode(True);
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	SetPrivilegedMode(False);
	
	Try
		DataCompositionSettings = Attributes.StorageOfDataCompositionSettings.Get();
	Except
		Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong nguồn điền dữ liệu ""%1"" có lỗi trong tùy chỉnh. Đã đặt tùy chỉnh mặc định.';
				|ru = 'В источнике заполнения данных ""%1"" имеются ошибки в настройках. Установлены настройки по умолчанию.';
				|en = 'There are errors in the settings in the ""%1"" data filling source. The default settings are set.'; fa = 'There are errors in the settings in the ""%1"" data filling source. The default settings are set.';
				|it = 'Nell''origine di compilazione dati ""%1"" sono presenti errori di impostazione. Sono selezionate le impostazioni predefinite.';
				|pl = 'Źródło wypełnienia danych ""%1"" zawiera błędy w ustawieniach. Ustawione są ustawienia domyślne.';
				|tr = 'Kaynakta ""%1"" verisinin doldurulması esnasında ayarlarda hatalar meydana geldi. Ayarlar varsayılana göre ayarlandı.'"), Source));
	EndTry;

	If DataCompositionSettings <> Undefined Then
		SettingsComposer.LoadSettings(DataCompositionSettings);
	Else
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	SettingsComposer.Refresh();
	
	If UserSettings <> Undefined And Not IsBlankString(UserSettings) Then
		
		SettingsComposer.LoadUserSettings(UserSettings);
		
	EndIf;
	
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	PopulationFields = PlanningClientServer.GetTextOfSelectedLayoutFields(
		SettingsComposer,
		DeleteUnusedFields,
		SchemaFields);
	
	If DeleteUnusedFields And IsTempStorageURL(AddressCustomSettings) Then
		PutToTempStorage(SettingsComposer.UserSettings, AddressCustomSettings);
	EndIf;
	
	Return PopulationFields;

EndFunction 

&AtServer
Procedure UpdateUserSettingsFromTemporaryStorage(FillingInPrices)
	
	RootElementOfRows = RootItem(FillingRule, FillingInPrices);
	SourceElements__ = RootElementOfRows.GetItems();
	
	If SourceElements__.Count() > 0 Then
		SourceItem = SourceElements__.Get(0);
	Else
		Return;
	EndIf;
	
	If FillingInPrices Then
		ChangePriceResultTo = SourceItem.ChangeResultTo;
	Else
		ChangeQuantityResultTo = SourceItem.ChangeResultTo;
	EndIf;
	
	ParameterChangeToSeasonalFactor = DataCompositionClientServer.GetParameter(
		?(FillingInPrices, PriceSourceSettingsComposer, QuantitySourceSettingsComposer),
		"ChangeToTheSeasonalIndex");
	
	If ParameterChangeToSeasonalFactor <> Undefined Then
		If FillingInPrices Then
			ChangeToSeasonalCoefficientPrice = ParameterChangeToSeasonalFactor.Value;
		Else
			ChangeQuantityToSeasonalFactor = ParameterChangeToSeasonalFactor.Value;
		EndIf;
	EndIf;
	
	If ValueIsFilled(SourceItem.CustomSettingsAddress) Then
		UserSettings = GetFromTempStorage(SourceItem.CustomSettingsAddress);
	Else
		UserSettings = New DataCompositionUserSettings();
	EndIf;
	
	SourceSettingsComposer = ?(FillingInPrices, PriceSourceSettingsComposer, QuantitySourceSettingsComposer);
	
	If UserSettings <> Undefined Then
		SourceSettingsComposer.LoadUserSettings(UserSettings);
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeSourceSettingsComposers(FillingInPrices)
	
	RootElementOfRows = RootItem(FillingRule, FillingInPrices);
	SourceElements__ = RootElementOfRows.GetItems();
	
	If SourceElements__.Count() > 0 Then
		SourceItem = SourceElements__.Get(0);
	Else
		Return;
	EndIf;
	
	Attributes = Common.ObjectAttributesValues(SourceItem.Source,
		"DCSTemplateName, DataCompositionSchema, StorageOfDataCompositionSettings");
	
	If ValueIsFilled(Attributes.DCSTemplateName) Then
		DataCompositionSchema = Catalogs.PlanningDataSources.LayoutSchemeByTemplateName(Attributes.DCSTemplateName);
		If DataCompositionSchema = Undefined Then
			DataCompositionSchema = Attributes.DataCompositionSchema.Get();
		EndIf; 
	Else
		DataCompositionSchema = Attributes.DataCompositionSchema.Get();
	EndIf;
	
	Try
		DataCompositionSettings = Attributes.StorageOfDataCompositionSettings.Get();
	Except
		Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong nguồn điền dữ liệu ""%1"" có lỗi trong tùy chỉnh. Đã đặt tùy chỉnh mặc định.';
				|ru = 'В источнике заполнения данных ""%1"" имеются ошибки в настройках. Установлены настройки по умолчанию.';
				|en = 'There are errors in the settings in the ""%1"" data filling source. The default settings are set.'; fa = 'There are errors in the settings in the ""%1"" data filling source. The default settings are set.';
				|it = 'Nell''origine di compilazione dati ""%1"" sono presenti errori di impostazione. Sono selezionate le impostazioni predefinite.';
				|pl = 'Źródło wypełnienia danych ""%1"" zawiera błędy w ustawieniach. Ustawione są ustawienia domyślne.';
				|tr = 'Kaynakta ""%1"" verisinin doldurulması esnasında ayarlarda hatalar meydana geldi. Ayarlar varsayılana göre ayarlandı.'"), SourceItem.Source));
			Modified = True;
	EndTry;
	
	SourceSettingsComposer = ?(FillingInPrices, PriceSourceSettingsComposer, QuantitySourceSettingsComposer);
	
	SourceSettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(
		PutToTempStorage(DataCompositionSchema, UUID)));

	If DataCompositionSettings <> Undefined Then
		SourceSettingsComposer.LoadSettings(DataCompositionSettings);
	Else
		SourceSettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	SourceSettingsComposer.Refresh();
	
	UserSettings = GetFromTempStorage(SourceItem.CustomSettingsAddress);
	
	If UserSettings <> Undefined Then
		SourceSettingsComposer.LoadUserSettings(UserSettings);
	EndIf;
	
	If ValueIsFilled(FilterPlan_) And Not FillingInPrices And Not SourceItem.FilterFromHeaderIsSet Then
		Catalogs.PlanningDataSources.SetSelectionsBasedOnPlanAttributes(QuantitySourceSettingsComposer, FilterPlan_);
		SourceItem.FilterFromHeaderIsSet = True;
	EndIf;
	
	ParameterChangeToSeasonalFactor = DataCompositionClientServer.GetParameter(
		?(FillingInPrices, PriceSourceSettingsComposer, QuantitySourceSettingsComposer),
		"ChangeToTheSeasonalIndex");
	
	ProductsField = New DataCompositionField("Products");
	ThereIsFieldProducts = False;
	GroupingFields = PlanningClientServer.GetDimensionFields(SettingsComposer);
	For Each Field In GroupingFields Do
	
		If Field.Use And Field.Field = ProductsField Then
		
			ThereIsFieldProducts = True;
			Break;
		
		EndIf; 
	
	EndDo;
	
	If Not ThereIsFieldProducts Then
	
		SelectionFields = PlanningClientServer.GetSelectionFields(SettingsComposer);
		For Each Field In SelectionFields Do
			
			If Field.Use And Field.Field = ProductsField Then
				
				ThereIsFieldProducts = True;
				Break;
				
			EndIf; 
			
		EndDo;
	
	EndIf; 
	
	UseSeasonalIndexes = ThereIsFieldProducts
		And ParameterChangeToSeasonalFactor <> Undefined 
		And GetFunctionalOption("UseSeasonalIndexes");
	
	If UseSeasonalIndexes Then
		If FillingInPrices Then
			ChangeToSeasonalCoefficientPrice = ParameterChangeToSeasonalFactor.Value;
		Else
			ChangeQuantityToSeasonalFactor = ParameterChangeToSeasonalFactor.Value;
		EndIf;
	EndIf;
	
	If FillingInPrices Then
		Items.GroupSeasonalCoefficients1.Visible = UseSeasonalIndexes;
	Else
		Items.GroupSeasonalCoefficients.Visible = UseSeasonalIndexes;
	EndIf;
	
EndProcedure

&AtClient
Procedure EstablishTaggingWithSubordinates(Tree, Value)
	
	TreeElements = Tree.GetItems();
	
	For Each TreeItem In TreeElements Do
		
		TreeItem.Use = Value;
		EstablishTaggingWithSubordinates(TreeItem, Value);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure PlaceFillRuleInTemporaryStorage(Val Data, Address, PlanByAmount)
	
	RuleFillingTable = GetFromTempStorage(Address);
	
	RuleFillingTable.Clear();
	
	For Each DataString In Data.GetItems().Get(0).GetItems() Do
		
		DataString.Attach = False;
		AddTreeRowToTablePart(RuleFillingTable, DataString);
		
	EndDo;
	
	If PlanByAmount Then
		For Each DataString In Data.GetItems().Get(1).GetItems() Do
			
			DataString.Attach = True;
			AddTreeRowToTablePart(RuleFillingTable, DataString);
			
		EndDo;
	EndIf;
	
	PutToTempStorage(RuleFillingTable, Address);
	
EndProcedure

&AtServerNoContext
Function SelectionByResources(SettingsComposer)
	
	SelectionByResources = New Structure("Count, Price, Sum", False, False, False);
	
	For Each SelectionSettingsElement In SettingsComposer.Settings.Filter.Items Do
		
		If String(SelectionSettingsElement.LeftValue) = "Count" Then
			
			For Each UserSettingsSelectionElement In SettingsComposer.UserSettings.Items Do
				If SelectionSettingsElement.UserSettingID = UserSettingsSelectionElement.UserSettingID Then
					SelectionByResources.Insert("Count", UserSettingsSelectionElement.Use);
				EndIf;
			EndDo;
			
		ElsIf String(SelectionSettingsElement.LeftValue) = "Price" Then
			
			For Each UserSettingsSelectionElement In SettingsComposer.UserSettings.Items Do
				If SelectionSettingsElement.UserSettingID = UserSettingsSelectionElement.UserSettingID Then
					SelectionByResources.Insert("Price", UserSettingsSelectionElement.Use);
				EndIf;
			EndDo;
			
		ElsIf String(SelectionSettingsElement.LeftValue) = "Sum" Then
			
			For Each UserSettingsSelectionElement In SettingsComposer.UserSettings.Items Do
				If SelectionSettingsElement.UserSettingID = UserSettingsSelectionElement.UserSettingID Then
					SelectionByResources.Insert("Sum", UserSettingsSelectionElement.Use);
				EndIf;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Return SelectionByResources;
	
EndFunction

&AtServerNoContext
Function CheckFillingRuleServer(Val Data, FillingRuleAddress, AddressOfDataConversionScheme, PlanProfile, PlanByAmount, SelectionByResources)

	RuleFillingTable = GetFromTempStorage(FillingRuleAddress);
	
	RuleFillingTable.Clear();
	
	For Each DataString In Data.GetItems().Get(0).GetItems() Do
		
		DataString.Attach = False;
		AddTreeRowToTablePart(RuleFillingTable, DataString);
		
	EndDo;
	
	If PlanByAmount Then
		For Each DataString In Data.GetItems().Get(1).GetItems() Do
			
			DataString.Attach = True;
			AddTreeRowToTablePart(RuleFillingTable, DataString);
			
		EndDo;
	EndIf; 
	
	Return Planning.CheckFillingRule(RuleFillingTable, AddressOfDataConversionScheme, PlanProfile,  "FillingRule", SelectionByResources);

EndFunction

&AtClientAtServerNoContext
Function AdvancedFeaturesAreUsed(Form)
	
	UseAdvancedFeatures = False;
	
	For Each Setting In Form.SettingsComposer.UserSettings.Items Do
	
		If TypeOf(Setting) = Type("DataCompositionFilterItem") And Setting.Use Then
			UseAdvancedFeatures = True;
			Break;
		EndIf; 
		
		If TypeOf(Setting) = Type("DataCompositionFilter") Then
			For Each FilterElement In Setting.Items Do
				If FilterElement.Use Then
					UseAdvancedFeatures = True;
					Break;
				EndIf; 
			EndDo; 
		EndIf; 
		
		If TypeOf(Setting) = Type("DataCompositionOrder") Then
			For Each OrderItem In Setting.Items Do
				If OrderItem.Use Then
					UseAdvancedFeatures = True;
					Break;
				EndIf; 
			EndDo; 
		EndIf;
	
	EndDo;
	
	RootElementOfRows = RootItem(Form.FillingRule);
	SourceElements__ = RootElementOfRows.GetItems();
	
	If SourceElements__.Count() > 1 Or SourceElements__.Count() = 1 And SourceElements__.Get(0).ElementType <> 0 Then
		
		UseAdvancedFeatures = True;
		
	EndIf; 
	
	If Form.PlanByAmount Then
		
		RootElementOfRows = RootItem(Form.FillingRule, True);
		SourceElements__ = RootElementOfRows.GetItems();
		
		If SourceElements__.Count() > 1 Or SourceElements__.Count() = 1 And SourceElements__.Get(0).ElementType <> 0 Then
			
			UseAdvancedFeatures = True;
			
		EndIf;
		
	EndIf;
	
	Return UseAdvancedFeatures;
	
EndFunction

&AtClient
Procedure TurnOffAdvancedModeCompletion(Result, AdditionalParameters) Export 
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	RootElementOfRows = RootItem(FillingRule);
	SourceElements__ = RootElementOfRows.GetItems();
	
	If SourceElements__.Count() > 1 Or SourceElements__.Count() = 1 And SourceElements__.Get(0).ElementType <> 0 Then
		
		SourceElements__.Clear();
		
	EndIf; 
	
	If SourceElements__.Count() = 0 Then
		FillingRuleQuantitySource = Undefined;
	EndIf;
	
	If PlanByAmount Then
		
		RootElementOfRows = RootItem(FillingRule, True);
		SourceElements__ = RootElementOfRows.GetItems();
		
		If SourceElements__.Count() > 1 Or SourceElements__.Count() = 1 And SourceElements__.Get(0).ElementType <> 0 Then
			
			SourceElements__.Clear();
			
		EndIf;
		
		If SourceElements__.Count() = 0 Then
			FillingRulePriceSource = Undefined;
		EndIf;
		
	EndIf;
	
	For Each Setting In SettingsComposer.UserSettings.Items Do
	
		If TypeOf(Setting) = Type("DataCompositionFilterItem") Then
			Setting.Use = False;
		EndIf; 
		
		If TypeOf(Setting) = Type("DataCompositionFilter") Then
			For Each FilterElement In Setting.Items Do
				FilterElement.Use = False;
			EndDo; 
		EndIf; 
		
		If TypeOf(Setting) = Type("DataCompositionOrder") Then
			For Each OrderItem In Setting.Items Do
				OrderItem.Use = False;
			EndDo; 
		EndIf;
		
	EndDo;
	
	UpdateUserSettingsFromTemporaryStorage(False);
	If PlanByAmount Then
		UpdateUserSettingsFromTemporaryStorage(True);
	EndIf;
	
	UseAdvancedPopulationOptions = False;
	CustomizeForm();
	
EndProcedure

&AtClient
Procedure OpenPreviewSaveEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf; 
	
	FillInTheDocumentSaveServer(True);
	
	OpenPreview();
	
EndProcedure

&AtClient
Procedure OpenPreview()
	
	FormParameters = New Structure;
	
	FormParameters.Insert("PlanProfile",                      PlanProfile);
	FormParameters.Insert("FillingRuleAddress",        FillingRuleAddress);
	FormParameters.Insert("CustomSettingsAddress", CustomSettingsAddress);
	FormParameters.Insert("RoundingPrecision",            RoundingPrecision);
	FormParameters.Insert("ChangeResultTo",           ChangeResultTo);
	FormParameters.Insert("BeginOfPeriod",                 BeginOfPeriod);
	FormParameters.Insert("PeriodEnding",              PeriodEnding);
	
	RootElementOfRows = RootItem(FillingRule, False);
	SourceElements__ = RootElementOfRows.GetItems();
	
	If SourceElements__.Count() > 0 Then
		SourceItem = SourceElements__.Get(0);
		
		If Not SourceItem.FilterFromHeaderIsSet Then
			FormParameters.Insert("FilterPlan_", FilterPlan_);
		EndIf;
		
	EndIf;
	
	OpenForm("Catalog.PlanningDataSources.Form.PreviewForm",FormParameters ,ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Save_ComposerSettings()
	
	SourceItem = GetFirstElementOfFillRule(False);
	
	PutToTempStorage(QuantitySourceSettingsComposer.UserSettings, SourceItem.CustomSettingsAddress);
	
	QuantitySourceSettingsComposer.LoadSettings(ApplyCustomSettings(QuantitySourceSettingsComposer));
	
	SourceItem.PopulationFields = PlanningClientServer.GetTextOfSelectedLayoutFields(QuantitySourceSettingsComposer);
	
	If PlanByAmount Then
		
		SourceItem = GetFirstElementOfFillRule(True);
		
		PutToTempStorage(PriceSourceSettingsComposer.UserSettings, SourceItem.CustomSettingsAddress);
		
		PriceSourceSettingsComposer.LoadSettings(ApplyCustomSettings(PriceSourceSettingsComposer));
		
		SourceItem.PopulationFields = PlanningClientServer.GetTextOfSelectedLayoutFields(PriceSourceSettingsComposer);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ApplyCustomSettings(SettingsComposer)
	Return SettingsComposer.GetSettings();
EndFunction

#EndRegion

#EndRegion
