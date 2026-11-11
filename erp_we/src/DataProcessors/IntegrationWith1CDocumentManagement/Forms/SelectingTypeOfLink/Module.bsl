#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SourceDocument_ = Parameters.SourceDocument_;
	SourceDocument_.Property("ID", SourceDocument_ID);
	SourceDocument_.Property("Type", SourceDocument_Type);
	SourceDocument_.Property("Presentation", SourceDocument_Presentation);
	
	LinkedDocument = Parameters.LinkedDocument;
	LinkedDocument.Property("ID", LinkedDocumentID);
	LinkedDocument.Property("Type", LinkedDocumentType);
	LinkedDocument.Property("Presentation", LinkedDocumentPresentation);
	
	FillInTypesOfLinks();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// In the absence of available links, we will show an explanation.
	If TypesOfLinks.Count() = 0 Then
		Items.GroupPages.CurrentPage
			= Items.PageNoAvailableTypes;
		Items.FormCreate.Visible = False;
		Items.CreateContext.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTypesOfLinks

&AtClient
Procedure TypesOfLinksValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	CloseWithParameter(Items.TypesOfLinks.CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateLink(Command)
	
	CurrentData = Items.TypesOfLinks.CurrentData;
	If CurrentData <> Undefined Then
		CloseWithParameter(CurrentData);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Fills in the relationship table with a request to the web service according to the linked documents.
//
&AtServer
Procedure FillInTypesOfLinks()
	
	TypesOfLinks.Clear();
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Conditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	ListOfSelectionConditions = Conditions.conditions; // XDTOList
	
	ConditionFrom = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	ConditionFrom.property = "DocumentFrom";
	ConditionFrom.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		SourceDocument_ID,
		SourceDocument_Type);
	ListOfSelectionConditions.Add(ConditionFrom);
	
	ConditionB = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	ConditionB.property = "DocumentTo";
	ConditionB.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		LinkedDocumentID,
		LinkedDocumentType);
	ListOfSelectionConditions.Add(ConditionB);
	
	Result = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMRelationType",
		Conditions);
	
	For Each Item In Result.items Do
		NewRow = TypesOfLinks.Add();
		NewRow.ID = Item.object.objectID.ID;
		NewRow.Description = Item.object.name;
	EndDo;
	
EndProcedure

// Closes the form with the transmission of the selected type of communication.
//
&AtClient
Procedure CloseWithParameter(RowSelected)
	
	LinkType = New Structure;
	LinkType.Insert("ID", RowSelected.ID);
	LinkType.Insert("Type", "DMRelationType");
	LinkType.Insert("Presentation", RowSelected.Description);
	
	Close(LinkType);
	
EndProcedure

// Closes the form with the transmission of the result that returns the process to the selection of the document.
//
&AtClient
Procedure RepeatDocumentSelection(Command)
	
	Close("RepeatDocumentSelection");
	
EndProcedure

#EndRegion
