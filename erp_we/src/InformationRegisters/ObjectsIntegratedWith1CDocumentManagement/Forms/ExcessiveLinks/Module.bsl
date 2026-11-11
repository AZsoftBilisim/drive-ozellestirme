#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	For Each Type In Metadata.DefinedTypes.IntegrationWith1CWorkflowAllLinksOverridable.Type.Types() Do
		IntegrationWith1CWorkflowAllLinks.Add(Type);
	EndDo;
	
	For Each LinkBefore In Parameters.ExcessiveLinksBefore Do
		FillPropertyValues(ExcessiveLinksBefore.Add(), LinkBefore);
	EndDo;
	
	For Each IPCommunication In Parameters.ExtraIPLinks Do
		FillPropertyValues(ExtraIPLinks.Add(), IPCommunication);
	EndDo;
	
	If ExcessiveLinksBefore.Count() = 0 And ExtraIPLinks.Count() = 0 Then
		Cancel = True;
		Return;
	EndIf;
	
	AbbreviatedNameOfConfiguration =
		IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	
	If ExcessiveLinksBefore.Count() = 0 Then
		Items.GroupExtraConnectionsDM.Visible = False;
	Else
		If ValueIsFilled(AbbreviatedNameOfConfiguration) Then
			Items.ExplanationExtraLinksDM.Title = StrTemplate(
				NStr("vi = 'Trong cơ sở 1C:Document Management có các tham chiếu đến các đối tượng không tồn tại %1.';
					|ru = 'В базе 1С:Документооборот есть ссылки на несуществующие объекты %1.';
					|en = '1C:Document Management contains references to non-existent %1 objects.'; fa = '1C:Document Management contains references to non-existent %1 objects.';
					|it = 'В базе 1С:Документооборот есть ссылки на несуществующие объекты %1.';
					|pl = '1C:Document Management contains references to non-existent %1 objects.';
					|tr = '1C:Document Management tabanında var olmayan %1 nesnelerine bağlantılar mevcut.'"),
				AbbreviatedNameOfConfiguration);
			Items.ExcessiveLinksBeforeObjectTypeIS.Title = StrTemplate(
				NStr("vi = 'Kiểu đối tượng %1';
					|ru = 'Тип объекта %1';
					|en = 'Object type %1'; fa = 'Object type %1';
					|it = 'Тип объекта %1';
					|pl = 'Object type %1';
					|tr = 'Nesne türü %1'"),
				AbbreviatedNameOfConfiguration);
			Items.ExcessiveLinksBeforeIdOfIPObject.Title = StrTemplate(
				NStr("vi = 'Tên định danh đối tượng %1';
					|ru = 'Идентификатор объекта %1';
					|en = '%1 object ID'; fa = '%1 object ID';
					|it = 'Идентификатор объекта %1';
					|pl = '%1 object ID';
					|tr = '%1 nesnesinin kimliği'"),
				AbbreviatedNameOfConfiguration);
			Items.ExcessiveLinksBeforeEstablishConnectionWithNewIPObject.Title = StrTemplate(
				NStr("vi = 'Cài đặt liên kết mới với đối tượng %1';
					|ru = 'Установить новую связь с объектом %1';
					|en = 'Add new link to %1 object'; fa = 'Add new link to %1 object';
					|it = 'Установить новую связь с объектом %1';
					|pl = 'Add new link to %1 object';
					|tr = '%1 nesnesi ile yeni bağlantı yapılandır'"),
				AbbreviatedNameOfConfiguration);
			Items.ExcessiveLinksBeforeContextMenuEstablishConnectionWithNewIPObject.Title = StrTemplate(
				NStr("vi = 'Cài đặt liên kết mới với đối tượng %1';
					|ru = 'Установить новую связь с объектом %1';
					|en = 'Add new link to %1 object'; fa = 'Add new link to %1 object';
					|it = 'Установить новую связь с объектом %1';
					|pl = 'Add new link to %1 object';
					|tr = '%1 nesnesi ile yeni bağlantı yapılandır'"),
				AbbreviatedNameOfConfiguration);
		EndIf;
	EndIf;
	
	If ExtraIPLinks.Count() = 0 Then
		Items.ExtraIPConnectionsGroup.Visible = False;
	Else
		If ValueIsFilled(AbbreviatedNameOfConfiguration) Then
			Items.ExplanationUnnecessaryIPLinks.Title = StrTemplate(
				NStr("vi = 'Trong cơ sở %1 có các tham chiếu đến các đối tượng không tồn tại của 1C:Document Management.';
					|ru = 'В базе %1 есть ссылки на несуществующие объекты 1С:Документооборот.';
					|en = '%1 contains references to non-existent 1C:Document Management objects.'; fa = '%1 contains references to non-existent 1C:Document Management objects.';
					|it = 'В базе %1 есть ссылки на несуществующие объекты 1С:Документооборот.';
					|pl = '%1 contains references to non-existent 1C:Document Management objects.';
					|tr = '%1 tabanında var olmayan 1C:Document Management nesnelerine bağlantılar mevcut.'"),
				AbbreviatedNameOfConfiguration);
			Items.ExtraIPLinksDeleteIPLinks.Title = StrTemplate(
				NStr("vi = 'Xóa bỏ các liên kết thừa trong cơ sở %1';
					|ru = 'Удалить лишние связи в базе %1';
					|en = 'Delete excessive links in %1'; fa = 'Delete excessive links in %1';
					|it = 'Удалить лишние связи в базе %1';
					|pl = 'Delete excessive links in %1';
					|tr = '%1 tabanındaki fazlalık bağlantıları sil'"),
				AbbreviatedNameOfConfiguration);
			Items.TitleExtraLinksIP.Title = StrTemplate(
				NStr("vi = 'Các liên kết thừa trong cơ sở %1';
					|ru = 'Лишние связи в базе %1';
					|en = 'Excessive links in %1'; fa = 'Excessive links in %1';
					|it = 'Лишние связи в базе %1';
					|pl = 'Excessive links in %1';
					|tr = '%1 tabanındaki fazlalık bağlantılar'"),
				AbbreviatedNameOfConfiguration);
			Items.ExtraIPLinksObjectIS.Title = StrTemplate(
				NStr("vi = 'Đối tượng %1';
					|ru = 'Объект %1';
					|en = 'Object %1'; fa = 'Object %1';
					|it = 'Oggetto %1';
					|pl = 'Obiekt %1';
					|tr = 'Nesne %1'"),
				AbbreviatedNameOfConfiguration);
			Items.ExtraIPLinksContextMenuOpenIPObject.Title = StrTemplate(
				NStr("vi = 'Mở đối tượng %1';
					|ru = 'Открыть объект %1';
					|en = 'Open the %1 object'; fa = 'Open the %1 object';
					|it = 'Открыть объект %1';
					|pl = 'Open the %1 object';
					|tr = '%1 nesnesini aç'"),
				AbbreviatedNameOfConfiguration);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExtraIPLinks

&AtClient
Procedure ExtraIPLinksSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Field.Name = "ExtraIPLinksObjectIS" Then
		OpenIPObject();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExcessiveLinksBefore

&AtClient
Procedure ExcessiveLinksBeforeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Field.Name = "ExtraConnectionsToObjectTO" Then
		OpenDMObject();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MarkExtraLinksDM(Command)
	
	For Each String In ExcessiveLinksBefore Do
		String.Mark = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure NoteUnnecessaryIPLinks(Command)
	
	For Each String In ExtraIPLinks Do
		String.Mark = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure RemoveMarksForUnnecessaryConnectionsDM(Command)
	
	For Each String In ExcessiveLinksBefore Do
		String.Mark = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure RemoveMarksUnnecessaryIPConnections(Command)
	
	For Each String In ExtraIPLinks Do
		String.Mark = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure OpenObjectDMCommand(Command)
	
	OpenDMObject();
	
EndProcedure

&AtClient
Procedure OpenIPObjectCommand(Command)
	
	OpenIPObject();
	
EndProcedure

&AtClient
Procedure DeleteLinksDM(Command)
	
	DeleteConnectionsDMOnServer();
	
EndProcedure

&AtClient
Procedure DeleteIPLinks(Command)
	
	DeleteIPConnectionsOnServer();
	
EndProcedure

&AtClient
Procedure EstablishConnectionWithNewObjectDM(Command)
	
	CurrentData = Items.ExtraIPLinks.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.ObjectTypeDM) Then
		EstablishConnectionWithNewObjectDMAfterSelectingType(CurrentData.ObjectTypeDM, CurrentData)
	Else
		Notification = New CallbackDescription("EstablishConnectionWithNewObjectDMAfterSelectingType", ThisObject, CurrentData);
		TypesOfXDTO = New Array;
		TypesOfXDTO.Add("DMDocument");
		TypesOfXDTO.Add("DMCorrespondent");
		TypesOfXDTO.Add("DMMeeting");
		TypesList = New ValueList;
		For Each XDTOType In TypesOfXDTO Do
			TypesList.Add(
				XDTOType,
				IntegrationWith1CDocumentManagement3ClientServer.ObjectTypePresentationXDTO(XDTOType));
		EndDo;
		TypesList.ShowChooseItem(Notification, NStr("vi = 'Chọn kiểu dữ liệu';
													|ru = 'Выбор типа данных';
													|en = 'Select data type'; fa = 'Select data type';
													|it = 'Scelta del tipo dati';
													|pl = 'Wybierz typ danych';
													|tr = 'Veri türünü seçin'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure EstablishConnectionWithNewObjectDMAfterSelectingType(Val ObjectTypeDM, CurrentData) Export
	
	If ObjectTypeDM = Undefined Then
		Return;
	ElsIf TypeOf(ObjectTypeDM) = Type("String") Then
		OldObjectTypeDM = ObjectTypeDM;
	ElsIf TypeOf(ObjectTypeDM) = Type("ValueListItem") Then
		OldObjectTypeDM = "";
		ObjectTypeDM = ObjectTypeDM.Value;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("ObjectIS", CurrentData.ObjectIS);
	NotificationParameters.Insert("OldObjectTypeDM", OldObjectTypeDM);
	NotificationParameters.Insert("OldObjectIdDM", CurrentData.ObjectIDDM);
	
	Notification = New CallbackDescription(
		"EstablishConnectionWithNewObjectDMEndOfSelection",
		ThisObject,
		NotificationParameters);
	
	ModuleIntegrationWith1CDocumentManagement3Client = CommonClient.CommonModule("IntegrationWith1CDocumentManagement3Client");
	ModuleIntegrationWith1CDocumentManagement3Client.SelectValueByObjectType(Notification, ObjectTypeDM);
	
EndProcedure

&AtClient
Procedure EstablishConnectionWithNewObjectDMEndOfSelection(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		EstablishConnectionWithNewObjectDMOnServer(
			NotificationParameters.ObjectIS,
			NotificationParameters.OldObjectTypeDM,
			NotificationParameters.OldObjectIdDM,
			Result.AttributeType,
			Result.AttributeID);
		For Each String In ExtraIPLinks Do
			If String.ObjectIS = NotificationParameters.ObjectIS
					And String.ObjectTypeDM = NotificationParameters.OldObjectTypeDM
					And String.ObjectIDDM = NotificationParameters.OldObjectIdDM Then
				ExtraIPLinks.Delete(ExtraIPLinks.IndexOf(String));
				Break;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure EstablishConnectionWithNewIPObject(Command)
	
	CurrentData = Items.ExcessiveLinksBefore.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.ObjectTypeIS) Then
		EstablishConnectionWithNewIPObjectAfterSelectingType(CurrentData.ObjectTypeIS, CurrentData)
	Else
		Notification = New CallbackDescription("EstablishConnectionWithNewIPObjectAfterSelectingType", ThisObject, CurrentData);
		IntegrationWith1CWorkflowAllLinks.ShowChooseItem(Notification, NStr("vi = 'Chọn kiểu dữ liệu';
																			|ru = 'Выбор типа данных';
																			|en = 'Select data type'; fa = 'Select data type';
																			|it = 'Scelta del tipo dati';
																			|pl = 'Wybierz typ danych';
																			|tr = 'Veri türünü seçin'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure EstablishConnectionWithNewIPObjectAfterSelectingType(Val ObjectTypeIS, CurrentData) Export
	
	If ObjectTypeIS = Undefined Then
		Return;
	ElsIf TypeOf(ObjectTypeIS) = Type("String") Then
		OldIPObjectType = ObjectTypeIS;
		NameOfIPObjectType = IntegrationWith1CDocumentManagementCoreClientServer.TypeNameFromFullName(ObjectTypeIS);
		ObjectTypeIS = Type(NameOfIPObjectType);
	ElsIf TypeOf(ObjectTypeIS) = Type("ValueListItem") Then
		OldIPObjectType = "";
		ObjectTypeIS = ObjectTypeIS.Value;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("OldIPObjectType", OldIPObjectType);
	NotificationParameters.Insert("OldIdOfIPObject", CurrentData.IdOfIPObject);
	NotificationParameters.Insert("ObjectTypeDM", CurrentData.ObjectTypeDM);
	NotificationParameters.Insert("ObjectIDDM", CurrentData.ObjectIDDM);
	
	Notification = New CallbackDescription(
		"EstablishConnectionWithNewIPObjectEndOfSelection",
		ThisObject,
		NotificationParameters);
	ShowInputValue(
		Notification,,
		StrTemplate(NStr("vi = 'Hãy chọn đối tượng mà có liên quan với ""%1""';
						|ru = 'Выберите объект, связанный с ""%1""';
						|en = 'Select an object connected with ""%1""'; fa = 'Select an object connected with ""%1""';
						|it = 'Выберите объект, связанный с ""%1""';
						|pl = 'Select an object connected with ""%1""';
						|tr = '""%1"" ile ilişkili nesneyi seçin'"), CurrentData.ObjectPresentationDM),
		ObjectTypeIS);
	
EndProcedure

&AtClient
Procedure EstablishConnectionWithNewIPObjectEndOfSelection(ObjectIS, NotificationParameters) Export
	
	If ObjectIS <> Undefined Then
		EstablishConnectionWithNewIPObjectOnServer(
			ObjectIS,
			NotificationParameters.ObjectTypeDM,
			NotificationParameters.ObjectIDDM,
			NotificationParameters.OldIPObjectType,
			NotificationParameters.OldIdOfIPObject);
		For Each String In ExcessiveLinksBefore Do
			If String.ObjectTypeIS = NotificationParameters.OldIPObjectType
					And String.IdOfIPObject = NotificationParameters.OldIdOfIPObject
					And String.ObjectTypeDM = NotificationParameters.ObjectTypeDM
					And String.ObjectIDDM = NotificationParameters.ObjectIDDM Then
				ExcessiveLinksBefore.Delete(ExcessiveLinksBefore.IndexOf(String));
				Break;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenDMObject()
	
	CurrentData = Items.ExcessiveLinksBefore.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ModuleIntegrationWith1CDocumentManagement3Client = CommonClient.CommonModule("IntegrationWith1CDocumentManagement3Client");
	ModuleIntegrationWith1CDocumentManagement3Client.OpenDMObject(CurrentData.ObjectBefore);
	
EndProcedure

&AtClient
Procedure OpenIPObject()
	
	CurrentData = Items.ExtraIPLinks.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ShowValue(, CurrentData.ObjectIS);
	
EndProcedure

&AtServer
Procedure EstablishConnectionWithNewObjectDMOnServer(ObjectIS, OldObjectTypeDM, OldObjectIdDM,
		NewObjectTypeDM, NewObjectIdDM)
	
	BeginTransaction();
	
	Try
		
		// There is no pair connection on the side BEFORE the pair. We remove the connection only from the register on the IC side.
		InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.DeleteLink(
			OldObjectIdDM,
			OldObjectTypeDM,
			ObjectIS);
		
		// Add a new link to the DO and IS databases.
		IntegrationWith1CDocumentManagementCoreServerCall.AddLink(
			NewObjectIdDM,
			NewObjectTypeDM,
			ObjectIS);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

&AtServer
Procedure EstablishConnectionWithNewIPObjectOnServer(ObjectIS, ObjectTypeDM, ObjectIDDM,
		OldIPObjectType, OldIdOfIPObject)
	
	BeginTransaction();
	
	Try
		
		// There is no pair connection on the IC side. We remove the connection only from the register on the DO side.
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRemoveObjectLinkRequest");
		Query.ownerObject = IntegrationWith1CDocumentManagementCore.CreateExternalObject(
			Proxy,,
			OldIdOfIPObject,
			OldIPObjectType);
		Query.linkedObject = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			ObjectIDDM,
			ObjectTypeDM);
		Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
		
		// Add a new link to the DO and IS databases.
		IntegrationWith1CDocumentManagementCoreServerCall.AddLink(
			ObjectIDDM,
			ObjectTypeDM,
			ObjectIS);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

&AtServer
Procedure DeleteConnectionsDMOnServer()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	QueriesArray = New Array;
	
	RowsCount = ExcessiveLinksBefore.Count();
	For LineNumber = 1 To RowsCount Do
		String = ExcessiveLinksBefore[RowsCount - LineNumber];
		If Not String.Mark Then
			Continue;
		EndIf;
		
		// There is no pair connection on the IC side. We remove the connection only from the register on the DO side.
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRemoveObjectLinkRequest");
		Query.ownerObject = IntegrationWith1CDocumentManagementCore.CreateExternalObject(
			Proxy,,
			String.IdOfIPObject,
			String.ObjectTypeIS);
		Query.linkedObject = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			String.ObjectIDDM,
			String.ObjectTypeDM);
		QueriesArray.Add(Query);
		
		ExcessiveLinksBefore.Delete(ExcessiveLinksBefore.IndexOf(String));
	EndDo;
	
	If QueriesArray.Count() > 0 Then
		IntegrationWith1CDocumentManagementCore.ExecuteBatchRequest(
			Proxy,
			QueriesArray,
			True);
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteIPConnectionsOnServer()
	
	BeginTransaction();
	
	Try
		
		RowsCount = ExtraIPLinks.Count();
		For LineNumber = 1 To RowsCount Do
			String = ExtraIPLinks[RowsCount - LineNumber];
			If Not String.Mark Then
				Continue;
			EndIf;
			
			// There is no pair connection on the side BEFORE the pair. We remove the connection only from the register on the IC side.
			InformationRegisters.ObjectsIntegratedWith1CDocumentManagement.DeleteLink(
				String.ObjectIDDM,
				String.ObjectTypeDM,
				String.ObjectIS);
			
			ExtraIPLinks.Delete(ExtraIPLinks.IndexOf(String));
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion