#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InitialObject = Parameters.Description;
	InitialObjectID = Parameters.ID;
	InitialObjectType = Parameters.Type;
	SourceObjectNavigationLink = Parameters.URL;
	
	UploadLinkSettings();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.Back.Visible = False;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InitialObjectPresentationOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	IntegrationWith1CDocumentManagement3Client.OpenDMObject(SourceObjectNavigationLink);
	
EndProcedure

&AtClient
Procedure LinkedObjectPresentationOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	If Not ValueIsFilled(LinkedObjectPresentation) Then
		Return;
	EndIf;
	
	If ValueIsFilled(LinkedObjectString) Then
		FileSystemClient.OpenURL(LinkedObjectString);
	Else
		IntegrationWith1CDocumentManagement3Client.OpenDMObject(RelatedObjectNavigationLink);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTreeOfOptions

&AtClient
Procedure TreeOfOptionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectObject();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLinkTypesTable

&AtClient
Procedure LinkTypesTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	AddLink();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	If Items.GroupPages.CurrentPage = Items.GroupChooseObject Then
		SelectObject();
	Else
		AddLink();
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	ClearLinkedObject();
	
	Items.GroupPages.CurrentPage = Items.GroupChooseObject;
	Items.Back.Visible = False;
	Items.Done.Title = NStr("vi = 'Tiếp theo >';
							|ru = 'Далее >';
							|en = 'Next >'; fa = 'بعدی >';
							|it = 'Avanti >';
							|pl = 'Dalej >';
							|tr = 'İleri >'");
	ChangeCommandsPromptDone(NStr("vi = 'Tiếp theo';
									|ru = 'Далее';
									|en = 'Next'; fa = 'بعدی';
									|it = 'Avanti';
									|pl = 'Dalej';
									|tr = 'İleri'"));
	
EndProcedure

#EndRegion

#Region Private

#Region Client

&AtClient
Procedure SelectObject()
	
	OptionTreeCurrentData = Items.TreeOfOptions.CurrentData;
	If OptionTreeCurrentData = Undefined Or OptionTreeCurrentData.ThisIsTheTitle Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("SelectObjectCompletion", ThisObject, Parameters);
	
	If OptionTreeCurrentData.Type = "ExternalRef" Then
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExternalResourceForm",,
			ThisObject,,,,
			Notification,
			FormWindowOpeningMode.LockWholeInterface);
	Else
		IntegrationWith1CDocumentManagement3Client.SelectValueByObjectType(Notification, OptionTreeCurrentData.Type);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectObjectCompletion(Result, Var_Parameters) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	If Result.Property("AttributeID")
			And Result.Property("AttributeType")
			And Result.AttributeID = InitialObjectID
			And Result.AttributeType = InitialObjectType Then
		ShowMessageBox(,
			NStr("vi = 'Không thể đặt liên kết đối với với chính nó. Hãy chọn đối tượng khác để tạo liên kết. ';
				|ru = 'Нельзя установить связь объекта с самим собой. Выберите другой объект для создания связи.';
				|en = 'Cannot link an object to itself. Select another object to create a link.'; fa = 'Cannot link an object to itself. Select another object to create a link.';
				|it = 'Cannot link an object to itself. Select another object to create a link.';
				|pl = 'Cannot link an object to itself. Select another object to create a link.';
				|tr = 'Bir nesne kendisine bağlanamaz. Bağlantı oluşturmak için başka bir nesne seçin.'"));
		Return;
	EndIf;
	
	If Result.Property("ExternalResource") Then
		LinkedObjectString = Result.ExternalResource;
		LinkedObjectPresentation = StrTemplate(NStr("vi = '%1 (Xâu ký tự)';
													|ru = '%1 (Строка)';
													|en = '%1 (String)'; fa = '%1 (String)';
													|it = '%1 (String)';
													|pl = '%1 (String)';
													|tr = '%1 (Satır)'"), LinkedObjectString);
		Comment = Result.Comment;
	Else
		ObjectType = ObjectTypePresentation(Result.AttributeType);
		If Result.AttributeType = "DMDocument" Then
			RelatedObjectDocumentTypeID = Result.DocumentTypeAttributeID;
		EndIf;
		If ValueIsFilled(ObjectType) Then
			LinkedObject = Result.AttributePresentation;
			LinkedObjectID = Result.AttributeID;
			LinkedObjectType = Result.AttributeType;
			LinkedObjectPresentation =
				StrTemplate(NStr("vi = '%1 (%2)';
								|ru = '%1 (%2)';
								|en = '%1 (%2)'; fa = '%1 (%2)';
								|it = '%1 (%2)';
								|pl = '%1 (%2)';
								|tr = '%1 (%2)'"), Result.AttributePresentation, ObjectType);
			RelatedObjectNavigationLink = Result.AttributeNavigationLink;
		EndIf;
	EndIf;
	
	FillInTypesOfLinks();
	
	If ValueIsFilled(ErrorText) Then
		ShowMessageBox(, ErrorText);
		ErrorText = "";
		ClearLinkedObject();
		Return;
	EndIf;
	
	Items.GroupPages.CurrentPage = Items.CreateLinkGroup;
	Items.Back.Visible = True;
	Items.Done.Title = NStr("vi = 'Tạo liên kết';
							|ru = 'Создать связь';
							|en = 'Create a link'; fa = 'ایجاد پیوند';
							|it = 'Creare collegamento';
							|pl = 'Utwórz powiązanie';
							|tr = 'Bağlantı oluştur'");
	ChangeCommandsPromptDone(NStr("vi = 'Liên kết các đối tượng đã chọn';
									|ru = 'Связать выбранные объекты';
									|en = 'Link selected objects'; fa = 'Link selected objects';
									|it = 'Link selected objects';
									|pl = 'Link selected objects';
									|tr = 'Seçili nesneleri bağla'"));
	
EndProcedure

&AtClient
Procedure AddLink()
	
	TypesOfRelationshipsCurrentDataTable = Items.LinkTypesTable.CurrentData;
	If TypesOfRelationshipsCurrentDataTable = Undefined Then
		Return;
	EndIf;
	
	InitialObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		InitialObjectID,
		InitialObjectType);
	
	LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		LinkedObjectID,
		LinkedObjectType);
	If ValueIsFilled(LinkedObjectString) Then
		LinkedObjectBefore.Presentation = LinkedObjectString;
	EndIf;
	
	LinkType = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		TypesOfRelationshipsCurrentDataTable.ID,
		"DMRelationType");
	
	IntegrationWith1CDocumentManagement3ServerCall.AddObjectRelationshipsBefore(
		InitialObjectBefore,
		LinkedObjectBefore,
		LinkType,
		Comment);
	
	Notify("AddingObjectLinksTO", InitialObjectBefore);
	
	Close(True);
	
EndProcedure

&AtClient
Procedure ClearLinkedObject()
	
	LinkedObject = "";
	LinkedObjectID = "";
	LinkedObjectType = "";
	LinkedObjectPresentation = "";
	RelatedObjectDocumentTypeID = "";
	RelatedObjectNavigationLink = "";
	LinkedObjectString = "";
	
EndProcedure

#EndRegion

#Region Server

&AtServer
Procedure UploadLinkSettings()
	
	LinkFrom = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		InitialObjectID,
		InitialObjectType);
	Proxy = IntegrationWith1CDocumentManagementCore.GetProxy();
	SettingsForObjectConnectionsUPTO = IntegrationWith1CDocumentManagement3.RelationshipSettings(Proxy, LinkFrom);
	
	PossibleTypes = New ValueList;
	AddExternalRef = False;
	
	For Each ConfigureLink In SettingsForObjectConnectionsUPTO.relationsSettings Do
		ObjectType = ConfigureLink.relationTo.objectID.type;
		TypePresentation = ObjectTypePresentation(ObjectType);
		
		FilterParameters = New Structure;
		FilterParameters.Insert("RefToID", ConfigureLink.relationTo.objectID.ID);
		FilterParameters.Insert("RefToType", ObjectType);
		FilterParameters.Insert("LinkTypeID", ConfigureLink.relationType.objectID.ID);
		If RelationshipSettings.FindRows(FilterParameters).Count() > 0 Then
			Continue;
		EndIf;
		
		LinkSetupLine = RelationshipSettings.Add();
		LinkSetupLine.RefToID = ConfigureLink.relationTo.objectID.ID;
		LinkSetupLine.RefToType = ObjectType;
		LinkSetupLine.RefToPresentation = ConfigureLink.relationTo.objectID.presentation;
		LinkSetupLine.Comment = ConfigureLink.relationType.comment;
		LinkSetupLine.Important = ConfigureLink.important;
		LinkSetupLine.LinkTypeID = ConfigureLink.relationType.objectID.ID;
		LinkSetupLine.LinkTypePresentation = ConfigureLink.relationType.name;
		
		If ValueIsFilled(TypePresentation) Then
			If PossibleTypes.FindByValue(ObjectType) = Undefined Then
				PossibleTypes.Add(ObjectType, TypePresentation);
			EndIf;
		Else
			AddExternalRef = True;
		EndIf;
	EndDo;
	
	PossibleTypes.SortByPresentation();
	
	If AddExternalRef Then
		PossibleTypes.Add("ExternalRef", NStr("vi = 'Tham chiếu ngoài';
												|ru = 'Внешняя ссылка';
												|en = 'External link'; fa = 'پیوند خارجی';
												|it = 'Link esterno';
												|pl = 'Odnośnik zewnętrzny';
												|tr = 'Harici bağlantı'"));
	EndIf;
	
	Tree = FormAttributeToValue("TreeOfOptions");
	
	Tree.Rows.Clear();
	
	TitleLine = Tree.Rows.Add();
	TitleLine.ThisIsTheTitle = True;
	TitleLine.Description = StrTemplate(NStr("vi = 'Có thể (%1)';
											|ru = 'Возможные (%1)';
											|en = 'Possible (%1)'; fa = 'Possible (%1)';
											|it = 'Possible (%1)';
											|pl = 'Possible (%1)';
											|tr = 'Olası (%1)'"), PossibleTypes.Count());
	
	For Each String In PossibleTypes Do
		SubjectLine = TitleLine.Rows.Add();
		SubjectLine.Description = String.Presentation;
		SubjectLine.Type = String.Value;
	EndDo;
	
	ValueToFormData(Tree, TreeOfOptions);
	
EndProcedure

&AtServer
Procedure FillInTypesOfLinks()
	
	LinkTypesTable.Clear();
	
	LinkFrom = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		InitialObjectID,
		InitialObjectType);
	RefTo = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
		LinkedObjectID,
		LinkedObjectType);
	If ValueIsFilled(LinkedObjectString) Then
		RefTo.Presentation = LinkedObjectString;
	EndIf;
	Proxy = IntegrationWith1CDocumentManagementCore.GetProxy();
	SettingsForObjectConnectionsUPTO = IntegrationWith1CDocumentManagement3.RelationshipSettings(Proxy, LinkFrom, RefTo);
	
	For Each ConfigureLink In SettingsForObjectConnectionsUPTO.relationsSettings Do
		NewRow = LinkTypesTable.Add();
		NewRow.ID = ConfigureLink.relationType.objectID.ID;
		NewRow.Description = ConfigureLink.relationType.name;
		NewRow.Important = ConfigureLink.important;
		NewRow.Comment = ConfigureLink.relationType.comment;
		NewRow.Presentation = ConfigureLink.relationType.name;
		If ValueIsFilled(NewRow.Comment) Then
			NewRow.Presentation =
				StrTemplate(NStr("vi = '%1 (%2)';
								|ru = '%1 (%2)';
								|en = '%1 (%2)'; fa = '%1 (%2)';
								|it = '%1 (%2)';
								|pl = '%1 (%2)';
								|tr = '%1 (%2)'"), NewRow.Presentation, NewRow.Comment);
		EndIf;
	EndDo;
	
	LinkTypesTable.Sort("Presentation");
	
	If LinkTypesTable.Count() = 0 Then
		ErrorText =
			NStr("vi = 'Không thể đặt liên kết, vì đối với các văn bản đã chọn chưa thiết lập kiểu liên kết nào';
				|ru = 'Нельзя установить связь, так как для выбранных документов не настроено ни одного типа связи';
				|en = 'Cannot set the link as no link type is configured for the selected documents'; fa = 'Cannot set the link as no link type is configured for the selected documents';
				|it = 'Cannot set the link as no link type is configured for the selected documents';
				|pl = 'Cannot set the link as no link type is configured for the selected documents';
				|tr = 'Seçilen belgeler için herhangi bir bağlantı tipi yapılandırılmadığından dolayı bağlantı kurulamaz'");
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeCommandsPromptDone(Val ToolTip)
	
	Commands.Done.ToolTip = ToolTip;
	
EndProcedure

&AtClientAtServerNoContext
Function ObjectTypePresentation(ObjectType)
	
	If ObjectType = "DMDocumentType" Then
		ObjectType = "DMDocument";
	EndIf;
	
	Return IntegrationWith1CDocumentManagement3ClientServer.ObjectTypePresentationXDTO(ObjectType);
	
EndFunction

#EndRegion

#EndRegion