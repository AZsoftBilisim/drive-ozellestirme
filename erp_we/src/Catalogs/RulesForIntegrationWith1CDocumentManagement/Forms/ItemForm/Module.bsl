#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	AbbreviatedNameOfConfiguration = IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	If ValueIsFilled(AbbreviatedNameOfConfiguration) Then
		Items.ObjectTypeIS.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối tượng %1';
				|ru = 'Объект %1';
				|en = 'Object %1'; fa = 'Object %1';
				|it = 'Oggetto %1';
				|pl = 'Obiekt %1';
				|tr = 'Nesne %1'"), AbbreviatedNameOfConfiguration);
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) And ValueIsFilled(Parameters.ObjectTypeIS) Then
		Object.ObjectTypeIS = Parameters.ObjectTypeIS;
		Items.ObjectTypeIS.Enabled = False;
	EndIf;
	
	If ValueIsFilled(Object.ObjectTypeIS) Then
		
		ConsumerObject = Metadata.FindByFullName(Object.ObjectTypeIS);
		If ConsumerObject <> Undefined Then
			ObjectPresentationIS = ?(ConsumerObject.Synonym = "",
				ConsumerObject.Name,
				ConsumerObject.Synonym);
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(Object.ObjectTypeDM) Then
		
		ObjectDocumentManagement = ListOf1CDocumentManagementObjects(True).FindByValue(Object.ObjectTypeDM);
		If ObjectDocumentManagement <> Undefined Then
			ObjectPresentationDM = ObjectDocumentManagement.Presentation;
		EndIf;
		
	EndIf;
	
	Items.ApplicabilityConditionOnExport.Check = Not IsBlankString(Object.ApplicabilityConditionOnExport);
	Items.ApplicabilityConditionOnImport.Check = Not IsBlankString(Object.ApplicabilityConditionOnImport);
	
	IsFullUser = Users.IsFullUser();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TestConnection();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not ValueIsFilled(ObjectPresentationIS) Then
		Cancel = True;
		
		Message = New UserMessage();
		Message.Text = CommonClientServer.FillingErrorText(,, NStr("vi = 'Đối tượng cấu hình';
																	|ru = 'Объект конфигурации';
																	|en = 'Metadata object tree'; fa = 'درخت اشیای فراداده';
																	|it = 'Oggetto di configurazione';
																	|pl = 'Obiekt konfiguracji';
																	|tr = 'Yapılandırma nesnesi'"));
		Message.Field = "ObjectPresentationIS";
		Message.Message();
	EndIf;
	
	If Not ValueIsFilled(ObjectPresentationDM) Then
		Cancel = True;
		
		Message = New UserMessage();
		Message.Text = CommonClientServer.FillingErrorText(,, NStr("vi = 'Đối tượng 1C:Document Management';
																	|ru = 'Объект 1С:Документооборота';
																	|en = '1C:Document Management object'; fa = 'شیء 1C:Document Management';
																	|it = 'Oggetto di 1C:Document Management';
																	|pl = 'Obiekt 1С:Document Management';
																	|tr = '1C:Document Management nesnesi'"));
		Message.Field = "ObjectPresentationDM";
		Message.Message();
	EndIf;
	
	For Each String In AttributeFillingRulesDM.GetItems() Do
		CheckRulesForFillingInDetailsWhenUploading(
			Cancel,
			String.AttributeValueDMType,
			String.AttributeValueDMID,
			String.AttributeValueDM,
			String.FilledInTemplate);
	EndDo;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If ValueIsFilled(Object.ObjectTypeIS) Then
		
		// Verification of filling in the details of the tabular part
		For Each String In AttributeFillingRulesDM.GetItems() Do
			
			If String.Mandatory And Not UploadRuleFilledIn(String, AttributeFillingRulesDM) Then
				ReportError(String);
				Cancel = True;
			EndIf;
			
			If String.ThisIsTable And Not Cancel And Not UploadRuleFilledIn(String, AttributeFillingRulesDM) Then
				For Each SubordinateRow In String.GetItems() Do
					If SubordinateRow.Mandatory
							And Not UploadRuleFilledIn(SubordinateRow, AttributeFillingRulesDM) Then
						
						If SubordinateRow.AttributeNameObjectDM = "correspondent"
								And SubordinateRow.Table = "correspondentRows.rows"
								And CounterpartyDetailsFilledIn() Then
							// We need to check the Counterparty's details, we may be able to take the counterparty from there.
							Continue;
						EndIf;
						
						ReportError(SubordinateRow);
						Cancel = True;
						Break;
					EndIf;
				EndDo;
			EndIf;
			
			If Cancel Then
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Function CounterpartyDetailsFilledIn()
	
	FilledIn_ = True;
	
	For Each String In AttributeFillingRulesDM.GetItems() Do
		If String.AttributeNameObjectDM = "correspondent" And String.Table = "" Then
			FilledIn_ = UploadRuleFilledIn(String, AttributeFillingRulesDM);
			Break;
		EndIf;
	EndDo;
	
	Return FilledIn_;
	
EndFunction

&AtClient
Procedure ReportError(String)
	
	Items.AttributeFillingRulesDM.CurrentRow = String.GetID();
	Items.RulePageGroup.CurrentPage = Items.OnExport;
	Items.GroupPages.CurrentPage = Items.GroupRulesForFillingInBankingDetails;
	
	Message = New UserMessage();
	Message.Text = StrTemplate(
		NStr("vi = 'Chưa đặt quy tắc cho %1 bắt buộc ""%2""';
			|ru = 'Не установлено правило для обязательного %1 ""%2""';
			|en = 'Rule for required %1 ""%2"" not configured'; fa = 'Rule for required %1 ""%2"" not configured';
			|it = 'Regola non impostata per %1 ""%2"" obbligatorio';
			|pl = 'Nie ustawiono reguły dla obowiązkowego %1 ""%2""';
			|tr = 'Gereklilik için kural ayarlanmadı %1 ""%2""'"),
		?(String.ThisIsTable, NStr("vi = 'danh sách';
									|ru = 'списка';
									|en = 'list'; fa = 'list';
									|it = 'dell''elenco';
									|pl = 'list';
									|tr = 'listenin'"), NStr("vi = 'mục tin';
														|ru = 'реквизита';
														|en = 'attribute'; fa = 'attribute';
														|it = 'del requisito';
														|pl = 'attribute';
														|tr = 'özniteliğin'")),
		String.ObjectAttributePresentationDM);
	Message.Message();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("IntegrationWith1CDocumentManagement_RuleRecorded");
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.AttributeFillingRulesDM.Clear();
	For Each Rule In AttributeFillingRulesDM.GetItems() Do
		If UploadRuleFilledIn(Rule, AttributeFillingRulesDM) Then
			NewRule = CurrentObject.AttributeFillingRulesDM.Add();
			FillPropertyValues(NewRule, Rule);
			If Rule.ThisIsTable Then
				For Each SubordinateRule In Rule.GetItems() Do
					If UploadRuleFilledIn(SubordinateRule, AttributeFillingRulesDM) Then
						NewRule = CurrentObject.AttributeFillingRulesDM.Add();
						FillPropertyValues(NewRule, SubordinateRule);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	
	CurrentObject.AttachedPrintedForms.Clear();
	For Each String In AttachedPrintedForms Do
		If String.Use Then
			NewRow = CurrentObject.AttachedPrintedForms.Add();
			FillPropertyValues(NewRow, String);
		EndIf;
	EndDo;
	
	CurrentObject.AttributeFillingRulesIS.Clear();
	For Each Rule In AttributeFillingRulesIS.GetItems() Do
		If LoadingRuleFilled(Rule, AttributeFillingRulesIS) Then
			NewRule = CurrentObject.AttributeFillingRulesIS.Add();
			FillPropertyValues(NewRule, Rule);
			If Rule.ThisIsTable Then
				For Each SubordinateRule In Rule.GetItems() Do
					If LoadingRuleFilled(SubordinateRule, AttributeFillingRulesIS) Then
						NewRule = CurrentObject.AttributeFillingRulesIS.Add();
						FillPropertyValues(NewRule, SubordinateRule);
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	
	Catalogs.RulesForIntegrationWith1CDocumentManagement.ToCheckRule(CurrentObject);
	
EndProcedure

// Returns True if the upload rule is filled in. Subordinate rules are also checked for tables.
//
&AtClientAtServerNoContext
Function UploadRuleFilledIn(Rule, Rules = Undefined)
	
	If Rule.ThisIsTable Then
		If (Rule.Variant = PredefinedValue(
					"Enum.VariantsOfTheRulesForFillingInAttributes.ScriptExpression")
				Or Rule.Variant = PredefinedValue(
					"Enum.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute"))
			And (ValueIsFilled(Rule.AttributeNameObjectIS)
				Or ValueIsFilled(Rule.ComputedExpression)) Then
			Return True;
		Else
			For Each SubordinateRule In Rule.GetItems() Do
				If SubordinateRule.Table = Rule.AttributeNameObjectDM
						And UploadRuleFilledIn(SubordinateRule) Then
					Return True;
				EndIf;
			EndDo;
			Return False;
		EndIf;
	Else // The usual Attributes.
		Return ValueIsFilled(Rule.Variant)
			And (ValueIsFilled(Rule.AttributeNameObjectIS)
				Or ValueIsFilled(Rule.AttributeValueDM)
				Or ValueIsFilled(Rule.ComputedExpression)
				Or Rule.FilledInTemplate);
	EndIf;
	
EndFunction

// Returns True if the loading rule is filled. Subordinate rules are also checked for tables.
//
&AtServer
Function LoadingRuleFilled(Rule, Rules = Undefined)
	
	If Rule.ThisIsTable Then
		If (Rule.Variant = PredefinedValue(
					"Enum.VariantsOfTheRulesForFillingInAttributes.ScriptExpression")
				Or Rule.Variant = PredefinedValue(
					"Enum.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute"))
			And (ValueIsFilled(Rule.AttributeNameObjectDM)
				Or ValueIsFilled(Rule.ComputedExpression)) Then
			Return True;
		Else
			For Each SubordinateRule In Rule.GetItems() Do
				If SubordinateRule.Table = Rule.AttributeNameObjectIS
						And LoadingRuleFilled(SubordinateRule) Then
					Return True;
				EndIf;
			EndDo;
			Return False;
		EndIf;
	Else // The usual Attributes.
		Return ValueIsFilled(Rule.Variant)
			And (ValueIsFilled(Rule.AttributeNameObjectDM)
				Or ValueIsFilled(Rule.AdditionalAttributeDMID)
				Or ValueIsFilled(Rule.AttributeValueIS)
				Or ValueIsFilled(Rule.ComputedExpression));
	EndIf;
	
EndFunction

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
Procedure ObjectTypeISStartChoice(Item, ChoiceData, StandardProcessing)
	
	Notification = New CallbackDescription("ObjectTypeISStartChoiceCompletion", ThisObject);
	
	IntegrationWith1CDocumentManagementCoreClient.ObjectTypeISStartChoice(
		Object.ObjectTypeIS,
		Notification);
	
EndProcedure

&AtClient
Procedure ObjectTypeISStartChoiceCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		Object.ObjectTypeIS = Result.Name;
		ObjectPresentationIS = Result.Synonym;
		Modified = True;
		FillInByDefaultWhenUploadingToServer_(True)
	EndIf;
	
EndProcedure

&AtClient
Procedure ObjectTypeISTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	
	For Each ChoiceItem In MetadataList Do
		If Find(Upper(ChoiceItem.Presentation), Upper(Text)) <> 0 Then
			ChoiceData.Add(ChoiceItem.Value, ChoiceItem.Presentation);
		EndIf;
	EndDo;
	
	If ChoiceData.Count() = 1 Then
		ObjectPresentationIS = ChoiceData[0].Presentation;
		Object.ObjectTypeIS = ChoiceData[0].Value;
		StandardProcessing = True;
		Modified = True;
		FillPrintFormsList();
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
Procedure ObjectTypeISChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected <> Undefined Then
		StandardProcessing = False;
		SelectedElement = MetadataList.FindByValue(ValueSelected);
		ObjectPresentationIS = SelectedElement.Presentation;
		Object.ObjectTypeIS = SelectedElement.Value;
		Modified = True;
		FillInConsumerObjectData();
	EndIf;
	
EndProcedure

&AtClient
Procedure ObjectTypeDMStartChoice(Item, ChoiceData, StandardProcessing)
	
	InitialObjectTypeDM = Object.ObjectTypeDM;
	ChoiceList = ListOf1CDocumentManagementObjects(CounterpartiesFunctionalityIsAvailable);
	
	Notification = New CallbackDescription("ObjectTypeDMStartChoiceCompletion",
		ThisObject, InitialObjectTypeDM);
	
	ShowChooseFromList(Notification, ChoiceList, Item);
	
EndProcedure

&AtClient
Procedure ObjectTypeDMStartChoiceCompletion(ValueSelected, InitialObjectTypeDM) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	Object.ObjectTypeDM = ValueSelected.Value;
	ObjectPresentationDM = ValueSelected.Presentation;
	
	If InitialObjectTypeDM <> Object.ObjectTypeDM Then
		Object.AttributeFillingRulesDM.Clear();
		FillInByDefaultWhenUploadingToServer(True);
		Modified = True;
	EndIf;
	
	SetAvailability();
	
EndProcedure

&AtClient
Procedure ObjectTypeDMAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	ChoiceList = ListOf1CDocumentManagementObjects(CounterpartiesFunctionalityIsAvailable);
	
	For Each ChoiceItem In ChoiceList Do
		If Find(Upper(ChoiceItem.Presentation), Upper(Text)) <> 0 Then
			ChoiceData.Add(ChoiceItem.Value, ChoiceItem.Presentation);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure ObjectTypeDMTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	ChoiceList = ListOf1CDocumentManagementObjects(CounterpartiesFunctionalityIsAvailable);
	InitialObjectTypeDM = Object.ObjectTypeDM;
	
	For Each ChoiceItem In ChoiceList Do
		If Find(Upper(ChoiceItem.Presentation), Upper(Text)) <> 0 Then
			ChoiceData.Add(ChoiceItem.Value, ChoiceItem.Presentation);
		EndIf;
	EndDo;
	
	If ChoiceData.Count() = 1 Then
		
		ValueSelected = ChoiceData[0];
		
		Object.ObjectTypeDM = ValueSelected.Value;
		ObjectPresentationDM = ValueSelected.Presentation;
		
		If InitialObjectTypeDM <> Object.ObjectTypeDM Then
			Object.AttributeFillingRulesDM.Clear();
			FillInByDefaultWhenUploadingToServer(True);
			Modified = True;
		EndIf;
		StandardProcessing = True;
	EndIf;
		
	SetAvailability();
	
EndProcedure

&AtClient
Procedure ObjectTypeDMChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	InitialObjectTypeDM = Object.ObjectTypeDM;
	
	If ValueSelected <> Undefined Then
		
		StandardProcessing = False;
		SelectedElement = ListOf1CDocumentManagementObjects(CounterpartiesFunctionalityIsAvailable).FindByValue(ValueSelected);
		Object.ObjectTypeDM = SelectedElement.Value;
		ObjectPresentationDM = SelectedElement.Presentation;
		If InitialObjectTypeDM <> Object.ObjectTypeDM Then
			Object.AttributeFillingRulesDM.Clear();
			FillInByDefaultWhenUploadingToServer(True);
			Modified = True;
		EndIf;
		
	EndIf;
	
	SetAvailability();
	
EndProcedure

&AtClient
Procedure TemplateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure;
	FormParameters.Insert("TypeOfSelectionObject", Object.ObjectTypeDM + "Template");
	If ValueIsFilled(Object.TemplateID) Then
		FormParameters.Insert("SelectedElement", Object.TemplateID);
	EndIf;
	Notification = New CallbackDescription("TemplateCompletionOfSelection", ThisObject, Undefined);
	Try
		OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFromList",
			FormParameters,
			ThisObject,,,,
			Notification,
			FormWindowOpeningMode.LockOwnerWindow);
	Except
		ErrorInfo = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
	EndTry;
	
EndProcedure

&AtClient
Procedure TemplateCompletionOfSelection(Result, Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Object.Template = Result.AttributePresentation;
	Object.TemplateType = Result.AttributeType;
	Object.TemplateID = Result.AttributeID;
	
	UpdateTemplateDetails();
	
EndProcedure

&AtClient
Procedure TemplateClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	Object.Template = "";
	Object.TemplateType = "";
	Object.TemplateID = "";
	
	For Each Item In AttributeFillingRulesDM.GetItems() Do
		If Item.Variant = OptionTemplate() Then
			ClearUploadFillRule(Item);
		EndIf;
	EndDo;
	
	UpdateTemplateDetails();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttributeFillingRulesDM

&AtClient
Procedure AttributeFillingRulesDMBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure AttributeFillingRulesDMBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	CurrentData = Items.AttributeFillingRulesDM.CurrentData;
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
	FormParameters.Insert("AttributeNameObjectDM");
	FormParameters.Insert("ObjectAttributePresentationDM");
	FormParameters.Insert("ObjectAttributeTypeDM");
	FormParameters.Insert("Variant");
	FormParameters.Insert("AttributeNameObjectIS");
	FormParameters.Insert("AttributeValueDM");
	FormParameters.Insert("AttributeValueDMID");
	FormParameters.Insert("AttributeValueDMType");
	FormParameters.Insert("ComputedExpression");
	FormParameters.Insert("IsAdditionalAttributeIS");
	FormParameters.Insert("AdditionalAttributeIS");
	FormParameters.Insert("AdditionalAttributeDMID");
	FormParameters.Insert("AdditionalAttributeDMType");
	FormParameters.Insert("ShouldUpdate");
	FormParameters.Insert("KeyAttribute_");
	FormParameters.Insert("FilledInTemplate");
	FormParameters.Insert("TemplateMeaning");
	FormParameters.Insert("TemplateID");
	FormParameters.Insert("TemplateType");
	
	FillPropertyValues(FormParameters, CurrentData);
	
	Parent = CurrentData.GetParent();
	FormParameters.Insert("DependentItem", (Parent <> Undefined));
	FormParameters.Insert("UpdateParent", ?(Parent <> Undefined, Parent.ShouldUpdate, Undefined));
	
	If ValueIsFilled(CurrentData.Table) Then
		If Parent.Variant = OptionProps() Then
			FormParameters.Insert("Table", Parent.AttributeNameObjectIS);
		Else
			FormParameters.Insert("Table", "");
		EndIf;
	EndIf;
	
	FormParameters.Insert("ObjectTypeDM", Object.ObjectTypeDM);
	FormParameters.Insert("ObjectTypeIS", Object.ObjectTypeIS);
	FormParameters.Insert("TemplateForbidModification", Object.TemplateForbidModification);
	FormParameters.Insert("DocumentKindDM", DocumentKindDM);
	
	Notification = New CallbackDescription(
		"AttributeFillingRulesDMBeforeRowChangeCompletion",
		ThisObject,
		CurrentData);
	
	FormParameters.Insert("IsFullUser", IsFullUser);
	
	If CurrentData.ThisIsTable Then
		OpenedForm = "Catalog.RulesForIntegrationWith1CDocumentManagement.Form.FormOfTheExportRuleForTable";
	Else
		OpenedForm = "Catalog.RulesForIntegrationWith1CDocumentManagement.Form.FormOfTheExportRule";
	EndIf;
	
	OpenForm(OpenedForm,
		FormParameters,
		ThisObject,
		FormParameters.AttributeNameObjectDM,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AttributeFillingRulesDMBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	CurrentData = Items.AttributeFillingRulesDM.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Object.TemplateForbidModification And CurrentData.FilledInTemplate Then
		ShowMessageBox(, NStr("vi = 'Khuôn mẫu đã chọn cấm thay đổi mục tin.';
								|ru = 'Выбранный шаблон запрещает изменение реквизитов.';
								|en = 'The template you selected does not permit editing attributes.'; fa = 'The template you selected does not permit editing attributes.';
								|it = 'Il modello selezionato impedisce la modifica degli attributi.';
								|pl = 'Wybrany szablon zabrania zmiany atrybutów.';
								|tr = 'Seçili numune, özniteliklerin değiştirilmesini yasaklıyor.'"));
		Return;
	EndIf;
	
	If CurrentData.AttributeNameObjectDM = "documentType" And CurrentData.FilledInTemplate Then
		ShowMessageBox(, NStr("vi = 'Dạng chứng từ được chọn trong khuôn mẫu và không thể thay đổi.';
								|ru = 'Вид документа указан в шаблоне и не может быть изменен.';
								|en = 'Document kind is specified in the template and cannot be changed.'; fa = 'Document kind is specified in the template and cannot be changed.';
								|it = 'Il tipo di documento indicato nel modello non può essere modificato.';
								|pl = 'Rodzaj dokumentu jest podany w szablonie i nie może być zmieniony.';
								|tr = 'Belge türü numunede belirtildi ve değiştirilemez.'"));
		Return;
	EndIf;
	
	AttributeFillingRulesDMBeforeDeleteRowContinued(CurrentData);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttachedPrintedForms

&AtClient
Procedure AttachedPrintedFormsUseOnChange(Item)
	
	UpdateTitleOfPrintedForms();
	
	Items.AttachedPrintedForms.CurrentData.ShouldUpdate =
		Items.AttachedPrintedForms.CurrentData.Use
		And SynchronizationFunctionalityIsAvailable;
	
EndProcedure

&AtClient
Procedure AttachedPrintedFormsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure AttachedPrintedFormsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
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
	
	ObjectAttributesBefore = New Array;
	For Each String In AttributeFillingRulesDM.GetItems() Do
		
		AttributeData = IntegrationWith1CDocumentManagementCoreClientServer.AttributeData();
		AttributeData.Name = String.AttributeNameObjectDM;
		AttributeData.Type = String.ObjectAttributeTypeDM;
		AttributeData.Presentation = String.ObjectAttributePresentationDM;
		AttributeData.IsAdditionalAttributeDM = String.IsAdditionalAttributeDM;
		AttributeData.AdditionalAttributeDMID = String.AdditionalAttributeDMID;
		AttributeData.AdditionalAttributeDMType = String.AdditionalAttributeDMType;
		AttributeData.ThisIsTable = String.ThisIsTable;
		AttributeData.Table = String.Table;
		ObjectAttributesBefore.Add(AttributeData);
		
		If String.ThisIsTable Then
			For Each SubordinateRow In String.GetItems() Do
				AttributeData = IntegrationWith1CDocumentManagementCoreClientServer.AttributeData();
				AttributeData.Name = SubordinateRow.AttributeNameObjectDM;
				AttributeData.Type = SubordinateRow.ObjectAttributeTypeDM;
				AttributeData.Presentation = SubordinateRow.ObjectAttributePresentationDM;
				AttributeData.IsAdditionalAttributeDM = SubordinateRow.IsAdditionalAttributeDM;
				AttributeData.AdditionalAttributeDMID = SubordinateRow.AdditionalAttributeDMID;
				AttributeData.AdditionalAttributeDMType = SubordinateRow.AdditionalAttributeDMType;
				AttributeData.ThisIsTable = SubordinateRow.ThisIsTable;
				AttributeData.Table = SubordinateRow.Table;
				ObjectAttributesBefore.Add(AttributeData);
			EndDo;
		EndIf;
		
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("Variant");
	FormParameters.Insert("ObjectAttributePresentationIS");
	FormParameters.Insert("ObjectAttributeTypeIS");
	FormParameters.Insert("AttributeNameObjectDM");
	FormParameters.Insert("AttributeNameObjectIS");
	FormParameters.Insert("ObjectAttributePresentationDM");
	FormParameters.Insert("AttributeValueIS");
	FormParameters.Insert("ComputedExpression");
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
	
	FormParameters.Insert("ObjectAttributesBefore", New FixedArray(ObjectAttributesBefore));
	FormParameters.Insert("ObjectTypeIS", Object.ObjectTypeIS);
	FormParameters.Insert("ObjectTypeDM", Object.ObjectTypeDM);
	FormParameters.Insert("DocumentKindDM", DocumentKindDM);
	
	FillingInDocument = StrStartsWith(Object.ObjectTypeIS, "Document.");
	FormParameters.Insert("FillingInDocument", FillingInDocument);
	
	FormParameters.Insert("IsFullUser", IsFullUser);
	
	If CurrentData.ThisIsTable Then
		OpenedForm = "Catalog.RulesForIntegrationWith1CDocumentManagement.Form.FormOfTheImportRuleForTable"
	Else
		OpenedForm = "Catalog.RulesForIntegrationWith1CDocumentManagement.Form.FormOfTheImportRule"
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
Async Procedure FillInByDefaultWhenUploading(Val Command)
	
	NeedToAskQuestion_ = False;
	
	For Each String In AttributeFillingRulesDM.GetItems() Do
		If ValueIsFilled(String.ComputedExpression)
				Or ValueIsFilled(String.AttributeValueDMID)
				Or ValueIsFilled(String.AttributeNameObjectIS) Then
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
			FillInByDefaultWhenUploadingToServer();
		EndIf;
	Else
		FillInByDefaultWhenUploadingToServer();
	EndIf;
	
EndProcedure

&AtClient
Async Procedure DefaultFillWhenLoading(Val Command)
	
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
			FillInByDefaultWhenUploadingToServer_();
		EndIf;
	Else
		FillInByDefaultWhenUploadingToServer_();
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicabilityConditionOnImport(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ComputedExpression", Object.ApplicabilityConditionOnImport);
	FormParameters.Insert("TypeOfExpression", "ApplicabilityConditionOnImport");
	FormParameters.Insert("ObjectTypeDM", Object.ObjectTypeDM);
	FormParameters.Insert("ObjectTypeIS", Object.ObjectTypeIS);
	
	CallbackDescription = New CallbackDescription("ApplicabilityConditionOnImportCompletion", ThisObject);
	
	OpenForm("Catalog.RulesForIntegrationWith1CDocumentManagement.Form.ScriptExpression",
		FormParameters, ThisObject,,,, CallbackDescription, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure ApplicabilityConditionOnImportCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("String") Then
		Object.ApplicabilityConditionOnImport = Result;
		Items.ApplicabilityConditionOnImport.Check =
			Not IsBlankString(Object.ApplicabilityConditionOnImport);
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicabilityConditionOnExport(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ComputedExpression", Object.ApplicabilityConditionOnExport);
	FormParameters.Insert("TypeOfExpression", "ApplicabilityConditionOnExport");
	FormParameters.Insert("ObjectTypeDM", Object.ObjectTypeDM);
	FormParameters.Insert("ObjectTypeIS", Object.ObjectTypeIS);
	
	CallbackDescription = New CallbackDescription("ApplicabilityConditionOnExportCompletion", ThisObject);
	
	OpenForm("Catalog.RulesForIntegrationWith1CDocumentManagement.Form.ScriptExpression",
		FormParameters, ThisObject,,,, CallbackDescription, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure ApplicabilityConditionOnExportCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("String") Then
		Object.ApplicabilityConditionOnExport = Result;
		Items.ApplicabilityConditionOnExport.Check =
			Not IsBlankString(Object.ApplicabilityConditionOnExport);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

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
Procedure WhenConnecting()
	
	If ProcessFormAccordingToServiceVersion() Then
		SetAvailability();
		UpdateTitleOfPrintedForms();
	EndIf;
	
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
		
		Items.ConnectionPageGroup.CurrentPage = Items.Page1CDocumentManagementIsAvailable;
		
		If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("3.0.1.1") Then
			
			DataProcessors.IntegrationWith1CDocumentManagement.ProcessFormIfServiceVersionFunctionalityIsUnavailable(ThisObject);
			Items.GroupCommandBar.Visible = False;
			Items.ObjectTypesGroup.Visible = False;
			Items.GroupIndent.Visible = False;
			
		Else
			
			Items.FunctionalityGroupIsNotSupported.Visible = False;
			Items.GroupCommandBar.Visible = True;
			Items.ObjectTypesGroup.Visible = True;
			Items.GroupIndent.Visible = True;
			
			SynchronizationFunctionalityIsAvailable =
				IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP");
			CounterpartiesFunctionalityIsAvailable =
				IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("1.3.2.3", True);
			AvailableFunctionalityTemplates =
				IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("2.0.8.1", True);
			FunctionalityOfAutomaticCreationOfLinksIsAvailable =
				IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("2.1.0.1", True);
			
			If Not SynchronizationFunctionalityIsAvailable Then
				Items.AttributeFillingRulesUpdate.Visible = False;
				Items.AttachedPrintedFormsShouldUpdate.Visible = False;
				Items.AttributeFillingRulesISShouldUpdate.Visible = False;
			EndIf;
			
			If Not AvailableFunctionalityTemplates Then
				Items.Template.Visible = False;
			ElsIf Object.ObjectTypeDM = "DMCorrespondent" Then
				Items.Template.Enabled = False;
			EndIf;
			
			Items.DoNotCreateRelationsByLinks.Visible = FunctionalityOfAutomaticCreationOfLinksIsAvailable;
			
			FillConfigurationObjectSelectionList();
			Fill1CDocumentManagementAttributes();
			FillPrintFormsList();
			FillInDetailsOfConsumer();
			
		EndIf;
		
	Except
		
		If IntegrationWith1CDocumentManagementCoreServerCall.NeedToProcessForm(ErrorInfo()) Then
			ProcessFormAccordingToServiceVersion();
		EndIf;
		
	EndTry;
	
	Return FormProcessedSuccessfully;
	
EndFunction

// The handler of the alert "Rules for filling in the requirements before the change is completed".
//
// Parameters:
//   Result - Structure:
//     * Variant - EnumRef.VariantsOfTheRulesForFillingInAttributes
//     * ComputedExpression - String
//     * AdditionalAttributeIS - Undefined
//     * AttributeValueDM - Undefined
//     * AttributeValueDMID - Undefined
//     * AttributeValueDMType - Undefined
//     * AttributeNameObjectIS - Undefined
//     * Picture - Number
//     * KeyAttribute_ - Boolean
//     * ShouldUpdate - Boolean
//     * TemplatePresentation - Undefined
//     * IsAdditionalAttributeIS - Boolean
//   CurrentData - FormDataTreeItem:
//     * Variant - EnumRef.VariantsOfTheRulesForFillingInAttributes
//     * ComputedExpression - String
//     * AdditionalAttributeDMID - String
//     * AdditionalAttributeDMType - String
//     * AdditionalAttributeIS - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo
//     * EditingAvailable - Boolean
//     * FilledInTemplate - Boolean
//     * AttributeValueDM - Undefined
//     * AttributeValueDMID - String
//     * AttributeValueDMType - String
//     * AttributeNameObjectDM - String
//     * AttributeNameObjectIS - String
//     * Picture - Number
//     * KeyAttribute_ - Boolean
//     * ShouldUpdate - Boolean
//     * Mandatory - Boolean
//     * Explanation - String
//     * Presentation - String
//     * ObjectAttributePresentationDM - String
//     * Table - String
//     * ObjectAttributeTypeDM - ValueList
//     * TemplateID - String
//     * TemplateMeaning - Undefined
//     * TemplatePresentation - String
//     * TemplateType - String
//     * IsAdditionalAttributeDM - Boolean
//     * IsAdditionalAttributeIS - Boolean
//     * ThisIsTable - Boolean
//
&AtClient
Procedure AttributeFillingRulesDMBeforeRowChangeCompletion(Result, CurrentData) Export
	
	If TypeOf(Result) = Type("Structure") Then
		
		FillPropertyValues(CurrentData, Result);
		Modified = True;
		
		If CurrentData.AttributeNameObjectDM = "documentType" Then
			
			If (CurrentData.Variant = OptionValue_()
					And ValueIsFilled(CurrentData.AttributeValueDMID))
				Or (CurrentData.Variant = OptionTemplate()
					And ValueIsFilled(CurrentData.TemplateID)) Then
				
				FillInRulesWhenUploadingItem(Object, AttributeFillingRulesDM);
				Fill1CDocumentManagementAttributes();
				
			EndIf;
			
		EndIf;
		
		If CurrentData.ThisIsTable Then // We will clear the subordinates that have ceased to correspond.
			SubordinateRules = CurrentData.GetItems();
			
			For Each SubordinateRule In SubordinateRules Do
				
				SubordinateRule.ShouldUpdate = CurrentData.ShouldUpdate;
				If CurrentData.Variant = OptionProps() Then
					If SubordinateRule.Variant = OptionProps()
							And StrFind(SubordinateRule.AttributeNameObjectIS, ".") <> 0
							And Not StrStartsWith(SubordinateRule.AttributeNameObjectIS,
								CurrentData.AttributeNameObjectIS) Then
						ClearUploadFillRule(SubordinateRule);
						
					ElsIf SubordinateRule.Variant = OptionEmpty() Then
						ClearUploadFillRule(SubordinateRule);
						
					EndIf;
					
				ElsIf CurrentData.Variant = TablePropsOption() Then
					If SubordinateRule.Variant = OptionProps()
							And StrFind(SubordinateRule.AttributeNameObjectIS, ".") <> 0 Then
						ClearUploadFillRule(SubordinateRule);
						
					ElsIf SubordinateRule.Variant = OptionEmpty() Then
						ClearUploadFillRule(SubordinateRule);
						
					EndIf;
					
				Else
					ClearUploadFillRule(SubordinateRule);
					
				EndIf;
				
				SubordinateRule.EditingAvailable =
					Not (CurrentData.Variant = VariantExpression() Or CurrentData.Variant = OptionEmpty());
				
			EndDo;
			
			Items.AttributeFillingRulesDM.Expand(CurrentData.GetID());
		EndIf;
		
	EndIf;
	
EndProcedure

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
Async Procedure AttributeFillingRulesDMBeforeDeleteRowContinued(Val CurrentData)
	
	Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(
		NStr("vi = 'Xóa quy tắc điền?';
			|ru = 'Очистить правило заполнения?';
			|en = 'Clear the autofill rule?'; fa = 'Clear the autofill rule?';
			|it = 'Очистить правило заполнения?';
			|pl = 'Wyczyścić regułę wypełnienia?';
			|tr = 'Dolgu kuralı silinsin mi?'"),
		IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo(DialogReturnCode.Yes));
	
	If Response = DialogReturnCode.Yes Then
		ClearUploadFillRule(CurrentData);
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Async Procedure AttributeFillingRulesISBeforeDeleteRowContinued(Val CurrentData)
	
	Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(
		NStr("vi = 'Xóa quy tắc điền mục tin?';
			|ru = 'Очистить правило заполнения реквизита?';
			|en = 'Clear the attribute autofill rule?'; fa = 'Clear the attribute autofill rule?';
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
Procedure SetAvailability()
	
	Items.FillByDefault.Enabled = ValueIsFilled(Object.ObjectTypeDM);
	Items.Template.Enabled = ValueIsFilled(Object.ObjectTypeDM) And (Object.ObjectTypeDM <> "DMCorrespondent");
	Items.ApplicabilityConditionOnExport.Enabled = IsFullUser;
	Items.ApplicabilityConditionOnImport.Enabled = IsFullUser;
	
EndProcedure

&AtServer
Procedure FillPrintFormsList()
	
	If Not ValueIsFilled(Object.TypeOfSavedPrintedFormFile) Then
		Object.TypeOfSavedPrintedFormFile =
			IntegrationWith1CDocumentManagementCore.DefaultFileTypeOfSavedPrintedForm();
	EndIf;
	
	If ValueIsFilled(Object.ObjectTypeIS) Then
		
		Items.AttachedPrintedForms.Enabled = True;
		
		AttachedPrintedForms.Clear();
		
		TableOfPrintedForms = IntegrationWith1CDocumentManagementCore.PrintManagers(Object.ObjectTypeIS);
		
		For Each StructureOfPrintedForm In TableOfPrintedForms Do
			NewRow = AttachedPrintedForms.Add();
			FillPropertyValues(NewRow, StructureOfPrintedForm);
			
			SavedData = Undefined;
			LinesOfPrintedForm = Object.AttachedPrintedForms.FindRows(
				New Structure("CommandName, PrintManager, AdditionalParameters",
					NewRow.CommandName,
					NewRow.PrintManager,
					NewRow.AdditionalParameters));
			If LinesOfPrintedForm.Count() > 0 Then
				SavedData = LinesOfPrintedForm[0];
			Else
				LinesOfPrintedForm = Object.AttachedPrintedForms.FindRows(
					New Structure("CommandName, PrintManager, AdditionalParameters",
						NewRow.CommandName,
						NewRow.PrintManager,
						""));
				If LinesOfPrintedForm.Count() > 0 Then
					SavedData = LinesOfPrintedForm[0];
				EndIf;
			EndIf;
			
			If SavedData <> Undefined Then
				NewRow.Use = True;
				NewRow.ShouldUpdate = SavedData.ShouldUpdate;
			EndIf;
		EndDo;
		
	EndIf;
	
	Items.GroupAttachablePrintedForms.Visible = (AttachedPrintedForms.Count() <> 0);
	Items.GroupPages.PagesRepresentation =
		?(AttachedPrintedForms.Count() <> 0,
			FormPagesRepresentation.TabsOnTop,
			FormPagesRepresentation.None);
	
EndProcedure

&AtClientAtServerNoContext
Function ListOf1CDocumentManagementObjects(Counterparties)
	
	List = New ValueList;
	
	List.Add("DMIncomingDocument");
	List.Add("DMOutgoingDocument");
	List.Add("DMInternalDocument");
	If Counterparties Then
		List.Add("DMCorrespondent");
	EndIf;
	
	For Each Item In List Do
		Item.Presentation = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(Item.Value);
	EndDo;
	
	Return List;
	
EndFunction

&AtServer
Procedure Fill1CDocumentManagementAttributes(WhenSelectingTemplate = False)
	
	If Not ValueIsFilled(Object.ObjectTypeDM) Then
		AttributeFillingRulesDM.GetItems().Clear();
		
	Else
		
		If DocumentKindDM = Undefined Then
			DocumentKindDM = Catalogs.RulesForIntegrationWith1CDocumentManagement.DocumentViewFromRule(Object);
		EndIf;
		
		TemplateAttributes = Catalogs.RulesForIntegrationWith1CDocumentManagement.GetDocumentTemplateDetails(
			Object.TemplateType,
			Object.TemplateID,
			Object.TemplateForbidModification);
		If TemplateAttributes = Undefined Then
			Object.Template = "";
			Object.TemplateType = "";
			Object.TemplateID = "";
			
			For Each Item In AttributeFillingRulesDM.GetItems() Do
				If Item.Variant = OptionTemplate() Then
					ClearUploadFillRule(Item);
				EndIf;
			EndDo;
			
			Modified = True;
			
		Else
			LinesDocumentView = TemplateAttributes.FindRows(New Structure("AttributeNameObjectDM", "documentType"));
			If LinesDocumentView.Count() = 1 Then
				DocumentKindDM = New Structure("ID, type, name",
					LinesDocumentView[0].TemplateID,
					LinesDocumentView[0].TemplateType,
					LinesDocumentView[0].TemplateMeaning);
			EndIf;
			
		EndIf;
		
		FillParameters = Undefined;
		If DocumentKindDM <> Undefined Then
			FillParameters = New Structure;
			FillParameters.Insert("documentType", DocumentKindDM);
		EndIf;
		
		Attributes = Catalogs.RulesForIntegrationWith1CDocumentManagement.ObjectAttributesBefore(
			Object.ObjectTypeDM,
			FillParameters);
		
		TreeItems = AttributeFillingRulesDM.GetItems();
		TreeItems.Clear();
		
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
			
			NewRow.AttributeNameObjectDM = String.Name;
			NewRow.ObjectAttributePresentationDM = String.Presentation;
			NewRow.ObjectAttributeTypeDM = String.Type;
			NewRow.IsAdditionalAttributeDM = String.AdditionalAttribute5;
			NewRow.AdditionalAttributeDMID = String.AdditionalAttribute5ID;
			NewRow.AdditionalAttributeDMType = String.AdditionalAttribute5Type;
			NewRow.Mandatory = String.Mandatory;
			
			If String.Name = "documentType" Then
				NewRow.KeyAttribute_ = True;
			EndIf;
			
			// Let's find the appropriate row in the table part.
			FilterStructure1 = New Structure("IsAdditionalAttributeDM", String.AdditionalAttribute5);
			If String.AdditionalAttribute5 Then
				FilterStructure1.Insert("AdditionalAttributeDMID", String.AdditionalAttribute5ID);
			Else
				FilterStructure1.Insert("ThisIsTable", String.ThisIsTable);
				FilterStructure1.Insert("Table", String.Table);
				FilterStructure1.Insert("AttributeNameObjectDM", String.Name);
			EndIf;
			FoundRows = Object.AttributeFillingRulesDM.FindRows(FilterStructure1);
			
			If FoundRows.Count() > 0 Then
				FillPropertyValues(NewRow, FoundRows[0],, "AttributeNameObjectDM");
			EndIf;
			
			// We will find a suitable line among the filled in template details.
			If TemplateAttributes <> Undefined Then
				
				FoundRows = TemplateAttributes.FindRows(FilterStructure1);
				If FoundRows.Count() > 0 Then // Filled in the template.
					
					NewRow.FilledInTemplate = True;
					NewRow.TemplateMeaning = FoundRows[0].TemplateMeaning;
					NewRow.TemplateID = FoundRows[0].TemplateID;
					NewRow.TemplateType = FoundRows[0].TemplateType;
					NewRow.TemplatePresentation = NewRow.TemplateMeaning;
					NewRow.ShouldUpdate = NewRow.ShouldUpdate And Not Object.TemplateForbidModification;
					
					If WhenSelectingTemplate And NewRow.Variant <> OptionTemplate() Then
						
						NewRow.Variant = OptionTemplate();
						NewRow.Picture = 5;
						NewRow.AttributeValueDM = Undefined;
						NewRow.AttributeValueDMID = Undefined;
						NewRow.AttributeNameObjectIS = Undefined;
						
					Else
						
						If NewRow.Variant = OptionValue_() Then // Let's warn you about the conflict.
							
							If (ValueIsFilled(NewRow.AttributeValueDMID)
									And (NewRow.AttributeValueDMID <> NewRow.TemplateID))
									Or (Not ValueIsFilled(NewRow.AttributeValueDMID)
									And (NewRow.AttributeValueDM <> NewRow.TemplateMeaning)) Then
								
								NewRow.Picture = 4;
								NewRow.TemplatePresentation = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'khuôn mẫu: %1';
										|ru = 'шаблон: %1';
										|en = 'template: %1'; fa = 'template: %1';
										|it = 'modello: %1';
										|pl = 'szablon: %1';
										|tr = 'numune: %1'"),
									NewRow.TemplateMeaning);
								
							Else
								
								NewRow.TemplatePresentation = "";
								
							EndIf;
							
						ElsIf Not ValueIsFilled(NewRow.Variant) Then
							
							NewRow.Variant = OptionTemplate();
							
						ElsIf NewRow.Variant <> OptionTemplate() Then
							
							NewRow.TemplatePresentation = "";
							
						EndIf;
						
					EndIf;
					
				ElsIf NewRow.Variant = OptionTemplate() Then
					
					NewRow.Variant = OptionEmpty();
					NewRow.FilledInTemplate = False;
					NewRow.TemplatePresentation = "";
					
				EndIf;
				
			ElsIf NewRow.Variant = OptionTemplate() Then
				
				NewRow.Variant = OptionEmpty();
				NewRow.FilledInTemplate = False;
				NewRow.TemplatePresentation = "";
				
			EndIf;
			
			If NewRow.Variant = TablePropsOption() Then
				NewRow.Explanation = NStr("vi = 'Đang điền theo quy tắc dành cho các mục tin riêng của bảng';
											|ru = 'Заполняется по правилам для отдельных реквизитов таблицы';
											|en = 'Filled in according to the rules of separate table attributes'; fa = 'Filled in according to the rules of separate table attributes';
											|it = 'Viene compilato in base alle regole per gli attributi singoli della tabella';
											|pl = 'Wypełnia się według reguł dla oddzielnych atrybutów tabeli';
											|tr = 'Bireysel tablo öznitelikleri kurallara göre doldurulur'");
			EndIf;
			
			// We will install the image according to the option, if it was not installed earlier.
			If Not ValueIsFilled(NewRow.Picture) Then
				If NewRow.Variant = OptionProps() Then
					NewRow.Picture = 1;
					
				ElsIf NewRow.Variant = TablePropsOption() Then
					NewRow.Picture = 1;
					
				ElsIf NewRow.Variant = OptionValue_() Then
					NewRow.Picture = 2;
					
				ElsIf NewRow.Variant = VariantExpression() Then
					NewRow.Picture = 3;
					
				ElsIf NewRow.Variant = OptionTemplate() Then
					NewRow.Picture = 5;
					
				EndIf;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateTemplateDetails()
	
	FillInRulesWhenUploadingItem(Object, AttributeFillingRulesDM);
	Fill1CDocumentManagementAttributes(True);
	
EndProcedure

&AtServer
Procedure FillInDetailsOfConsumer()
	
	TreeItems = AttributeFillingRulesIS.GetItems();
	TreeItems.Clear();
	
	If Not ValueIsFilled(Object.ObjectTypeIS) Then
		Return;
	EndIf;
	
	// Let's collect representations of the object's details UP to the tree of their filling.
	ObjectAttributesPresentationDM = New Map;
	For Each Item1 In AttributeFillingRulesDM.GetItems() Do
		If Item1.IsAdditionalAttributeDM Then
			ObjectAttributesPresentationDM[Item1.AdditionalAttributeDMID] =
				Item1.ObjectAttributePresentationDM;
		Else
			ObjectAttributesPresentationDM[Item1.AttributeNameObjectDM] =
				Item1.ObjectAttributePresentationDM;
		EndIf;
		For Each Item2 In Item1.GetItems() Do
			ObjectAttributesPresentationDM[Item2.Table + "." + Item2.AttributeNameObjectDM] =
				Item2.ObjectAttributePresentationDM;
		EndDo;
	EndDo;
	States1 = Catalogs.RulesForIntegrationWith1CDocumentManagement.PossibleStatesOfThe1CDocumentManagementObject();
	For Each State In States1 Do
		ObjectAttributesPresentationDM[State.Name] = State.Presentation;
	EndDo;
	
	Attributes = IntegrationWith1CDocumentManagementCore.ObjectAttributesIS(Object.ObjectTypeIS);
	
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
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInRulesWhenUploadingItem(Object, AttributeFillingRulesDM)
	
	Object.AttributeFillingRulesDM.Clear();
	TreeItems = AttributeFillingRulesDM.GetItems();
	
	For Each TreeItem In TreeItems Do
		
		If TreeItem.ThisIsTable Then
			NewRow = Object.AttributeFillingRulesDM.Add();
			FillPropertyValues(NewRow, TreeItem);
			SubordinateRules = TreeItem.GetItems();
			
			For Each SubordinateRule In SubordinateRules Do
				If UploadRuleFilledIn(SubordinateRule) Then
					NewRow = Object.AttributeFillingRulesDM.Add();
					FillPropertyValues(NewRow, SubordinateRule);
				EndIf;
			EndDo;
			
		ElsIf UploadRuleFilledIn(TreeItem) Then
			NewRow = Object.AttributeFillingRulesDM.Add();
			FillPropertyValues(NewRow, TreeItem);
			
		EndIf;
		
	EndDo;
	
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

&AtServer
Procedure FillInByDefaultWhenUploadingToServer(InitialFilling = False)
	
	// We will reset the template if its type does not match the object type
	If Object.TemplateType <> "" And StrFind(Object.TemplateType, Object.ObjectTypeDM) = 0 Then
		Object.Template = "";
		Object.TemplateID = "";
		Object.TemplateType = "";
		Object.TemplateForbidModification = False;
		
		For Each Item In AttributeFillingRulesDM.GetItems() Do
			If Item.Variant = OptionTemplate() Then
				ClearUploadFillRule(Item);
			EndIf;
		EndDo;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	FillInRulesWhenUploadingItem(Object, AttributeFillingRulesDM);
	DocumentKindDM = Catalogs.RulesForIntegrationWith1CDocumentManagement.DocumentViewFromRule(Object);
	
	If DocumentKindDM = Undefined
			And (Object.ObjectTypeDM = "DMIncomingDocument"
				Or Object.ObjectTypeDM = "DMInternalDocument"
				Or Object.ObjectTypeDM = "DMOutgoingDocument") Then
		// Let's define the default document type
		ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
		FilterConditions = ListOfConditions.conditions; // XDTOList
		
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "name";
		Condition.value = ObjectPresentationIS;
		FilterConditions.Add(Condition);
		
		Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
			Proxy,
			Object.ObjectTypeDM + "Type",
			ListOfConditions);
		
		If Result.items.Count() = 1 Then
			ElementToFillIn = Result.items[0].object;
			DocumentKindDM = New Structure("ID, type, name",
				ElementToFillIn.objectID.ID,
				ElementToFillIn.objectID.type,
				ElementToFillIn.name);
			InitialFilling = True;
		EndIf;
	EndIf;
	
	If InitialFilling Then
		Fill1CDocumentManagementAttributes();
		FillInByDefaultWhenUploadingToServer_(InitialFilling);
	EndIf;
	
	TreeOfUploadRules = FormAttributeToValue("AttributeFillingRulesDM");
	
	// Filling in the document type and details by default.
	DocumentViewStrings = TreeOfUploadRules.Rows.FindRows(
		New Structure("AttributeNameObjectDM", "documentType"));
	If DocumentViewStrings.Count() > 0 Then
		RulesRow = DocumentViewStrings[0];
		
		If DocumentKindDM <> Undefined
				And Not ValueIsFilled(RulesRow.AttributeValueDMType)
				And Not ValueIsFilled(RulesRow.TemplateType) Then
			RulesRow.Variant = OptionValue_();
			RulesRow.AttributeValueDM = DocumentKindDM.name;
			RulesRow.AttributeValueDMID = DocumentKindDM.ID;
			RulesRow.AttributeValueDMType = DocumentKindDM.type;
			RulesRow.Picture = 2;
		EndIf;
		
		If DocumentKindDM <> Undefined And CounterpartiesFunctionalityIsAvailable Then
			
			RequestingBankingDetailsValues = IntegrationWith1CDocumentManagementCore.CreateObject(
				Proxy,
				"DMGetDefaultValuesByDocumentTypeRequest");
			XDTOKind = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				DocumentKindDM.ID,
				DocumentKindDM.type);
			RequestingBankingDetailsValues.documentTypeID = XDTOKind;
			Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(
				Proxy,
				RequestingBankingDetailsValues);
			IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
			ObjectProperties = Response.object.Properties();
			
			For Each RulesRow In TreeOfUploadRules.Rows Do
				
				If ValueIsFilled(RulesRow.AttributeNameObjectDM)
						And ObjectProperties.Get(RulesRow.AttributeNameObjectDM) <> Undefined
						And Not RulesRow.FilledInTemplate Then
					
					CurrentProperty = Response.object[RulesRow.AttributeNameObjectDM];
					If CurrentProperty <> Undefined Then
						RulesRow.Variant = OptionValue_();
						RulesRow.Picture = 2;
						
						If TypeOf(CurrentProperty) = Type("String")
								Or TypeOf(CurrentProperty) = Type("Number")
								Or TypeOf(CurrentProperty) = Type("Date")
								Or TypeOf(CurrentProperty) = Type("Boolean") Then
							RulesRow.AttributeValueDM = CurrentProperty;
							
						Else
							RulesRow.Variant = OptionValue_();
							RulesRow.AttributeValueDM = CurrentProperty.name;
							RulesRow.AttributeValueDMID = CurrentProperty.objectID.ID;
							RulesRow.AttributeValueDMType = CurrentProperty.objectID.type;
							
						EndIf;
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		Modified = True;
	EndIf;
	
	// Filling in the default rules
	FillingRules = New Map;
	
	If StrFind(Object.ObjectTypeIS, "Catalog.") <> 0 Then
		SourceMetadata = Metadata.FindByFullName(Object.ObjectTypeIS);
		If SourceMetadata <> Undefined Then
			If SourceMetadata.DescriptionLength <> 0 Then
				FillingRules.Insert("title", "Description");
				FillingRules.Insert("name", "Description");
			EndIf;
		EndIf;
		
	ElsIf StrFind(Object.ObjectTypeIS, "Document.") <> 0 Then
		SourceMetadata = Metadata.FindByFullName(Object.ObjectTypeIS);
		If SourceMetadata <> Undefined Then
			FillingRules.Insert("title", "Presentation");
		EndIf;
		
	EndIf;
	
	IntegrationWith1CDocumentManagement.SetDefaultFillingRulesForUploading(
		FillingRules,
		Object.ObjectTypeDM,
		Object.ObjectTypeIS);
	
	For Each RulesRow In TreeOfUploadRules.Rows Do
		FillValue = FillingRules.Get(RulesRow.AttributeNameObjectDM);
		If ValueIsFilled(FillValue) And Not RulesRow.FilledInTemplate Then
			ClearUploadFillRule(RulesRow);
			RulesRow.Variant = OptionProps();
			RulesRow.AttributeNameObjectIS = FillValue;
			RulesRow.ShouldUpdate = SynchronizationFunctionalityIsAvailable;
			RulesRow.Picture = 1;
			Modified = True;
		EndIf;
	EndDo;
	
	// Filling in the access bar
	AccessFingerboardStrings = TreeOfUploadRules.Rows.FindRows(
		New Structure("AttributeNameObjectDM", "accessLevel"));
	
	If AccessFingerboardStrings.Count() > 0
			And Not ValueIsFilled(AccessFingerboardStrings[0].AttributeValueDM)
			And Not AccessFingerboardStrings[0].FilledInTemplate Then
		RulesRow = AccessFingerboardStrings[0];
		
		ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
		Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
			Proxy,
			"DMAccessLevel",
			ListOfConditions);
		
		If Result.items.Count() = 1 Then
			ElementToFillIn = Result.items[0].object;
			ClearUploadFillRule(RulesRow);
			RulesRow.Variant = OptionValue_();
			RulesRow.AttributeValueDM = ElementToFillIn.name;
			RulesRow.AttributeValueDMID = ElementToFillIn.objectID.ID;
			RulesRow.AttributeValueDMType = ElementToFillIn.objectID.type;
			RulesRow.Picture = 2;
			Modified = True;
		EndIf;
	EndIf;
	
	ValueToFormAttribute(TreeOfUploadRules, "AttributeFillingRulesDM");
	FillInRulesWhenUploadingItem(Object, AttributeFillingRulesDM);
	
EndProcedure

&AtServer
Procedure FillInByDefaultWhenUploadingToServer_(InitialFilling = False)
	
	If InitialFilling Then
		FillInDetailsOfConsumer();
		FillPrintFormsList();
	EndIf;
	
	If Not ValueIsFilled(Object.ObjectTypeDM) Then
		Return;
	EndIf;
	
	IsCatalog = (Find(Object.ObjectTypeIS, "Catalog.") > 0);
	IsDocument = (Find(Object.ObjectTypeIS, "Document.") > 0);
	
	// Filling in the default rules.
	FillingRules = New Map;
	
	If IsCatalog Then
		FillingRules.Insert(
			"Description",
			IntegrationWith1CDocumentManagementCore.RuleForFillingInFromObjectAttributesTO("title"));
		FillingRules.Insert(
			"Code",
			IntegrationWith1CDocumentManagementCore.RuleForFillingInFromObjectAttributesTO(
				"regNumber",
				"",
				False));
	ElsIf IsDocument Then
		FillingRules.Insert(
			"Number",
			IntegrationWith1CDocumentManagementCore.RuleForFillingInFromObjectAttributesTO(
				"regNumber",
				"",
				False));
		FillingRules.Insert(
			"Date",
			IntegrationWith1CDocumentManagementCore.RuleForFillingInFromObjectAttributesTO(
				"regDate",
				"",
				False));
	EndIf;
	
	IntegrationWith1CDocumentManagement.SetDefaultFillInRulesWhenLoading(
		FillingRules,
		Object.ObjectTypeIS,
		Object.ObjectTypeDM);
	
	StateStructure = New Map;
	StateStructure.Insert("statusRegistration", NStr("vi = 'Trạng thái đăng ký';
													|ru = 'Состояние регистрации';
													|en = 'Registration state'; fa = 'Registration state';
													|it = 'Stato registrazione';
													|pl = 'Status rejestracji';
													|tr = 'Kayıt durumu'"));
	StateStructure.Insert("statusConsideration", NStr("vi = 'Trạng thái xem xét';
														|ru = 'Состояние рассмотрения';
														|en = 'Review state'; fa = 'Review state';
														|it = 'Stato valutazione';
														|pl = 'Status rozpatrzenia';
														|tr = 'Değerlendirme durumu'"));
	StateStructure.Insert("statusApproval", NStr("vi = 'Trạng thái thống nhất';
												|ru = 'Состояние согласования';
												|en = 'Approval state '; fa = 'وضعیت تأیید';
												|it = 'Stato omologazione';
												|pl = 'Status uzgodnienia';
												|tr = 'Onay durumu'"));
	StateStructure.Insert("statusConfirmation", NStr("vi = 'Trạng thái phê duyệt';
													|ru = 'Состояние утверждения';
													|en = 'Confirmation state'; fa = 'Confirmation state';
													|it = 'Stato conferma';
													|pl = 'Status zatwierdzenia';
													|tr = 'Onay durumu'"));
	StateStructure.Insert("statusPerformance", NStr("vi = 'Trạng thái thực hiện';
													|ru = 'Состояние исполнения';
													|en = 'Execution state'; fa = 'Execution state';
													|it = 'Stato esecuzione';
													|pl = 'Status wykonania';
													|tr = 'Yürütme durumu'"));
	
	TreeOfUploadRules = FormAttributeToValue("AttributeFillingRulesDM");
	LoadingRulesTree = FormAttributeToValue("AttributeFillingRulesIS");
	
	For Each RulesRow In LoadingRulesTree.Rows Do
		
		ClearFillRuleWhenLoading(RulesRow);
		
		FillValue = FillingRules.Get(RulesRow.AttributeNameObjectIS);
		If ValueIsFilled(FillValue) Then
			
			Filter = New Structure;
			Filter.Insert("AttributeNameObjectDM", FillValue.Name);
			StringsOfProps = TreeOfUploadRules.Rows.FindRows(Filter);
			
			If StringsOfProps.Count() > 0 Then
				RulesRow.ObjectAttributePresentationDM = StringsOfProps[0].ObjectAttributePresentationDM;
			Else
				RulesRow.ObjectAttributePresentationDM = StateStructure[FillValue.Name];
			EndIf;
			
			If ValueIsFilled(RulesRow.ObjectAttributePresentationDM) Then
				RulesRow.Variant = OptionProps();
				RulesRow.AttributeNameObjectDM = FillValue.Name;
				RulesRow.Picture = 1;
				RulesRow.ShouldUpdate = FillValue.ShouldUpdate;
				If IsDocument Then
					RulesRow.ModeOfChangingTheDataOfThePostedDocument =
						Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
				EndIf;
				Modified = True;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ValueToFormAttribute(LoadingRulesTree, "AttributeFillingRulesIS");
	
EndProcedure

&AtClientAtServerNoContext
Procedure ClearUploadFillRule(Rule)
	
	Rule.Picture = 0;
	Rule.Explanation = "";
	Rule.Variant = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.EmptyRef");
	Rule.ComputedExpression = "";
	Rule.AttributeValueDM = Undefined;
	Rule.AttributeValueDMID = "";
	Rule.AttributeValueDMType = "";
	Rule.AttributeNameObjectIS = "";
	Rule.IsAdditionalAttributeIS = False;
	Rule.KeyAttribute_ = False;
	Rule.ShouldUpdate = False;
	Rule.TemplateID = "";
	Rule.TemplateType = "";
	Rule.TemplatePresentation = "";
	
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
				ClearUploadFillRule(SubordinateRule);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ClearFillRuleWhenLoading(Rule)
	
	Rule.Picture = 0;
	Rule.ObjectAttributePresentationDM = "";
	Rule.Explanation = "";
	Rule.Variant = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.EmptyRef");
	Rule.ComputedExpression = "";
	Rule.AdditionalAttributeDMID = "";
	Rule.AdditionalAttributeDMType = "";
	Rule.AttributeValueIS = Undefined;
	Rule.AttributeNameObjectDM = "";
	Rule.IsAdditionalAttributeDM = False;
	Rule.KeyAttribute_ = False;
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

&AtServer
Procedure FillInConsumerObjectData()

	FillInDetailsOfConsumer();
	FillPrintFormsList();

EndProcedure // Fill in the data of the consumer's object()

&AtClient
Procedure UpdateTitleOfPrintedForms()
	
	Count = 0;
	For Each FormString In AttachedPrintedForms Do
		Count = Count + ?(FormString.Use, 1, 0);
	EndDo;
	
	BookmarkTitle = NStr("vi = 'Thêm mẫu in';
						|ru = 'Добавление печатных форм';
						|en = 'Add print forms'; fa = 'افزودن فرم‌های چاپی';
						|it = 'Aggiunta forme di stampa';
						|pl = 'Dodawanie formularzy wydruku';
						|tr = 'Yazdırma formu ekleme'");
	If Count > 0 Then
		BookmarkTitle = StrTemplate("%1 (%2)", BookmarkTitle, Count);
	EndIf;
	Items.GroupAttachablePrintedForms.Title = BookmarkTitle;
	
EndProcedure

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

// Returns the value of the variant value().
//
&AtClientAtServerNoContext
Function OptionValue_()
	Return PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue");
EndFunction

// Returns the Enumeration value.Options for the right to fill in the requirements.Expression in a built-in language.
//
&AtClientAtServerNoContext
Function VariantExpression()
	Return PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.ScriptExpression");
EndFunction

// Returns the value of the Variant Pattern().
//
&AtClientAtServerNoContext
Function OptionTemplate()
	Return PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.FromTemplate");
EndFunction

// Returns the value of the Empty() option.
//
&AtClientAtServerNoContext
Function OptionEmpty()
	Return PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.EmptyRef");
EndFunction

&AtServer
Procedure CheckRulesForFillingInDetailsWhenUploading(Cancel, AttributeValueType, IDOfPropsValue,
	ValueOfAttribute1CDocumentManagement, FilledInTemplate)
	
	If Not FilledInTemplate
			And (AttributeValueType = "DMInternalDocumentType"
				Or AttributeValueType = "DMIncomingDocumentType"
				Or AttributeValueType = "DMOutgoingDocumentType") Then
		
		DocumentKind = IntegrationWith1CDocumentManagementCore.GetObject(
			IntegrationWith1CDocumentManagementCoreCached.GetProxy(),
			AttributeValueType,
			IDOfPropsValue);
		If IntegrationWith1CDocumentManagementCore.PropertySet(DocumentKind, "templateRequired")
				And DocumentKind.templateRequired
				And Object.TemplateID = "" Then
			
			Cancel = True;
			Message = New UserMessage();
			Message.Text = StrTemplate(
				NStr("vi = 'Trong tùy chỉnh dạng văn bản ""%1"" có đặt cấm tạo mới văn bản không theo khuôn mẫu,
							|nhưng chưa chọn khuôn mẫu văn bản.';
							|ru = 'В настройках вида документа ""%1"" установлен запрет на создание документов не по шаблону,
							|но шаблон документа не выбран.';
							|en = 'The prohibition on creating documents not based on the template is set in the settings for the document kind ""%1"",
							|but the document template is not selected.'; fa = 'The prohibition on creating documents not based on the template is set in the settings for the document kind ""%1"",
							|but the document template is not selected.';
							|it = 'Nelle impostazioni del tipo di documento ""%1"" è impostata una restrizione di creazione di documenti se non per modello,
							|ma non è stato selezionato il modello del documento.';
							|pl = 'W ustawieniach rodzaju dokumentu ""%1"" jest ustawiony zakaz utworzenia dokumentów bez szablonu,
							|ale szablon dokumentu nie jest wybrany.';
							|tr = '""%1"" belge türü ayarı, numune olmayan belgelerin oluşturulmasını engelleyecek şekilde ayarlandı,
							|ancak hiçbir belge numunesi seçilmedi.'"),
				ValueOfAttribute1CDocumentManagement);
			Message.Field = "Object.Template";
			Message.Message();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion