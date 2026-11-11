#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("CurrentRow", CurrentRow);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateAppropriateRulesForLoadingVDO();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSuitableRulesForLoadingVDO

&AtClient
Procedure SuitableRulesForLoadingVDOValueChoice(Item, Value, StandardProcessing)
	
	ProcessTreeElementSelection();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	ProcessTreeElementSelection();
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	FormOwner.SuitableRulesForLoadingVDO.Clear();
	
	RulesArray = IntegrationWith1CDocumentManagement3ServerCall.SuitableRulesForLoadingVDO(
		FormOwner.Object.ObjectTypeIS);
	For Each Rule In RulesArray Do
		NewRow = FormOwner.SuitableRulesForLoadingVDO.Add();
		FillPropertyValues(NewRow, Rule);
	EndDo;
	
	UpdateAppropriateRulesForLoadingVDO();
	
EndProcedure

&AtClient
Procedure Create(Command)
	
	IntegrationWith1CDocumentManagement3Client.OpenDMObject(
		"e1cib/command/DataProcessor.SeamlessIntegrationAdministrationPanel.Command.IntegrationSettings");
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateAppropriateRulesForLoadingVDO()
	
	FillInAppropriateRulesForLoadingVDO(FormOwner.SuitableRulesForLoadingVDO);
	
	Rows = SuitableRulesForLoadingVDO.GetItems();
	For Each String In Rows Do
		Items.SuitableRulesForLoadingVDO.Expand(String.GetID(), True);
	EndDo;
	
	If ValueIsFilled(CurrentRow) Then
		For Each GroupString In Rows Do
			For Each String In GroupString.GetItems() Do
				If String.VDOLoadingRuleID = CurrentRow Then
					Items.SuitableRulesForLoadingVDO.CurrentRow = String.GetID();
					Break;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessTreeElementSelection()
	
	CurrentData = Items.SuitableRulesForLoadingVDO.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	If CurrentData.VDOLoadingRuleID = "" Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("VDOLoadingRule", CurrentData.VDOLoadingRule);
	Result.Insert("VDOLoadingRuleID", CurrentData.VDOLoadingRuleID);
	Result.Insert("ObjectTypeDM", CurrentData.ObjectTypeDM);
	Result.Insert("DocumentKindDM", CurrentData.DocumentKindDM);
	Result.Insert("DocumentKindDMID", CurrentData.DocumentKindDMID);
	
	Close(Result);
	
EndProcedure

&AtServer
Procedure FillInAppropriateRulesForLoadingVDO(Val ListOfRulesForLoadingVDO)
	
	Tree = FormAttributeToValue("SuitableRulesForLoadingVDO");
	
	Tree.Rows.Clear();
	
	FillInMetadataTreeBranch(
		Tree,
		ListOfRulesForLoadingVDO,
		"DMCorrespondent",
		PictureLib.Catalog,
		NStr("vi = 'Danh mục';
			|ru = 'Справочники';
			|en = 'Catalogs'; fa = 'فهرست‌ها';
			|it = 'Directory';
			|pl = 'Kartoteki';
			|tr = 'Kataloglar'"));
	FillInMetadataTreeBranch(
		Tree,
		ListOfRulesForLoadingVDO,
		"DMMeeting",
		PictureLib.Catalog,
		NStr("vi = 'Danh mục';
			|ru = 'Справочники';
			|en = 'Catalogs'; fa = 'فهرست‌ها';
			|it = 'Directory';
			|pl = 'Kartoteki';
			|tr = 'Kataloglar'"));
	FillInMetadataTreeBranch(
		Tree,
		ListOfRulesForLoadingVDO,
		"DMDocument",
		PictureLib.Document,
		NStr("vi = 'Văn bản';
			|ru = 'Документы';
			|en = 'Documents'; fa = 'اسناد';
			|it = 'Documenti';
			|pl = 'Documents';
			|tr = 'Belgeler'"));
	
	ValueToFormAttribute(Tree, "SuitableRulesForLoadingVDO");
	
EndProcedure

&AtServerNoContext
Procedure FillInMetadataTreeBranch(Tree, ListOfRulesForLoadingVDO, ObjectTypeDM, Picture, Presentation)
	
	LinesByType = ListOfRulesForLoadingVDO.FindRows(New Structure("ObjectTypeDM", ObjectTypeDM));
	
	If LinesByType.Count() > 0 Then
		GroupString = Tree.Rows.Find(Presentation, "VDOLoadingRule");
		If GroupString = Undefined Then
			GroupString = Tree.Rows.Add();
			GroupString.VDOLoadingRuleID = "";
			GroupString.VDOLoadingRule = Presentation;
			GroupString.Picture = Picture;
		EndIf;
		
		For Each StringByType In LinesByType Do
			FillPropertyValues(GroupString.Rows.Add(), StringByType);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion