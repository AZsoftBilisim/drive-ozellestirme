#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Title") Then
		Title = Parameters["Title"];
	EndIf;
	
	If Parameters.Property("CommandTitle") Then
		Items.Done.Title = Parameters["CommandTitle"];
	EndIf;
	
	If Parameters.Property("ObjectIS") Then
		ObjectTypeIS = Parameters.ObjectIS.Metadata().FullName();
	EndIf;
	
	Items.GroupConfigureRule.Visible =
		AccessRight("Insert", Metadata.Catalogs.RulesForIntegrationWith1CDocumentManagement);
	
	TypesOfXDTO = New Array;
	TypesOfXDTO.Add("DMInternalDocument");
	TypesOfXDTO.Add("DMIncomingDocument");
	TypesOfXDTO.Add("DMOutgoingDocument");
	TypesOfXDTO.Add("DMCorrespondent");
	
	For Each XDTOType In TypesOfXDTO Do
		NewRow = ObjectsTypes.Add();
		NewRow.Type = XDTOType;
		NewRow.Presentation = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(XDTOType);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SceneryCustomizeRuleClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectTypeIS", ObjectTypeIS);
	
	OpenForm("Catalog.RulesForIntegrationWith1CDocumentManagement.Form.ItemForm",
		FormParameters,
		ThisObject);
	
	Close();
	
EndProcedure

&AtClient
Procedure Done(Command)
	
	SelectAndClose();
	
EndProcedure

&AtClient
Procedure ObjectsTypesSelection(Item, RowSelected, Field, StandardProcessing)
	
	SelectAndClose();
	
EndProcedure

&AtClient
Procedure SelectAndClose()
	
	CurrentData = Items.ObjectsTypes.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Close(CurrentData.Type);
	
EndProcedure

#EndRegion