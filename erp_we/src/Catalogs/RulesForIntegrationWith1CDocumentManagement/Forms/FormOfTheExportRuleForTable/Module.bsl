#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("AttributeNameObjectDM", AttributeNameObjectDM);
	Parameters.Property("ObjectAttributePresentationDM", ObjectAttributePresentationDM);
	Parameters.Property("Variant", Variant);
	Parameters.Property("IsFullUser", IsFullUser);
	Parameters.Property("AttributeNameObjectIS", AttributeNameObjectIS);
	Parameters.Property("ComputedExpression", ComputedExpression);
	Parameters.Property("ObjectTypeDM", ObjectTypeDM);
	Parameters.Property("ObjectTypeIS", ObjectTypeIS);
	Parameters.Property("ShouldUpdate", ShouldUpdate);
	Parameters.Property("DocumentKindDM", DocumentKindDM);
	
	ObjectAttribute = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute");
	ScriptExpression =
		PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.ScriptExpression");
	TableAttribute = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.TableAttribute");
	DontFill = PredefinedValue("Enum.VariantsOfTheRulesForFillingInAttributes.EmptyRef");
	
	If Parameters.FilledInTemplate And Parameters.TemplateForbidModification Then
		TemplateForbidModification = True;
	Else
		TemplateForbidModification = False;
	EndIf;
	
	Items.ShouldUpdate.Visible =
		IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP");
	
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
Procedure AttributeNameObjectISStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectDetailsOfConsumerObject();
	
EndProcedure

&AtClient
Procedure ComputedExpressionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
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
	Result.Insert("Variant", Variant);
	Result.Insert("AttributeNameObjectIS");
	Result.Insert("Explanation");
	Result.Insert("ComputedExpression");
	Result.Insert("Picture");
	Result.Insert("ShouldUpdate", ShouldUpdate);
	
	If Variant = ObjectAttribute Then
		
		Result.AttributeNameObjectIS = AttributeNameObjectIS;
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
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectDetailsOfConsumerObject()
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectType", ObjectTypeIS);
	FormParameters.Insert("AttributeNameObjectIS", AttributeNameObjectIS);
	FormParameters.Insert("ObjectAttributePresentationDM", ObjectAttributePresentationDM);
	FormParameters.Insert("ThisIsTable", True);
	
	ChoiceFormName = "Catalog.RulesForIntegrationWith1CDocumentManagement.Form.SelectAttributeIS";
	Notification = New CallbackDescription("SelectDetailsOfConsumerObjectCompletion", ThisObject);
	
	OpenForm(ChoiceFormName, FormParameters, ThisObject,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectDetailsOfConsumerObjectCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		Result.Property("Name", AttributeNameObjectIS);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectCalculatedExpression()
	
	FormParameters = New Structure;
	FormParameters.Insert("ComputedExpression", ComputedExpression);
	FormParameters.Insert("TypeOfExpression", "ExportRule");
	FormParameters.Insert("ObjectTypeDM", ObjectTypeDM);
	FormParameters.Insert("ObjectTypeIS", ObjectTypeIS);
	FormParameters.Insert("AttributeNameObjectDM", AttributeNameObjectDM);
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
	
	Items.AttributeNameObjectIS.Enabled = (Variant = ObjectAttribute);
	Items.AttributeNameObjectIS.AutoMarkIncomplete = (Variant = ObjectAttribute);
	Items.AttributeNameObjectIS.MarkIncomplete = (Variant = ObjectAttribute) And Not ValueIsFilled(AttributeNameObjectIS);
	
	Items.ComputedExpression.Enabled = IsFullUser And (Variant = ScriptExpression);
	Items.ComputedExpression.AutoMarkIncomplete = (Variant = ScriptExpression);
	Items.ComputedExpression.MarkIncomplete = (Variant = ScriptExpression) And Not ValueIsFilled(ComputedExpression);
	
	Items.ShouldUpdate.Enabled = Not TemplateForbidModification;
	ShouldUpdate = ShouldUpdate And Not TemplateForbidModification;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Variant = ObjectAttribute Then
		CheckedAttributes.Add("AttributeNameObjectIS");
		
	ElsIf Variant = ScriptExpression Then
		CheckedAttributes.Add("ComputedExpression");
		
	EndIf;
	
EndProcedure

#EndRegion