#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ID", ID);
	Type = "DMInternalDocumentFolder";
	ParentType = "DMInternalDocumentFolder";
	
	Parameters.Property("ParentID", ParentID);
	Parameters.Property("Parent", Parent);
	
	If ValueIsFilled(ID) Then
		FillInXDTOObject_(GetXDTOObject());
	Else
		FillByDefault();
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ClosingWithParameter Then
		Return;
	EndIf;
	
	If Modified Then
		
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		WarningText = "";
		CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit,,WarningText);
		
	Else
		
		Cancel = True;
		AttachIdleHandler("CloseWithParameter", 0.1, True);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ParentOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	IntegrationWith1CDocumentManagementCoreClient.OpenObject(ParentType, ParentID, Item);
	
EndProcedure

&AtClient
Procedure ParentStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList(
		ParentType, "Parent", ThisObject);
	
EndProcedure

&AtClient
Procedure ParentChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"Parent", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure ParentAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			ParentType,
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure ParentTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			ParentType, ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"Parent", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleStartChoice(Item, ChoiceData, StandardProcessing)
	
	IntegrationWith1CDocumentManagementClient.SelectAValueFromTheList(
		EmployeeResponsibleType, "EmployeeResponsible", ThisObject);
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
		"EmployeeResponsible", ValueSelected, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			EmployeeResponsibleType,
			ChoiceData,
			Text,
			StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
			EmployeeResponsibleType, ChoiceData, Text, StandardProcessing);
		
		If ChoiceData.Count() = 1 Then
			IntegrationWith1CDocumentManagementCoreClient.ProcessingSelectionOfDataForAutoMatching(
				"EmployeeResponsible", ChoiceData[0].Value, StandardProcessing, ThisObject);
			StandardProcessing = True;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	If Not YouCanWrite() Then
		Return;
	EndIf;
	WriteAtServer();
	CloseWithParameter();
	
EndProcedure

&AtClient
Procedure WriteObject(Command)
	
	If Not YouCanWrite() Then
		Return;
	EndIf;
	WriteAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function YouCanWrite()
	
	If Not ValueIsFilled(Description) Then
		CurrentItem = Items.Description;
		ShowMessageBox(, NStr("vi = 'Chưa điền tên gọi.';
								|ru = 'Не заполнено наименование.';
								|en = 'Description is required.'; fa = 'Description is required.';
								|it = 'Il nome non è compilato.';
								|pl = 'Nie została wypełniona nazwa.';
								|tr = 'Tanım doldurulmadı.'"));
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure BeforeCloseCompletion(Response, NotificationParameters) Export
	
	FillAndWriteXDTOObject();
	CloseWithParameter();
	
EndProcedure

&AtClient
Procedure CloseWithParameter()
	
	If ValueIsFilled(ID) Then
		Result = New Structure;
		Result.Insert("ID", ID);
		Result.Insert("Type", Type);
		Result.Insert("Description", Description);
	Else
		Result = Undefined;
	EndIf;
	
	ClosingWithParameter = True;
	Close(Result);
	
EndProcedure

&AtServer
Procedure FillByDefault()
	
	CreationDate = CurrentSessionDate();
	
	CurCurrentUserAndEmployees =
		IntegrationWith1CDocumentManagementCoreCached.Current1CDocumentManagementUser();
	ResponsibleXDTO = CurCurrentUserAndEmployees[0];
	EmployeeResponsible = ResponsibleXDTO.name;
	EmployeeResponsibleID = ResponsibleXDTO.objectID.ID;
	EmployeeResponsibleType = ResponsibleXDTO.objectID.type;
	
EndProcedure

&AtServer
Function GetXDTOObject()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRetrieveRequest");
	ListOfObjects = Query.objectIDs; // XDTOList
	FieldsReceived = Query.columnSet; // XDTOList
	
	For Each PropsAndProperties In PropsAndProperties_() Do
		FieldsReceived.Add(PropsAndProperties.Key);
	EndDo;
	
	ListOfObjects.Add(
		IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			ID,
			Type));
	
	Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
	
	Return Result.objects[0];
	
EndFunction

&AtServer
Procedure WriteAtServer()
	
	FillInXDTOObject_(WriteXDTOObject(FillInXDTOObject()));
	
EndProcedure

&AtServer
Procedure FillAndWriteXDTOObject()
	
	WriteXDTOObject(FillInXDTOObject());
	
EndProcedure

&AtServer
Procedure FillInXDTOObject_(XDTODataObject)
	
	Description = XDTODataObject.name;
	ID = XDTODataObject.objectID.ID;
	Type = XDTODataObject.objectID.type;
	
	IntegrationWith1CDocumentManagement.FillOutFormFromXDTOObject(ThisObject,
		XDTODataObject,
		PropsAndProperties_());
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.SetNavigationLink(ThisObject, XDTODataObject);
	
EndProcedure

&AtServer
Function FillInXDTOObject()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODataObject = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, Type);
	
	IntegrationWith1CDocumentManagement.FillInXDTOObjectFromForm(XDTODataObject,
		ThisObject,
		PropsAndProperties_());
	
	XDTODataObject.name = Description;
	If ValueIsFilled(ID) Then
		XDTODataObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, ID, Type);
	Else
		XDTODataObject.objectID = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy);
	EndIf;
	
	Return XDTODataObject;
	
EndFunction

&AtServer
Function WriteXDTOObject(XDTODataObject)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	If ValueIsFilled(XDTODataObject.objectID.ID) Then
		Result = IntegrationWith1CDocumentManagementCore.WriteObject(Proxy, XDTODataObject);
		Return Result.objects[0];
	Else
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMCreateRequest");
		Query.object = XDTODataObject;
		Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
		Return Result.object;
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function PropsAndProperties_()
	
	Result = New Map;
	Result.Insert("parent", "Parent");
	Result.Insert("responsible", "EmployeeResponsible");
	Result.Insert("creationDate", "CreationDate");
	Result.Insert("description", "LongDesc");
	Return Result;
	
EndFunction

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
