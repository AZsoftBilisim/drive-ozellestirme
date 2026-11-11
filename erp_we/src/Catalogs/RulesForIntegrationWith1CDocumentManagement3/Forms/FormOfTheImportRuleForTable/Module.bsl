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
	Parameters.Property("PlaceWhereExpressionIsExecuted", PlaceWhereExpressionIsExecuted);
	Parameters.Property("ObjectAttributesBefore", ObjectAttributesBefore);
	Parameters.Property("ShouldUpdate", ShouldUpdate);
	
	If Parameters.Property("ToolTip") And ValueIsFilled(Parameters.ToolTip) Then
		Items.ObjectAttributePresentationIS.ToolTip = Parameters.ToolTip;
		Items.ObjectAttributePresentationIS.ToolTipRepresentation = ToolTipRepresentation.Button;
	EndIf;
	
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
		Items.ObjectAttributePresentationDM.Visible = False;
		Items.Variant.ChoiceList.Delete(Items.Variant.ChoiceList.FindByValue(ObjectAttribute));
	EndIf;
	
	AbbreviatedNameOfConfiguration =
		IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	If ValueIsFilled(AbbreviatedNameOfConfiguration) Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Quy tắc điền bảng %1';
				|ru = 'Правило заполнения таблицы %1';
				|en = 'Table filling rule %1'; fa = 'Table filling rule %1';
				|it = 'Regola di compilazione della tabella %1';
				|pl = 'Reguła wypełnienia tabeli %1';
				|tr = 'Tablo doldurma kuralı %1'"), AbbreviatedNameOfConfiguration);
	EndIf;
	
	Items.ModeOfChangingTheDataOfThePostedDocument.Visible = Parameters.FillingInDocument;
	If Parameters.FillingInDocument Then
		Parameters.Property("ModeOfChangingTheDataOfThePostedDocument", ModeOfChangingTheDataOfThePostedDocument);
		If Not ValueIsFilled(ModeOfChangingTheDataOfThePostedDocument) Then
			ModeOfChangingTheDataOfThePostedDocument =
				Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
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
	
	If PlaceWhereExpressionIsExecuted = Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnDocumentManagementSide Then
		Items.ComputedExpression.ToolTip =
			NStr("vi = 'Biểu thức sẽ được thực hiện trong cơ sở của 1C:Document Management';
				|ru = 'Выражение будет выполняться в базе 1С:Документооборот';
				|en = 'The expression will be executed in 1C:Document Management'; fa = 'The expression will be executed in 1C:Document Management';
				|it = 'Выражение будет выполняться в базе 1С:Документооборот';
				|pl = 'The expression will be executed in 1C:Document Management';
				|tr = 'İfade, 1C:Document Management tabanında yürütülecektir'");
	Else
		Items.ComputedExpression.ToolTip =
			StrTemplate(NStr("vi = 'Biểu thức sẽ được thực hiện trong cơ sở %1';
							|ru = 'Выражение будет выполняться в базе %1';
							|en = 'The expression will be executed in %1'; fa = 'The expression will be executed in %1';
							|it = 'Выражение будет выполняться в базе %1';
							|pl = 'The expression will be executed in %1';
							|tr = 'İfade, %1 tabanında yürütülecektir'"), AbbreviatedNameOfConfiguration);
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
	
	ShouldUpdate = ShouldUpdate And (Variant <> DontFill);
	
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
	Result.Insert("PlaceWhereExpressionIsExecuted");
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
		Result.PlaceWhereExpressionIsExecuted = ?(ValueIsFilled(PlaceWhereExpressionIsExecuted),
			PlaceWhereExpressionIsExecuted,
			PredefinedValue("Enum.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnIntegratedSystemSide"));
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
	FormParameters.Insert("PlaceWhereExpressionIsExecuted", PlaceWhereExpressionIsExecuted);
	FormParameters.Insert("ObjectTypeDM", ObjectTypeDM);
	FormParameters.Insert("ObjectTypeIS", ObjectTypeIS);
	FormParameters.Insert("AttributeNameObjectIS", AttributeNameObjectIS);
	FormParameters.Insert("ThisIsTable", True);
	FormParameters.Insert("DocumentKindDM", DocumentKindDM);
	
	CallbackDescription = New CallbackDescription("SelectCalculatedExpressionCompletion", ThisObject);
	
	OpenForm(
		"Catalog.RulesForIntegrationWith1CDocumentManagement3.Form.ScriptExpression",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure SelectCalculatedExpressionCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ComputedExpression = Result.ComputedExpression;
		PlaceWhereExpressionIsExecuted = Result.PlaceWhereExpressionIsExecuted;
		
		If PlaceWhereExpressionIsExecuted =
				PredefinedValue("Enum.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnDocumentManagementSide") Then
			Items.ComputedExpression.ToolTip =
				NStr("vi = 'Biểu thức sẽ được thực hiện trong cơ sở của 1C:Document Management';
					|ru = 'Выражение будет выполняться в базе 1С:Документооборот';
					|en = 'The expression will be executed in 1C:Document Management'; fa = 'The expression will be executed in 1C:Document Management';
					|it = 'Выражение будет выполняться в базе 1С:Документооборот';
					|pl = 'The expression will be executed in 1C:Document Management';
					|tr = 'İfade, 1C:Document Management tabanında yürütülecektir'");
		Else
			Items.ComputedExpression.ToolTip =
				StrTemplate(NStr("vi = 'Biểu thức sẽ được thực hiện trong cơ sở %1';
								|ru = 'Выражение будет выполняться в базе %1';
								|en = 'The expression will be executed in %1'; fa = 'The expression will be executed in %1';
								|it = 'Выражение будет выполняться в базе %1';
								|pl = 'The expression will be executed in %1';
								|tr = 'İfade, %1 tabanında yürütülecektir'"), AbbreviatedNameOfConfiguration);
		EndIf;
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
	
	Items.ShouldUpdate.Enabled = (Variant <> DontFill);
	Items.ModeOfChangingTheDataOfThePostedDocument.Enabled = Items.ShouldUpdate.Enabled;
	
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