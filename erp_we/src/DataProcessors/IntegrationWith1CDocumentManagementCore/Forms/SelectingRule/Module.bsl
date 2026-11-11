#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreOverridable.WhenCreatingRuleSelectionFormOnServer(
		ThisObject);
	
	Settings = IntegrationWith1CDocumentManagementCoreServerCall.UseIntegration();
	NameOfTypeOfRulesOfIntegrationWith1CWorkflow3 = "CatalogRef.RulesForIntegrationWith1CDocumentManagement3";
	
	If Settings.UseIntegrationBefore3
			And Parameters.Rules.Count() > 0
			And TypeOf(Parameters.Rules[0]) = Type(NameOfTypeOfRulesOfIntegrationWith1CWorkflow3) Then
		// An array of links to the rules was passed to the parameters
		RulesAttributes = Common.ObjectsAttributesValues(
			Parameters.Rules,
			"Ref, Comment,
			|ObjectTypeIS, ObjectTypeDM,
			|ObjectPresentationISWithKeyFields, RepresentationOfDMObjectWithKeyAttributes");
		For Each Rule In RulesAttributes Do
			RuleRow = Rules.Add();
			FillPropertyValues(RuleRow, Rule.Value);
			RuleRow.ObjectPresentationIS = Rule.Value.ObjectPresentationISWithKeyFields;
			RuleRow.ObjectPresentationDM = Rule.Value.RepresentationOfDMObjectWithKeyAttributes;
		EndDo;
	Else
		// An array of structures with rule Attributes is passed to the parameters
		For Each Rule In Parameters.Rules Do
			RuleRow = Rules.Add();
			FillPropertyValues(RuleRow, Rule);
			RuleRow.Comment = Common.ObjectAttributeValue(
				RuleRow.Ref,
				"Comment");
		EndDo;
	EndIf;
	
	HasComments = False;
	For Each RuleRow In Rules Do
		IntegrationWith1CDocumentManagementCoreOverridable.WhenDefiningPresentationViewOfConsumerObject(
			RuleRow.Ref,
			RuleRow.ObjectPresentationIS);
		HasComments = HasComments Or ValueIsFilled(RuleRow.Comment);
	EndDo;
	
	If Parameters.Property("ObjectCreationIS") Then
		Items.RulesObjectPresentationDM.Visible = False;
		Items.RulesObjectPresentationIS.Visible = True;
	EndIf;
	
	Items.RulesComment.Visible = HasComments;
	Items.Rules.Header = HasComments;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	SelectAndClose();
	
EndProcedure

&AtClient
Procedure RulesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectAndClose();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectAndClose()
	
	CurrentData = Items.Rules.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Ref", CurrentData.Ref);
	Result.Insert("ObjectTypeDM", CurrentData.ObjectTypeDM);
	Result.Insert("ObjectTypeIS", CurrentData.ObjectTypeIS);
	Result.Insert("ObjectPresentationDM", CurrentData.ObjectPresentationDM);
	Result.Insert("ObjectPresentationIS", CurrentData.ObjectPresentationIS);
	
	Close(Result);
	
EndProcedure

#EndRegion