#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Role = Parameters.Role;
	RoleType = Parameters.RoleType;
	RoleID = Parameters.RoleID;
	
	UpdateRoleData(Parameters.RoleType, Parameters.RoleID);
	
	If RoleData.UsedWithoutAddressingObjects And Not RoleData.UsedByAddressingObjects Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MainAddressingObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectAddressObject("MainAddressingObject", "TypeOfMainAddressingObject");
	
EndProcedure

&AtClient
Procedure AdditionalAddressingObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectAddressObject("AdditionalAddressingObject", "TypeOfAdditionalAddressingObject");
	
EndProcedure

&AtClient
Procedure RoleOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure MainAddressingObjectOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure AdditionalAddressingObjectOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure RoleClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure MainAddressingObjectClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	ClearAddressObject("MainAddressingObject");
	
EndProcedure

&AtClient
Procedure AdditionalAddressingObjectClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	ClearAddressObject("AdditionalAddressingObject");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	Cancel = False;
	ClearMessages();
	If RoleData.UsedByAddressingObjects And Not RoleData.UsedWithoutAddressingObjects Then
		
		If Items.MainAddressingObject.Visible And Not ValueIsFilled(MainAddressingObject) Then
			Text = CommonClientServer.FillingErrorText(,, Items.MainAddressingObject.Title);
			CommonClient.MessageToUser(Text,,, "MainAddressingObject");
			Cancel = True;
		EndIf;
		
		If Items.AdditionalAddressingObject.Visible And Not ValueIsFilled(AdditionalAddressingObject) Then
			Text = CommonClientServer.FillingErrorText(,, Items.AdditionalAddressingObject.Title);
			CommonClient.MessageToUser(Text,,, "AdditionalAddressingObject");
			Cancel = True;
		EndIf;
		
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	ReturnData = New Structure;
	
	ReturnData.Insert("Result", "OK");
	
	ReturnData.Insert("Performer", Role);
	ReturnData.Insert("PerformerID", RoleID);
	ReturnData.Insert("PerformerType", RoleType);
	
	ReturnData.Insert("MainAddressingObject", MainAddressingObject);
	ReturnData.Insert("MainAddressingObjectID", MainAddressingObjectID);
	ReturnData.Insert("MainAddressingObjectType", MainAddressingObjectType);
	
	ReturnData.Insert("AdditionalAddressingObject", AdditionalAddressingObject);
	ReturnData.Insert("AdditionalAddressingObjectID", AdditionalAddressingObjectID);
	ReturnData.Insert("AdditionalAddressingObjectType", AdditionalAddressingObjectType);
	
	Close(ReturnData);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	ReturnData = New Structure;
	ReturnData.Insert("Result", "Cancel");
	
	Close(ReturnData);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateRoleData(Type, ID)
	
	RoleData = New Structure;
	
	Items.MainAddressingObject.Visible = False;
	Items.AdditionalAddressingObject.Visible = False;
	Items.MainAddressingObject.Title = "";
	Items.AdditionalAddressingObject.Title = "";
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ReceivedRole = IntegrationWith1CDocumentManagementCore.GetObject(Proxy, Type, ID);
	
	RoleData.Insert("UsedByAddressingObjects", ReceivedRole.withAddressingObjects);
	RoleData.Insert("UsedWithoutAddressingObjects", ReceivedRole.withoutAddressingObjects);
	
	If ReceivedRole.withAddressingObjects Then
		
		Items.MainAddressingObject.Title = ReceivedRole.mainAddressingObjectName;
		Items.AdditionalAddressingObject.Title = ReceivedRole.secondaryAddressingObjectName;
		
		RoleData.Insert("NameOfMainAddressingObject", ReceivedRole.mainAddressingObjectName);
		RoleData.Insert("NameOfAdditionalAddressingObject", ReceivedRole.secondaryAddressingObjectName);
		
		TypeOfMainAddressingObject = New ValueList;
		For Each ElementType In ReceivedRole.mainAddressingObjectType Do
			TypeData_ = New Structure;
			TypeData_.Insert("XDTOClassName", ElementType.xdtoClassName);
			TypeData_.Insert("Presentation", ElementType.presentation);
			TypeOfMainAddressingObject.Add(TypeData_);
		EndDo;
		
		TypeOfAdditionalAddressingObject = New ValueList;
		For Each ElementType In ReceivedRole.secondaryAddressingObjectType Do
			TypeData_ = New Structure;
			TypeData_.Insert("XDTOClassName", ElementType.xdtoClassName);
			TypeData_.Insert("Presentation", ElementType.presentation);
			TypeOfAdditionalAddressingObject.Add(TypeData_);
		EndDo;
		
		RoleData.Insert("TypeOfMainAddressingObject", TypeOfMainAddressingObject);
		RoleData.Insert("TypeOfAdditionalAddressingObject", TypeOfAdditionalAddressingObject);
		
		Items.MainAddressingObject.Visible = ValueIsFilled(Items.MainAddressingObject.Title);
		Items.AdditionalAddressingObject.Visible =
			ValueIsFilled(Items.AdditionalAddressingObject.Title);
		
		Items.MainAddressingObject.MarkIncomplete = False;
		Items.AdditionalAddressingObject.MarkIncomplete = False;
		
		Items.MainAddressingObject.AutoMarkIncomplete = False;
		Items.AdditionalAddressingObject.AutoMarkIncomplete = False;
		
		If RoleData.UsedByAddressingObjects And Not RoleData.UsedWithoutAddressingObjects Then
			Items.MainAddressingObject.AutoMarkIncomplete = Items.MainAddressingObject.Visible;
			Items.AdditionalAddressingObject.AutoMarkIncomplete = Items.AdditionalAddressingObject.Visible;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAddressObject(VariableName, FieldName)
	
	TypeName = "";
	
	If RoleData[FieldName].Count() > 1 Then
		
		FormCaption = NStr("vi = 'Kiểu đối tượng đánh địa chỉ';
							|ru = 'Тип объекта адресации';
							|en = 'Business object type '; fa = 'Business object type ';
							|it = 'Tipo di oggetto di indirizzamento';
							|pl = 'Typ obiektu adresacji';
							|tr = 'Adresleme nesnesi türü'");
		FormParameters = New Structure("AvailableTypeList, FormCaption", RoleData[FieldName], FormCaption);
		Notification = New CallbackDescription("SelectAddressingObjectSelectDestinationType", ThisObject, VariableName);
		
		OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingOneTypeFromCompositeType",
			FormParameters,
			ThisObject,,,,
			Notification);
		
	ElsIf RoleData[FieldName].Count() = 1 Then
		
		TypeName = RoleData[FieldName][0].Value.XDTOClassName;
		FormParameters = New Structure;
		FormParameters.Insert("TypeOfSelectionObject", TypeName);
		
		Notification = New CallbackDescription("SelectAddressObjectCompletion", ThisObject, VariableName);
		
		OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFromList",
			FormParameters,
			ThisObject,,,,
			Notification);
		
	Else
		
		Return;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAddressingObjectSelectDestinationType(TypeSelectionResult, VariableName) Export
	
	If TypeSelectionResult = Undefined Then
		Return;
	EndIf;
	
	TypeName = TypeSelectionResult;
	
	FormParameters = New Structure;
	FormParameters.Insert("TypeOfSelectionObject", TypeName);
	
	Notification = New CallbackDescription("SelectAddressObjectCompletion", ThisObject, VariableName);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFromList",
		FormParameters,
		ThisObject,,,,
		Notification);
	
EndProcedure

&AtClient
Procedure SelectAddressObjectCompletion(SelectionResult, VariableName) Export
	
	If SelectionResult <> Undefined Then
		ThisObject[VariableName] = SelectionResult.AttributePresentation;
		ThisObject[VariableName + "ID"] = SelectionResult.AttributeID;
		ThisObject[VariableName + "Type"] = SelectionResult.AttributeType;
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearAddressObject(VariableName)
	
	ThisObject[VariableName] = "";
	ThisObject[VariableName + "ID"] = "";
	ThisObject[VariableName + "Type"] = "";
	
EndProcedure

#EndRegion