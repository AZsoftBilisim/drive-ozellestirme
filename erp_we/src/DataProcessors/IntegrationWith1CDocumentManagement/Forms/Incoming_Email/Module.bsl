#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillOutLetterForm(Parameters);
	DisplayNumberOfServerFiles();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SubjectOfClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(SubjectOfID) Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(SubjectOfType, SubjectOfID, Item);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersApplicationTree

&AtClient
Procedure ApplicationTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Item.CurrentData;
	If CurrentData <> Undefined Then
		IntegrationWith1CDocumentManagementCoreClient.OpenFile(
			CurrentData.RefID,
			CurrentData.Ref,
			CurrentData.Extension,
			UUID);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Reply(Command)
	
	FormParameters = New Structure("SubjectOf", New Structure);
	
	FormParameters.SubjectOf.Insert("name", Subject);
	FormParameters.SubjectOf.Insert("ID", ID);
	FormParameters.SubjectOf.Insert("type", Type);
	FormParameters.Insert("answerType", "reply");
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Outgoing_Email", FormParameters);
	AttachIdleHandler("CloseForm", 0.2, True);
	
EndProcedure

&AtClient
Procedure ReplyToAll(Command)
	
	FormParameters = New Structure("SubjectOf", New Structure);
	
	FormParameters.SubjectOf.Insert("name", Subject);
	FormParameters.SubjectOf.Insert("ID", ID);
	FormParameters.SubjectOf.Insert("type", Type);
	FormParameters.Insert("answerType", "replyToAll");
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Outgoing_Email", FormParameters);
	AttachIdleHandler("CloseForm", 0.2, True);
	
EndProcedure

&AtClient
Procedure ForwardMail(Command)
	
	FormParameters = New Structure("SubjectOf", New Structure);
	
	FormParameters.SubjectOf.Insert("name", Subject);
	FormParameters.SubjectOf.Insert("ID", ID);
	FormParameters.SubjectOf.Insert("type", Type);
	FormParameters.Insert("answerType", "transfer");
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.Outgoing_Email", FormParameters);
	AttachIdleHandler("CloseForm", 0.2, True);
	
EndProcedure

&AtClient
Procedure CreateProcess(Command)
	
	FormParameters = New Structure("SubjectOf", New Structure);
	
	FormParameters.SubjectOf.Insert("ID", ID);
	FormParameters.SubjectOf.Insert("type", Type);
	FormParameters.SubjectOf.Insert("name", Presentation);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.CreatingBusinessProcess", FormParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillOutLetterForm(Var_Parameters)
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	XDTOLetter = IntegrationWith1CDocumentManagementCore.GetObject(Proxy, Var_Parameters.type, Var_Parameters.ID);
	
	ID = XDTOLetter.objectID.ID;
	Type = XDTOLetter.objectID.type;
	Presentation = XDTOLetter.objectID.presentation;
	Title = XDTOLetter.subject;
	Subject = XDTOLetter.subject;
	EmailText = XDTOLetter.body;
	CreationDate = XDTOLetter.creationDate;
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject, XDTOLetter.importance,"Importance");
	IntegrationWith1CDocumentManagementCore.FillInObjectDetails(ThisObject, XDTOLetter.target,"SubjectOf");
	
	AddAddressees(XDTOLetter.senderAddress, NStr("vi = 'Người nhận';
												|ru = 'От';
												|en = 'From'; fa = 'از';
												|it = 'Del';
												|pl = 'From';
												|tr = 'İtibaren'"));
	AddAddressees(XDTOLetter.recipients, NStr("vi = 'Người gửi';
												|ru = 'Кому';
												|en = 'To'; fa = 'به';
												|it = 'A chi';
												|pl = 'To';
												|tr = 'Kime'"));
	AddAddressees(XDTOLetter.courtesyCopyRecipients, NStr("vi = 'Bản sao';
															|ru = 'Копия';
															|en = 'Copy'; fa = 'کپی';
															|it = 'Copia';
															|pl = 'Copy';
															|tr = 'Cc'"));
	
	If XDTOLetter.Properties().Get("files") <> Undefined Then
		For Each File In XDTOLetter.files Do
			SubjectLine = ApplicationTree.Add();
			IntegrationWith1CDocumentManagementCore.FillInObjectDetails(SubjectLine, File, "Ref");
			SubjectLine.Extension = File.extension;
			SubjectLine.ModificationDate = File.modificationDateUniversal;
			SubjectLine.Size = File.size;
			
			DeletionMark = False;
			If IntegrationWith1CDocumentManagementCore.PropertySet(File, "deletionMark") Then
				DeletionMark = File.deletionMark;
			EndIf;
			SubjectLine.ItemTypeImage =
				IntegrationWith1CDocumentManagementCore.IndexOfFileIcon(
					SubjectLine.Extension,
					DeletionMark);
			
			SetItemTypeImage(SubjectLine);
		EndDo;
	EndIf;
	
	DataProcessors.IntegrationWith1CDocumentManagementCore.SetNavigationLink(ThisObject, XDTOLetter);
	
EndProcedure

&AtServer
Procedure AddAddressees(AddresseeString, AddresseesType)
	If Not IsBlankString(AddresseeString) Then
		ArrayOfRecipients = StrSplit(AddresseeString, ";", False);
		For Each Addressee In ArrayOfRecipients Do
			If Not IsBlankString(TrimAll(Addressee)) Then
				StringAddressee = Recipients.Add();
				StringAddressee.DestinationType = AddresseesType + ":";
				StringAddressee.Addressee = TrimAll(Addressee);
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure SetItemTypeImage(SubjectLine)
	If StrFind(SubjectLine.RefType,"Document.") <> 0 Then
		SubjectLine.ItemTypeImage = PictureLib.Document;
	ElsIf StrFind(SubjectLine.RefType,"Catalog.") <> 0 Then
		SubjectLine.ItemTypeImage = PictureLib.Catalog
	ElsIf StrFind(SubjectLine.RefType,"BusinessProcess.") <> 0 Then
		SubjectLine.ItemTypeImage = PictureLib.BusinessProcess;
	ElsIf StrFind(SubjectLine.RefType,"Task.") <> 0 Then
		SubjectLine.ItemTypeImage = PictureLib.Task;
	EndIf;
EndProcedure

&AtServer
Procedure DisplayNumberOfServerFiles()
	
	If ApplicationTree.Count() > 0 Then
		Items.ApplicationTreeRef.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tệp (%1)';
				|ru = 'Файлы (%1)';
				|en = 'Files (%1)'; fa = 'Files (%1)';
				|it = 'File (%1)';
				|pl = 'Pliki (%1)';
				|tr = 'Dosyalar (%1)'"),
			ApplicationTree.Count());
	Else
		Items.ApplicationTreeRef.Title = NStr("vi = 'Tệp';
												|ru = 'Файлы';
												|en = 'Files'; fa = 'فایل‌ها';
												|it = 'File';
												|pl = 'Files';
												|tr = 'Dosyalar'");
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseForm()
	
	Close();
	
EndProcedure

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
