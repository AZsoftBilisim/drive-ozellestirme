#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	// Tasks.
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.6.2") Then
		Cancel = True;
		Return;
	EndIf;
	
	SummaryIsAvailable = IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.28.12.CORP");
	
	If Parameters.Property("SubjectOf") And ValueIsFilled(Parameters.SubjectOf) Then
		SubjectOf = Parameters.SubjectOf.name;
		SubjectOfID = Parameters.SubjectOf.ID;
		SubjectOfType = Parameters.SubjectOf.type;
		If Parameters.SubjectOf.Property("ExternalObject") Then
			ExternalObject = Parameters.SubjectOf.ExternalObject;
		EndIf;
	EndIf;
	
	If Parameters.Property("MainTask") And ValueIsFilled(Parameters.MainTask) Then
		MainTask = Parameters.MainTask.name;
		MainTaskID = Parameters.MainTask.ID;
		MainTaskType = Parameters.MainTask.type;
	EndIf;
	
	If ValueIsFilled(SubjectOfID) Then
		GettingDocumentView = False;
		If Not ValueIsFilled(DocumentKindID) Then
			// Batch requests.
			If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3") Then
				GettingDocumentView = True;
			Else
				Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMRetrieveRequest");
				ListOfObjects = Query.objectIDs; // XDTOList
				FieldsReceived = Query.columnSet; // XDTOList
				
				ListOfObjects.Add(
					IntegrationWith1CDocumentManagementCore.CreateObjectID(
						Proxy,
						SubjectOfID,
						SubjectOfType));
				
				FieldsReceived.Add("documentType");
				
				Result = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
				IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Result);
				Object = Result.objects[0];
				If Find(Object.objectID.type,"Document") <> 0 Then
					DocumentKind = Object.documentType.name;
				Else
					Items.DocumentKind.Visible = False;
				EndIf;
			EndIf;
		EndIf;
		FillInTemplateTree(GettingDocumentView);
	Else
		FillInTemplateTree();
	EndIf;
	
	SetItemTitleByItemType();
	
	If ValueIsFilled(SubjectOfID) Then
		Items.GroupElements.Enabled = True;
		Items.CreateProcess.Enabled = True;
		Items.SubjectGroup.Visible = True;
	Else
		Items.StartImmediately.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// The default branch expansion is set.
	TreeItems = TemplateTree.GetItems();
	For Each TreeItem In TreeItems Do
		If TreeItem.Expand Then
			Items.TemplateTree.Expand(TreeItem.GetID(), False);
		EndIf;
	EndDo;
	
	If NewDocumentIsCreated Then // We will notify the open Forms.
		
		NotificationParameters = New Structure;
		NotificationParameters.Insert("name", SubjectOf);
		NotificationParameters.Insert("ID", SubjectOfID);
		NotificationParameters.Insert("type", SubjectOfType);
		NotificationParameters.Insert("documentType", DocumentKind);
		
		Notify("Recording_1CDocumentManagementDocument", NotificationParameters, FormOwner);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Recording_1CDocumentManagementDocument" And Source = Items.SubjectOf Then
		SubjectOfID = Parameter.ID;
		SubjectOfType = Parameter.type;
		SubjectOf = Parameter.name;
		If Parameter.Property("documentType") Then
			DocumentKind = Parameter.documentType;
		EndIf;
		
		Items.GroupElements.Enabled = True;
		Items.CreateProcess.Enabled = True;
		Items.SubjectGroup.Enabled = True;
		
		FillInTemplateTree();
		
		TreeItems = TemplateTree.GetItems();
		For Each TreeItem In TreeItems Do
			If TreeItem.Expand Then
				Items.TemplateTree.Expand(TreeItem.GetID(), False);
			EndIf;
		EndDo;
	ElsIf EventName = "Recording_1CDocumentManagementBusinessProcess" Then
		If Parameter.Property("Started") Then
			If Parameter.Started Then
				AttachIdleHandler("CloseForm",0.1,True);
			EndIf;
		EndIf;
	ElsIf EventName = "Recording_1CDocumentManagementOutgoingEmail"
			And Parameter.SubjectOfID = SubjectOfID Then
		AttachIdleHandler("CloseForm",0.1,True);
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SubjectOfClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(SubjectOfID) Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(SubjectOfType, SubjectOfID, Items.SubjectOf);
	EndIf;
	
EndProcedure

&AtClient
Procedure SummaryOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTemplateTree

&AtClient
Procedure TemplateTreeBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure TemplateTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	CreateProcessExecute();
	
EndProcedure

&AtClient
Procedure TemplateTreeOnActivateRow(Item)
	
	CurrentData = Items.TemplateTree.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Items.CreateProcess.Enabled = Not CurrentData.ThisIsTheTitle;
	
	If Not CurrentData.HintReceived And SummaryIsAvailable Then
		Summary = TemplateSummary_(CurrentData.TemplateID, CurrentData.TemplateType);
	Else
		Summary = HTMLToolTip(CurrentData);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateProcess(Command)
	
	CreateProcessExecute();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(False);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function HTMLToolTip(Data)
	
	If StrFind(Data.ToolTip, "<html>") = 1 Then
		Return Data.ToolTip;
	EndIf;
	
	If Data.ThisIsTheTitle Then
		Return HTMLHeaderHint(Data.ToolTip);
	Else
		Return HTMLStringHint(Data.ToolTip);
	EndIf;
	
EndFunction

&AtClient
Function HTMLHeaderHint(ToolTip)
	
	Return StrReplace(
		"<html><head><style type=""text/css"">
		|	body {
		|		overflow:    auto;
		|		margin-top:  2px;
		|		margin-left: 2px;
		|		font-family: Arial;
		|		font-size:   10pt;}
		|	table {
		|		width:       100%;
		|		font-family: Arial;
		|		font-size:   10pt;
		|		border: 0px solID;}
		|	td {vertical-align: top;}
		|	a:link {
		|		color: #006699; text-decoration: none;}
		|	a:visited {
		|		color: #006699; text-decoration: none;}
		|	a:hover {
		|		color: #006699; text-decoration: underline;}
		|	p {
		|		margin-top: 15px;}
		|	table.frame {
		|		border-collapse: collapse;
		|		border: 1px solID #C8C8C8;}
		|	td.frame {
		|		border: 1px solID #C8C8C8;}
		|</style><body><table><tr><td><html><head><style type=""text/css""><br>
		|	body {<br>
		|		overflow:    auto;<br>
		|		margin-top:  2px;<br>
		|		margin-left: 2px;<br>
		|		font-family: Arial;<br>
		|		font-size:   10pt;}<br>
		|	table {<br>
		|		width:       100%;<br>
		|		font-family: Arial;<br>
		|		font-size:   10pt;<br>
		|		border: 0px solID;}<br>
		|	td {vertical-align: top;}<br>
		|	a:link {<br>
		|		color: #006699; text-decoration: none;}<br>
		|	a:visited {<br>
		|		color: #006699; text-decoration: none;}<br>
		|	a:hover {<br>
		|		color: #006699; text-decoration: underline;}<br>
		|	p {<br>
		|		margin-top: 15px;}<br>
		|	table.frame {<br>
		|		border-collapse: collapse;<br>
		|		border: 1px solID #C8C8C8;}<br>
		|	td.frame {<br>
		|		border: 1px solID #C8C8C8;}<br></style><body><table><tr>
		|<td>%ToolTip%</td>
		|</tr></table></body></html></td></tr></table></body></html>",
		"%ToolTip%",
		StrReplace(ToolTip, Chars.LF, "<br>"));
	
EndFunction

&AtClient
Function HTMLStringHint(ToolTip)
	
	Return StrReplace(
		"<html><head><style type=""text/css"">
		|	body {
		|		overflow:    auto;
		|		margin-top:  2px;
		|		margin-left: 2px;
		|		font-family: Arial;
		|		font-size:   10pt;}
		|	table {
		|		width:       100%;
		|		font-family: Arial;
		|		font-size:   10pt;
		|		border: 0px solID;}
		|	td {vertical-align: top;}
		|	a:link {
		|		color: #006699; text-decoration: none;}
		|	a:visited {
		|		color: #006699; text-decoration: none;}
		|	a:hover {
		|		color: #006699; text-decoration: underline;}
		|	p {
		|		margin-top: 15px;}
		|	table.frame {
		|		border-collapse: collapse;
		|		border: 1px solID #C8C8C8;}
		|	td.frame {
		|		border: 1px solID #C8C8C8;}
		|</style><body><table><tr><td>%ToolTip%</td></tr></table></body></html>",
		"%ToolTip%",
		StrReplace(ToolTip, Chars.LF, "<br>"));
	
EndFunction

&AtServer
Function TemplateSummary_(TemplateID, TemplateType)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetTemplateHintRequest");
	Query.template = IntegrationWith1CDocumentManagementCore.CreateObjectID(
		Proxy,
		TemplateID,
		TemplateType);
	
	QueryResult = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, QueryResult);
	
	Return QueryResult.hintHTML;
	
EndFunction

&AtServer
Procedure SetItemTitleByItemType()
	
	Items.SubjectOf.Title = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(SubjectOfType);
	If Items.SubjectOf.Title = SubjectOfType Then
		Items.SubjectOf.Title = NStr("vi = 'Chủ đề';
									|ru = 'Предмет';
									|en = 'Subject'; fa = 'موضوع';
									|it = 'Subject';
									|pl = 'Subject';
									|tr = 'Konu'");
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInTemplateTree(GettingDocumentView = False)
	
	Tree = FormAttributeToValue("TemplateTree");
	Tree.Rows.Clear();
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	PackageQueries = New Array;
	
	If GettingDocumentView Then
		ItemToReceiveFromDM = New Structure("ID, Type", SubjectOfID, SubjectOfType);
		PackageQueries.Add(
			IntegrationWith1CDocumentManagementCore.GetRequestObjects(
				Proxy,
				CommonClientServer.ValueInArray(ItemToReceiveFromDM),
				"documentType"));
	EndIf;
	
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetBusinessProcessTemplatesTreeRequest");
	If IntegrationWith1CDocumentManagementCore.PropertyExists(Query, "getComplexBusinessProcessTemplateHint") Then
		Query.getComplexBusinessProcessTemplateHint = False;
	EndIf;
	
	If ValueIsFilled(SubjectOfID) Then
		SubjectOfBusinessProcessID = IntegrationWith1CDocumentManagementCore.CreateObjectID(
			Proxy,
			SubjectOfID,
			SubjectOfType);
		Query.businessProcessTargetID = SubjectOfBusinessProcessID;
	EndIf;
	
	If GettingDocumentView Then
		PackageQueries.Add(Query);
		ResponseToPackageRequests = IntegrationWith1CDocumentManagementCore.ExecuteBatchRequest(
			Proxy,
			PackageQueries,
			True);
		
		ResultDocumentView = ResponseToPackageRequests.responses[0];
		Object = ResultDocumentView.objects[0];
		If Find(Object.objectID.type,"Document") <> 0 Then
			DocumentKind = Object.documentType.name;
		Else
			Items.DocumentKind.Visible = False;
		EndIf;
		
		ResultTemplateTree = ResponseToPackageRequests.responses[1];
	Else
		ResultTemplateTree = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, ResultTemplateTree);
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(ResultTemplateTree, "formHeader") Then
		Title = ResultTemplateTree.formHeader;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(ResultTemplateTree, "commandHeader") Then
		Items.CreateProcess.Title = ResultTemplateTree.commandHeader;
	EndIf;
	
	If SendingByMailIsUsed() Then
		SendByEmail = Tree.Rows.Add();
		SendByEmail.Description = NStr("vi = 'Qua E-mail';
										|ru = 'По почте';
										|en = 'By mail'; fa = 'By mail';
										|it = 'Per posta';
										|pl = 'Przez pocztę';
										|tr = 'E-posta ile'");
		SendByEmail.ToolTip = NStr("vi = 'Tạo thông điệp qua E-mail để gửi đi.';
									|ru = 'Создание почтового сообщения для отправки.';
									|en = 'Create a message to send.'; fa = 'Create a message to send.';
									|it = 'Creazione messaggio di posta per l''invio.';
									|pl = 'Tworzenie wiadomości pocztowej do wysyłki.';
									|tr = 'Göndermek için e-posta mesajı oluştur.'");
		SendByEmail.HintReceived = True;
		SendByEmail.ThisIsTheTitle = False;
		SendByEmail.ProcessType = "SendByEmail";
	EndIf;
	
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1") Then
		ProcessResult_2_1_18_1(Tree, ResultTemplateTree);
	Else
		ProcessResult(Tree, ResultTemplateTree);
	EndIf;
	
	ValueToFormData(Tree, TemplateTree);
	SetCurRowInTreeToFirstSignificantElement();
	
EndProcedure

&AtServer
Procedure ProcessResult(Tree, ResultTemplateTree)
	
	OrderOfBusinessProcesses = New Array();
	OrderOfBusinessProcesses.Add("DMBusinessProcessOrder");
	OrderOfBusinessProcesses.Add("DMBusinessProcessApproval");
	OrderOfBusinessProcesses.Add("DMBusinessProcessPerformance");
	OrderOfBusinessProcesses.Add("DMBusinessProcessConsideration");
	OrderOfBusinessProcesses.Add("DMBusinessProcessAcquaintance");
	OrderOfBusinessProcesses.Add("DMComplexBusinessProcess");
	OrderOfBusinessProcesses.Add("DMBusinessProcessRegistration");
	OrderOfBusinessProcesses.Add("DMBusinessProcessConfirmation");
	OrderOfBusinessProcesses.Add("DMBusinessProcessInvitation");
	OrderOfBusinessProcesses.Add("DMBusinessProcessOutgoingDocumentProcessing");
	OrderOfBusinessProcesses.Add("DMBusinessProcessInternalDocumentProcessing");
	OrderOfBusinessProcesses.Add("DMBusinessProcessIncomingDocumentProcessing");
	
	HideOrders = IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.0.0.0");
	
	For Each Section In ResultTemplateTree.BusinessProcessTemplatesTree Do
		
		TreeSection = Tree.Rows.Add();
		TreeSection.Description = Section.name;
		TreeSection.ToolTip = Section.hint;
		TreeSection.HintReceived = True;
		TreeSection.ThisIsTheTitle = True;
		
		If TreeSection.Description = NStr("vi = 'Khuôn mẫu mới';
											|ru = 'Другие шаблоны';
											|en = 'Other templates'; fa = 'Other templates';
											|it = 'Altri modelli';
											|pl = 'Inne szablony';
											|tr = 'Diğer numuneler'") Then
			TreeSection.Expand = False;
		Else
			TreeSection.Expand = True;
		EndIf;
		
		For Each Template In Section.elements Do
			
			If HideOrders And Template.businessProcessType = "DMBusinessProcessOrder" Then
				Continue;
			EndIf;
			
			SectionRow = TreeSection.Rows.Add();
			SectionRow.Description = Template.name;
			SectionRow.ToolTip = Template.hint;
			SectionRow.HintReceived = True;
			SectionRow.ThisIsTheTitle = False;
			SectionRow.ProcessType = Template.businessProcessType;
			If ValueIsFilled(Template.template.objectID.ID) Then
				SectionRow.TemplateID = Template.template.objectID.ID;
				SectionRow.TemplateType = Template.template.objectID.type;
			Else
				SectionRow.IndexOf = OrderOfBusinessProcesses.Find(SectionRow.ProcessType);
			EndIf;
			
		EndDo;
		
		TreeSection.Rows.Sort("IndexOf");
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ProcessResult_2_1_18_1(Tree, ResultTemplateTree)
	
	ConditionalAppearance.Items.Clear();
	
	For Each Section In ResultTemplateTree.BusinessProcessTemplatesTree Do
		
		If Section.name = NStr("vi = 'Khuôn mẫu khuyến cáo';
								|ru = 'Рекомендованные шаблоны';
								|en = 'Recommended templates'; fa = 'Recommended templates';
								|it = 'Modelli consigliati';
								|pl = 'Zalecane szablony';
								|tr = 'Önerilen numuneler'") Then
			
			For Each Template In Section.elements Do
				
				If Template.businessProcessType = "DMBusinessProcessOrder" Then
					Continue;
				EndIf;
				
				SectionRow = Tree.Rows.Add();
				SectionRow.Description = Template.name;
				If IntegrationWith1CDocumentManagementCore.PropertySet(Template, "hintHTML") Then
					SectionRow.ToolTip = Template.hintHTML;
					SectionRow.HintReceived = True;
				ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(Template, "hint") Then
					SectionRow.ToolTip = Template.hint;
					SectionRow.HintReceived = True;
				EndIf;
				SectionRow.ThisIsTheTitle = False;
				SectionRow.ProcessType = Template.businessProcessType;
				If ValueIsFilled(Template.template.objectID.ID) Then
					SectionRow.TemplateID = Template.template.objectID.ID;
					SectionRow.TemplateType = Template.template.objectID.type;
				EndIf;
				
			EndDo;
			
		Else
			
			TreeSection = Tree.Rows.Add();
			TreeSection.Description = Section.name;
			If IntegrationWith1CDocumentManagementCore.PropertySet(Section, "hintHTML") Then
				TreeSection.ToolTip = Section.hintHTML;
				TreeSection.HintReceived = True;
			ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(Section, "hint") Then
				TreeSection.ToolTip = Section.hint;
				TreeSection.HintReceived = True;
			EndIf;
			TreeSection.ThisIsTheTitle = True;
			
			If TreeSection.Description = NStr("vi = 'Các phương án khác';
												|ru = 'Другие варианты';
												|en = 'Other options'; fa = 'Other options';
												|it = 'Altre varianti';
												|pl = 'Inne warianty';
												|tr = 'Diğer seçenekler'") Then
				TreeSection.Expand = False;
			Else
				TreeSection.Expand = True;
			EndIf;
			
			For Each Template In Section.elements Do
				
				If Template.businessProcessType = "DMBusinessProcessOrder" Then
					Continue;
				EndIf;
				
				SectionRow = TreeSection.Rows.Add();
				SectionRow.Description = Template.name;
				If IntegrationWith1CDocumentManagementCore.PropertySet(Template, "hintHTML") Then
					SectionRow.ToolTip = Template.hintHTML;
					SectionRow.HintReceived = True;
				ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(Template, "hint") Then
					SectionRow.ToolTip = Template.hint;
					SectionRow.HintReceived = True;
				EndIf;
				SectionRow.ThisIsTheTitle = False;
				SectionRow.ProcessType = Template.businessProcessType;
				If ValueIsFilled(Template.template.objectID.ID) Then
					SectionRow.TemplateID = Template.template.objectID.ID;
					SectionRow.TemplateType = Template.template.objectID.type;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function SendingByMailIsUsed()
	
	If Not GetFunctionalOption("UseEmail1CDocumentManagement") Then
		Return False;
	EndIf;
	
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.8.1.CORP") Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(ExternalObject) Then
		Return False;
	EndIf;
	
	Return Metadata.CommonCommands.IntegrationWith1CDocumentManagementCreateLetter.
		CommandParameterType.Types().Find(TypeOf(ExternalObject)) <> Undefined;
	
EndFunction

&AtServer
Procedure SetCurRowInTreeToFirstSignificantElement()
	
	TreeItems = TemplateTree.GetItems();
	If TreeItems.Count() = 0 Then
		Return;
	EndIf;
	FirstGroup = TreeItems[0];
	If FirstGroup.GetItems().Count() = 0 Then
		Return;
	EndIf;
	FirstElementOfFirstGroup = FirstGroup.GetItems()[0];
	IndexOf = FirstElementOfFirstGroup.GetID();
	Items.TemplateTree.CurrentRow = IndexOf;
	
EndProcedure

&AtClient
Procedure CreateProcessExecute()
	
	If Items.TemplateTree.CurrentData = Undefined
			Or Items.TemplateTree.CurrentData.ThisIsTheTitle Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	
	SubjectOfBusinessProcess = New Structure;
	SubjectOfBusinessProcess.Insert("ID", SubjectOfID);
	SubjectOfBusinessProcess.Insert("type", SubjectOfType);
	SubjectOfBusinessProcess.Insert("name", SubjectOf);
	
	If ValueIsFilled(SubjectOfID) Then
		FormParameters.Insert("SubjectOf", SubjectOfBusinessProcess);
	EndIf;
	
	Data = Items.TemplateTree.CurrentData;
	
	If Data.ProcessType = "SendByEmail" Then
		If ValueIsFilled(SubjectOfID) Then
			OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Outgoing_Email", FormParameters);
		EndIf;
		Return;
	EndIf;
	
	If ValueIsFilled(MainTaskID) Then
		MainTaskOfBusinessProcess = New Structure;
		MainTaskOfBusinessProcess.Insert("ID",MainTaskID);
		MainTaskOfBusinessProcess.Insert("type",MainTaskType);
		MainTaskOfBusinessProcess.Insert("name",MainTask);
		FormParameters.Insert("MainTask", MainTaskOfBusinessProcess);
	EndIf;
	
	If ValueIsFilled(Data.TemplateID) Then
		BusinessProcessTemplate = New Structure;
		BusinessProcessTemplate.Insert("ID", Data.TemplateID);
		BusinessProcessTemplate.Insert("type", Data.TemplateType);
		FormParameters.Insert("Template", BusinessProcessTemplate);
	EndIf;
	
	If ValueIsFilled(SubjectOfID) And StartImmediately Then
		If ValueIsFilled(Data.TemplateID) Then
			
			Items.CreateProcess.Enabled = False;
			
			If FillStartProcess(Data.ProcessType, FormParameters) Then
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã khởi động quy trình nghiệp vụ theo khuôn mẫu ""%1"".';
						|ru = 'Стартован бизнес-процесс по шаблону ""%1"".';
						|en = 'Business process started by template ""%1"".'; fa = 'Business process started by template ""%1"".';
						|it = 'Processo aziendale avviato in base al modello ""%1"".';
						|pl = 'Proces biznesowy jest uruchomiony według szablonu ""%1"".';
						|tr = '""%1"" numunesi ile iş süreci başlatıldı.'"), Data.Description);
				TitleText = NStr("vi = 'Đã khởi động quy trình';
								|ru = 'Стартован процесс';
								|en = 'Process is started'; fa = 'Process is started';
								|it = 'Processo avviato';
								|pl = 'Proces jest uruchomiony';
								|tr = 'Süreç başlatıldı'");
				ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
				
				NotificationParameters = New Structure;
				NotificationParameters.Insert("ID", Process_ID);
				NotificationParameters.Insert("Started", True);
				
				// Let's collect the items.
				Subjects = New Array;
				Subjects.Add(SubjectOfBusinessProcess);
				
				NotificationParameters.Insert("Subjects", Subjects);
				
				Notify("Recording_1CDocumentManagementBusinessProcess", NotificationParameters, FormOwner);
				
			Else
				IntegrationWith1CDocumentManagementCoreClient.OpenObject(Data.ProcessType, Undefined, , FormParameters);
			EndIf;
			
		Else
			Items.CreateProcess.Enabled = True;
			IntegrationWith1CDocumentManagementCoreClient.OpenObject(Data.ProcessType, Undefined, , FormParameters);
		EndIf;
	Else
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(Data.ProcessType, Undefined, , FormParameters);
	EndIf;
	
EndProcedure

&AtServer
Function FillStartProcess(ProcessType, StartupParameters)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	If StartupParameters.Property("SubjectOf") Then
		ProcessTemplate = IntegrationWith1CDocumentManagement.NewBusinessProcessByTemplate(Proxy, ProcessType, StartupParameters.Template, StartupParameters.SubjectOf);
	Else
		ProcessTemplate = IntegrationWith1CDocumentManagement.NewBusinessProcessByTemplate(Proxy, ProcessType, StartupParameters.Template);
	EndIf;
	
	NewProcess = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, ProcessTemplate.ObjectID.type);
	IntegrationWith1CDocumentManagementCore.FillInXDTOPropertyValues(Proxy, NewProcess, ProcessTemplate);
	
	RunResult = IntegrationWith1CDocumentManagement.StartBusinessProcess(Proxy, NewProcess);
		
	If IntegrationWith1CDocumentManagementCore.ValidateType(Proxy, RunResult, "DMError") Then
		Return False;
	Else
		Process_ID = RunResult.businessProcess.ObjectID.ID;
		Return True;
	EndIf;
	
EndFunction

#EndRegion