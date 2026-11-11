#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ID", ID);
	Parameters.Property("Type", Type);
	Parameters.Property("Presentation", Presentation);
	
	TreeItems = DocumentTree.GetItems();
	
	SuitableDocuments = GetSuitableDocuments();
	
	If SuitableDocuments.Count() <> 0 Then
		
		GroupString = TreeItems.Add();
		GroupString.IsFolder = True;
		GroupString.Presentation = StrTemplate(
			NStr("vi = 'Phù hợp (%1)';
				|ru = 'Подходящие (%1)';
				|en = 'Suitable (%1)'; fa = 'Suitable (%1)';
				|it = 'Adatti (%1)';
				|pl = 'Pasujące (%1)';
				|tr = 'Uygun (%1)'"),
			SuitableDocuments.Count());
		
		GroupItems1 = GroupString.GetItems();
		
		For Each SuitableDocument In SuitableDocuments Do
			StringElement = GroupItems1.Add();
			FillPropertyValues(StringElement, SuitableDocument);
		EndDo;
		
	EndIf;
	
	GroupString = TreeItems.Add();
	GroupString.IsFolder = True;
	GroupString.Presentation = NStr("vi = 'Có thể (3)';
									|ru = 'Возможные (3)';
									|en = 'Possible (3)'; fa = 'Possible (3)';
									|it = 'Possibili (3)';
									|pl = 'Możliwe (3)';
									|tr = 'Olası (3)'");
	
	GroupItems1 = GroupString.GetItems();
	
	TypesOfXDTO = New Array;
	TypesOfXDTO.Add("DMInternalDocument");
	TypesOfXDTO.Add("DMIncomingDocument");
	TypesOfXDTO.Add("DMOutgoingDocument");
	
	For Each XDTOType In TypesOfXDTO Do
		StringElement = GroupItems1.Add();
		StringElement.Type = XDTOType;
		StringElement.Presentation = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(XDTOType);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDocumentTree

&AtClient
Procedure DocumentTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	SelectAndClose();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NextCommand(Command)
	
	SelectAndClose();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

// Closes the form, passing as a result the description of the document in the current line.
//
&AtClient
Procedure SelectAndClose()
	
	CurrentData = Items.DocumentTree.CurrentData;
	
	If CurrentData = Undefined Or CurrentData.IsFolder Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("AttributeID", CurrentData.ID);
	Result.Insert("AttributeType", CurrentData.Type);
	Result.Insert("AttributePresentation", CurrentData.Presentation);
	
	Close(Result);
	
EndProcedure

// Returns an array of structures describing suitable documents UP TO.
//
&AtServer
Function GetSuitableDocuments()
	
	Result = New Array;
	
	// We get the IP object by the object UP to.
	ObjectReferenceIS = InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.ReferenceToIPObjectAccordingToDocumentManagementData(
		ID,
		Type);
	If ObjectReferenceIS = Undefined Then
		Return Result;
	EndIf;
	
	SuitableObjects = IntegrationWith1CDocumentManagement.GetSuitableObjectsToAddLinksTo(ObjectReferenceIS);
		
	If SuitableObjects.Count() = 0 Then
		Return Result;
	EndIf;
	
	// We will get the related documents UP to for suitable IP objects.
	Query = New Query(
		"SELECT DISTINCT
		|	IntegratedObjects_.ObjectTypeDM AS Type,
		|	IntegratedObjects_.ObjectIDDM AS ID,
		|	PRESENTATION(IntegratedObjects_.Object) AS Presentation
		|FROM
		|	InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS IntegratedObjects_
		|WHERE
		|	IntegratedObjects_.Object IN(&SuitableObjects)
		|	AND IntegratedObjects_.ObjectTypeDM IN(&AllowedTypes)");
	
	AllowedTypes = New Array; // The DO web service only supports links to documents
	AllowedTypes.Add("DMIncomingDocument");
	AllowedTypes.Add("DMInternalDocument");
	AllowedTypes.Add("DMOutgoingDocument");
	Query.SetParameter("AllowedTypes", AllowedTypes);
	
	Query.SetParameter("SuitableObjects", SuitableObjects);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ObjectDetails = New Structure;
		ObjectDetails.Insert("Type", Selection.Type);
		ObjectDetails.Insert("ID", Selection.ID);
		ObjectDetails.Insert("Presentation", Selection.Presentation);
		
		Result.Add(ObjectDetails);
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion