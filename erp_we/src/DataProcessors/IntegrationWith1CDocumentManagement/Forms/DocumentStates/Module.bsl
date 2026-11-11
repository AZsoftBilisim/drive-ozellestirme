#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Document = Parameters.Document;
	DocumentID = Parameters.DocumentID;
	DocumentType = Parameters.DocumentType;
	
	If ValueIsFilled(DocumentID) Then
		
		ReadDocumentStates(Parameters);
		
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trạng thái văn bản ""%1""';
				|ru = 'Состояние документа ""%1""';
				|en = 'State of document ""%1""'; fa = 'State of document ""%1""';
				|it = 'Stato del documento ""%1""';
				|pl = 'Status dokumentu ""%1""';
				|tr = '""%1"" belge durumu'"),
			Document);
		
	Else
		
		If DocumentType = "DMIncomingDocument" Then
			StateRegistration = NStr("vi = 'Chờ đăng ký';
									|ru = 'На регистрации';
									|en = 'On registration'; fa = 'در حال ثبت';
									|it = 'In registrazione';
									|pl = 'Na rejestracji';
									|tr = 'Kayıtda'");
			StateRegistrationID = "НаРегистрации"; //@NON-NLS-1
			StateRegistrationType = "DMDocumentStatus";
		Else
			StateRegistration = NStr("vi = 'Dự án';
									|ru = 'Проект';
									|en = 'Project'; fa = 'پروژه';
									|it = 'Progetto';
									|pl = 'Projekt';
									|tr = 'Proje'");
			StateRegistrationID = "Проект"; //@NON-NLS-1
			StateRegistrationType = "DMDocumentStatus";
		EndIf;
		
	EndIf;
	
	If Parameters.ReadOnly Then
		
		ReadOnly = True;
		Items.FormWrite.Visible = False;
		Items.FormCancel.Title = NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Close';
										|tr = 'Kapat'");
		
	EndIf;
	
	Items.StateApproval.ChoiceList.Clear();
	Items.StateApproval.ChoiceList.Add(
		"НаСогласовании",
		NStr("en = 'Pending approval'; fa = 'در انتظار تأیید'")); //@NON-NLS-1
	Items.StateApproval.ChoiceList.Add(
		"Согласован",
		NStr("en = 'Approved'; fa = 'تأییدشده'")); //@NON-NLS-1
	Items.StateApproval.ChoiceList.Add(
		"НеСогласован",
		NStr("en = 'Not approved'; fa = 'تأییدنشده'")); //@NON-NLS-1
	
	Items.StateConfirmation.ChoiceList.Clear();
	Items.StateConfirmation.ChoiceList.Add(
		"НаУтверждении",
		NStr("en = 'Pending confirmation'; fa = 'در انتظار تصدیق'")); //@NON-NLS-1
	Items.StateConfirmation.ChoiceList.Add(
		"Утвержден",
		NStr("en = 'Confirmed'; fa = 'تأییدشده'")); //@NON-NLS-1
	Items.StateConfirmation.ChoiceList.Add(
		"НеУтвержден",
		NStr("en = 'Not confirmed'; fa = 'تصدیق‌نشده'")); //@NON-NLS-1
	
	Items.StateSigning.ChoiceList.Clear();
	Items.StateSigning.ChoiceList.Add(
		"НаПодписании",
		NStr("en = 'On signing'; fa = 'در حال امضا'")); //@NON-NLS-1
	Items.StateSigning.ChoiceList.Add(
		"Подписан",
		NStr("en = 'Signed'; fa = 'امضاشده'")); //@NON-NLS-1
	Items.StateSigning.ChoiceList.Add(
		"Отклонен",
		NStr("en = 'Rejected'; fa = 'ردشده'")); //@NON-NLS-1
	
	Items.StateRegistration.ChoiceList.Clear();
	Items.StateRegistration.ChoiceList.Add(
		"Проект",
		NStr("en = 'Project'; fa = 'پروژه'")); //@NON-NLS-1
	Items.StateRegistration.ChoiceList.Add(
		"НаРегистрации",
		NStr("en = 'On registration'; fa = 'در حال ثبت'")); //@NON-NLS-1
	Items.StateRegistration.ChoiceList.Add(
		"Зарегистрирован",
		NStr("en = 'Registered'; fa = 'ثبت‌شده'")); //@NON-NLS-1
	Items.StateRegistration.ChoiceList.Add(
		"НеЗарегистрирован",
		NStr("en = 'Not registered'; fa = 'ثبت‌نشده'")); //@NON-NLS-1
	
	Items.StateReviewal.ChoiceList.Clear();
	Items.StateReviewal.ChoiceList.Add(
		"НаРассмотрении",
		NStr("en = 'On review'; fa = 'در حال بررسی'")); //@NON-NLS-1
	Items.StateReviewal.ChoiceList.Add(
		"Рассмотрен",
		NStr("en = 'Reviewed'; fa = 'بررسی‌شده'")); //@NON-NLS-1
	
	Items.StatePerformance.ChoiceList.Clear();
	Items.StatePerformance.ChoiceList.Add(
		"НаИсполнении",
		NStr("en = 'On execution'; fa = 'در حال اجرا'")); //@NON-NLS-1
	Items.StatePerformance.ChoiceList.Add(
		"Исполнен",
		NStr("en = 'Executed'; fa = 'Executed'")); //@NON-NLS-1
	
	RefreshVisibility();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
#If WebClient Then
	If Not Parameters.ReadOnly Then
		Items.StateApproval.TextEdit = False;
		Items.StateConfirmation.TextEdit = False;
		Items.StateSigning.TextEdit = False;
		Items.StateRegistration.TextEdit = False;
		Items.StateReviewal.TextEdit = False;
		Items.StatePerformance.TextEdit = False;
		
		Items.StateApproval.ClearButton = True;
		Items.StateConfirmation.ClearButton = True;
		Items.StateSigning.ClearButton = True;
		Items.StateRegistration.ClearButton = True;
		Items.StateReviewal.ClearButton = True;
		Items.StatePerformance.ClearButton = True;
	EndIf;
#EndIf
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StateApprovalOnChange(Item)
	
	WhenStateChanges(Item);
	
EndProcedure

&AtClient
Procedure StateConfirmationOnChange(Item)
	
	WhenStateChanges(Item);
	
EndProcedure

&AtClient
Procedure StateSigningOnChange(Item)
	
	WhenStateChanges(Item);
	
EndProcedure

&AtClient
Procedure StateRegistrationOnChange(Item)
	
	WhenStateChanges(Item);
	
EndProcedure

&AtClient
Procedure StateReviewalOnChange(Item)
	
	WhenStateChanges(Item);
	
EndProcedure

&AtClient
Procedure StatePerformanceOnChange(Item)
	
	WhenStateChanges(Item);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Result = New Structure;
	
	Attributes = New Structure;
	Attributes.Insert("StateApproval");
	Attributes.Insert("StateConfirmation");
	Attributes.Insert("StateSigning");
	Attributes.Insert("StateRegistration");
	Attributes.Insert("StateReviewal");
	Attributes.Insert("StatePerformance");
	For Each Attribute In Attributes Do
		AttributeName = Attribute.Key;
		Result.Insert(AttributeName, ThisObject[AttributeName]);
		Result.Insert(AttributeName + "ID", ThisObject[AttributeName + "ID"]);
		Result.Insert(AttributeName + "Type", ThisObject[AttributeName + "Type"]);
	EndDo;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtServer
Procedure ReadDocumentStates(Var_Parameters)
	
	Attributes = New Structure;
	Attributes.Insert("StateApproval");
	Attributes.Insert("StateConfirmation");
	Attributes.Insert("StateRegistration");
	Attributes.Insert("StateReviewal");
	Attributes.Insert("StatePerformance");
	If Var_Parameters.Property("StateSigning") Then
		Attributes.Insert("StateSigning");
	EndIf;
	For Each Attribute In Attributes Do
		AttributeName = Attribute.Key;
		ThisObject[AttributeName] = Var_Parameters[AttributeName];
		ThisObject[AttributeName + "ID"] = Var_Parameters[AttributeName + "ID"];
		ThisObject[AttributeName + "Type"] = Var_Parameters[AttributeName + "Type"];
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WhenStateChanges(Item)
	
	ThisObject[Item.Name] = Item.EditText;
	If ValueIsFilled(ThisObject[Item.Name]) Then
		ThisObject[Item.Name + "Type"] = "DMDocumentStatus";
	Else
		ThisObject[Item.Name + "Type"] = "";
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshVisibility()
	
	SigningIsUsed = False;
	
	If DocumentType = "DMInternalDocument" Then
		Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
		XDTODocument = IntegrationWith1CDocumentManagementCore.GetObject(
			Proxy,
			DocumentType,
			DocumentID,
			"documentType");
		If IntegrationWith1CDocumentManagementCore.PropertySet(
				XDTODocument.documentType, "useSigningByManager") Then
			SigningIsUsed = XDTODocument.documentType.useSigningByManager;
		EndIf;
	EndIf;
	
	If SigningIsUsed Then
		Items.ConfirmationGroup.Visible = False;
		Items.SignGroup.Visible = True;
	Else
		Items.ConfirmationGroup.Visible = True;
		Items.SignGroup.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion