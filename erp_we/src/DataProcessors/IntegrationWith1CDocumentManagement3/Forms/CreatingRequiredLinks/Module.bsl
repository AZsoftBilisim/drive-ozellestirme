#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If TypeOf(Parameters.RequiredLinks) = Type("Array") And Parameters.RequiredLinks.Count() > 0 Then
		
		SettingsForRequiredLinks =
			Parameters.RequiredLinks; // An array of See IntegrationWith1CDocumentManagementCoreClientServer.SettingUpConnectionOfObjectsTO
		
		InitialObjectID = SettingsForRequiredLinks[0].LinkFrom.ID;
		InitialObjectType = SettingsForRequiredLinks[0].LinkFrom.Type;
		
		For Each MandatoryCommunication In SettingsForRequiredLinks Do
			LinkString = RequiredLinks.Add();
			
			If MandatoryCommunication.RefTo.Type = "DMDocumentType" Then
				LinkString.RefToType = "DMDocument";
				LinkString.DocumentKind = MandatoryCommunication.RefTo.Description;
				LinkString.DocumentKindID = MandatoryCommunication.RefTo.ID;
			ElsIf MandatoryCommunication.RefTo.Type = "" Then
				LinkString.RefToType = "ExternalRef";
			Else
				LinkString.RefToType = MandatoryCommunication.RefTo.Type;
			EndIf;
			
			LinkString.LinkType = MandatoryCommunication.LinkType.Description;
			If ValueIsFilled(MandatoryCommunication.TypeOfLinkComment) Then
				LinkString.LinkTypePresentation = StrTemplate(NStr("vi = '%1 (%2)';
																	|ru = '%1 (%2)';
																	|en = '%1 (%2)'; fa = '%1 (%2)';
																	|it = '%1 (%2)';
																	|pl = '%1 (%2)';
																	|tr = '%1 (%2)'"),
					MandatoryCommunication.LinkType.Presentation,
					MandatoryCommunication.TypeOfLinkComment);
			Else
				LinkString.LinkTypePresentation = MandatoryCommunication.LinkType.Presentation;
			EndIf;
			LinkString.LinkTypeID = MandatoryCommunication.LinkType.ID;
			LinkString.LinkTypeType = MandatoryCommunication.LinkType.Type;
		EndDo;
		
		RequiredLinks.Sort("LinkTypePresentation");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRequiredLinks

&AtClient
Procedure RequiredLinksSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.RequiredLinks.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("ChoosingMandatoryLinkEnd", ThisObject);

	Filter = Undefined;
	If ValueIsFilled(CurrentData.DocumentKindID) Then
		Filter = New Structure;
		ConditionDetails = New Structure;
		ConditionDetails.Insert("Value", CurrentData.DocumentKind);
		ConditionDetails.Insert("ValueID", CurrentData.DocumentKindID);
		ConditionDetails.Insert("ValueType", "DMDocumentType");
		Filter.Insert("documentType", ConditionDetails);
	EndIf;
	
	If CurrentData.RefToType = "ExternalRef" Then
		DetailsDecoration = StrTemplate(
			NStr("vi = 'Để hòa thành tạo văn bản, cần chỉ định liên kết ""%1"".
				|Hãy nhập địa chỉ tham chiếu để tạo liên kết.';
				|ru = 'Чтобы завершить создание документа, необходимо указать связь ""%1"".
				|Укажите адрес ссылки для создания связи.';
				|en = 'To complete the document creation, specify the ""%1"" link.
				|Specify URL to create the link.'; fa = 'To complete the document creation, specify the ""%1"" link.
				|Specify URL to create the link.';
				|it = 'To complete the document creation, specify the ""%1"" link.
				|Specify URL to create the link.';
				|pl = 'To complete the document creation, specify the ""%1"" link.
				|Specify URL to create the link.';
				|tr = 'Belge oluşturmayı tamamlamak için ""%1"" bağlantısının belirtilmesi gerekmektedir.
				|Bağlantı oluşturmak için bağlantı adresi belirtin.'"),
			CurrentData.LinkType);
		FormParameters = New Structure("DetailsDecoration", DetailsDecoration);
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExternalResourceForm",
			FormParameters,
			ThisObject,,,,
			CallbackDescription,
			FormWindowOpeningMode.LockWholeInterface);
	Else
		IntegrationWith1CDocumentManagement3Client.SelectValueByObjectType(
			CallbackDescription,
			CurrentData.RefToType,
			Filter,
			CurrentData.RefToID,
			ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure RequiredLinksBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	CurrentData = Items.RequiredLinks.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ClearLink(CurrentData);
	
EndProcedure

&AtClient
Procedure RequiredLinksBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	For Each String In RequiredLinks Do
		If Not ValueIsFilled(String.RefTo) Then
			ShowMessageBox(, NStr("vi = 'Cần chỉ định đối tượng liên kết.';
									|ru = 'Нужно указать связанный объект.';
									|en = 'Specify the related object.'; fa = 'Specify the related object.';
									|it = 'Specify the related object.';
									|pl = 'Specify the related object.';
									|tr = 'Bağlantılı nesne belirtilmelidir.'"));
			Return;
		EndIf;
	EndDo;
	
	ReturnArray = New Array;
	
	For Each MandatoryCommunication In RequiredLinks Do
		ConnectionToCreation = IntegrationWith1CDocumentManagementCoreClientServer.ConnectionToCreation();
		FillPropertyValues(ConnectionToCreation, MandatoryCommunication);
		If ConnectionToCreation.RefToType = "ExternalRef" Then
			ConnectionToCreation.RefToType = "";
		EndIf;
		ReturnArray.Add(ConnectionToCreation);
	EndDo;
	
	Close(ReturnArray);
	
EndProcedure

&AtClient
Procedure OpenLinkedObject(Command)
	
	CurrentData = Items.RequiredLinks.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.RefTo) And CurrentData.RefToType = "ExternalRef" Then
		FileSystemClient.OpenURL(CurrentData.RefTo);
	ElsIf ValueIsFilled(CurrentData.LinkToNavigationLink) Then
		IntegrationWith1CDocumentManagement3Client.OpenDMObject(CurrentData.LinkToNavigationLink);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ChoosingMandatoryLinkEnd(SelectionResult, Var_Parameters) Export
	
	If ValueIsFilled(SelectionResult)
			And SelectionResult <> DialogReturnCode.Cancel
			And Items.RequiredLinks.CurrentData <> Undefined Then
		
		CurrentData = Items.RequiredLinks.CurrentData;
		
		ClearLink(CurrentData);
		
		If Not LinkedObjectFits(SelectionResult, CurrentData.LinkTypeID) Then
			WarningText = StrTemplate(
				NStr("vi = 'Đối tượng đã chọn không tương ứng với kiểu liên kết ""%1"".
					|Hãy kiểm tra tùy chỉnh liên kết và chọn đối tượng liên kết phù hợp.';
					|ru = 'Выбранный объект не соответствует типу связи ""%1"".
					|Проверьте настройки связи и выберите подходящий связанный объект.';
					|en = 'The selected object does not match the ""%1"" link type.
					|Check the link settings and select the appropriate related object.'; fa = 'The selected object does not match the ""%1"" link type.
					|Check the link settings and select the appropriate related object.';
					|it = 'The selected object does not match the ""%1"" link type.
					|Check the link settings and select the appropriate related object.';
					|pl = 'The selected object does not match the ""%1"" link type.
					|Check the link settings and select the appropriate related object.';
					|tr = 'Seçilen nesne ""%1"" bağlantı tipiyle eşleşmiyor.
					|Bağlantı ayarlarını kontrol edin ve uygun bağlantılı nesne seçin.'"),
				CurrentData.LinkTypePresentation);
			ShowMessageBox(, WarningText);
			Return;
		EndIf;
		
		If SelectionResult.Property("ExternalResource") Then
			CurrentData.RefTo = SelectionResult.ExternalResource;
			CurrentData.Comment = SelectionResult.Comment;
		Else
			CurrentData.RefTo = SelectionResult.AttributePresentation;
			CurrentData.RefToID = SelectionResult.AttributeID;
			CurrentData.RefToType = SelectionResult.AttributeType;
			CurrentData.LinkToNavigationLink = SelectionResult.AttributeNavigationLink;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearLink(CurrentData)
	
	CurrentData.RefTo = "";
	CurrentData.RefToID = "";
	CurrentData.LinkToNavigationLink = "";
	CurrentData.Comment = "";
	
EndProcedure

&AtServer
Function LinkedObjectFits(Val SelectionResult, Val LinkTypeID)
	
	LinkedObjectFits = False;
	
	LinkFrom = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		InitialObjectID,
		InitialObjectType);
	
	RefTo = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM("", "");
	If SelectionResult.Property("ExternalResource") Then
		RefTo.Presentation = SelectionResult.ExternalResource;
	Else
		RefTo.Presentation = SelectionResult.AttributePresentation;
		RefTo.ID = SelectionResult.AttributeID;
		RefTo.Type = SelectionResult.AttributeType;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCore.GetProxy();
	SettingsForObjectConnectionsUPTO = IntegrationWith1CDocumentManagement3.RelationshipSettings(Proxy, LinkFrom, RefTo);
	
	For Each ConfigureLink In SettingsForObjectConnectionsUPTO.relationsSettings Do
		If LinkTypeID = ConfigureLink.relationType.objectID.ID Then
			LinkedObjectFits = True;
			Break;
		EndIf;
	EndDo;
	
	Return LinkedObjectFits;
	
EndFunction

#EndRegion