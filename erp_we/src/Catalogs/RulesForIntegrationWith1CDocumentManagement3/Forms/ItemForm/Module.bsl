#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	QuestionAsked = False;
	SelectionOfValuesOfAdditionalAttributesIsAvailable =
		IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("3.0.15.41");
	
	AbbreviatedNameOfConfiguration =
		IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	If ValueIsFilled(AbbreviatedNameOfConfiguration) Then
		Items.ObjectTypeIS.Title = StrTemplate(NStr("vi = 'Đối tượng %1';
													|ru = 'Объект %1';
													|en = 'Object %1'; fa = 'Object %1';
													|it = 'Oggetto %1';
													|pl = 'Obiekt %1';
													|tr = 'Nesne %1'"), AbbreviatedNameOfConfiguration);
		Items.GroupGettingFromTO.Title = StrTemplate(NStr("vi = 'Điền mục tin đối tượng %1';
															|ru = 'Заполнение реквизитов объекта %1';
															|en = 'Fill %1 object attributes'; fa = 'Fill %1 object attributes';
															|it = 'Compilazione di attributi dell''oggetto %1';
															|pl = 'Wypełnienie atrybutów obiektu %1';
															|tr = 'Nesne özniteliklerinin doldurulması %1'"),
			AbbreviatedNameOfConfiguration);
		Items.KeyAttributesISPresentation.Title = StrTemplate(NStr("vi = 'Mục tin đối tượng %1';
																	|ru = 'Реквизит объекта %1';
																	|en = '%1 object attribute'; fa = '%1 object attribute';
																	|it = 'Attributo oggetto %1';
																	|pl = 'Atrybut obiektu %1';
																	|tr = 'Nesne özniteliği %1'"),
			AbbreviatedNameOfConfiguration);
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) And ValueIsFilled(Parameters.ObjectTypeIS) Then
		Object.ObjectTypeIS = Parameters.ObjectTypeIS;
		Items.ObjectTypeIS.Enabled = False;
	EndIf;
	
	If ValueIsFilled(Object.ObjectTypeIS) Then
		
		ConsumerObject = Metadata.FindByFullName(Object.ObjectTypeIS);
		If ConsumerObject <> Undefined Then
			Object.ObjectPresentationIS = ?(ConsumerObject.Synonym = "",
				ConsumerObject.Name,
				ConsumerObject.Synonym);
		EndIf;
		
	EndIf;
	
	IsFullUser = Users.IsFullUser();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UseApplicabilityConditionWhenExporting = Number(Object.UseApplicabilityConditionWhenExporting);
	UseApplicabilityConditionWhenImporting = Number(Object.UseApplicabilityConditionWhenImporting);
	ConditionOfApplicabilityONChange();
	
	TestConnection();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not ValueIsFilled(Object.ObjectPresentationIS) Then
		Cancel = True;
		
		Message = New UserMessage();
		Message.Text = CommonClientServer.FillingErrorText(,, Items.ObjectTypeIS.Title);
		Message.Field = "Object.ObjectPresentationIS";
		Message.Message();
	EndIf;
	
	If Not ValueIsFilled(Object.ObjectPresentationDM) Then
		Cancel = True;
		
		Message = New UserMessage();
		Message.Text = CommonClientServer.FillingErrorText(,, Items.ObjectTypeDM.Title);
		Message.Field = "Object.ObjectPresentationDM";
		Message.Message();
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.AttributeFillingRulesIS.Clear();
	For Each Rule In AttributeFillingRulesIS.GetItems() Do
		If LoadingRuleFilled(Rule) Then
			NewRule = CurrentObject.AttributeFillingRulesIS.Add();
			FillPropertyValues(NewRule, Rule);
			If Rule.ThisIsTable Then
				For Each SubordinateRule In Rule.GetItems() Do
					If LoadingRuleFilled(SubordinateRule) Then
						NewRule = CurrentObject.AttributeFillingRulesIS.Add();
						FillPropertyValues(NewRule, SubordinateRule);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	
	CurrentObject.KeyAttributesDM.Clear();
	For Each String In KeyAttributesDM Do
		If String.KeyAttribute_ And ValueIsFilled(String.Name) Then
			FillPropertyValues(CurrentObject.KeyAttributesDM.Add(), String);
		EndIf;
	EndDo;
	
	CurrentObject.KeyAttributesIS.Clear();
	For Each String In KeyAttributesIS Do
		If String.KeyAttribute_ And ValueIsFilled(String.Name) Then
			FillPropertyValues(CurrentObject.KeyAttributesIS.Add(), String);
		EndIf;
	EndDo;
	
	Catalogs.RulesForIntegrationWith1CDocumentManagement3.RefreshPresentation(CurrentObject);
	Catalogs.RulesForIntegrationWith1CDocumentManagement3.ToCheckRule(CurrentObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("IntegrationWith1CWorkflow3_RuleWritten");
	
	SetAvailability();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "IntegrationWith1CDocumentManagement_SuccessfulConnection" And Source <> ThisObject Then
		WhenConnecting();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AuthorizationSettingsDecorationClick(Item)
	
	Notification = New CallbackDescription("AuthorizationSettingsDecorationClickCompletion", ThisObject);
	NameOfParameterForm = "DataProcessor.IntegrationWith1CDocumentManagementCore.Form.AuthorizationIn1CDocumentManagement";
	
	OpenForm(NameOfParameterForm,, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AuthorizationSettingsDecorationClickCompletion(Result, Var_Parameters) Export
	
	If Result = True Then
		WhenConnecting();
	EndIf;
	
EndProcedure

&AtClient
Procedure InstructionIsConditionOfApplicabilityWhenUnloadingOnClick(Item, EventData, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.InstructionOnClick(Item, EventData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure InstructionIsConditionOfApplicabilityWhenUploadingOnClick(Item, EventData, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.InstructionOnClick(Item, EventData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure UseApplicabilityConditionWhenExportingOnChange(Item)
	
	Modified = True;
	
	Object.UseApplicabilityConditionWhenExporting = Boolean(UseApplicabilityConditionWhenExporting);
	ConditionOfApplicabilityONChange();
	
EndProcedure

&AtClient
Procedure UseApplicabilityConditionWhenImportingOnChange(Item)
	
	Modified = True;
	
	Object.UseApplicabilityConditionWhenImporting = Boolean(UseApplicabilityConditionWhenImporting);
	ConditionOfApplicabilityONChange();
	
EndProcedure

&AtClient
Procedure ObjectTypeISClearing(Item, StandardProcessing)
	
	WhenChangingIPObject("", "");
	
EndProcedure

&AtClient
Procedure ObjectTypeISStartChoice(Item, ChoiceData, StandardProcessing)
	
	Notification = New CallbackDescription("ObjectTypeISStartChoiceCompletion", ThisObject);
	
	IntegrationWith1CDocumentManagementCoreClient.ObjectTypeISStartChoice(
		Object.ObjectTypeIS,
		Notification);
	
EndProcedure

&AtClient
Procedure ObjectTypeISStartChoiceCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		WhenChangingIPObject(Result.Name, Result.Synonym);
	EndIf;
	
EndProcedure

&AtClient
Procedure ObjectTypeISChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected <> Undefined Then
		StandardProcessing = False;
		SelectedElement = MetadataList.FindByValue(ValueSelected);
		WhenChangingIPObject(SelectedElement.Value, SelectedElement.Presentation);
	EndIf;
	
EndProcedure

&AtClient
Procedure ObjectTypeISAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	
	For Each ChoiceItem In MetadataList Do
		If Find(Upper(ChoiceItem.Presentation), Upper(Text)) <> 0 Then
			ChoiceData.Add(ChoiceItem.Value, ChoiceItem.Presentation);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ObjectTypeISTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	StandardProcessing = False;
	
	If IsBlankString(Text) Then
		WhenChangingIPObject("", "");
		Return;
	EndIf;
	
	ChoiceData = New ValueList;
	
	For Each ChoiceItem In MetadataList Do
		If Find(Upper(ChoiceItem.Presentation), Upper(Text)) <> 0 Then
			ChoiceData.Add(ChoiceItem.Value, ChoiceItem.Presentation);
		EndIf;
	EndDo;
	
	If ChoiceData.Count() = 1 Then
		WhenChangingIPObject(ChoiceData[0].Value, ChoiceData[0].Presentation);
		StandardProcessing = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ObjectTypeDMOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FoundRules = SuitableRulesForLoadingVDO.FindRows(
		New Structure("VDOLoadingRuleID", Object.DMDataLoadingRule));
	
	If FoundRules.Count() = 0 Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagement3Client.OpenDMObject(FoundRules[0].URL);
	
EndProcedure

&AtClient
Procedure ObjectTypeDMClearing(Item, StandardProcessing)
	
	WhenChangingObjectTO(Undefined);
	
EndProcedure

&AtClient
Procedure ObjectTypeDMStartChoice(Item, ChoiceData, StandardProcessing)
	
	Notification = New CallbackDescription("ObjectTypeDMStartChoiceCompletion", ThisObject);
	
	If SuitableRulesForLoadingVDO.Count() = 0 Then
		FillInAppropriateRulesForLoadingVDO();
	EndIf;
	
	FormParameter = New Structure;
	FormParameter.Insert("CurrentRow", Object.DMDataLoadingRule);
	OpenForm("Catalog.RulesForIntegrationWith1CDocumentManagement3.Form.SelectingDMDataLoadingRule",
		FormParameter,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ObjectTypeDMStartChoiceCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		WhenChangingObjectTO(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure ObjectTypeDMChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected <> Undefined Then
		StandardProcessing = False;
		
		If SuitableRulesForLoadingVDO.Count() = 0 Then
			FillInAppropriateRulesForLoadingVDO();
		EndIf;
		
		Rows = SuitableRulesForLoadingVDO.FindRows(New Structure("VDOLoadingRuleID", ValueSelected));
		If Rows.Count() = 1 Then
			WhenChangingObjectTO(Rows[0]);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ObjectTypeDMAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	
	If SuitableRulesForLoadingVDO.Count() = 0 Then
		FillInAppropriateRulesForLoadingVDO();
	EndIf;
	
	For Each ChoiceItem In SuitableRulesForLoadingVDO Do
		If Find(Upper(ChoiceItem.VDOLoadingRule), Upper(Text)) <> 0 Then
			ChoiceData.Add(ChoiceItem.VDOLoadingRuleID, ChoiceItem.VDOLoadingRule);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ObjectTypeDMTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	StandardProcessing = False;
	
	If IsBlankString(Text) Then
		WhenChangingObjectTO(Undefined);
		Return;
	EndIf;
	
	ChoiceData = New ValueList;
	
	If SuitableRulesForLoadingVDO.Count() = 0 Then
		FillInAppropriateRulesForLoadingVDO();
	EndIf;
	
	For Each ChoiceItem In SuitableRulesForLoadingVDO Do
		If Find(Upper(ChoiceItem.VDOLoadingRule), Upper(Text)) <> 0 Then
			ChoiceData.Add(ChoiceItem.VDOLoadingRuleID, ChoiceItem.VDOLoadingRule);
		EndIf;
	EndDo;
	
	If ChoiceData.Count() = 1 Then
		Rows = SuitableRulesForLoadingVDO.FindRows(
			New Structure("VDOLoadingRuleID", ChoiceData[0].Value));
		If Rows.Count() = 1 Then
			WhenChangingObjectTO(Rows[0]);
		EndIf;
		StandardProcessing = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersKeyAttributesDM

&AtClient
Procedure KeyAttributesDMKeyAttribute_OnChange(Item)
	
	CurrentData = Items.KeyAttributesDM.CurrentData;
	CurrentRowNumber = KeyAttributesDM.IndexOf(CurrentData);
	KeyAttributesDM.Sort("KeyAttribute_ DESC, Presentation");
	Items.KeyAttributesDM.CurrentRow = KeyAttributesDM[CurrentRowNumber].GetID();
	Modified = True;
	
EndProcedure

&AtClient
Procedure KeyAttributesDMAttributeValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.KeyAttributesDM.CurrentData;
	
	// Configure the input field for primitive types.
	If CurrentData.Type.Count() = 0 Then
		StandardProcessing = False;
		CurrentData.AttributeValue = "";
		Return;
	Else
		FirstType = CurrentData.Type[0].Value;
		Items.KeyAttributesDMAttributeValue.SpinButton =
			(FirstType = "Number" Or FirstType = "Date");
	EndIf;
	
	If TypeOf(CurrentData.AttributeValue) = Type("Number")
			Or TypeOf(CurrentData.AttributeValue) = Type("Date")
			Or TypeOf(CurrentData.AttributeValue) = Type("Boolean") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	ValueSelectionParametersBefore = IntegrationWith1CDocumentManagementCoreClient.ValueSelectionParametersBefore();
	ValueSelectionParametersBefore.Notification =
		New CallbackDescription("ChooseValueOfAttributeDMCompletionInputValue", ThisObject);
	ValueSelectionParametersBefore.EditText = Item.EditText;
	ValueSelectionParametersBefore.Presentation = CurrentData.Presentation;
	ValueSelectionParametersBefore.AttributeValue = CurrentData.AttributeValue;
	ValueSelectionParametersBefore.AttributeValueID = CurrentData.AttributeValueID;
	ValueSelectionParametersBefore.AttributeValueType = CurrentData.AttributeValueType;
	
	If CurrentData.IsAdditionalAttributeDM
			And SelectionOfValuesOfAdditionalAttributesIsAvailable
			And FirstType = "DMObjectPropertyValue" Then
		ValueSelectionParametersBefore.Filter = New Structure("additionalPropertyID", CurrentData.Name);
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreClient.ChooseValueOfAttributeBefore(
		ThisObject,
		Items.KeyAttributesDMAttributeValue,
		CurrentData.Type,
		ValueSelectionParametersBefore);
	
EndProcedure

&AtClient
Procedure ChooseValueOfAttributeDMCompletionInputValue(Result, NotificationParameters) Export
	
	CurrentData = Items.KeyAttributesDM.CurrentData;
	
	If Result <> Undefined Then
		If TypeOf(Result) = Type("Structure") Then
			CurrentData.AttributeValue = Result.AttributePresentation;
			CurrentData.AttributeValueID = Result.AttributeID;
			CurrentData.AttributeValueType = Result.AttributeType;
		Else
			CurrentData.AttributeValue = Result;
		EndIf;
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure KeyAttributesDMAttributeValueChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.KeyAttributesDM.CurrentData;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		CurrentData.AttributeValue = ValueSelected.name;
		CurrentData.AttributeValueID = ValueSelected.ID;
		CurrentData.AttributeValueType = ValueSelected.type;
	Else
		CurrentData.AttributeValue = ValueSelected;
	EndIf;
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure KeyAttributesDMAttributeValueAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	CurrentData = Items.KeyAttributesDM.CurrentData;
	
	// Configure the input field for primitive types.
	If CurrentData.Type.Count() = 0 Then
		StandardProcessing = False;
		CurrentData.AttributeValue = "";
		Text = "";
	Else
		FirstType = CurrentData.Type[0].Value;
		Items.KeyAttributesDMAttributeValue.SpinButton =
			(FirstType = "Number" Or FirstType = "Date");
	EndIf;
	
	If ValueIsFilled(Text) Then
		
		If FirstType = "String"
				Or FirstType = "Boolean"
				Or FirstType = "Date"
				Or FirstType = "Number" Then
			Return;
		EndIf;
		
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			CurrentData.Type, ChoiceData, Text, StandardProcessing);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure KeyAttributesDMAttributeValueTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	CurrentData = Items.KeyAttributesDM.CurrentData;
	
	If ValueIsFilled(Text) Then
		
		FirstType = CurrentData.Type[0].Value;
		If FirstType = "String"
				Or FirstType = "Boolean"
				Or FirstType = "Date"
				Or FirstType = "Number" Then
			Return;
		EndIf;
		
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			CurrentData.Type, ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			KeyAttributesDMAttributeValueChoiceProcessing(
				Items.KeyAttributesDMAttributeValue,
				ChoiceData[0].Value,
				StandardProcessing);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure KeyAttributesDMBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure KeyAttributesDMBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure KeyAttributesDMAttributeValueOnChange(Item)
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersKeyAttributesIS

&AtClient
Procedure KeyAttributesISKeyAttribute_OnChange(Item)
	
	CurrentData = Items.KeyAttributesIS.CurrentData;
	CurrentRowNumber = KeyAttributesIS.IndexOf(CurrentData);
	KeyAttributesIS.Sort("KeyAttribute_ DESC, Presentation");
	Items.KeyAttributesIS.CurrentRow = KeyAttributesIS[CurrentRowNumber].GetID();
	Modified = True;
	
EndProcedure

&AtClient
Procedure KeyAttributesISAttributeValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.KeyAttributesIS.CurrentData;
	
	IntegrationWith1CDocumentManagementCoreClientServer.ConfigureInputFieldByType(
		Items.KeyAttributesISAttributeValue,
		CurrentData.Type);
	
	If TypeOf(CurrentData.AttributeValue) = Type("Number")
			Or TypeOf(CurrentData.AttributeValue) = Type("Date")
			Or TypeOf(CurrentData.AttributeValue) = Type("Boolean") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Notification = New CallbackDescription("ChooseValueOfAttributeISCompletionInputValue", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.ChooseValueOfAttributeIS(
		ThisObject,
		Items.KeyAttributesISAttributeValue,
		CurrentData.Type,
		CurrentData.Presentation,
		CurrentData.AttributeValue,
		CurrentData.AdditionalAttributeIS,
		Notification);
	
EndProcedure

&AtClient
Procedure ChooseValueOfAttributeISCompletionInputValue(Result, NotificationParameters) Export
	
	CurrentData = Items.KeyAttributesIS.CurrentData;
	
	If Result <> Undefined Then
		CurrentData.AttributeValue = Result;
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure KeyAttributesISAttributeValueAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	CurrentData = Items.KeyAttributesIS.CurrentData;
	
	IntegrationWith1CDocumentManagementCoreClientServer.ConfigureInputFieldByType(
		Items.KeyAttributesISAttributeValue,
		CurrentData.Type);
	
EndProcedure

&AtClient
Procedure KeyAttributesISBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure KeyAttributesISBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure KeyAttributesISAttributeValueOnChange(Item)
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttributeFillingRulesIS

&AtClient
Procedure AttributeFillingRulesISBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure AttributeFillingRulesISBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	CurrentData = Items.AttributeFillingRulesIS.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Parent = CurrentData.GetParent();
	If Parent <> Undefined Then
		If Parent.Variant = VariantExpression() Then
			ShowMessageBox(,
				NStr("vi = 'Bảng được điền bằng kết quả biểu thức bằng ngôn ngữ hệ thống,
					|do đó không cần quy tắc dành cho các mục tin riêng biệt.';
					|ru = 'Таблица заполняется результатом выражения на встроенном языке,
					|поэтому правила для отдельных реквизитов не нужны.';
					|en = 'The table is populated with the result of the expression in 1C:Enterprise language,
					| so the rules for the individual details are not required.'; fa = 'The table is populated with the result of the expression in 1C:Enterprise language,
					| so the rules for the individual details are not required.';
					|it = 'La tabella viene compilata con il risultato di espressione nel linguaggio integrato,
					|poiché non sono necessarie regole per gli attributi singoli.';
					|pl = 'Tabela jest wypełniana wynikiem wyrażenia w języku wbudowanym,
					|dlatego reguły dla oddzielnych atrybutów nie są potrzebne.';
					|tr = 'Tablo, yerleşik dildeki ifadenin sonucuyla doldurulur,
					|bu nedenle bireysel öznitelikler için kurallara gerek yoktur.'"));
			Return;
		EndIf;
		If Parent.Variant = OptionEmpty() Then
			ShowMessageBox(,
				NStr("vi = 'Ban đầu cần chọn phương án điền bảng.';
					|ru = 'Вначале нужно выбрать вариант заполнения таблицы.';
					|en = 'First select a table filling option.'; fa = 'First select a table filling option.';
					|it = 'Innanzitutto è necessario selezionare la variante di compilazione della tabella.';
					|pl = 'Najpierw należy wybrać wariant wypełnienia tabeli.';
					|tr = 'Öncelikle tablo doldurma seçeneğinin seçilmesi gerekir.'"));
			Return;
		EndIf;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Variant");
	FormParameters.Insert("ObjectAttributePresentationIS");
	FormParameters.Insert("ToolTip");
	FormParameters.Insert("ObjectAttributeTypeIS");
	FormParameters.Insert("AttributeNameObjectDM");
	FormParameters.Insert("AttributeNameObjectIS");
	FormParameters.Insert("ObjectAttributePresentationDM");
	FormParameters.Insert("AttributeValueIS");
	FormParameters.Insert("ComputedExpression");
	FormParameters.Insert("PlaceWhereExpressionIsExecuted");
	FormParameters.Insert("ShouldUpdate");
	FormParameters.Insert("IsAdditionalAttributeDM");
	FormParameters.Insert("AdditionalAttributeDMID");
	FormParameters.Insert("AdditionalAttributeDMType");
	FormParameters.Insert("IsAdditionalAttributeIS");
	FormParameters.Insert("AdditionalAttributeIS");
	FormParameters.Insert("KeyAttribute_");
	FormParameters.Insert("ThisIsTable");
	FormParameters.Insert("DependentItem", False);
	FormParameters.Insert("UpdateParent");
	FormParameters.Insert("ModeOfChangingTheDataOfThePostedDocument");
	
	FillPropertyValues(FormParameters, CurrentData);
	
	Parent = CurrentData.GetParent();
	If Parent <> Undefined Then
		FormParameters.DependentItem = True;
		FormParameters.UpdateParent = Parent.ShouldUpdate;
		FormParameters.ModeOfChangingTheDataOfThePostedDocument = Parent.ModeOfChangingTheDataOfThePostedDocument;
	EndIf;
	
	If ValueIsFilled(CurrentData.Table) Then
		If Parent.Variant = OptionProps() Then
			FormParameters.Insert("Table", Parent.AttributeNameObjectDM);
		Else
			FormParameters.Insert("Table", "");
		EndIf;
	EndIf;
	
	FormParameters.Insert("ObjectAttributesBefore", ObjectAttributesBefore);
	FormParameters.Insert("ObjectTypeIS", Object.ObjectTypeIS);
	FormParameters.Insert("ObjectTypeDM", Object.ObjectTypeDM);
	FormParameters.Insert("DocumentKindDM", Object.DocumentKindDMID);
	
	FillingInDocument = StrStartsWith(Object.ObjectTypeIS, "Document.");
	FormParameters.Insert("FillingInDocument", FillingInDocument);
	
	FormParameters.Insert("IsFullUser", IsFullUser);
	
	If CurrentData.ThisIsTable Then
		OpenedForm = "Catalog.RulesForIntegrationWith1CDocumentManagement3.Form.FormOfTheImportRuleForTable"
	Else
		OpenedForm = "Catalog.RulesForIntegrationWith1CDocumentManagement3.Form.FormOfTheImportRule"
	EndIf;
	
	Notification = New CallbackDescription("AttributeFillingRulesISBeforeRowChangeCompletion",
		ThisObject, CurrentData);
	
	OpenForm(
		OpenedForm,
		FormParameters,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AttributeFillingRulesISBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	CurrentData = Items.AttributeFillingRulesIS.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	AttributeFillingRulesISBeforeDeleteRowContinued(CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Async Procedure FillByDefault(Val Command)
	
	NeedToAskQuestion_ = False;
	
	For Each String In AttributeFillingRulesIS.GetItems() Do
		If ValueIsFilled(String.ComputedExpression)
				Or ValueIsFilled(String.AttributeValueIS)
				Or ValueIsFilled(String.AttributeNameObjectDM) Then
			NeedToAskQuestion_ = True;
			Break;
		EndIf;
	EndDo;
	
	If NeedToAskQuestion_ Then
		Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(
			NStr("vi = 'Quy tắc sẽ được điền theo mặc định. Điền?';
				|ru = 'Правила будут заполнены по умолчанию. Заполнить?';
				|en = 'Rules will be populated by default. Populate?'; fa = 'Rules will be populated by default. Populate?';
				|it = 'Правила будут заполнены по умолчанию. Заполнить?';
				|pl = 'Reguły zostaną wypełnione domyślnie. Wypełnić?';
				|tr = 'Kurallar varsayılan olarak doldurulacaktır. Doldur?'"),
			IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo(DialogReturnCode.No));
		If Response = DialogReturnCode.Yes Then
			FillInByDefaultOnServer();
		EndIf;
	Else
		FillInByDefaultOnServer();
	EndIf;
	
EndProcedure

&AtClient
Async Procedure MarkToDelete(Val Command)
	
	QuestionParametersYesNo = IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo(
		DialogReturnCode.Yes);
	If Modified Then
		If Object.DeletionMark Then
			QueryText = NStr("vi = 'Để bỏ dấu xóa, cần ghi lại các thay đổi';
							|ru = 'Для снятия пометки на удаление необходимо записать внесенные изменения';
							|en = 'To clear a deletion mark, save the changes'; fa = 'To clear a deletion mark, save the changes';
							|it = 'Per rimuovere il contrassegno di eliminazione, è necessario salvare le modifiche apportate';
							|pl = 'Aby usunąć zaznaczenie do usunięcia należy zapisać wprowadzone zmiany';
							|tr = 'Silme işaretini temizlemek için yapılan değişiklikleri kaydetmeniz gerekir'");
			QuestionParametersYesNo.YesButtonText = NStr("vi = 'Ghi lại và bỏ dấu';
														|ru = 'Записать и снять пометку';
														|en = 'Save and clear checkbox'; fa = 'Save and clear checkbox';
														|it = 'Записать и снять пометку';
														|pl = 'Zapisz i usuń zaznaczenie';
														|tr = 'Kaydet ve onay kutusunu temizle'");
		Else
			QueryText = NStr("vi = 'Để đặt dấu xóa, cần ghi lại các thay đổi';
							|ru = 'Для пометки на удаление необходимо записать внесенные изменения';
							|en = 'To set a deletion mark, save the changes'; fa = 'To set a deletion mark, save the changes';
							|it = 'Per impostare il contrassegno di eliminazione, è necessario salvare le modifiche apportate';
							|pl = 'Aby zaznaczyć do usunięcia należy zapisać wprowadzone zmiany';
							|tr = 'Silme işareti için yapılan değişiklikleri kaydetmeniz gerekir'");
			QuestionParametersYesNo.YesButtonText = NStr("vi = 'Ghi lại và đặt dấu';
														|ru = 'Записать и пометить';
														|en = 'Save and mark'; fa = 'Save and mark';
														|it = 'Записать и пометить';
														|pl = 'Zapisz i zaznacz';
														|tr = 'Kaydet ve işaretle'");
		EndIf;
		QuestionParametersYesNo.NoButtonText = NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Отмена';
													|pl = 'Cancel';
													|tr = 'İptal'");
	Else
		If Object.DeletionMark Then
			QueryText = StrTemplate(
				NStr("vi = 'Bỏ dấu xóa ""%1""?';
					|ru = 'Снять с ""%1"" пометку на удаление?';
					|en = 'Do you want to clear the deletion mark from ""%1""?'; fa = 'Do you want to clear the deletion mark from ""%1""?';
					|it = 'Rimuovere il contrassegno per cancellazione da ""%1""?';
					|pl = 'Usunąć z ""%1"" zaznaczenie do usunięcia?';
					|tr = '""%1"" için silme işareti kaldırılsın mı?'"),
				String(Object.Ref));
		Else
			QueryText = StrTemplate(
				NStr("vi = 'Đặt dấu xóa ""%1""?';
					|ru = 'Пометить ""%1"" на удаление?';
					|en = 'Do you want to mark %1 for deletion?'; fa = 'Do you want to mark %1 for deletion?';
					|it = 'Contrassegnare ""%1"" per cancellazione?';
					|pl = 'Zaznaczyć ""%1"" do usunięcia?';
					|tr = '""%1"" silinmek üzere işaretlensin mi?'"),
				String(Object.Ref));
		EndIf;
		QuestionParametersYesNo.YesButtonText = NStr("vi = 'Có';
													|ru = 'Да';
													|en = 'Yes'; fa = 'بله';
													|it = 'Да';
													|pl = 'Tak';
													|tr = 'Evet'");
		QuestionParametersYesNo.NoButtonText = NStr("vi = 'Không';
													|ru = 'Нет';
													|en = 'No'; fa = 'خیر';
													|it = 'Нет';
													|pl = 'Nie';
													|tr = 'Hayır'");
	EndIf;
	
	Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(
		QueryText,
		QuestionParametersYesNo);
	
	If Response = DialogReturnCode.Yes Then
		Object.DeletionMark = Not Object.DeletionMark;
		Write();
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckApplicabilityConditionExpressionWhenUploading(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.ObjectTypeIS) Then
		CommonClient.MessageToUser(
			StrTemplate(NStr("vi = 'Chưa điền trường ""%1""';
							|ru = 'Поле ""%1"" не заполнено';
							|en = '""%1"" is required'; fa = '""%1"" is required';
							|it = 'Il campo ""%1"" non è compilato';
							|pl = 'Pole ""%1"" nie jest wypełnione';
							|tr = '""%1"" alanı doldurulmadı.'"), Items.ObjectTypeIS.Title),,
			"Object.ObjectPresentationIS");
		Return;
	EndIf;
	
	CheckExpressionOfConditionsOfApplicabilityWhenUploadingAtServer();
	
EndProcedure

&AtClient
Procedure CheckApplicabilityConditionExpressionWhenLoading(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.ObjectTypeDM) Then
		CommonClient.MessageToUser(
			StrTemplate(NStr("vi = 'Chưa điền trường ""%1""';
							|ru = 'Поле ""%1"" не заполнено';
							|en = '""%1"" is required'; fa = '""%1"" is required';
							|it = 'Il campo ""%1"" non è compilato';
							|pl = 'Pole ""%1"" nie jest wypełnione';
							|tr = '""%1"" alanı doldurulmadı.'"), Items.ObjectTypeDM.Title),,
			"Object.ObjectPresentationDM");
		Return;
	EndIf;
	
	CheckExpressionOfApplicabilityConditionWhenUploadingAtServer();
	
EndProcedure

#EndRegion

#Region Private

#Region Client

// The handler for the notification "Rules for filling in the requirements for the change to be completed".
//
// Parameters:
//   Result - Structure:
//     * Variant - EnumRef.VariantsOfTheRulesForFillingInAttributes
//     * ComputedExpression - String
//     * AdditionalAttributeDMID - String
//     * AdditionalAttributeDMType - String
//     * AttributeValueIS - Undefined
//     * AttributeNameObjectDM - Undefined
//     * Picture - Number
//     * KeyAttribute_ - Boolean
//     * ShouldUpdate - Boolean
//     * ObjectAttributePresentationDM - Undefined
//     * ModeOfChangingTheDataOfThePostedDocument - EnumRef
//         ModeOfChangingPostedDocumentBy1CDocumentManagementData
//     * IsAdditionalAttributeDM - Boolean
//   CurrentData - FormDataTreeItem:
//     * Variant - EnumRef.VariantsOfTheRulesForFillingInAttributes
//     * ComputedExpression - String
//     * AdditionalAttributeDMID - String
//     * AdditionalAttributeDMType - String
//     * AdditionalAttributeIS - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo
//     * EditingAvailable - Boolean
//     * AttributeValueIS - Undefined
//     * AttributeNameObjectDM - String
//     * AttributeNameObjectIS - String
//     * Picture - Number
//     * KeyAttribute_ - Boolean
//     * ShouldUpdate - Boolean
//     * Explanation - String
//     * ObjectAttributePresentationDM - String
//     * ObjectAttributePresentationIS - String
//     * ModeOfChangingTheDataOfThePostedDocument - EnumRef
//         ModeOfChangingPostedDocumentBy1CDocumentManagementData
//     * Table - String
//     * ObjectAttributeTypeIS - TypeDescription
//     * IsAdditionalAttributeDM - Boolean
//     * IsAdditionalAttributeIS - Boolean
//     * ThisIsTable - Boolean
//
&AtClient
Procedure AttributeFillingRulesISBeforeRowChangeCompletion(Result, CurrentData) Export
	
	If TypeOf(Result) = Type("Structure") Then
		
		FillPropertyValues(CurrentData, Result);
		Modified = True;
		
		If CurrentData.ThisIsTable Then // We will clear the subordinates that have ceased to correspond.
			
			SubordinateRules = CurrentData.GetItems();
			For Each SubordinateRule In SubordinateRules Do
				
				SubordinateRule.ShouldUpdate = CurrentData.ShouldUpdate;
				SubordinateRule.ModeOfChangingTheDataOfThePostedDocument =
					CurrentData.ModeOfChangingTheDataOfThePostedDocument;
				
				If CurrentData.Variant = OptionProps() And SubordinateRule.Variant = OptionProps() Then
					If StrFind(SubordinateRule.AttributeNameObjectDM, ".") <> 0
							And Not StrStartsWith(SubordinateRule.AttributeNameObjectDM, CurrentData.AttributeNameObjectDM) Then
						ClearFillRuleWhenLoading(SubordinateRule);
					EndIf;
					
				ElsIf CurrentData.Variant = TablePropsOption() Then
					If SubordinateRule.Variant = OptionProps()
							And StrFind(SubordinateRule.AttributeNameObjectDM, ".") <> 0 Then
						ClearFillRuleWhenLoading(SubordinateRule);
						
					ElsIf SubordinateRule.Variant = OptionEmpty() Then
						ClearFillRuleWhenLoading(SubordinateRule);
						
					EndIf;
					
				ElsIf CurrentData.Variant = VariantExpression() Then
					ClearFillRuleWhenLoading(SubordinateRule);
					
				ElsIf CurrentData.Variant = OptionEmpty() Then
					ClearFillRuleWhenLoading(SubordinateRule);
					
				ElsIf SubordinateRule.Variant.IsEmpty() Then
					ClearFillRuleWhenLoading(SubordinateRule);
					
				EndIf;
				
				SubordinateRule.EditingAvailable =
					Not (CurrentData.Variant = VariantExpression() Or CurrentData.Variant = OptionEmpty());
				
			EndDo;
			
		EndIf;
		
		Items.AttributeFillingRulesIS.Expand(Items.AttributeFillingRulesIS.CurrentRow);
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure AttributeFillingRulesISBeforeDeleteRowContinued(Val CurrentData)
	
	Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(
		NStr("vi = 'Xóa quy tắc điền mục tin?';
			|ru = 'Очистить правило заполнения реквизита?';
			|en = 'Do you want to clear the attribute filling rule?'; fa = 'Do you want to clear the attribute filling rule?';
			|it = 'Очистить правило заполнения реквизита?';
			|pl = 'Wyczyścić regułę wypełnienia atrybutu?';
			|tr = 'Öznitelik doldurma kuralını temizle?'"),
		IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo(DialogReturnCode.Yes));
	
	If Response = DialogReturnCode.Yes Then
		ClearFillRuleWhenLoading(CurrentData);
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Async Procedure WhenChangingObjectTO(Val LineSuitableRulesForLoadingVDO)
	
	If LineSuitableRulesForLoadingVDO = Undefined Then
		NewPresentationOfObjectBEFORE = "";
		NewObjectTypeDM = "";
		NewDocumentViewBEFORE = "";
		NewDocumentViewBEFOREID = "";
		NewRuleForLoadingVDOData = "";
	Else
		NewPresentationOfObjectBEFORE = LineSuitableRulesForLoadingVDO.VDOLoadingRule;
		NewObjectTypeDM = LineSuitableRulesForLoadingVDO.ObjectTypeDM;
		NewDocumentViewBEFORE = LineSuitableRulesForLoadingVDO.DocumentKindDM;
		NewDocumentViewBEFOREID = LineSuitableRulesForLoadingVDO.DocumentKindDMID;
		NewRuleForLoadingVDOData = LineSuitableRulesForLoadingVDO.VDOLoadingRuleID;
	EndIf;
	
	Object.ObjectPresentationDM = NewPresentationOfObjectBEFORE;
	
	If Object.ObjectTypeDM = NewObjectTypeDM And Object.DocumentKindDMID = NewDocumentViewBEFOREID Then
		Return;
	EndIf;
	
	Object.ObjectTypeDM = NewObjectTypeDM;
	Object.DocumentKindDM = NewDocumentViewBEFORE;
	Object.DocumentKindDMID = NewDocumentViewBEFOREID;
	Object.DMDataLoadingRule = NewRuleForLoadingVDOData;
	
	Modified = True;
	
	DownloadDataFromWorkflow(False);
	
	FillInFromObjectTO = True;
	If ValueIsFilled(Object.ObjectTypeDM) And ValueIsFilled(Object.ObjectPresentationDM) Then
		QueryText = StrTemplate(
			NStr("vi = 'Thiết lập điền các mục tin từ đối tượng ""%1""?';
				|ru = 'Установить заполнение реквизитов из объекта ""%1""?';
				|en = 'Do you want to set attribute filling from the %1 object?'; fa = 'Do you want to set attribute filling from the %1 object?';
				|it = 'Impostare la compilazione di attributi dall''oggetto ""%1""?';
				|pl = 'Ustawić wypełnienie atrybutów z obiektu ""%1""?';
				|tr = '""%1"" nesnesinden öznitelik doldurmanı ayarla?'"),
			Object.ObjectPresentationDM);
		Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(
			QueryText,
			IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo(DialogReturnCode.Yes));
		If Response = DialogReturnCode.No Then
			FillInFromObjectTO = False;
		EndIf;
	Else
		FillInFromObjectTO = False;
	EndIf;
	
	FillInByDefaultOnServer(FillInFromObjectTO);
	
EndProcedure

&AtClient
Procedure WhenChangingIPObject(Name, Synonym)
	
	Object.ObjectPresentationIS = Synonym;
	
	If Object.ObjectTypeIS = Name Then
		Return;
	EndIf;
	
	Object.ObjectTypeIS = Name;
	
	WhenChangingObjectTO(Undefined);
	
	SuitableRulesForLoadingVDO.Clear();
	
	Modified = True;
	FillInDetailsOfConsumer();
	DownloadDataFromWorkflow();
	
	FillInByDefaultOnServer();
	
	SetAvailability();
	
EndProcedure

&AtClient
Async Procedure WhenConnecting()
	
	If ProcessFormAccordingToServiceVersion() Then
		SetAvailability();
		If Not QuestionAsked
				And ValueIsFilled(Object.ObjectTypeDM)
				And ValueIsFilled(Object.ObjectTypeIS)
				And Object.AttributeFillingRulesIS.Count() = 0
				And AttributeFillingRulesIS.GetItems().Count() > 0 Then
			Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(
				NStr("vi = 'Điền quy tắc tích hợp theo mặc định?';
					|ru = 'Заполнить правила интеграции по умолчанию?';
					|en = 'Do you want to populate integration rules by default?'; fa = 'Do you want to populate integration rules by default?';
					|it = 'Заполнить правила интеграции по умолчанию?';
					|pl = 'Wypełnij reguły integracji domyślnie?';
					|tr = 'Entegrasyon kurallarını varsayılan olarak doldur?'"),
				IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo(DialogReturnCode.No));
			If Response = DialogReturnCode.Yes Then
				FillInByDefaultOnServer();
			EndIf;
			QuestionAsked = True;
		EndIf;
	EndIf;
	
EndProcedure

// Checks the connection to the DO by displaying the authorization window, if necessary, and changing the form according to the result.
//
&AtClient
Procedure TestConnection()
	
	CallbackDescription = New CallbackDescription("TestConnectionCompletion", ThisObject);
	IntegrationWith1CDocumentManagementCoreClient.TestConnection(
		CallbackDescription,
		ThisObject,,
		False,
		True);
	
EndProcedure

// It is called after checking the connection to BEFORE and changes the form according to the result.
//
&AtClient
Procedure TestConnectionCompletion(Result, Var_Parameters) Export
	
	If Result = True Then
		WhenConnecting();
	Else // Couldn't connect to BEFORE.
		ProcessFormAccordingToServiceVersion();
	EndIf;
	
EndProcedure

&AtClient
Procedure ConditionOfApplicabilityONChange()
	
	If UseApplicabilityConditionWhenExporting Then
		Items.PagesOfConditionsOfApplicabilityForUploading.CurrentPage =
			Items.PageExpressingConditionsOfApplicabilityWhenUploading;
	Else
		Items.PagesOfConditionsOfApplicabilityForUploading.CurrentPage = Items.KeyIPAttributesPage;
	EndIf;
	Items.CheckApplicabilityConditionExpressionWhenUploading.Visible = UseApplicabilityConditionWhenExporting;
	Items.CommandPanelKeyIPAttributes.Visible = Not UseApplicabilityConditionWhenExporting;
	
	If UseApplicabilityConditionWhenImporting Then
		Items.TermsOfUsePagesWhenLoading.CurrentPage =
			Items.PageExpressingConditionsOfApplicabilityWhenLoading;
	Else
		Items.TermsOfUsePagesWhenLoading.CurrentPage = Items.PageKeyAttributesTO;
	EndIf;
	Items.CheckApplicabilityConditionExpressionWhenLoading.Visible = UseApplicabilityConditionWhenImporting;
	Items.CommandPanelKeyAttributesTO.Visible = Not UseApplicabilityConditionWhenImporting;
	
EndProcedure

&AtClient
Procedure SetAvailability()
	
	Items.ObjectTypeDM.Enabled = ValueIsFilled(Object.ObjectTypeIS);
	Items.FormMarkToDelete.Enabled = ValueIsFilled(Object.Ref);
	
EndProcedure

#EndRegion

#Region ClientServer

// Returns the Enumeration value.Options for the right to fill in the requirements.Expression in a built-in language.
//
&AtClientAtServerNoContext
Function VariantExpression()
	
	Return PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.ScriptExpression");
	
EndFunction

// Returns the value of the variant value().
//
&AtClientAtServerNoContext
Function OptionValue_()
	
	Return PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue");
	
EndFunction

// Returns the value of the Empty() option.
//
&AtClientAtServerNoContext
Function OptionEmpty()
	
	Return PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.EmptyRef");
	
EndFunction

// Returns the Enumeration value.Options for the right to fill in the requirements.The object's props.
//
&AtClientAtServerNoContext
Function OptionProps()
	
	Return PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute");
	
EndFunction

// Returns the Enumeration value.Options for the right to fill in the requirements.Props tables.
//
&AtClientAtServerNoContext
Function TablePropsOption()
	
	Return PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.TableAttribute");
	
EndFunction

&AtClientAtServerNoContext
Procedure ClearFillRuleWhenLoading(Rule)
	
	Rule.ID = "";
	Rule.Picture = 0;
	Rule.ObjectAttributePresentationDM = "";
	Rule.Explanation = "";
	Rule.Variant = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.EmptyRef");
	Rule.ComputedExpression = "";
	Rule.PlaceWhereExpressionIsExecuted = PredefinedValue(
		"Enum.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.EmptyRef");
	Rule.AdditionalAttributeDMID = "";
	Rule.AdditionalAttributeDMType = "";
	Rule.AttributeValueIS = Undefined;
	Rule.AttributeNameObjectDM = "";
	Rule.IsAdditionalAttributeDM = False;
	Rule.ShouldUpdate = False;
	Rule.ModeOfChangingTheDataOfThePostedDocument = PredefinedValue(
		"Enum.ModeOfChangingPostedDocumentBy1CDocumentManagementData.EmptyRef");
	
	Parent = Undefined;
	If TypeOf(Rule) = Type("FormDataTreeItem") Then
		Parent = Rule.GetParent();
	ElsIf TypeOf(Rule) = Type("ValueTreeRow") Then
		Parent = Rule.Parent;
	EndIf;
	
	If Parent <> Undefined
			And (Parent.Variant = VariantExpression() Or Parent.Variant = OptionEmpty()) Then
		Rule.EditingAvailable = False;
	Else
		Rule.EditingAvailable = True;
	EndIf;
	
	If Rule.ThisIsTable Then
		SubordinateRules = Undefined;
		If TypeOf(Rule) = Type("FormDataTreeItem") Then
			SubordinateRules = Rule.GetItems();
		ElsIf TypeOf(Rule) = Type("ValueTreeRow") Then
			SubordinateRules = Rule.Rows;
		EndIf;
		
		If SubordinateRules <> Undefined Then
			For Each SubordinateRule In SubordinateRules Do
				ClearFillRuleWhenLoading(SubordinateRule);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

// Returns True if the loading rule is filled. Subordinate rules are also checked for tables.
//
&AtClientAtServerNoContext
Function LoadingRuleFilled(Rule)
	
	If Rule.ThisIsTable Then
		// This is the table of the IC object.
		If Rule.Variant = OptionProps() And ValueIsFilled(Rule.AttributeNameObjectDM) Then
			// Filled in from the object table BEFORE.
			Return True;
			
		ElsIf Rule.Variant = VariantExpression() And ValueIsFilled(Rule.ComputedExpression) Then
			// Filled in from an expression in the embedded language.
			Return True;
			
		ElsIf Rule.Variant = TablePropsOption() Then
			// Filled in according to the rules for individual Attributes.
			For Each SubordinateRule In Rule.GetItems() Do
				If SubordinateRule.Table = Rule.AttributeNameObjectIS
						And LoadingRuleFilled(SubordinateRule) Then
					Return True;
				EndIf;
			EndDo;
			Return False;
			
		Else
			Return False;
			
		EndIf;
		
	Else
		// This is the Attribute (or Attribute of the table) of the IP object.
		Return ValueIsFilled(Rule.Variant)
			And (ValueIsFilled(Rule.AttributeNameObjectDM)
				Or ValueIsFilled(Rule.AdditionalAttributeDMID)
				Or ValueIsFilled(Rule.AttributeValueIS)
				Or ValueIsFilled(Rule.ComputedExpression));
		
	EndIf;
	
EndFunction

#EndRegion

#Region Server

&AtServer
Procedure AddRulesForFillingIn(FillingRules, NameOfIPAttribute, AttributeNameBefore, ShouldUpdate = True)
	
	If FillingRules.Get(NameOfIPAttribute) <> Undefined Then
		Return;
	EndIf;
	
	LinesOfAttributesUPTO = KeyAttributesDM.FindRows(New Structure("Name", AttributeNameBefore));
	
	If LinesOfAttributesUPTO.Count() = 0 Then
		Return;
	EndIf;
	
	FillingRules.Insert(
		NameOfIPAttribute,
		IntegrationWith1CDocumentManagementCore.RuleForFillingInFromObjectAttributesTO(
			AttributeNameBefore,
			LinesOfAttributesUPTO[0].Presentation,
			ShouldUpdate));
	
EndProcedure

&AtServer
Procedure DownloadDataFromWorkflow(FillInAppropriateRulesForLoadingVDO = True)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	AdditionalRequests = New Array;
	ResponsesToAdditionalRequests = New Array;
	
	If FillInAppropriateRulesForLoadingVDO And ValueIsFilled(Object.ObjectTypeIS) Then
		RequestingRulesForLoadingVDO = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy,
			"DMGetDataLoadingRulesRequest");
		RequestingRulesForLoadingVDO.externalObjectType = Object.ObjectTypeIS;
		AdditionalRequests.Add(RequestingRulesForLoadingVDO);
	EndIf;
	
	Try
		Fill1CDocumentManagementAttributes(AdditionalRequests, ResponsesToAdditionalRequests);
	Except
		Common.MessageToUser(StrTemplate(
			NStr("vi = 'Không thể nhận các mục tin đối tượng 1C:Document Management do nguyên nhân:
				|%1';
				|ru = 'Не удалось получить реквизиты объекта 1С:Документооборот по причине:
				|%1';
				|en = 'Cannot get attributes of the 1C:Document Management object. Reason:
				|%1'; fa = 'Cannot get attributes of the 1C:Document Management object. Reason:
				|%1';
				|it = 'Non è stato possibile ottenere gli attributi dell''oggetto 1C:Document Management a causa di:
				|%1';
				|pl = 'Nie udało się otrzymać atrybutów obiektu 1C:Document Management z powodu:
				|%1';
				|tr = '1C:Document Management nesnesinin öznitelikleri şu nedenle alınamadı:
				|%1'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo())));
		KeyAttributesDM.Clear();
		ObjectAttributesBefore = New FixedArray(New Array);
	EndTry;
	
	For Each Response In ResponsesToAdditionalRequests Do
		If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, Response, "DMGetDataLoadingRulesResponse") Then
			FillInAppropriateRulesForLoadingVDO(Response.dataLoadingRules);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInInstructionsConditionsOfApplicabilityWhenUploading()
	
	ExpressionParameters = Catalogs.RulesForIntegrationWith1CDocumentManagement3.ParametersOfExpressionInEmbeddedLanguage();
	ExpressionParameters.ThisIsConditionOfApplicabilityWhenUnloading = True;
	ExpressionParameters.ObjectTypeIS = Object.ObjectTypeIS;
	InstructionIsConditionOfApplicabilityWhenUnloading = Catalogs.RulesForIntegrationWith1CDocumentManagement3.ExpressionInstruction(
		ExpressionParameters);
	
EndProcedure

&AtServer
Procedure FillInInstructionsConditionsOfApplicabilityWhenDownloading(XDTOAttributes)
	
	ExpressionParameters = Catalogs.RulesForIntegrationWith1CDocumentManagement3.ParametersOfExpressionInEmbeddedLanguage();
	ExpressionParameters.ThisIsConditionOfApplicabilityWhenLoading = True;
	ExpressionParameters.ObjectTypeDM = Object.ObjectTypeDM;
	ExpressionParameters.DocumentKindDMID = Object.DocumentKindDMID;
	InstructionIsConditionOfApplicabilityWhenUploading = Catalogs.RulesForIntegrationWith1CDocumentManagement3.ExpressionInstruction(
		ExpressionParameters,
		XDTOAttributes);
	
EndProcedure

&AtServer
Procedure FillInAppropriateRulesForLoadingVDO(Val RulesForLoadingXDTO = Undefined)
	
	SuitableRulesForLoadingVDO.Clear();
	
	RulesArray = IntegrationWith1CDocumentManagement3ServerCall.SuitableRulesForLoadingVDO(
		Object.ObjectTypeIS,
		RulesForLoadingXDTO);
	For Each Rule In RulesArray Do
		NewRow = SuitableRulesForLoadingVDO.Add();
		FillPropertyValues(NewRow, Rule);
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInByDefaultOnServer(FillInFromObjectTO = True)
	
	RuleTree = FormAttributeToValue("AttributeFillingRulesIS");
	For Each RulesRow In RuleTree.Rows Do
		ClearFillRuleWhenLoading(RulesRow);
	EndDo;
	ValueToFormAttribute(RuleTree, "AttributeFillingRulesIS");
	
	If Not ValueIsFilled(Object.ObjectTypeDM) Or Not FillInFromObjectTO Then
		Return;
	EndIf;
	
	FillingRules = New Map;
	StandardProcessing = True;
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenSettingTheDefaultFillInRuleOnLoading(
		FillingRules,
		Object.ObjectTypeIS,
		Object.ObjectTypeDM,
		StandardProcessing);
	
	IsCatalog = (StrFind(Object.ObjectTypeIS, "Catalog.") > 0);
	IsDocument = (StrFind(Object.ObjectTypeIS, "Document.") > 0);
	
	If StandardProcessing Then
		
		For Each AttributeBefore In KeyAttributesDM Do
			If AttributeBefore.Name = "" Then
				Continue;
			EndIf;
			
			For Each AttributeIS In KeyAttributesIS Do
				If AttributeIS.Name = "" Then
					Continue;
				EndIf;
				
				If AttributeBefore.Presentation = AttributeIS.Presentation Then
					FillingRule =
						IntegrationWith1CDocumentManagementCore.RuleForFillingInFromObjectAttributesTO(
							AttributeBefore.Name,
							AttributeBefore.Presentation);
					FillingRule.IsAdditionalAttributeDM = AttributeBefore.IsAdditionalAttributeDM;
					FillingRules.Insert(AttributeIS.Name, FillingRule);
				EndIf;
			EndDo;
		EndDo;
		
		If IntegrationWith1CDocumentManagement3.IsDocumentBefore3(Object.ObjectTypeDM) Then
			
			AddRulesForFillingIn(FillingRules, "State", "statusApproval");
			AddRulesForFillingIn(FillingRules, "Status", "statusApproval");
			AddRulesForFillingIn(FillingRules, "Approved", "statusApproval");
			AddRulesForFillingIn(FillingRules, "Counterparty", "correspondent");
			AddRulesForFillingIn(FillingRules, "Counterparty", "recipient");
			AddRulesForFillingIn(FillingRules, "Department_Company", "subdivision");
			AddRulesForFillingIn(FillingRules, "Department", "subdivision");
			AddRulesForFillingIn(FillingRules, "Sum", "sum");
			AddRulesForFillingIn(FillingRules, "DocumentAmount", "sum");
			AddRulesForFillingIn(FillingRules, "Currency", "currency");
			AddRulesForFillingIn(FillingRules, "ARAPCurrency", "currency");
			AddRulesForFillingIn(FillingRules, "SettlementsCurrency", "currency");
			AddRulesForFillingIn(FillingRules, "DocumentCurrency", "currency");
			AddRulesForFillingIn(FillingRules, "Prepared", "author");
			AddRulesForFillingIn(FillingRules, "Author", "author");
			AddRulesForFillingIn(FillingRules, "TaskDueDate", "performanceDate");
			AddRulesForFillingIn(FillingRules, "Comment", "comment");
			AddRulesForFillingIn(FillingRules, "StartDate", "beginDate");
			AddRulesForFillingIn(FillingRules, "EndDate", "endDate");
			AddRulesForFillingIn(FillingRules, "Organization", "organization");
			AddRulesForFillingIn(FillingRules, "Content", "summary");
			AddRulesForFillingIn(FillingRules, "RegistrationNumber", "regNumber");
			AddRulesForFillingIn(FillingRules, "RegistrationDate", "regDate");
			AddRulesForFillingIn(FillingRules, "ContactPerson", "contactPerson");
			AddRulesForFillingIn(FillingRules, "EmployeeResponsible", "responsible");
			AddRulesForFillingIn(FillingRules, "Description", "title");
			AddRulesForFillingIn(FillingRules, "IncomingDocumentDate", "externalDate");
			AddRulesForFillingIn(FillingRules, "IncomingDocumentNumber", "externalNumber");
			
		ElsIf Object.ObjectTypeDM = "DMMeeting" Then
			
			AddRulesForFillingIn(FillingRules, "Description", "name");
			AddRulesForFillingIn(FillingRules, "Organization", "organization");
			AddRulesForFillingIn(FillingRules, "LongDesc", "description");
			AddRulesForFillingIn(FillingRules, "Venue", "place");
			AddRulesForFillingIn(FillingRules, "StartDate", "startDate");
			AddRulesForFillingIn(FillingRules, "EndDate", "endDate");
			AddRulesForFillingIn(FillingRules, "Organizer", "calledBy");
			AddRulesForFillingIn(FillingRules, "Secretary", "secretary");
			AddRulesForFillingIn(FillingRules, "Chairman", "chairPerson");
			AddRulesForFillingIn(FillingRules, "Comment", "comment");
			AddRulesForFillingIn(FillingRules, "Project", "project");
			
		ElsIf Object.ObjectTypeDM = "DMCorrespondent" Then
			
			AddRulesForFillingIn(FillingRules, "LegalEntityIndividual", "legalPrivatePerson");
			AddRulesForFillingIn(FillingRules, "Comment", "comment");
			AddRulesForFillingIn(FillingRules, "Description", "name");
			AddRulesForFillingIn(FillingRules, "EmployeeResponsible", "responsible");
			AddRulesForFillingIn(FillingRules, "TIN", "inn");
			AddRulesForFillingIn(FillingRules, "CRTR", "kpp");
			AddRulesForFillingIn(FillingRules, "NCBOCode", "okpo");
			AddRulesForFillingIn(FillingRules, "FullDescr", "fullName");
			AddRulesForFillingIn(FillingRules, "DescriptionFull", "fullName");
			AddRulesForFillingIn(FillingRules, "Individual", "privatePerson");
			AddRulesForFillingIn(FillingRules, "Person", "privatePerson");
			
		EndIf;
		
		If IsCatalog Then
			AddRulesForFillingIn(FillingRules, "Description", "title");
			AddRulesForFillingIn(FillingRules, "Code", "regNumber", False);
			
		ElsIf IsDocument Then
			AddRulesForFillingIn(FillingRules, "Number", "regNumber", False);
			AddRulesForFillingIn(FillingRules, "Date", "regDate", False);
			
		EndIf;
		
	EndIf;
	
	If FillingRules.Count() = 0 Then
		Return;
	EndIf;
	
	RuleTree = FormAttributeToValue("AttributeFillingRulesIS");
	For Each RulesRow In RuleTree.Rows Do
		FillValue = FillingRules.Get(RulesRow.AttributeNameObjectIS);
		If ValueIsFilled(FillValue) Then
			
			RulesRow.Variant = OptionProps();
			RulesRow.ObjectAttributePresentationDM = FillValue.Presentation;
			RulesRow.Picture = 1;
			RulesRow.ShouldUpdate = FillValue.ShouldUpdate;
			RulesRow.IsAdditionalAttributeDM = FillValue.IsAdditionalAttributeDM;
			If IsDocument Then
				RulesRow.ModeOfChangingTheDataOfThePostedDocument =
					Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
			EndIf;
			
			If FillValue.IsAdditionalAttributeDM Then
				RulesRow.AttributeNameObjectDM = "";
				RulesRow.AdditionalAttributeDMID = FillValue.Name;
				RulesRow.AdditionalAttributeDMType = "DMAdditionalProperty";
			Else
				RulesRow.AttributeNameObjectDM = FillValue.Name;
				RulesRow.AdditionalAttributeDMID = "";
				RulesRow.AdditionalAttributeDMType = "";
			EndIf;
			
			Modified = True;
			
		EndIf;
	EndDo;
	ValueToFormAttribute(RuleTree, "AttributeFillingRulesIS");
	
EndProcedure

&AtServer
Procedure Fill1CDocumentManagementAttributes(AdditionalRequests, ResponsesToAdditionalRequests)
	
	AttributesArray = New Array;
	KeyAttributesDM.Clear();
	
	XDTOAttributes = Undefined;
	If ValueIsFilled(Object.ObjectTypeDM) Then
		XDTOAttributes = Catalogs.RulesForIntegrationWith1CDocumentManagement3.ObjectAttributesBefore(
			Object.ObjectTypeDM,
			Object.DocumentKindDMID,
			False,,
			AdditionalRequests,
			ResponsesToAdditionalRequests);
		
		For Each String In XDTOAttributes Do
			
			AttributeData = IntegrationWith1CDocumentManagementCoreClientServer.AttributeData();
			AttributeData.Name = String.Name;
			AttributeData.Type = String.Type;
			AttributeData.Presentation = String.Presentation;
			AttributeData.IsAdditionalAttributeDM = String.AdditionalAttribute5;
			AttributeData.AdditionalAttributeDMID = String.AdditionalAttribute5ID;
			AttributeData.AdditionalAttributeDMType = String.AdditionalAttribute5Type;
			AttributeData.ThisIsTable = String.ThisIsTable;
			AttributeData.Table = String.Table;
			AttributesArray.Add(AttributeData);
			
			If String.ThisIsMainAttribute Then
				
				StringKeyAttributesTO = KeyAttributesDM.Add();
				FillPropertyValues(StringKeyAttributesTO, String);
				
				If String.AdditionalAttribute5 Then
					StringKeyAttributesTO.Name = String.AdditionalAttribute5ID;
					StringKeyAttributesTO.IsAdditionalAttributeDM = True;
					
					KeyAttributesOfObject = Object.KeyAttributesDM.FindRows(
						New Structure("Name, IsAdditionalAttributeDM", String.AdditionalAttribute5ID, True));
					If KeyAttributesOfObject.Count() > 0 Then
						StringKeyAttributesTO.KeyAttribute_ = True;
						FillPropertyValues(StringKeyAttributesTO, KeyAttributesOfObject[0],,"Presentation");
					EndIf;
					
				ElsIf String.Name = "documentType" Then
					StringKeyAttributesTO.KeyAttribute_ = True;
					StringKeyAttributesTO.AttributeValue = Object.DocumentKindDM;
					StringKeyAttributesTO.AttributeValueID = Object.DocumentKindDMID;
					StringKeyAttributesTO.AttributeValueType = "DMDocumentType";
					
				Else
					KeyAttributesOfObject = Object.KeyAttributesDM.FindRows(
						New Structure("Name", String.Name));
					If KeyAttributesOfObject.Count() > 0 Then
						StringKeyAttributesTO.KeyAttribute_ = True;
						FillPropertyValues(StringKeyAttributesTO, KeyAttributesOfObject[0],,"Presentation");
					EndIf;
					
				EndIf;
				
				If Not ValueIsFilled(StringKeyAttributesTO.AttributeValue)
						And StringKeyAttributesTO.Type.Count() > 0 Then
					FirstType = StringKeyAttributesTO.Type[0].Value;
					If FirstType = "Number" Then
						StringKeyAttributesTO.AttributeValue = 0;
						
					ElsIf FirstType = "Date" Then
						StringKeyAttributesTO.AttributeValue = Date(1, 1, 1);
						
					ElsIf FirstType = "Boolean" Then
						StringKeyAttributesTO.AttributeValue = False;
						
					Else // String or reference type BEFORE.
						StringKeyAttributesTO.AttributeValue = "";
						StringKeyAttributesTO.AttributeValueID = "";
						StringKeyAttributesTO.AttributeValueType = "";
						
					EndIf;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		NewRow = KeyAttributesDM.Add();
		NewRow.Presentation = NStr("vi = 'Kiểu đối tượng';
									|ru = 'Тип объекта';
									|en = 'Object type'; fa = 'نوع شیء';
									|it = 'Tipo di oggetto';
									|pl = 'Typ obiektu';
									|tr = 'Nesne türü'");
		NewRow.AttributeValue = IntegrationWith1CDocumentManagement3ClientServer.ObjectTypePresentationXDTO(
			Object.ObjectTypeDM);
		NewRow.KeyAttribute_ = True;
	ElsIf AdditionalRequests.Count() > 0 Then
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		ResponseToPackageRequests = IntegrationWith1CDocumentManagementCore.ExecuteBatchRequest(
			Proxy,
			AdditionalRequests,
			True);
		For Each ResponseToAdditionalRequest In ResponseToPackageRequests.responses Do
			ResponsesToAdditionalRequests.Add(ResponseToAdditionalRequest);
		EndDo;
	EndIf;
	
	ObjectAttributesBefore = New FixedArray(AttributesArray);
	KeyAttributesDM.Sort("KeyAttribute_ DESC, Presentation");
	
	FillInInstructionsConditionsOfApplicabilityWhenDownloading(XDTOAttributes);
	
EndProcedure

&AtServer
Procedure FillInDetailsOfConsumer()
	
	TreeItems = AttributeFillingRulesIS.GetItems();
	TreeItems.Clear();
	
	KeyAttributesIS.Clear();
	
	FillInInstructionsConditionsOfApplicabilityWhenUploading();
	
	If Not ValueIsFilled(Object.ObjectTypeIS) Then
		Return;
	EndIf;
	
	// Let's collect representations of the object's details UP to the tree of their filling.
	ObjectAttributesPresentationDM = New Map;
	For Each Item In ObjectAttributesBefore Do // See IntegrationWith1CDocumentManagementCoreClientServer.AttributeData
		If Item.IsAdditionalAttributeDM Then
			ObjectAttributesPresentationDM[Item.AdditionalAttributeDMID] = Item.Presentation;
		Else
			If ValueIsFilled(Item.Table) Then
				ObjectAttributesPresentationDM[StrTemplate("%1.%2", Item.Table, Item.Name)] =
					Item.Presentation;
			Else
				ObjectAttributesPresentationDM[Item.Name] = Item.Presentation;
			EndIf;
		EndIf;
	EndDo;
	
	Attributes = IntegrationWith1CDocumentManagementCore.ObjectAttributesIS(Object.ObjectTypeIS);
	Attributes.Sort("TableForSorting, ThisIsTable DESC, IsAdditionalAttributeIS, Presentation");
	
	For Each String In Attributes Do
		
		If String.ThisIsTable Then
			NewRow = TreeItems.Add();
			NewRow.ThisIsTable = True;
			TreeLevel = NewRow.GetItems();
		Else
			If String.Table = "" Then
				TreeLevel = TreeItems;
			EndIf;
			NewRow = TreeLevel.Add();
			NewRow.Table = String.Table;
		EndIf;
		
		Parent = NewRow.GetParent();
		If Parent <> Undefined
				And (Parent.Variant = VariantExpression() Or Parent.Variant = OptionEmpty()) Then
			NewRow.EditingAvailable = False;
		Else
			NewRow.EditingAvailable = True;
		EndIf;
		
		NewRow.AttributeNameObjectIS = String.Name;
		NewRow.ObjectAttributePresentationIS = String.Presentation;
		If ValueIsFilled(String.ToolTip) And String.ToolTip <> String.Presentation Then
			NewRow.ToolTip = String.ToolTip;
		EndIf;
		NewRow.ObjectAttributeTypeIS = String.Type;
		NewRow.IsAdditionalAttributeIS = String.IsAdditionalAttributeIS;
		NewRow.AdditionalAttributeIS = String.AdditionalAttributeIS;
		
		FilterParameters = New Structure;
		If String.IsAdditionalAttributeIS Then
			FilterParameters.Insert("AdditionalAttributeIS", String.AdditionalAttributeIS);
		Else
			FilterParameters.Insert("ThisIsTable", String.ThisIsTable);
			FilterParameters.Insert("Table", String.Table);
			FilterParameters.Insert("AttributeNameObjectIS", String.Name);
		EndIf;
		FoundRows = Object.AttributeFillingRulesIS.FindRows(FilterParameters);
		If FoundRows.Count() > 0 Then
			FillPropertyValues(NewRow, FoundRows[0],, "AttributeNameObjectIS");
		EndIf;
		
		NewRow.ObjectAttributePresentationDM = ObjectAttributesPresentationDM[
			?(NewRow.IsAdditionalAttributeDM,
				NewRow.AdditionalAttributeDMID,
				NewRow.AttributeNameObjectDM)];
		
		If NewRow.Variant = TablePropsOption() Then
			NewRow.Explanation = NStr("vi = 'Đang điền theo quy tắc dành cho các mục tin riêng của bảng';
										|ru = 'Заполняется по правилам для отдельных реквизитов таблицы';
										|en = 'Filled in according to the rules of separate table attributes'; fa = 'Filled in according to the rules of separate table attributes';
										|it = 'Viene compilato in base alle regole per gli attributi singoli della tabella';
										|pl = 'Wypełnia się według reguł dla oddzielnych atrybutów tabeli';
										|tr = 'Bireysel tablo öznitelikleri kurallara göre doldurulur'");
		EndIf;
		
		If NewRow.Variant = OptionProps() Then
			NewRow.Picture = 1;
			
		ElsIf NewRow.Variant = TablePropsOption() Then
			NewRow.Picture = 1;
			
		ElsIf NewRow.Variant = OptionValue_() Then
			NewRow.Picture = 2;
			
		ElsIf NewRow.Variant = VariantExpression() Then
			NewRow.Picture = 3;
			
		EndIf;
		
		If Not String.ThisIsTable And String.Table = "" Then
			LineKeyAttributesOfIP = KeyAttributesIS.Add();
			FillPropertyValues(LineKeyAttributesOfIP, String);
			
			KeyAttributesOfObject = Object.KeyAttributesIS.FindRows(
				New Structure("Name", String.Name));
			If KeyAttributesOfObject.Count() > 0 Then
				LineKeyAttributesOfIP.KeyAttribute_ = True;
				FillPropertyValues(LineKeyAttributesOfIP, KeyAttributesOfObject[0],,"Presentation");
			EndIf;
			
			If Not ValueIsFilled(LineKeyAttributesOfIP.AttributeValue) Then
				LineKeyAttributesOfIP.AttributeValue = LineKeyAttributesOfIP.Type.AdjustValue(
					LineKeyAttributesOfIP.AttributeValue);
			EndIf;
		EndIf;
		
	EndDo;
	
	NewRow = KeyAttributesIS.Add();
	NewRow.Presentation = NStr("vi = 'Kiểu đối tượng';
								|ru = 'Тип объекта';
								|en = 'Object type'; fa = 'نوع شیء';
								|it = 'Tipo di oggetto';
								|pl = 'Typ obiektu';
								|tr = 'Nesne türü'");
	NewRow.AttributeValue = StrTemplate("%1, %2",
		Left(Object.ObjectTypeIS, StrFind(Object.ObjectTypeIS, ".") - 1),
		Metadata.FindByFullName(Object.ObjectTypeIS).Synonym);
	NewRow.KeyAttribute_ = True;
	
	KeyAttributesIS.Sort("KeyAttribute_ DESC, Presentation");
	
EndProcedure

&AtServer
Procedure FillConfigurationObjectSelectionList()
	
	Types = IntegrationWith1CDocumentManagementCoreCached.TypesOfObjectsThatSupportIntegration();
	For Each Type In Types Do
		MetadataObject = Metadata.FindByType(Type);
		MetadataList.Add(MetadataObject.FullName(),
			?(MetadataObject.Synonym = "", MetadataObject.Name, MetadataObject.Synonym));
	EndDo;
	
	MetadataList.SortByPresentation();
	
EndProcedure

// Modifies the form according to the availability of the service BEFORE and its version number.
//
&AtServer
Function ProcessFormAccordingToServiceVersion()
	
	ServiceVersion = IntegrationWith1CDocumentManagementCore.ServiceVersion();
	
	If Not IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
		Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsUnavailable;
		Return False;
	EndIf;
	
	FormProcessedSuccessfully = True;
	
	Try
		
		If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("3.0.7.31") Then
			
			Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
			
			FillConfigurationObjectSelectionList();
			DownloadDataFromWorkflow();
			FillInDetailsOfConsumer();
			
			Rows = SuitableRulesForLoadingVDO.FindRows(
				New Structure("VDOLoadingRuleID", Object.DMDataLoadingRule));
			If Rows.Count() = 1 Then
				Object.ObjectPresentationDM = Rows[0].VDOLoadingRule;
				If Object.ObjectTypeDM <> Rows[0].ObjectTypeDM
						Or Object.DocumentKindDM <> Rows[0].DocumentKindDM
						Or Object.DocumentKindDMID <> Rows[0].DocumentKindDMID Then
					Object.ObjectTypeDM = Rows[0].ObjectTypeDM;
					Object.DocumentKindDM = Rows[0].DocumentKindDM;
					Object.DocumentKindDMID = Rows[0].DocumentKindDMID;
					Modified = True;
					DownloadDataFromWorkflow();
				EndIf;
			EndIf;
			
		Else
			
			Items.ConnectionPageGroup.CurrentPage = Items.VersionPageIsNotSupported;
			FormProcessedSuccessfully = False;
			
		EndIf;
		
	Except
		
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo()) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		
	EndTry;
	
	Return FormProcessedSuccessfully;
	
EndFunction

&AtServer
Procedure CheckExpressionOfConditionsOfApplicabilityWhenUploadingAtServer()
	
	Catalogs.RulesForIntegrationWith1CDocumentManagement3.CheckApplicabilityConditionExpressionWhenUploading(
		Object.ApplicabilityConditionOnExport,
		Object.ObjectTypeIS);
	
	Common.MessageToUser(NStr("vi = 'Không tìm thấy lỗi';
								|ru = 'Ошибок не обнаружено';
								|en = 'No errors detected'; fa = 'No errors detected';
								|it = 'Non sono stati rilevati errori';
								|pl = 'Nie wykryto błędów';
								|tr = 'Hatalar algılanmıyor'"));
	
EndProcedure

&AtServer
Procedure CheckExpressionOfApplicabilityConditionWhenUploadingAtServer()
	
	ContextOfExpression = Catalogs.RulesForIntegrationWith1CDocumentManagement3.ContextOfExpressionInEmbeddedLanguage();
	ContextOfExpression.DocumentKindDMID = Object.DocumentKindDMID;
	
	Catalogs.RulesForIntegrationWith1CDocumentManagement3.CheckApplicabilityConditionExpressionWhenLoading(
		Object.ApplicabilityConditionOnImport,
		Object.ObjectTypeDM,
		ContextOfExpression);
	
	Common.MessageToUser(NStr("vi = 'Không tìm thấy lỗi';
								|ru = 'Ошибок не обнаружено';
								|en = 'No errors detected'; fa = 'No errors detected';
								|it = 'Non sono stati rilevati errori';
								|pl = 'Nie wykryto błędów';
								|tr = 'Hatalar algılanmıyor'"));
	
EndProcedure

#EndRegion

#EndRegion