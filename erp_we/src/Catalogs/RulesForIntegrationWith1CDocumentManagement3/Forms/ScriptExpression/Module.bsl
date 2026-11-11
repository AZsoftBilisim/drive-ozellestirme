#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	AbbreviatedNameOfConfiguration =
		IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	If ValueIsFilled(AbbreviatedNameOfConfiguration) Then
		Items.PlaceWhereExpressionIsExecuted.ChoiceList.Clear();
		Items.PlaceWhereExpressionIsExecuted.ChoiceList.Add(
			Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnIntegratedSystemSide,
			StrTemplate(NStr("vi = 'Trong %1';
							|ru = 'На стороне %1';
							|en = 'On the %1 side'; fa = 'On the %1 side';
							|it = 'Sul lato %1';
							|pl = 'Po stronie %1';
							|tr = 'Tarafında %1'"), AbbreviatedNameOfConfiguration));
		Items.PlaceWhereExpressionIsExecuted.ChoiceList.Add(
			Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnDocumentManagementSide,
			NStr("vi = 'Trong 1C:Document Management';
				|ru = 'На стороне 1С:Документооборот';
				|en = 'On 1C:Document Management side'; fa = 'در سمت 1C:Document Management';
				|it = 'Sul lato 1C:Document Managment';
				|pl = 'Po stronie 1C:Document Management';
				|tr = '1C:Document Management tarafında'"));
	EndIf;
	
	Parameters.Property("ObjectTypeDM", ObjectTypeDM);
	Parameters.Property("ObjectTypeIS", ObjectTypeIS);
	Parameters.Property("AttributeNameObjectIS", AttributeNameObjectIS);
	Parameters.Property("ThisIsTable", ThisIsTable);
	Parameters.Property("Table", Table);
	Parameters.Property("DocumentKindDM", DocumentKindDM);
	Parameters.Property("ComputedExpression", ComputedExpression);
	Parameters.Property("PlaceWhereExpressionIsExecuted", PlaceWhereExpressionIsExecuted);
	Parameters.Property("CurCurrentLineIsAvailable", CurCurrentLineIsAvailable);
	
	If Not ValueIsFilled(PlaceWhereExpressionIsExecuted) Then
		PlaceWhereExpressionIsExecuted = Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnIntegratedSystemSide;
	EndIf;
	
	FillInInstructions();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DetailsWhenClicked(Item, EventData, StandardProcessing)
	
	IntegrationWith1CDocumentManagement3Client.InstructionOnClick(Item, EventData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PlaceWhereExpressionIsExecutedOnChange(Item)
	
	FillInInstructions();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Async Procedure TheCleanCommand(Val Command)
	
	QueryText = NStr("vi = 'Xóa biểu thức đã nhập?';
					|ru = 'Очистить введенное выражение?';
					|en = 'Clear the expression entered?'; fa = 'Clear the expression entered?';
					|it = 'Cancellare l''espressione inserita?';
					|pl = 'Wyczyścić wprowadzone wyrażenie?';
					|tr = '​​Girilen ifade temizlensin mi?'");
	Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(QueryText);
	
	If Response = DialogReturnCode.Yes Then
		Response = New Structure;
		Response.Insert("ComputedExpression", "");
		Response.Insert("PlaceWhereExpressionIsExecuted", PlaceWhereExpressionIsExecuted);
		
		Close(Response);
	EndIf;
	
EndProcedure

&AtClient
Procedure OkCommand(Command)
	
	Response = New Structure;
	Response.Insert("ComputedExpression", ComputedExpression);
	Response.Insert("PlaceWhereExpressionIsExecuted", PlaceWhereExpressionIsExecuted);
	
	Close(Response);
	
EndProcedure

&AtClient
Procedure CheckCommand(Command)
	
	ClearMessages();
	CheckExpressionInEmbeddedLanguage(ComputedExpression, ObjectTypeDM, ObjectTypeIS);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInInstructions()
	
	ExpressionParameters = Catalogs.RulesForIntegrationWith1CDocumentManagement3.ParametersOfExpressionInEmbeddedLanguage();
	If ThisIsTable Then
		ExpressionParameters.ThisIsTableLoadingRule = True;
	Else
		ExpressionParameters.ThisIsAttributeLoadingRule = True;
	EndIf;
	ExpressionParameters.ObjectTypeDM = ObjectTypeDM;
	ExpressionParameters.DocumentKindDMID = DocumentKindDM;
	ExpressionParameters.ObjectTypeIS = ObjectTypeIS;
	ExpressionParameters.AttributeNameObjectIS = AttributeNameObjectIS;
	ExpressionParameters.CurCurrentLineIsAvailable = CurCurrentLineIsAvailable;
	ExpressionParameters.SourceTable2 = Table;
	ExpressionParameters.PlaceWhereExpressionIsExecuted = PlaceWhereExpressionIsExecuted;
	Instruction = Catalogs.RulesForIntegrationWith1CDocumentManagement3.ExpressionInstruction(ExpressionParameters);
	
EndProcedure

&AtServer
Procedure CheckExpressionInEmbeddedLanguage(ComputedExpression, ObjectTypeDM, ObjectTypeIS)
	
	ContextOfExpression = Catalogs.RulesForIntegrationWith1CDocumentManagement3.ContextOfExpressionInEmbeddedLanguage();
	ContextOfExpression.SourceTable1 = Table;
	ContextOfExpression.DocumentKindDMID = DocumentKindDM;
	
	Catalogs.RulesForIntegrationWith1CDocumentManagement3.CheckLoadingRuleExpression(
		ComputedExpression,
		PlaceWhereExpressionIsExecuted,
		ObjectTypeDM,
		ObjectTypeIS,
		ContextOfExpression,
		ThisIsTable);
	
	Common.MessageToUser(NStr("vi = 'Không tìm thấy lỗi';
								|ru = 'Ошибок не обнаружено';
								|en = 'No errors detected'; fa = 'No errors detected';
								|it = 'Non sono stati rilevati errori';
								|pl = 'Nie wykryto błędów';
								|tr = 'Hatalar algılanmıyor'"));
	
EndProcedure

#EndRegion