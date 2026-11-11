#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ObjectTypeDM", ObjectTypeDM);
	Parameters.Property("ObjectTypeIS", ObjectTypeIS);
	Parameters.Property("DocumentKindDM", DocumentKindDM);
	Parameters.Property("Variant", Variant);
	Parameters.Property("IsFullUser", IsFullUser);
	Parameters.Property("ObjectAttributePresentationIS", ObjectAttributePresentationIS);
	Parameters.Property("AttributeNameObjectDM", AttributeNameObjectDM);
	Parameters.Property("AttributeNameObjectIS", AttributeNameObjectIS);
	Parameters.Property("ObjectAttributePresentationDM", ObjectAttributePresentationDM);
	Parameters.Property("ComputedExpression", ComputedExpression);
	Parameters.Property("ObjectAttributesBefore", ObjectAttributesBefore);
	Parameters.Property("ShouldUpdate", ShouldUpdate);
	
	ObjectAttribute = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute");
	ScriptExpression =
		PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.ScriptExpression");
	TableAttribute = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.TableAttribute");
	DontFill = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.EmptyRef");
	
	// Let's choose the default option.
	NoTables = True;
	For Each ObjectAttributeBefore In ObjectAttributesBefore Do // See IntegrationWith1CDocumentManagementCoreClientServer.AttributeData
		If ObjectAttributeBefore.ThisIsTable Then
			NoTables = False;
			Break;
		EndIf;
	EndDo;
	If NoTables Then
		Items.GroupOfProps.Visible = False;
		Items.AddGroupFromExpression.Visible = True;
		Items.Variant.ChoiceList.Delete(0);
	EndIf;
	
	AbbreviatedNameOfConfiguration =
		IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	If ValueIsFilled(AbbreviatedNameOfConfiguration) Then
		Title = StrTemplate(NStr("vi = 'Quy tắc điền bảng %1';
								|ru = 'Правило заполнения таблицы %1';
								|en = 'Table filling rule %1'; fa = 'Table filling rule %1';
								|it = 'Regola di compilazione della tabella %1';
								|pl = 'Reguła wypełnienia tabeli %1';
								|tr = 'Tablo doldurma kuralı %1'"), AbbreviatedNameOfConfiguration);
	EndIf;
	
	ExchangeFunctionalityIsAvailable = IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable(
		"1.3.2.3.CORP");
	Items.ShouldUpdate.Visible = ExchangeFunctionalityIsAvailable;
	
	Items.ModeOfChangingTheDataOfThePostedDocument.Visible =
		(Parameters.FillingInDocument And ExchangeFunctionalityIsAvailable);
	If Items.ModeOfChangingTheDataOfThePostedDocument.Visible Then
		Parameters.Property("ModeOfChangingTheDataOfThePostedDocument", ModeOfChangingTheDataOfThePostedDocument);
		If Not ValueIsFilled(ModeOfChangingTheDataOfThePostedDocument) Then
			ModeOfChangingTheDataOfThePostedDocument =
				Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.Prohibited;
		EndIf;
		// We will set the available modes of change in the conducted document.
		Items.ModeOfChangingTheDataOfThePostedDocument.ChoiceList.Add(
			Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting);
		Items.ModeOfChangingTheDataOfThePostedDocument.ChoiceList.Add(
			Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithoutReposting);
		Items.ModeOfChangingTheDataOfThePostedDocument.ChoiceList.Add(
			Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.Prohibited);
		IntegrationWith1CDocumentManagementCoreOverridable.SetModesOfChangeInConductedDocument(
			ObjectTypeIS,
			ObjectAttributePresentationIS,
			Items.ModeOfChangingTheDataOfThePostedDocument.ChoiceList);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetAvailability();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure VariantOnChange(Item)
	
	SetAvailability();
	
EndProcedure

&AtClient
Procedure ObjectAttributePresentationDMStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectThe1CDocumentManagementObjectAttribute();
	
EndProcedure

&AtClient
Procedure ComputedExpressionStartChoice(Item, ChoiceData, StandardProcessing)
	
	SelectCalculatedExpression();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("AttributeNameObjectDM");
	Result.Insert("ObjectAttributePresentationDM");
	Result.Insert("Explanation");
	Result.Insert("ComputedExpression");
	Result.Insert("Picture");
	Result.Insert("ShouldUpdate", ShouldUpdate);
	
	If Variant = ObjectAttribute Then
		Result.AttributeNameObjectDM = AttributeNameObjectDM;
		Result.ObjectAttributePresentationDM = ObjectAttributePresentationDM;
		Result.Picture = 1;
		
	ElsIf Variant = TableAttribute Then
		
		Result.Explanation = NStr("vi = 'Đang điền theo quy tắc dành cho các mục tin riêng của bảng';
									|ru = 'Заполняется по правилам для отдельных реквизитов таблицы';
									|en = 'Filled in according to the rules of separate table attributes'; fa = 'Filled in according to the rules of separate table attributes';
									|it = 'Viene compilato in base alle regole per gli attributi singoli della tabella';
									|pl = 'Wypełnia się według reguł dla oddzielnych atrybutów tabeli';
									|tr = 'Bireysel tablo öznitelikleri kurallara göre doldurulur'");
		Result.Picture = 1;
		
	ElsIf Variant = ScriptExpression Then
		Result.ComputedExpression = ComputedExpression;
		Result.Picture = 3;
		
	EndIf;
	
	Result.Insert("Variant", Variant);
	Result.Insert("ModeOfChangingTheDataOfThePostedDocument", ModeOfChangingTheDataOfThePostedDocument);
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectThe1CDocumentManagementObjectAttribute()
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectTypeDM", ObjectTypeDM);
	FormParameters.Insert("ObjectAttributesBefore", ObjectAttributesBefore);
	FormParameters.Insert("AttributeNameObjectDM", AttributeNameObjectDM);
	FormParameters.Insert("ObjectAttributePresentationIS", ObjectAttributePresentationIS);
	FormParameters.Insert("ThisIsTable", True);
	
	Notification = New CallbackDescription("SelectThe1CDocumentManagementObjectAttributeCompletion", ThisObject);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectAttributeDM",
		FormParameters, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectThe1CDocumentManagementObjectAttributeCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		Result.Property("Name", AttributeNameObjectDM);
		Result.Property("Presentation", ObjectAttributePresentationDM);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectCalculatedExpression()
	
	FormParameters = New Structure;
	FormParameters.Insert("ComputedExpression", ComputedExpression);
	FormParameters.Insert("TypeOfExpression", "LoadingRule");
	FormParameters.Insert("ObjectTypeDM", ObjectTypeDM);
	FormParameters.Insert("ObjectTypeIS", ObjectTypeIS);
	FormParameters.Insert("AttributeNameObjectIS", AttributeNameObjectIS);
	FormParameters.Insert("ThisIsTable", True);
	FormParameters.Insert("DocumentKindDM", DocumentKindDM);
	
	CallbackDescription = New CallbackDescription("SelectCalculatedExpressionCompletion", ThisObject);
	
	OpenForm("Catalog.RulesForIntegrationWith1CDocumentManagement.Form.ScriptExpression",
		FormParameters, ThisObject,,,, CallbackDescription, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure SelectCalculatedExpressionCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("String") Then
		ComputedExpression = Result;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetAvailability()
	
	Items.ObjectAttributePresentationDM.Enabled = (Variant = ObjectAttribute);
	Items.ObjectAttributePresentationDM.AutoMarkIncomplete =
		(Variant = ObjectAttribute);
	Items.ObjectAttributePresentationDM.MarkIncomplete =
		(Variant = ObjectAttribute) And Not ValueIsFilled(ObjectAttributePresentationDM);
	
	Items.ComputedExpression.Enabled = IsFullUser And (Variant = ScriptExpression);
	Items.ComputedExpression.AutoMarkIncomplete = (Variant = ScriptExpression);
	Items.ComputedExpression.MarkIncomplete =
		(Variant = ScriptExpression) And Not ValueIsFilled(ComputedExpression);
	
	Items.ModeOfChangingTheDataOfThePostedDocument.Enabled =
		(Variant = ObjectAttribute)
		Or (Variant = ScriptExpression);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute Then
		CheckedAttributes.Add("ObjectAttributePresentationDM");
		If Parameters.FillingInDocument Then
			CheckedAttributes.Add("ModeOfChangingTheDataOfThePostedDocument");
		EndIf;
		
	ElsIf Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression Then
		CheckedAttributes.Add("ComputedExpression");
		If Parameters.FillingInDocument Then
			CheckedAttributes.Add("ModeOfChangingTheDataOfThePostedDocument");
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion